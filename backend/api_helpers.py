"""Helpers compartilhados pelos routers."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import (
    HTTPException,
    UploadFile,
)

from ai_state import (
    configured_provider,
    gemini_candidates,
    provider_configured,
    provider_key,
    provider_model,
    remember_model,
)
from config import MAX_UPLOAD_BYTES, OPENAI_TIMEOUT_SECONDS
from schemas import ChatMessage


def _openai_client():
    if not provider_configured("openai"):
        return None
    from openai import OpenAI

    return OpenAI(
        api_key=provider_key("openai"),
        timeout=OPENAI_TIMEOUT_SECONDS,
        max_retries=1,
    )


def _gemini_configured() -> bool:
    return provider_configured("gemini")


def _configured_provider() -> str | None:
    return configured_provider()


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


class GeminiValidationError(Exception):
    def __init__(self, kind: str, detail: str) -> None:
        super().__init__(detail)
        self.kind = kind
        self.detail = detail


def _gemini_request(
    api_key: str,
    model: str,
    instructions: str,
    user_content: str,
    history: list[ChatMessage] | None = None,
) -> str:
    import httpx

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent"
    )
    body = {
        "systemInstruction": {"parts": [{"text": instructions}]},
        "contents": _gemini_messages(user_content, history),
        "generationConfig": {"temperature": 0.2},
    }
    try:
        response = httpx.post(
            url,
            headers={"x-goog-api-key": api_key},
            json=body,
            timeout=OPENAI_TIMEOUT_SECONDS,
        )
        if response.status_code >= 400:
            invalid_key = False
            try:
                error_payload = response.json()
            except (ValueError, TypeError):
                error_payload = {}
            if isinstance(error_payload, dict):
                error = error_payload.get("error")
                if isinstance(error, dict):
                    code = str(error.get("status") or error.get("code") or "").upper()
                    message = str(error.get("message") or "").lower()
                    invalid_key = (
                        "API_KEY_INVALID" in code
                        or "api key not valid" in message
                        or ("invalid_argument" in code.lower() and "api key" in message)
                    )
            if response.status_code in {401, 403} or invalid_key:
                raise GeminiValidationError(
                    "key",
                    "A chave Gemini foi recusada. Verifique se ela está ativa.",
                )
            if response.status_code == 429:
                raise GeminiValidationError(
                    "quota",
                    "O Gemini atingiu o limite gratuito de uso. Tente novamente mais tarde.",
                )
            if response.status_code == 404 or "no longer available" in str(
                error_payload
            ).lower():
                raise GeminiValidationError(
                    "unavailable",
                    "O modelo Gemini não está disponível para esta chave.",
                )
            else:
                raise GeminiValidationError(
                    "other",
                    f"Falha Gemini (HTTP {response.status_code}).",
                )
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
    except httpx.TimeoutException as exc:
        raise GeminiValidationError(
            "connection",
            "Não foi possível alcançar o Gemini dentro do tempo limite.",
        ) from exc
    except httpx.HTTPError as exc:
        raise GeminiValidationError(
            "connection",
            "Não foi possível conectar ao Gemini.",
        ) from exc


def _gemini_http_error(error: GeminiValidationError) -> HTTPException:
    return HTTPException(status_code=502, detail=error.detail)


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
    last: GeminiValidationError | None = None
    for model in gemini_candidates():
        try:
            answer = _gemini_request(
                provider_key("gemini"),
                model,
                instructions,
                user_content,
                history,
            )
            if model != provider_model("gemini"):
                remember_model("gemini", model)
            return answer
        except GeminiValidationError as error:
            if error.kind == "key":
                raise _gemini_http_error(error) from error
            if error.kind not in {"unavailable", "quota"}:
                raise _gemini_http_error(error) from error
            last = error
    if last is not None:
        raise _gemini_http_error(
            GeminiValidationError(
                "exhausted",
                (
                    "O Gemini atingiu o limite gratuito de uso ou os modelos disponíveis "
                    "estão sem cota. Tente novamente mais tarde."
                ),
            )
        ) from last
    raise HTTPException(status_code=502, detail="Nenhum modelo Gemini disponível.")


def validate_gemini_key(api_key: str, initial_model: str | None = None) -> str:
    last: GeminiValidationError | None = None
    for model in gemini_candidates(initial_model):
        try:
            _gemini_request(
                api_key,
                model,
                "Responda apenas com OK.",
                "Teste de configuração.",
            )
            return model
        except GeminiValidationError as error:
            if error.kind == "key":
                raise HTTPException(status_code=400, detail=error.detail) from error
            if error.kind not in {"unavailable", "quota"}:
                raise HTTPException(status_code=502, detail=error.detail) from error
            last = error
    raise HTTPException(
        status_code=502,
        detail=(
            "Os modelos Gemini disponíveis estão indisponíveis ou sem cota. "
            "Tente novamente mais tarde."
        ),
    ) from last


def validate_openai_key(api_key: str) -> str:
    from openai import OpenAI

    try:
        client = OpenAI(
            api_key=api_key,
            timeout=OPENAI_TIMEOUT_SECONDS,
            max_retries=0,
        )
        response = client.responses.create(
            model=provider_model("openai"),
            instructions="Responda apenas com OK.",
            input=[{"role": "user", "content": "Teste de configuração."}],
        )
        if not (response.output_text or "").strip():
            raise HTTPException(status_code=502, detail="A OpenAI retornou uma resposta vazia.")
        return provider_model("openai")
    except HTTPException:
        raise
    except Exception as exc:
        kind = type(exc).__name__
        if kind in {"AuthenticationError", "PermissionDeniedError"}:
            detail = "A chave OpenAI foi recusada. Verifique se ela está ativa."
            status = 400
        elif kind == "RateLimitError":
            detail = "A OpenAI atingiu o limite de uso ou cota."
            status = 502
        elif kind in {"APITimeoutError", "APIConnectionError"}:
            detail = "Não foi possível conectar à OpenAI."
            status = 502
        else:
            detail = "Não foi possível validar a chave OpenAI."
            status = 502
        raise HTTPException(status_code=status, detail=detail) from exc


def _ask_openai(instructions: str, user_content: str, history: list[ChatMessage] | None = None) -> str:
    client = _openai_client()
    if client is None:
        raise HTTPException(
            status_code=503,
            detail="OPENAI_API_KEY não configurada.",
        )
    messages = []
    for item in (history or [])[-20:]:
        messages.append({"role": item.role, "content": item.content})
    messages.append({"role": "user", "content": user_content})
    try:
        response = client.responses.create(
            model=provider_model("openai"),
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
