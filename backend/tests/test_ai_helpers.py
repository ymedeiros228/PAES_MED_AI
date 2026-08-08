"""Regressões da configuração e dos erros da integração OpenAI."""

from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace

import pytest
from fastapi import HTTPException

BACKEND = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND))

import api_helpers  # noqa: E402
from routers.ai import retrieval_query  # noqa: E402
from schemas import ChatMessage  # noqa: E402


def test_ask_gemini_retorna_texto_da_resposta(monkeypatch: pytest.MonkeyPatch) -> None:
    response = SimpleNamespace(
        status_code=200,
        json=lambda: {
            "candidates": [
                {"content": {"parts": [{"text": "  resposta Gemini  "}]}}
            ]
        },
    )
    monkeypatch.setattr(api_helpers, "_gemini_configured", lambda: True)
    monkeypatch.setattr("httpx.post", lambda *args, **kwargs: response)

    assert api_helpers._ask_gemini("instruções", "pergunta") == "resposta Gemini"


def test_ask_gemini_traduz_limite_gratuito(monkeypatch: pytest.MonkeyPatch) -> None:
    response = SimpleNamespace(status_code=429, json=lambda: {})
    monkeypatch.setattr(api_helpers, "_gemini_configured", lambda: True)
    monkeypatch.setattr("httpx.post", lambda *args, **kwargs: response)

    with pytest.raises(HTTPException) as raised:
        api_helpers._ask_gemini("instruções", "pergunta")

    assert raised.value.status_code == 502
    assert "limite gratuito" in str(raised.value.detail)


def test_ask_gemini_traduz_api_key_invalid_em_400(monkeypatch: pytest.MonkeyPatch) -> None:
    response = SimpleNamespace(
        status_code=400,
        json=lambda: {
            "error": {
                "status": "INVALID_ARGUMENT",
                "message": "API key not valid. Please pass a valid API key.",
            }
        },
    )
    monkeypatch.setattr(api_helpers, "_gemini_configured", lambda: True)
    monkeypatch.setattr("httpx.post", lambda *args, **kwargs: response)

    with pytest.raises(HTTPException) as raised:
        api_helpers._ask_gemini("instruções", "pergunta")

    assert raised.value.status_code == 502
    assert str(raised.value.detail) == "A chave Gemini foi recusada. Verifique se ela está ativa."


def test_follow_up_usa_pergunta_original_para_retrieval() -> None:
    history = [
        ChatMessage(role="assistant", content="Olá"),
        ChatMessage(role="user", content="Explique genética mendeliana com base local."),
        ChatMessage(role="assistant", content="Resposta grounded"),
    ]

    assert retrieval_query(
        "Explique a resposta anterior de forma mais simples, com um exemplo curto.",
        history,
    ) == "Explique genética mendeliana com base local."
    assert retrieval_query("O que é crossing-over?", history) == "O que é crossing-over?"


def test_prioriza_citacoes_de_questao_antes_do_limite() -> None:
    from services_extra import prioritize_rag_citations

    citations = [
        {"type": "edital", "id": f"syl-{i}"} for i in range(12)
    ] + [
        {"type": "question", "id": "bio-2017-01"},
        {"type": "question", "id": "bio-2017-02"},
    ]

    result = prioritize_rag_citations(citations, question_limit=8)

    assert [item["id"] for item in result[:2]] == ["bio-2017-01", "bio-2017-02"]
    assert len(result) == 12
    assert all(item["type"] == "edital" for item in result[2:])


def test_ask_openai_retorna_texto_do_responses(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_client = SimpleNamespace(
        responses=SimpleNamespace(
            create=lambda **_: SimpleNamespace(output_text="  resposta grounded  ")
        )
    )
    monkeypatch.setattr(api_helpers, "_openai_client", lambda: fake_client)

    assert api_helpers._ask_openai("instruções", "pergunta") == "resposta grounded"


@pytest.mark.parametrize(
    ("error_name", "expected"),
    [
        ("RateLimitError", "atingiu o limite de uso ou cota"),
        ("AuthenticationError", "foi recusada"),
        ("APITimeoutError", "tempo limite"),
    ],
)
def test_ask_openai_traduz_erros_operacionais(
    monkeypatch: pytest.MonkeyPatch,
    error_name: str,
    expected: str,
) -> None:
    error_type = type(error_name, (Exception,), {})
    fake_client = SimpleNamespace(
        responses=SimpleNamespace(
            create=lambda **_: (_ for _ in ()).throw(error_type())
        )
    )
    monkeypatch.setattr(api_helpers, "_openai_client", lambda: fake_client)

    with pytest.raises(HTTPException) as raised:
        api_helpers._ask_openai("instruções", "pergunta")

    assert raised.value.status_code == 502
    assert expected in str(raised.value.detail)
