"""Classifica as questões oficiais nos tópicos do edital, com IA restrita à lista da disciplina.

Uso (na raiz do repositório):
    python scripts/provas/classificar_temas.py 2025          # só as que ainda não têm tema
    python scripts/provas/classificar_temas.py 2025 --refazer

Lê data/provas_oficiais/paes-<ano>.json e o edital (tabela syllabus do data/paes_med_ai.db).
Grava scripts/provas/temas/paes-<ano>.json: {id: {"topico", "subtopico", "syllabus_id"}}.
O arquivo é versionado e pode ser corrigido à mão; o importador só lê dele.
A disciplina não passa pela IA: vem do número da questão na prova.
"""

from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ / "backend"))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(RAIZ / "backend" / ".env")

from api_helpers import _ask_compatible, _ask_gemini, _ask_openai  # noqa: E402

MATERIAS = {
    "biologia": "Biologia", "fisica": "Física", "quimica": "Química", "matematica": "Matemática",
    "historia": "História", "geografia": "Geografia", "filosofia": "Filosofia", "sociologia": "Sociologia",
    "portugues": "Língua Portuguesa e Literatura", "ingles": "Inglês", "espanhol": "Espanhol",
}


def opcoes_do_edital(conn: sqlite3.Connection, disciplina: str) -> list[dict]:
    """Lista fechada de (tópico, subtópico, id) que a IA pode escolher para a disciplina."""
    materia = MATERIAS[disciplina]
    opcoes: list[dict] = []
    if disciplina in ("biologia", "fisica", "quimica", "historia", "geografia", "filosofia", "sociologia"):
        # edital de Natureza e Humanas é uma lista corrida ("Citologia, membranas, Mendel...");
        # cada item vira um tópico (agrupar pela maiúscula falha em nome próprio como Mendel)
        area = "Natureza" if disciplina in ("biologia", "fisica", "quimica") else "Humanas"
        for sid, item in conn.execute(
            "SELECT id, subtopic FROM syllabus WHERE subject=? AND topic=? ORDER BY rowid", (area, materia)
        ):
            opcoes.append({"topico": item[:1].upper() + item[1:], "subtopico": None, "syllabus_id": sid})
    else:
        assunto = "Linguagens" if disciplina != "matematica" else "Matemática"
        for sid, topico, sub in conn.execute(
            "SELECT id, topic, subtopic FROM syllabus WHERE subject=? AND id LIKE 'edital-%' ORDER BY rowid",
            (assunto,),
        ):
            if topico == "Produção textual":
                continue
            if disciplina in ("ingles", "espanhol") and topico not in ("Interpretação de texto", "Linguagem"):
                continue
            opcoes.append({"topico": topico, "subtopico": sub, "syllabus_id": sid})
    if not opcoes:
        raise SystemExit(f"Edital sem itens para {materia}; rode o seed do edital antes")
    return opcoes


def perguntar(instrucoes: str, conteudo: str) -> str:
    erros = []
    for nome, fn in (
        ("openrouter", lambda: _ask_compatible("openrouter", instrucoes, conteudo)),
        ("gemini", lambda: _ask_gemini(instrucoes, conteudo)),
        ("groq", lambda: _ask_compatible("groq", instrucoes, conteudo)),
        ("openai", lambda: _ask_openai(instrucoes, conteudo)),
    ):
        # o provedor às vezes fica "pendurado" no meio da resposta: corta em 90 s e tenta o próximo
        pool = ThreadPoolExecutor(max_workers=1)
        try:
            return pool.submit(fn).result(timeout=90)
        except Exception as exc:  # noqa: BLE001 — tenta o próximo provedor
            erros.append(f"{nome}: {getattr(exc, 'detail', exc) or type(exc).__name__}")
        finally:
            pool.shutdown(wait=False, cancel_futures=True)
    raise RuntimeError("Nenhum provedor de IA respondeu: " + " | ".join(erros))


def resumo(q: dict, textos: dict) -> str:
    base = textos.get(q.get("texto_base") or "", {}).get("conteudo", "") if q.get("texto_base") else ""
    corpo = re.sub(r"\[\[(FIGURA|TABELA) \d+\]\]", "", (base[:600] + "\n" + q["enunciado"]).strip())
    alts = " | ".join(a[:120] for a in q["alternativas"])
    return f"{corpo[:1400]}\nAlternativas: {alts}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("ano", type=int)
    ap.add_argument("--refazer", action="store_true")
    args = ap.parse_args()

    prova = json.loads((RAIZ / "data" / "provas_oficiais" / f"paes-{args.ano}.json").read_text(encoding="utf-8"))
    textos = {t["codigo"]: t for t in prova.get("textos_base", [])}
    saida = RAIZ / "scripts" / "provas" / "temas" / f"paes-{args.ano}.json"
    temas: dict = {} if args.refazer or not saida.exists() else json.loads(saida.read_text(encoding="utf-8"))
    conn = sqlite3.connect(RAIZ / "data" / "paes_med_ai.db")

    por_disc: dict[str, list[dict]] = {}
    for q in prova["questoes"]:
        if q["id"] not in temas:
            por_disc.setdefault(q["disciplina"], []).append(q)
    for disc, questoes in por_disc.items():
        opcoes = opcoes_do_edital(conn, disc)
        lista = "\n".join(
            f"{i}: {o['topico']}" + (f" — {o['subtopico']}" if o["subtopico"] else "") for i, o in enumerate(opcoes)
        )
        instrucoes = (
            f"Você classifica questões do vestibular PAES/UEMA de {MATERIAS[disc]} nos tópicos do edital. "
            "Escolha, para cada questão, o número do tópico da lista que melhor descreve o conteúdo cobrado "
            "(o que o aluno precisa saber para acertar, não o tema do texto de apoio). "
            "Responda só com JSON no formato {\"<id>\": <número>, ...}, sem comentários.\n\nTópicos:\n" + lista
        )
        escolhas: dict = {}
        for i in range(0, len(questoes), 5):  # lote pequeno: modelo gratuito demora com texto longo
            conteudo = "\n\n".join(f"### {q['id']}\n{resumo(q, textos)}" for q in questoes[i : i + 5])
            bruto = perguntar(instrucoes, conteudo)
            m = re.search(r"\{.*\}", bruto, re.S)
            escolhas.update(json.loads(m.group(0)) if m else {})
        for q in questoes:
            k = escolhas.get(q["id"])
            if isinstance(k, str) and k.strip().isdigit():
                k = int(k)
            if not isinstance(k, int) or not 0 <= k < len(opcoes):
                print(f"  {q['id']}: resposta inválida da IA ({k!r}); fica sem tema")
                continue
            temas[q["id"]] = {**opcoes[k], "materia": MATERIAS[disc]}
        print(f"{MATERIAS[disc]:<32} {sum(q['id'] in temas for q in questoes)}/{len(questoes)}", flush=True)
        # grava a cada matéria: se cair no meio, a próxima rodada continua de onde parou
        saida.parent.mkdir(parents=True, exist_ok=True)
        saida.write_text(json.dumps(dict(sorted(temas.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    saida.parent.mkdir(parents=True, exist_ok=True)
    saida.write_text(json.dumps(dict(sorted(temas.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    faltam = [q["id"] for q in prova["questoes"] if q["id"] not in temas]
    print(f"Gravado {saida.relative_to(RAIZ)}; sem tema: {faltam or 'nenhuma'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
