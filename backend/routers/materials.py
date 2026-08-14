"""Rotas: materiais de estudo com IA + imagens da Wikipedia PT."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from material_service import (
    delete_material,
    generate_material,
    get_material,
    list_materials,
    list_syllabus_with_status,
)

router = APIRouter(prefix="/api/materials", tags=["materiais"])


class GenerateRequest(BaseModel):
    subject: str
    topic: str
    subtopic: str | None = None
    force: bool = False


@router.get("/syllabus")
async def get_syllabus(subject: str | None = Query(None)) -> list[dict[str, Any]]:
    """Lista o conteúdo programático com status de material gerado."""
    return list_syllabus_with_status(subject)


@router.get("/list")
async def list_all_materials(subject: str | None = Query(None)) -> list[dict[str, Any]]:
    """Lista todos os materiais já gerados."""
    return list_materials(subject)


@router.get("/{subject}/{topic}")
async def get_material_route(
    subject: str,
    topic: str,
    subtopic: str | None = Query(None),
) -> dict[str, Any]:
    """Recupera material já gerado para um tópico."""
    material = get_material(subject, topic, subtopic)
    if not material:
        raise HTTPException(status_code=404, detail="Material não gerado ainda.")
    return material


@router.post("/generate")
async def generate_material_route(req: GenerateRequest) -> dict[str, Any]:
    """Gera material de estudo: teoria via IA + imagens da Wikipedia PT."""
    try:
        result = await generate_material(
            subject=req.subject,
            topic=req.topic,
            subtopic=req.subtopic,
            force=req.force,
        )
        return result
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar material: {e}")


@router.delete("/{material_id}")
async def delete_material_route(material_id: str) -> dict[str, Any]:
    """Remove um material gerado."""
    deleted = delete_material(material_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Material não encontrado.")
    return {"ok": True, "deleted": material_id}
