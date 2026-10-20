"""Contas de acesso da versão web: login com usuário e senha, sessão em cookie assinado.

No app local (sem a variável VERCEL) não há login: /api/auth/me responde que não exige.
No Vercel, quem não tem sessão válida não passa do middleware.js (borda, protege /api e /data)
nem do _exige_sessao_na_web do main.py (segunda barreira, só /api).

Token da sessão: "<payload em base64url>.<HMAC-SHA256 do payload em base64url>", assinado com
PAES_SESSAO_SEGREDO. O middleware.js confere a mesma assinatura sem consultar o banco.
Contas: tabela `usuarios` (db.py); criar e trocar senha com scripts/criar_usuario.py.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, HTTPException, Request, Response
from pydantic import BaseModel

from db import db

router = APIRouter(prefix="/api/auth", tags=["auth"])

COOKIE = "paes_sessao"
DURACAO_SEGUNDOS = 30 * 24 * 3600
ITERACOES = 310_000
MAX_FALHAS = 5
BLOQUEIO_MINUTOS = 10
# conta inexistente também gasta o tempo de um PBKDF2: a resposta não denuncia quem existe
_HASH_FALSO = "pbkdf2_sha256$310000$AAAAAAAAAAAAAAAAAAAAAA$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"


def exige_login() -> bool:
    return bool(os.getenv("VERCEL"))


def _b64(dados: bytes) -> str:
    return base64.urlsafe_b64encode(dados).rstrip(b"=").decode()


def _de_b64(texto: str) -> bytes:
    return base64.urlsafe_b64decode(texto + "=" * (-len(texto) % 4))


def hash_senha(senha: str) -> str:
    sal = secrets.token_bytes(16)
    chave = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal, ITERACOES)
    return f"pbkdf2_sha256${ITERACOES}${_b64(sal)}${_b64(chave)}"


def confere_senha(senha: str, guardado: str) -> bool:
    try:
        _alg, iteracoes, sal, chave = guardado.split("$")
        calculada = hashlib.pbkdf2_hmac("sha256", senha.encode(), _de_b64(sal), int(iteracoes))
        return hmac.compare_digest(calculada, _de_b64(chave))
    except (ValueError, TypeError):
        return False


def _segredo() -> bytes:
    segredo = (os.getenv("PAES_SESSAO_SEGREDO") or "").strip()
    if not segredo:
        raise HTTPException(status_code=503, detail="Login não configurado no servidor.")
    return segredo.encode()


def _assina(corpo: str) -> str:
    return _b64(hmac.new(_segredo(), corpo.encode(), hashlib.sha256).digest())


def cria_token(usuario: str, nome: str, papel: str) -> str:
    corpo = _b64(json.dumps(
        {"u": usuario, "n": nome, "p": papel, "exp": int(time.time()) + DURACAO_SEGUNDOS},
        ensure_ascii=False, separators=(",", ":"),
    ).encode())
    return f"{corpo}.{_assina(corpo)}"


def le_token(token: str) -> dict[str, Any] | None:
    corpo, _, assinatura = (token or "").partition(".")
    if not corpo or not assinatura or not hmac.compare_digest(_assina(corpo), assinatura):
        return None
    try:
        dados = json.loads(_de_b64(corpo))
    except ValueError:
        return None
    return dados if isinstance(dados, dict) and dados.get("exp", 0) > time.time() else None


def sessao_da_requisicao(request: Request) -> dict[str, Any] | None:
    return le_token(request.cookies.get(COOKIE, ""))


def _agora() -> datetime:
    return datetime.now(timezone.utc)


class LoginRequest(BaseModel):
    usuario: str
    senha: str


def _iso(momento: datetime) -> str:
    # formato fixo: bloqueado_ate é comparado como texto no SQL
    return momento.isoformat(timespec="microseconds")


def _travado(minutos: int) -> HTTPException:
    return HTTPException(status_code=429, detail=f"Muitas tentativas erradas. Tente de novo em {minutos} min.")


@router.post("/login")
def login(payload: LoginRequest, response: Response) -> dict[str, Any]:
    usuario = payload.usuario.strip().lower()
    agora = _agora()
    with db() as conn:
        conta = conn.execute(
            "SELECT usuario, nome, senha_hash, papel, bloqueado_ate FROM usuarios WHERE usuario = ?",
            (usuario,),
        ).fetchone()
        if not conta:
            confere_senha(payload.senha, _HASH_FALSO)
            raise HTTPException(status_code=401, detail="Usuário ou senha incorretos.")
        # Reserva a tentativa ANTES de conferir a senha, num UPDATE só (atômico): mesmo com
        # pedidos em paralelo, no máximo MAX_FALHAS senhas são testadas por janela de bloqueio.
        vaga = conn.execute(
            "UPDATE usuarios SET falhas = falhas + 1 WHERE usuario = ? AND falhas < ?"
            " AND (bloqueado_ate IS NULL OR bloqueado_ate <= ?) RETURNING falhas",
            (usuario, MAX_FALHAS, _iso(agora)),
        ).fetchone()
        conn.commit()
        if not vaga:
            bloqueio = conta["bloqueado_ate"]
            if bloqueio and datetime.fromisoformat(bloqueio) > agora:
                raise _travado(max(1, round((datetime.fromisoformat(bloqueio) - agora).total_seconds() / 60)))
            # vagas gastas sem bloqueio registrado (pedido que caiu no meio): abre a janela agora
            conn.execute(
                "UPDATE usuarios SET falhas = 0, bloqueado_ate = ? WHERE usuario = ?",
                (_iso(agora + timedelta(minutes=BLOQUEIO_MINUTOS)), usuario),
            )
            conn.commit()
            raise _travado(BLOQUEIO_MINUTOS)
        if not confere_senha(payload.senha, conta["senha_hash"]):
            if int(vaga["falhas"]) >= MAX_FALHAS:
                conn.execute(
                    "UPDATE usuarios SET falhas = 0, bloqueado_ate = ? WHERE usuario = ?",
                    (_iso(agora + timedelta(minutes=BLOQUEIO_MINUTOS)), usuario),
                )
                conn.commit()
            raise HTTPException(status_code=401, detail="Usuário ou senha incorretos.")
        conn.execute(
            "UPDATE usuarios SET falhas = 0, bloqueado_ate = NULL, ultimo_acesso = ? WHERE usuario = ?",
            (_iso(agora), usuario),
        )
        conn.commit()
    response.set_cookie(
        COOKIE,
        cria_token(conta["usuario"], conta["nome"], conta["papel"]),
        max_age=DURACAO_SEGUNDOS,
        httponly=True,
        secure=True,
        samesite="lax",
        path="/",
    )
    return {"usuario": conta["usuario"], "nome": conta["nome"], "papel": conta["papel"], "exigeLogin": True}


@router.post("/logout")
def logout(response: Response) -> dict[str, Any]:
    response.delete_cookie(COOKIE, path="/", secure=True, httponly=True, samesite="lax")
    return {"ok": True}


@router.get("/me")
def me(request: Request) -> dict[str, Any]:
    if not exige_login():
        return {"usuario": "local", "nome": "", "papel": "admin", "exigeLogin": False}
    sessao = sessao_da_requisicao(request)
    if not sessao:
        raise HTTPException(status_code=401, detail="Faça login para continuar.")
    return {"usuario": sessao["u"], "nome": sessao.get("n") or "", "papel": sessao.get("p") or "aluno", "exigeLogin": True}
