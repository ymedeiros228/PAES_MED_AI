"""Rotas: redacao."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter

from api_helpers import (
    _ask_gemini,
    _ask_groq,
    _ask_openai,
    _ask_openrouter,
)
from ai_state import configured_providers
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

_ESSAY_INSTRUCTIONS = (
    "Você é um corretor de redações no espírito do PAES/UEMA. "
    "Avalie a redação do aluno e responda APENAS em JSON válido com estes campos:\n"
    "- score: nota geral (0-10, número)\n"
    "- grammar: gramática (0-10, número)\n"
    "- cohesion: coesão (0-10, número)\n"
    "- coherence: coerência (0-10, número)\n"
    "- argumentation: argumentação (0-10, número)\n"
    "- intervention: proposta de intervenção (0-10, número)\n"
    "- strengths: lista de 2-3 pontos fortes (strings)\n"
    "- improvements: lista de 2-3 pontos a melhorar (strings)\n"
    "- rewriteExample: exemplo de uma frase reescrita de forma melhor\n"
    "- grammarTip: dica curta de gramática\n"
    "- cohesionTip: dica curta de coesão\n"
    "- coherenceTip: dica curta de coerência\n"
    "- argumentationTip: dica curta de argumentação\n"
    "- interventionTip: dica curta de proposta de intervenção\n"
    "Responda SEMPRE em português. Nunca invente nota de banca oficial. "
    "Retorne apenas o JSON, sem texto adicional."
)


def _try_essay_ai(theme: str, text: str, focus: str | None, style_line: str) -> str | None:
    """Tenta corrigir a redação com o cascade de providers de IA."""
    user_content = (
        f"Tema: {theme}\n"
        f"Foco eixo: {focus or 'geral'}\n\n"
        f"Redação:\n{text}"
    )
    instructions = _ESSAY_INSTRUCTIONS + "\n" + style_line

    providers = configured_providers()
    # Cascade: gemini -> groq -> openrouter -> openai
    provider_fns = {
        "gemini": _ask_gemini,
        "groq": _ask_groq,
        "openrouter": _ask_openrouter,
        "openai": _ask_openai,
    }
    for provider in providers:
        fn = provider_fns.get(provider)
        if fn is None:
            continue
        try:
            raw = fn(instructions, user_content)
            if raw and len(raw) > 20:
                return raw
        except Exception:
            continue
    return None


@router.post("/api/essay/grade")
def api_essay_grade(payload: EssayRequest) -> dict[str, Any]:
    feedback: dict[str, Any]
    score: float
    persona = persona_by_id(payload.persona)
    focus = (payload.focusAxis or (persona or {}).get("focusAxis") or "").strip() or None
    persona_id = (persona or {}).get("id") if persona else (payload.persona or None)
    persona_label = (persona or {}).get("label") if persona else None
    style_line = ""
    if persona:
        style_line = f"Persona: {persona['label']}. Foque o eixo {persona.get('focusAxis')}. {persona.get('hint') or ''}\n"

    # Tentar cascade de IA primeiro
    raw = _try_essay_ai(payload.theme, payload.text, focus, style_line)

    if raw:
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
            feedback["note"] = "Correção com IA · não é nota de banca UEMA."
        feedback["aiProvider"] = True
    else:
        # Fallback: heurístico offline
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
                "Configure um provedor de IA em Ajustes para correção mais rica."
            ),
            "offlineHeuristic": True,
            "wordCount": heur["wordCount"],
            "paragraphCount": heur.get("paragraphCount"),
            "persona": persona_id,
            "personaLabel": persona_label,
            "focusAxis": focus,
        }
        for ax, tip in tips.items():
            feedback[f"{ax}_note"] = tip
        if focus in tips:
            feedback["missionHint"] = tips[focus]

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
