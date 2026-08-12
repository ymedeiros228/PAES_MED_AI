"""Gera flashcards em massa para todas as questoes com gabarito."""

from __future__ import annotations

import sys
sys.path.insert(0, '.')

from db import db
from timeutil import iso_in


def generate_flashcards_bulk() -> dict:
    """Cria 1 flashcard por questao (front = enunciado, back = gabarito + resolucao)."""
    with db() as conn:
        questions = conn.execute(
            "SELECT id, subject, topic, statement, correct_index, resolution, macete, exam_board, source "
            "FROM questions WHERE correct_index IS NOT NULL ORDER BY year, subject"
        ).fetchall()

        existing_sources = {
            r[0] for r in conn.execute(
                "SELECT source FROM flashcards WHERE source LIKE 'questao:%'"
            ).fetchall()
        }

        created = 0
        skipped = 0
        for q in questions:
            source = f"questao:{q['id']}"
            if source in existing_sources:
                skipped += 1
                continue

            idx = int(q["correct_index"] or 0)
            letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
            board = (q["exam_board"] if "exam_board" in q.keys() else None) or "TREINO"
            statement = (q["statement"] or "")[:200]
            front = f"[{q['subject']}] {q['topic']}: {statement}..."

            back_parts = [f"Gabarito: {letter}"]
            mac = (q["macete"] or "").strip() if "macete" in q.keys() else ""
            if mac:
                back_parts.append(f"Macete: {mac[:200]}")
            res = (q["resolution"] or "").strip() if "resolution" in q.keys() else ""
            if res:
                back_parts.append(f"Resolucao: {res[:400]}")
            back_parts.append(f"Banca: {board}")
            back = "\n".join(back_parts)

            next_due = iso_in(1)
            conn.execute(
                "INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews) "
                "VALUES (?, ?, ?, ?, ?, ?, 0)",
                (front, back, q["subject"], q["topic"], source, next_due),
            )
            created += 1

        conn.commit()

        total = conn.execute("SELECT COUNT(*) FROM flashcards").fetchone()[0]
        return {
            "ok": True,
            "created": created,
            "skipped": skipped,
            "totalFlashcards": total,
            "message": f"Flashcards gerados: {created} novos, {skipped} ja existiam. Total: {total}.",
        }


if __name__ == "__main__":
    import json
    result = generate_flashcards_bulk()
    print(json.dumps(result, ensure_ascii=False, indent=2))
