"""Estado runtime e persistência segura das credenciais de IA."""

from __future__ import annotations

import os
import re
import stat
import tempfile
from pathlib import Path
from threading import RLock
from typing import Literal

from config import (
    BASE_DIR,
    GEMINI_API_KEY,
    GEMINI_MODEL,
    OPENAI_API_KEY,
    OPENAI_MODEL,
)

Provider = Literal["gemini", "openai"]
MAX_API_KEY_LENGTH = 512
_PLACEHOLDER = "cole_sua_chave_aqui"
GEMINI_MODEL_CANDIDATES = (
    "gemini-flash-latest",
    "gemini-3-flash-preview",
    "gemini-2.5-flash-lite",
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
)

_lock = RLock()
_values = {
    "gemini": {"key": GEMINI_API_KEY, "model": GEMINI_MODEL},
    "openai": {"key": OPENAI_API_KEY, "model": OPENAI_MODEL},
}
_gemini_model_explicit = bool(os.getenv("GEMINI_MODEL"))


def _usable(value: str) -> bool:
    return bool(value and value != _PLACEHOLDER)


def validate_secret(value: str) -> str:
    value = value.strip()
    if not value or len(value) > MAX_API_KEY_LENGTH:
        raise ValueError("A chave deve ter entre 1 e 512 caracteres.")
    if any(not char.isprintable() or char in "\r\n" for char in value):
        raise ValueError("A chave contém caracteres inválidos.")
    return value


def provider_key(provider: Provider) -> str:
    with _lock:
        return str(_values[provider]["key"])


def provider_model(provider: Provider) -> str:
    with _lock:
        return str(_values[provider]["model"])


def provider_configured(provider: Provider) -> bool:
    return _usable(provider_key(provider))


def configured_provider() -> str | None:
    with _lock:
        if _usable(str(_values["gemini"]["key"])):
            return "gemini"
        if _usable(str(_values["openai"]["key"])):
            return "openai"
    return None


def active_model(provider: Provider) -> str:
    return provider_model(provider)


def masked_key(provider: Provider) -> str | None:
    key = provider_key(provider)
    return key[-4:] if _usable(key) else None


def state() -> dict[str, object]:
    provider = configured_provider()
    return {
        "activeProvider": provider,
        "activeModel": provider_model(provider) if provider else None,
        "geminiConfigured": provider_configured("gemini"),
        "geminiModel": provider_model("gemini"),
        "geminiKeyLast4": masked_key("gemini"),
        "openaiConfigured": provider_configured("openai"),
        "openaiModel": provider_model("openai"),
        "openaiKeyLast4": masked_key("openai"),
    }


def gemini_candidates(initial_model: str | None = None) -> list[str]:
    configured = (
        initial_model
        if initial_model is not None
        else (provider_model("gemini") if _gemini_model_explicit else "")
    ).strip()
    result: list[str] = []
    for model in ([configured] if configured else []) + list(GEMINI_MODEL_CANDIDATES):
        if model and model not in result:
            result.append(model)
    return result


def _update_env_file(updates: dict[str, str]) -> None:
    env_path = BASE_DIR / ".env"
    existing = env_path.read_text(encoding="utf-8") if env_path.exists() else ""
    lines = existing.splitlines()
    seen: set[str] = set()
    output: list[str] = []
    for line in lines:
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=", line)
        if not match:
            output.append(line)
            continue
        name = match.group(1)
        if name in updates:
            output.append(f"{name}={updates[name]}")
            seen.add(name)
        else:
            output.append(line)
    if output and output[-1] != "":
        output.append("")
    for name, value in updates.items():
        if name not in seen:
            output.append(f"{name}={value}")
    content = "\n".join(output).rstrip("\n") + "\n"
    fd, temp_name = tempfile.mkstemp(prefix=".env.", dir=BASE_DIR)
    try:
        os.fchmod(fd, stat.S_IRUSR | stat.S_IWUSR)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, env_path)
        os.chmod(env_path, stat.S_IRUSR | stat.S_IWUSR)
    except Exception:
        Path(temp_name).unlink(missing_ok=True)
        raise


def configure_provider(provider: Provider, key: str, model: str | None = None) -> None:
    clean_key = validate_secret(key)
    clean_model = (model or provider_model(provider)).strip()
    if not clean_model or any(not char.isprintable() or char in "\r\n" for char in clean_model):
        raise ValueError("O modelo contém caracteres inválidos.")
    env_updates = {
        "GEMINI_API_KEY" if provider == "gemini" else "OPENAI_API_KEY": clean_key,
    }
    if model is not None:
        env_updates["GEMINI_MODEL" if provider == "gemini" else "OPENAI_MODEL"] = clean_model
    with _lock:
        _values[provider] = {"key": clean_key, "model": clean_model}
        if provider == "gemini" and model is not None:
            global _gemini_model_explicit
            _gemini_model_explicit = True
        _update_env_file(env_updates)


def remember_model(provider: Provider, model: str) -> None:
    clean_model = model.strip()
    with _lock:
        _values[provider]["model"] = clean_model
        if provider == "gemini":
            global _gemini_model_explicit
            _gemini_model_explicit = True
        _update_env_file(
            {"GEMINI_MODEL" if provider == "gemini" else "OPENAI_MODEL": clean_model}
        )
