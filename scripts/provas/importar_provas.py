"""Leva as provas oficiais extraídas (data/provas_oficiais/paes-<ano>.json) para o banco do app.

Uso (na raiz do repositório):
    python scripts/provas/importar_provas.py 2022 2024 2025 2026
    python scripts/provas/importar_provas.py 2025 --banco outro.db

Para cada ano:
- apaga as questões antigas do ano (source 'oficial' e 'pdf_ingest_sem_gabarito:<ano>' da banca UEMA_PAES)
  e os embeddings delas; respostas já dadas ficam (guardam matéria e tópico próprios);
- grava as novas com id paes-<ano>-NN (-en/-es nas línguas), texto-base em `passage`, figuras
  da questão em `figures_json` e o número da prova em `number`;
- figura e tabela ficam no lugar certo do texto: [[img:figuras/<ano>/x.webp]] e tabela markdown;
- questão anulada ou sem gabarito não entra (não serve para treino);
- tema vem de scripts/provas/temas/paes-<ano>.json (classificar_temas.py); sem tema, fica "Geral".
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
LETRAS = "ABCDE"
MATERIAS = {
    "biologia": "Biologia", "fisica": "Física", "quimica": "Química", "matematica": "Matemática",
    "historia": "História", "geografia": "Geografia", "filosofia": "Filosofia", "sociologia": "Sociologia",
    "portugues": "Língua Portuguesa e Literatura", "ingles": "Inglês", "espanhol": "Espanhol",
}
COLUNAS_NOVAS = {"passage": "TEXT", "figures_json": "TEXT DEFAULT '[]'", "number": "INTEGER"}


SUBSCRITOS = str.maketrans("0123456789aehijklmnoprstuvxTSN+-", "₀₁₂₃₄₅₆₇₈₉ₐₑₕᵢⱼₖₗₘₙₒₚᵣₛₜᵤᵥₓₜₛₙ₊₋")


def latex_para_texto(texto: str) -> str:
    """O app mostra texto puro: \\(\\frac{20}{9}\\) vira 20/9, \\sqrt{5} vira √5, F_{TS} vira Fₜₛ."""

    def grupo(s: str) -> str:
        return s if re.fullmatch(r"[\w√.,]+", s) else f"({s})"

    def formula(m: re.Match) -> str:
        f = m.group(1)
        for _ in range(3):  # frações e raízes aninhadas
            f = re.sub(r"\\sqrt\{([^{}]*)\}", lambda r: "√" + grupo(r.group(1)), f)
            f = re.sub(r"\\d?frac\{([^{}]*)\}\{([^{}]*)\}", lambda r: f"{grupo(r.group(1))}/{grupo(r.group(2))}", f)
        f = re.sub(r"_\{([^{}]*)\}|_(\w)", lambda r: (r.group(1) or r.group(2)).translate(SUBSCRITOS), f)
        f = re.sub(r"\\(?:left|right)\s*", "", f)
        f = f.replace("\\cdot", "·").replace("\\times", "×").replace("\\leq", "≤").replace("\\geq", "≥")
        return f.replace("-", "−").strip()

    return re.sub(r"\\\((.*?)\\\)", formula, texto or "")


def resolver(texto: str, figuras: list[dict], tabelas: list[str], creditos: list[str]) -> str:
    """Troca os marcadores pela figura/tabela de verdade; créditos vão logo abaixo da última
    figura (são legenda de foto, em geral) ou, sem figura, no fim."""

    def troca(m: re.Match) -> str:
        tipo, n = m.group(1), int(m.group(2)) - 1
        if tipo == "FIGURA":
            return f"[[img:{figuras[n]['caminho']}]]" if n < len(figuras) else ""
        return tabelas[n] if n < len(tabelas) else ""

    saida = re.sub(r"\[\[(FIGURA|TABELA) (\d+)\]\]", troca, texto or "")
    # tabela sem marcador (extração antiga) vai para o fim, para não sumir
    for k, tab in enumerate(tabelas, 1):
        if f"[[TABELA {k}]]" not in (texto or ""):
            saida += "\n\n" + tab
    if creditos:
        linhas = (" ".join(c.split()) for c in creditos)
        bloco = "\n".join(c if c.startswith("Fonte:") else f"Fonte: {c}" for c in linhas)
        ultima = list(re.finditer(r"\[\[img:[^\]]+\]\]", saida))
        if ultima:
            fim = ultima[-1].end()
            saida = saida[:fim] + "\n\n" + bloco + "\n\n" + saida[fim:]
        else:
            saida += "\n\n" + bloco
    return latex_para_texto(re.sub(r"\n{3,}", "\n\n", saida).strip())


def importar(conn: sqlite3.Connection, ano: int) -> None:
    prova = json.loads((RAIZ / "data" / "provas_oficiais" / f"paes-{ano}.json").read_text(encoding="utf-8"))
    arq_temas = RAIZ / "scripts" / "provas" / "temas" / f"paes-{ano}.json"
    temas = json.loads(arq_temas.read_text(encoding="utf-8")) if arq_temas.exists() else {}
    textos = {t["codigo"]: t for t in prova.get("textos_base", [])}

    antigas = [r[0] for r in conn.execute(
        "SELECT id FROM questions WHERE year = ? AND exam_board = 'UEMA_PAES' AND (source = 'oficial' OR source = ?)",
        (ano, f"pdf_ingest_sem_gabarito:{ano}"),
    )]
    conn.executemany("DELETE FROM embeddings WHERE ref_type = 'question' AND ref_id = ?", [(i,) for i in antigas])
    conn.executemany("DELETE FROM questions WHERE id = ?", [(i,) for i in antigas])

    novas, fora = 0, []
    for q in prova["questoes"]:
        if q.get("anulada") or q.get("gabarito") not in tuple(LETRAS):
            fora.append(q["id"])
            continue
        tb = textos.get(q.get("texto_base") or "")
        passagem = resolver(tb["conteudo"], tb["figuras"], tb["tabelas"], tb["creditos"]) if tb else None
        enunciado = resolver(q["enunciado"], q["figuras"], q["tabelas"], q.get("creditos", []))
        tema = temas.get(q["id"], {})
        tem_figura = bool(q["figuras"] or (tb and tb["figuras"]))
        tem_tabela = bool(q["tabelas"] or (tb and tb["tabelas"]))
        conn.execute(
            """INSERT INTO questions (id, year, subject, topic, subtopic, statement, options_json, correct_index,
                   difficulty, tags_json, syllabus_id, source, has_table, has_image, avg_text_len, generated,
                   approved, exam_board, passage, figures_json, number)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Média', ?, ?, 'oficial', ?, ?, ?, 0, 1, 'UEMA_PAES', ?, ?, ?)""",
            (
                q["id"], ano, MATERIAS[q["disciplina"]], tema.get("topico") or "Geral", tema.get("subtopico"),
                enunciado, json.dumps([latex_para_texto(a) for a in q["alternativas"]], ensure_ascii=False), LETRAS.index(q["gabarito"]),
                json.dumps([f"PAES {ano}", f"questão {q['numero']}"], ensure_ascii=False), tema.get("syllabus_id"),
                int(tem_tabela), int(tem_figura), len(enunciado) + len(passagem or ""),
                passagem, json.dumps([f["caminho"] for f in q["figuras"]]), q["numero"],
            ),
        )
        novas += 1
    sem_tema = sum(1 for q in prova["questoes"] if q["id"] not in temas)
    print(f"{ano}: {len(antigas)} antigas removidas, {novas} importadas, fora do treino: {fora or 'nenhuma'}"
          + (f", {sem_tema} sem tema" if sem_tema else ""))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("anos", type=int, nargs="+")
    ap.add_argument("--banco", default=str(RAIZ / "data" / "paes_med_ai.db"))
    args = ap.parse_args()

    conn = sqlite3.connect(args.banco)
    colunas = {r[1] for r in conn.execute("PRAGMA table_info(questions)")}
    for nome, tipo in COLUNAS_NOVAS.items():
        if nome not in colunas:
            conn.execute(f"ALTER TABLE questions ADD COLUMN {nome} {tipo}")
    for ano in args.anos:
        importar(conn, ano)
    conn.commit()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
