"""Rotas: simulados."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter

from schemas import (
    GradeRequest,
    ScheduleGapsRequest,
    SimCheckpointRequest,
    SimulationRequest,
)
from services_extra import (
    clear_sim_checkpoint,
    create_simulation,
    get_sim_checkpoint,
    grade_simulation,
    save_sim_checkpoint,
    schedule_gap_revisions,
)

router = APIRouter(tags=["simulados"])


@router.post("/api/simulations")
def api_simulations(payload: SimulationRequest) -> dict[str, Any]:
    return create_simulation(
        payload.mode,
        payload.subject,
        payload.topic,
        payload.difficulty,
        payload.year,
        payload.limit,
        payload.exam_minutes,
    )

@router.post("/api/simulations/grade")
def api_simulations_grade(payload: GradeRequest) -> dict[str, Any]:
    return grade_simulation(payload.answers)

@router.get("/api/sim/checkpoint")
def api_sim_checkpoint_get() -> dict[str, Any]:
    data = get_sim_checkpoint()
    return {"checkpoint": data}

@router.post("/api/sim/checkpoint")
def api_sim_checkpoint_save(payload: SimCheckpointRequest) -> dict[str, Any]:
    return save_sim_checkpoint(payload.model_dump())

@router.delete("/api/sim/checkpoint")
def api_sim_checkpoint_clear() -> dict[str, Any]:
    return clear_sim_checkpoint()

@router.post("/api/simulations/schedule-gaps")
def api_schedule_gaps(payload: ScheduleGapsRequest) -> dict[str, Any]:
    return schedule_gap_revisions(payload.gaps)
