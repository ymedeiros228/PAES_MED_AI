"""Rotas: ia."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter, HTTPException

from ai_state import configured_providers, provider_configured, provider_model
from api_helpers import (
    _ask_gemini,
    _ask_groq,
    _ask_openai,
    _ask_openrouter,
    _configured_provider,
    _openai_client,
)
from db import db
from schemas import (
    ChatRequest,
    ChatResponse,
    ProfessorAcceptRequest,
    ProfessorBatchRequest,
    ProfessorGenerateRequest,
    ProfessorQueueActionRequest,
)
from services_advanced import (
    build_rag_context_embedded_full,
    index_all_questions,
)
from services_core import get_question
from services_extra import (
    TUTOR_SYSTEM,
    accept_professor_draft,
    build_rag_context,
    build_rag_context_with_citations,
    fill_professor_drafts,
    list_professor_draft_queue,
    skip_professor_draft,
)

# Compatibilidade para testes e clientes internos que importavam este nome.
configured_provider = _configured_provider

router = APIRouter(tags=["ia"])

_FOLLOW_UP_PREFIXES = (
    "explique a resposta anterior",
    "faça uma pergunta curta para testar meu entendimento",
    "transforme a resposta anterior em até 3 flashcards",
)


def _ask_provider(
    provider: str,
    instructions: str,
    content: str,
    history: list[Any] | None,
) -> str:
    askers = {
        "gemini": _ask_gemini,
        "groq": _ask_groq,
        "openrouter": _ask_openrouter,
        "openai": _ask_openai,
    }
    return askers[provider](instructions, content, history)


def retrieval_query(message: str, history: list[Any] | None) -> str:
    """Mantém os atalhos do Tutor ancorados na pergunta original do aluno."""
    normalized = message.strip().lower()
    if not any(normalized.startswith(prefix) for prefix in _FOLLOW_UP_PREFIXES):
        return message
    for item in reversed(history or []):
        if getattr(item, "role", None) != "user":
            continue
        candidate = getattr(item, "content", "").strip()
        if candidate and not any(candidate.lower().startswith(prefix) for prefix in _FOLLOW_UP_PREFIXES):
            return candidate
    return message


def _api_chat(
    payload: ChatRequest,
    *,
    provider_override: str | None = None,
    force_offline: bool = False,
) -> ChatResponse:
    citations: list[dict[str, Any]] = []
    rag_query = retrieval_query(payload.message, payload.history)
    try:
        context, rag_mode, citations = build_rag_context_embedded_full(rag_query)
    except Exception:
        try:
            context, citations = build_rag_context_with_citations(rag_query)
            rag_mode = "keyword"
        except Exception:
            context, rag_mode = build_rag_context(rag_query), "keyword"
            citations = []
    style_hint = {
        "professor": "Explique como professor especialista, com perguntas.",
        "medico": "Explique conectando com raciocínio clínico/Medicina quando fizer sentido.",
        "crianca": "Explique como se o aluno tivesse 12 anos, sem perder precisão.",
        "analogia": "Use analogias concretas.",
        "mapa": "Organize a resposta como mapa mental em tópicos.",
        "resumo": "Resumo em até 5 linhas + 1 pergunta.",
        "macete": "Foque em macetes e eliminação de alternativas.",
        "flashcard": "Devolva no formato Frente/Verso de flashcards.",
    }.get(payload.style or "professor", "Explique como professor.")

    user_content = (
        f"ESTILO: {style_hint}\n\n"
        f"MODO_RAG: {rag_mode}\n\n"
        "REGRAS: Ensine diretamente o conceito, a teoria, o raciocínio ou a "
        "resolução pedida, mesmo que o CONTEXTO não contenha uma explicação pronta. "
        "Use o CONTEXTO para ancorar afirmações sobre provas e a banca e cite apenas "
        "ids reais de questões. Não invente gabarito, resolução de questão específica, "
        "id, percentual de cobrança, incidência, frequência, estatística, tendência "
        "ou o que vai cair. Só informe um percentual se ele estiver explicitamente "
        "sustentado pelo CONTEXTO; nunca converta uma frequência em percentual. "
        "Se faltar suporte para um dado de prova, explique o conteúdo relacionado e "
        "acrescente uma ressalva curta, sem substituir o ensino.\n\n"
        f"CONTEXTO DA BASE LOCAL:\n{context}\n\n"
        f"PERGUNTA DO ALUNO:\n{payload.message}"
    )

    q_cites = [
        c
        for c in citations
        if isinstance(c, dict) and c.get("type") == "question" and c.get("id")
    ]
    has_local = bool(q_cites) or bool((context or "").strip())

    provider = None if force_offline else (provider_override or _configured_provider())
    if provider is None:
        from services_core import dashboard_stats, stats_basis

        basis = stats_basis()
        daily = dashboard_stats().get("dailyRoutine") or {}
        session_path = daily.get("sessionPath") or "/sessao"
        grounded_cites: list[dict[str, Any]] = []
        lines: list[str] = [
            "Tutor sem internet · fontes locais alinhadas ao pedido:",
            "",
        ]
        if q_cites:
            grounded_cites.extend(q_cites[:5])
            for cite in grounded_cites:
                label = cite.get("label") or "fonte local"
                snippet = (cite.get("snippet") or "")[:180]
                lines.append(f"• {label}: {snippet}" if snippet else f"• {label}")
        has_local_off = bool(grounded_cites)
        if not has_local_off:
            answer = (
                "Sem base local para esta pergunta.\n\n"
                "Não há trechos de questões/resoluções oficiais na base alinhados ao pedido. "
                "Abra Biblioteca (2024–26) ou a Fila com preferNatureza=1 — o tutor não inventa cobranca UEMA.\n\n"
                f"Próximo passo: {session_path}"
            )
            return ChatResponse(
                answer=answer,
                model=f"offline-no-base-{rag_mode}",
                usedRag=False,
                citations=[],
                ragMode=rag_mode,
                hasLocalBase=False,
                uncited=True,
            )
        lines.append("")
        lines.append(f"Próximo passo: sessão em {session_path}")
        lines.append("Pergunta: qual distrator você eliminaria primeiro e por quê?")
        lines.append("")
        lines.append(
            "[Aviso] Offline grounded na base local. Não inventa % de cobrança UEMA."
            + ("" if basis.get("basis") == "oficial" else " Stats ainda em treino.")
            + " Configure GEMINI_API_KEY ou OPENAI_API_KEY para diálogo completo."
        )
        answer = "\n".join(lines)
        return ChatResponse(
            answer=answer,
            model=f"offline-grounded-{rag_mode}",
            usedRag=True,
            citations=grounded_cites[:8],
            ragMode=rag_mode,
            hasLocalBase=True,
            uncited=False,
        )

    if not has_local or not q_cites:
        # Sem questão local: ensina o conceito, mas não atribui incidência oficial.
        uncited_content = (
            f"{user_content}\n\n"
            "AVISO DE FONTE: não há questão local alinhada a esta pergunta. "
            "Isso não impede o ensino do conteúdo geral: explique-o com clareza "
            "e, se o aluno tiver pedido um dado sobre a prova ou a banca, diga "
            "apenas que a base local não sustenta esse dado. Não substitua a "
            "explicação por uma recusa."
        )
        answer = _ask_provider(provider, TUTOR_SYSTEM, uncited_content, payload.history)
        return ChatResponse(
            answer=answer,
            model=provider_model(provider),
            usedRag=False,
            citations=[],
            ragMode=rag_mode,
            hasLocalBase=False,
            uncited=True,
        )

    answer = _ask_provider(provider, TUTOR_SYSTEM, user_content, payload.history)
    model = provider_model(provider)
    return ChatResponse(
        answer=answer,
        model=model,
        usedRag=True,
        citations=q_cites[:8],
        ragMode=rag_mode,
        hasLocalBase=True,
        uncited=False,
    )


@router.post("/api/chat", response_model=ChatResponse)
def api_chat(payload: ChatRequest) -> ChatResponse:
    first_error: HTTPException | None = None
    providers = configured_providers()
    preferred = _configured_provider()
    if preferred and preferred not in providers:
        providers.insert(0, preferred)
    for candidate in ("gemini", "groq", "openrouter", "openai"):
        if provider_configured(candidate) and candidate not in providers:
            providers.append(candidate)
    for provider in providers:
        try:
            return _api_chat(payload, provider_override=provider)
        except HTTPException as error:
            first_error = first_error or error
    try:
        return _api_chat(payload, force_offline=True)
    except HTTPException:
        if first_error is not None:
            raise first_error from None
        raise

@router.post("/api/rag/reindex")
def api_rag_reindex() -> dict[str, Any]:
    return index_all_questions()

def _professor_draft(question: dict[str, Any]) -> dict[str, Any]:
    """Rascunho explicitamente revisável; nunca declara explicação oficial da banca."""
    base = question.get("professorMode") or {}
    resolution = base.get("resolution") or question.get("resolution") or ""
    if _openai_client() is not None:
        prompt = (
            "Crie uma resolução didática curta para a questão abaixo, sem inventar fatos fora do enunciado. "
            "Depois explique intenção da banca, macete e pegadinha em blocos identificáveis.\n\n"
            f"Disciplina: {question['subject']}\nTópico: {question['topic']}\nEnunciado: {question['statement']}\n"
            f"Alternativas: {question['options']}"
        )
        try:
            resolution = _ask_openai(
                "Você é professor do PAES/UEMA. Produza um rascunho que exige revisão humana.",
                prompt,
            )
        except HTTPException:
            pass
    return {
        "questionId": question["id"],
        "resolution": resolution,
        "bancaIntent": base.get("bancaIntent") or question.get("bancaIntent") or "",
        "macete": base.get("macete") or question.get("macete") or "",
        "pegadinha": base.get("pegadinha") or question.get("pegadinha") or "",
        "relatedTopics": base.get("relatedTopics") or question.get("relatedTopics") or [],
        "draft": True,
        "message": "Rascunho do professor: revise e envie para /api/professor/accept antes de salvar.",
    }

@router.post("/api/professor/generate")
def api_professor_generate(payload: ProfessorGenerateRequest) -> dict[str, Any]:
    from services_core import is_official_source, stats_basis

    question = get_question(payload.questionId)
    if not question:
        raise HTTPException(404, "Questão não encontrada")
    basis = stats_basis()
    if basis["officialCount"] >= 10 and not is_official_source(question.get("source"), question.get("generated")):
        raise HTTPException(
            400,
            "Com base oficial ativa, gere resoluções só para questões oficiais commitadas "
            "(itens gerados vão para /aprovacao).",
        )
    draft = _professor_draft(question)
    draft["officialOnlyGate"] = basis["officialCount"] >= 10
    return draft

@router.post("/api/professor/accept")
def api_professor_accept(payload: ProfessorAcceptRequest) -> dict[str, Any]:
    with db() as conn:
        row = conn.execute("SELECT id FROM questions WHERE id=?", (payload.questionId,)).fetchone()
        if not row:
            raise HTTPException(404, "Questão não encontrada")
        conn.execute(
            """
            UPDATE questions SET resolution=?, banca_intent=?, macete=?, pegadinha=?, related_topics_json=?
            WHERE id=?
            """,
            (
                payload.resolution,
                payload.bancaIntent,
                payload.macete,
                payload.pegadinha,
                json.dumps(payload.relatedTopics, ensure_ascii=False),
                payload.questionId,
            ),
        )
        conn.commit()
        return {"ok": True, "questionId": payload.questionId, "message": "Blocos do professor salvos."}

@router.post("/api/professor/batch-fill")
def api_professor_batch(payload: ProfessorBatchRequest) -> dict[str, Any]:
    """Preenche blocos vazios/mínimos com templates ricos (revisão humana recomendada)."""
    return fill_professor_drafts(
        limit=payload.limit,
        prefer_uema=payload.preferUema,
        uema_only=payload.uemaOnly,
    )

@router.get("/api/professor/draft-queue")
def api_professor_draft_queue(limit: int = 5, uemaOnly: bool = True) -> dict[str, Any]:
    return list_professor_draft_queue(limit=limit, uema_only=uemaOnly)

@router.post("/api/professor/draft-accept")
def api_professor_draft_accept(payload: ProfessorQueueActionRequest) -> dict[str, Any]:
    result = accept_professor_draft(payload.questionId)
    if not result.get("ok"):
        raise HTTPException(404, result.get("error") or "Questão não encontrada")
    return result

@router.post("/api/professor/draft-skip")
def api_professor_draft_skip(payload: ProfessorQueueActionRequest) -> dict[str, Any]:
    result = skip_professor_draft(payload.questionId)
    if not result.get("ok"):
        raise HTTPException(404, result.get("error") or "Questão não encontrada")
    return result
