"""Rotas: materiais de estudo com IA + imagens da Wikipedia PT + PDFs."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel

from material_service import (
    delete_material,
    generate_material,
    get_material,
    list_materials,
    list_syllabus_with_status,
)

router = APIRouter(prefix="/api/materials", tags=["materiais"])

# Diretório de PDFs gerados
_PDF_DIR = Path(__file__).resolve().parent.parent.parent / "data" / "materiais"


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


@router.get("/pdf-list")
async def list_pdfs() -> list[dict[str, Any]]:
    """Lista todos os PDFs disponíveis na pasta de materiais."""
    if not _PDF_DIR.exists():
        return []
    pdfs = []
    for f in sorted(_PDF_DIR.glob("*.pdf")):
        # Decodificar nome: BI_CITOLOGIA_MEMBRANA_PLASMATICA.pdf
        name = f.stem
        parts = name.split("_", 1)
        subject_code = parts[0] if parts else ""
        title = parts[1].replace("_", " ") if len(parts) > 1 else name
        subject_map = {"BI": "Biologia", "QU": "Química", "FI": "Física",
                       "MT": "Matemática", "PT": "Português", "HIS": "História",
                       "GEO": "Geografia", "FIL": "Filosofia", "SOC": "Sociologia",
                       "ING": "Inglês", "ESP": "Espanhol"}
        subject = subject_map.get(subject_code, subject_code)
        pdfs.append({
            "filename": f.name,
            "title": title,
            "subject": subject,
            "size_kb": round(f.stat().st_size / 1024, 1),
            "url": f"/api/materials/pdf/{f.name}",
        })
    return pdfs


@router.get("/pdf/{filename}")
async def download_pdf(filename: str):
    """Serve um PDF gerado pelo sistema."""
    # Sanitizar nome do arquivo (sem path traversal)
    safe = Path(filename).name
    if not safe.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser PDF.")
    pdf_path = _PDF_DIR / safe
    if not pdf_path.exists():
        raise HTTPException(status_code=404, detail="PDF não encontrado.")
    return FileResponse(
        str(pdf_path),
        media_type="application/pdf",
        filename=safe,
    )


@router.post("/open-pdf")
async def open_pdf(filename: str = Query(...)) -> dict[str, Any]:
    """Abre um PDF no visualizador padrao do sistema (desktop)."""
    import os
    safe = Path(filename).name
    if not safe.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser PDF.")
    pdf_path = _PDF_DIR / safe
    if not pdf_path.exists():
        raise HTTPException(status_code=404, detail="PDF não encontrado.")
    try:
        if os.name == "nt":
            os.startfile(str(pdf_path))  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess
            subprocess.Popen(["open", str(pdf_path)])
        else:
            import subprocess
            subprocess.Popen(["xdg-open", str(pdf_path)])
        return {"ok": True, "path": str(pdf_path)}
    except Exception as e:
        return {"ok": False, "error": str(e)}


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
