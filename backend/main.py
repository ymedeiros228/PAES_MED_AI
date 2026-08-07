"""PAES MED AI — API local (FastAPI + SQLite + OpenAI opcional)."""

from __future__ import annotations

import json
import os
import shutil
from pathlib import Path
from typing import Any, Literal

from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from db import DATA_DIR, connect, init_db
from seed import seed
from services_core import (
    bank_profile,
    build_exam_countdown,
    build_study_calendar,
    build_study_plan,
    build_tutor_day_plan,
    close_study_day,
    close_study_week,
    curation_health,
    dashboard_stats,
    export_study_day_markdown,
    export_study_week_markdown,
    get_exam_date,
    get_question,
    get_study_plan,
    is_official_source,
    library_search,
    list_library_search_history,
    list_questions,
    mark_topic_read,
    medicine_priority,
    official_axle_health,
    official_curation_inventory,
    predict_topic,
    promote_all_pending_officials,
    promote_natureza_real_resolutions,
    promote_other_axles_real_resolutions,
    set_exam_date,
    stats_basis,
    study_day_close_status,
    study_week_close_status,
    topic_cooccurrence,
    topic_frequency,
    topic_read_status,
    year_pdf_info,
)
from services_extra import (
    TUTOR_SYSTEM,
    accept_professor_draft,
    build_rag_context,
    build_rag_context_with_citations,
    clear_session_checkpoint,
    clear_sim_checkpoint,
    complete_revision,
    create_backup,
    create_natureza_pack,
    create_simulation,
    essay_grade_deltas,
    essay_themes,
    fill_professor_drafts,
    generate_similar_question_stub,
    get_session_checkpoint,
    get_sim_checkpoint,
    grade_simulation,
    ingest_pdf_placeholder,
    essay_progress,
    list_essays,
    list_lessons,
    list_pending_ingest_previews,
    list_professor_draft_queue,
    list_revisions,
    list_study_gaps,
    mark_gap_card_remembered,
    offline_essay_axis_scores,
    parse_gate_flags,
    progress_overview,
    record_answer,
    recover_study_gap,
    remediation_for,
    save_essay,
    save_session_checkpoint,
    save_sim_checkpoint,
    schedule_gap_revisions,
    skip_professor_draft,
    structure_lesson_from_text,
)
from services_advanced import (
    adaptive_training,
    build_rag_context_embedded,
    build_rag_context_embedded_full,
    create_flashcard,
    delete_flashcard,
    flashcard_axis_stats,
    index_all_questions,
    list_flashcards,
    review_flashcard,
    set_plan_day_done,
)
from services_edital import edital_coverage, sync_syllabus_from_edital_file, theory_snippets_for
from services_media import (
    essay_personas,
    list_media_opens,
    list_media_reads,
    list_topic_articles,
    list_topic_videos,
    mark_media_read,
    media_prefs,
    open_media_url,
    persona_by_id,
    serper_configured,
    set_media_prefs,
    youtube_configured,
)
from ingest_pdf import (
    apply_gabarito,
    classify_questions_by_syllabus,
    commit_preview,
    compute_year_statuses,
    extract_pdf_text,
    get_preview,
    import_and_commit_year,
    import_year_pair,
    list_pdf_inventory,
    pair_prova_gabarito,
    parse_gabarito,
    parse_pdf_file,
    update_preview,
)

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1-mini").strip()

app = FastAPI(title="PAES MED AI API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    for sub in ("provas", "gabaritos", "edital", "aulas", "backups", "inventory"):
        (DATA_DIR / sub).mkdir(parents=True, exist_ok=True)
    init_db()
    seed(force=False)
    try:
        from services_advanced import index_all_questions

        index_all_questions(limit=300)
    except Exception:
        pass


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=12000)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=12000)
    history: list[ChatMessage] = Field(default_factory=list, max_length=20)
    style: str | None = Field(
        default="professor",
        description="professor|medico|crianca|analogia|mapa|resumo|macete|flashcard",
    )


class ChatResponse(BaseModel):
    answer: str
    model: str
    usedRag: bool = True
    citations: list[dict[str, Any]] = Field(default_factory=list)
    ragMode: str | None = None
    hasLocalBase: bool = True
    uncited: bool = False


class AnswerRequest(BaseModel):
    questionId: str
    correct: bool
    subject: str
    topic: str
    errorType: str | None = None
    timeMs: int | None = None


class SimulationRequest(BaseModel):
    mode: str = "prova_completa"
    subject: str | None = None
    topic: str | None = None
    difficulty: str | None = None
    year: int | None = None
    limit: int = 10


class GradeRequest(BaseModel):
    answers: list[dict[str, Any]]


class LessonTextRequest(BaseModel):
    title: str
    transcript: str = Field(min_length=20, max_length=200000)
    sourceType: str = "legenda"
    sourceRef: str | None = None


class EssayRequest(BaseModel):
    theme: str
    text: str = Field(min_length=50, max_length=20000)
    persona: str | None = None
    focusAxis: str | None = None


class PlanRequest(BaseModel):
    days: int = 30
    examDate: str | None = None


class GenerateQuestionRequest(BaseModel):
    subject: str
    topic: str


def _openai_client():
    if not OPENAI_API_KEY or OPENAI_API_KEY == "cole_sua_chave_aqui":
        return None
    from openai import OpenAI

    return OpenAI(api_key=OPENAI_API_KEY)


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
        raise HTTPException(
            status_code=502,
            detail=f"Falha OpenAI ({type(exc).__name__}).",
        ) from exc


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "PAES MED AI API", "docs": "/docs", "health": "/health"}


@app.get("/health")
def health() -> dict[str, Any]:
    conn = connect()
    try:
        nq = conn.execute("SELECT COUNT(*) AS c FROM questions").fetchone()["c"]
    finally:
        conn.close()
    basis = stats_basis()
    cur = official_curation_inventory()
    health_gate = curation_health()
    provas = DATA_DIR / "provas"
    gabaritos = DATA_DIR / "gabaritos"
    edital = DATA_DIR / "edital"
    return {
        "status": "ok",
        "openai_configured": bool(OPENAI_API_KEY and OPENAI_API_KEY != "cole_sua_chave_aqui"),
        "youtube_configured": youtube_configured(),
        "serper_configured": serper_configured(),
        "model": OPENAI_MODEL,
        "questions": nq,
        "officialCount": basis.get("officialCount", 0),
        "statsBasis": basis.get("basis"),
        "dataDir": str(DATA_DIR),
        "pdfCounts": {
            "provas": len(list(provas.glob("*.pdf"))) if provas.is_dir() else 0,
            "gabaritos": len(list(gabaritos.glob("*.pdf"))) if gabaritos.is_dir() else 0,
            "edital": (
                (len(list(edital.glob("*.pdf"))) + len(list(edital.glob("*.md")))) if edital.is_dir() else 0
            ),
        },
        "curation": {
            "realCount": cur.get("realCount", 0),
            "realPercent": cur.get("realPercent", 0),
            "crossDomainCount": cur.get("crossDomainCount", 0),
            "naturezaCount": cur.get("naturezaCount", 0),
            "naturezaReal": health_gate.get("naturezaReal"),
            "naturezaFloorOk": health_gate.get("naturezaFloorOk"),
            "status": health_gate.get("status"),
            "message": health_gate.get("message") or cur.get("message"),
            "alerts": health_gate.get("alerts") or [],
        },
    }


@app.post("/api/seed")
def api_seed(force: bool = False) -> dict[str, Any]:
    return seed(force=force)


@app.get("/api/questions")
def api_questions(
    subject: str | None = None,
    topic: str | None = None,
    year: int | None = None,
    difficulty: str | None = None,
    medicine: bool = False,
    source: str | None = None,
    examBoard: str | None = None,
    similares: bool = False,
    approved: str | None = None,
    officialWithGab: bool = False,
    limit: int | None = 200,
    offset: int = 0,
) -> list[dict[str, Any]]:
    approved_only: bool | None = None
    if approved == "1" or approved == "true":
        approved_only = True
    elif approved == "0" or approved == "false":
        approved_only = False
    # Ciclo HL: chip «Só oficiais com gab» = UEMA + fonte PDF/ingest
    if officialWithGab:
        examBoard = "UEMA_PAES"
        source = source or "oficial"
    return list_questions(
        subject,
        topic,
        year,
        difficulty,
        medicine,
        source_kind=source,
        exam_board=examBoard,
        similares_only=similares,
        approved_only=approved_only,
        limit=limit,
        offset=offset,
    )


class ApprovalRequest(BaseModel):
    questionId: str
    approve: bool = True


@app.get("/api/approval/pending")
def api_questions_pending(limit: int = 50) -> list[dict[str, Any]]:
    return list_questions(approved_only=False, limit=limit)


@app.post("/api/approval/decide")
def api_questions_approve(payload: ApprovalRequest) -> dict[str, Any]:
    conn = connect()
    try:
        row = conn.execute("SELECT id FROM questions WHERE id=?", (payload.questionId,)).fetchone()
        if not row:
            raise HTTPException(404, "Questão não encontrada")
        if payload.approve:
            conn.execute("UPDATE questions SET approved=1 WHERE id=?", (payload.questionId,))
            conn.commit()
            return {"ok": True, "questionId": payload.questionId, "approved": True}
        conn.execute("DELETE FROM questions WHERE id=?", (payload.questionId,))
        conn.commit()
        return {"ok": True, "questionId": payload.questionId, "deleted": True}
    finally:
        conn.close()


@app.get("/api/questions/{question_id}")
def api_question(question_id: str) -> dict[str, Any]:
    q = get_question(question_id)
    if not q:
        raise HTTPException(404, "Questão não encontrada")
    return q


@app.get("/api/syllabus")
def api_syllabus() -> list[dict[str, Any]]:
    conn = connect()
    try:
        return [dict(r) for r in conn.execute("SELECT * FROM syllabus ORDER BY subject, topic").fetchall()]
    finally:
        conn.close()


@app.get("/api/stats/frequency")
def api_frequency() -> list[dict[str, Any]]:
    return topic_frequency()


@app.get("/api/stats/medicine")
def api_medicine() -> dict[str, Any]:
    inv = official_curation_inventory()
    return {
        "items": medicine_priority(),
        "statsBasis": stats_basis(),
        "curation": {
            "realCount": inv.get("realCount"),
            "realPercent": inv.get("realPercent"),
            "crossDomainCount": inv.get("crossDomainCount"),
            "naturezaCount": inv.get("naturezaCount"),
            "naturezaBySubject": inv.get("naturezaBySubject"),
            "resolutionQuality": inv.get("resolutionQuality"),
            "message": inv.get("message"),
        },
    }


@app.get("/api/curation/inventory")
def api_curation_inventory() -> dict[str, Any]:
    return official_curation_inventory()


