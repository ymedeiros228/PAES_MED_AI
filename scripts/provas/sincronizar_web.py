"""Leva para o banco web (Supabase) as questões de provas reimportadas no SQLite local, sem recriar nada.

Uso (na raiz do repositório, depois de importar_provas.py no SQLite):
    python scripts/provas/sincronizar_web.py --plano scripts/provas/migracoes/2026-11-01.json            # simula
    python scripts/provas/sincronizar_web.py --plano scripts/provas/migracoes/2026-11-01.json --aplicar  # grava

O plano (JSON) diz:
    "anos": [2014, 2015, 2016]          provas cujas questões oficiais são trocadas pelas do SQLite
    "ids_extras": ["mat-fun-2024", ...] outras questões copiadas do SQLite (upsert)
    "mapa_ids": {"paes-2015-005": "paes-2015-05", ...}   id antigo -> id novo
    "acertos": [{"esquema", "question_id", "answered_at", "correct", "motivo"}]  correções pontuais de resposta
    "apagar_flashcards_fonte": ["question:paes-2014-070", ...]

Em cada esquema de conta (paes = Jonas, paes_yuri = Yuri):
- respostas e flashcards que apontam para id antigo passam a apontar para o novo, com a matéria e o
  tópico corretos da questão nova;
- flashcard de erro ("erro:<id>") é refeito a partir da questão nova (o antigo guardava o gabarito errado);
- as correções de "acertos" são aplicadas pela chave (questão, data/hora da resposta).

Tudo numa transação: sem --aplicar, desfaz no fim e só mostra o que faria.
Antes de aplicar: python scripts/backup_supabase.py  (e --esquema paes_yuri).
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "backend"))

import psycopg  # noqa: E402

from db import DATABASE_URL  # noqa: E402

ESQUEMAS_DE_CONTA = ("paes", "paes_yuri")
LETRAS = "ABCDE"


def frente_e_verso(q: dict) -> tuple[str, str]:
    """Mesmo formato de services_extra._maybe_flashcard_from_error, sem as marcas de figura."""
    enunciado = re.sub(r"\[\[img:[^\]]+\]\]", " ", q["statement"] or "")
    enunciado = re.sub(r"\s+", " ", enunciado).strip()
    frente = f"[{q['subject']}] {q['topic']}: {enunciado[:180]}…"
    idx = int(q["correct_index"] or 0)
    partes = [f"Gabarito: {LETRAS[idx] if 0 <= idx < 5 else '?'}"]
    for campo in ("macete", "pegadinha", "resolution"):
        if (q.get(campo) or "").strip():
            partes.append(q[campo].strip()[:360])
    partes.append(f"Banca: {q.get('exam_board') or 'TREINO'}")
    return frente, "\n".join(partes)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plano", required=True)
    ap.add_argument("--sqlite", default=str(RAIZ / "data" / "paes_med_ai.db"))
    ap.add_argument("--aplicar", action="store_true")
    args = ap.parse_args()
    plano = json.loads(Path(args.plano).read_text(encoding="utf-8"))
    anos = plano.get("anos", [])
    mapa: dict[str, str] = plano.get("mapa_ids", {})

    loc = sqlite3.connect(args.sqlite)
    loc.row_factory = sqlite3.Row
    colunas = [r[1] for r in loc.execute("PRAGMA table_info(questions)")]
    marcas = ",".join("?" * len(anos))
    novas = [dict(r) for r in loc.execute(
        f"SELECT * FROM questions WHERE source='oficial' AND exam_board='UEMA_PAES' AND year IN ({marcas})", anos
    )] if anos else []
    extras = [dict(r) for r in loc.execute(
        f"SELECT * FROM questions WHERE id IN ({','.join('?' * len(plano.get('ids_extras', [])))})",
        plano.get("ids_extras", []),
    )] if plano.get("ids_extras") else []
    por_id = {q["id"]: q for q in novas + extras}
    faltando = sorted({n for n in mapa.values() if n not in por_id})
    if faltando:
        raise SystemExit(f"O mapa aponta para questões que não estão no SQLite: {faltando[:10]}")

    lista_cols = ", ".join(f'"{c}"' for c in colunas)
    sets = ", ".join(f'"{c}" = EXCLUDED."{c}"' for c in colunas if c != "id")
    def contar_orfas(cur) -> dict[str, int]:
        saida = {}
        for esq in ESQUEMAS_DE_CONTA:
            cur.execute("SELECT 1 FROM information_schema.tables WHERE table_schema=%s AND table_name='answers'", (esq,))
            if cur.fetchone():
                cur.execute(
                    f"SELECT count(*) FROM {esq}.answers a LEFT JOIN paes.questions q ON q.id = a.question_id "
                    "WHERE q.id IS NULL"
                )
                saida[esq] = cur.fetchone()[0]
        return saida

    with psycopg.connect(DATABASE_URL) as pg:
        cur = pg.cursor()
        orfas_antes = contar_orfas(cur)
        # 1) questões oficiais dos anos: sai a versão antiga, entra a reextraída
        if anos:
            cur.execute(
                "SELECT id FROM paes.questions WHERE source='oficial' AND exam_board='UEMA_PAES' AND year = ANY(%s)", (anos,)
            )
            antigas = [r[0] for r in cur.fetchall()]
            cur.execute("DELETE FROM paes.embeddings WHERE ref_type='question' AND ref_id = ANY(%s)", (antigas,))
            emb = cur.rowcount
            cur.execute("DELETE FROM paes.questions WHERE id = ANY(%s)", (antigas,))
            print(f"questões antigas removidas: {cur.rowcount} (embeddings: {emb})")
        for q in novas + extras:
            cur.execute(
                f"INSERT INTO paes.questions ({lista_cols}) VALUES ({', '.join(['%s'] * len(colunas))}) "
                f"ON CONFLICT (id) DO UPDATE SET {sets}",
                [q[c] for c in colunas],
            )
        print(f"questões gravadas: {len(novas)} das provas + {len(extras)} extras")

        # 2) progresso de cada conta
        for esq in ESQUEMAS_DE_CONTA:
            cur.execute("SELECT 1 FROM information_schema.tables WHERE table_schema=%s AND table_name='answers'", (esq,))
            if not cur.fetchone():
                continue
            n_resp = 0
            for velho, novo in mapa.items():
                q = por_id[novo]
                cur.execute(
                    f"UPDATE {esq}.answers SET question_id=%s, subject=%s, topic=%s WHERE question_id=%s",
                    (novo, q["subject"], q["topic"], velho),
                )
                n_resp += cur.rowcount
            n_acertos = 0
            for a in plano.get("acertos", []):
                if a["esquema"] != esq:
                    continue
                qid = mapa.get(a["question_id"], a["question_id"])
                cur.execute(
                    f"UPDATE {esq}.answers SET correct=%s WHERE question_id=%s AND answered_at=%s",
                    (a["correct"], qid, a["answered_at"]),
                )
                if cur.rowcount != 1:
                    raise SystemExit(f"{esq}: correção de acerto não achou 1 resposta: {a}")
                n_acertos += 1
            n_fc = n_apagados = 0
            cur.execute("SELECT 1 FROM information_schema.tables WHERE table_schema=%s AND table_name='flashcards'", (esq,))
            if cur.fetchone():
                fontes = plano.get("apagar_flashcards_fonte", [])
                if fontes:
                    cur.execute(f"DELETE FROM {esq}.flashcards WHERE source = ANY(%s)", (fontes,))
                    n_apagados = cur.rowcount
                for velho, novo in mapa.items():
                    q = por_id[novo]
                    frente, verso = frente_e_verso(q)
                    cur.execute(
                        f"UPDATE {esq}.flashcards SET source=%s, front=%s, back=%s, subject=%s, topic=%s WHERE source=%s",
                        (f"erro:{novo}", frente, verso, q["subject"], q["topic"], f"erro:{velho}"),
                    )
                    n_fc += cur.rowcount
                    cur.execute(
                        f"UPDATE {esq}.flashcards SET source=%s, subject=%s, topic=%s WHERE source=%s",
                        (f"question:{novo}", q["subject"], q["topic"], f"question:{velho}"),
                    )
                    n_fc += cur.rowcount
            print(f"{esq}: respostas remapeadas {n_resp}, acertos corrigidos {n_acertos}, "
                  f"flashcards refeitos {n_fc}, flashcards apagados {n_apagados}")

        # 3) nenhuma resposta pode ficar apontando para questão que deixou de existir
        orfas_depois = contar_orfas(cur)
        for esq, depois in orfas_depois.items():
            print(f"{esq}: respostas sem questão — antes {orfas_antes.get(esq)}, depois {depois}")
            if depois > orfas_antes.get(esq, 0):
                pg.rollback()
                raise SystemExit("Abortado: a troca deixaria respostas órfãs (nada foi gravado)")

        if args.aplicar:
            pg.commit()
            print("APLICADO.")
        else:
            pg.rollback()
            print("Simulação: nada foi gravado (use --aplicar).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
