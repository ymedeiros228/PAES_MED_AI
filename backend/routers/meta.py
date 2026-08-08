"""Rotas: meta."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter

from config import (
    GEMINI_API_KEY,
    GEMINI_MODEL,
    OPENAI_API_KEY,
    OPENAI_MODEL,
)
from db import DATA_DIR, db
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
def root() -> dict[str, str]:
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
        "openai_configured": bool(OPENAI_API_KEY and OPENAI_API_KEY != "cole_sua_chave_aqui"),
        "gemini_configured": bool(GEMINI_API_KEY and GEMINI_API_KEY != "cole_sua_chave_aqui"),
        "youtube_configured": youtube_configured(),
        "serper_configured": serper_configured(),
        "model": OPENAI_MODEL,
        "gemini_model": GEMINI_MODEL,
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

@router.post("/api/seed")
def api_seed(force: bool = False) -> dict[str, Any]:
    return seed(force=force)
