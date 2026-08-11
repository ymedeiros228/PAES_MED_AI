"""Testes: servir front web (SPA) + API 404 JSON."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient


@pytest.fixture()
def client(tmp_path, monkeypatch) -> TestClient:
    monkeypatch.setenv("PAES_DATA_DIR", str(tmp_path))
    import importlib

    import main as main_mod

    importlib.reload(main_mod)
    c = TestClient(main_mod.app)
    c.__enter__()
    yield c
    c.__exit__(None, None, None)


def test_api_404_devolve_json_nao_html(client: TestClient) -> None:
    """Rotas /api/ inexistentes devolvem JSON 404, não HTML do SPA."""
    r = client.get("/api/nonexistent")
    assert r.status_code == 404
    assert "detail" in r.json()


def test_health_sempre_json(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert "status" in data
    assert "questions" in data


def test_docs_disponivel(client: TestClient) -> None:
    r = client.get("/docs")
    assert r.status_code == 200
