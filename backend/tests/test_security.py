"""Regressões de segurança da API local (CORS, upload e restore)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

from db import DATA_DIR  # noqa: E402
from main import app  # noqa: E402


@pytest.fixture(scope="module")
def client() -> TestClient:
    with TestClient(app) as c:
        yield c


def test_cors_libera_origem_local(client: TestClient) -> None:
    r = client.get("/health", headers={"Origin": "http://localhost:52345"})
    assert r.headers.get("access-control-allow-origin") == "http://localhost:52345"


def test_cors_bloqueia_site_externo(client: TestClient) -> None:
    r = client.get("/health", headers={"Origin": "https://site-qualquer.com"})
    assert "access-control-allow-origin" not in r.headers


def test_ingest_rejeita_path_traversal(client: TestClient) -> None:
    alvo = DATA_DIR.parent / "invadido.pdf"
    r = client.post(
        "/api/ingest/pdf?kind=prova",
        files={"file": ("../../invadido.pdf", b"%PDF-1.4 fake", "application/pdf")},
    )
    assert not alvo.exists()
    # O arquivo, se gravado, fica com o nome simples dentro de data/provas.
    salvo = DATA_DIR / "provas" / "invadido.pdf"
    if salvo.exists():
        salvo.unlink()
    assert r.status_code in (200, 500)


def test_ingest_rejeita_extensao_nao_pdf(client: TestClient) -> None:
    r = client.post(
        "/api/ingest/pdf?kind=prova",
        files={"file": ("payload.exe", b"MZ", "application/octet-stream")},
    )
    assert r.status_code == 400


def test_restore_rejeita_path_fora_de_backups(client: TestClient) -> None:
    r = client.post("/api/backup/restore", params={"path": "/etc/passwd"})
    assert r.status_code == 400


def test_restore_rejeita_folder_name_com_traversal(client: TestClient) -> None:
    r = client.post("/api/backup/restore", params={"folderName": "../../paes_med_ai.db"})
    assert r.status_code == 400
