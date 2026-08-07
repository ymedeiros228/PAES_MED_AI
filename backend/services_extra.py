"""Tutor RAG, aulas/vídeo, redação, simulados, backup."""

from __future__ import annotations

import json
import re
import shutil
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from db import DATA_DIR, connect, loads_json
from services_core import list_questions, medicine_priority, predict_topic, stats_basis, topic_frequency
import time

ROOT = Path(__file__).resolve().parent.parent

_PATH_TTL_S = 12.0
_path_cache: dict[str, Any] = {"t": 0.0, "v": None}
_PACK_TTL_S = 45.0
_pack_cache: dict[str, Any] = {}  # key -> (t, value)


def invalidate_path_cache() -> None:
    _path_cache["t"] = 0.0
    _path_cache["v"] = None
    _pack_cache.clear()


REMEDIATION_RECIPES: dict[str, dict[str, Any]] = {
    "conceito": {
        "title": "Remediação — conceito",
        "steps": [
            "Releia o trecho do edital/teoria do tópico (2–3 min).",
            "Escreva a definição em 1 frase com suas palavras.",
            "Faça 2–3 questões fáceis/médias do mesmo tópico.",
        ],
        "practiceHint": "Priorize questões de conceito (definição/classificação).",
    },
    "interpretacao": {
        "title": "Remediação — interpretação",
        "steps": [
            "Sublinhe o verbo de comando do enunciado.",
            "Marque dados úteis vs distratores; ignore enfeite.",
            "Elimine 2 alternativas e justifique por que caem.",
        ],
        "practiceHint": "Treine enunciados longos do mesmo assunto.",
    },
    "calculo": {
        "title": "Remediação — cálculo",
        "steps": [
            "Refaça o cálculo no papel sem olhar o gabarito.",
            "Cheque unidades e ordem de grandeza.",
            "Refaça 2 exercícios numéricos parecidos.",
        ],
        "practiceHint": "Foque itens com números/gráficos do tópico.",
    },
    "distracao": {
        "title": "Remediação — distração",
        "steps": [
            "Pause 30s; respire; releia só o que a banca pergunta.",
            "Confira se marcou a letra que você escolheu.",
            "Próxima questão: ritual de 5s de foco antes de ler.",
        ],
        "practiceHint": "Simulado curto (5 Q) com timer leve.",
    },
    "tempo": {
        "title": "Remediação — tempo",
        "steps": [
            "Cronometre a próxima tentativa (máx. 2 min).",
            "Se travar, chute informado e marque para revisão.",
            "Treine 5 questões em bloco cronometrado.",
        ],
        "practiceHint": "Bloco cronometrado do mesmo tópico.",
    },
}


def remediation_for(error_type: str | None, subject: str = "", topic: str = "") -> dict[str, Any]:
    key = (error_type or "conceito").strip().lower()
    recipe = dict(REMEDIATION_RECIPES.get(key) or REMEDIATION_RECIPES["conceito"])
    recipe["errorType"] = key
    recipe["subject"] = subject
    recipe["topic"] = topic
    recipe["cta"] = {
        "path": f"/adaptativo?subject={subject}&topic={topic}" if subject else "/adaptativo",
        "label": "Treinar remediação",
    }
    return recipe


def build_rag_context(query: str, limit: int = 8) -> str:
    """Recupera trechos da base local relevantes à pergunta (RAG simples por palavras)."""
    context, _ = build_rag_context_with_citations(query, limit)
    return context


def build_rag_context_with_citations(query: str, limit: int = 8) -> tuple[str, list[dict[str, Any]]]:
    """Retorna (contexto, citações) para o tutor mostrar fontes."""
    tokens = {t.lower() for t in query.replace("?", " ").split() if len(t) > 3}
    conn = connect()
    try:
        questions = [dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()]
        syllabus = [dict(r) for r in conn.execute("SELECT * FROM syllabus").fetchall()]
        lessons = [dict(r) for r in conn.execute("SELECT * FROM lessons ORDER BY created_at DESC LIMIT 20").fetchall()]
    finally:
        conn.close()

    scored_q: list[tuple[int, dict[str, Any]]] = []
    for q in questions:
        blob = " ".join(
            [
                q["subject"],
                q["topic"],
                q.get("subtopic") or "",
                q["statement"],
                q.get("resolution") or "",
                q.get("macete") or "",
            ]
        ).lower()
        score = sum(1 for t in tokens if t in blob)
        if score:
            scored_q.append((score, q))
    scored_q.sort(key=lambda x: -x[0])

    chunks: list[str] = []
    citations: list[dict[str, Any]] = []
    chunks.append("=== EDITAL (tópicos cadastrados) ===")
    for s in syllabus[:30]:
        chunks.append(f"- {s['subject']} > {s['topic']} ({s.get('subtopic') or ''}) peso={s['weight']}")
        citations.append(
            {
                "type": "edital",
                "id": s.get("id"),
                "label": f"Edital · {s['subject']} · {s['topic']}",
                "snippet": s["topic"],
                "subject": s["subject"],
                "topic": s["topic"],
            }
        )

    chunks.append("=== QUESTÕES / RESOLUÇÕES RELEVANTES ===")
    for score, q in scored_q[:limit]:
        chunks.append(
            f"[{q['year']}] {q['subject']} / {q['topic']} (id={q['id']})\n"
            f"Enunciado: {q['statement']}\n"
            f"Resolução: {q.get('resolution') or 'n/d'}\n"
            f"Banca quis: {q.get('banca_intent') or 'n/d'}\n"
            f"Macete: {q.get('macete') or 'n/d'}"
        )
        citations.append(
            {
                "type": "question",
                "id": q["id"],
                "label": f"{q['subject']} · {q['topic']} ({q['year']})",
                "snippet": (q["statement"] or "")[:140],
                "score": score,
                "subject": q["subject"],
                "topic": q["topic"],
            }
        )

    if lessons:
        chunks.append("=== AULAS DO ALUNO ===")
        for lesson in lessons[:5]:
            chunks.append(
                f"{lesson['title']} | {lesson.get('subject')}/{lesson.get('topic')}\n"
                f"Resumo: {lesson.get('summary') or ''}"
            )
            citations.append(
                {
                    "type": "lesson",
                    "id": lesson["id"],
                    "label": lesson["title"],
                    "snippet": (lesson.get("summary") or "")[:140],
                    "subject": lesson.get("subject"),
                    "topic": lesson.get("topic"),
                }
            )

    freq = topic_frequency()[:10]
    chunks.append("=== FREQUÊNCIA (TOP) — estimativa, não garantia ===")
    for f in freq:
        chunks.append(
            f"{f['subject']}/{f['topic']}: {f['frequency']}x anos={f['years']}"
        )

    return "\n\n".join(chunks), citations[:12]


TUTOR_SYSTEM = """
Você é o Tutor IA do PAES MED AI (UEMA/PAES — preparação para Medicina).
Responda em português do Brasil, com tom de professor paciente e exigente.

MISSÃO PEDAGÓGICA (ordem obrigatória):
1) Elicitar: peça (ou valorize) o raciocínio do aluno antes de despejar a resposta.
2) Ensinar: explique o conceito em passos; use o ESTILO pedido (professor/macete/mapa…).
3) Verificar: termine com UMA pergunta de checagem (não várias).
4) Praticar: se houver ids de questões no contexto, sugira 1–2 caminhos de treino (não invente ids).

REGRAS DE INTEGRIDADE:
1. Priorize o CONTEXTO DA BASE LOCAL (edital, questões, resoluções, aulas). Não invente gabaritos oficiais,
   percentuais de cobrança UEMA, nem “prova de ano X” sem fonte no contexto.
2. Com contexto parcial: ensine o que der com o que há (trecho de edital, enunciado, macete) e marque
   o resto como raciocínio didático — nunca recuse a aula só porque a base é incompleta.
3. Se faltar fonte local: ensine o conceito de forma geral e diga com clareza
   "Isto é raciocínio didático, não gabarito oficial UEMA".
4. Nunca diga que o tutor “não funciona”, “está quebrado” ou “indisponível” — sempre ensine algo útil.
5. Frequências do contexto são ESTIMATIVAS da base de treino, não garantia de edital.
6. Cite ids/anos do contexto quando existirem.
""".strip()


_STYLE_HINTS: dict[str, str] = {
    "professor": "Explique como professor especialista, com perguntas socráticas.",
    "medico": "Conecte com raciocínio clínico/Medicina quando fizer sentido (sem diagnosticar o aluno).",
    "crianca": "Explique de forma simples (nível ~12 anos), sem perder precisão.",
    "analogia": "Use analogias concretas e curtas.",
    "mapa": "Organize como mapa mental em tópicos hierárquicos.",
    "resumo": "Resumo em até 5 linhas + 1 pergunta de verificação.",
    "macete": "Foque macetes de eliminação de distratores (sem inventar letra do gabarito).",
    "flashcard": "Devolva 3–5 flashcards Frente/Verso do tema.",
}


def tutor_style_hint(style: str | None) -> str:
    return _STYLE_HINTS.get((style or "professor").strip().lower(), _STYLE_HINTS["professor"])


def _score_blob(tokens: set[str], blob: str) -> int:
    low = blob.lower()
    return sum(1 for t in tokens if t in low)


