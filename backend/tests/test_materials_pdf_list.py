"""Testes da lista de PDFs de materiais (título vindo do banco, capas genéricas)."""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

from routers import materials  # noqa: E402


def test_pdf_list_usa_titulo_do_banco(tmp_path, monkeypatch):
    (tmp_path / "BI_BOTANICA.pdf").write_bytes(b"%PDF-1.4")
    monkeypatch.setattr(materials, "_PDF_DIR", tmp_path)
    monkeypatch.setattr(materials, "_IMG_DIR", tmp_path / "imagens")
    monkeypatch.setattr(
        materials,
        "list_pdf_metadata",
        lambda: {
            "BI_BOTANICA.pdf": {
                "title": "Botânica", "subject": "Biologia", "topic": "Botânica", "content_len": 500,
            }
        },
    )
    itens = asyncio.run(materials.list_pdfs())
    assert itens[0]["title"] == "Botânica"
    assert itens[0]["hasContent"] is True


def test_pdf_list_sem_banco_capitaliza_nome(tmp_path, monkeypatch):
    (tmp_path / "BI_CITOLOGIA_CICLO.pdf").write_bytes(b"%PDF-1.4")
    monkeypatch.setattr(materials, "_PDF_DIR", tmp_path)
    monkeypatch.setattr(materials, "_IMG_DIR", tmp_path / "imagens")
    monkeypatch.setattr(materials, "list_pdf_metadata", lambda: {})
    itens = asyncio.run(materials.list_pdfs())
    assert itens[0]["title"] == "Citologia Ciclo"
    assert itens[0]["hasContent"] is False
