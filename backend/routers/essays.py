"""Rotas: redacao."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter

from api_helpers import (
    _ask_openai,
    _openai_client,
)
from schemas import EssayRequest
from services_extra import (
    essay_grade_deltas,
    essay_progress,
    essay_themes,
    list_essays,
    offline_essay_axis_scores,
    save_essay,
)
from services_media import (
    essay_personas,
    persona_by_id,
)

router = APIRouter(tags=["redacao"])


@router.get("/api/essay/themes")
def api_essay_themes() -> list[str]:
    return essay_themes()

@router.get("/api/essays/personas")
def api_essays_personas() -> dict[str, Any]:
    return {"ok": True, "items": essay_personas(), "disclaimer": "Personas = prompts locais · treino, não banca."}

@router.post("/api/essay/grade")
def api_essay_grade(payload: EssayRequest) -> dict[str, Any]:
    client = _openai_client()
    feedback: dict[str, Any]
    score: float
    persona = persona_by_id(payload.persona)
    focus = (payload.focusAxis or (persona or {}).get("focusAxis") or "").strip() or None
    persona_id = (persona or {}).get("id") if persona else (payload.persona or None)
    persona_label = (persona or {}).get("label") if persona else None
    style_line = ""
    if persona:
        style_line = f"Persona: {persona['label']}. Foque o eixo {persona.get('focusAxis')}. {persona.get('hint') or ''}\n"
    if client is None:
        heur = offline_essay_axis_scores(payload.theme, payload.text)
        score = float(heur["score"])
        scores = heur["scores"]
        tips = heur["tips"]
        feedback = {
            **scores,
            "scores": scores,
            "tips": tips,
            "grammarTip": tips["grammar"],
            "cohesionTip": tips["cohesion"],
            "coherenceTip": tips["coherence"],
            "argumentationTip": tips["argumentation"],
            "interventionTip": tips["intervention"],
            "note": (
                "Rascunho offline por eixos (0–10) — NÃO é nota de banca UEMA. "
                "Configure OpenAI para correção mais rica."
            ),
            "offlineHeuristic": True,
            "wordCount": heur["wordCount"],
            "paragraphCount": heur.get("paragraphCount"),
            "persona": persona_id,
            "personaLabel": persona_label,
            "focusAxis": focus,
        }
        # Manter strings de leitura humana nos eixos também (UI antiga)
        for ax, tip in tips.items():
            feedback[f"{ax}_note"] = tip
        if focus in tips:
            feedback["missionHint"] = tips[focus]
    else:
        raw = _ask_openai(
            "Você corrige redações no espírito do PAES/UEMA. Responda JSON com "
            "score (0-10), grammar, cohesion, coherence, argumentation, intervention "
            "(números 0-10), strengths, improvements, tips opcional por eixo. "
            "Nunca invente nota de banca oficial. " + style_line,
            f"Tema: {payload.theme}\nFoco eixo: {focus or 'geral'}\n\nRedação:\n{payload.text}",
        )
        try:
            start = raw.find("{")
            end = raw.rfind("}") + 1
            feedback = json.loads(raw[start:end])
            score = float(feedback.get("score", 7))
        except Exception:
            score = 7.0
            feedback = {"raw": raw, "note": "Não foi possível parsear JSON; segue texto bruto."}
        feedback = dict(feedback) if isinstance(feedback, dict) else {"raw": feedback}
        feedback["persona"] = persona_id
        feedback["personaLabel"] = persona_label
        feedback["focusAxis"] = focus
        if "note" not in feedback:
            feedback["note"] = "Treino local com IA · não é nota de banca UEMA."
    saved = save_essay(payload.theme, payload.text, feedback, score)
    deltas = essay_grade_deltas(payload.theme, feedback if isinstance(feedback, dict) else {})
    out = dict(saved)
    out["deltas"] = deltas
    out["disclaimer"] = "Treino local · não banca UEMA."
    return out

@router.get("/api/essays")
def api_essays() -> list[dict[str, Any]]:
    return list_essays()

@router.get("/api/essays/progress")
def api_essays_progress() -> dict[str, Any]:
    """Progresso agregado de redação local (Ciclo AT/BB/HQ) — sem fingir nota UEMA."""
    return essay_progress()
