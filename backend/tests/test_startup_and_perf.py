"""Startup em background + logging (main.py) e caches de desempenho."""

from __future__ import annotations

import logging
import sys
import threading
import time
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

import main  # noqa: E402
import services_core  # noqa: E402


def test_startup_pesado_roda_em_background(monkeypatch: pytest.MonkeyPatch) -> None:
    done = threading.Event()

    def slow_heavy() -> None:
        time.sleep(0.5)
        done.set()

    monkeypatch.delenv("PAES_STARTUP_SYNC", raising=False)
    monkeypatch.setattr(main, "_startup_heavy", slow_heavy)
    t0 = time.perf_counter()
    main._run_startup()
    assert time.perf_counter() - t0 < 0.45, "startup não deveria esperar o trabalho pesado"
    assert done.wait(5), "tarefa de background não terminou"


def test_startup_sync_quando_pedido(monkeypatch: pytest.MonkeyPatch) -> None:
    calls: list[str] = []
    monkeypatch.setenv("PAES_STARTUP_SYNC", "1")
    monkeypatch.setattr(main, "_startup_heavy", lambda: calls.append("x"))
    main._run_startup()
    assert calls == ["x"]


def test_falha_no_startup_vai_para_o_log(monkeypatch: pytest.MonkeyPatch, caplog: pytest.LogCaptureFixture) -> None:
    import ingest_pdf
    import services_advanced

    def boom(*_a, **_k):
        raise RuntimeError("falha de teste no índice")

    monkeypatch.setattr(services_advanced, "index_all_questions", boom)
    monkeypatch.setattr(ingest_pdf, "sanitize_questions_full", lambda: {"statements": 0, "options": 0})
    monkeypatch.setenv("PAES_AUTO_BACKUP", "0")
    monkeypatch.delenv("PAES_BOOTSTRAP_PROD", raising=False)
    with caplog.at_level(logging.INFO, logger="paes"):
        main._startup_heavy()  # não pode propagar
    assert any("falha de teste no índice" in (r.exc_text or "") or r.exc_info for r in caplog.records)
    assert any("Indexação local" in r.getMessage() for r in caplog.records)


def test_predict_topic_usa_basis_recebido(monkeypatch: pytest.MonkeyPatch) -> None:
    def fail() -> dict:
        raise AssertionError("stats_basis não deveria ser chamado")

    monkeypatch.setattr(services_core, "stats_basis", fail)
    match = {
        "subject": "Biologia",
        "topic": "Genética",
        "frequency": 3,
        "yearsSinceLast": 1,
        "avgGap": 2.0,
        "years": [2020, 2022, 2024],
        "lastYear": 2024,
    }
    out = services_core.predict_topic("Biologia", "Genética", match, None, "oficial")
    assert out["priorityScore"] > 0


def test_cache_de_pdfs_de_prova_invalida_ao_mudar_pasta(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(services_core, "DATA_DIR", tmp_path)
    provas = tmp_path / "provas"
    provas.mkdir()
    assert services_core.resolve_prova_pdf(2019) is None
    (provas / "paes_2019.pdf").write_bytes(b"%PDF-1.4")
    # força mtime diferente mesmo em FS com resolução grosseira
    import os

    st = provas.stat()
    os.utime(provas, ns=(st.st_atime_ns, st.st_mtime_ns + 10_000_000))
    found = services_core.resolve_prova_pdf(2019)
    assert found is not None and found.name == "paes_2019.pdf"
