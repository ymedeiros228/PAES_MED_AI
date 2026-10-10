"""Questões sem gabarito não entram em seleções de prática."""

from db import db, init_db
from services_core import list_questions


def test_answerable_only_exclui_sem_gabarito():
    init_db()
    with db() as conn:
        for qid, src in (("teste-ans-1", "pdf_ingest_sem_gabarito:2024"), ("teste-ans-2", "treino")):
            conn.execute(
                "INSERT OR REPLACE INTO questions (id, year, subject, topic, statement, options_json, "
                "correct_index, difficulty, source) VALUES (?,?,?,?,?,?,?,?,?)",
                (qid, 2024, "Teste", "TesteAns", "Enunciado", '["a","b","c","d","e"]', 0, "media", src),
            )
        conn.commit()
    try:
        todas = {q["id"] for q in list_questions(subject="Teste")}
        praticaveis = {q["id"] for q in list_questions(subject="Teste", answerable_only=True)}
        assert {"teste-ans-1", "teste-ans-2"} <= todas
        assert "teste-ans-1" not in praticaveis and "teste-ans-2" in praticaveis
    finally:
        with db() as conn:
            conn.execute("DELETE FROM questions WHERE id LIKE 'teste-ans-%'")
            conn.commit()
