"""Progresso separado por conta (versão web) e estabilidade com o banco fora do ar.

Sem Postgres de verdade: a conexão bruta é um dublê que registra o SQL recebido.
"""

from __future__ import annotations

from typing import Any

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import auth
import db
from db import PgConnection


class _CursorFalso:
    description = None
    rowcount = 0

    def __init__(self, log: list[tuple[str, Any]]) -> None:
        self._log = log

    def execute(self, sql: str, params: Any = None) -> None:
        self._log.append((sql, params))

    def executemany(self, sql: str, seq: Any) -> None:
        self._log.append((sql, seq))

    def fetchone(self) -> tuple[int]:
        return (1,)  # RETURNING id dos INSERTs


class _RawFalso:
    def __init__(self) -> None:
        self.log: list[tuple[str, Any]] = []

    def cursor(self, **_kw: Any) -> _CursorFalso:
        return _CursorFalso(self.log)

    def execute(self, sql: str, params: Any = None) -> None:
        self.log.append((sql, params))

    def commit(self) -> None:
        self.log.append(("COMMIT", None))

    def rollback(self) -> None:
        self.log.append(("ROLLBACK", None))


def _search_paths(raw: _RawFalso) -> list[Any]:
    return [p for s, p in raw.log if "set_config('search_path'" in s]


def test_conta_sem_esquema_usa_o_base_sem_mexer_no_search_path() -> None:
    # jonas: nada muda, nenhum set_config
    raw = _RawFalso()
    conn = PgConnection(raw, None)
    conn.execute("SELECT 1 FROM answers")
    conn.commit()
    conn.execute("SELECT 1 FROM answers")
    assert _search_paths(raw) == []


def test_conta_com_esquema_aplica_search_path_em_cada_transacao() -> None:
    raw = _RawFalso()
    conn = PgConnection(raw, "paes_yuri")
    conn.execute("SELECT 1 FROM answers")
    conn.execute("SELECT 2 FROM answers")  # mesma transação: não repete
    assert _search_paths(raw) == [["paes_yuri, paes"]]
    conn.commit()  # set_config(..., true) acaba com a transação: aplica de novo
    conn.execute("INSERT INTO answers (question_id) VALUES (?)", ["q1"])
    conn.rollback()
    conn.execute("SELECT 3")
    assert _search_paths(raw) == [["paes_yuri, paes"]] * 3
    # o set_config vem sempre ANTES do SQL do app na transação
    primeiro_sql = next(i for i, (s, _) in enumerate(raw.log) if "SELECT 1 FROM answers" in s)
    assert "set_config" in raw.log[primeiro_sql - 1][0]


@pytest.mark.parametrize("nome", ["paes", "public", "paes_yuri; DROP TABLE x", "PAES_YURI", "", None, "x_paes"])
def test_esquema_invalido_cai_no_base(nome: str | None) -> None:
    raw = _RawFalso()
    PgConnection(raw, nome).execute("SELECT 1")
    assert _search_paths(raw) == []


def test_sessao_leva_o_esquema_da_conta_ate_a_rota(monkeypatch: pytest.MonkeyPatch) -> None:
    # o middleware do main.py lê o "e" do cookie e o db() enxerga dentro da rota
    monkeypatch.setenv("VERCEL", "1")
    monkeypatch.setenv("PAES_SESSAO_SEGREDO", "segredo-de-teste")
    from main import _exige_sessao_na_web

    app = FastAPI()
    app.middleware("http")(_exige_sessao_na_web)

    @app.get("/api/quem")
    def quem() -> dict[str, Any]:
        return {"esquema": db.esquema_atual()}

    cliente = TestClient(app)
    jonas = auth.cria_token("jonas", "Jonas", "admin")
    yuri = auth.cria_token("yuri", "Yuri", "admin", "paes_yuri")
    assert cliente.get("/api/quem", cookies={auth.COOKIE: jonas}).json() == {"esquema": None}
    assert cliente.get("/api/quem", cookies={auth.COOKIE: yuri}).json() == {"esquema": "paes_yuri"}
    # um pedido não contamina o próximo
    assert cliente.get("/api/quem", cookies={auth.COOKIE: jonas}).json() == {"esquema": None}
    assert cliente.get("/api/quem").status_code == 401
    assert db.esquema_atual() is None


def test_token_antigo_sem_esquema_continua_valendo(monkeypatch: pytest.MonkeyPatch) -> None:
    # cookies emitidos antes desta mudança não têm "e": a sessão do Jonas segue válida
    monkeypatch.setenv("PAES_SESSAO_SEGREDO", "segredo-de-teste")
    dados = auth.le_token(auth.cria_token("jonas", "Jonas", "admin"))
    assert dados and dados["u"] == "jonas" and "e" not in dados
