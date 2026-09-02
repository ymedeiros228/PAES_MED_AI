"""Adiciona topicos novos ao syllabus e gera aulas com IA para eles."""

from __future__ import annotations

import json
import sys
import uuid

sys.path.insert(0, '.')

from db import db
from generate_lessons import _LESSON_PROMPT, _ask_ai, _parse_lesson_response
from timeutil import now_iso


def add_new_topics_and_generate_lessons() -> dict:
    """Adiciona topicos das questoes novas ao syllabus e gera aulas."""
    with db() as conn:
        # Topicos das questoes novas que nao estao no syllabus
        new_topics = conn.execute(
            "SELECT DISTINCT q.subject, q.topic FROM questions q "
            "WHERE NOT EXISTS (SELECT 1 FROM syllabus s WHERE s.subject = q.subject AND s.topic = q.topic) "
            "AND q.topic IS NOT NULL AND q.topic != '' AND q.topic != 'A classificar' "
            "ORDER BY q.subject, q.topic"
        ).fetchall()

        added = 0
        for t in new_topics:
            syllabus_id = str(uuid.uuid4())
            conn.execute(
                "INSERT OR IGNORE INTO syllabus (id, subject, topic, subtopic, weight) VALUES (?, ?, ?, '', 1.0)",
                (syllabus_id, t[0], t[1]),
            )
            added += 1
        conn.commit()

        # Agora gera aulas para esses topicos
        topics_to_generate = conn.execute(
            "SELECT s.id, s.subject, s.topic, s.subtopic FROM syllabus s "
            "WHERE NOT EXISTS (SELECT 1 FROM lessons l WHERE l.subject = s.subject AND l.topic = s.topic) "
            "ORDER BY s.subject, s.topic"
        ).fetchall()

        generated = 0
        failed = 0
        errors = []

        for s in topics_to_generate:
            try:
                prompt = _LESSON_PROMPT.replace("{subject}", s["subject"]).replace(
                    "{topic}", s["topic"]
                ).replace("{subtopic}", s["subtopic"] if s["subtopic"] else "—")
                instructions = "Voce e professor do PAES/UEMA. Produza uma aula estruturada em JSON."
                raw = _ask_ai(instructions, prompt)
                data = _parse_lesson_response(raw)

                lesson_id = str(uuid.uuid4())
                title = f"{s['subject']} · {s['topic']}"

                conn.execute(
                    "DELETE FROM lessons WHERE subject=? AND topic=? AND source_type='legenda'",
                    (s["subject"], s["topic"]),
                )
                conn.execute(
                    "INSERT INTO lessons (id, title, source_type, source_ref, transcript, subject, topic, "
                    "difficulty, summary, macetes_json, keywords_json, flashcards_json, "
                    "questions_json, incidence_note, created_at) "
                    "VALUES (?, ?, 'ia_gerada', ?, ?, ?, ?, 'Media', ?, ?, ?, ?, ?, ?, ?)",
                    (
                        lesson_id, title,
                        s["subtopic"] if s["subtopic"] else "",
                        data.get("summary", ""),
                        s["subject"], s["topic"],
                        data.get("summary", ""),
                        json.dumps(data.get("macetes", []), ensure_ascii=False),
                        json.dumps(data.get("keywords", []), ensure_ascii=False),
                        json.dumps(data.get("flashcards", []), ensure_ascii=False),
                        json.dumps(data.get("questions", []), ensure_ascii=False),
                        data.get("incidenceNote", ""),
                        now_iso(),
                    ),
                )
                conn.commit()
                generated += 1
                print(f"OK: {s['subject']} :: {s['topic']}")
            except Exception as exc:
                failed += 1
                errors.append(f"{s['subject']}::{s['topic']}: {exc}")
                print(f"FAIL: {s['subject']} :: {s['topic']}: {exc}")

        total_lessons = conn.execute("SELECT COUNT(*) FROM lessons").fetchone()[0]
        total_syllabus = conn.execute("SELECT COUNT(*) FROM syllabus").fetchone()[0]

        return {
            "ok": True,
            "topicsAddedToSyllabus": added,
            "lessonsGenerated": generated,
            "lessonsFailed": failed,
            "errors": errors[:10],
            "totalSyllabus": total_syllabus,
            "totalLessons": total_lessons,
            "message": f"Topicos adicionados: {added}. Aulas geradas: {generated}. Falhas: {failed}.",
        }


if __name__ == "__main__":
    result = add_new_topics_and_generate_lessons()
    print(json.dumps(result, ensure_ascii=False, indent=2))
