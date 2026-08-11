"""Rotas: meta."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from ai_state import (
    configure_provider,
    provider_configured,
    provider_key,
    provider_model,
    set_provider_status,
    validate_secret,
)
from ai_state import state as ai_state
from api_helpers import (
    validate_compatible_key,
    validate_gemini_key,
    validate_openai_key,
)
from db import DATA_DIR, db
from schemas import AIProviderConfigRequest, AIProviderTestRequest
from seed import seed
from services_core import (
    curation_health,
    official_curation_inventory,
    stats_basis,
)
from services_media import (
    serper_configured,
    youtube_configured,
)

router = APIRouter(tags=["meta"])


@router.get("/")
def root() -> Any:
    # Se o build web existir, serve o SPA; caso contrário, JSON informativo.
    # meta.py está em backend/routers/, então:
    #   .parent = routers/, .parent.parent = backend/, .parent.parent.parent = repo root
    for _web in (
        Path(__file__).resolve().parent.parent.parent / "build" / "web",
        Path(__file__).resolve().parent.parent / "build" / "web",
    ):
        _idx = _web / "index.html"
        if _idx.is_file():
            return FileResponse(str(_idx))
    return {"message": "PAES MED AI API", "docs": "/docs", "health": "/health"}

@router.get("/health")
def health() -> dict[str, Any]:
    with db() as conn:
        nq = conn.execute("SELECT COUNT(*) AS c FROM questions").fetchone()["c"]
    basis = stats_basis()
    cur = official_curation_inventory()
    health_gate = curation_health()
    provas = DATA_DIR / "provas"
    gabaritos = DATA_DIR / "gabaritos"
    edital = DATA_DIR / "edital"
    return {
        "status": "ok",
        "openai_configured": provider_configured("openai"),
        "gemini_configured": provider_configured("gemini"),
        "groq_configured": provider_configured("groq"),
        "openrouter_configured": provider_configured("openrouter"),
        "youtube_configured": youtube_configured(),
        "serper_configured": serper_configured(),
        "model": provider_model("openai"),
        "gemini_model": provider_model("gemini"),
        "groq_model": provider_model("groq"),
        "openrouter_model": provider_model("openrouter"),
        "questions": nq,
        "officialCount": basis.get("officialCount", 0),
        "statsBasis": basis.get("basis"),
        "dataDir": str(DATA_DIR),
        "pdfCounts": {
            "provas": len(list(provas.glob("*.pdf"))) if provas.is_dir() else 0,
            "gabaritos": len(list(gabaritos.glob("*.pdf"))) if gabaritos.is_dir() else 0,
            "edital": (
                (len(list(edital.glob("*.pdf"))) + len(list(edital.glob("*.md")))) if edital.is_dir() else 0
            ),
        },
        "curation": {
            "realCount": cur.get("realCount", 0),
            "realPercent": cur.get("realPercent", 0),
            "crossDomainCount": cur.get("crossDomainCount", 0),
            "naturezaCount": cur.get("naturezaCount", 0),
            "naturezaReal": health_gate.get("naturezaReal"),
            "naturezaFloorOk": health_gate.get("naturezaFloorOk"),
            "status": health_gate.get("status"),
            "message": health_gate.get("message") or cur.get("message"),
            "alerts": health_gate.get("alerts") or [],
        },
    }


@router.get("/api/ai/config")
def api_ai_config() -> dict[str, Any]:
    return {"ok": True, **ai_state()}


@router.post("/api/ai/config")
def api_ai_configure(payload: AIProviderConfigRequest) -> dict[str, Any]:
    try:
        api_key = validate_secret(payload.apiKey)
        if payload.provider == "gemini":
            model = validate_gemini_key(api_key, payload.model)
        elif payload.provider in {"groq", "openrouter"}:
            model = validate_compatible_key(payload.provider, api_key, payload.model)
        else:
            model = validate_openai_key(api_key)
        configure_provider(payload.provider, api_key, payload.model or model)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {
        "ok": True,
        "message": f"Provedor {payload.provider} configurado e validado.",
        **ai_state(),
    }


@router.post("/api/ai/test")
def api_ai_test(payload: AIProviderTestRequest | None = None) -> dict[str, Any]:
    provider = payload.provider if payload and payload.provider else ai_state().get("activeProvider")
    if provider is None:
        return {
            "ok": False,
            "status": "not_configured",
            "message": "Nenhum provedor de IA está configurado.",
            **ai_state(),
        }
    try:
        if provider == "gemini":
            model = validate_gemini_key(provider_key("gemini"))
            if model != provider_model("gemini"):
                configure_provider("gemini", provider_key("gemini"), model)
        elif provider in {"groq", "openrouter"}:
            model = validate_compatible_key(provider, provider_key(provider))
            if model != provider_model(provider):
                configure_provider(provider, provider_key(provider), model)
        else:
            model = validate_openai_key(provider_key("openai"))
    except HTTPException as exc:
        detail = str(exc.detail)
        if "recusada" in detail:
            status = "key_rejected"
        elif "cota" in detail or "limite" in detail:
            status = "quota"
        elif "conectar" in detail or "alcançar" in detail:
            status = "connection"
        else:
            status = "unavailable"
        set_provider_status(provider, status)
        return {
            "ok": False,
            "status": status,
            "message": detail,
            **ai_state(),
        }
    set_provider_status(provider, "working")
    return {
        "ok": True,
        "status": "working",
        "message": f"{provider.capitalize()} funcionando com {model}.",
        **ai_state(),
    }

@router.post("/api/seed")
def api_seed(force: bool = False) -> dict[str, Any]:
    return seed(force=force)
