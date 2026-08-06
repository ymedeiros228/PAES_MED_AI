"""Tutor RAG, aulas/vídeo, redação, simulados, backup."""

from __future__ import annotations

import json
import shutil
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from db import DATA_DIR, connect, loads_json
from services_core import list_questions, medicine_priority, predict_topic, stats_basis, topic_frequency

ROOT = Path(__file__).resolve().parent.parent

REMEDIATION_RECIPES: dict[str, dict[str, Any]] = {
    "conceito": {
        "title": "Remediação — conceito",
        "steps": [
            "Releia o trecho do edital/teoria do tópico (2–3 min).",
            "Escreva a definição em 1 frase com suas palavras.",
            "Faça 2–3 questões fáceis/médias do mesmo tópico.",
        ],
        "practiceHint": "Priorize questões de conceito (definição/classificação).",
        "axisFocus": "conceito",
        "diagnosis": "O erro costuma ser falha de definição ou classificação — volte ao conceito antes de marcar.",
        "socraticSeed": "Em uma frase, o que este tópico exige que você saiba definir?",
    },
    "interpretacao": {
        "title": "Remediação — interpretação",
        "steps": [
            "Sublinhe o verbo de comando do enunciado.",
            "Marque dados úteis vs distratores; ignore enfeite.",
            "Elimine 2 alternativas e justifique por que caem.",
        ],
        "practiceHint": "Treine enunciados longos do mesmo assunto.",
        "axisFocus": "comando",
        "diagnosis": "O erro costuma ser ler o comando errado ou cair no distrator — releia o que a banca pede.",
        "socraticSeed": "Qual é o verbo de comando do enunciado e o que ele exige exatamente?",
    },
    "calculo": {
        "title": "Remediação — cálculo",
        "steps": [
            "Refaça o cálculo no papel sem olhar o gabarito.",
            "Cheque unidades e ordem de grandeza.",
            "Refaça 2 exercícios numéricos parecidos.",
        ],
        "practiceHint": "Foque itens com números/gráficos do tópico.",
        "axisFocus": "gabarito",
        "diagnosis": "O erro costuma ser conta/unidade — refaça no papel e cheque a ordem de grandeza.",
        "socraticSeed": "Quais dados numéricos entram na conta e qual unidade o gabarito exige?",
    },
    "distracao": {
        "title": "Remediação — distração",
        "steps": [
            "Pause 30s; respire; releia só o que a banca pergunta.",
            "Confira se marcou a letra que você escolheu.",
            "Próxima questão: ritual de 5s de foco antes de ler.",
        ],
        "practiceHint": "Simulado curto (5 Q) com timer leve.",
        "axisFocus": "distrator",
        "diagnosis": "O erro costuma ser pressa ou marcar outra letra — ritual de foco antes da próxima.",
        "socraticSeed": "O que você marcou e o que o enunciado pedia de fato?",
    },
    "tempo": {
        "title": "Remediação — tempo",
        "steps": [
            "Cronometre a próxima tentativa (máx. 2 min).",
            "Se travar, chute informado e marque para revisão.",
            "Treine 5 questões em bloco cronometrado.",
        ],
        "practiceHint": "Bloco cronometrado do mesmo tópico.",
        "axisFocus": "comando",
        "diagnosis": "O erro costuma ser pressão de tempo — limite 2 min e avance com chute informado se travar.",
        "socraticSeed": "Em 30 segundos, qual atalho elimina duas alternativas claramente erradas?",
    },
}


_ERROR_LABEL_PT = {
    "conceito": "conceito",
    "interpretacao": "interpretação",
    "calculo": "cálculo",
    "distracao": "distração",
    "tempo": "tempo",
}


