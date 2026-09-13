"""Rotas: materiais de estudo com IA + imagens da Wikipedia PT + PDFs."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel

from db import DATA_DIR
from material_service import (
    delete_material,
    generate_material,
    get_material,
    list_materials,
    list_syllabus_with_status,
)

router = APIRouter(prefix="/api/materials", tags=["materiais"])

# Diretório de PDFs gerados — usa DATA_DIR (respeita PAES_DATA_DIR no PyInstaller).
_PDF_DIR = DATA_DIR / "materiais"
_IMG_DIR = _PDF_DIR / "imagens"
_IMG_EXT = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
_IMG_MEDIA = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".gif": "image/gif",
    ".webp": "image/webp",
}


class GenerateRequest(BaseModel):
    subject: str
    topic: str
    subtopic: str | None = None
    force: bool = False


def _cover_for_stem(stem: str) -> str | None:
    """Resolve filename de capa a partir do stem do PDF (ex.: BI_GENETICA)."""
    from pdf_cover_map import PDF_TO_COVER

    prefix = PDF_TO_COVER.get(stem.upper())
    if not prefix or not _IMG_DIR.exists():
        return None
    matches = sorted(p for p in _IMG_DIR.glob(f"{prefix}*") if p.suffix.lower() in _IMG_EXT)
    return matches[0].name if matches else None


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
        cover = _cover_for_stem(name)
        pdfs.append({
            "filename": f.name,
            "title": title,
            "subject": subject,
            "size_kb": round(f.stat().st_size / 1024, 1),
            "url": f"/api/materials/pdf/{f.name}",
            "coverUrl": f"/api/materials/imagens/{cover}" if cover else None,
            "coverFilename": cover,
        })
    return pdfs


@router.get("/pdf/{filename}/cover")
async def pdf_cover_image(filename: str):
    """Serve a capa associada a um PDF (mesmo mapa das imagens de materiais)."""
    safe = Path(filename).name
    if not safe.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Arquivo deve ser PDF.")
    cover = _cover_for_stem(Path(safe).stem)
    if not cover:
        raise HTTPException(status_code=404, detail="Capa não encontrada.")
    img_path = (_IMG_DIR / cover).resolve()
    try:
        img_path.relative_to(_IMG_DIR.resolve())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Caminho inválido.") from exc
    if not img_path.is_file():
        raise HTTPException(status_code=404, detail="Capa não encontrada.")
    suffix = img_path.suffix.lower()
    return FileResponse(
        str(img_path),
        media_type=_IMG_MEDIA.get(suffix, "application/octet-stream"),
        filename=cover,
    )


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


@router.get("/imagens/{filename}")
async def serve_cover_image(filename: str):
    """Serve capa/diagrama local de `data/materiais/imagens` (flashcards + UI)."""
    safe = Path(filename).name
    suffix = Path(safe).suffix.lower()
    if suffix not in _IMG_EXT:
        raise HTTPException(status_code=400, detail="Formato de imagem não suportado.")
    img_path = (_IMG_DIR / safe).resolve()
    try:
        img_path.relative_to(_IMG_DIR.resolve())
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Caminho inválido.") from exc
    if not img_path.is_file():
        raise HTTPException(status_code=404, detail="Imagem não encontrada.")
    return FileResponse(
        str(img_path),
        media_type=_IMG_MEDIA.get(suffix, "application/octet-stream"),
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
        raise HTTPException(status_code=503, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao gerar material: {e}") from e


@router.delete("/{material_id}")
async def delete_material_route(material_id: str) -> dict[str, Any]:
    """Remove um material gerado."""
    deleted = delete_material(material_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Material não encontrado.")
    return {"ok": True, "deleted": material_id}
