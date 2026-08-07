"""Rotas: estatisticas."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter

from db import DATA_DIR
from schemas import (
    CurationPromoteRequest,
    GapRecoverRequest,
)
from services_core import (
    bank_profile,
    curation_health,
    dashboard_stats,
    medicine_priority,
    official_axle_health,
    official_curation_inventory,
    predict_topic,
    promote_all_pending_officials,
    promote_natureza_real_resolutions,
    promote_other_axles_real_resolutions,
    stats_basis,
    topic_cooccurrence,
    topic_frequency,
)
from services_extra import (
    list_study_gaps,
    progress_overview,
    recover_study_gap,
    remediation_for,
)

router = APIRouter(tags=["estatisticas"])


@router.get("/api/stats/frequency")
def api_frequency() -> list[dict[str, Any]]:
    return topic_frequency()

@router.get("/api/stats/medicine")
def api_medicine() -> dict[str, Any]:
    inv = official_curation_inventory()
    return {
        "items": medicine_priority(),
        "statsBasis": stats_basis(),
        "curation": {
            "realCount": inv.get("realCount"),
            "realPercent": inv.get("realPercent"),
            "crossDomainCount": inv.get("crossDomainCount"),
            "naturezaCount": inv.get("naturezaCount"),
            "naturezaBySubject": inv.get("naturezaBySubject"),
            "resolutionQuality": inv.get("resolutionQuality"),
            "message": inv.get("message"),
        },
    }

@router.get("/api/curation/inventory")
def api_curation_inventory() -> dict[str, Any]:
    return official_curation_inventory()

@router.get("/api/curation/health")
def api_curation_health() -> dict[str, Any]:
    """Gate anti-regressão Natureza + contagens honestas (Ciclo D)."""
    return curation_health()

@router.post("/api/curation/promote-natureza-real")
def api_curation_promote_natureza(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Eleva floor de resoluções Natureza para quality=real (didático local)."""
    limit = (payload.limit if payload is not None else 8)
    return promote_natureza_real_resolutions(limit=limit)

@router.post("/api/curation/promote-other-real")
def api_curation_promote_other(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Floor leve oficiais fora de Natureza — não mexe na Natureza (Ciclo D)."""
    limit = (payload.limit if payload is not None else 12)
    return promote_other_axles_real_resolutions(limit=limit)

@router.post("/api/curation/promote-all-pending")
def api_curation_promote_all(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Natureza primeiro, depois outras áreas (Ciclo E)."""
    limit = (payload.limit if payload is not None else 40)
    return promote_all_pending_officials(limit=limit)

@router.get("/api/curation/axles")
def api_curation_axles() -> dict[str, Any]:
    return official_axle_health()

@router.get("/api/stats/bank-profile")
def api_bank_profile() -> dict[str, Any]:
    return bank_profile()

@router.post("/api/stats/bank-profile/export")
def api_bank_profile_export() -> dict[str, Any]:
    profile = bank_profile()
    basis = stats_basis()
    destination = DATA_DIR / "perfil_banca.md"
    years_used: list[int] = []
    heat = profile.get("heatmap") or {}
    for years in heat.values():
        for y in years:
            try:
                years_used.append(int(y))
            except (TypeError, ValueError):
                pass
    years_used = sorted(set(years_used))
    lines = [
        "# Como a UEMA cobra — perfil da banca (operacional)",
        "",
        f"Base usada: **{profile.get('basis', 'treino')}** · oficiais={basis.get('officialCount', 0)} · treino={basis.get('trainingCount', 0)}.",
        f"Anos na amostra: {', '.join(map(str, years_used)) or '—'}.",
        profile.get("disclaimer", ""),
        "",
        f"- Questões analisadas: {profile.get('totalQuestions', 0)}",
        f"- Tamanho médio do enunciado: {profile.get('avgStatementLen', 0)}",
        f"- Viés de gabarito (A–E): {json.dumps(profile.get('correctLetterBias', {}), ensure_ascii=False)}",
        f"- Verbos mais comuns: {json.dumps(profile.get('topVerbs', [])[:10], ensure_ascii=False)}",
        f"- Distribuição por disciplina: {json.dumps(profile.get('subjectDistribution', {}), ensure_ascii=False)}",
        f"- Dificuldade: {json.dumps(profile.get('difficultyDistribution', {}), ensure_ascii=False)}",
        "",
        "## Coocorrência de tópicos",
    ]
    lines.extend(
        f"- {item['a']} × {item['b']}: {item['count']}"
        for item in profile.get("cooccurrence", [])
    )
    lines.extend(["", "## Heatmap (disciplina × ano)", ""])
    for subject, years in sorted(heat.items()):
        lines.append(f"- **{subject}**: {json.dumps(years, ensure_ascii=False)}")
    lines.extend(
        [
            "",
            "---",
            "Estimativa local — não inventa incidência sem PDF oficial commitado.",
        ]
    )
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return {
        "ok": True,
        "path": str(destination),
        "basis": profile.get("basis"),
        "yearsUsed": years_used,
        "statsBasis": basis,
    }

@router.get("/api/stats/cooccurrence")
def api_cooccurrence(limit: int = 20) -> dict[str, Any]:
    return {"items": topic_cooccurrence(limit=max(1, min(limit, 100))), "statsBasis": stats_basis()}

@router.get("/api/stats/basis")
def api_stats_basis() -> dict[str, Any]:
    return stats_basis()

@router.get("/api/stats/predict")
def api_predict(subject: str, topic: str) -> dict[str, Any]:
    return predict_topic(subject, topic)

@router.get("/api/dashboard")
def api_dashboard() -> dict[str, Any]:
    return dashboard_stats()

@router.get("/api/remediation")
def api_remediation(errorType: str = "conceito", subject: str = "", topic: str = "") -> dict[str, Any]:
    return remediation_for(errorType, subject, topic)

@router.get("/api/gaps")
def api_gaps(status: str = "open", limit: int = 40) -> dict[str, Any]:
    return list_study_gaps(status=status, limit=limit)

@router.post("/api/gaps/recover")
def api_gaps_recover(payload: GapRecoverRequest) -> dict[str, Any]:
    return recover_study_gap(payload.subject, payload.topic)

@router.get("/api/curation/dirty-labels")
def api_curation_dirty_labels(limit: int = 40) -> dict[str, Any]:
    from services_core import list_dirty_labels

    return list_dirty_labels(limit=max(1, min(int(limit or 40), 80)))

@router.get("/api/progress/overview")
def api_progress_overview() -> dict[str, Any]:
    """Painel Relevo — cola dashboard + redação + gaps (Ciclo HR)."""
    return progress_overview()