def remediation_for(error_type: str | None, subject: str = "", topic: str = "") -> dict[str, Any]:
    key = (error_type or "conceito").strip().lower()
    recipe = dict(REMEDIATION_RECIPES.get(key) or REMEDIATION_RECIPES["conceito"])
    recipe["errorType"] = key
    recipe["errorLabel"] = _ERROR_LABEL_PT.get(key, key)
    recipe["subject"] = subject
    recipe["topic"] = topic
    recipe["teachFocus"] = recipe.get("axisFocus") or "conceito"
    recipe["cta"] = {
        "path": (
            f"/adaptativo?subject={subject}&topic={topic}"
            if subject
            else "/adaptativo"
        ),
        "label": "Treinar remediação",
    }
    # Micro-path: teoria → adaptativo (F2 accept, sem tela nova)
    if subject and topic:
        recipe["ctaTheory"] = {
            "label": "Ler teoria",
            "subject": subject,
            "topic": topic,
        }
        recipe["ctaTutor"] = {
            "path": (
                f"/tutor?subject={subject}&topic={topic}"
                f"&errorType={key}"
                f"&q={_url_quote(f'Errei por {_ERROR_LABEL_PT.get(key, key)} em {topic}. Me ensine o ponto certo.')}"
            ),
            "label": "Pedir aula ao tutor",
        }
    return recipe


def _url_quote(s: str) -> str:
    from urllib.parse import quote

    return quote(s, safe="")


def clean_resolution_lines(resolution: str, limit: int = 3) -> list[str]:
    """Trechos de resolução sem meta técnica (ids/paths/http)."""
    clean_lines: list[str] = []
    for ln in (resolution or "").splitlines():
        t = ln.strip()
        if not t or t == "—":
            continue
        low = t.lower()
        if low.startswith("[rascunho") or "não é resolução oficial" in low:
            continue
        if t.startswith("id=") or "/data/" in t or t.startswith("http"):
            continue
        clean_lines.append(t)
        if len(clean_lines) >= limit:
            break
    return clean_lines


def build_offline_tutor_lesson(
    *,
    subject: str,
    topic: str,
    year: Any = None,
    resolution: str = "",
    statement: str = "",
    error_type: str | None = None,
    basis_oficial: bool = False,
    is_first: bool = True,
) -> list[str]:
    """
    Lição offline estruturada (HM): socrático → conceito → (diagnóstico) → verificação.
    Sem ids/paths/URLs no corpo.
    """
    bits: list[str] = []
    rem = remediation_for(error_type, subject, topic) if error_type else None
    year_bit = f" (prova {year})" if year else ""
    clean = clean_resolution_lines(resolution, limit=3)
    stmt = (statement or "").strip()
    # Socrático: pergunta do errorType ou do enunciado
    if rem and rem.get("socraticSeed"):
        ask = rem["socraticSeed"]
    elif stmt and len(stmt) > 40:
        ask = "Antes do gabarito: o que o enunciado pede de fato — qual o comando?"
    else:
        ask = f"Antes de memorizar: o que você precisa saber sobre {topic}?"
    if is_first:
        bits.append(f"Vamos estudar {subject} · {topic}{year_bit}.")
        bits.append(ask)
    else:
        bits.append(f"Outro ângulo do mesmo eixo{year_bit}:")
        bits.append(ask)
    if clean:
        bits.append("")
        bits.append("Ponto da base local:")
        bits.append(" ".join(clean))
    if rem:
        bits.append("")
        bits.append(
            f"Como o erro foi de {rem.get('errorLabel', 'conceito')}: {rem.get('diagnosis', '')}"
        )
        focus = rem.get("teachFocus") or rem.get("axisFocus")
        if focus:
            bits.append(f"Foque no eixo «{focus}» da explicação.")
        steps = rem.get("steps") or []
        if steps:
            bits.append("")
            bits.append(f"Próximo passo: {steps[0]}")
        hint = rem.get("practiceHint")
        if hint:
            bits.append(f"Depois: {hint}")
    if is_first:
        bits.append("")
        bits.append(
            rem.get("socraticSeed")
            if rem and rem.get("socraticSeed") and rem["socraticSeed"] != ask
            else "Verificação: qual distrator você eliminaria primeiro e por quê?"
        )
    if is_first and not basis_oficial:
        bits.append("")
        bits.append(
            "Aviso: a base ainda mistura treino — não inventa % de cobrança oficial."
        )
    return bits