@app.get("/api/curation/health")
def api_curation_health() -> dict[str, Any]:
    """Gate anti-regressão Natureza + contagens honestas (Ciclo D)."""
    return curation_health()


class CurationPromoteRequest(BaseModel):
    limit: int = Field(default=8, ge=1, le=40)


@app.post("/api/curation/promote-natureza-real")
def api_curation_promote_natureza(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Eleva floor de resoluções Natureza para quality=real (didático local)."""
    limit = (payload.limit if payload is not None else 8)
    return promote_natureza_real_resolutions(limit=limit)


@app.post("/api/curation/promote-other-real")
def api_curation_promote_other(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Floor leve oficiais fora de Natureza — não mexe na Natureza (Ciclo D)."""
    limit = (payload.limit if payload is not None else 12)
    return promote_other_axles_real_resolutions(limit=limit)


@app.post("/api/curation/promote-all-pending")
def api_curation_promote_all(payload: CurationPromoteRequest | None = None) -> dict[str, Any]:
    """Natureza primeiro, depois outras áreas (Ciclo E)."""
    limit = (payload.limit if payload is not None else 40)
    return promote_all_pending_officials(limit=limit)


@app.get("/api/curation/axles")
def api_curation_axles() -> dict[str, Any]:
    return official_axle_health()


@app.get("/api/study/day-close")
def api_study_day_close_status() -> dict[str, Any]:
    return study_day_close_status()


@app.post("/api/study/day-close")
def api_study_day_close() -> dict[str, Any]:
    return close_study_day()


class ExamDatePayload(BaseModel):
    examDate: str | None = None


@app.get("/api/study/exam-date")
def api_study_exam_date_get() -> dict[str, Any]:
    return {"ok": True, "examDate": get_exam_date(), "countdown": build_exam_countdown()}


@app.post("/api/study/exam-date")
def api_study_exam_date_set(payload: ExamDatePayload) -> dict[str, Any]:
    try:
        return set_exam_date(payload.examDate)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/api/study/week-close")
def api_study_week_close_status() -> dict[str, Any]:
    return study_week_close_status()


@app.post("/api/study/week-close")
def api_study_week_close() -> dict[str, Any]:
    return close_study_week()


class MarkReadPayload(BaseModel):
    subject: str = Field(min_length=1, max_length=120)
    topic: str = Field(min_length=1, max_length=200)


@app.post("/api/study/mark-read")
def api_study_mark_read(payload: MarkReadPayload) -> dict[str, Any]:
    out = mark_topic_read(payload.subject, payload.topic)
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "payload inválido")
    return out


