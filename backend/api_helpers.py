"""Helpers compartilhados pelos routers."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import (
    HTTPException,
    UploadFile,
)

from config import (
    MAX_UPLOAD_BYTES,
    OPENAI_API_KEY,
    OPENAI_MODEL,
    OPENAI_TIMEOUT_SECONDS,
)
from schemas import ChatMessage


def _openai_client():
    if not OPENAI_API_KEY or OPENAI_API_KEY == "cole_sua_chave_aqui":
        return None
    from openai import OpenAI

    return OpenAI(api_key=OPENAI_API_KEY, timeout=OPENAI_TIMEOUT_SECONDS, max_retries=1)

def _ask_openai(instructions: str, user_content: str, history: list[ChatMessage] | None = None) -> str:
    client = _openai_client()
    if client is None:
        raise HTTPException(
            status_code=503,
            detail="OPENAI_API_KEY não configurada. Edite backend/.env",
        )
    messages = []
    for item in (history or [])[-20:]:
        messages.append({"role": item.role, "content": item.content})
    messages.append({"role": "user", "content": user_content})
    try:
        response = client.responses.create(
            model=OPENAI_MODEL,
            instructions=instructions,
            input=messages,
        )
        answer = (response.output_text or "").strip()
        if not answer:
            raise HTTPException(status_code=502, detail="IA retornou vazio.")
        return answer
    except HTTPException:
        raise
    except Exception as exc:
        kind = type(exc).__name__
        if kind == "RateLimitError":
            detail = "A chave OpenAI foi aceita, mas atingiu o limite de uso ou cota."
        elif kind in {"AuthenticationError", "PermissionDeniedError"}:
            detail = "A chave OpenAI foi recusada. Verifique se ela está ativa e autorizada."
        elif kind in {"APITimeoutError", "APIConnectionError"}:
            detail = "Não foi possível alcançar a OpenAI dentro do tempo limite."
        else:
            detail = f"Falha OpenAI ({kind})."
        raise HTTPException(
            status_code=502,
            detail=detail,
        ) from exc

async def _save_upload(file: UploadFile, folder: Path, default_name: str) -> Path:
    """Grava o upload dentro de `folder`, sem sair da pasta e sem estourar o limite."""
    folder.mkdir(parents=True, exist_ok=True)
    dest = folder / (Path(file.filename or default_name).name or default_name)
    written = 0
    with dest.open("wb") as f:
        while chunk := await file.read(1024 * 1024):
            written += len(chunk)
            if written > MAX_UPLOAD_BYTES:
                f.close()
                dest.unlink(missing_ok=True)
                raise HTTPException(413, f"Arquivo acima do limite de {MAX_UPLOAD_BYTES // (1024 * 1024)} MB")
            f.write(chunk)
    return dest

def loads_json_safe(value: Any) -> list[Any]:
    if not value:
        return []
    if isinstance(value, list):
        return value
    try:
        data = json.loads(value)
        return data if isinstance(data, list) else []
    except Exception:
        return []