def _extract_topic_candidates(message: str) -> list[tuple[str, str, int]]:
    """Devolve [(subject, topic, score)] do syllabus + menções no texto."""
    tokens = {t.lower() for t in re.findall(r"[A-Za-zÀ-ÿ0-9]{3,}", message)}
    if not tokens:
        return []
    conn = connect()
    try:
        syllabus = [dict(r) for r in conn.execute("SELECT subject, topic, subtopic, weight FROM syllabus").fetchall()]
    finally:
        conn.close()
    scored: list[tuple[str, str, int]] = []
    for s in syllabus:
        blob = f"{s.get('subject') or ''} {s.get('topic') or ''} {s.get('subtopic') or ''}"
        sc = _score_blob(tokens, blob)
        # peso leve do edital
        try:
            sc += min(2, int(s.get("weight") or 0) // 3)
        except (TypeError, ValueError):
            pass
        if sc > 0:
            scored.append((s.get("subject") or "—", s.get("topic") or "—", sc))
    scored.sort(key=lambda x: -x[2])
    # unique by subject+topic
    seen: set[tuple[str, str]] = set()
    out: list[tuple[str, str, int]] = []
    for sub, top, sc in scored:
        key = (sub, top)
        if key in seen:
            continue
        seen.add(key)
        out.append((sub, top, sc))
        if len(out) >= 5:
            break
    return out


def build_local_tutor_reply(
    message: str,
    style: str | None = "professor",
    context: str = "",
    citations: list[dict[str, Any]] | None = None,
    rag_mode: str = "keyword",
) -> dict[str, Any]:
    """
    offline-tutor-v2: ensina com base local + pedagogia (nunca só «não funciona»).
    Nunca inventa gabarito oficial / % de cobrança UEMA.
    """
    citations = list(citations or [])
    style_hint = tutor_style_hint(style)
    basis = stats_basis()
    # Light path: avoid full dashboard_stats scan on every tutor turn.
    day_subject, day_topic = "Biologia", "Genética"
    session_path = "/sessao"
    hot: list = []
    day_plan: dict = {}
    try:
        from services_core import build_tutor_day_plan, error_hot_topics, get_study_plan

        day_plan = build_tutor_day_plan() or {}
        hot = error_hot_topics(3) or []
        plans = get_study_plan(30) or []
        pending = [p for p in plans if not p.get("done")]
        if pending:
            day_subject = (pending[0].get("subject") or day_subject).strip()
            day_topic = (pending[0].get("topic") or day_topic).strip()
    except Exception:  # noqa: BLE001
        day_plan = {}
    daily: dict = {}
    meta = (day_plan.get("meta") or "").replace("Hoje: ", "")
    if " · " in meta:
        parts = meta.split(" · ")
        day_subject = (parts[0] or day_subject).strip()
        day_topic = (parts[1] if len(parts) > 1 else day_topic).strip()
    session_path = day_plan.get("ctaSession") or session_path

    candidates = _extract_topic_candidates(message)
    if candidates:
        subject, topic, _ = candidates[0]
    else:
        subject, topic = day_subject, day_topic

    pool = (
        list_questions(subject=subject, topic=topic, exam_board="UEMA_PAES", limit=10)
        or list_questions(subject=subject, topic=topic, limit=10)
        or list_questions(subject=day_subject, topic=day_topic, limit=8)
        or list_questions(limit=8)
    )
    q_cites = [c for c in citations if isinstance(c, dict) and c.get("type") == "question" and c.get("id")]
    ed_cites = [c for c in citations if isinstance(c, dict) and c.get("type") in ("edital", "lesson")]

    theory_lines: list[str] = []
    grounded_cites: list[dict[str, Any]] = []
    for q in pool[:8]:
        res = (q.get("resolution") or "").strip()
        mac = (q.get("macete") or "").strip()
        stmt = (q.get("statement") or "").strip()
        if not res or res == "—":
            if not mac and not stmt:
                continue
        qid = q.get("id")
        board = q.get("examBoard") or q.get("exam_board") or "—"
        year = q.get("year") or "—"
        theory_lines.append(f"• Questão {qid} ({year} · {board}):")
        if stmt:
            theory_lines.append(f"  Enunciado (trecho): {stmt[:220]}")
        if res and res != "—":
            for ln in res.splitlines()[:5]:
                if ln.strip():
                    theory_lines.append(f"  {ln.strip()[:220]}")
        elif stmt:
            theory_lines.append(
                "  (Sem resolução oficial na base — use o enunciado para treinar o tópico, "
                "sem afirmar a letra.)"
            )
        if mac and mac != "—":
            theory_lines.append(f"  Macete (base local): {mac[:200]}")
        grounded_cites.append(
            {
                "type": "question",
                "id": qid,
                "label": f"{q.get('subject')} · {q.get('topic')} ({year})",
                "snippet": stmt[:140],
                "subject": q.get("subject"),
                "topic": q.get("topic"),
                "year": year,
            }
        )
        if len(theory_lines) >= 18:
            break

    if len(grounded_cites) < 2:
        for cite in q_cites[:4]:
            if cite.get("id") in {c.get("id") for c in grounded_cites}:
                continue
            sn = (cite.get("snippet") or "")[:180]
            lab = cite.get("label") or cite.get("id")
            if sn:
                theory_lines.append(f"• {lab}: {sn}")
            grounded_cites.append(cite)

    for cite in ed_cites[:3]:
        if cite not in grounded_cites:
            grounded_cites.append(cite)

    try:
        from services_edital import theory_snippets_for

        snips = theory_snippets_for(subject, topic, limit=4)
    except Exception:  # noqa: BLE001
        snips = []

    pack_summary = ""
    try:
        from services_media import study_materials_pack

        pack = study_materials_pack(subject=subject, topic=topic)
        if pack.get("ok"):
            bits = []
            for lane in (pack.get("lanes") or [])[:3]:
                n = int(lane.get("count") or 0)
                if n > 0:
                    bits.append(f"{lane.get('label')}: {n}")
            if bits:
                pack_summary = " · ".join(bits)
    except Exception:  # noqa: BLE001
        pack_summary = ""

    try:
        n_q = len(list_questions(limit=1) or [])
    except Exception:  # noqa: BLE001
        n_q = 0
    has_material = bool(theory_lines or snips or grounded_cites or (context or "").strip() or n_q > 0)

    reason = day_plan.get("reason") or daily.get("reason") or "Prioridade do plano local / Medicina."
    lines: list[str] = [
        f"Tutor local (base + pedagogia) · {subject} · {topic}",
        f"Estilo: {style_hint}",
        "",
        "1) O que estudar",
        f"• Foco: {subject} · {topic}",
        f"• Por quê: {reason}",
    ]
    if hot:
        h0 = hot[0]
        lines.append(f"• Lacuna quente: {h0.get('key')} ({h0.get('misses')} miss(es)).")
    if day_plan.get("meta"):
        lines.append(f"• Meta do dia: {day_plan.get('meta')}")
    lines.append("")

    lines.append("2) Como pensar o conceito")
    lines.append(
        "• Não afirmo letra de gabarito sem resolução na base. "
        "Raciocínio: comando do enunciado → conceito → eliminação de distratores."
    )
    if snips:
        for s in snips[:3]:
            for ln in str(s).splitlines()[:4]:
                if ln.strip():
                    lines.append(f"• {ln.strip()[:240]}")
    if theory_lines:
        lines.extend(theory_lines[:14])
    elif context:
        raw_lines = [ln.strip() for ln in context.splitlines() if ln.strip()]
        useful = [ln for ln in raw_lines if not ln.startswith("===") and len(ln) > 20][:8]
        for ln in useful:
            lines.append(f"• {ln[:240]}")
    else:
        lines.append(
            f"• «{topic}» em {subject} está no syllabus de treino. "
            "Método: definição → causa-efeito → exceções → descarte de distratores."
        )
        lines.append(
            "• Passos PAES: (a) verbo de comando; (b) conceito-chave; "
            "(c) elimine 2 alternativas incompatíveis; (d) só então escolha."
        )

    if style == "macete":
        lines.append("• Macete: se a alternativa confunde definição com processo, elimine-a cedo.")
    elif style == "mapa":
        lines.append(f"• Mapa: {subject} → {topic} → (definição) → (mecanismo) → (exceção) → (distrator)")
    elif style == "flashcard":
        lines.append(f"• Frente: O que é {topic} em {subject}?")
        lines.append("• Verso: (suas palavras; sem copiar gabarito oficial sem fonte)")

    lines.append("")
    lines.append("3) Perguntas socráticas")
    lines.append(
        f"• Em uma frase: o que é «{topic}» em {subject} e qual palavra costuma ser a armadilha?"
    )
    lines.append(
        f"• Qual distrator você eliminaria primeiro em {topic} e por quê? "
        "(raciocínio — sem precisar da letra final.)"
    )
    lines.append("")

    lines.append("4) Próximo passo")
    sample_ids = [c.get("id") for c in grounded_cites if c.get("type") == "question" and c.get("id")][:3]
    if sample_ids:
        lines.append(f"• Questões na base: {', '.join(str(i) for i in sample_ids)} (fontes clicáveis).")
    lines.append(f"• Fila / sessão: {session_path}")
    lines.append("• Lista filtrada: /questoes")
    lines.append(f"• Treino adaptativo: /adaptativo?subject={subject}&topic={topic}")
    if pack_summary:
        lines.append(f"• Materiais (pack): {pack_summary} — Biblioteca ou teoria da sessão.")
    else:
        lines.append("• Materiais: Biblioteca + pack de reforço na sessão.")
    lines.append("")

    if not theory_lines and not snips:
        lines.append(
            "Obs.: base fina para este recorte — o método e o plano de hoje ainda valem; "
            "importe provas 2024–26 na Biblioteca para enriquecer resoluções oficiais."
        )
    lines.append(
        "[Aviso] offline-tutor-v2 · base local + pedagogia. "
        "Não inventa % de cobrança UEMA nem gabarito oficial ausente."
        + ("" if basis.get("basis") == "oficial" else " Stats ainda em treino.")
        + " Para modelo externo: OPENAI_API_KEY (+ OPENAI_BASE_URL opcional) ou OLLAMA_MODEL no backend/.env."
    )

    answer = "\n".join(lines)
    return {
        "answer": answer,
        "model": f"offline-tutor-v2-{rag_mode}",
        "usedRag": bool(theory_lines or snips or grounded_cites or (context or "").strip()),
        "citations": grounded_cites[:8],
        "ragMode": rag_mode,
        "hasLocalBase": has_material,
        "uncited": not bool(grounded_cites or snips or theory_lines),
        "provider": "offline",
        "statsBasis": basis,
    }



def record_answer(
    question_id: str,
    correct: bool,
    subject: str,
    topic: str,
    error_type: str | None = None,
    time_ms: int | None = None,
) -> dict[str, Any]:
    import sqlite3

    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        _ensure_study_gaps_table(conn)
        flash_info: dict[str, Any] | None = None
        gap_info: dict[str, Any] | None = None
        persisted = True
        try:
            conn.execute(
                """
                INSERT INTO answers (question_id, correct, subject, topic, error_type, time_ms, answered_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (question_id, 1 if correct else 0, subject, topic, error_type, time_ms, now),
            )
            if not correct:
                _schedule_revision(conn, subject, topic)
                flash_info = _maybe_flashcard_from_error(conn, question_id, subject, topic)
                gap_info = _upsert_gap_on_miss(conn, subject, topic, error_type, now)
            else:
                gap_info = _progress_gap_on_correct(conn, subject, topic)
            conn.commit()
        except sqlite3.IntegrityError:
            # Id sintético / sem linha em questions — ainda devolve pedagogia (teach)
            try:
                conn.rollback()
            except Exception:  # noqa: BLE001
                pass
            persisted = False
        out: dict[str, Any] = {"ok": True, "persisted": persisted}
        if gap_info:
            out["gap"] = gap_info
        if not correct:
            out["remediation"] = remediation_for(error_type, subject, topic)
            if flash_info:
                out["flashcardCreated"] = flash_info.get("created") is True
                out["flashcard"] = flash_info
        # Bloco didático honesto (nunca inventa gabarito oficial)
        out["teach"] = build_teach_block(
            question_id=question_id,
            subject=subject,
            topic=topic,
            correct=correct,
            error_type=error_type,
        )
        try:
            from services_core import invalidate_hot_caches

            invalidate_hot_caches()
        except Exception:  # noqa: BLE001
            try:
                invalidate_path_cache()
            except Exception:  # noqa: BLE001
                pass
        try:
            out["path"] = study_path()
        except Exception:
            pass
        return out
    finally:
        conn.close()


def _ensure_study_gaps_table(conn) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS study_gaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT NOT NULL,
            topic TEXT NOT NULL,
            error_type TEXT,
            status TEXT NOT NULL DEFAULT 'open',
            last_miss_at TEXT,
            correct_streak INTEGER DEFAULT 0,
            remembered_card INTEGER DEFAULT 0,
            miss_count INTEGER DEFAULT 1,
            UNIQUE(subject, topic)
        )
        """
    )


def _upsert_gap_on_miss(conn, subject: str, topic: str, error_type: str | None, now: str) -> dict[str, Any]:
    row = conn.execute(
        "SELECT * FROM study_gaps WHERE subject=? AND topic=?",
        (subject, topic),
    ).fetchone()
    if row:
        conn.execute(
            """
            UPDATE study_gaps SET status='open', error_type=?, last_miss_at=?,
                correct_streak=0, miss_count=COALESCE(miss_count,0)+1
            WHERE subject=? AND topic=?
            """,
            (error_type or row["error_type"], now, subject, topic),
        )
        return {
            "subject": subject,
            "topic": topic,
            "status": "open",
            "errorType": error_type or row["error_type"],
            "missCount": int(row["miss_count"] or 0) + 1,
            "action": "reopened",
        }
    conn.execute(
        """
        INSERT INTO study_gaps (subject, topic, error_type, status, last_miss_at, correct_streak, remembered_card, miss_count)
        VALUES (?, ?, ?, 'open', ?, 0, 0, 1)
        """,
        (subject, topic, error_type, now),
    )
    return {
        "subject": subject,
        "topic": topic,
        "status": "open",
        "errorType": error_type,
        "missCount": 1,
        "action": "opened",
    }


def _progress_gap_on_correct(conn, subject: str, topic: str) -> dict[str, Any] | None:
    row = conn.execute(
        "SELECT * FROM study_gaps WHERE subject=? AND topic=? AND status='open'",
        (subject, topic),
    ).fetchone()
    if not row:
        return None
    streak = int(row["correct_streak"] or 0) + 1
    remembered = int(row["remembered_card"] or 0)
    recovered = streak >= 2 or (remembered and streak >= 1)
    if recovered:
        conn.execute(
            "UPDATE study_gaps SET status='recovered', correct_streak=? WHERE subject=? AND topic=?",
            (streak, subject, topic),
        )
        return {
            "subject": subject,
            "topic": topic,
            "status": "recovered",
            "correctStreak": streak,
            "action": "recovered",
        }
    conn.execute(
        "UPDATE study_gaps SET correct_streak=? WHERE subject=? AND topic=?",
        (streak, subject, topic),
    )
    return {
        "subject": subject,
        "topic": topic,
        "status": "open",
        "correctStreak": streak,
        "action": "progress",
    }


def mark_gap_card_remembered(subject: str, topic: str) -> dict[str, Any]:
    """Flashcard remembered no tópico: marca flag; recovered se já houver ≥1 acerto streak."""
    conn = connect()
    try:
        _ensure_study_gaps_table(conn)
        row = conn.execute(
            "SELECT * FROM study_gaps WHERE subject=? AND topic=? AND status='open'",
            (subject, topic),
        ).fetchone()
        if not row:
            return {"ok": True, "skipped": True}
        streak = int(row["correct_streak"] or 0)
        recovered = streak >= 1
        if recovered:
            conn.execute(
                "UPDATE study_gaps SET remembered_card=1, status='recovered' WHERE subject=? AND topic=?",
                (subject, topic),
            )
            status = "recovered"
        else:
            conn.execute(
                "UPDATE study_gaps SET remembered_card=1 WHERE subject=? AND topic=?",
                (subject, topic),
            )
            status = "open"
        conn.commit()
        return {"ok": True, "subject": subject, "topic": topic, "status": status}
    finally:
        conn.close()


def _topic_has_local_material(subject: str, topic: str) -> bool:
    """Espelha o recorte de /api/library/materials — lacuna sem material → Biblioteca."""
    from services_edital import theory_snippets_for

    subj = (subject or "").strip()
    top = (topic or "").strip()
    if theory_snippets_for(subj or None, top or None, limit=1):
        return True
    tokens = [t.lower() for t in f"{subj} {top}".split() if len(t) > 2]
    if not tokens:
        return False

    def _matches_blob(blob: str) -> bool:
        low = blob.lower()
        return any(tok in low for tok in tokens)

    edital_dir = DATA_DIR / "edital"
    if edital_dir.exists():
        for p in edital_dir.iterdir():
            if not p.is_file():
                continue
            if p.suffix.lower() not in {".md", ".txt", ".pdf"}:
                continue
            if _matches_blob(p.name):
                return True
            if p.suffix.lower() in {".md", ".txt"}:
                try:
                    head = p.read_text(encoding="utf-8", errors="ignore")[:8000]
                except OSError:
                    continue
                if _matches_blob(head):
                    return True
    provas_dir = DATA_DIR / "provas"
    if provas_dir.exists():
        for p in provas_dir.glob("*.pdf"):
            if _matches_blob(p.name):
                return True
    aulas_dir = DATA_DIR / "aulas"
    if aulas_dir.exists():
        for p in aulas_dir.iterdir():
            if p.is_file() and _matches_blob(p.name):
                return True
    return False


def list_study_gaps(*, status: str = "open", limit: int = 40) -> dict[str, Any]:
    conn = connect()
    try:
        _ensure_study_gaps_table(conn)
        if status == "all":
            rows = conn.execute(
                "SELECT * FROM study_gaps ORDER BY last_miss_at DESC LIMIT ?",
                (limit,),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM study_gaps WHERE status=? ORDER BY last_miss_at DESC LIMIT ?",
                (status, limit),
            ).fetchall()
        items = [
            {
                "id": r["id"],
                "subject": r["subject"],
                "topic": r["topic"],
                "errorType": r["error_type"],
                "status": r["status"],
                "lastMissAt": r["last_miss_at"],
                "correctStreak": r["correct_streak"],
                "rememberedCard": bool(r["remembered_card"]),
                "missCount": r["miss_count"],
                "key": f"{r['subject']}::{r['topic']}",
                "hasLocalMaterial": _topic_has_local_material(r["subject"], r["topic"]),
            }
            for r in rows
        ]
        open_n = conn.execute("SELECT COUNT(*) AS c FROM study_gaps WHERE status='open'").fetchone()["c"]
        return {"ok": True, "count": len(items), "openCount": int(open_n), "items": items}
    finally:
        conn.close()


def recover_study_gap(subject: str, topic: str) -> dict[str, Any]:
    conn = connect()
    try:
        _ensure_study_gaps_table(conn)
        conn.execute(
            "UPDATE study_gaps SET status='recovered' WHERE subject=? AND topic=?",
            (subject, topic),
        )
        conn.commit()
        return {"ok": True, "subject": subject, "topic": topic, "status": "recovered"}
    finally:
        conn.close()


def _schedule_revision(conn, subject: str, topic: str) -> None:
    intervals = [1, 3, 7, 15, 30, 60, 120]
    row = conn.execute(
        "SELECT * FROM revisions WHERE subject=? AND topic=?",
        (subject, topic),
    ).fetchone()
    reviews = row["reviews"] if row else 0
    interval = intervals[min(reviews, len(intervals) - 1)]
    next_due = (datetime.now() + timedelta(days=interval)).isoformat(timespec="seconds")
    conn.execute(
        """
        INSERT INTO revisions (subject, topic, next_due, interval_days, reviews)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(subject, topic) DO UPDATE SET
          next_due=excluded.next_due,
          interval_days=excluded.interval_days,
          reviews=excluded.reviews
        """,
        (subject, topic, next_due, interval, reviews),
    )


def _maybe_flashcard_from_error(conn, question_id: str, subject: str, topic: str) -> dict[str, Any]:
    """Cria 1 flashcard por questão errada (dedupe por source erro:id). Due amanhã."""
    source = f"erro:{question_id}"
    existing = conn.execute(
        "SELECT id FROM flashcards WHERE source=? LIMIT 1",
        (source,),
    ).fetchone()
    if existing:
        return {"created": False, "id": existing["id"], "reason": "already_exists", "source": source}
    q = conn.execute("SELECT * FROM questions WHERE id=?", (question_id,)).fetchone()
    if not q:
        return {"created": False, "reason": "question_missing", "source": source}
    idx = int(q["correct_index"] or 0)
    letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
    board = (q["exam_board"] if "exam_board" in q.keys() else None) or "TREINO"
    front = f"[{subject}] {topic}: {(q['statement'] or '')[:180]}…"
    mac = (q["macete"] or "").strip()
    peg = (q["pegadinha"] or "").strip() if "pegadinha" in q.keys() else ""
    res = (q["resolution"] or "").strip()
    # Preferir verso com campos professor (macete/pegadinha/rascunho) antes do template mínimo
    back_parts = [
        f"Gabarito: {letter}",
        mac or None,
        peg[:180] if peg else None,
        res[:360] if res else None,
        f"Banca: {board}",
    ]
    back = "\n".join(p for p in back_parts if p)
    next_due = (datetime.now() + timedelta(days=1)).isoformat(timespec="seconds")
    cur = conn.execute(
        """
        INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews)
        VALUES (?, ?, ?, ?, ?, ?, 0)
        """,
        (front, back, subject, topic, source, next_due),
    )
    return {
        "created": True,
        "id": cur.lastrowid,
        "source": source,
        "nextDue": next_due,
        "front": front,
    }


def _subject_draft_hints(subject: str, topic: str) -> tuple[str, str, str]:
    """Macete/pegadinha/passo extra por disciplina (rascunho local, não banca)."""
    s = (subject or "").lower()
    if "biolog" in s:
        return (
            f"Em {topic}: ligue enunciado a processo (mitose/meiose/fluxo) antes de memorizar termo.",
            "Distrator clássico: trocar mitose↔meiose ou causa↔consequência ecológica.",
            "Identifique o nível (célula → organismo → ecossistema) pedido no comando.",
        )
    if "qu" in s and "mic" in s:
        return (
            f"Em {topic}: balanceie ou estime mol/razão antes de olhar alternativas.",
            "Distrator: unidade errada ou reagente limitante invertido.",
            "Separe dado estequiométrico de distrator de nomenclatura.",
        )
    if "f" in s and "sic" in s:
        return (
            f"Em {topic}: escreva a grandeza pedida (v, a, F, E) e a unidade antes de calcular.",
            "Distrator: confundir vetor/escalar ou instante/média.",
            "Cheque se o enunciado é cinemática, dinâmica ou energia.",
        )
    if "matem" in s:
        return (
            f"Em {topic}: traduza o texto em equação; teste extremos nas alternativas.",
            "Distrator: operação invertida ou domínio ignorado.",
            "Marque o que se pede (valor, gráfico, condição).",
        )
    if "portug" in s or "literat" in s or "lingua" in s:
        return (
            f"Em {topic}: sublinhe o comando (inferência, coesão, figura) no trecho.",
            "Distrator: paráfrase parcial que foge ao foco do enunciado.",
            "Elimine o que o texto não autoriza.",
        )
    return (
        f"Em {topic}: sublinhe verbos do comando (assinale, correto, exceto) e risque extremos.",
        "Pegadinha típica: alternativa parcialmente correta misturada a conclusão indevida.",
        f"Recorde o núcleo de {topic} em {subject} e elimine generalizações.",
    )


def fill_professor_drafts(
    *,
    limit: int = 20,
    prefer_uema: bool = True,
    uema_only: bool = False,
) -> dict[str, Any]:
    """Preenche resoluções thin com rascunhos 4 eixos (ainda draft até Aceitar). Ciclo Y."""
    from services_core import is_official_source, resolution_quality, stats_basis

    prefer_official = stats_basis()["officialCount"] >= 10 or prefer_uema
    conn = connect()
    try:
        rows = [
            dict(r)
            for r in conn.execute(
                """
                SELECT id, subject, topic, statement, resolution, banca_intent, macete, pegadinha,
                       related_topics_json, difficulty, source, generated, exam_board, correct_index, year
                FROM questions
                ORDER BY
                  CASE WHEN UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES' THEN 0 ELSE 1 END,
                  id
                LIMIT ?
                """,
                (max(limit * 12, 60),),
            ).fetchall()
        ]

        def needs_draft(r: dict[str, Any]) -> bool:
            res = (r.get("resolution") or "").strip()
            q = resolution_quality(res)
            # Ciclo D: nunca sobrescreve real (anti-regressão)
            if q == "real":
                return False
            if q == "draft":
                return False  # já tem rascunho: fila professor, não rebatch
            # template / vazio
            if not res or res == "—":
                return True
            low = res.lower()
            if low.startswith("revisar gabarito"):
                return True
            if "oficial paes-" in low and "refine" in low:
                return True
            if "[rascunho didático" in low:
                return False
            return True

        candidates = [r for r in rows if needs_draft(r)]
        # segunda trava: ids com real no momento do update
        real_ids = {
            str(r["id"])
            for r in rows
            if resolution_quality(r.get("resolution")) == "real"
        }
        if uema_only or prefer_uema:
            uema = [
                r
                for r in candidates
                if (r.get("exam_board") or "").upper() == "UEMA_PAES"
                or is_official_source(r.get("source"), r.get("generated"))
            ]
            if uema:
                candidates = uema
            elif uema_only:
                candidates = []
            elif prefer_official:
                official = [r for r in candidates if is_official_source(r.get("source"), r.get("generated"))]
                if official:
                    candidates = official
        # Ciclo X/Y: Natureza-first (Bio/Qui/Fis)
        nat = _NATUREZA_SUBJECTS

        def _draft_sort(r: dict[str, Any]) -> tuple[int, str]:
            s = (r.get("subject") or "").strip()
            return (0 if s in nat else 1, str(r.get("id") or ""))

        candidates = sorted(candidates, key=_draft_sort)[:limit]

        updated = 0
        skipped_real = 0
        for r in candidates:
            rid = str(r.get("id") or "")
            if rid in real_ids or resolution_quality(r.get("resolution")) == "real":
                skipped_real += 1
                continue
            topic = r["topic"]
            subject = r["subject"]
            year = r.get("year") or ""
            idx = int(r.get("correct_index") or 0)
            letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
            board = (r.get("exam_board") or "TREINO").upper()
            macete, pegadinha, passo2 = _subject_draft_hints(str(subject), str(topic))
            draft_tag = f"[Rascunho didático — NÃO é resolução oficial da banca | {board}]"
            resolution = (
                f"{draft_tag}\n"
                f"Comando: identifique o que o enunciado pede em {subject}/{topic}.\n"
                f"Conceito: {passo2}"
                + (f" (PAES-{year})" if year else "")
                + ".\n"
                f"Gabarito: a alternativa correta é {letter}; confira se responde ao comando sem extrapolar.\n"
                f"Distrator: elimine opções que trocam termos técnicos ou generalizam além do texto."
            )
            banca = (
                f"{draft_tag} Cobrar domínio aplicado de {subject}/{topic} no padrão PAES — "
                "distinguir conceito correto de distrator plausível."
            )
            related = loads_json(r.get("related_topics_json"), []) or [topic]
            conn.execute(
                """
                UPDATE questions SET resolution=?, banca_intent=?, macete=?, pegadinha=?,
                    related_topics_json=?
                WHERE id=?
                """,
                (
                    resolution,
                    banca,
                    macete or f"Marque comando e conceito de {topic} antes das alternativas.",
                    pegadinha or "Distrator clássico: termo vizinho ou conclusão não autorizada.",
                    json.dumps(related[:5], ensure_ascii=False),
                    r["id"],
                ),
            )
            updated += 1
        conn.commit()
        return {
            "ok": True,
            "updated": updated,
            "skippedReal": skipped_real,
            "preferUema": prefer_uema,
            "uemaOnly": uema_only,
            "resolutionQualityNote": "batch-fill gera draft — só Aceitar/promote eleva a real; não sobrescreve real",
            "note": "Rascunhos didáticos (draft) — NÃO resolvidos oficiais. Aceite na fila para marcar real.",
        }
    finally:
        conn.close()


_NATUREZA_SUBJECTS = {"Biologia", "Química", "Física"}
_DRAFT_TAG = "[Rascunho didático"
_DRAFT_ACCEPTED = "[Revisado — didático, NÃO oficial da banca]"
_DRAFT_SKIPPED = "[Pulado — rascunho didático]"


def create_natureza_pack(*, limit: int = 12, year: int | None = None) -> dict[str, Any]:
    """Flashcards Natureza due+1d a partir de macete/pegadinha oficiais (dedupe source=pack:id)."""
    conn = connect()
    try:
        sql = """
            SELECT id, subject, topic, statement, macete, pegadinha, resolution, correct_index, year, exam_board
            FROM questions
            WHERE UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES'
              AND subject IN ('Biologia', 'Química', 'Física')
            ORDER BY year DESC, id
            LIMIT ?
        """
        rows = [dict(r) for r in conn.execute(sql, (max(limit * 6, 40),)).fetchall()]
        if year is not None:
            rows = [r for r in rows if int(r.get("year") or 0) == int(year)]
        created = 0
        drafts = 0
        card_ids: list[int] = []
        next_due = (datetime.now() + timedelta(days=1)).isoformat(timespec="seconds")
        for r in rows:
            if created >= limit:
                break
            mac = (r.get("macete") or "").strip()
            peg = (r.get("pegadinha") or "").strip()
            res = (r.get("resolution") or "").strip()
            if not mac and not peg and not res:
                continue
            if res.lower().startswith("[rascunho didático"):
                drafts += 1
            source = f"pack:{r['id']}"
            existing = conn.execute(
                "SELECT id FROM flashcards WHERE source=? LIMIT 1",
                (source,),
            ).fetchone()
            if existing:
                continue
            idx = int(r.get("correct_index") or 0)
            letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
            front = f"[Natureza] {r['subject']} · {r['topic']}: {(r.get('statement') or '')[:160]}…"
            back_parts = [
                f"Gabarito: {letter}",
                mac or None,
                peg[:200] if peg else None,
                (res[:280] if res else None),
            ]
            back = "\n".join(p for p in back_parts if p)
            cur = conn.execute(
                """
                INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews)
                VALUES (?, ?, ?, ?, ?, ?, 0)
                """,
                (front, back, r["subject"], r["topic"], source, next_due),
            )
            created += 1
            card_ids.append(int(cur.lastrowid))
        conn.commit()
        return {
            "ok": True,
            "drafts": drafts,
            "cardsCreated": created,
            "cardIds": card_ids,
            "nextDue": next_due,
            "year": year,
            "note": "Pack Natureza — cards due amanhã (não oficiais da banca).",
        }
    finally:
        conn.close()


def list_professor_draft_queue(*, limit: int = 5, uema_only: bool = True) -> dict[str, Any]:
    """Fila Natureza oficiais com template|draft — cap diário (Ciclo L). batch-fill ≠ resolvido."""
    from services_core import is_official_source, resolution_quality

    limit = max(1, min(int(limit or 5), 40))
    conn = connect()
    try:
        rows = [
            dict(r)
            for r in conn.execute(
                """
                SELECT id, subject, topic, year, exam_board, resolution, macete, pegadinha,
                       banca_intent, statement, correct_index, source, generated
                FROM questions
                WHERE subject IN ('Biologia', 'Química', 'Física')
                ORDER BY
                  CASE WHEN UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES' THEN 0 ELSE 1 END,
                  year DESC, id
                LIMIT 400
                """
            ).fetchall()
        ]
    finally:
        conn.close()
    if uema_only:
        filtered = [
            r
            for r in rows
            if (r.get("exam_board") or "").upper() == "UEMA_PAES"
            or is_official_source(r.get("source"), r.get("generated"))
        ]
        if filtered:
            rows = filtered
    items = []
    for r in rows:
        if not is_official_source(r.get("source"), r.get("generated")) and (
            r.get("exam_board") or ""
        ).upper() != "UEMA_PAES":
            continue
        q = resolution_quality(r.get("resolution"))
        if q == "real":
            continue
        if q not in ("template", "draft"):
            continue
        label = "rascunho" if q == "draft" else "template"
        items.append(
            {
                "questionId": r["id"],
                "subject": r["subject"],
                "topic": r["topic"],
                "year": r.get("year"),
                "examBoard": r.get("exam_board"),
                "resolution": r.get("resolution") or "",
                "macete": r.get("macete") or "",
                "pegadinha": r.get("pegadinha") or "",
                "bancaIntent": r.get("banca_intent") or "",
                "statement": (r.get("statement") or "")[:220],
                "correctIndex": r.get("correct_index"),
                "resolutionQuality": q,
                "studentLabel": label,
                "note": "Rascunho didático — Aceitar grava real (não é texto oficial da banca).",
            }
        )
        if len(items) >= limit:
            break
    return {
        "ok": True,
        "count": len(items),
        "items": items,
        "scope": "natureza_official_non_real",
        "dailyCap": 5,
        "disclaimer": "Só Natureza não-real (máx. 5 no dia). batch-fill não conta como resolvido.",
    }


def accept_professor_draft(question_id: str) -> dict[str, Any]:
    """Aceita rascunho e grava resolução quality=real (4 eixos, sem tag rascunho)."""
    from services_core import resolution_quality

    conn = connect()
    try:
        row = conn.execute(
            """
            SELECT id, resolution, banca_intent, subject, topic, correct_index, year, macete, pegadinha
            FROM questions WHERE id=?
            """,
            (question_id,),
        ).fetchone()
        if not row:
            return {"ok": False, "error": "not_found"}
        res = row["resolution"] or ""
        subj = row["subject"] or "Natureza"
        topic = row["topic"] or "Tópico"
        year = row["year"] or ""
        idx = int(row["correct_index"] or 0)
        letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
        # Sempre reescreve para estrutura real (limpa [Rascunho…])
        res = (
            f"[Aceito — didático estruturado, NÃO oficial da banca]\n"
            f"Comando: identifique no enunciado o que a banca pede em {subj} ({topic}).\n"
            f"Conceito: relacione ao conteúdo de {topic}"
            + (f" no padrão PAES-{year}" if year else "")
            + ".\n"
            f"Gabarito: a alternativa correta é {letter}; ela responde ao comando sem extrapolar o enunciado.\n"
            f"Distrator: elimine opções que trocam termos técnicos ou concluem além do texto."
        )
        assert resolution_quality(res) == "real"
        banca = row["banca_intent"] or ""
        if _DRAFT_TAG in banca:
            banca = banca.replace(_DRAFT_TAG, _DRAFT_ACCEPTED, 1)
        elif not banca or banca == "—":
            banca = f"[Revisado — didático, NÃO oficial da banca] Cobrar {subj}/{topic}."
        mac = (row["macete"] or "").strip()
        peg = (row["pegadinha"] or "").strip()
        if not mac or mac == "—":
            mac = f"Marque o comando e o conceito de {topic} antes das alternativas."
        if not peg or peg == "—":
            peg = "Distrator clássico: termo vizinho ou conclusão que o enunciado não autoriza."
        conn.execute(
            "UPDATE questions SET resolution=?, banca_intent=?, macete=?, pegadinha=? WHERE id=?",
            (res, banca, mac, peg, question_id),
        )
        conn.commit()
        return {
            "ok": True,
            "questionId": question_id,
            "action": "accept",
            "resolutionQuality": "real",
        }
    finally:
        conn.close()


def skip_professor_draft(question_id: str) -> dict[str, Any]:
    """Remove da fila marcando como pulado (ainda didático, não real)."""
    from services_core import resolution_quality

    conn = connect()
    try:
        row = conn.execute(
            "SELECT id, resolution, banca_intent FROM questions WHERE id=?",
            (question_id,),
        ).fetchone()
        if not row:
            return {"ok": False, "error": "not_found"}
        res = row["resolution"] or ""
        if resolution_quality(res) == "real":
            return {"ok": True, "questionId": question_id, "skipped": True, "reason": "already_real"}
        if _DRAFT_TAG in res:
            lines = res.splitlines()
            if lines and _DRAFT_TAG in lines[0]:
                lines[0] = _DRAFT_SKIPPED
                res = "\n".join(lines)
            else:
                res = res.replace(_DRAFT_TAG, _DRAFT_SKIPPED, 1)
        else:
            res = f"{_DRAFT_SKIPPED}\n" + res
        banca = row["banca_intent"] or ""
        if _DRAFT_TAG in banca:
            banca = banca.replace(_DRAFT_TAG, _DRAFT_SKIPPED, 1)
        conn.execute(
            "UPDATE questions SET resolution=?, banca_intent=? WHERE id=?",
            (res, banca, question_id),
        )
        conn.commit()
        return {"ok": True, "questionId": question_id, "action": "skip"}
    finally:
        conn.close()


def parse_gate_flags(
    *,
    year_health: dict[str, Any] | None = None,
    pending: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Gate soft antes de Estudar: suspects altos ou needsOcr (Ciclo Q)."""
    health = year_health or {}
    pend = pending or {}
    suspects = int(health.get("suspectsRemaining") or 0)
    total = int(health.get("total") or 0)
    # Também considerar previews pendentes se health sem suspects
    if suspects == 0 and pend:
        suspects = int(pend.get("suspectsTotal") or 0)
        if total == 0:
            for it in pend.get("items") or []:
                total += int(it.get("count") or 0)
    needs_ocr = bool(pend.get("needsOcrCount") or 0)
    if not needs_ocr and health.get("needsOcr"):
        needs_ocr = True
    ratio = (suspects / total) if total > 0 else 0.0
    warn = needs_ocr or (total > 0 and ratio >= 0.30) or (suspects >= 8 and total == 0)
    return {
        "warn": warn,
        "suspects": suspects,
        "total": total,
        "suspectRatio": round(ratio, 3),
        "needsOcr": needs_ocr,
        "threshold": 0.30,
        "message": (
            "Parse com muitas suspeitas ou needsOcr — revise antes de estudar, ou continue mesmo assim."
            if warn
            else "Parse ok para estudar."
        ),
    }


def list_pending_ingest_previews(limit: int = 8) -> dict[str, Any]:
    """Previews não commitados + suspeitas / needsOcr (Ciclo P)."""
    from ingest_pdf import _is_suspect_question

    conn = connect()
    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS ingest_previews (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                filename TEXT NOT NULL,
                questions_json TEXT NOT NULL,
                raw_text TEXT,
                created_at TEXT NOT NULL,
                committed INTEGER DEFAULT 0
            )
            """
        )
        rows = conn.execute(
            """
            SELECT id, kind, filename, questions_json, raw_text, created_at, committed
            FROM ingest_previews
            WHERE COALESCE(committed, 0)=0
            ORDER BY created_at DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
    finally:
        conn.close()

    items = []
    total_suspects = 0
    needs_ocr_n = 0
    for row in rows:
        questions = loads_json(row["questions_json"], [])
        suspects = sum(1 for q in questions if isinstance(q, dict) and _is_suspect_question(q))
        raw = (row["raw_text"] or "")[:200]
        needs_ocr = "[NEEDS_OCR]" in (row["raw_text"] or "") or any(
            (q.get("needsOcr") is True) for q in questions if isinstance(q, dict)
        )
        if needs_ocr:
            needs_ocr_n += 1
        total_suspects += suspects
        year = None
        if questions and isinstance(questions[0], dict):
            year = questions[0].get("year")
        items.append(
            {
                "previewId": row["id"],
                "kind": row["kind"],
                "filename": row["filename"],
                "createdAt": row["created_at"],
                "count": len(questions),
                "suspects": suspects,
                "needsOcr": needs_ocr,
                "year": year,
                "snippet": raw,
            }
        )
    return {
        "pendingCount": len(items),
        "suspectsTotal": total_suspects,
        "needsOcrCount": needs_ocr_n,
        "items": items,
    }


def list_revisions() -> list[dict[str, Any]]:
    conn = connect()
    try:
        rows = conn.execute("SELECT * FROM revisions ORDER BY next_due").fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


def complete_revision(subject: str, topic: str) -> dict[str, Any]:
    intervals = [1, 3, 7, 15, 30, 60, 120]
    conn = connect()
    try:
        row = conn.execute(
            "SELECT * FROM revisions WHERE subject=? AND topic=?",
            (subject, topic),
        ).fetchone()
        if not row:
            return {"ok": False, "message": "Revisão não encontrada"}
        reviews = row["reviews"] + 1
        interval = intervals[min(reviews, len(intervals) - 1)]
        next_due = (datetime.now() + timedelta(days=interval)).isoformat(timespec="seconds")
        conn.execute(
            "UPDATE revisions SET reviews=?, interval_days=?, next_due=? WHERE subject=? AND topic=?",
            (reviews, interval, next_due, subject, topic),
        )
        conn.commit()
        return {"ok": True, "nextDue": next_due, "intervalDays": interval}
    finally:
        conn.close()


def save_session_checkpoint(payload: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO session_checkpoint (id, payload_json, updated_at)
            VALUES (1, ?, ?)
            ON CONFLICT(id) DO UPDATE SET payload_json=excluded.payload_json, updated_at=excluded.updated_at
            """,
            (json.dumps(payload, ensure_ascii=False), now),
        )
        conn.commit()
        return {"ok": True, "updatedAt": now}
    finally:
        conn.close()


def get_session_checkpoint() -> dict[str, Any] | None:
    conn = connect()
    try:
        row = conn.execute("SELECT payload_json, updated_at FROM session_checkpoint WHERE id=1").fetchone()
        if not row:
            return None
        data = json.loads(row["payload_json"] or "{}")
        data["updatedAt"] = row["updated_at"]
        return data
    finally:
        conn.close()


def clear_session_checkpoint() -> dict[str, Any]:
    conn = connect()
    try:
        conn.execute("DELETE FROM session_checkpoint WHERE id=1")
        conn.commit()
        return {"ok": True}
    finally:
        conn.close()


_SIM_CHECKPOINT_KEY = "sim_checkpoint"


def save_sim_checkpoint(payload: dict[str, Any]) -> dict[str, Any]:
    """Checkpoint mid-flow de simulado (Ciclo BP) — settings.sim_checkpoint."""
    now = datetime.now().isoformat(timespec="seconds")
    body = dict(payload)
    body["started"] = True
    body["kind"] = "sim"
    body["updatedAt"] = now
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO settings(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value
            """,
            (_SIM_CHECKPOINT_KEY, json.dumps(body, ensure_ascii=False)),
        )
        conn.commit()
        return {"ok": True, "updatedAt": now}
    finally:
        conn.close()


def get_sim_checkpoint() -> dict[str, Any] | None:
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key=?", (_SIM_CHECKPOINT_KEY,)).fetchone()
        if not row:
            return None
        data = json.loads(row["value"] or "{}")
        if not isinstance(data, dict) or not data.get("started"):
            return None
        return data
    finally:
        conn.close()


def clear_sim_checkpoint() -> dict[str, Any]:
    conn = connect()
    try:
        conn.execute("DELETE FROM settings WHERE key=?", (_SIM_CHECKPOINT_KEY,))
        conn.commit()
        return {"ok": True}
    finally:
        conn.close()


def schedule_gap_revisions(gaps: list[dict[str, Any]]) -> dict[str, Any]:
    """Agenda revisões para lacunas do simulado (subject/topic)."""
    scheduled = 0
    conn = connect()
    try:
        for g in gaps:
            subject = (g.get("subject") or "").strip()
            topic = (g.get("topic") or "").strip()
            if not subject or not topic:
                parts = str(g.get("key") or "").split("::", 1)
                if len(parts) == 2:
                    subject, topic = parts[0], parts[1]
            if subject and topic:
                _schedule_revision(conn, subject, topic)
                scheduled += 1
        conn.commit()
    finally:
        conn.close()
    first = gaps[0] if gaps else {}
    subject = first.get("subject") or ""
    topic = first.get("topic") or ""
    if not subject and first.get("key"):
        parts = str(first["key"]).split("::", 1)
        if len(parts) == 2:
            subject, topic = parts[0], parts[1]
    return {
        "ok": True,
        "scheduled": scheduled,
        "topSubject": subject,
        "topTopic": topic,
        "cta": f"/adaptativo?subject={subject}&topic={topic}" if subject else "/fila",
    }


def create_simulation(
    mode: str = "prova_completa",
    subject: str | None = None,
    topic: str | None = None,
    difficulty: str | None = None,
    year: int | None = None,
    limit: int = 10,
) -> dict[str, Any]:
    medicine = mode == "medicina"
    # Ciclo J: disciplina real (não vira prova completa)
    if mode == "disciplina":
        mode_eff = "disciplina"
    else:
        mode_eff = mode
    serious_mode = mode_eff in {"dia_prova", "prova_completa", "medicina", "disciplina"}
    basis_info = stats_basis()
    official_required = serious_mode and basis_info["officialCount"] >= 10 and mode_eff != "revisao"
    # Dia de prova / prova completa: pool sério sem gerados
    force_official_board = official_required or mode_eff == "dia_prova"
    questions = list_questions(
        subject=subject,
        topic=topic if mode_eff != "prova_completa" else None,
        year=year,
        difficulty=difficulty,
        medicine_only=medicine,
        exam_board="UEMA_PAES" if force_official_board and basis_info["officialCount"] >= 10 else None,
        source_kind="oficial" if force_official_board and basis_info["officialCount"] >= 10 else None,
        approved_only=True if force_official_board and basis_info["officialCount"] >= 10 else None,
    )
    warning = None
    mixed_treino = False
    if serious_mode and not (basis_info["officialCount"] >= 10):
        warning = (
            "Modo sério: acervo oficial ainda insuficiente "
            f"({basis_info['officialCount']} oficiais). Pool usa treino local — "
            "importe prova+gabarito na Biblioteca antes de confiar nestas estatísticas."
        )
        mixed_treino = True
    if force_official_board and not questions and basis_info["officialCount"] >= 10:
        questions = list_questions(
            subject=subject,
            topic=topic,
            year=year,
            difficulty=difficulty,
            medicine_only=medicine,
            source_kind="oficial",
            approved_only=True,
        )
    if force_official_board and not questions:
        questions = list_questions(
            subject=subject, topic=topic, year=year, difficulty=difficulty, medicine_only=medicine
        )
        warning = "Não há questões oficiais aprovadas para estes filtros; o simulado usou treino local."
        mixed_treino = True
    # Ciclo H: nunca stubs/gerados em modo sério
    if serious_mode:
        cleaned = [q for q in questions if not q.get("generated")]
        if cleaned:
            questions = cleaned
        else:
            mixed_treino = True
            if not warning:
                warning = "Pool sem oficiais não-gerados — treino local sem stubs novos."
    if mode_eff == "incidencia":
        ranking = medicine_priority()
        order = {f"{r['subject']}::{r['topic']}": i for i, r in enumerate(ranking)}
        questions.sort(key=lambda q: order.get(f"{q['subject']}::{q['topic']}", 999))
    if mode_eff == "revisao":
        revs = list_revisions()
        keys = {f"{r['subject']}::{r['topic']}" for r in revs}
        questions = [q for q in questions if f"{q['subject']}::{q['topic']}" in keys] or questions
    if mode_eff == "disciplina" and subject:
        questions = [q for q in questions if (q.get("subject") or "") == subject] or questions

    selected = questions[:limit]
    safe = []
    stub_n = 0
    for q in selected:
        if q.get("generated"):
            stub_n += 1
            continue  # never ship stubs into packed questions
        safe.append(
            {
                "id": q["id"],
                "year": q["year"],
                "subject": q["subject"],
                "topic": q["topic"],
                "statement": q["statement"],
                "options": q["options"],
                "difficulty": q["difficulty"],
                "examBoard": q.get("examBoard") or q.get("exam_board"),
            }
        )
    if stub_n and not safe:
        # fallback only when nothing else: mark treino
        mixed_treino = True
    years_used = sorted({int(q["year"]) for q in selected if q.get("year")})
    generated_in_pack = sum(1 for q in safe if q.get("generated"))
    return {
        "mode": mode_eff,
        "count": len(safe),
        "questions": safe,
        "startedAt": datetime.now().isoformat(timespec="seconds"),
        "examDayMode": mode_eff == "dia_prova",
        "note": "Cronometre no app. Após enviar, o relatório usa o modo professor.",
        "basis": "oficial" if official_required and warning is None else "treino",
        "warning": warning,
        "mixedTraining": mixed_treino,
        "statsBasis": basis_info,
        "yearsUsed": years_used,
        "multiYear": len(years_used) > 1,
        "subjectFilter": subject,
        "generatedInPack": generated_in_pack,
        "officialInPack": sum(1 for q in safe if not q.get("generated")),
    }


def grade_simulation(answers: list[dict[str, Any]]) -> dict[str, Any]:
    """answers: [{questionId, selectedIndex, timeMs, errorType?}]"""
    results = []
    correct_n = 0
    wrong_topics: dict[tuple[str, str], int] = {}
    professor_hints: list[dict[str, Any]] = []
    subject_stats: dict[str, dict[str, int]] = {}
    times: list[int] = []
    cards_due = 0
    conn = connect()
    try:
        for item in answers:
            qid = item["questionId"]
            row = conn.execute("SELECT * FROM questions WHERE id=?", (qid,)).fetchone()
            if not row:
                continue
            ok = int(item.get("selectedIndex", -1)) == row["correct_index"]
            subj = row["subject"]
            topic = row["topic"]
            bucket = subject_stats.setdefault(subj, {"correct": 0, "wrong": 0, "total": 0})
            bucket["total"] += 1
            tms = item.get("timeMs")
            if isinstance(tms, (int, float)) and tms >= 0:
                times.append(int(tms))
            if ok:
                correct_n += 1
                bucket["correct"] += 1
            else:
                bucket["wrong"] += 1
                key = (subj, topic)
                wrong_topics[key] = wrong_topics.get(key, 0) + 1
                professor_hints.append(
                    {
                        "questionId": qid,
                        "subject": subj,
                        "topic": topic,
                        "macete": row["macete"] or "Revise o conceito central e elimine alternativas extremas.",
                    }
                )
            results.append(
                {
                    "questionId": qid,
                    "correct": ok,
                    "correctIndex": row["correct_index"],
                    "selectedIndex": item.get("selectedIndex"),
                    "subject": subj,
                    "topic": topic,
                    "timeMs": item.get("timeMs"),
                    "_pendingAnswer": {
                        "ok": ok,
                        "errorType": None if ok else item.get("errorType", "conceito"),
                        "timeMs": item.get("timeMs"),
                    },
                }
            )
    finally:
        conn.close()

    # record_answer abre conexão própria — após fechar o SELECT
    for r in results:
        pending = r.pop("_pendingAnswer", None)
        if not pending:
            continue
        ans = record_answer(
            r["questionId"],
            pending["ok"],
            r["subject"],
            r["topic"],
            pending["errorType"],
            pending["timeMs"],
        )
        if not pending["ok"] and ans.get("flashcardCreated") is True:
            cards_due += 1

    total = len(results)
    gaps = [
        {"subject": subject, "topic": topic, "wrong": count}
        for (subject, topic), count in sorted(wrong_topics.items(), key=lambda item: -item[1])
    ]
    weak_keys = {(item["subject"], item["topic"]) for item in gaps}
    suggested = [
        item for item in medicine_priority()
        if (item["subject"], item["topic"]) not in weak_keys
    ][:5]
    subject_breakdown = [
        {
            "subject": s,
            "total": v["total"],
            "correct": v["correct"],
            "wrong": v["wrong"],
            "accuracy": round(v["correct"] / v["total"], 4) if v["total"] else 0,
        }
        for s, v in sorted(subject_stats.items(), key=lambda x: -x[1]["wrong"])
    ]
    avg_time = round(sum(times) / len(times), 1) if times else 0
    return {
        "total": total,
        "correct": correct_n,
        "accuracy": round(correct_n / total, 4) if total else 0,
        "avgTimeMs": avg_time,
        "subjectBreakdown": subject_breakdown,
        "cardsDueCreated": cards_due,
        "results": results,
        "gaps": gaps,
        "suggestedTopics": suggested,
        "professorHints": professor_hints,
        "ctas": {
            "natureza": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
            "filaDue": "/fila",
            "scheduleGaps": "/api/simulations/schedule-gaps",
        },
        "statsBasis": stats_basis(),
        "disclaimer": "Relatório baseado apenas nas questões da base local.",
    }


def structure_lesson_from_text(
    title: str,
    transcript: str,
    source_type: str = "legenda",
    source_ref: str | None = None,
    llm_payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Estrutura aula. Se llm_payload vier preenchido pelo main (OpenAI), usa; senão heurística."""
    freq = topic_frequency()
    subject = "Geral"
    topic = "A revisar"
    difficulty = "Média"

    blob = (title + " " + transcript).lower()
    conn = connect()
    try:
        syllabus = [dict(r) for r in conn.execute("SELECT subject, topic, subtopic FROM syllabus").fetchall()]
    finally:
        conn.close()

    # Match syllabus first (better than frequency alone)
    best_score = 0
    for s in syllabus:
        score = 0
        for part in (s["subject"], s["topic"], s.get("subtopic") or ""):
            p = (part or "").lower()
            if len(p) > 3 and p in blob:
                score += 2 if part == s["topic"] else 1
        if score > best_score:
            best_score = score
            subject = s["subject"]
            topic = s["topic"]
    if best_score == 0:
        for f in freq:
            if f["topic"].lower() in blob or f["subject"].lower() in blob:
                subject = f["subject"]
                topic = f["topic"]
                break

    if llm_payload:
        subject = llm_payload.get("subject", subject)
        topic = llm_payload.get("topic", topic)
        difficulty = llm_payload.get("difficulty", difficulty)
        summary = llm_payload.get("summary", transcript[:500])
        macetes = llm_payload.get("macetes", [])
        keywords = llm_payload.get("keywords", [])
        flashcards = llm_payload.get("flashcards", [])
        questions = llm_payload.get("questions", [])
    else:
        # Outline: first sentences / bullets as summary chunks
        chunks = [c.strip() for c in transcript.replace("\r", "\n").split("\n") if len(c.strip()) > 40]
        if not chunks:
            chunks = [transcript[i : i + 220].strip() for i in range(0, min(len(transcript), 900), 220) if transcript[i : i + 40].strip()]
        summary = "\n".join(f"• {c[:280]}" for c in chunks[:5]) or (transcript[:600] + ("..." if len(transcript) > 600 else ""))
        macetes = [
            f"Relacione '{topic}' com o edital ({subject}).",
            "Elimine alternativas absurdas antes de marcar.",
            "Faça 3 questões do mesmo tópico depois desta aula.",
        ]
        keywords = list({w for w in blob.split() if len(w) > 5})[:12]
        flashcards = [
            {"front": f"Tema central — {title}", "back": (chunks[0] if chunks else summary)[:280]},
            {"front": f"{subject} · {topic}: o que a banca costuma cobrar?", "back": f"Revise: {topic}. {macetes[0]}"},
            {"front": f"Macete rápido — {topic}", "back": macetes[1]},
        ]
        if len(chunks) > 1:
            flashcards.append({"front": f"Detalhe da aula — {topic}", "back": chunks[1][:280]})
        questions = []

    pred = predict_topic(subject, topic)
    incidence = (
        f"Histórico na base: {pred.get('frequency', 0)} ocorrência(s). "
        f"Estimativa de retorno: {pred.get('probability', 0)}% ({pred.get('confidence')}). "
        f"{pred.get('disclaimer')}"
    )

    lesson_id = str(uuid.uuid4())
    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO lessons (
                id, title, source_type, source_ref, transcript, subject, topic, difficulty,
                summary, macetes_json, keywords_json, flashcards_json, questions_json,
                incidence_note, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                lesson_id,
                title,
                source_type,
                source_ref,
                transcript,
                subject,
                topic,
                difficulty,
                summary,
                json.dumps(macetes, ensure_ascii=False),
                json.dumps(keywords, ensure_ascii=False),
                json.dumps(flashcards, ensure_ascii=False),
                json.dumps(questions, ensure_ascii=False),
                incidence,
                now,
            ),
        )
        for fc in flashcards:
            conn.execute(
                """
                INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews)
                VALUES (?, ?, ?, ?, ?, ?, 0)
                """,
                (
                    fc.get("front", ""),
                    fc.get("back", ""),
                    subject,
                    topic,
                    f"lesson:{lesson_id}",
                    (datetime.now() + timedelta(days=1)).isoformat(timespec="seconds"),
                ),
            )
        conn.commit()
    finally:
        conn.close()

    return {
        "id": lesson_id,
        "title": title,
        "subject": subject,
        "topic": topic,
        "difficulty": difficulty,
        "summary": summary,
        "macetes": macetes,
        "keywords": keywords,
        "flashcards": flashcards,
        "questions": questions,
        "incidenceNote": incidence,
        "createdAt": now,
    }


def list_lessons() -> list[dict[str, Any]]:
    conn = connect()
    try:
        rows = conn.execute("SELECT * FROM lessons ORDER BY created_at DESC").fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "id": r["id"],
                    "title": r["title"],
                    "subject": r["subject"],
                    "topic": r["topic"],
                    "difficulty": r["difficulty"],
                    "summary": r["summary"],
                    "macetes": loads_json(r["macetes_json"], []),
                    "keywords": loads_json(r["keywords_json"], []),
                    "flashcards": loads_json(r["flashcards_json"], []),
                    "questions": loads_json(r["questions_json"], []),
                    "incidenceNote": r["incidence_note"],
                    "createdAt": r["created_at"],
                    "sourceType": r["source_type"],
                    "sourceRef": r["source_ref"],
                }
            )
        return out
    finally:
        conn.close()


