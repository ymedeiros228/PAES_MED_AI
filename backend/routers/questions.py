"""Rotas: questoes."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter, HTTPException

from db import db
from schemas import (
    AnswerRequest,
    ApprovalRequest,
    GenerateQuestionRequest,
    UpdateQuestionRequest,
)
from services_core import (
    get_question,
    list_questions,
)
from services_extra import (
    generate_similar_question_stub,
    record_answer,
)

router = APIRouter(tags=["questoes"])


@router.get("/api/questions")
def api_questions(
    subject: str | None = None,
    topic: str | None = None,
    year: int | None = None,
    difficulty: str | None = None,
    medicine: bool = False,
    source: str | None = None,
    examBoard: str | None = None,
    similares: bool = False,
    approved: str | None = None,
    officialWithGab: bool = False,
    limit: int | None = 200,
    offset: int = 0,
) -> list[dict[str, Any]]:
    approved_only: bool | None = None
    if approved == "1" or approved == "true":
        approved_only = True
    elif approved == "0" or approved == "false":
        approved_only = False
    # Ciclo HL: chip «Só oficiais com gab» = UEMA + fonte PDF/ingest
    if officialWithGab:
        examBoard = "UEMA_PAES"
        source = source or "oficial"
    return list_questions(
        subject,
        topic,
        year,
        difficulty,
        medicine,
        source_kind=source,
        exam_board=examBoard,
        similares_only=similares,
        approved_only=approved_only,
        limit=limit,
        offset=offset,
    )


@router.get("/api/approval/pending")
def api_questions_pending(limit: int = 50) -> list[dict[str, Any]]:
    return list_questions(approved_only=False, limit=limit)


@router.post("/api/approval/decide")
def api_questions_approve(payload: ApprovalRequest) -> dict[str, Any]:
    with db() as conn:
        row = conn.execute("SELECT id FROM questions WHERE id=?", (payload.questionId,)).fetchone()
        if not row:
            raise HTTPException(404, "Questão não encontrada")
        if payload.approve:
            conn.execute("UPDATE questions SET approved=1 WHERE id=?", (payload.questionId,))
            conn.commit()
            return {"ok": True, "questionId": payload.questionId, "approved": True}
        conn.execute("DELETE FROM questions WHERE id=?", (payload.questionId,))
        conn.commit()
        return {"ok": True, "questionId": payload.questionId, "deleted": True}


@router.get("/api/questions/{question_id}")
def api_question(question_id: str) -> dict[str, Any]:
    q = get_question(question_id)
    if not q:
        raise HTTPException(404, "Questão não encontrada")
    return q


@router.patch("/api/questions/{question_id}")
def api_patch_question(question_id: str, payload: UpdateQuestionRequest) -> dict[str, Any]:
    """Curadoria: edita enunciado, alternativas A–E, gabarito e meta."""
    with db() as conn:
        row = conn.execute("SELECT * FROM questions WHERE id=?", (question_id,)).fetchone()
        if not row:
            raise HTTPException(404, "Questão não encontrada")

        fields: dict[str, Any] = {}
        if payload.statement is not None:
            stmt = payload.statement.strip()
            if len(stmt) < 5:
                raise HTTPException(400, "Enunciado muito curto")
            fields["statement"] = stmt
            fields["avg_text_len"] = len(stmt)

        if payload.options is not None:
            opts = [str(o or "").strip() for o in payload.options]
            if len(opts) != 5:
                raise HTTPException(400, "Envie exatamente 5 alternativas (A–E)")
            if sum(1 for o in opts if o) < 2:
                raise HTTPException(400, "Pelo menos 2 alternativas precisam de texto")
            fields["options_json"] = json.dumps(opts, ensure_ascii=False)

        if payload.correctIndex is not None:
            fields["correct_index"] = int(payload.correctIndex)

        if payload.subject is not None:
            fields["subject"] = payload.subject.strip()
        if payload.topic is not None:
            fields["topic"] = payload.topic.strip()

        if not fields:
            raise HTTPException(400, "Nada para atualizar")

        final_opts = (
            json.loads(fields["options_json"])
            if "options_json" in fields
            else json.loads(row["options_json"] or "[]")
        )
        final_ci = fields.get("correct_index", int(row["correct_index"] or 0))
        if final_ci < 0 or final_ci >= max(len(final_opts), 1):
            raise HTTPException(400, "correctIndex fora do intervalo das alternativas")

        sets = ", ".join(f"{k}=?" for k in fields)
        conn.execute(
            f"UPDATE questions SET {sets} WHERE id=?",
            (*fields.values(), question_id),
        )
        conn.commit()

    q = get_question(question_id)
    return {"ok": True, "question": q, "message": "Questão atualizada."}


@router.get("/api/syllabus")
def api_syllabus() -> list[dict[str, Any]]:
    with db() as conn:
        return [dict(r) for r in conn.execute("SELECT * FROM syllabus ORDER BY subject, topic").fetchall()]


@router.post("/api/answers")
def api_answers(payload: AnswerRequest) -> dict[str, Any]:
    return record_answer(
        payload.questionId,
        payload.correct,
        payload.subject,
        payload.topic,
        payload.errorType,
        payload.timeMs,
    )


@router.post("/api/questions/generate-similar")
def api_generate_similar(payload: GenerateQuestionRequest) -> dict[str, Any]:
    return generate_similar_question_stub(payload.topic, payload.subject)
