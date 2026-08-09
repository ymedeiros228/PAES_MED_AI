"""Rotas: flashcards."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException

from schemas import (
    FlashcardCreate,
    FlashcardReview,
    FlashcardsFromQuestionRequest,
)
from services_advanced import (
    create_flashcard,
    delete_flashcard,
    list_flashcards,
    review_flashcard,
)
from services_core import get_question

router = APIRouter(tags=["flashcards"])


@router.get("/api/flashcards")
def api_flashcards(dueOnly: bool = False, axesOnly: bool = False) -> list[dict[str, Any]]:
    return list_flashcards(due_only=dueOnly, axes_only=axesOnly)

@router.post("/api/flashcards")
def api_flashcards_create(payload: FlashcardCreate) -> dict[str, Any]:
    return create_flashcard(payload.front, payload.back, payload.subject, payload.topic)

@router.post("/api/flashcards/{card_id}/review")
def api_flashcards_review(card_id: int, payload: FlashcardReview) -> dict[str, Any]:
    return review_flashcard(card_id, payload.remembered)

@router.delete("/api/flashcards/{card_id}")
def api_flashcards_delete(card_id: int) -> dict[str, Any]:
    return delete_flashcard(card_id)

@router.post("/api/flashcards/from-question")
def api_flashcards_from_question(payload: FlashcardsFromQuestionRequest) -> dict[str, Any]:
    """Cards leves a partir da resolução — prioriza 4 eixos se real (Ciclo AG)."""
    question = get_question(payload.questionId)
    if not question:
        raise HTTPException(404, "Questão não encontrada")
    cards = []
    from_axes = False
    axes = question.get("resolutionAxes") or (question.get("professorMode") or {}).get("resolutionAxes") or {}
    quality = question.get("resolutionQuality") or (question.get("professorMode") or {}).get("resolutionQuality")
    subj = question.get("subject") or "Geral"
    topic = question.get("topic") or "Tópico"
    qid = question["id"]
    axis_pairs = [
        ("Comando (eixo)", axes.get("comando"), "Gabarito (eixo)", axes.get("gabarito")),
        ("Conceito (eixo)", axes.get("conceito"), "Distrator (eixo)", axes.get("distrator")),
    ]
    if quality == "real" and any(axes.get(k) for k in ("comando", "conceito", "gabarito", "distrator")):
        for front_l, front, back_l, back in axis_pairs:
            if not front and not back:
                continue
            if front and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {front_l}",
                        str(front),
                        subj,
                        topic,
                        source=f"axis:{qid}",
                    )
                )
                from_axes = True
            if back and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {back_l}",
                        str(back),
                        subj,
                        topic,
                        source=f"axis:{qid}",
                    )
                )
                from_axes = True
            if len(cards) >= payload.count:
                break
    if not cards:
        sources = [
            ("Resolução", question.get("resolution") or question.get("professorMode", {}).get("resolution")),
            ("Macete", question.get("macete") or question.get("professorMode", {}).get("macete")),
            ("Pegadinha", question.get("pegadinha") or question.get("professorMode", {}).get("pegadinha")),
            ("Intenção da banca", question.get("bancaIntent") or question.get("professorMode", {}).get("bancaIntent")),
            (
                "Tópicos relacionados",
                ", ".join(question.get("relatedTopics") or question.get("professorMode", {}).get("relatedTopics", []))
                or topic,
            ),
        ]
        for label, content in sources:
            if content and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {label}",
                        str(content),
                        subj,
                        topic,
                        source=f"question:{qid}",
                    )
                )
    return {
        "ok": True,
        "questionId": qid,
        "created": len(cards),
        "cards": cards,
        "fromAxes": from_axes,
        "note": "Cartões didáticos locais — não oficiais da banca.",
    }