@app.get("/api/study/reads")
def api_study_reads(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    return topic_read_status(subject, topic)


@app.get("/api/study/calendar")
def api_study_calendar(days: int = 28) -> dict[str, Any]:
    return build_study_calendar(days=max(7, min(int(days or 28), 90)))


@app.get("/api/study/readiness")
def api_study_readiness() -> dict[str, Any]:
    dash = dashboard_stats()
    return dash.get("readiness") or {"ok": True, "score": 0}


@app.get("/api/stats/bank-profile")
def api_bank_profile() -> dict[str, Any]:
    return bank_profile()


@app.post("/api/stats/bank-profile/export")
def api_bank_profile_export() -> dict[str, Any]:
    profile = bank_profile()
    basis = stats_basis()
    destination = DATA_DIR / "perfil_banca.md"
    years_used: list[int] = []
    heat = profile.get("heatmap") or {}
    for years in heat.values():
        for y in years:
            try:
                years_used.append(int(y))
            except (TypeError, ValueError):
                pass
    years_used = sorted(set(years_used))
    lines = [
        "# Como a UEMA cobra — perfil da banca (operacional)",
        "",
        f"Base usada: **{profile.get('basis', 'treino')}** · oficiais={basis.get('officialCount', 0)} · treino={basis.get('trainingCount', 0)}.",
        f"Anos na amostra: {', '.join(map(str, years_used)) or '—'}.",
        profile.get("disclaimer", ""),
        "",
        f"- Questões analisadas: {profile.get('totalQuestions', 0)}",
        f"- Tamanho médio do enunciado: {profile.get('avgStatementLen', 0)}",
        f"- Viés de gabarito (A–E): {json.dumps(profile.get('correctLetterBias', {}), ensure_ascii=False)}",
        f"- Verbos mais comuns: {json.dumps(profile.get('topVerbs', [])[:10], ensure_ascii=False)}",
        f"- Distribuição por disciplina: {json.dumps(profile.get('subjectDistribution', {}), ensure_ascii=False)}",
        f"- Dificuldade: {json.dumps(profile.get('difficultyDistribution', {}), ensure_ascii=False)}",
        "",
        "## Coocorrência de tópicos",
    ]
    lines.extend(
        f"- {item['a']} × {item['b']}: {item['count']}"
        for item in profile.get("cooccurrence", [])
    )
    lines.extend(["", "## Heatmap (disciplina × ano)", ""])
    for subject, years in sorted(heat.items()):
        lines.append(f"- **{subject}**: {json.dumps(years, ensure_ascii=False)}")
    lines.extend(
        [
            "",
            "---",
            "Estimativa local — não inventa incidência sem PDF oficial commitado.",
        ]
    )
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return {
        "ok": True,
        "path": str(destination),
        "basis": profile.get("basis"),
        "yearsUsed": years_used,
        "statsBasis": basis,
    }


@app.get("/api/stats/cooccurrence")
def api_cooccurrence(limit: int = 20) -> dict[str, Any]:
    return {"items": topic_cooccurrence(limit=max(1, min(limit, 100))), "statsBasis": stats_basis()}


@app.get("/api/stats/basis")
def api_stats_basis() -> dict[str, Any]:
    return stats_basis()


@app.get("/api/stats/predict")
def api_predict(subject: str, topic: str) -> dict[str, Any]:
    return predict_topic(subject, topic)


@app.get("/api/dashboard")
def api_dashboard() -> dict[str, Any]:
    return dashboard_stats()


@app.get("/api/remediation")
def api_remediation(errorType: str = "conceito", subject: str = "", topic: str = "") -> dict[str, Any]:
    return remediation_for(errorType, subject, topic)


@app.get("/api/gaps")
def api_gaps(status: str = "open", limit: int = 40) -> dict[str, Any]:
    return list_study_gaps(status=status, limit=limit)


class GapRecoverRequest(BaseModel):
    subject: str
    topic: str


@app.post("/api/gaps/recover")
def api_gaps_recover(payload: GapRecoverRequest) -> dict[str, Any]:
    return recover_study_gap(payload.subject, payload.topic)


@app.post("/api/answers")
def api_answers(payload: AnswerRequest) -> dict[str, Any]:
    return record_answer(
        payload.questionId,
        payload.correct,
        payload.subject,
        payload.topic,
        payload.errorType,
        payload.timeMs,
    )


@app.get("/api/revisions")
def api_revisions() -> list[dict[str, Any]]:
    return list_revisions()


@app.post("/api/revisions/complete")
def api_revisions_complete(subject: str, topic: str) -> dict[str, Any]:
    return complete_revision(subject, topic)


@app.post("/api/plans/generate")
def api_plans_generate(payload: PlanRequest) -> list[dict[str, Any]]:
    if payload.days not in (30, 60, 90) and payload.days < 1:
        raise HTTPException(400, "days inválido")
    days = payload.days if payload.days in (30, 60, 90) else max(7, min(payload.days, 180))
    return build_study_plan(days, payload.examDate)


@app.get("/api/plans/{days}")
def api_plans_get(days: int) -> list[dict[str, Any]]:
    return get_study_plan(days)


@app.post("/api/simulations")
def api_simulations(payload: SimulationRequest) -> dict[str, Any]:
    return create_simulation(
        payload.mode,
        payload.subject,
        payload.topic,
        payload.difficulty,
        payload.year,
        payload.limit,
    )


@app.post("/api/simulations/grade")
def api_simulations_grade(payload: GradeRequest) -> dict[str, Any]:
    return grade_simulation(payload.answers)


@app.post("/api/chat", response_model=ChatResponse)
def api_chat(payload: ChatRequest) -> ChatResponse:
    citations: list[dict[str, Any]] = []
    try:
        context, rag_mode, citations = build_rag_context_embedded_full(payload.message)
    except Exception:
        try:
            context, citations = build_rag_context_with_citations(payload.message)
            rag_mode = "keyword"
        except Exception:
            context, rag_mode = build_rag_context(payload.message), "keyword"
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

    client = _openai_client()
    if client is None:
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
            + " Configure OPENAI_API_KEY para diálogo completo."
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
        # Online sem ids reais: recusa honesta (não bola de cristal)
        return ChatResponse(
            answer=(
                "Sem base local suficiente para responder com fonte.\n\n"
                "A busca na base não trouxe questões com id real alinhadas à pergunta. "
                "Importe provas 2024–26 ou abra uma sessão — não invento resolução nem % de cobrança UEMA."
            ),
            model=f"{OPENAI_MODEL}-uncited-refuse",
            usedRag=False,
            citations=[],
            ragMode=rag_mode,
            hasLocalBase=False,
            uncited=True,
        )

    answer = _ask_openai(TUTOR_SYSTEM, user_content, payload.history)
    return ChatResponse(
        answer=answer,
        model=OPENAI_MODEL,
        usedRag=True,
        citations=q_cites[:8],
        ragMode=rag_mode,
        hasLocalBase=True,
        uncited=False,
    )


@app.post("/api/lessons/from-text")
def api_lessons_from_text(payload: LessonTextRequest) -> dict[str, Any]:
    llm_payload = None
    client = _openai_client()
    if client is not None:
        prompt = (
            "Estruture a aula em JSON com chaves: subject, topic, difficulty, summary, "
            "macetes (lista), keywords (lista), flashcards (lista de {front,back}), "
            "questions (lista de enunciados curtos). Foque no PAES/UEMA. Texto:\n"
            + payload.transcript[:12000]
        )
        raw = _ask_openai(
            "Você organiza aulas para o PAES/UEMA. Responda SÓ JSON válido.",
            prompt,
        )
        try:
            start = raw.find("{")
            end = raw.rfind("}") + 1
            llm_payload = json.loads(raw[start:end])
        except Exception:
            llm_payload = None
    return structure_lesson_from_text(
        payload.title,
        payload.transcript,
        payload.sourceType,
        payload.sourceRef,
        llm_payload,
    )


@app.post("/api/lessons/from-audio")
async def api_lessons_from_audio(
    title: str = "Aula importada",
    file: UploadFile = File(...),
) -> dict[str, Any]:
    """Transcreve com Whisper (OpenAI) se houver chave; senão orienta colar legenda."""
    aulas = DATA_DIR / "aulas"
    aulas.mkdir(parents=True, exist_ok=True)
    dest = aulas / (file.filename or f"audio_{title}.bin")
    with dest.open("wb") as f:
        shutil.copyfileobj(file.file, f)

    client = _openai_client()
    if client is None:
        return {
            "ok": False,
            "savedPath": str(dest),
            "message": (
                "Áudio salvo. Sem OPENAI_API_KEY não há Whisper. "
                "Cole a legenda/transcrição em /api/lessons/from-text."
            ),
        }
    try:
        with dest.open("rb") as audio_f:
            tr = client.audio.transcriptions.create(model="whisper-1", file=audio_f)
        transcript = getattr(tr, "text", None) or str(tr)
    except Exception as exc:
        raise HTTPException(502, f"Falha Whisper: {type(exc).__name__}") from exc

    return structure_lesson_from_text(title, transcript, "audio", str(dest), None)


@app.get("/api/lessons")
def api_lessons() -> list[dict[str, Any]]:
    return list_lessons()


@app.post("/api/ingest/pdf")
async def api_ingest_pdf(
    kind: str = "prova",
    year: int | None = None,
    subject: str = "Geral",
    file: UploadFile = File(...),
) -> dict[str, Any]:
    if kind not in ("prova", "gabarito", "edital"):
        raise HTTPException(400, "kind deve ser prova|gabarito|edital")
    folder = DATA_DIR / ("provas" if kind == "prova" else "gabaritos" if kind == "gabarito" else "edital")
    folder.mkdir(parents=True, exist_ok=True)
    dest = folder / (file.filename or "arquivo.pdf")
    with dest.open("wb") as f:
        shutil.copyfileobj(file.file, f)
    try:
        return parse_pdf_file(dest, kind, year=year, subject=subject)
    except Exception as exc:
        ingest_pdf_placeholder(dest.name, kind)
        raise HTTPException(500, f"Falha ao parsear PDF: {type(exc).__name__}: {exc}") from exc


class CommitIngestRequest(BaseModel):
    previewId: str
    questions: list[dict[str, Any]] | None = None
    highConfidenceOnly: bool = False
    minConfidence: float = 0.55
    autoProfessor: bool = True
    allowWithoutGabarito: bool = False


class UpdatePreviewRequest(BaseModel):
    previewId: str
    questions: list[dict[str, Any]]


class IngestFromDataRequest(BaseModel):
    kind: Literal["prova", "gabarito", "edital"]
    filename: str
    year: int | None = None
    subject: str = "Geral"


class ApplyGabaritoRequest(BaseModel):
    year: int


class ImportYearRequest(BaseModel):
    year: int = Field(ge=1900, le=2100)
    commit: bool = False


class ImportYearSafeRequest(BaseModel):
    year: int = Field(ge=1900, le=2100)
    commit: bool = True
    minConfidence: float = 0.55
    skipIfCommitted: bool = False


@app.post("/api/ingest/commit")
def api_ingest_commit(payload: CommitIngestRequest) -> dict[str, Any]:
    create_backup()
    result = commit_preview(
        payload.previewId,
        payload.questions,
        high_confidence_only=payload.highConfidenceOnly,
        min_confidence=payload.minConfidence,
        allow_without_gabarito=payload.allowWithoutGabarito,
    )
    if not result.get("ok"):
        raise HTTPException(400, result.get("message", "Commit falhou"))
    if payload.autoProfessor and int(result.get("inserted") or 0) > 0:
        result["professor"] = fill_professor_drafts(
            limit=max(40, int(result.get("inserted") or 20)),
            prefer_uema=True,
        )
    sp = result.get("sessionPath") or "/sessao?examBoard=UEMA_PAES"
    if "preferNatureza" not in sp:
        sp = f"{sp}&preferNatureza=1" if "?" in sp else f"{sp}?preferNatureza=1"
    result["sessionPath"] = sp
    try:
        result["rag"] = index_all_questions()
    except Exception as exc:
        result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
    return result


@app.post("/api/ingest/from-data")
def api_ingest_from_data(payload: IngestFromDataRequest) -> dict[str, Any]:
    folders = {"prova": "provas", "gabarito": "gabaritos", "edital": "edital"}
    filename = Path(payload.filename).name
    if filename != payload.filename or not filename.lower().endswith(".pdf"):
        raise HTTPException(400, "filename deve ser um PDF existente nas pastas de dados.")
    path = DATA_DIR / folders[payload.kind] / filename
    if not path.is_file():
        raise HTTPException(404, "PDF não encontrado na pasta de dados.")
    return parse_pdf_file(path, payload.kind, payload.year, payload.subject)


@app.post("/api/ingest/import-year")
def api_ingest_import_year(payload: ImportYearRequest) -> dict[str, Any]:
    try:
        result = import_and_commit_year(payload.year) if payload.commit else import_year_pair(payload.year)
        if payload.commit and result.get("commit", {}).get("ok"):
            try:
                result["rag"] = index_all_questions()
            except Exception as exc:
                result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        return result
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except Exception as exc:
        raise HTTPException(500, f"Falha ao importar {payload.year}: {type(exc).__name__}: {exc}") from exc


@app.post("/api/acervo/import-year-safe")
def api_acervo_import_year_safe(payload: ImportYearSafeRequest) -> dict[str, Any]:
    """Preview + commit high-conf só com gabarito; senão devolve needsGabarito (HH)."""
    from acervo_fetch import import_year_safe

    result = import_year_safe(
        payload.year,
        commit=payload.commit,
        min_confidence=payload.minConfidence,
        skip_if_committed=payload.skipIfCommitted,
    )
    if not result.get("ok") and result.get("needsProva"):
        raise HTTPException(400, result.get("message") or "Sem prova no disco")
    if result.get("committed") and result.get("ok"):
        try:
            result["rag"] = index_all_questions()
        except Exception as exc:
            result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        if payload.commit and int(result.get("inserted") or 0) > 0:
            result["professor"] = fill_professor_drafts(
                limit=max(40, int(result.get("inserted") or 20)),
                prefer_uema=True,
            )
    return result


@app.post("/api/ingest/classify-pending")
def api_ingest_classify_pending() -> dict[str, Any]:
    """Reclassifica tópicos fracos, oficiais Natureza/Humanas e cross-domain (Ciclo X/Y/K)."""
    from ingest_pdf import refine_natureza_subject
    from services_core import is_cross_domain, is_official_source, official_curation_inventory

    updated = 0
    subject_changed = 0
    cross_fixed = 0
    n_candidates = 0
    conn = connect()
    try:
        rows = conn.execute(
            """
            SELECT id, subject, topic, subtopic, statement, options_json, source, generated, exam_board
            FROM questions
            WHERE topic='A classificar'
               OR subject IN ('Geral', 'Ciências da Natureza', 'A classificar', 'Matemática')
               OR (
                    COALESCE(generated,0)=0
                    AND (
                        LOWER(COALESCE(source,'')) LIKE '%pdf%'
                        OR LOWER(COALESCE(source,'')) LIKE '%ingest%'
                        OR LOWER(COALESCE(source,'')) LIKE '%oficial%'
                        OR UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES'
                    )
               )
            """
        ).fetchall()
        by_id: dict[str, Any] = {}
        for row in rows:
            by_id[str(row["id"])] = row
        questions = []
        for row in by_id.values():
            questions.append(
                {
                    "id": row["id"],
                    "subject": row["subject"],
                    "topic": row["topic"],
                    "subtopic": row["subtopic"],
                    "statement": row["statement"],
                    "options": json.loads(row["options_json"] or "[]"),
                    "_force": is_cross_domain(row["subject"], row["topic"])
                    or (
                        (row["subject"] or "") in ("Biologia", "Química", "Física")
                        and is_official_source(row["source"], row["generated"])
                    ),
                }
            )
        n_candidates = len(questions)
        classified = classify_questions_by_syllabus(questions)
        humanas = {
            "História",
            "Geografia",
            "Filosofia",
            "Sociologia",
            "Língua Portuguesa e Literatura",
            "Linguagens",
        }
        natureza = {"Biologia", "Química", "Física"}
        topic_to_nat = {
            "cinemática": "Física",
            "cinematica": "Física",
            "dinâmica": "Física",
            "dinamica": "Física",
            "óptica": "Física",
            "optica": "Física",
            "eletromagnetismo": "Física",
            "termodinâmica": "Física",
            "estequiometria": "Química",
            "equilibrio quimico": "Química",
            "equilíbrio químico": "Química",
            "cinética química": "Química",
            "genetica": "Biologia",
            "genética": "Biologia",
            "ecologia": "Biologia",
            "citologia": "Biologia",
        }
        for original, question in zip(questions, classified):
            new_subj = question.get("subject")
            new_topic = question.get("topic")
            if (new_subj or "") in humanas and is_cross_domain(new_subj, new_topic):
                tl = (new_topic or "").lower()
                forced = None
                for key, sub in topic_to_nat.items():
                    if key in tl:
                        forced = sub
                        break
                if not forced:
                    refined = refine_natureza_subject(
                        str(original.get("statement") or ""),
                        list(original.get("options") or []),
                        "Ciências da Natureza",
                    )
                    if refined in natureza:
                        forced = refined
                if forced:
                    new_subj = forced
                    question["subject"] = forced
                    cross_fixed += 1
            if (new_subj or "") in natureza and is_cross_domain(new_subj, new_topic):
                new_topic = f"Conceitos de {new_subj}"
                question["topic"] = new_topic
                cross_fixed += 1
            if new_topic == "A classificar" and new_subj == original.get("subject"):
                if not original.get("_force"):
                    continue
            if (
                new_subj != original.get("subject")
                or new_topic != original.get("topic")
                or question.get("subtopic") != original.get("subtopic")
            ):
                conn.execute(
                    "UPDATE questions SET subject=?, topic=?, subtopic=?, syllabus_id=? WHERE id=?",
                    (
                        new_subj,
                        new_topic,
                        question.get("subtopic"),
                        question.get("syllabusId"),
                        question["id"],
                    ),
                )
                updated += 1
                if new_subj != original.get("subject"):
                    subject_changed += 1
        conn.commit()
    finally:
        conn.close()

    inv = official_curation_inventory()
    residual = int(inv.get("crossDomainCount") or 0)
    residual_sample = (inv.get("crossDomainSample") or [])[:8]
    bank_export: dict[str, Any] = {"ok": False}
    try:
        profile = bank_profile()
        bank_export = {
            "ok": True,
            "officialYears": profile.get("yearsUsed") or profile.get("years"),
            "topicCount": len(profile.get("topicFrequency") or profile.get("topics") or []),
        }
    except Exception:  # noqa: BLE001
        bank_export = {"ok": False}

    return {
        "ok": True,
        "candidates": n_candidates,
        "updated": updated,
        "subjectChanged": subject_changed,
        "crossDomainFixed": cross_fixed,
        "residualCrossDomain": residual,
        "residualSample": residual_sample,
        "bySubject": inv.get("bySubject"),
        "bankProfile": bank_export,
        "message": (
            f"Reclassificados {updated} · cross-domain corrigidos {cross_fixed} · residual {residual}."
        ),
        "disclaimer": "Relatório da base local — não inventa incidência UEMA.",
    }


@app.get("/api/curation/dirty-labels")
def api_curation_dirty_labels(limit: int = 40) -> dict[str, Any]:
    from services_core import list_dirty_labels

    return list_dirty_labels(limit=max(1, min(int(limit or 40), 80)))


@app.post("/api/ingest/apply-gabarito")
def api_ingest_apply_gabarito(payload: ApplyGabaritoRequest) -> dict[str, Any]:
    candidates = [
        item for item in list_pdf_inventory()
        if item["kind"] == "gabarito" and item.get("year") == payload.year
    ]
    if not candidates:
        raise HTTPException(404, f"Gabarito de {payload.year} não encontrado.")
    gabarito = parse_gabarito(extract_pdf_text(Path(candidates[-1]["path"])))
    if not gabarito:
        raise HTTPException(422, "Não foi possível identificar respostas A–E no gabarito.")
    conn = connect()
    try:
        rows = conn.execute(
            """
            SELECT id, source, correct_index FROM questions
            WHERE year=? AND generated=0
              AND (LOWER(COALESCE(source,'')) LIKE '%pdf%' OR LOWER(COALESCE(source,'')) LIKE '%ingest%' OR LOWER(COALESCE(source,'')) LIKE '%oficial%')
            ORDER BY id
            """,
            (payload.year,),
        ).fetchall()
        questions = [
            {"id": r["id"], "number": int((r["source"] or "0_0").rsplit("_", 1)[-1]) if (r["source"] or "").rsplit("_", 1)[-1].isdigit() else index}
            for index, r in enumerate(rows, start=1)
        ]
        merged = apply_gabarito(questions, gabarito)
        updated = 0
        for question in merged:
            if question.get("gabaritoApplied"):
                conn.execute("UPDATE questions SET correct_index=? WHERE id=?", (question["correctIndex"], question["id"]))
                updated += 1
        conn.commit()
    finally:
        conn.close()
    return {"ok": True, "year": payload.year, "answersFound": len(gabarito), "updated": updated}


@app.post("/api/ingest/preview/update")
def api_ingest_preview_update(payload: UpdatePreviewRequest) -> dict[str, Any]:
    result = update_preview(payload.previewId, payload.questions)
    if not result.get("ok"):
        raise HTTPException(400, result.get("message", "Update falhou"))
    return result


@app.get("/api/ingest/preview/{preview_id}")
def api_ingest_preview_get(preview_id: str) -> dict[str, Any]:
    data = get_preview(preview_id)
    if not data:
        raise HTTPException(404, "Preview não encontrado")
    return data


@app.get("/api/essay/themes")
def api_essay_themes() -> list[str]:
    return essay_themes()


@app.get("/api/essays/personas")
def api_essays_personas() -> dict[str, Any]:
    return {"ok": True, "items": essay_personas(), "disclaimer": "Personas = prompts locais · treino, não banca."}


@app.post("/api/essay/grade")
def api_essay_grade(payload: EssayRequest) -> dict[str, Any]:
    client = _openai_client()
    feedback: dict[str, Any]
    score: float
    persona = persona_by_id(payload.persona)
    focus = (payload.focusAxis or (persona or {}).get("focusAxis") or "").strip() or None
    persona_id = (persona or {}).get("id") if persona else (payload.persona or None)
    persona_label = (persona or {}).get("label") if persona else None
    style_line = ""
    if persona:
        style_line = f"Persona: {persona['label']}. Foque o eixo {persona.get('focusAxis')}. {persona.get('hint') or ''}\n"
    if client is None:
        heur = offline_essay_axis_scores(payload.theme, payload.text)
        score = float(heur["score"])
        scores = heur["scores"]
        tips = heur["tips"]
        feedback = {
            **scores,
            "scores": scores,
            "tips": tips,
            "grammarTip": tips["grammar"],
            "cohesionTip": tips["cohesion"],
            "coherenceTip": tips["coherence"],
            "argumentationTip": tips["argumentation"],
            "interventionTip": tips["intervention"],
            "note": (
                "Rascunho offline por eixos (0–10) — NÃO é nota de banca UEMA. "
                "Configure OpenAI para correção mais rica."
            ),
            "offlineHeuristic": True,
            "wordCount": heur["wordCount"],
            "paragraphCount": heur.get("paragraphCount"),
            "persona": persona_id,
            "personaLabel": persona_label,
            "focusAxis": focus,
        }
        # Manter strings de leitura humana nos eixos também (UI antiga)
        for ax, tip in tips.items():
            feedback[f"{ax}_note"] = tip
        if focus in tips:
            feedback["missionHint"] = tips[focus]
    else:
        raw = _ask_openai(
            "Você corrige redações no espírito do PAES/UEMA. Responda JSON com "
            "score (0-10), grammar, cohesion, coherence, argumentation, intervention "
            "(números 0-10), strengths, improvements, tips opcional por eixo. "
            "Nunca invente nota de banca oficial. " + style_line,
            f"Tema: {payload.theme}\nFoco eixo: {focus or 'geral'}\n\nRedação:\n{payload.text}",
        )
        try:
            start = raw.find("{")
            end = raw.rfind("}") + 1
            feedback = json.loads(raw[start:end])
            score = float(feedback.get("score", 7))
        except Exception:
            score = 7.0
            feedback = {"raw": raw, "note": "Não foi possível parsear JSON; segue texto bruto."}
        feedback = dict(feedback) if isinstance(feedback, dict) else {"raw": feedback}
        feedback["persona"] = persona_id
        feedback["personaLabel"] = persona_label
        feedback["focusAxis"] = focus
        if "note" not in feedback:
            feedback["note"] = "Treino local com IA · não é nota de banca UEMA."
    saved = save_essay(payload.theme, payload.text, feedback, score)
    deltas = essay_grade_deltas(payload.theme, feedback if isinstance(feedback, dict) else {})
    out = dict(saved)
    out["deltas"] = deltas
    out["disclaimer"] = "Treino local · não banca UEMA."
    return out


@app.get("/api/essays")
def api_essays() -> list[dict[str, Any]]:
    return list_essays()


@app.get("/api/essays/progress")
def api_essays_progress() -> dict[str, Any]:
    """Progresso agregado de redação local (Ciclo AT/BB/HQ) — sem fingir nota UEMA."""
    return essay_progress()


@app.get("/api/progress/overview")
def api_progress_overview() -> dict[str, Any]:
    """Painel Relevo — cola dashboard + redação + gaps (Ciclo HR)."""
    return progress_overview()

@app.get("/api/media/videos")
def api_media_videos(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Vídeos de reforço do tópico (catálogo local + YouTube opcional)."""
    return list_topic_videos(subject, topic)


@app.get("/api/media/articles")
def api_media_articles(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Artigos/leituras de reforço do tópico (catálogo local + Serper opcional)."""
    return list_topic_articles(subject, topic)


class MediaOpenPayload(BaseModel):
    url: str = Field(min_length=8, max_length=2000)
    kind: str | None = Field(default=None, description="video|article|auto")
    subject: str | None = None
    topic: str | None = None
    title: str | None = None


@app.post("/api/media/open")
def api_media_open(payload: MediaOpenPayload) -> dict[str, Any]:
    out = open_media_url(
        payload.url,
        kind=payload.kind,
        subject=payload.subject,
        topic=payload.topic,
        title=payload.title,
    )
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "Não foi possível abrir")
    return out


@app.get("/api/media/opens")
def api_media_opens(limit: int = 20) -> dict[str, Any]:
    """Histórico local de aberturas de mídia (não é progresso de banca)."""
    return list_media_opens(limit=limit)


class MediaMarkReadPayload(BaseModel):
    url: str = Field(min_length=8, max_length=2000)
    subject: str | None = None
    topic: str | None = None
    title: str | None = None


@app.post("/api/media/mark-read")
def api_media_mark_read(payload: MediaMarkReadPayload) -> dict[str, Any]:
    out = mark_media_read(
        payload.url,
        subject=payload.subject,
        topic=payload.topic,
        title=payload.title,
    )
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "Não foi possível marcar")
    return out