TUTOR_SYSTEM = """
Você é o Tutor IA pessoal do PAES MED AI (UEMA/PAES — Medicina).
Responda em português do Brasil, em prosa clara para o aluno.

MISSÃO: ensinar como um professor excelente — diagnosticar a falha, explicar o ponto certo,
guiar o próximo passo. Não despeje texto; conduza o aprendizado.

REGRAS OBRIGATÓRIAS:
1. Use APENAS o contexto fornecido (edital, questões, aulas do aluno). Não invente provas, gabaritos ou estatísticas.
2. Se a informação não estiver no contexto, diga claramente: "Não há essa informação na base local."
3. Estrutura da resposta (nessa ordem):
   (a) 1 pergunta socrática OU diagnóstico curto do tipo de erro (se informado);
   (b) 2–4 frases com o conceito/comando certo, com base no contexto;
   (c) 1 próximo passo concreto (releitura, eliminação, cálculo, treino);
   (d) UMA pergunta de verificação no final.
4. Nunca entregue só o gabarito. Ensine o raciocínio.
5. Quando citar frequência ou chance de cair, diga que é ESTIMATIVA estatística, não garantia.
6. NÃO cole no texto da resposta: ids de questão (ex. bio-2017-01), paths de arquivo, URLs, nem rótulos técnicos.
   As fontes estruturadas vão no schema citations (fora do texto). No corpo, fale só de assunto/tópico/ano em linguagem natural.
7. Se o aluno informar errorType (conceito/interpretação/cálculo/distração/tempo), priorize o eixo didático correspondente
   (conceito; comando+distrator; conta/unidade; foco; ritmo) e cite a remediação em 1 passo.
""".strip()


def normalize_citation(cite: dict[str, Any]) -> dict[str, Any]:
    """Aliases F3: refType/refId espelham type/id (compat UI)."""
    out = dict(cite)
    ctype = out.get("type") or out.get("refType")
    cid = out.get("id") if out.get("id") is not None else out.get("refId")
    if ctype is not None:
        out["type"] = ctype
        out["refType"] = ctype
    if cid is not None:
        out["id"] = cid
        out["refId"] = cid
    return out


def score_questions_for_query(
    query: str,
    *,
    prefer_official: bool = False,
    coach_subject: str | None = None,
    coach_topic: str | None = None,
    natureza_bias: bool = False,
    limit: int = 12,
) -> list[dict[str, Any]]:
    """Pontua questões pela pergunta (+ boost coach / Natureza). Só ids reais do SQLite."""
    from services_core import NATUREZA_SUBJECTS, is_official_source

    tokens = {t.lower() for t in query.replace("?", " ").replace("·", " ").split() if len(t) > 2}
    conn = connect()
    try:
        questions = [dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()]
    finally:
        conn.close()

    scored: list[tuple[int, dict[str, Any]]] = []
    for q in questions:
        if prefer_official and not is_official_source(q.get("source"), q.get("generated")):
            continue
        blob = " ".join(
            [
                q.get("subject") or "",
                q.get("topic") or "",
                q.get("subtopic") or "",
                q.get("statement") or "",
                q.get("resolution") or "",
                q.get("macete") or "",
                q.get("banca_intent") or "",
            ]
        ).lower()
        score = sum(1 for t in tokens if t in blob)
        subj = (q.get("subject") or "").strip()
        topic = (q.get("topic") or "").strip()
        if coach_subject and subj.lower() == coach_subject.lower():
            score += 2
        if coach_topic and coach_topic.lower() in topic.lower():
            score += 3
        if natureza_bias and subj in NATUREZA_SUBJECTS:
            score += 2
        if score:
            scored.append((score, q))
    scored.sort(key=lambda x: -x[0])
    return [q for _, q in scored[:limit]]


