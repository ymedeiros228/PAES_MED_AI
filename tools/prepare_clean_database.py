"""
Gera um banco limpo (paes_med_ai_clean.db) para distribuicao no instalador.
Remove todo o progresso, respostas, configuracoes e planos do usuario.
Mantem: questions, flashcards, lessons, materials, syllabus.
"""
import shutil
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "paes_med_ai.db"
DST = ROOT / "data" / "paes_med_ai_clean.db"


def create_clean_database():
    if DST.exists():
        DST.unlink()
    shutil.copy2(SRC, DST)

    conn = sqlite3.connect(DST)
    c = conn.cursor()

    # Tabelas com dados pessoais do usuario a serem limpas
    personal_tables = [
        "answers",
        "revisions",
        "session_checkpoint",
        "settings",
        "study_plan",
        "study_gaps",
        "essays",
        "embeddings",  # embeddings gerados por usuario tambem
    ]

    for table in personal_tables:
        try:
            c.execute(f"DELETE FROM {table}")
            print(f"Limpa: {table}")
        except sqlite3.OperationalError as e:
            print(f"Tabela {table} nao encontrada: {e}")

    # Reset de sequencias (sqlite_sequence)
    for table in personal_tables:
        try:
            c.execute("DELETE FROM sqlite_sequence WHERE name = ?", (table,))
        except sqlite3.OperationalError:
            pass

    # Opcional: cria um usuario/padrao minimo se necessario, mas no app ele cria sozinho.
    conn.commit()

    # Verifica conteudo final
    c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
    tables = [r[0] for r in c.fetchall()]
    print("\nBanco limpo:")
    for t in tables:
        c.execute(f"SELECT COUNT(*) FROM {t}")
        print(f"  {t}: {c.fetchone()[0]}")

    conn.close()
    print(f"\nBanco limpo salvo em: {DST}")
    return DST


if __name__ == "__main__":
    create_clean_database()