@app.get("/api/media/reads")
def api_media_reads(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Leituras de reforço marcadas localmente (não é edital/oficial)."""
    return list_media_reads(subject, topic)


@app.get("/api/media/prefs")
def api_media_prefs_get() -> dict[str, Any]:
    return {
        "ok": True,
        **media_prefs(),
        "youtubeConfigured": youtube_configured(),
        "serperConfigured": serper_configured(),
    }


class MediaPrefsPayload(BaseModel):
    suggestVideos: bool | None = None
    suggestArticles: bool | None = None


@app.post("/api/media/prefs")
def api_media_prefs_set(payload: MediaPrefsPayload) -> dict[str, Any]:
    return set_media_prefs(
        suggest_videos=payload.suggestVideos,
        suggest_articles=payload.suggestArticles,
    )


class FlashcardCreate(BaseModel):
    front: str
    back: str
    subject: str | None = None
    topic: str | None = None


class FlashcardReview(BaseModel):
    remembered: bool


class PlanDoneRequest(BaseModel):
    days: int
    day: int
    done: bool = True


class AdaptiveRequest(BaseModel):
    subject: str
    topic: str
    nSimilar: int = 10
    nHarder: int = 20
    nGenerated: int = 0


@app.post("/api/questions/generate-similar")
def api_generate_similar(payload: GenerateQuestionRequest) -> dict[str, Any]:
    return generate_similar_question_stub(payload.topic, payload.subject)


@app.post("/api/training/adaptive")
def api_adaptive(payload: AdaptiveRequest) -> dict[str, Any]:
    return adaptive_training(
        payload.subject,
        payload.topic,
        payload.nSimilar,
        payload.nHarder,
        payload.nGenerated,
    )


@app.post("/api/backup")
def api_backup() -> dict[str, Any]:
    return create_backup()


@app.get("/api/backup/last")
def api_backup_last() -> dict[str, Any]:
    from services_extra import last_backup_status

    return last_backup_status()


@app.post("/api/backup/restore")
def api_backup_restore(folderName: str = "", path: str = "") -> dict[str, Any]:
    """Restaura DB a partir de pasta em backups/ ou path zip absoluto."""
    from services_extra import restore_backup_db

    if path:
        return restore_backup_db(path)
    if not folderName:
        raise HTTPException(400, "Informe folderName ou path")
    src = DATA_DIR / "backups" / folderName
    if (src / "paes_med_ai.db").exists():
        return restore_backup_db(str(src))
    zip_path = DATA_DIR / "backups" / folderName
    if zip_path.suffix == ".zip" and zip_path.exists():
        return restore_backup_db(str(zip_path))
    # folderName may be zip filename
    z2 = DATA_DIR / "backups" / f"{folderName}.zip" if not folderName.endswith(".zip") else DATA_DIR / "backups" / folderName
    if z2.exists():
        return restore_backup_db(str(z2))
    raise HTTPException(404, f"Backup não encontrado: {folderName}")


@app.get("/api/flashcards")
def api_flashcards(dueOnly: bool = False, axesOnly: bool = False) -> list[dict[str, Any]]:
    return list_flashcards(due_only=dueOnly, axes_only=axesOnly)


@app.post("/api/flashcards")
def api_flashcards_create(payload: FlashcardCreate) -> dict[str, Any]:
    return create_flashcard(payload.front, payload.back, payload.subject, payload.topic)


@app.post("/api/flashcards/{card_id}/review")
def api_flashcards_review(card_id: int, payload: FlashcardReview) -> dict[str, Any]:
    return review_flashcard(card_id, payload.remembered)


@app.delete("/api/flashcards/{card_id}")
def api_flashcards_delete(card_id: int) -> dict[str, Any]:
    return delete_flashcard(card_id)


@app.post("/api/plans/done")
def api_plans_done(payload: PlanDoneRequest) -> dict[str, Any]:
    return set_plan_day_done(payload.days, payload.day, payload.done)


@app.post("/api/rag/reindex")
def api_rag_reindex() -> dict[str, Any]:
    return index_all_questions()


@app.get("/api/library")
def api_library() -> dict[str, Any]:
    inventory = list_pdf_inventory()
    pairs = pair_prova_gabarito(inventory)
    year_statuses = compute_year_statuses()
    from acervo_fetch import manifest_with_local

    acervo = manifest_with_local()
    conn = connect()
    try:
        rows = conn.execute("SELECT year, source, generated, COUNT(*) AS c FROM questions GROUP BY year, source, generated").fetchall()
        by_year: dict[int, dict[str, Any]] = {
            item["year"]: {
                "year": item["year"], "questions": item["officialQuestionCount"],
                "status": item["status"], "hasProva": item["hasProva"], "hasGabarito": item["hasGabarito"],
            }
            for item in year_statuses
        }
        counts = {"total": 0, "treino": 0, "oficial": 0, "generated": 0}
        for r in rows:
            y = int(r["year"])
            c = int(r["c"])
            counts["total"] += c
            if r["generated"]:
                counts["generated"] += c
            src = (r["source"] or "").lower()
            if "pdf" in src or "oficial" in src or "ingest" in src:
                counts["oficial"] += c
            else:
                counts["treino"] += c
        provas_years = sorted({item["year"] for item in inventory if item["kind"] == "prova" and item.get("year")})
        gabaritos_years = sorted({item["year"] for item in inventory if item["kind"] == "gabarito" and item.get("year")})
        edital_ok = any(item["kind"] == "edital" for item in inventory)
        checklist = {
            "editalOk": edital_ok,
            "yearsWithProva": provas_years,
            "yearsWithGabarito": gabaritos_years,
            "yearsComplete": sorted(set(provas_years) & set(gabaritos_years)),
            "coveragePct": round(100 * len(set(provas_years) & set(gabaritos_years)) / 13, 1),
            "missingYears": [
                year for year in range(2014, 2027)
                if year not in provas_years or year not in gabaritos_years
            ],
            "yearStatuses": year_statuses,
            "guide": {
                "provasPath": str(DATA_DIR / "provas"),
                "gabaritosPath": str(DATA_DIR / "gabaritos"),
                "editalPath": str(DATA_DIR / "edital"),
                "naming": "paes_YYYY.pdf | gabarito_YYYY.pdf | edital_YYYY.pdf",
            },
            "provasYears": provas_years,
            "gabaritosYears": gabaritos_years,
            "anosCompletos": sorted(set(provas_years) & set(gabaritos_years)),
            "anosParciais": sorted(set(provas_years) - set(gabaritos_years)),
            "anosParciaisCount": len(set(provas_years) - set(gabaritos_years)),
            "anosCompletosCount": len(set(provas_years) & set(gabaritos_years)),
            "officialCount": stats_basis()["officialCount"],
            "message": (
                "Acervo oficial disponível para revisão."
                if edital_ok and provas_years and gabaritos_years
                else "Ainda faltam arquivos oficiais; dados de treino permanecem claramente identificados."
            ),
        }
        from ingest_pdf import year_health_from_db

        year_health: dict[str, Any] = {}
        for y in sorted({int(r["year"]) for r in rows}):
            health = year_health_from_db(y)
            if health.get("total", 0) > 0:
                year_health[str(y)] = health
                if y in by_year:
                    by_year[y]["yearHealth"] = health
        checklist["yearHealth"] = year_health
        from acervo_fetch import acervo_year_grid

        year_grid = acervo_year_grid()
        checklist["yearGrid"] = year_grid
        pending = list_pending_ingest_previews(limit=8)
        checklist["pendingPreviews"] = pending
        return {
            "years": [by_year[y] for y in sorted(by_year)],
            "counts": counts,
            "inventory": inventory,
            "pairs": pairs,
            "checklist": checklist,
            "yearGrid": year_grid,
            "pendingPreviews": pending,
            "acervoManifest": acervo,
            "dataDir": str(DATA_DIR),
            "paths": {
                "provas": str(DATA_DIR / "provas"),
                "gabaritos": str(DATA_DIR / "gabaritos"),
                "edital": str(DATA_DIR / "edital"),
                "root": str(DATA_DIR),
            },
        }
    finally:
        conn.close()


class AcervoFetchRequest(BaseModel):
    year: int
    dryRun: bool = False
    overwrite: bool = False


@app.get("/api/acervo/manifest")
def api_acervo_manifest() -> dict[str, Any]:
    from acervo_fetch import manifest_with_local

    return manifest_with_local()


@app.post("/api/acervo/fetch-year")
def api_acervo_fetch_year(payload: AcervoFetchRequest) -> dict[str, Any]:
    from acervo_fetch import fetch_year

    return fetch_year(payload.year, dry_run=payload.dryRun, overwrite=payload.overwrite)


class AcervoFetchAvailableRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False


@app.post("/api/acervo/fetch-available")
def api_acervo_fetch_available(payload: AcervoFetchAvailableRequest) -> dict[str, Any]:
    from acervo_fetch import fetch_available

    return fetch_available(dry_run=payload.dryRun, overwrite=payload.overwrite)


class AcervoBootstrapRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    year: int | None = None


@app.post("/api/acervo/bootstrap-year")
def api_acervo_bootstrap_year(payload: AcervoBootstrapRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_year

    result = bootstrap_year(dry_run=payload.dryRun, overwrite=payload.overwrite, year=payload.year)
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "Bootstrap falhou")
    return result


class AcervoBootstrapCommitRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    year: int | None = None
    minConfidence: float = 0.55
    autoProfessor: bool = True


@app.post("/api/acervo/bootstrap-and-commit")
def api_acervo_bootstrap_and_commit(payload: AcervoBootstrapCommitRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_and_commit

    result = bootstrap_and_commit(
        dry_run=payload.dryRun,
        overwrite=payload.overwrite,
        year=payload.year,
        min_confidence=payload.minConfidence,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "Bootstrap+commit falhou")
    return result


class AcervoBatchCommitRequest(BaseModel):
    dryRun: bool = False
    overwrite: bool = False
    minConfidence: float = 0.55
    skipCommitted: bool = True
    autoProfessor: bool = True


@app.post("/api/acervo/bootstrap-and-commit-available")
def api_acervo_bootstrap_and_commit_available(payload: AcervoBatchCommitRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_and_commit_available

    result = bootstrap_and_commit_available(
        dry_run=payload.dryRun,
        overwrite=payload.overwrite,
        min_confidence=payload.minConfidence,
        skip_committed=payload.skipCommitted,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "Lote found falhou")
    return result


class AcervoCommitOnDiskRequest(BaseModel):
    dryRun: bool = False
    minConfidence: float = 0.55
    skipCommitted: bool = True
    autoProfessor: bool = True


@app.post("/api/acervo/commit-on-disk")
def api_acervo_commit_on_disk(payload: AcervoCommitOnDiskRequest) -> dict[str, Any]:
    from acervo_fetch import commit_on_disk

    result = commit_on_disk(
        dry_run=payload.dryRun,
        min_confidence=payload.minConfidence,
        skip_committed=payload.skipCommitted,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun and (result.get("years") or []):
        failed = [y for y in (result.get("years") or []) if not y.get("ok") and not y.get("skipped")]
        if failed and result.get("insertedTotal", 0) == 0:
            raise HTTPException(400, result.get("message") or "Commit no disco falhou")
    return result


class AcervoImportAllCompleteRequest(BaseModel):
    minConfidence: float = 0.55
    skipIfCommitted: bool = False
    classifyAfter: bool = True


@app.post("/api/acervo/import-all-complete")
def api_acervo_import_all_complete(payload: AcervoImportAllCompleteRequest) -> dict[str, Any]:
    """Importa todos os anos com prova+gab no disco (Ciclo HK)."""
    from acervo_fetch import import_all_complete

    result = import_all_complete(
        min_confidence=payload.minConfidence,
        skip_if_committed=payload.skipIfCommitted,
        classify_after=payload.classifyAfter,
    )
    if payload.classifyAfter and int(result.get("insertedTotal") or 0) > 0:
        try:
            result["classified"] = api_ingest_classify_pending()
        except Exception as exc:  # noqa: BLE001
            result["classified"] = {"ok": False, "error": str(exc)}
    if int(result.get("insertedTotal") or 0) > 0:
        try:
            result["rag"] = index_all_questions()
        except Exception as exc:  # noqa: BLE001
            result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        try:
            result["professor"] = fill_professor_drafts(
                limit=max(40, int(result.get("insertedTotal") or 20)),
                prefer_uema=True,
            )
        except Exception as exc:  # noqa: BLE001
            result["professor"] = {"ok": False, "error": str(exc)}
    return result


@app.get("/api/tutor/today-plan")
def api_tutor_today_plan() -> dict[str, Any]:
    return build_tutor_day_plan()


class OpenFolderRequest(BaseModel):
    folder: Literal["provas", "gabaritos", "edital", "root"] = "provas"


@app.post("/api/library/open-folder")
def api_library_open_folder(payload: OpenFolderRequest) -> dict[str, Any]:
    mapping = {
        "provas": DATA_DIR / "provas",
        "gabaritos": DATA_DIR / "gabaritos",
        "edital": DATA_DIR / "edital",
        "root": DATA_DIR,
    }
    path = mapping[payload.folder]
    path.mkdir(parents=True, exist_ok=True)
    try:
        if os.name == "nt":
            os.startfile(str(path))  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", str(path)])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", str(path)])
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Não foi possível abrir a pasta: {exc}") from exc
    return {"ok": True, "path": str(path), "folder": payload.folder}


class OpenPathRequest(BaseModel):
    path: str = Field(min_length=2, max_length=2000)


@app.post("/api/library/open-path")
def api_library_open_path(payload: OpenPathRequest) -> dict[str, Any]:
    """Abre arquivo/pasta local dentro de DATA_DIR (Ciclo AP)."""
    from pathlib import Path as _Path

    target = _Path(payload.path).resolve()
    root = DATA_DIR.resolve()
    try:
        target.relative_to(root)
    except ValueError as exc:
        raise HTTPException(403, "Só é possível abrir arquivos dentro da pasta de dados do app") from exc
    if not target.exists():
        raise HTTPException(
            404,
            "Arquivo não encontrado no disco — pode ter sido movido ou apagado.",
        )
    try:
        if os.name == "nt":
            os.startfile(str(target))  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", str(target)])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", str(target)])
    except OSError as exc:
        raise HTTPException(500, f"Não foi possível abrir: {exc}") from exc
    return {"ok": True, "path": str(target)}


@app.get("/api/library/materials")
def api_library_materials(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Lista material local filtrado por subject/topic + snippets do edital (Ciclo AR)."""
    subj = (subject or "").strip()
    top = (topic or "").strip()
    filter_active = bool(subj or top)
    tokens = [t.lower() for t in f"{subj} {top}".split() if len(t) > 2]
    matched = f"{subj} · {top}".strip(" ·") if filter_active else None

    def _matches_blob(blob: str) -> bool:
        if not filter_active:
            return True
        low = blob.lower()
        return any(tok in low for tok in tokens)

    def _matches_file(path: Path) -> bool:
        if not filter_active:
            return True
        if _matches_blob(path.name):
            return True
        if path.suffix.lower() in {".md", ".txt"}:
            try:
                head = path.read_text(encoding="utf-8", errors="ignore")[:8000]
            except OSError:
                return False
            return _matches_blob(head)
        return False

    items: list[dict[str, Any]] = []
    file_match_count = 0

    # Trechos de teoria do edital/syllabus (não inventa PDF)
    for i, snip in enumerate(theory_snippets_for(subj or None, top or None, limit=6)):
        text = (snip or "").strip()
        if not text:
            continue
        items.append(
            {
                "kind": "theory_snippet",
                "label": f"Teoria · {matched or 'edital'}" + (f" ({i + 1})" if i else ""),
                "snippet": text[:800],
                "path": None,
                "folder": "edital",
                "exists": True,
                "matchedTopic": matched,
                "sourceKind": "edital_snippet",
            }
        )

    edital_dir = DATA_DIR / "edital"
    if edital_dir.exists():
        for p in sorted(edital_dir.iterdir()):
            if not p.is_file() or p.suffix.lower() not in {".md", ".txt", ".pdf"}:
                continue
            if not _matches_file(p):
                continue
            kind = "edital_md" if p.suffix.lower() in {".md", ".txt"} else "edital_pdf"
            items.append(
                {
                    "kind": kind,
                    "label": p.name,
                    "path": str(p),
                    "folder": "edital",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1

    # PDFs de prova: com filtro de tópico só se o nome bater; sem filtro, até 8
    provas_dir = DATA_DIR / "provas"
    if provas_dir.exists():
        prova_n = 0
        for p in sorted(provas_dir.glob("*.pdf")):
            if filter_active and not _matches_blob(p.name):
                continue
            if not filter_active and prova_n >= 8:
                break
            items.append(
                {
                    "kind": "prova",
                    "label": p.name,
                    "path": str(p),
                    "folder": "provas",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1
            prova_n += 1

    if not filter_active:
        gab_dir = DATA_DIR / "gabaritos"
        if gab_dir.exists():
            for p in sorted(gab_dir.glob("*.pdf"))[:4]:
                items.append(
                    {
                        "kind": "gabarito",
                        "label": p.name,
                        "path": str(p),
                        "folder": "gabaritos",
                        "exists": True,
                        "matchedTopic": matched,
                        "sourceKind": "local",
                    }
                )
                file_match_count += 1

    aulas_dir = DATA_DIR / "aulas"
    if aulas_dir.exists():
        for p in sorted(aulas_dir.iterdir()):
            if not p.is_file():
                continue
            if not _matches_file(p):
                continue
            items.append(
                {
                    "kind": "estudo",
                    "label": p.name,
                    "path": str(p),
                    "folder": "aulas",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1

    note = None
    if not items:
        note = (
            f"Nenhum material local para {matched or 'este recorte'}. "
            "Coloque resumo MD em data/edital ou PDFs oficiais — o app não inventa edital UEMA."
        )
    elif filter_active and file_match_count == 0:
        note = (
            f"Sem arquivo no disco batendo em {matched}; há trecho(s) de edital/syllabus se listados. "
            "Não inventamos PDF. Abra a Biblioteca para o acervo 2024–26."
        )

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "matchedTopic": matched,
        "items": items,
        "count": len(items),
        "fileMatchCount": file_match_count,
        "note": note,
        "disclaimer": "Só lista o que existe no disco ou trechos do edital local; não inventa 2017–23 nem PDF ausente.",
    }


@app.get("/api/library/year-pdf")
def api_library_year_pdf(year: int) -> dict[str, Any]:
    """Resolve PDF de prova oficial no disco para o ano (Ciclo AV)."""
    return year_pdf_info(int(year))


@app.get("/api/library/search")
def api_library_search(
    q: str = "",
    subject: str | None = None,
    topic: str | None = None,
    sourceKind: str | None = None,
    limit: int = 30,
) -> dict[str, Any]:
    """Busca acervo local oficial/estudo (Ciclo AW)."""
    return library_search(q=q, subject=subject, topic=topic, source_kind=sourceKind, limit=limit)


@app.get("/api/library/search-history")
def api_library_search_history(limit: int = 15) -> dict[str, Any]:
    """Histórico local de buscas na Biblioteca (Ciclo BL)."""
    return list_library_search_history(limit=limit)


class ExportDayPayload(BaseModel):
    markdown: str = Field(default="", max_length=200_000)
    filename: str | None = Field(default=None, max_length=120)


@app.post("/api/study/export-day")
def api_study_export_day(payload: ExportDayPayload) -> dict[str, Any]:
    """Salva pacote do dia em data/exports (Ciclo BN)."""
    return export_study_day_markdown(payload.markdown, payload.filename)


@app.post("/api/study/export-week")
def api_study_export_week() -> dict[str, Any]:
    """Relatório semanal real em data/exports (Ciclo BT)."""
    return export_study_week_markdown()


class OpenUrlRequest(BaseModel):
    url: str = Field(min_length=8, max_length=2000)


@app.post("/api/library/open-url")
def api_library_open_url(payload: OpenUrlRequest) -> dict[str, Any]:
    """Abre portal UEMA (ou URL http/https) no navegador padrão — playbook Acervo."""
    from urllib.parse import urlparse

    url = payload.url.strip()
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise HTTPException(400, "URL inválida (use http/https)")
    host = (parsed.hostname or "").lower()
    if not (host == "uema.br" or host.endswith(".uema.br")):
        raise HTTPException(400, "Só portais *.uema.br são abertos pelo app")
    try:
        if os.name == "nt":
            os.startfile(url)  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", url])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", url])
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Não foi possível abrir o navegador: {exc}") from exc
    return {"ok": True, "url": url}


@app.post("/api/edital/sync-syllabus")
def api_edital_sync_syllabus() -> dict[str, Any]:
    return sync_syllabus_from_edital_file()


@app.get("/api/edital/coverage")
def api_edital_coverage() -> dict[str, Any]:
    return edital_coverage()


@app.post("/api/library/reprocess")
def api_library_reprocess() -> dict[str, Any]:
    """Estatísticas são derivadas do SQLite; reindex embeddings + confirmação."""
    indexed = index_all_questions()
    return {"ok": True, "message": "Base reprocessada (frequência/perfil recalculam na leitura).", "rag": indexed}


@app.get("/api/today")
def api_today(
    examBoard: str | None = None,
    year: int | None = None,
    preferNatureza: bool | None = None,
    subject: str | None = None,
    topic: str | None = None,
    officialWithGab: bool | None = None,
) -> dict[str, Any]:
    dash = dashboard_stats()
    revs = list_revisions()
    now = __import__("datetime").datetime.now().isoformat(timespec="seconds")
    due_revs = [r for r in revs if (r.get("next_due") or "") <= now]
    cards = list_flashcards(due_only=True)
    study_today = dash.get("studyToday")
    subject_filter = (subject or "").strip() or None
    topic_filter = (topic or "").strip() or None
    if subject_filter and topic_filter:
        study_today = {
            "subject": subject_filter,
            "topic": topic_filter,
            "reason": "Deep-link Domínio / tópico do dia (Ciclo X)",
        }
    elif subject_filter and not study_today:
        study_today = {
            "subject": subject_filter,
            "topic": topic_filter or "Geral",
            "reason": "Disciplina escolhida no Domínio",
        }
    topic_keys: list[tuple[str, str]] = []
    if study_today:
        topic_keys.append((study_today["subject"], study_today["topic"]))
    for critical in dash.get("criticalTopics", []):
        s, _, t = critical["key"].partition("::")
        if t:
            topic_keys.append((s, t))
    selected: list[dict[str, Any]] = []
    prefer_official = stats_basis()["officialCount"] >= 10
    used_fallback = False
    natureza_first = False
    seen: set[str] = set()
    board_filter = (examBoard or "").strip().upper() or None
    # HL: sessão Dia de prova / oficiais só com PDF (gab no commit seguro)
    want_oficial_gab = officialWithGab is True or (
        officialWithGab is None and board_filter == "UEMA_PAES"
    )
    year_filter = int(year) if year else None
    natureza_subjects = {"Biologia", "Química", "Física"}
    # Default Natureza-first quando UEMA; deep-link Natureza só se subject for Bio/Qui/Fis
    want_natureza = preferNatureza is True or (
        preferNatureza is None
        and board_filter == "UEMA_PAES"
        and (not subject_filter or subject_filter in natureza_subjects)
    )
    if preferNatureza is False:
        want_natureza = False
    if subject_filter and subject_filter not in natureza_subjects:
        if preferNatureza is not True:
            want_natureza = False

    def _interleave_natureza(pool: list[dict[str, Any]], limit: int = 15) -> list[dict[str, Any]]:
        buckets = {"Biologia": [], "Química": [], "Física": []}
        for q in pool:
            subj = (q.get("subject") or "").strip()
            if subj in buckets:
                buckets[subj].append(q)
        out: list[dict[str, Any]] = []
        while len(out) < limit and any(buckets.values()):
            for key in ("Biologia", "Química", "Física"):
                if buckets[key] and len(out) < limit:
                    out.append(buckets[key].pop(0))
        return out

    def _official_gab_ok(q: dict[str, Any]) -> bool:
        if q.get("generated"):
            return False
        board = (q.get("examBoard") or "").upper()
        if board == "TREINO":
            return False
        if board == "UEMA_PAES" or q.get("isOfficial") or is_official_source(
            q.get("source"), q.get("generated")
        ):
            src = (q.get("source") or "").lower()
            return (
                "pdf" in src
                or "ingest" in src
                or "oficial" in src
                or bool(q.get("isOfficial"))
            )
        return False

    # Deep-link subject+topic: prioriza as questões do tópico
    year_widened = False
    if subject_filter and topic_filter:
        qpool = list_questions(
            subject=subject_filter,
            topic=topic_filter,
            exam_board=board_filter or ("UEMA_PAES" if prefer_official else None),
            year=year_filter,
            source_kind="oficial" if want_oficial_gab else None,
            limit=20,
        )
        # AE2: year estreito demais → multi-ano do mesmo tópico
        if year_filter and len(qpool) < 5 and board_filter == "UEMA_PAES":
            multi = list_questions(
                subject=subject_filter,
                topic=topic_filter,
                exam_board="UEMA_PAES",
                year=None,
                source_kind="oficial" if want_oficial_gab else None,
                limit=20,
            )
            if len(multi) > len(qpool):
                qpool = multi
                year_widened = True
        if not qpool and prefer_official:
            qpool = list_questions(
                subject=subject_filter, topic=topic_filter, source_kind="oficial", limit=20
            )
            used_fallback = True
        if not qpool and not want_oficial_gab:
            qpool = list_questions(subject=subject_filter, topic=topic_filter, limit=20)
            if qpool:
                used_fallback = True
        if want_oficial_gab:
            qpool = [q for q in qpool if _official_gab_ok(q)]
        selected = qpool[:15]
        if len(selected) < 8 and subject_filter in natureza_subjects and board_filter == "UEMA_PAES":
            more = list_questions(
                subject=subject_filter,
                exam_board="UEMA_PAES",
                source_kind="oficial" if want_oficial_gab else None,
                limit=15,
            )
            for question in more:
                if want_oficial_gab and not _official_gab_ok(question):
                    continue
                if question["id"] not in {q["id"] for q in selected}:
                    selected.append(question)
                if len(selected) >= 15:
                    break
        if want_natureza and selected and not topic_filter:
            nat = [q for q in selected if (q.get("subject") or "") in natureza_subjects]
            if nat:
                selected = _interleave_natureza(nat, 15)
                natureza_first = True
        session_plan = [
            {"phase": "theory", "minutes": 20, "title": f"Teoria · {subject_filter} · {topic_filter}"},
            {
                "phase": "questions",
                "minutes": 30,
                "title": f"Questões · {subject_filter} · {topic_filter}",
            },
            {"phase": "revisions", "minutes": 10, "title": "Revisão espaçada (SRS leve)"},
        ]
    # Ciclo M/O/P: sessão só-oficiais (year opcional; Natureza-first)
    elif board_filter:
        selected = list_questions(
            exam_board=board_filter,
            year=year_filter,
            source_kind="oficial" if (want_oficial_gab and board_filter == "UEMA_PAES") else None,
            limit=40,
        )
        if want_oficial_gab and board_filter == "UEMA_PAES":
            selected = [q for q in selected if _official_gab_ok(q)]
        if subject_filter:
            filtered = [q for q in selected if (q.get("subject") or "") == subject_filter]
            if filtered:
                selected = filtered
        if year_filter and len(selected) < 5 and board_filter == "UEMA_PAES":
            multi = list_questions(
                exam_board="UEMA_PAES",
                year=None,
                source_kind="oficial" if want_oficial_gab else None,
                limit=40,
            )
            if want_oficial_gab:
                multi = [q for q in multi if _official_gab_ok(q)]
            if subject_filter:
                multi = [q for q in multi if (q.get("subject") or "") == subject_filter] or multi
            if len(multi) > len(selected):
                selected = multi
                year_widened = True
        if not selected and board_filter == "UEMA_PAES":
            selected = list_questions(
                exam_board="UEMA_PAES",
                source_kind="oficial" if want_oficial_gab else None,
                limit=40,
            )
            if want_oficial_gab:
                selected = [q for q in selected if _official_gab_ok(q)]
            used_fallback = bool(selected) and year_filter is not None
        # Nunca recuar para TREINO quando officialWithGab / UEMA base
        if not selected and board_filter == "UEMA_PAES" and not want_oficial_gab:
            selected = list_questions(source_kind="oficial", year=year_filter, limit=40)
            used_fallback = True
        if board_filter == "UEMA_PAES" and want_natureza and selected:
            nat = [q for q in selected if (q.get("subject") or "") in natureza_subjects]
            if nat:
                selected = _interleave_natureza(nat, 15)
                natureza_first = True
            else:
                selected = selected[:15]
        else:
            selected = selected[:15]
        if (
            board_filter == "UEMA_PAES"
            and year_filter is None
            and prefer_official
            and len(selected) < 8
        ):
            more = list_questions(
                exam_board="UEMA_PAES",
                source_kind="oficial" if want_oficial_gab else None,
                limit=15,
            )
            for question in more:
                if want_oficial_gab and not _official_gab_ok(question):
                    continue
                if question["id"] not in {q["id"] for q in selected}:
                    selected.append(question)
                if len(selected) >= 15:
                    break
        session_plan = [
            {"phase": "theory", "minutes": 20, "title": "Teoria do tópico do dia"},
            {"phase": "questions", "minutes": 30, "title": "Questões focadas e críticas"},
            {"phase": "revisions", "minutes": 10, "title": "Revisão espaçada (SRS leve)"},
        ]
    else:
        for s, t in topic_keys:
            questions = list_questions(subject=s, topic=t, exam_board="UEMA_PAES", limit=15)
            if not questions and prefer_official:
                questions = list_questions(subject=s, topic=t, source_kind="oficial", limit=15)
            if not questions and not want_oficial_gab:
                questions = list_questions(subject=s, topic=t, exam_board="TREINO", limit=15)
                if questions:
                    used_fallback = True
            if not questions and not want_oficial_gab:
                questions = list_questions(subject=s, topic=t, limit=15)
                if questions:
                    used_fallback = True
            for question in questions:
                if want_oficial_gab and not _official_gab_ok(question):
                    continue
                if question["id"] not in seen:
                    selected.append(question)
                    seen.add(question["id"])
                if len(selected) >= 15:
                    break
            if len(selected) >= 15:
                break
        session_plan = [
            {"phase": "theory", "minutes": 20, "title": "Teoria do tópico do dia"},
            {"phase": "questions", "minutes": 30, "title": "Questões focadas e críticas"},
            {"phase": "revisions", "minutes": 10, "title": "Revisão espaçada (SRS leve)"},
        ]
    if board_filter == "UEMA_PAES" and not (subject_filter and topic_filter):
        if natureza_first:
            session_plan[1]["title"] = "UEMA · Natureza (Bio/Qui/Fis)"
        elif year_filter and not used_fallback and not year_widened:
            session_plan[1]["title"] = f"Só oficiais UEMA_PAES · {year_filter}"
        elif prefer_official or selected:
            years_in = sorted({int(q.get("year") or 0) for q in selected if q.get("year")})
            years_in = [y for y in years_in if y > 0]
            session_plan[1]["title"] = (
                f"Só oficiais UEMA_PAES · multi-ano"
                + (f" ({', '.join(map(str, years_in[:4]))})" if years_in else "")
            )
        else:
            session_plan[1]["title"] = "Só oficiais UEMA_PAES"
    edital_topics: list[dict[str, Any]] = []
    theory_snippets: list[str] = []
    if study_today:
        conn = connect()
        try:
            edital_topics = [
                dict(row) for row in conn.execute(
                    "SELECT subject, topic, subtopic, weight FROM syllabus WHERE subject=? ORDER BY topic, subtopic",
                    (study_today["subject"],),
                ).fetchall()
            ]
        finally:
            conn.close()
        theory_snippets = theory_snippets_for(
            study_today.get("subject"),
            study_today.get("topic"),
            limit=8,
        )
        if study_today.get("reason"):
            theory_snippets.insert(0, str(study_today["reason"]))
        if not theory_snippets:
            for entry in edital_topics[:8]:
                theory_snippets.append(
                    f"{entry['subject']} · {entry['topic']}"
                    + (f" ({entry['subtopic']})" if entry.get("subtopic") else "")
                    + f" — peso {entry.get('weight', 1)}"
                )
    warning = None
    if prefer_official and selected:
        official_sel = [
            q
            for q in selected
            if not q.get("generated")
            and (
                q.get("isOfficial")
                or is_official_source(q.get("source"), q.get("generated"))
                or (q.get("examBoard") or "").upper() == "UEMA_PAES"
            )
        ]
        if want_oficial_gab:
            official_sel = [q for q in official_sel if _official_gab_ok(q)]
        if official_sel:
            selected = official_sel[:15]

    # AE1: top-off Natureza until ≥10 oficiais (sem stubs)
    topped_off = False
    target_pack_min = 10
    natureza_pool_n = 0
    if prefer_official or board_filter == "UEMA_PAES":
        nat_pool = list_questions(
            exam_board="UEMA_PAES",
            source_kind="oficial" if want_oficial_gab else None,
            limit=80,
        )
        nat_pool = [
            q
            for q in nat_pool
            if (q.get("subject") or "") in natureza_subjects
            and not q.get("generated")
            and (
                q.get("isOfficial")
                or is_official_source(q.get("source"), q.get("generated"))
                or (q.get("examBoard") or "").upper() == "UEMA_PAES"
            )
            and (not want_oficial_gab or _official_gab_ok(q))
        ]
        natureza_pool_n = len(nat_pool)
        if want_natureza and natureza_pool_n >= target_pack_min and len(selected) < target_pack_min:
            ids = {q["id"] for q in selected}
            more = _interleave_natureza([q for q in nat_pool if q["id"] not in ids], 20)
            for q in more:
                if q["id"] not in ids:
                    selected.append(q)
                    ids.add(q["id"])
                    topped_off = True
                if len(selected) >= target_pack_min:
                    break
            if topped_off:
                natureza_first = True
                selected = selected[:15]
                if session_plan and len(session_plan) > 1:
                    session_plan[1]["title"] = "UEMA · Natureza (tópico + top-off)"

    if board_filter == "UEMA_PAES" and not selected:
        warning = "Nenhuma oficial UEMA_PAES na base. Commit na Biblioteca primeiro."
    elif year_widened:
        warning = (
            f"Poucas oficiais em {year_filter} para o recorte; ampliando multi-ano (base local)."
            if year_filter
            else "Pacote ampliado multi-ano para completar a sessão."
        )
    elif board_filter == "UEMA_PAES" and used_fallback and year_filter:
        warning = f"Sem oficiais do ano {year_filter}; usando outras UEMA_PAES."
    elif topped_off:
        warning = "Tópico fino completo com oficiais Natureza (top-off) — sem stubs."
    elif used_fallback:
        warning = "Sem questão oficial para o tópico do dia; foram usadas questões de treino."
    elif not prefer_official and not board_filter:
        warning = "Acervo oficial insuficiente; sessão usa base de treino rotulada."
    official_in_pack = sum(1 for q in selected if not q.get("generated"))
    return {
        "studyToday": study_today,
        "phases": {
            "theory": study_today,
            "theorySnippets": theory_snippets,
            "questions": [question["id"] for question in selected],
            "revisions": due_revs,
            "flashcards": cards[:30],
        },
        "revisions": due_revs,
        "flashcards": cards[:30],
        "flashcardsDueCount": len(cards),
        **{k: v for k, v in flashcard_axis_stats().items()},
        "theorySnippets": theory_snippets,
        "sessionPlan": session_plan,
        "preferOfficial": prefer_official,
        "preferNatureza": natureza_first or want_natureza,
        "naturezaFirst": natureza_first,
        "subjectFilter": subject_filter,
        "topicFilter": topic_filter,
        "yearFilter": year_filter,
        "yearWidened": year_widened,
        "toppedOff": topped_off,
        "targetPackMin": target_pack_min,
        "naturezaPoolCount": natureza_pool_n,
        "officialInPack": official_in_pack,
        "generatedInPack": sum(1 for q in selected if q.get("generated")),
        "srsMode": "leve",
        "srsIntervals": [1, 3, 7, 15, 30, 60, 120],
        "officialCount": stats_basis()["officialCount"],
        "statsBasis": stats_basis(),
        "officialUnlocked": dash.get("officialUnlocked"),
        "officialUnlockMessage": dash.get("officialUnlockMessage"),
        "weekClose": dash.get("weekClose"),
        "openGaps": dash.get("openGaps"),
        "dailyRoutine": dash.get("dailyRoutine"),
        "medicineTop": (dash.get("medicineTop") or dash.get("criticalTopics") or [])[:5],
        "examBoardFilter": board_filter,
        "officialWithGab": want_oficial_gab,
        "warning": warning,
        "editalTopics": edital_topics,
        "suggestedMinutes": 60,
        "disclaimer": "Fila montada com dados locais do aluno.",
    }


@app.get("/api/session/plan")
def api_session_plan(
    examBoard: str | None = None,
    year: int | None = None,
    preferNatureza: bool | None = None,
    subject: str | None = None,
    topic: str | None = None,
    officialWithGab: bool | None = None,
) -> dict[str, Any]:
    return api_today(
        examBoard=examBoard,
        year=year,
        preferNatureza=preferNatureza,
        subject=subject,
        topic=topic,
        officialWithGab=officialWithGab,
    )


class SessionCheckpointRequest(BaseModel):
    phaseIndex: int = 0
    qIndex: int = 0
    answeredIds: list[str] = Field(default_factory=list)
    elapsedMs: int = 0
    correctCount: int = 0
    sessionErrors: list[str] = Field(default_factory=list)
    phaseName: str | None = None
    questionIds: list[str] = Field(default_factory=list)
    started: bool = True


@app.get("/api/session/checkpoint")
def api_session_checkpoint_get() -> dict[str, Any]:
    data = get_session_checkpoint()
    return {"checkpoint": data}


@app.post("/api/session/checkpoint")
def api_session_checkpoint_save(payload: SessionCheckpointRequest) -> dict[str, Any]:
    return save_session_checkpoint(payload.model_dump())


@app.delete("/api/session/checkpoint")
def api_session_checkpoint_clear() -> dict[str, Any]:
    return clear_session_checkpoint()


class SimCheckpointRequest(BaseModel):
    mode: str = "dia_prova"
    limit: int = 10
    subject: str | None = None
    startedAt: str | None = None
    answers: dict[str, Any] = Field(default_factory=dict)
    errorTypes: dict[str, Any] = Field(default_factory=dict)
    questionIds: list[str] = Field(default_factory=list)
    questions: list[dict[str, Any]] = Field(default_factory=list)
    currentIndex: int = 0
    elapsedSec: int = 0
    examLocked: bool = False
    preflightDone: bool = False
    basis: str | None = None
    warning: str | None = None
    started: bool = True


@app.get("/api/sim/checkpoint")
def api_sim_checkpoint_get() -> dict[str, Any]:
    data = get_sim_checkpoint()
    return {"checkpoint": data}


@app.post("/api/sim/checkpoint")
def api_sim_checkpoint_save(payload: SimCheckpointRequest) -> dict[str, Any]:
    return save_sim_checkpoint(payload.model_dump())


@app.delete("/api/sim/checkpoint")
def api_sim_checkpoint_clear() -> dict[str, Any]:
    return clear_sim_checkpoint()


class ScheduleGapsRequest(BaseModel):
    gaps: list[dict[str, Any]] = Field(default_factory=list)


@app.post("/api/simulations/schedule-gaps")
def api_schedule_gaps(payload: ScheduleGapsRequest) -> dict[str, Any]:
    return schedule_gap_revisions(payload.gaps)


class ProfessorBatchRequest(BaseModel):
    limit: int = 20
    preferUema: bool = True
    uemaOnly: bool = False


class ProfessorGenerateRequest(BaseModel):
    questionId: str


class ProfessorAcceptRequest(BaseModel):
    questionId: str
    resolution: str
    bancaIntent: str
    macete: str
    pegadinha: str
    relatedTopics: list[str] = Field(default_factory=list)


class FlashcardsFromQuestionRequest(BaseModel):
    questionId: str
    count: int = Field(default=5, ge=1, le=10)


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


@app.post("/api/professor/generate")
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


@app.post("/api/professor/accept")
def api_professor_accept(payload: ProfessorAcceptRequest) -> dict[str, Any]:
    conn = connect()
    try:
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
    finally:
        conn.close()


@app.post("/api/flashcards/from-question")
def api_flashcards_from_question(payload: FlashcardsFromQuestionRequest) -> dict[str, Any]:
    """Cards leves a partir da resolução — prioriza 4 eixos se real (Ciclo AG)."""
    question = get_question(payload.questionId)
    if not question:
        raise HTTPException(404, "Questão não encontrada")
    cards = []
    from_axes = False
    axes = question.get("resolutionAxes") or (question.get("professorMode") or {}).get("resolutionAxes") or {}
    quality = question.get("resolutionQuality") or (question.get("professorMode") or {}).get("resolutionQuality")
    subj = question.get("subject") or "Geral"
    topic = question.get("topic") or "Tópico"
    qid = question["id"]
    axis_pairs = [
        ("Comando (eixo)", axes.get("comando"), "Gabarito (eixo)", axes.get("gabarito")),
        ("Conceito (eixo)", axes.get("conceito"), "Distrator (eixo)", axes.get("distrator")),
    ]
    if quality == "real" and any(axes.get(k) for k in ("comando", "conceito", "gabarito", "distrator")):
        for front_l, front, back_l, back in axis_pairs:
            if not front and not back:
                continue
            if front and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {front_l}",
                        str(front),
                        subj,
                        topic,
                        source=f"axis:{qid}",
                    )
                )
                from_axes = True
            if back and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {back_l}",
                        str(back),
                        subj,
                        topic,
                        source=f"axis:{qid}",
                    )
                )
                from_axes = True
            if len(cards) >= payload.count:
                break
    if not cards:
        sources = [
            ("Resolução", question.get("resolution") or question.get("professorMode", {}).get("resolution")),
            ("Macete", question.get("macete") or question.get("professorMode", {}).get("macete")),
            ("Pegadinha", question.get("pegadinha") or question.get("professorMode", {}).get("pegadinha")),
            ("Intenção da banca", question.get("bancaIntent") or question.get("professorMode", {}).get("bancaIntent")),
            (
                "Tópicos relacionados",
                ", ".join(question.get("relatedTopics") or question.get("professorMode", {}).get("relatedTopics", []))
                or topic,
            ),
        ]
        for label, content in sources:
            if content and len(cards) < payload.count:
                cards.append(
                    create_flashcard(
                        f"[{subj}] {topic} — {label}",
                        str(content),
                        subj,
                        topic,
                        source=f"question:{qid}",
                    )
                )
    return {
        "ok": True,
        "questionId": qid,
        "created": len(cards),
        "cards": cards,
        "fromAxes": from_axes,
        "note": "Cards didáticos locais — não oficiais da banca.",
    }


