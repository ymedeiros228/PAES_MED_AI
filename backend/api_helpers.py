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
    GEMINI_API_KEY,
    GEMINI_MODEL,
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


def _gemini_configured() -> bool:
    return bool(GEMINI_API_KEY and GEMINI_API_KEY != "cole_sua_chave_aqui")


def _configured_provider() -> str | None:
    if _gemini_configured():
        return "gemini"
    if _openai_client() is not None:
        return "openai"
    return None


def _gemini_messages(
    user_content: str,
    history: list[ChatMessage] | None,
) -> list[dict[str, object]]:
    messages: list[dict[str, object]] = []
    for item in (history or [])[-20:]:
        role = "model" if item.role == "assistant" else "user"
        messages.append({"role": role, "parts": [{"text": item.content}]})
    messages.append({"role": "user", "parts": [{"text": user_content}]})
    return messages


def _ask_gemini(
    instructions: str,
    user_content: str,
    history: list[ChatMessage] | None = None,
) -> str:
    if not _gemini_configured():
        raise HTTPException(
            status_code=503,
            detail="GEMINI_API_KEY não configurada.",
        )

    import httpx

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GEMINI_MODEL}:generateContent"
    )
    body = {
        "systemInstruction": {"parts": [{"text": instructions}]},
        "contents": _gemini_messages(user_content, history),
        "generationConfig": {"temperature": 0.2},
    }
    try:
        response = httpx.post(
            url,
            headers={"x-goog-api-key": GEMINI_API_KEY},
            json=body,
            timeout=OPENAI_TIMEOUT_SECONDS,
        )
        if response.status_code >= 400:
            if response.status_code == 429:
                detail = "O Gemini atingiu o limite gratuito de uso. Tente novamente mais tarde."
            elif response.status_code in {401, 403}:
                detail = "A chave Gemini foi recusada. Verifique se ela está ativa."
            else:
                detail = f"Falha Gemini (HTTP {response.status_code})."
            raise HTTPException(status_code=502, detail=detail)
        data = response.json()
        parts = data.get("candidates", [{}])[0].get("content", {}).get("parts", [])
        answer = "\n".join(
            part.get("text", "").strip()
            for part in parts
            if isinstance(part, dict) and part.get("text")
        ).strip()
        if not answer:
            raise HTTPException(status_code=502, detail="O Gemini retornou uma resposta vazia.")
        return answer
    except HTTPException:
        raise
    except httpx.TimeoutException as exc:
        raise HTTPException(
            status_code=502,
            detail="Não foi possível alcançar o Gemini dentro do tempo limite.",
        ) from exc
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail="Não foi possível conectar ao Gemini.",
        ) from exc


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
