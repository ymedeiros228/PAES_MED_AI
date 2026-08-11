"""Bootstrap de produção: roda no primeiro startup do servidor (Render).

Se o banco não existir ou estiver vazio, faz seed + ingere todos os PDFs
oficiais encontrados em data/provas + data/gabaritos com gabarito aplicado.
Idempotente: se o banco já tem questões, só reindexa o RAG.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def bootstrap_production() -> dict:
    """Garante que o banco tem questões oficiais + RAG indexado."""
    from db import DB_PATH, init_db
    from seed import seed
    from ingest_pdf import import_and_commit_year, pair_prova_gabarito, sanitize_question_statements
    from services_advanced import index_all_questions

    init_db()
    seed(force=False)

    # Se já tem questões suficientes, só reindexa
    import sqlite3

    conn = sqlite3.connect(str(DB_PATH))
    count = conn.execute("SELECT COUNT(*) FROM questions").fetchone()[0]
    conn.close()
    if count >= 200:
        # Limpa enunciados + reindexa
        sanitize_question_statements()
        return index_all_questions()

    # Ingere todos os anos com PDF + gabarito disponíveis
    results = []
    for pair in pair_prova_gabarito():
        year = pair.get("year")
        if not year or not pair.get("prova"):
            continue
        if not pair.get("gabarito"):
            continue  # sem gabarito, pula (não commitamos sem gabarito em prod)
        try:
            r = import_and_commit_year(year)
            results.append({"year": year, "inserted": r.get("commit", {}).get("inserted", 0)})
        except Exception as exc:
            results.append({"year": year, "error": str(exc)})

    # Limpa enunciados + reindexa
    sanitize_question_statements()
    rag = index_all_questions()
    return {"ingested": results, "rag": rag}


if __name__ == "__main__":
    print(bootstrap_production())
