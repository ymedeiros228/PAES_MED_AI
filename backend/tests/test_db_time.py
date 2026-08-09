"""Conexão SQLite com fechamento garantido e relógio único."""

from __future__ import annotations

import sqlite3
import sys
from datetime import datetime, timedelta
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

from db import db  # noqa: E402
from timeutil import file_stamp, iso_in, now, now_iso, today, today_iso  # noqa: E402


def test_db_fecha_a_conexao_no_fim_do_bloco() -> None:
    with db() as conn:
        conn.execute("SELECT 1")
    with pytest.raises(sqlite3.ProgrammingError):
        conn.execute("SELECT 1")


def test_db_fecha_a_conexao_mesmo_com_erro() -> None:
    with pytest.raises(RuntimeError), db() as conn:
        raise RuntimeError("falha no meio da query")
    with pytest.raises(sqlite3.ProgrammingError):
        conn.execute("SELECT 1")


def test_carimbos_sao_comparaveis_como_string() -> None:
    # O banco guarda ISO local sem offset: ordenação de string == ordenação de tempo.
    assert now_iso() < iso_in(1)
    assert iso_in(-1) < now_iso()
    assert datetime.fromisoformat(now_iso()).tzinfo is None


def test_relogio_local_coerente() -> None:
    assert today() == now().date()
    assert today_iso() == today().isoformat()
    assert datetime.fromisoformat(iso_in(3)) - now() > timedelta(days=2)
    assert len(file_stamp()) == len("20260807_093000")
