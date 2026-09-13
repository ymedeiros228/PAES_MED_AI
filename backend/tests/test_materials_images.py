"""Serve capas locais em /api/materials/imagens/{filename}."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND = Path(__file__).resolve().parent.parent
ROOT = BACKEND.parent
sys.path.insert(0, str(BACKEND))

from main import app  # noqa: E402


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c


def test_serve_cover_image_ok(client: TestClient) -> None:
    img = ROOT / "data" / "materiais" / "imagens" / "bi_gene_capa.jpg"
    if not img.is_file():
        pytest.skip("capa bi_gene_capa.jpg ausente no workspace")
    r = client.get("/api/materials/imagens/bi_gene_capa.jpg")
    assert r.status_code == 200, r.text
    assert r.headers["content-type"].startswith("image/")
    assert len(r.content) > 100


def test_serve_cover_image_bloqueia_traversal(client: TestClient) -> None:
    r = client.get("/api/materials/imagens/..%2F..%2Fetc%2Fpasswd")
    assert r.status_code in (400, 404)


def test_serve_cover_image_rejeita_extensao(client: TestClient) -> None:
    r = client.get("/api/materials/imagens/readme.txt")
    assert r.status_code == 400


def test_pdf_list_inclui_cover_url(client: TestClient) -> None:
    r = client.get("/api/materials/pdf-list")
    assert r.status_code == 200
    data = r.json()
    assert isinstance(data, list)
    if not data:
        pytest.skip("sem PDFs em data/materiais")
    with_cover = [p for p in data if p.get("coverUrl")]
    assert with_cover, "esperado ao menos um PDF com capa mapeada"
    assert with_cover[0]["coverUrl"].startswith("/api/materials/imagens/")
    cover = client.get(with_cover[0]["coverUrl"])
    assert cover.status_code == 200
    assert cover.headers["content-type"].startswith("image/")