def build_rag_context_with_citations(
    query: str,
    limit: int = 8,
    *,
    prefer_official: bool = False,
    coach_subject: str | None = None,
    coach_topic: str | None = None,
    natureza_bias: bool = False,
) -> tuple[str, list[dict[str, Any]]]:
    """Retorna (contexto, citações) para o tutor mostrar fontes."""
    from services_core import is_official_source

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
        if prefer_official and not is_official_source(q.get("source"), q.get("generated")):
            continue
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
        subj = (q.get("subject") or "").strip()
        topic = (q.get("topic") or "").strip()
        if coach_subject and subj.lower() == (coach_subject or "").lower():
            score += 2
        if coach_topic and (coach_topic or "").lower() in topic.lower():
            score += 3
        if natureza_bias:
            from services_core import NATUREZA_SUBJECTS

            if subj in NATUREZA_SUBJECTS:
                score += 2
        if score:
            scored_q.append((score, q))
    scored_q.sort(key=lambda x: -x[0])

    scored_s: list[tuple[int, dict[str, Any]]] = []
    for s in syllabus:
        blob = f"{s.get('subject','')} {s.get('topic','')} {s.get('subtopic') or ''}".lower()
        score = sum(1 for t in tokens if t in blob)
        if score:
            scored_s.append((score, s))
    scored_s.sort(key=lambda x: -x[0])
    syllabus_hits = [s for _, s in scored_s[:8]] or syllabus[:5]

    chunks: list[str] = []
    citations: list[dict[str, Any]] = []
    chunks.append("=== EDITAL (tópicos alinhados à pergunta) ===")
    for s in syllabus_hits:
        chunks.append(f"- {s['subject']} > {s['topic']} ({s.get('subtopic') or ''}) peso={s['weight']}")
        citations.append(
            normalize_citation(
                {
                    "type": "edital",
                    "id": s.get("id"),
                    "label": f"Edital · {s['subject']} · {s['topic']}",
                    "snippet": s["topic"],
                    "subject": s["subject"],
                    "topic": s["topic"],
                }
            )
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
            normalize_citation(
                {
                    "type": "question",
                    "id": q["id"],
                    "label": f"{q['subject']} · {q['topic']} ({q['year']})",
                    "snippet": (q["statement"] or "")[:140],
                    "score": score,
                    "subject": q["subject"],
                    "topic": q["topic"],
                    "official": is_official_source(q.get("source"), q.get("generated")),
                }
            )
        )

    if lessons:
        chunks.append("=== AULAS DO ALUNO ===")
        for lesson in lessons[:5]:
            chunks.append(
                f"{lesson['title']} | {lesson.get('subject')}/{lesson.get('topic')}\n"
                f"Resumo: {lesson.get('summary') or ''}"
            )
            citations.append(
                normalize_citation(
                    {
                        "type": "lesson",
                        "id": lesson["id"],
                        "label": lesson["title"],
                        "snippet": (lesson.get("summary") or "")[:140],
                        "subject": lesson.get("subject"),
                        "topic": lesson.get("topic"),
                    }
                )
            )

    freq = topic_frequency()[:10]
    chunks.append("=== FREQUÊNCIA (TOP) — estimativa, não garantia ===")
    for f in freq:
        chunks.append(
            f"{f['subject']}/{f['topic']}: {f['frequency']}x anos={f['years']}"
        )

    return "\n\n".join(chunks), citations[:12]


def build_rag_context(query: str, limit: int = 8) -> str:
    """Recupera trechos da base local relevantes à pergunta (RAG simples por palavras)."""
    context, _ = build_rag_context_with_citations(query, limit)
    return context