def save_essay(theme: str, text: str, feedback: dict[str, Any] | None = None, score: float | None = None) -> dict[str, Any]:
    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        cur = conn.execute(
            """
            INSERT INTO essays (theme, text, score, feedback_json, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (theme, text, score, json.dumps(feedback or {}, ensure_ascii=False), now),
        )
        conn.commit()
        return {"id": cur.lastrowid, "theme": theme, "score": score, "feedback": feedback, "createdAt": now}
    finally:
        conn.close()


def list_essays() -> list[dict[str, Any]]:
    conn = connect()
    try:
        rows = conn.execute("SELECT * FROM essays ORDER BY created_at DESC").fetchall()
        return [
            {
                "id": r["id"],
                "theme": r["theme"],
                "text": r["text"],
                "score": r["score"],
                "feedback": loads_json(r["feedback_json"], {}),
                "createdAt": r["created_at"],
            }
            for r in rows
        ]
    finally:
        conn.close()


_ESSAY_AXES = (
    "grammar",
    "cohesion",
    "coherence",
    "argumentation",
    "intervention",
)

_ESSAY_AXIS_LABELS = {
    "grammar": "Gramática",
    "cohesion": "Coesão",
    "coherence": "Coerência",
    "argumentation": "Argumentação",
    "intervention": "Intervenção",
}

_MISSION_CLEAR_DELTA = 0.6


def _clamp10(v: float) -> float:
    return float(max(0.0, min(10.0, v)))


def offline_essay_axis_scores(theme: str, text: str) -> dict[str, Any]:
    """Heurísticas honestas 0–10 por eixo (treino local · não banca)."""
    raw = text or ""
    words = re.findall(r"(?u)\b[\wÀ-ÿ]+\b", raw.lower())
    n = len(words)
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", raw) if p.strip()]
    sentences = [s.strip() for s in re.split(r"[.!?]+", raw) if s.strip()]
    # Gramática (proxy): pontuação, variação, frases não monstruosas
    punct = len(re.findall(r"[,.;:!?]", raw))
    long_sents = sum(1 for s in sentences if len(s.split()) > 45)
    grammar = 4.2 + min(3.5, punct / 8.0) + min(1.2, n / 200.0) - min(2.0, long_sents * 0.4)
    # Coesão: conectores
    connectors = (
        "porém", "contudo", "entretanto", "portanto", "assim", "além", "também",
        "não só", "mas também", "logo", "dessa forma", "em suma", "ademais",
        "embora", "ainda", "porque", "pois", "enquanto",
    )
    conn_hits = sum(1 for c in connectors if c in raw.lower())
    cohesion = 3.8 + min(4.0, conn_hits * 0.55) + min(1.5, len(paragraphs) * 0.35)
    # Coerência: tokens do tema + repetições controladas
    theme_tokens = set(re.findall(r"(?u)\b[\wÀ-ÿ]{4,}\b", (theme or "").lower()))
    unique = set(words)
    theme_hits = sum(1 for t in theme_tokens if t in unique) if theme_tokens else 0
    coherence = 4.0 + min(3.5, theme_hits * 0.9) + min(1.5, len(paragraphs) * 0.3)
    if n < 40:
        coherence = min(coherence, 4.5)
    # Argumentação: densidade de períodos longos + repertório genérico
    claim_markers = ("porque", "visto que", "dado que", "segundo", "de acordo", "é preciso", "deve-se")
    claims = sum(1 for m in claim_markers if m in raw.lower())
    longish = sum(1 for s in sentences if 18 <= len(s.split()) <= 55)
    argumentation = 3.6 + min(3.5, claims * 0.7) + min(2.0, longish * 0.35) + min(1.2, n / 250.0)
    # Intervenção: proposta
    inter_markers = (
        "deve", "necessário", "governo", "sociedade", "escola", "política",
        "proposta", "investir", "promover", "garantir", "campanha", "conscientiza",
        "órgão", "município", "estado", "família",
    )
    inter_hits = sum(1 for m in inter_markers if m in raw.lower())
    intervention = 3.2 + min(4.5, inter_hits * 0.55) + (0.8 if any(x in raw.lower() for x in ("agente", "meio", "efeito", "projeto")) else 0.0)

    tips = {
        "grammar": "Revise concordância e pontuação; evite frases longas demais.",
        "cohesion": "Use conectivos de oposição e conclusão entre parágrafos.",
        "coherence": "Mantenha o fio do tema; um eixo por parágrafo.",
        "argumentation": "Amarre repertório à tese com causa e efeito.",
        "intervention": "Feche com proposta viável (agente, meio, efeito).",
    }
    scores = {
        "grammar": round(_clamp10(grammar), 1),
        "cohesion": round(_clamp10(cohesion), 1),
        "coherence": round(_clamp10(coherence), 1),
        "argumentation": round(_clamp10(argumentation), 1),
        "intervention": round(_clamp10(intervention), 1),
    }
    overall = round(sum(scores.values()) / 5.0, 1)
    return {
        "score": overall,
        "scores": scores,
        "tips": tips,
        "wordCount": n,
        "paragraphCount": len(paragraphs),
    }


def _axis_numeric(fb: dict[str, Any], key: str) -> float | None:
    v = fb.get(key)
    if isinstance(v, (int, float)):
        return _clamp10(float(v))
    for alt in (f"{key}Score", f"{key}_score", f"{key}Rating"):
        av = fb.get(alt)
        if isinstance(av, (int, float)):
            return _clamp10(float(av))
    scores = fb.get("scores")
    if isinstance(scores, dict) and isinstance(scores.get(key), (int, float)):
        return _clamp10(float(scores[key]))
    return None


def essay_progress() -> dict[str, Any]:
    """Médias locais por eixo (5) + missão/streak — treino, não banca UEMA."""
    essays = list_essays()
    axis_sums: dict[str, float] = {k: 0.0 for k in _ESSAY_AXES}
    axis_counts: dict[str, int] = {k: 0 for k in _ESSAY_AXES}
    last_scores: list[float] = []
    last_axis_scores: dict[str, float | None] = {k: None for k in _ESSAY_AXES}
    prev_axis_scores: dict[str, float | None] = {k: None for k in _ESSAY_AXES}
    used_proxy = False

    def _axis_val(fb: dict[str, Any], key: str, overall: float | None) -> float | None:
        nonlocal used_proxy
        num = _axis_numeric(fb, key)
        if num is not None:
            return num
        tip = fb.get(key)
        if isinstance(tip, str) and overall is not None:
            used_proxy = True
            return _clamp10(overall)
        if overall is not None:
            used_proxy = True
            return _clamp10(overall)
        return None

    for e in essays:
        overall = e.get("score")
        try:
            overall_f = float(overall) if overall is not None else None
        except (TypeError, ValueError):
            overall_f = None
        if overall_f is not None:
            last_scores.append(round(overall_f, 2))
        fb = e.get("feedback") if isinstance(e.get("feedback"), dict) else {}
        for key in _ESSAY_AXES:
            val = _axis_val(fb, key, overall_f)
            if val is None:
                continue
            axis_sums[key] += val
            axis_counts[key] += 1

    if essays:
        e0 = essays[0]
        try:
            o0 = float(e0["score"]) if e0.get("score") is not None else None
        except (TypeError, ValueError):
            o0 = None
        fb0 = e0.get("feedback") if isinstance(e0.get("feedback"), dict) else {}
        for key in _ESSAY_AXES:
            last_axis_scores[key] = _axis_val(fb0, key, o0)
    if len(essays) >= 2:
        e1 = essays[1]
        try:
            o1 = float(e1["score"]) if e1.get("score") is not None else None
        except (TypeError, ValueError):
            o1 = None
        fb1 = e1.get("feedback") if isinstance(e1.get("feedback"), dict) else {}
        for key in _ESSAY_AXES:
            prev_axis_scores[key] = _axis_val(fb1, key, o1)

    averages = {
        k: (round(axis_sums[k] / axis_counts[k], 2) if axis_counts[k] else None) for k in _ESSAY_AXES
    }
    labels = dict(_ESSAY_AXIS_LABELS)
    weakest: str | None = None
    weakest_val: float | None = None
    for k in _ESSAY_AXES:
        v = averages.get(k)
        if v is None:
            continue
        if weakest_val is None or float(v) < weakest_val:
            weakest_val = float(v)
            weakest = k

    moving_window = last_scores[:7]
    moving_avg = round(sum(moving_window) / len(moving_window), 2) if moving_window else None
    if moving_avg is None:
        level_label = "Início"
    elif moving_avg < 5.0:
        level_label = "Aquecimento"
    elif moving_avg < 6.5:
        level_label = "Em forma"
    elif moving_avg < 8.0:
        level_label = "Consistente"
    else:
        level_label = "Afiado"

    persona_by_axis = {
        "cohesion": "cohesion_revisor",
        "argumentation": "argument_critic",
        "coherence": "timed_reader",
        "grammar": "grammar_coach",
        "intervention": "intervention_mentor",
    }

    mission_status = "open"
    next_mission = None
    if essays and weakest:
        lab = labels.get(weakest, weakest)
        last_w = last_axis_scores.get(weakest)
        prev_w = prev_axis_scores.get(weakest)
        delta_w = None
        if last_w is not None and prev_w is not None:
            delta_w = round(float(last_w) - float(prev_w), 2)
            if delta_w >= _MISSION_CLEAR_DELTA:
                mission_status = "cleared"
            else:
                mission_status = "active"
        elif last_w is not None:
            mission_status = "active"
        next_mission = {
            "axis": weakest,
            "label": lab,
            "score": weakest_val,
            "lastScore": last_w,
            "prevScore": prev_w,
            "delta": delta_w,
            "status": mission_status,
            "clearThreshold": _MISSION_CLEAR_DELTA,
            "prompt": (
                f"Missão: subir {lab.lower()}. Reescreva o parágrafo mais fraco e peça nova correção — "
                f"treino local, não nota de banca."
                + (
                    f" Vitória: +{_MISSION_CLEAR_DELTA:.1f} no eixo desde a redação anterior."
                    if mission_status != "cleared"
                    else " Eixo subiu o suficiente — escolha novo tema ou treine outro vale."
                )
            ),
            "suggestedPersona": persona_by_axis.get(weakest),
        }

    days_set: set[str] = set()
    last_essay_at = essays[0].get("createdAt") if essays else None
    for e in essays:
        ca = (e.get("createdAt") or "")[:10]
        if len(ca) == 10:
            days_set.add(ca)
    streak = 0
    if days_set:
        cursor = datetime.now().date()
        if cursor.isoformat() not in days_set:
            cursor = cursor - timedelta(days=1)
        while cursor.isoformat() in days_set:
            streak += 1
            cursor = cursor - timedelta(days=1)

    # Deltas último vs penúltimo (radar fino)
    axis_deltas: dict[str, float | None] = {}
    for k in _ESSAY_AXES:
        lv = last_axis_scores.get(k)
        pv = prev_axis_scores.get(k)
        if lv is not None and pv is not None:
            axis_deltas[k] = round(float(lv) - float(pv), 2)
        else:
            axis_deltas[k] = None

    # Timeline de missões / redações recentes (UI Redação + Progresso)
    mission_timeline: list[dict[str, Any]] = []
    if next_mission:
        mission_timeline.append(
            {
                "kind": "mission",
                "id": f"mission_{next_mission.get('axis') or 'open'}",
                "title": f"Missão · {next_mission.get('label') or 'eixo'}",
                "subtitle": (
                    f"Status: {next_mission.get('status') or 'open'}"
                    + (
                        f" · delta {next_mission.get('delta'):+g}"
                        if next_mission.get("delta") is not None
                        else ""
                    )
                    + (
                        f" · mentor {next_mission.get('suggestedPersona')}"
                        if next_mission.get("suggestedPersona")
                        else ""
                    )
                ),
                "at": last_essay_at,
                "route": "/redacao",
                "axis": next_mission.get("axis"),
                "status": next_mission.get("status"),
                "suggestedPersona": next_mission.get("suggestedPersona"),
                "prompt": next_mission.get("prompt"),
            }
        )
    for e in essays[:8]:
        fb = e.get("feedback") if isinstance(e.get("feedback"), dict) else {}
        focus = fb.get("focusAxis") or fb.get("personaFocus")
        persona = fb.get("personaLabel") or fb.get("persona")
        sc = e.get("score")
        mission_timeline.append(
            {
                "kind": "essay",
                "id": e.get("id"),
                "title": f"Redação · {e.get('theme') or 'tema'}",
                "subtitle": (
                    f"Nota {sc if sc is not None else '—'}"
                    + (f" · eixo {_ESSAY_AXIS_LABELS.get(str(focus), focus)}" if focus else "")
                    + (f" · mentor {persona}" if persona else "")
                    + " · treino local"
                ),
                "at": e.get("createdAt"),
                "route": "/redacao",
                "score": sc,
                "focusAxis": focus,
                "persona": persona,
            }
        )

    return {
        "ok": True,
        "count": len(essays),
        "axes": _ESSAY_AXES,
        "labels": labels,
        "averages": averages,
        "lastAxisScores": last_axis_scores,
        "prevAxisScores": prev_axis_scores,
        "axisDeltas": axis_deltas,
        "lastScores": last_scores[:12],
        "meanScore": round(sum(last_scores) / len(last_scores), 2) if last_scores else None,
        "movingAvg": moving_avg,
        "levelLabel": level_label,
        "weakestAxis": weakest,
        "nextMission": next_mission,
        "missionStatus": mission_status if next_mission else None,
        "missionTimeline": mission_timeline[:12],
        "streakDays": streak,
        "lastEssayAt": last_essay_at,
        "disclaimer": "Treino local por eixos · não é nota de banca UEMA.",
        "usedOverallAsProxy": used_proxy,
    }


def essay_grade_deltas(theme: str, feedback: dict[str, Any]) -> dict[str, float | None]:
    """Delta por eixo vs redação imediatamente anterior (já salva a atual)."""
    essays = list_essays()
    prev = essays[1] if len(essays) >= 2 else None
    if prev is None:
        return {k: None for k in _ESSAY_AXES}
    fb_prev = prev.get("feedback") if isinstance(prev.get("feedback"), dict) else {}
    try:
        o_prev = float(prev["score"]) if prev.get("score") is not None else None
    except (TypeError, ValueError):
        o_prev = None
    out: dict[str, float | None] = {}
    for k in _ESSAY_AXES:
        cur = _axis_numeric(feedback, k)
        old = _axis_numeric(fb_prev, k)
        if old is None and o_prev is not None:
            old = o_prev
        if cur is None or old is None:
            out[k] = None
        else:
            out[k] = round(float(cur) - float(old), 2)
    return out


def essay_themes() -> list[str]:
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key='essay_themes'").fetchone()
        if row:
            return loads_json(row["value"], [])
        return []
    finally:
        conn.close()


def progress_overview() -> dict[str, Any]:
    """Cola dashboard + redação + gaps + caminho para /progresso (Ciclo HR/JB)."""
    from services_core import dashboard_stats, stats_basis

    dash = dashboard_stats()
    essay = essay_progress()
    path = study_path()
    basis = stats_basis()
    _raw_gaps = dash.get("openGaps") or dash.get("criticalTopics") or []
    gaps = list(_raw_gaps)[:5] if isinstance(_raw_gaps, (list, tuple)) else []
    # Forças por disciplina (acerto quando houver stats)
    subject_force: dict[str, float] = {}
    by_subj = dash.get("accuracyBySubject") or dash.get("subjectAccuracy") or {}
    if isinstance(by_subj, dict):
        for k, v in by_subj.items():
            try:
                subject_force[str(k)] = float(v) * (100.0 if float(v) <= 1.0 else 1.0)
            except (TypeError, ValueError):
                continue
    # Relevo peeks: eixos de redação + sujetos
    peaks: list[dict[str, Any]] = []
    for k in _ESSAY_AXES:
        avg = essay.get("averages", {}).get(k)
        if avg is not None:
            peaks.append(
                {
                    "id": k,
                    "label": _ESSAY_AXIS_LABELS.get(k, k),
                    "value": float(avg),
                    "kind": "essay_axis",
                    "max": 10.0,
                }
            )
    for subj, val in list(subject_force.items())[:6]:
        peaks.append(
            {
                "id": f"subj_{subj}",
                "label": subj,
                "value": min(10.0, float(val) / 10.0),
                "kind": "subject",
                "max": 10.0,
            }
        )
    if not peaks:
        peaks = [
            {"id": "placeholder", "label": "Comece a treinar", "value": 2.0, "kind": "hint", "max": 10.0}
        ]
    # Timeline unificada: missão de redação + nós do caminho concluídos
    path_timeline: list[dict[str, Any]] = []
    essay_tl = essay.get("missionTimeline") if isinstance(essay.get("missionTimeline"), list) else []
    for item in essay_tl[:8]:
        if isinstance(item, dict):
            path_timeline.append(item)
    nodes = path.get("nodes") if isinstance(path.get("nodes"), list) else []
    for n in nodes:
        if not isinstance(n, dict):
            continue
        if n.get("done") or n.get("status") == "done":
            path_timeline.append(
                {
                    "kind": "path_node",
                    "id": n.get("id"),
                    "title": n.get("title") or "Nó do caminho",
                    "subtitle": (n.get("detail") or "Concluído · treino local"),
                    "route": n.get("route") or "/dashboard",
                    "status": "done",
                }
            )
    return {
        "ok": True,
        "essay": essay,
        "path": path,
        "qa": path.get("qa"),
        "streakDays": dash.get("streakDays"),
        "studyMinutesToday": dash.get("studyMinutesToday"),
        "studyMinutesWeek": dash.get("studyMinutesWeek") or (dash.get("weekClose") or {}).get("studyMinutesWeek"),
        "accuracy": dash.get("accuracy"),
        "readiness": dash.get("readinessScore") or (dash.get("weekClose") or {}).get("readinessScore"),
        "activity28": dash.get("activity28") or dash.get("studyCalendar") or [],
        "gaps": gaps,
        "peaks": peaks,
        "missionTimeline": path_timeline[:14],
        "officialCount": basis.get("officialCount", 0),
        "disclaimer": "Progresso local · treino · não é % de aprovação nem banca UEMA.",
        "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
        "essayPath": "/redacao",
        "queuePath": "/fila",
    }

def create_backup() -> dict[str, Any]:
    import hashlib
    import uuid
    import zipfile

    backup_dir = DATA_DIR / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = backup_dir / f"backup_{stamp}_{uuid.uuid4().hex[:6]}"
    dest.mkdir(parents=True, exist_ok=True)

    db_path = DATA_DIR / "paes_med_ai.db"
    files_copied = []
    if db_path.exists():
        shutil.copy2(db_path, dest / "paes_med_ai.db")
        files_copied.append("paes_med_ai.db")
    for sub in ("provas", "gabaritos", "edital", "aulas"):
        src = DATA_DIR / sub
        if src.exists():
            target = dest / sub
            if target.exists():
                try:
                    shutil.rmtree(target)
                except OSError:
                    # Windows: arquivo preso por outro processo — usa pasta nova
                    target = dest / f"{sub}_{uuid.uuid4().hex[:4]}"
            try:
                shutil.copytree(src, target, dirs_exist_ok=True)
                files_copied.append(sub)
            except OSError as exc:
                return {
                    "ok": False,
                    "error": f"Não foi possível copiar {sub}: {exc}",
                    "path": str(dest),
                }

    zip_path = shutil.make_archive(str(dest), "zip", root_dir=dest)
    zpath = Path(zip_path)
    size = zpath.stat().st_size if zpath.exists() else 0
    sha = hashlib.sha256(zpath.read_bytes()).hexdigest()[:16] if zpath.exists() else ""
    member_count = 0
    if zpath.exists():
        with zipfile.ZipFile(zpath, "r") as zf:
            member_count = len(zf.namelist())
    verify = {
        "ok": size > 0 and member_count > 0,
        "bytes": size,
        "sha256Prefix": sha,
        "members": member_count,
        "files": files_copied,
    }
    # Persist last-ok in settings
    conn = connect()
    try:
        conn.execute(
            "INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
            (
                "last_backup_ok",
                json.dumps(
                    {
                        "path": zip_path,
                        "at": datetime.now().isoformat(timespec="seconds"),
                        "verify": verify,
                    },
                    ensure_ascii=False,
                ),
            ),
        )
        conn.commit()
    finally:
        conn.close()
    folder_removed = False
    if verify["ok"]:
        try:
            shutil.rmtree(dest)
            folder_removed = True
        except OSError:
            folder_removed = False
    return {
        "ok": True,
        "path": zip_path,
        "folder": str(dest),
        "folderKept": not folder_removed,
        "verify": verify,
        "note": "Backup verificado em zip. Restore restaura o DB; pastas PDF podem ser reabertas do zip.",
    }


def restore_backup_db(zip_or_folder: str) -> dict[str, Any]:
    """Restaura paes_med_ai.db de um zip ou pasta de backup (com confirmação no cliente)."""
    import zipfile

    src = Path(zip_or_folder)
    if not src.exists():
        return {"ok": False, "error": "path_not_found"}
    tmp_db = None
    if src.suffix.lower() == ".zip":
        with zipfile.ZipFile(src, "r") as zf:
            names = [n for n in zf.namelist() if n.endswith("paes_med_ai.db")]
            if not names:
                return {"ok": False, "error": "db_missing_in_zip"}
            extract_dir = DATA_DIR / "backups" / "_restore_tmp"
            extract_dir.mkdir(parents=True, exist_ok=True)
            zf.extract(names[0], extract_dir)
            tmp_db = extract_dir / names[0]
    else:
        candidate = src / "paes_med_ai.db"
        if not candidate.exists():
            return {"ok": False, "error": "db_missing_in_folder"}
        tmp_db = candidate
    dest = DATA_DIR / "paes_med_ai.db"
    shutil.copy2(tmp_db, dest)
    return {
        "ok": True,
        "dbPath": str(dest),
        "message": "DB restaurado. Pastas PDF: reextraia do zip se precisar (provas/gabaritos/edital).",
        "pdfNote": "O zip inclui pastas PDF; restauração automática de PDF fica manual por segurança.",
    }


def last_backup_status() -> dict[str, Any]:
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key='last_backup_ok'").fetchone()
        if not row:
            return {"ok": False, "message": "Nenhum backup verificado ainda."}
        return {"ok": True, **loads_json(row["value"], {})}
    finally:
        conn.close()


def backup_storage_summary() -> dict[str, Any]:
    backup_dir = DATA_DIR / "backups"
    if not backup_dir.exists():
        return {"ok": True, "count": 0, "dirs": 0, "zips": 0, "bytes": 0, "mb": 0}
    files = list(backup_dir.rglob("*"))
    total = sum(p.stat().st_size for p in files if p.is_file())
    dirs = sum(1 for p in backup_dir.iterdir() if p.is_dir())
    zips = sum(1 for p in backup_dir.iterdir() if p.is_file() and p.suffix.lower() == ".zip")
    return {
        "ok": True,
        "count": dirs + zips,
        "dirs": dirs,
        "zips": zips,
        "bytes": total,
        "mb": round(total / (1024 * 1024), 2),
        "path": str(backup_dir),
        "warning": (
            "Muitos backups ocupando espaço; rode tools\\limpar_backups.ps1 primeiro para simular."
            if total > 5 * 1024 * 1024 * 1024 or dirs + zips > 60
            else None
        ),
    }


def backup_cleanup_plan(keep: int = 10) -> dict[str, Any]:
    backup_dir = DATA_DIR / "backups"
    keep = max(1, min(int(keep or 10), 200))
    if not backup_dir.exists():
        return {
            "ok": True,
            "keep": keep,
            "total": 0,
            "removeCount": 0,
            "reclaimBytes": 0,
            "reclaimMb": 0,
            "candidates": [],
            "command": f"powershell -ExecutionPolicy Bypass -File tools\\limpar_backups.ps1 -Keep {keep} -Apply",
        }

    items = [
        p
        for p in backup_dir.iterdir()
        if p.name != "_restore_tmp" and (p.is_dir() or (p.is_file() and p.suffix.lower() == ".zip"))
    ]
    items.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    remove = items[keep:]

    def item_size(path: Path) -> int:
        if path.is_file():
            return path.stat().st_size
        return sum(f.stat().st_size for f in path.rglob("*") if f.is_file())

    candidates = []
    total_bytes = 0
    for p in remove:
        size = item_size(p)
        total_bytes += size
        candidates.append(
            {
                "name": p.name,
                "kind": "folder" if p.is_dir() else "zip",
                "bytes": size,
                "mb": round(size / (1024 * 1024), 2),
                "modifiedAt": datetime.fromtimestamp(p.stat().st_mtime).isoformat(timespec="seconds"),
            }
        )

    return {
        "ok": True,
        "keep": keep,
        "total": len(items),
        "removeCount": len(remove),
        "reclaimBytes": total_bytes,
        "reclaimMb": round(total_bytes / (1024 * 1024), 2),
        "candidates": candidates[:5],
        "command": f"powershell -ExecutionPolicy Bypass -File tools\\limpar_backups.ps1 -Keep {keep} -Apply",
        "dryRun": True,
    }


def list_backups(limit: int = 30) -> list[dict[str, Any]]:
    import zipfile

    backup_dir = DATA_DIR / "backups"
    if not backup_dir.exists():
        return []
    entries: dict[str, dict[str, Any]] = {}
    for p in backup_dir.iterdir():
        if p.name == "_restore_tmp":
            continue
        if p.is_file() and p.suffix.lower() == ".zip":
            key = p.stem
            stat = p.stat()
            item: dict[str, Any] = {
                "name": p.name,
                "path": str(p),
                "kind": "zip",
                "bytes": stat.st_size,
                "modifiedAt": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
            }
            try:
                with zipfile.ZipFile(p, "r") as zf:
                    names = zf.namelist()
                    item["verify"] = {"ok": len(names) > 0, "members": len(names), "bytes": stat.st_size}
            except zipfile.BadZipFile:
                item["verify"] = {"ok": False, "error": "zip_invalido", "bytes": stat.st_size}
            entries[key] = item
            continue
        if p.is_dir() and (p / "paes_med_ai.db").exists():
            key = p.name
            stat = p.stat()
            entries.setdefault(
                key,
                {
                    "name": p.name,
                    "path": str(p),
                    "kind": "folder",
                    "bytes": sum(f.stat().st_size for f in p.rglob("*") if f.is_file()),
                    "modifiedAt": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
                },
            )
    return sorted(entries.values(), key=lambda item: item.get("modifiedAt", ""), reverse=True)[:limit]


def register_ingest(filename: str, kind: str, status: str, message: str) -> None:
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO ingest_jobs (filename, kind, status, message, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (filename, kind, status, message, datetime.now().isoformat(timespec="seconds")),
        )
        conn.commit()
    finally:
        conn.close()


def ingest_pdf_placeholder(filename: str, kind: str) -> dict[str, Any]:
    """Registra PDF oficial para processamento. OCR completo fica para lote com revisão humana."""
    folder = DATA_DIR / ("provas" if kind == "prova" else "gabaritos" if kind == "gabarito" else "edital")
    folder.mkdir(parents=True, exist_ok=True)
    message = (
        f"Arquivo '{filename}' registrado em {folder}. "
        "O parse/OCR automático exige revisão humana antes de entrar nas estatísticas oficiais. "
        "A base atual já possui questões de treino alinhadas ao edital para uso imediato."
    )
    register_ingest(filename, kind, "pendente_revisao", message)
    return {"ok": True, "status": "pendente_revisao", "message": message}


def generate_similar_question_stub(topic: str, subject: str) -> dict[str, Any]:
    """Marca questão como gerada (estilo UEMA) — conteúdo deve ser revisado."""
    qid = f"gen-{uuid.uuid4().hex[:8]}"
    statement = (
        f"[QUESTÃO INÉDITA — ESTILO UEMA — REVISAR] Sobre {topic} ({subject}), "
        f"assinale a alternativa correta conforme o padrão da banca."
    )
    options = [
        "Afirmação plausível porém incompleta",
        "Afirmação correta no núcleo do conteúdo",
        "Distrator clássico por troca de termos",
        "Generalização indevida",
        "Dado fora do edital",
    ]
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO questions (
                id, year, subject, topic, statement, options_json, correct_index, difficulty,
                source, resolution, banca_intent, macete, pegadinha, generated, approved, avg_text_len
            ) VALUES (?, ?, ?, ?, ?, ?, 1, 'Média', 'gerada_estilo_uema', ?, ?, ?, ?, 1, 0, ?)
            """,
            (
                qid,
                datetime.now().year,
                subject,
                topic,
                statement,
                json.dumps(options, ensure_ascii=False),
                "Resolver identificando o conceito central do tópico e eliminando distratores.",
                f"Treinar reconhecimento do padrão de cobrança em {topic}.",
                "Elimine extremos e termos trocados.",
                "Distrator troca nomes parecidos.",
                len(statement),
            ),
        )
        conn.commit()
    finally:
        conn.close()
    return {
        "id": qid,
        "generated": True,
        "approved": False,
        "warning": "Questão gerada — pendente em Aprovar antes de simulado sério.",
    }


