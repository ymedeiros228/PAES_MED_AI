"""Rotas: ia."""

from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter, HTTPException

from ai_state import provider_model
from api_helpers import (
    _ask_gemini,
    _ask_openai,
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

router = APIRouter(tags=["ia"])

_FOLLOW_UP_PREFIXES = (
    "explique a resposta anterior",
    "faça uma pergunta curta para testar meu entendimento",
    "transforme a resposta anterior em até 3 flashcards",
)


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


@router.post("/api/chat", response_model=ChatResponse)
def api_chat(payload: ChatRequest) -> ChatResponse:
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
        f"REGRAS: Só use o CONTEXTO. Se faltar fonte, diga que não tem base local — "
        f"não invente % de cobrança UEMA nem resolução de prova ausente. "
        f"Cite ids de questões do contexto quando falar de itens.\n\n"
        f"CONTEXTO DA BASE LOCAL:\n{context}\n\n"
        f"PERGUNTA DO ALUNO:\n{payload.message}"
    )

    q_cites = [
        c
        for c in citations
        if isinstance(c, dict) and c.get("type") == "question" and c.get("id")
    ]
    has_local = bool(q_cites) or bool((context or "").strip())

    provider = _configured_provider()
    if provider is None:
        from services_core import NATUREZA_SUBJECTS, dashboard_stats, list_questions, stats_basis

        basis = stats_basis()
        dash = dashboard_stats()
        daily = dash.get("dailyRoutine") or {}
        subject = daily.get("subject") or "Biologia"
        topic = daily.get("topic") or "Genética"
        session_path = daily.get("sessionPath") or "/sessao"
        hot = dash.get("errorHotTopics") or []
        grounded_cites: list[dict[str, Any]] = []
        lines: list[str] = [
            f"Tutor offline · tópico do dia: {subject} · {topic}",
            "",
        ]
        # Prefer oficiais Natureza no coach Natureza; senão tópico do dia
        prefer_nat = (subject in NATUREZA_SUBJECTS) or "natureza" in (session_path or "").lower()
        pool = list_questions(subject=subject, topic=topic, exam_board="UEMA_PAES", limit=8) or list_questions(
            subject=subject, topic=topic, limit=8
        )
        if prefer_nat and pool:
            nat_pool = [q for q in pool if (q.get("subject") or "") in NATUREZA_SUBJECTS]
            if nat_pool:
                pool = nat_pool + [q for q in pool if q not in nat_pool]
        grounded = 0
        for q in pool[:5]:
            res = (q.get("resolution") or "").strip()
            if not res or res == "—":
                continue
            qid = q.get("id")
            lines.append(f"• Questão {qid} ({q.get('year') or '—'}):")
            for ln in res.splitlines()[:4]:
                if ln.strip():
                    lines.append(f"  {ln.strip()[:200]}")
            grounded_cites.append(
                {
                    "type": "question",
                    "id": qid,
                    "label": f"{q.get('subject')} · {q.get('topic')} ({q.get('year')})",
                    "snippet": (q.get("statement") or "")[:140],
                    "subject": q.get("subject"),
                    "topic": q.get("topic"),
                }
            )
            grounded += 1
            if grounded >= 2:
                break
        if not grounded:
            for cite in q_cites[:3]:
                label = cite.get("label") or cite.get("type") or "fonte"
                snippet = (cite.get("snippet") or "")[:180]
                if snippet:
                    lines.append(f"• {label}: {snippet}")
                else:
                    lines.append(f"• {label}")
                grounded_cites.append(cite)
        # Merge RAG question cites not already used
        seen_ids = {c.get("id") for c in grounded_cites}
        for cite in q_cites:
            if cite.get("id") not in seen_ids:
                grounded_cites.append(cite)
                seen_ids.add(cite.get("id"))
        has_local_off = bool(grounded_cites)
        if hot and has_local_off:
            h0 = hot[0]
            lines.append("")
            lines.append(f"Lacuna quente: {h0.get('key')} ({h0.get('misses')} miss(es)).")
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
            "Ensine o conceito geral com clareza, sem inventar fonte. "
            "É PROIBIDO afirmar percentual de cobrança, incidência UEMA, "
            "gabarito ou resolução de prova que não estejam no contexto."
        )
        if provider == "gemini":
            answer = _ask_gemini(TUTOR_SYSTEM, uncited_content, payload.history)
        else:
            answer = _ask_openai(TUTOR_SYSTEM, uncited_content, payload.history)
        return ChatResponse(
            answer=answer,
            model=provider_model(provider),
            usedRag=False,
            citations=[],
            ragMode=rag_mode,
            hasLocalBase=False,
            uncited=True,
        )

    if provider == "gemini":
        answer = _ask_gemini(TUTOR_SYSTEM, user_content, payload.history)
    else:
        answer = _ask_openai(TUTOR_SYSTEM, user_content, payload.history)
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
