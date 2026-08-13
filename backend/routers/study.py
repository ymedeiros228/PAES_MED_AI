"""Rotas: estudo."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, HTTPException

from db import db
from schemas import (
    AdaptiveRequest,
    ExamDatePayload,
    ExportDayPayload,
    MarkReadPayload,
    PlanDoneRequest,
    PlanRequest,
    SessionCheckpointRequest,
)
from services_advanced import (
    adaptive_training,
    flashcard_axis_stats,
    list_flashcards,
    set_plan_day_done,
)
from services_core import (
    build_exam_countdown,
    build_smart_insights,
    build_smart_study_plan,
    build_study_calendar,
    build_study_plan,
    build_tutor_day_plan,
    close_study_day,
    close_study_week,
    dashboard_stats,
    export_study_day_markdown,
    export_study_week_markdown,
    get_exam_date,
    get_study_plan,
    is_official_source,
    list_questions,
    mark_topic_read,
    set_exam_date,
    stats_basis,
    study_day_close_status,
    study_week_close_status,
    topic_read_status,
)
from services_edital import theory_snippets_for
from services_extra import (
    clear_session_checkpoint,
    complete_revision,
    get_session_checkpoint,
    list_revisions,
    save_session_checkpoint,
)
from timeutil import now_iso

router = APIRouter(tags=["estudo"])


@router.get("/api/study/day-close")
def api_study_day_close_status() -> dict[str, Any]:
    return study_day_close_status()

@router.post("/api/study/day-close")
def api_study_day_close() -> dict[str, Any]:
    return close_study_day()

@router.get("/api/study/exam-date")
def api_study_exam_date_get() -> dict[str, Any]:
    return {"ok": True, "examDate": get_exam_date(), "countdown": build_exam_countdown()}

@router.post("/api/study/exam-date")
def api_study_exam_date_set(payload: ExamDatePayload) -> dict[str, Any]:
    try:
        return set_exam_date(payload.examDate)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

@router.get("/api/study/week-close")
def api_study_week_close_status() -> dict[str, Any]:
    return study_week_close_status()

@router.post("/api/study/week-close")
def api_study_week_close() -> dict[str, Any]:
    return close_study_week()

@router.post("/api/study/mark-read")
def api_study_mark_read(payload: MarkReadPayload) -> dict[str, Any]:
    out = mark_topic_read(payload.subject, payload.topic)
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "payload inválido")
    return out

@router.get("/api/study/reads")
def api_study_reads(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    return topic_read_status(subject, topic)

@router.get("/api/study/calendar")
def api_study_calendar(days: int = 28) -> dict[str, Any]:
    return build_study_calendar(days=max(7, min(int(days or 28), 90)))

@router.get("/api/study/readiness")
def api_study_readiness() -> dict[str, Any]:
    dash = dashboard_stats()
    return dash.get("readiness") or {"ok": True, "score": 0}

@router.get("/api/revisions")
def api_revisions() -> list[dict[str, Any]]:
    return list_revisions()

@router.post("/api/revisions/complete")
def api_revisions_complete(subject: str, topic: str) -> dict[str, Any]:
    return complete_revision(subject, topic)

@router.post("/api/plans/generate")
def api_plans_generate(payload: PlanRequest) -> list[dict[str, Any]]:
    if payload.days not in (30, 60, 90) and payload.days < 1:
        raise HTTPException(400, "days inválido")
    days = payload.days if payload.days in (30, 60, 90) else max(7, min(payload.days, 180))
    return build_study_plan(days, payload.examDate)

@router.get("/api/plans/{days}")
def api_plans_get(days: int) -> list[dict[str, Any]]:
    return get_study_plan(days)


@router.get("/api/plans/smart")
def api_plans_smart(examDate: str | None = None) -> dict[str, Any]:
    """Cronograma inteligente com countdown, metas diarias e balanceamento."""
    return build_smart_study_plan(exam_date=examDate)

@router.post("/api/training/adaptive")
def api_adaptive(payload: AdaptiveRequest) -> dict[str, Any]:
    return adaptive_training(
        payload.subject,
        payload.topic,
        payload.nSimilar,
        payload.nHarder,
        payload.nGenerated,
    )

@router.post("/api/plans/done")
def api_plans_done(payload: PlanDoneRequest) -> dict[str, Any]:
    return set_plan_day_done(payload.days, payload.day, payload.done)

@router.get("/api/tutor/today-plan")
def api_tutor_today_plan() -> dict[str, Any]:
    return build_tutor_day_plan()

@router.post("/api/study/export-day")
def api_study_export_day(payload: ExportDayPayload) -> dict[str, Any]:
    """Salva pacote do dia em data/exports (Ciclo BN)."""
    return export_study_day_markdown(payload.markdown, payload.filename)

@router.post("/api/study/export-week")
def api_study_export_week() -> dict[str, Any]:
    """Relatório semanal real em data/exports (Ciclo BT)."""
    return export_study_week_markdown()

@router.get("/api/coach/insights")
def api_coach_insights() -> dict[str, Any]:
    """Coach inteligente: insights personalizados baseados no desempenho."""
    return build_smart_insights()


@router.get("/api/today")
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
    now = now_iso()
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
                "Só oficiais UEMA_PAES · multi-ano"
                + (f" ({', '.join(map(str, years_in[:4]))})" if years_in else "")
            )
        else:
            session_plan[1]["title"] = "Só oficiais UEMA_PAES"
    edital_topics: list[dict[str, Any]] = []
    theory_snippets: list[str] = []
    if study_today:
        with db() as conn:
            edital_topics = [
                dict(row) for row in conn.execute(
                    "SELECT subject, topic, subtopic, weight FROM syllabus WHERE subject=? ORDER BY topic, subtopic",
                    (study_today["subject"],),
                ).fetchall()
            ]
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

@router.get("/api/session/plan")
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

@router.get("/api/session/checkpoint")
def api_session_checkpoint_get() -> dict[str, Any]:
    data = get_session_checkpoint()
    return {"checkpoint": data}

@router.post("/api/session/checkpoint")
def api_session_checkpoint_save(payload: SessionCheckpointRequest) -> dict[str, Any]:
    return save_session_checkpoint(payload.model_dump())

@router.delete("/api/session/checkpoint")
def api_session_checkpoint_clear() -> dict[str, Any]:
    return clear_session_checkpoint()
