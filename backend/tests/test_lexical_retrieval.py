from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import services_advanced  # noqa: E402
from services_advanced import (
    _infer_subject,
    _lexical_question_score,
    build_rag_context_embedded_full,
    lexical_tokens,
)  # noqa: E402


def _score_documents(query: str, questions: list[dict[str, str]]) -> list[tuple[float, str]]:
    terms = lexical_tokens(query)
    token_sets = [
        set(
            lexical_tokens(
                f"{item['subject']} {item['topic']} {item['statement']}"
            )
        )
        for item in questions
    ]
    frequencies: dict[str, int] = {}
    for tokens in token_sets:
        for token in tokens:
            frequencies[token] = frequencies.get(token, 0) + 1
    average = sum(len(tokens) for tokens in token_sets) / len(token_sets)
    return sorted(
        (
            _lexical_question_score(
                terms,
                question,
                document_frequency=frequencies,
                document_count=len(questions),
                average_length=average,
            ),
            question["id"],
        )
        for question in questions
    )


def test_normalizacao_remove_acentos_caixa_e_palavras_funcao() -> None:
    assert lexical_tokens("Explique a solução tampão para VOCÊ") == [
        "solucao",
        "tampao",
    ]


def test_materia_da_mesma_taxonomia_ranqueia_acima() -> None:
    questions = [
        {
            "id": "bio",
            "subject": "Biologia",
            "topic": "Genética",
            "statement": "Explique genótipo e fenótipo.",
        },
        {
            "id": "hist",
            "subject": "História",
            "topic": "Brasil República",
            "statement": "Explique a política brasileira.",
        },
    ]
    ranking = _score_documents("explique genética", questions)
    assert ranking[-1][1] == "bio"
    assert _infer_subject(lexical_tokens("genética"), questions) == "Biologia"


def test_palavras_funcao_nao_dominam_ranking() -> None:
    questions = [
        {
            "id": "specific",
            "subject": "Física",
            "topic": "Cinemática",
            "statement": "Calcule a velocidade média.",
        },
        {
            "id": "generic",
            "subject": "História",
            "topic": "Brasil",
            "statement": "Explique como estudar para a prova.",
        },
    ]
    ranking = _score_documents("explique como calcular a velocidade", questions)
    assert ranking[-1][1] == "specific"


def test_busca_do_tutor_nao_depende_do_hash(monkeypatch) -> None:
    def fail(*_args: object, **_kwargs: object) -> list[float]:
        raise AssertionError("hash não deve decidir a recuperação do Tutor")

    monkeypatch.setattr(services_advanced, "local_embedding", fail)
    monkeypatch.setattr(services_advanced, "openai_embedding", fail)
    _context, mode, _citations = build_rag_context_embedded_full("genética")
    assert mode == "lexical"


def test_pergunta_sem_relacao_nao_produz_citacao() -> None:
    _context, _mode, citations = build_rag_context_embedded_full(
        "zangão quasar inexistente pluma"
    )
    assert not [item for item in citations if item.get("type") == "question"]