def qa_progress() -> dict[str, Any]:
    """Progresso local de Q&A (acertos/streak) — treino, não % de aprovação UEMA."""
    conn = connect()
    try:
        row = conn.execute(
            """
            SELECT
              COUNT(*) AS total,
              SUM(CASE WHEN COALESCE(correct,0)=1 THEN 1 ELSE 0 END) AS correct,
              COUNT(DISTINCT CASE WHEN TRIM(COALESCE(subject,''))!='' THEN subject END) AS subjects,
              COUNT(DISTINCT CASE WHEN TRIM(COALESCE(topic,''))!=''
                THEN subject || '::' || topic END) AS topics
            FROM answers
            """
        ).fetchone()
        total = int(row["total"] or 0) if row else 0
        correct = int(row["correct"] or 0) if row else 0
        subjects = int(row["subjects"] or 0) if row else 0
        topics = int(row["topics"] or 0) if row else 0
        day_rows = conn.execute(
            """
            SELECT DISTINCT substr(answered_at, 1, 10) AS d
            FROM answers
            WHERE answered_at IS NOT NULL AND length(answered_at) >= 10
            ORDER BY d DESC
            """
        ).fetchall()
        days_set = {str(r["d"]) for r in day_rows if r["d"]}
        last = conn.execute(
            "SELECT answered_at FROM answers ORDER BY answered_at DESC LIMIT 1"
        ).fetchone()
        last_at = last["answered_at"] if last else None
    finally:
        conn.close()

    streak = 0
    if days_set:
        cursor = datetime.now().date()
        if cursor.isoformat() not in days_set:
            cursor = cursor - timedelta(days=1)
        while cursor.isoformat() in days_set:
            streak += 1
            cursor = cursor - timedelta(days=1)

    accuracy = round(100.0 * correct / total, 1) if total else None
    return {
        "ok": True,
        "answersTotal": int(total),
        "answersCorrect": int(correct),
        "accuracyPercent": accuracy,
        "subjectsTouched": int(subjects),
        "topicsTouched": int(topics),
        "streakDays": streak,
        "lastAnswerAt": last_at,
        "disclaimer": "Treino local de questões · não é prova oficial nem garantia de aprovação.",
    }