def record_answer(
    question_id: str,
    correct: bool,
    subject: str,
    topic: str,
    error_type: str | None = None,
    time_ms: int | None = None,
) -> dict[str, Any]:
    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        _ensure_study_gaps_table(conn)
        conn.execute(
            """
            INSERT INTO answers (question_id, correct, subject, topic, error_type, time_ms, answered_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (question_id, 1 if correct else 0, subject, topic, error_type, time_ms, now),
        )
        flash_info: dict[str, Any] | None = None
        gap_info: dict[str, Any] | None = None
        if not correct:
            _schedule_revision(conn, subject, topic)
            flash_info = _maybe_flashcard_from_error(conn, question_id, subject, topic)
            gap_info = _upsert_gap_on_miss(conn, subject, topic, error_type, now)
        else:
            gap_info = _progress_gap_on_correct(conn, subject, topic)
        conn.commit()
        out: dict[str, Any] = {"ok": True}
        if gap_info:
            out["gap"] = gap_info
        if not correct:
            out["remediation"] = remediation_for(error_type, subject, topic)
            if flash_info:
                out["flashcardCreated"] = flash_info.get("created") is True
                out["flashcard"] = flash_info
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


def essay_progress() -> dict[str, Any]:
    """Médias locais por eixo (5) + últimos scores — treino, não banca UEMA (Ciclo AT)."""
    essays = list_essays()
    axis_sums: dict[str, float] = {k: 0.0 for k in _ESSAY_AXES}
    axis_counts: dict[str, int] = {k: 0 for k in _ESSAY_AXES}
    last_scores: list[float] = []
    last_axis_scores: dict[str, float | None] = {k: None for k in _ESSAY_AXES}

    def _axis_val(fb: dict[str, Any], key: str, overall: float | None) -> float | None:
        v = fb.get(key)
        if isinstance(v, (int, float)):
            return float(max(0.0, min(10.0, float(v))))
        for alt in (f"{key}Score", f"{key}_score", f"{key}Rating"):
            av = fb.get(alt)
            if isinstance(av, (int, float)):
                return float(max(0.0, min(10.0, float(av))))
        if overall is not None:
            return float(max(0.0, min(10.0, overall)))
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

    # última redação = first in list (DESC created)
    if essays:
        e0 = essays[0]
        try:
            o0 = float(e0["score"]) if e0.get("score") is not None else None
        except (TypeError, ValueError):
            o0 = None
        fb0 = e0.get("feedback") if isinstance(e0.get("feedback"), dict) else {}
        for key in _ESSAY_AXES:
            last_axis_scores[key] = _axis_val(fb0, key, o0)

    averages = {
        k: (round(axis_sums[k] / axis_counts[k], 2) if axis_counts[k] else None) for k in _ESSAY_AXES
    }
    labels = {
        "grammar": "Gramática",
        "cohesion": "Coesão",
        "coherence": "Coerência",
        "argumentation": "Argumentação",
        "intervention": "Intervenção",
    }
    weakest: str | None = None
    weakest_val: float | None = None
    for k in _ESSAY_AXES:
        v = averages.get(k)
        if v is None:
            continue
        if weakest_val is None or float(v) < weakest_val:
            weakest_val = float(v)
            weakest = k
    next_mission = None
    if essays and weakest:
        lab = labels.get(weakest, weakest)
        next_mission = {
            "axis": weakest,
            "label": lab,
            "score": weakest_val,
            "prompt": (
                f"Missão: subir {lab.lower()}. Reescreva o parágrafo mais fraco e peça nova correção — "
                f"treino local, não nota de banca."
            ),
            "suggestedPersona": {
                "cohesion": "cohesion_revisor",
                "argumentation": "argument_critic",
                "coherence": "timed_reader",
            }.get(weakest),
        }

    # Streak de dias com ≥1 redação (calendário local)
    days_set: set[str] = set()
    last_essay_at = essays[0].get("createdAt") if essays else None
    for e in essays:
        ca = (e.get("createdAt") or "")[:10]
        if len(ca) == 10:
            days_set.add(ca)
    streak = 0
    if days_set:
        cursor = datetime.now().date()
        # se hoje não tem, começa de ontem (streak ainda "quente")
        if cursor.isoformat() not in days_set:
            cursor = cursor - timedelta(days=1)
        while cursor.isoformat() in days_set:
            streak += 1
            cursor = cursor - timedelta(days=1)

    return {
        "ok": True,
        "count": len(essays),
        "axes": _ESSAY_AXES,
        "labels": labels,
        "averages": averages,
        "lastAxisScores": last_axis_scores,
        "lastScores": last_scores[:12],
        "meanScore": round(sum(last_scores) / len(last_scores), 2) if last_scores else None,
        "weakestAxis": weakest,
        "nextMission": next_mission,
        "streakDays": streak,
        "lastEssayAt": last_essay_at,
        "disclaimer": "Treino local por eixos · não é nota de banca UEMA.",
        "usedOverallAsProxy": True,
    }


def essay_themes() -> list[str]:
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key='essay_themes'").fetchone()
        if row:
            return loads_json(row["value"], [])
        return []
    finally:
        conn.close()


def create_backup() -> dict[str, Any]:
    import hashlib
    import zipfile

    backup_dir = DATA_DIR / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = backup_dir / f"backup_{stamp}"
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
                shutil.rmtree(target)
            shutil.copytree(src, target, dirs_exist_ok=True)
            files_copied.append(sub)

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
    return {
        "ok": True,
        "path": zip_path,
        "folder": str(dest),
        "verify": verify,
        "note": "PDFs em provas/gabaritos/edital também estão no zip. Restore restaura o DB; pastas PDF podem ser reabertas do zip.",
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
