"""Testes da migração de conteúdo de flashcards."""

import json

from content_migrations import CONTENT_MIGRATION_VERSION, migrate_content
from db import db, init_db


def _reset():
    init_db()
    with db() as conn:
        conn.execute("DELETE FROM flashcards")
        conn.execute("DELETE FROM settings WHERE key='content_migration_version'")
        conn.execute("DELETE FROM lessons WHERE id LIKE 'teste-mig-%'")
        conn.commit()


def test_migracao_limpa_template_e_importa_aulas():
    _reset()
    with db() as conn:
        conn.execute(
            "INSERT INTO flashcards (front, back, source, reviews) VALUES "
            "('[Biologia] Genética — Gabarito (eixo)', 'x', 'axis:q1', 0),"
            "('Macete rápido — Genética', 'x', 'lesson:a', 0),"
            "('Distrator (eixo)', 'x', 'manual', 3),"
            "('Minha carta', 'resposta', 'manual', 0)"
        )
        conn.execute(
            "INSERT INTO lessons (id, title, source_type, subject, topic, flashcards_json, created_at) "
            "VALUES ('teste-mig-1','T','texto','Biologia','Genética', ?, '2026-01-01T00:00:00')",
            (json.dumps([{"front": "Minha carta", "back": "dup"}, {"front": "Nova?", "back": "Sim"}]),),
        )
        conn.commit()
    r = migrate_content()
    assert r["removed"] == 2 and r["added"] >= 1
    with db() as conn:
        fronts = [x["front"] for x in conn.execute("SELECT front FROM flashcards").fetchall()]
        ver = conn.execute("SELECT value FROM settings WHERE key='content_migration_version'").fetchone()
    assert "Distrator (eixo)" in fronts  # já revisado: preservado
    assert fronts.count("Minha carta") == 1  # sem duplicar
    assert "Nova?" in fronts
    assert ver["value"] == CONTENT_MIGRATION_VERSION
    assert migrate_content() == {"skipped": True}


def test_migracao_corrige_disciplina_errada():
    _reset()
    with db() as conn:
        conn.execute("DELETE FROM syllabus WHERE id LIKE 'teste-mig-%'")
        conn.execute("DELETE FROM lessons WHERE id LIKE 'teste-mig-%'")
        conn.execute(
            "INSERT INTO syllabus (id, subject, topic) VALUES ('teste-mig-s1','Geografia','Geografia do Brasil Teste')"
        )
        conn.execute(
            "INSERT INTO lessons (id, title, source_type, subject, topic, created_at) "
            "VALUES ('teste-mig-2','T','texto','História','geografia do brasil téste','2026-01-01T00:00:00')"
        )
        conn.execute(
            "INSERT INTO flashcards (front, back, subject, topic, source, reviews) "
            "VALUES ('Fx','b','História','Geografia do Brasil Teste','aula',4)"
        )
        conn.commit()
    r = migrate_content()
    assert r["fixed"] >= 2
    with db() as conn:
        l = conn.execute("SELECT subject FROM lessons WHERE id='teste-mig-2'").fetchone()
        c = conn.execute("SELECT subject, reviews FROM flashcards WHERE front='Fx'").fetchone()
        conn.execute("DELETE FROM syllabus WHERE id LIKE 'teste-mig-%'")
        conn.execute("DELETE FROM lessons WHERE id LIKE 'teste-mig-%'")
        conn.commit()
    assert l["subject"] == "Geografia"
    assert c["subject"] == "Geografia" and c["reviews"] == 4
