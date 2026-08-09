"""Testes da configuração runtime e do Tutor sem citação de questão."""

from __future__ import annotations

import stat
import sys
from pathlib import Path

import pytest
from fastapi import HTTPException

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

import ai_state  # noqa: E402
from routers import (  # noqa: E402
    ai,
    meta,
)
from schemas import AIProviderConfigRequest, AIProviderTestRequest, ChatRequest  # noqa: E402
from services_extra import TUTOR_SYSTEM  # noqa: E402


def test_grava_env_preservando_outras_chaves_e_sem_expor_segredo(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text("OPENAI_MODEL=gpt-test\nOUTRA_CONFIG=preservar\n", encoding="utf-8")
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    original = dict(ai_state._values["gemini"])
    original_status = ai_state._statuses["gemini"]
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
        ai_state._statuses["gemini"] = original_status
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
    original_status = ai_state._statuses["gemini"]
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
        assert result["geminiStatus"] == "working"
    finally:
        ai_state._values["gemini"] = original
        ai_state._statuses["gemini"] = original_status
        ai_state._gemini_model_explicit = original_explicit


def test_salvar_openai_preserva_chave_gemini(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text(
        "GEMINI_API_KEY=gemini-existente\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    monkeypatch.setattr(meta, "validate_openai_key", lambda _: "gpt-test")
    original = dict(ai_state._values["openai"])
    original_status = ai_state._statuses["openai"]
    original_explicit = ai_state._gemini_model_explicit
    try:
        meta.api_ai_configure(
            AIProviderConfigRequest(
                provider="openai",
                apiKey="openai-chave-nova",
                model="gpt-test",
            )
        )
        content = env_path.read_text(encoding="utf-8")
        assert "GEMINI_API_KEY=gemini-existente" in content
        assert "OPENAI_API_KEY=openai-chave-nova" in content
    finally:
        ai_state._values["openai"] = original
        ai_state._statuses["openai"] = original_status
        ai_state._gemini_model_explicit = original_explicit


def test_testa_provedor_especifico_sem_apagar_o_outro(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text(
        "GEMINI_API_KEY=gemini-existente\nOPENAI_API_KEY=openai-existente\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    monkeypatch.setattr(meta, "validate_openai_key", lambda _: "gpt-test")
    original_values = {name: dict(value) for name, value in ai_state._values.items()}
    original_status = dict(ai_state._statuses)
    try:
        ai_state._values["gemini"]["key"] = "gemini-existente"
        ai_state._values["openai"]["key"] = "openai-existente"
        result = meta.api_ai_test(AIProviderTestRequest(provider="openai"))
        assert result["ok"] is True
        assert result["activeProvider"] == "gemini"
        assert result["geminiConfigured"] is True
        assert result["openaiConfigured"] is True
        assert result["openaiStatus"] == "working"
    finally:
        ai_state._values.update(original_values)
        ai_state._statuses.update(original_status)


def test_configuracao_rejeita_quebra_de_linha() -> None:
    with pytest.raises(ValueError):
        ai_state.validate_secret("chave\ninjetada")


def test_tutor_ensina_sem_citacao_quando_provedor_esta_configurado(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    prompts: list[tuple[str, str]] = []

    def fake_gemini(system: str, content: str, *_args: object) -> str:
        prompts.append((system, content))
        return "Explicação conceitual."

    monkeypatch.setattr(
        ai,
        "build_rag_context_embedded_full",
        lambda _: ("", "embedded", []),
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "_ask_gemini", fake_gemini)
    monkeypatch.setattr(ai, "provider_model", lambda _: "gemini-flash-latest")

    result = ai.api_chat(ChatRequest(message="Explique osmose."))

    assert result.answer == "Explicação conceitual."
    assert result.usedRag is False
    assert result.citations == []
    assert result.hasLocalBase is False
    assert result.uncited is True
    assert prompts[0][0] == TUTOR_SYSTEM
    assert "Ensine diretamente o conceito" in prompts[0][1]
    assert "Isso não impede o ensino do conteúdo geral" in prompts[0][1]
    assert "Não invente gabarito" in prompts[0][1]


def test_prompt_do_tutor_separa_ensino_de_afirmacoes_da_prova() -> None:
    assert "Use seu conhecimento geral" in TUTOR_SYSTEM
    assert "É PROIBIDO inventar" in TUTOR_SYSTEM
    assert "Entregue primeiro a explicação útil" in TUTOR_SYSTEM
    assert "Não há essa informação na base local." not in TUTOR_SYSTEM


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


def test_tutor_tenta_openai_quando_gemini_falha(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        ai,
        "build_rag_context_embedded_full",
        lambda _: ("", "embedded", []),
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "provider_configured", lambda provider: provider == "openai")
    monkeypatch.setattr(
        ai,
        "_ask_gemini",
        lambda *_args: (_ for _ in ()).throw(
            HTTPException(status_code=502, detail="cota")
        ),
    )
    monkeypatch.setattr(ai, "_ask_openai", lambda *_args: "Resposta da OpenAI.")
    monkeypatch.setattr(ai, "provider_model", lambda provider: f"{provider}-modelo")

    result = ai.api_chat(ChatRequest(message="Explique osmose."))

    assert result.answer == "Resposta da OpenAI."
    assert result.model == "openai-modelo"


def test_tutor_cai_para_offline_se_os_dois_provedores_falharem(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(
        ai,
        "build_rag_context_embedded_full",
        lambda _: ("", "embedded", []),
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "provider_configured", lambda provider: provider == "openai")
    def failure(*_args: object) -> str:
        raise HTTPException(status_code=502, detail="indisponível")

    monkeypatch.setattr(ai, "_ask_gemini", failure)
    monkeypatch.setattr(ai, "_ask_openai", failure)
    monkeypatch.setattr("services_core.dashboard_stats", lambda: {"dailyRoutine": {}})
    monkeypatch.setattr("services_core.list_questions", lambda **_: [])

    result = ai.api_chat(ChatRequest(message="Explique osmose."))

    assert result.model == "offline-no-base-embedded"
    assert result.uncited is True


def test_preserva_as_quatro_chaves_ao_salvar_uma(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    env_path = tmp_path / ".env"
    env_path.write_text(
        "GEMINI_API_KEY=g\nGROQ_API_KEY=r\nOPENROUTER_API_KEY=o\nOPENAI_API_KEY=a\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(ai_state, "BASE_DIR", tmp_path)
    original = {name: dict(value) for name, value in ai_state._values.items()}
    statuses = dict(ai_state._statuses)
    try:
        ai_state.configure_provider("groq", "groq-nova", "llama-test")
        content = env_path.read_text(encoding="utf-8")
        assert "GEMINI_API_KEY=g" in content
        assert "GROQ_API_KEY=groq-nova" in content
        assert "OPENROUTER_API_KEY=o" in content
        assert "OPENAI_API_KEY=a" in content
        assert "GROQ_MODEL=llama-test" in content
        assert "groq-nova" not in str(ai_state.state())
    finally:
        ai_state._values.clear()
        ai_state._values.update(original)
        ai_state._statuses.clear()
        ai_state._statuses.update(statuses)


def test_cascata_tenta_provedores_na_ordem_e_depois_offline(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    attempts: list[str] = []
    monkeypatch.setattr(
        ai,
        "configured_providers",
        lambda: ["gemini", "groq", "openrouter", "openai"],
    )
    monkeypatch.setattr(ai, "_configured_provider", lambda: "gemini")
    monkeypatch.setattr(ai, "provider_configured", lambda _provider: True)

    def failure(
        _payload: ChatRequest,
        provider_override: str | None = None,
        force_offline: bool = False,
    ) -> None:
        attempts.append("offline" if force_offline else str(provider_override))
        raise HTTPException(status_code=502, detail="falha")

    monkeypatch.setattr(ai, "_api_chat", failure)
    with pytest.raises(HTTPException):
        ai.api_chat(ChatRequest(message="Explique osmose."))
    assert attempts == ["gemini", "groq", "openrouter", "openai", "offline"]


def test_modelos_openrouter_preservam_sufixo_gratuito() -> None:
    assert ai_state.provider_model_candidates("openrouter") == [
        "deepseek/deepseek-r1:free",
        "meta-llama/llama-3.3-70b-instruct:free",
    ]
