"""Testes da configuração runtime e do Tutor sem citação de questão."""

from __future__ import annotations

import stat
import sys
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

import ai_state  # noqa: E402
from routers import (  # noqa: E402
    ai,
    meta,
)
from schemas import AIProviderConfigRequest, ChatRequest  # noqa: E402


def test_grava_env_preservando_outras_chaves_e_sem_expor_segredo(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text("OPENAI_MODEL=gpt-test\nOUTRA_CONFIG=preservar\n", encoding="utf-8")
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    original = dict(ai_state._values["gemini"])
    original_explicit = ai_state._gemini_model_explicit
    secret = "gemini-chave-de-teste"
    try:
        ai_state.configure_provider("gemini", secret, "gemini-test")
        content = env_path.read_text(encoding="utf-8")
        assert "OPENAI_MODEL=gpt-test" in content
        assert "OUTRA_CONFIG=preservar" in content
        assert "GEMINI_MODEL=gemini-test" in content
        assert "GEMINI_API_KEY=" + secret in content
        assert stat.S_IMODE(env_path.stat().st_mode) == 0o600
        assert ai_state.masked_key("gemini") == "este"
        assert secret not in str(ai_state.state())
    finally:
        ai_state._values["gemini"] = original
        ai_state._gemini_model_explicit = original_explicit


def test_endpoint_configuracao_nao_devolve_chave(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text("OPENAI_API_KEY=outra-chave\n", encoding="utf-8")
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    monkeypatch.setattr(meta, "validate_gemini_key", lambda *_: "gemini-test")
    original = dict(ai_state._values["gemini"])
    original_explicit = ai_state._gemini_model_explicit
    secret = "chave-secreta-nao-retornar"
    try:
        result = meta.api_ai_configure(
            AIProviderConfigRequest(
                provider="gemini",
                apiKey=secret,
                model="gemini-test",
            )
        )
        content = env_path.read_text(encoding="utf-8")
        assert "OPENAI_API_KEY=outra-chave" in content
        assert secret in content
        assert secret not in str(result)
        assert result["geminiKeyLast4"] == "rnar"
    finally:
        ai_state._values["gemini"] = original
        ai_state._gemini_model_explicit = original_explicit


def test_configuracao_rejeita_quebra_de_linha() -> None:
    with pytest.raises(ValueError):
        ai_state.validate_secret("chave\ninjetada")


def test_tutor_ensina_sem_citacao_quando_provedor_esta_configurado(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        ai,
        "build_rag_context_embedded_full",
        lambda _: ("", "embedded", []),
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "_ask_gemini", lambda *_args: "Explicação conceitual.")
    monkeypatch.setattr(ai, "provider_model", lambda _: "gemini-flash-latest")

    result = ai.api_chat(ChatRequest(message="Explique osmose."))

    assert result.answer == "Explicação conceitual."
    assert result.usedRag is False
    assert result.citations == []
    assert result.hasLocalBase is False
    assert result.uncited is True


def test_tutor_offline_sem_provedor_mantem_recusa_sem_base(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        ai,
        "build_rag_context_embedded_full",
        lambda _: ("", "embedded", []),
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: None)
    monkeypatch.setattr("services_core.dashboard_stats", lambda: {"dailyRoutine": {}})
    monkeypatch.setattr("services_core.list_questions", lambda **_: [])

    result = ai.api_chat(ChatRequest(message="Explique um tema ausente."))

    assert result.model == "offline-no-base-embedded"
    assert result.usedRag is False
    assert result.hasLocalBase is False
    assert result.uncited is True
    assert "Sem base local" in result.answer
