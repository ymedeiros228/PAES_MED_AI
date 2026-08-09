import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from ingest_pdf import clean_question_statement, sanitize_question_statements  # noqa: E402


def test_clean_question_statement_removes_real_pdf_artifacts() -> None:
    dirty = (
        "Processo Seletivo de Acesso à Educação Superior "
        "/gid00049/gid00034/gid00038/gid000522024 3 "
        "No contexto poético, são versos..."
    )
    assert clean_question_statement(dirty) == "No contexto poético, são versos..."

    dirty_with_url = (
        "https://www.letras.mus.br/erasmo-carlos/ "
        "Processo Seletivo de Acesso à Educação Superior "
        "/gid00049/gid00034/gid00038/gid000522024 4 És engraçada..."
    )
    assert clean_question_statement(dirty_with_url) == (
        "https://www.letras.mus.br/erasmo-carlos/ És engraçada..."
    )


def test_clean_question_statement_is_idempotent() -> None:
    value = "Processo Seletivo de Acesso à Educação Superior /gid00049 2024 12 Leia o texto."
    once = clean_question_statement(value)
    assert once == "Leia o texto."
    assert clean_question_statement(once) == once


def test_clean_question_statement_preserves_legitimate_numbers() -> None:
    value = "Entre 1976-1983, foram usados US$ 1,324 bilhão, 2L, 0,4mL e 120°C."
    assert clean_question_statement(value) == value


def test_sanitize_question_statements_updates_only_dirty_rows(tmp_path, monkeypatch) -> None:
    import sqlite3
    from contextlib import contextmanager

    import ingest_pdf

    db_path = tmp_path / "paes_med_ai.db"
    @contextmanager
    def temporary_db():
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    monkeypatch.setattr(ingest_pdf, "db", temporary_db)
    with temporary_db() as conn:
        conn.execute(
            "CREATE TABLE questions (id TEXT PRIMARY KEY, statement TEXT NOT NULL)"
        )
        conn.execute(
            "INSERT INTO questions VALUES (?, ?)",
            ("dirty", "Processo Seletivo de Acesso à Educação Superior /gid00049 2024 3 Enunciado."),
        )
        conn.execute("INSERT INTO questions VALUES (?, ?)", ("clean", "2L e 120°C."))

    assert sanitize_question_statements() == 1
    assert sanitize_question_statements() == 0
    with temporary_db() as conn:
        rows = {row["id"]: row["statement"] for row in conn.execute("SELECT * FROM questions")}
    assert rows == {"dirty": "Enunciado.", "clean": "2L e 120°C."}