def study_path() -> dict[str, Any]:
    """
    Caminho gamificado unificado: Q&A + redação.
    Níveis e nós são treino local — não inventamos nota de banca.
    """
    now = time.monotonic()
    cached = _path_cache.get("v")
    if cached is not None and (now - float(_path_cache.get("t") or 0)) < _PATH_TTL_S:
        return cached
    result = _study_path_compute()
    _path_cache["t"] = now
    _path_cache["v"] = result
    return result


def _study_path_compute() -> dict[str, Any]:
    qa = qa_progress()
    essay = essay_progress()
    n_ans = int(qa.get("answersTotal") or 0)
    n_ok = int(qa.get("answersCorrect") or 0)
    n_essays = int(essay.get("count") or 0)
    qa_streak = int(qa.get("streakDays") or 0)
    essay_streak = int(essay.get("streakDays") or 0)
    mission = essay.get("nextMission") if isinstance(essay.get("nextMission"), dict) else None
    mission_cleared = (mission or {}).get("status") == "cleared" or (
        essay.get("missionStatus") == "cleared"
    )

    # XP local (heurística transparente)
    xp = (
        n_ans * 2
        + n_ok * 3
        + n_essays * 28
        + max(qa_streak, essay_streak) * 10
        + (25 if mission_cleared else 0)
        + int(qa.get("topicsTouched") or 0) * 2
    )
    level = max(1, min(25, 1 + xp // 45))
    if level < 3:
        level_label = "Iniciante"
    elif level < 6:
        level_label = "Trilha"
    elif level < 10:
        level_label = "Ritmo"
    elif level < 15:
        level_label = "Maratonista"
    else:
        level_label = "Studio"

    def node(
        nid: str,
        *,
        kind: str,
        title: str,
        detail: str,
        done: bool,
        cta: str,
        route: str,
        progress: float | None = None,
    ) -> dict[str, Any]:
        return {
            "id": nid,
            "kind": kind,  # qa | essay | mix
            "title": title,
            "detail": detail,
            "done": done,
            "cta": cta,
            "route": route,
            "progress": progress,
        }

    raw_nodes: list[dict[str, Any]] = [
        node(
            "start",
            kind="mix",
            title="Base",
            detail="Abra o app e comece a treinar",
            done=n_ans > 0 or n_essays > 0,
            cta="Ir ao Hoje",
            route="/dashboard",
            progress=1.0 if (n_ans > 0 or n_essays > 0) else 0.0,
        ),
        node(
            "qa_10",
            kind="qa",
            title="10 questões",
            detail=f"{min(n_ans, 10)}/10 respostas salvas",
            done=n_ans >= 10,
            cta="Banco de questões",
            route="/questoes",
            progress=min(1.0, n_ans / 10.0),
        ),
        node(
            "essay_1",
            kind="essay",
            title="1ª redação",
            detail="Corrigir pelo menos um texto (treino local)",
            done=n_essays >= 1,
            cta="Escrever",
            route="/redacao",
            progress=1.0 if n_essays >= 1 else 0.0,
        ),
        node(
            "qa_topic",
            kind="qa",
            title="5 tópicos",
            detail=f"{min(int(qa.get('topicsTouched') or 0), 5)}/5 temas tocados",
            done=int(qa.get("topicsTouched") or 0) >= 5,
            cta="Sessão",
            route="/sessao",
            progress=min(1.0, int(qa.get("topicsTouched") or 0) / 5.0),
        ),
        node(
            "essay_mission",
            kind="essay",
            title="Missão de eixo",
            detail=(
                "Suba o eixo mais fraco na redação"
                if not mission_cleared
                else "Missão de eixo concluída"
            ),
            done=bool(mission_cleared) or n_essays >= 3,
            cta="Missão de redação",
            route="/redacao",
            progress=1.0 if mission_cleared or n_essays >= 3 else (0.5 if n_essays >= 1 else 0.0),
        ),
        node(
            "qa_50",
            kind="qa",
            title="50 questões",
            detail=f"{min(n_ans, 50)}/50 · volume de treino",
            done=n_ans >= 50,
            cta="Continuar Q&A",
            route="/questoes",
            progress=min(1.0, n_ans / 50.0),
        ),
        node(
            "essay_5",
            kind="essay",
            title="5 redações",
            detail=f"{min(n_essays, 5)}/5 textos corrigidos",
            done=n_essays >= 5,
            cta="Nova redação",
            route="/redacao",
            progress=min(1.0, n_essays / 5.0),
        ),
        node(
            "streak_3",
            kind="mix",
            title="Sequência 3 dias",
            detail=f"Melhor streak: Q&A {qa_streak}d · redação {essay_streak}d",
            done=max(qa_streak, essay_streak) >= 3,
            cta="Fila do dia",
            route="/fila",
            progress=min(1.0, max(qa_streak, essay_streak) / 3.0),
        ),
        node(
            "studio",
            kind="mix",
            title="Studio firme",
            detail="50+ questões e 5+ redações (ritmo de studio)",
            done=n_ans >= 50 and n_essays >= 5,
            cta="Ver relevo",
            route="/progresso",
            progress=min(1.0, (min(n_ans, 50) / 50.0 + min(n_essays, 5) / 5.0) / 2.0),
        ),
    ]

    nodes: list[dict[str, Any]] = []
    found_active = False
    for n in raw_nodes:
        if n["done"]:
            status = "done"
        elif not found_active:
            status = "active"
            found_active = True
        else:
            status = "locked"
        n2 = dict(n)
        n2["status"] = status
        nodes.append(n2)

    current = next((n for n in nodes if n["status"] == "active"), None)
    if current is None and nodes:
        current = nodes[-1]

    done_n = sum(1 for n in nodes if n["status"] == "done")
    return {
        "ok": True,
        "xp": xp,
        "level": level,
        "levelLabel": level_label,
        "nodes": nodes,
        "current": current,
        "doneCount": done_n,
        "totalCount": len(nodes),
        "pathProgress": round(done_n / len(nodes), 3) if nodes else 0.0,
        "qa": qa,
        "essay": {
            "count": n_essays,
            "levelLabel": essay.get("levelLabel"),
            "streakDays": essay_streak,
            "missionStatus": essay.get("missionStatus"),
            "meanScore": essay.get("meanScore"),
        },
        "disclaimer": (
            "Caminho de treino local (Q&A + redação). "
            "Não é nota da banca UEMA nem garantia de aprovação."
        ),
    }


# ---------------------------------------------------------------------------
# Ciclo JC — ensinar de verdade (heurísticas locais, sem inventar oficial)
# ---------------------------------------------------------------------------

TEACH_DISCLAIMER = (
    "Heurística de treino local: sugere o que estudar com base nos seus erros e materiais do PC. "
    "Não é nota da banca UEMA nem garantia de aprovação."
)


def _clip_text(s: str | None, n: int = 420) -> str:
    t = (s or "").strip()
    if len(t) <= n:
        return t
    return t[: n - 1].rstrip() + "…"


def build_teach_block(
    *,
    question_id: str | None = None,
    subject: str = "",
    topic: str = "",
    correct: bool | None = None,
    error_type: str | None = None,
    question: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """
    Bloco didático pós-resposta.
    Usa só campos da base (resolução, eixos, macete). Nunca inventa gabarito oficial.
    """
    from services_core import get_question, is_official_source

    q = question
    if q is None and question_id:
        q = get_question(question_id) or {}
    q = q or {}

    subj = (subject or q.get("subject") or "").strip()
    top = (topic or q.get("topic") or "").strip()
    exam_board = (q.get("examBoard") or "TREINO").strip().upper()
    is_official = bool(q.get("isOfficial")) or is_official_source(q.get("source"), q.get("generated"))
    quality = (q.get("resolutionQuality") or "template").strip().lower()
    axes = q.get("resolutionAxes") if isinstance(q.get("resolutionAxes"), dict) else {}
    resolution = (q.get("resolution") or "").strip()
    macete = (q.get("macete") or "").strip()
    pegadinha = (q.get("pegadinha") or "").strip()
    banca = (q.get("bancaIntent") or q.get("banca_intent") or "").strip()
    concept_axis = _clip_text((axes or {}).get("conceito") or "", 360)
    comando_axis = _clip_text((axes or {}).get("comando") or "", 220)

    has_stored_teach = bool(concept_axis or resolution or macete or banca)

    concept_parts: list[str] = []
    if concept_axis:
        concept_parts.append(concept_axis)
    elif resolution and quality == "real":
        concept_parts.append(_clip_text(resolution, 360))
    elif resolution:
        concept_parts.append(_clip_text(resolution, 280))
    if not concept_parts:
        if top and subj:
            concept_parts.append(
                f"Revise o núcleo de «{top}» em {subj}: defina o conceito em 1 frase suas "
                "e reconecte com o verbo de comando do enunciado."
            )
        elif top:
            concept_parts.append(
                f"Revise o conceito de «{top}»: escreva 1 frase + 1 exemplo simples (treino local)."
            )
        else:
            concept_parts.append(
                "Revise o tema deste item: releia o enunciado, isole o comando e elimine extremos."
            )
    concept = " ".join(concept_parts)

    review_points: list[str] = []
    if comando_axis:
        review_points.append(f"Comando da questão: {comando_axis}")
    if macete:
        review_points.append(f"Macete local: {_clip_text(macete, 200)}")
    if pegadinha:
        review_points.append(f"Pegadinha típica: {_clip_text(pegadinha, 200)}")
    if banca:
        review_points.append(f"Intenção da banca (treino): {_clip_text(banca, 200)}")
    if not review_points:
        review_points = [
            f"Releia teoria de {top or 'do tópico'} em {subj or 'a disciplina'} (2–4 min).",
            "Escreva a ideia-central em 1 frase com suas palavras.",
            "Faça 2–3 itens do mesmo tópico só depois da revisão do conceito.",
        ]
    if error_type:
        rem = remediation_for(error_type, subj, top)
        for step in (rem.get("steps") or [])[:2]:
            s = str(step).strip()
            if s and s not in review_points:
                review_points.append(s)

    # Gabarito: só o que a base já tem (índice + marca de fonte) — sem inventar
    correct_idx = q.get("correctIndex")
    if correct_idx is None:
        correct_idx = q.get("correct_index")
    letter = None
    try:
        if correct_idx is not None:
            i = int(correct_idx)
            if 0 <= i <= 4:
                letter = "ABCDE"[i]
    except (TypeError, ValueError):
        letter = None

    if letter is None:
        gabarito_status = "unavailable"
        gabarito_message = "Gabarito oficial não disponível neste item."
    elif is_official and exam_board == "UEMA_PAES":
        gabarito_status = "official_index"
        gabarito_message = f"Gabarito da base (PAES-UEMA no acervo local): {letter}"
    else:
        gabarito_status = "training_index"
        gabarito_message = (
            f"Resposta da base de treino: {letter} "
            f"({'outra banca' if exam_board == 'OUTRA' else 'treino local'} — não inventamos oficial ausente)."
        )

    theory_path = (
        f"/questoes?subject={subj}&topic={top}" if subj else "/questoes"
    )
    materials_path = f"/biblioteca?subject={subj}&topic={top}" if subj else "/biblioteca"
    adaptive_path = (
        f"/adaptativo?subject={subj}&topic={top}" if subj else "/adaptativo"
    )
    force_review = correct is False

    next_steps: list[dict[str, Any]] = []
    if force_review:
        next_steps.append(
            {
                "id": "review_concept",
                "label": "Revisar conceito (prioridade)",
                "route": None,
                "action": "open_theory",
                "subject": subj,
                "topic": top,
                "priority": 1,
                "why": "Erro recente — priorize o conceito antes de bombardear a próxima Q.",
            }
        )
        next_steps.append(
            {
                "id": "materials",
                "label": "Materiais do tópico",
                "route": materials_path,
                "action": "materials_pack",
                "subject": subj,
                "topic": top,
                "priority": 2,
                "why": "Pacote banca/vídeo/leitura/busca — escolha o que existe no PC/web.",
            }
        )
        next_steps.append(
            {
                "id": "same_topic",
                "label": "Treinar mesmo tópico",
                "route": adaptive_path,
                "action": "adaptive",
                "subject": subj,
                "topic": top,
                "priority": 3,
                "why": "Só depois de reler o conceito.",
            }
        )
    else:
        next_steps.append(
            {
                "id": "same_topic",
                "label": "Mais do tópico",
                "route": adaptive_path,
                "action": "adaptive",
                "subject": subj,
                "topic": top,
                "priority": 1,
                "why": "Consolidar acerto no mesmo tema.",
            }
        )
        next_steps.append(
            {
                "id": "materials",
                "label": "Materiais",
                "route": materials_path,
                "action": "materials_pack",
                "subject": subj,
                "topic": top,
                "priority": 2,
                "why": "Reforço opcional se quiser firmar o conceito.",
            }
        )

    try:
        from services_media import study_materials_pack

        pack_meta = study_materials_pack(subject=subj or None, topic=top or None)
        pack_hint = {
            "suggestedLane": pack_meta.get("suggestedLane"),
            "totalItems": pack_meta.get("totalItems"),
            "subject": subj,
            "topic": top,
        }
    except Exception:
        pack_hint = {"subject": subj, "topic": top, "totalItems": 0}

    primary = next_steps[0] if next_steps else None
    return {
        "ok": True,
        "correct": correct,
        "subject": subj,
        "topic": top,
        "examBoard": exam_board,
        "isOfficial": is_official,
        "forceReview": force_review,
        "concept": concept,
        "hasStoredTeach": has_stored_teach,
        "reviewPoints": review_points[:6],
        "quality": quality,
        "gabarito": {
            "status": gabarito_status,
            "message": gabarito_message,
            "letter": letter,
        },
        "materials": pack_hint,
        "nextSteps": next_steps,
        "primaryCta": primary,
        "paths": {
            "adaptive": adaptive_path,
            "materials": materials_path,
            "theory": theory_path,
            "queue": "/fila",
            "session": (
                f"/sessao?examBoard=UEMA_PAES&subject={subj}&topic={top}"
                if subj
                else "/sessao?examBoard=UEMA_PAES&preferNatureza=1"
            ),
        },
        "whyThisMatters": (
            f"Você errou em {subj} · {top} — dominar o conceito reduz repetição do mesmo buraco."
            if force_review and subj
            else (
                f"Acertou em {subj} · {top} — um reforço curto do tópico trava o aprendizado."
                if correct and subj
                else "Ligue teoria + questão + material no mesmo tópico (treino local)."
            )
        ),
        "disclaimer": TEACH_DISCLAIMER,
        "label": "treino local · ensinar de verdade",
    }


def _weak_topics_from_answers(*, limit: int = 6) -> list[dict[str, Any]]:
    conn = connect()
    try:
        rows = conn.execute(
            """
            SELECT subject, topic,
                   COUNT(*) AS n,
                   SUM(CASE WHEN COALESCE(correct,0)=0 THEN 1 ELSE 0 END) AS misses,
                   MAX(answered_at) AS last_at
            FROM answers
            WHERE TRIM(COALESCE(subject,'')) != '' AND TRIM(COALESCE(topic,'')) != ''
            GROUP BY subject, topic
            HAVING n >= 1
            ORDER BY
                (1.0 * misses / n) DESC,
                misses DESC,
                last_at DESC
            LIMIT ?
            """,
            (max(1, min(limit, 20)),),
        ).fetchall()
    finally:
        conn.close()
    out: list[dict[str, Any]] = []
    for r in rows:
        n = int(r["n"] or 0)
        misses = int(r["misses"] or 0)
        rate = round(100.0 * misses / n, 1) if n else 0.0
        if misses == 0 and n < 3:
            continue  # pouco sinal
        out.append(
            {
                "subject": r["subject"],
                "topic": r["topic"],
                "attempts": n,
                "misses": misses,
                "wrongRate": rate,
                "lastAt": r["last_at"],
            }
        )
    # Prefer topics with at least one miss
    with_miss = [x for x in out if x["misses"] > 0]
    return (with_miss or out)[:limit]


def study_coach() -> dict[str, Any]:
    """
    Coach de estudo: fracos + 1 foco Q + 1 material + 1 revisão/card se due.
    Heurística local transparente — sem garantir aprovação.
    """
    from services_advanced import list_flashcards
    from services_core import list_questions

    weak = _weak_topics_from_answers(limit=5)
    gaps_payload = list_study_gaps(status="open", limit=8)
    gap_items = list(gaps_payload.get("items") or [])
    revisions = list_revisions()
    due_rev = [
        r
        for r in revisions
        if isinstance(r, dict)
        and (r.get("due") is True or r.get("status") == "due" or r.get("pending") is True)
    ]
    if not due_rev:
        # fallback: first few scheduled
        due_rev = [r for r in revisions if isinstance(r, dict)][:3]

    due_cards: list[dict[str, Any]] = []
    try:
        raw_cards = list_flashcards(due_only=True)
        if isinstance(raw_cards, list):
            due_cards = [c for c in raw_cards if isinstance(c, dict)][:8]
        elif isinstance(raw_cards, dict):
            due_cards = list(raw_cards.get("items") or raw_cards.get("cards") or [])[:8]
    except TypeError:
        try:
            raw_cards = list_flashcards()
            due_cards = [c for c in (raw_cards or []) if isinstance(c, dict)][:5]
        except Exception:
            due_cards = []
    except Exception:
        due_cards = []

    focus_subj = ""
    focus_topic = ""
    focus_source = "path"
    if weak:
        focus_subj = str(weak[0]["subject"])
        focus_topic = str(weak[0]["topic"])
        focus_source = "errors"
    elif gap_items:
        g0 = gap_items[0] if isinstance(gap_items[0], dict) else {}
        focus_subj = str(g0.get("subject") or "")
        focus_topic = str(g0.get("topic") or "")
        focus_source = "gaps"

    path = study_path()
    current = path.get("current") if isinstance(path.get("current"), dict) else None
    if (not focus_subj or not focus_topic) and current:
        route = str(current.get("route") or "")
        if "redacao" in route:
            focus_source = "path_essay"
        else:
            focus_source = "path"

    # 1 questão foco
    focus_question: dict[str, Any] | None = None
    if focus_subj:
        try:
            qs = list_questions(subject=focus_subj, topic=focus_topic or None, limit=12)
            items = qs if isinstance(qs, list) else []
            for it in items:
                if not isinstance(it, dict):
                    continue
                if it.get("generated") and not it.get("approved"):
                    continue
                focus_question = {
                    "id": it.get("id"),
                    "subject": it.get("subject"),
                    "topic": it.get("topic"),
                    "year": it.get("year"),
                    "examBoard": it.get("examBoard"),
                    "route": f"/questoes/{it.get('id')}",
                }
                break
        except Exception:
            focus_question = None

    materials_lane = {
        "subject": focus_subj,
        "topic": focus_topic,
        "suggestedLane": "video",
        "route": f"/biblioteca?subject={focus_subj}&topic={focus_topic}" if focus_subj else "/biblioteca",
        "label": "Materiais do tópico fraco" if focus_subj else "Abrir biblioteca",
    }
    try:
        from services_media import study_materials_pack

        if focus_subj:
            pack = study_materials_pack(subject=focus_subj, topic=focus_topic or None)
            materials_lane["suggestedLane"] = pack.get("suggestedLane") or "video"
            materials_lane["totalItems"] = pack.get("totalItems")
    except Exception:
        pass

    revision_lane: dict[str, Any] | None = None
    if due_cards:
        revision_lane = {
            "kind": "flashcard",
            "count": len(due_cards),
            "label": f"{len(due_cards)} card(s) due",
            "route": "/flashcards?due=1",
        }
    elif due_rev:
        r0 = due_rev[0]
        revision_lane = {
            "kind": "revision",
            "subject": r0.get("subject"),
            "topic": r0.get("topic"),
            "label": f"Revisão · {r0.get('subject')} · {r0.get('topic')}",
            "route": "/fila",
        }
    elif gap_items:
        g0 = gap_items[0] if isinstance(gap_items[0], dict) else {}
        revision_lane = {
            "kind": "gap",
            "subject": g0.get("subject"),
            "topic": g0.get("topic"),
            "label": f"Lacuna · {g0.get('subject')} · {g0.get('topic')}",
            "route": (
                f"/adaptativo?subject={g0.get('subject')}&topic={g0.get('topic')}"
                if g0.get("subject")
                else "/fila"
            ),
        }

    # Primary action (one clear next move)
    if revision_lane and revision_lane.get("kind") == "flashcard" and len(due_cards) >= 3:
        primary = {
            "id": "cards",
            "label": "Revisar cards due",
            "route": "/flashcards?due=1",
            "why": "Há cards vencidos — fecha o ciclo SRS antes de novas questões.",
        }
    elif focus_question and focus_question.get("id"):
        primary = {
            "id": "question",
            "label": f"Questão foco · {focus_subj} · {focus_topic}" if focus_topic else "Questão foco",
            "route": focus_question["route"],
            "why": (
                "Erro recente no tópico — pratique com 1 item guiado e revise o conceito se errar."
                if focus_source == "errors"
                else "Próximo passo de treino local no tema prioritário."
            ),
            "questionId": focus_question.get("id"),
        }
    elif current and current.get("route"):
        primary = {
            "id": "path",
            "label": current.get("cta") or current.get("title") or "Próximo nó do caminho",
            "route": current.get("route"),
            "why": current.get("detail") or "Continue o caminho de treino local.",
        }
    else:
        primary = {
            "id": "session",
            "label": "Começar sessão guiada",
            "route": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
            "why": "Ainda sem histórico de erros — a sessão monta um bloco didático do dia.",
        }

    headline = "O que estudar agora"
    if focus_subj and focus_topic and focus_source == "errors":
        line = f"Prioridade: {focus_subj} · {focus_topic} (erros recentes no treino local)."
    elif focus_subj and focus_topic:
        line = f"Foco sugerido: {focus_subj} · {focus_topic}."
    elif current:
        line = f"Caminho: {current.get('title')} — {current.get('detail') or 'próximo passo'}."
    else:
        line = "Comece com uma sessão guiada (Natureza) ou responda 5 questões."

    return {
        "ok": True,
        "headline": headline,
        "line": line,
        "weakTopics": weak,
        "openGaps": gap_items[:5],
        "openGapsCount": int(gaps_payload.get("openCount") or len(gap_items)),
        "focus": {
            "subject": focus_subj,
            "topic": focus_topic,
            "source": focus_source,
            "question": focus_question,
        },
        "materialLane": materials_lane,
        "revisionLane": revision_lane,
        "primary": primary,
        "path": {
            "current": current,
            "level": path.get("level"),
            "xp": path.get("xp"),
            "pathProgress": path.get("pathProgress"),
        },
        "suggestions": [
            primary,
            {
                "id": "materials",
                "label": materials_lane.get("label"),
                "route": materials_lane.get("route"),
                "why": "Pacote de materiais (banca/vídeo/leitura/busca) do tópico.",
            },
            revision_lane
            or {
                "id": "queue",
                "label": "Abrir fila do dia",
                "route": "/fila",
                "why": "Lacunas e revisões agendadas.",
            },
        ],
        "disclaimer": TEACH_DISCLAIMER,
        "label": "coach local · treino",
    }


def session_teach_summary(misses: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    """Agrupa erros da sessão por tópico + CTAs de material (honesto)."""
    grouped: dict[tuple[str, str], int] = {}
    for m in misses or []:
        if not isinstance(m, dict):
            continue
        s = str(m.get("subject") or "").strip()
        t = str(m.get("topic") or "").strip()
        if not s and not t:
            continue
        key = (s, t)
        grouped[key] = grouped.get(key, 0) + 1
    topics: list[dict[str, Any]] = []
    for (s, t), n in sorted(grouped.items(), key=lambda x: -x[1]):
        topics.append(
            {
                "subject": s,
                "topic": t,
                "missCount": n,
                "adaptPath": f"/adaptativo?subject={s}&topic={t}" if s else "/adaptativo",
                "materialsPath": f"/biblioteca?subject={s}&topic={t}" if s else "/biblioteca",
                "reviewLabel": f"Revisar materiais · {s} · {t}",
                "trainLabel": f"Treinar · {t or s}",
            }
        )
    return {
        "ok": True,
        "topics": topics,
        "empty": not topics,
        "message": (
            "Erros agrupados por tópico — revise o material antes de bombardear a próxima lista."
            if topics
            else "Sem erros neste bloco — consolidar na Fila ou no próximo nó do caminho."
        ),
        "disclaimer": TEACH_DISCLAIMER,
    }


def essay_teach_after_grade(feedback: dict[str, Any] | None = None) -> dict[str, Any]:
    """Pós-correção: eixo fraco + missão + dica de escrita (treino local)."""
    essay = essay_progress()
    mission = essay.get("nextMission") if isinstance(essay.get("nextMission"), dict) else None
    weak = essay.get("weakestAxis") or (mission or {}).get("axis")
    labels = {
        "grammar": "Gramática",
        "cohesion": "Coesão",
        "coherence": "Coerência",
        "argumentation": "Argumentação",
        "intervention": "Intervenção",
    }
    tips_local = {
        "grammar": "Releia 1 parágrafo em voz alta e marque só acordo verbo-nome e pontuação.",
        "cohesion": "Conecte frases com 3 conectores diferentes (contudo, além disso, assim).",
        "coherence": "Escreva o tópico frasal de cada parágrafo em 1 linha antes de expandir.",
        "argumentation": "Traga 1 dado/exemplo e 1 contraponto curto no parágrafo de desenvolvimento.",
        "intervention": "Feche com agente + ação + meio + finalidade (sem utopia genérica).",
    }
    tip = tips_local.get(str(weak or ""), "Reescreva o parágrafo mais fraco com foco em clareza.")
    path = study_path()
    current = path.get("current") if isinstance(path.get("current"), dict) else None
    return {
        "ok": True,
        "weakestAxis": weak,
        "weakestLabel": labels.get(str(weak or ""), weak),
        "tip": tip,
        "mission": mission,
        "pathNode": current,
        "readingTip": {
            "label": "Dica de escrita (treino local)",
            "body": tip,
            "disclaimer": "Dica gerada localmente — não é correção oficial UEMA.",
        },
        "cta": {
            "label": "Reescrever no eixo fraco",
            "route": "/redacao",
            "path": (current or {}).get("route") if current else "/redacao",
        },
        "disclaimer": TEACH_DISCLAIMER,
    }