@app.post("/api/professor/batch-fill")
def api_professor_batch(payload: ProfessorBatchRequest) -> dict[str, Any]:
    """Preenche blocos vazios/mínimos com templates ricos (revisão humana recomendada)."""
    return fill_professor_drafts(
        limit=payload.limit,
        prefer_uema=payload.preferUema,
        uema_only=payload.uemaOnly,
    )


@app.get("/api/professor/draft-queue")
def api_professor_draft_queue(limit: int = 5, uemaOnly: bool = True) -> dict[str, Any]:
    return list_professor_draft_queue(limit=limit, uema_only=uemaOnly)


class ProfessorQueueActionRequest(BaseModel):
    questionId: str


@app.post("/api/professor/draft-accept")
def api_professor_draft_accept(payload: ProfessorQueueActionRequest) -> dict[str, Any]:
    result = accept_professor_draft(payload.questionId)
    if not result.get("ok"):
        raise HTTPException(404, result.get("error") or "Questão não encontrada")
    return result


@app.post("/api/professor/draft-skip")
def api_professor_draft_skip(payload: ProfessorQueueActionRequest) -> dict[str, Any]:
    result = skip_professor_draft(payload.questionId)
    if not result.get("ok"):
        raise HTTPException(404, result.get("error") or "Questão não encontrada")
    return result


class ParseGateRequest(BaseModel):
    yearHealth: dict[str, Any] | None = None
    pending: dict[str, Any] | None = None


@app.post("/api/acervo/parse-gate")
def api_parse_gate(payload: ParseGateRequest) -> dict[str, Any]:
    return parse_gate_flags(year_health=payload.yearHealth, pending=payload.pending)


@app.post("/api/acervo/natureza-pack")
def api_natureza_pack(limit: int = 12, year: int | None = None) -> dict[str, Any]:
    return create_natureza_pack(limit=limit, year=year)


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


@app.get("/api/backups")
def api_list_backups() -> list[dict[str, str]]:
    backup_dir = DATA_DIR / "backups"
    if not backup_dir.exists():
        return []
    out = []
    for p in sorted(backup_dir.iterdir(), reverse=True):
        if p.is_dir() and (p / "paes_med_ai.db").exists():
            out.append({"name": p.name, "path": str(p)})
        if p.suffix == ".zip":
            out.append({"name": p.name, "path": str(p)})
    return out[:30]
