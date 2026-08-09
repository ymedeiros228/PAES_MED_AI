"""Flashcards, treino adaptativo e embeddings RAG."""

from __future__ import annotations

import json
import math
import os
import re
from datetime import timedelta
from typing import Any

from db import db, loads_json
from services_core import list_questions, stats_basis
from services_extra import generate_similar_question_stub
from timeutil import iso_in, now_iso
from timeutil import now as time_now

INTERVALS = [1, 3, 7, 15, 30, 60, 120]


def ensure_embeddings_table(conn) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS embeddings (
            ref_type TEXT NOT NULL,
            ref_id TEXT NOT NULL,
            model TEXT NOT NULL,
            vector_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (ref_type, ref_id)
        )
        """
    )


def list_flashcards(due_only: bool = False, axes_only: bool = False) -> list[dict[str, Any]]:
    with db() as conn:
        rows = conn.execute("SELECT * FROM flashcards ORDER BY id DESC LIMIT 300").fetchall()
        now = now_iso()
        out = []
        for r in rows:
            item = dict(r)
            src = (item.get("source") or "").strip()
            if axes_only and not src.startswith("axis:"):
                continue
            if due_only and item.get("next_due") and item["next_due"] > now:
                continue
            out.append(
                {
                    "id": item.get("id"),
                    "front": item.get("front"),
                    "back": item.get("back"),
                    "subject": item.get("subject"),
                    "topic": item.get("topic"),
                    "source": src or "manual",
                    "next_due": item.get("next_due"),
                    "reviews": item.get("reviews") or 0,
                    "fromAxes": src.startswith("axis:"),
                }
            )
        return out


def flashcard_axis_stats() -> dict[str, Any]:
    """Contagens honestas de cards de eixos (local). Sem coluna created_at: 'hoje' ≈ ainda sem review."""
    with db() as conn:
        now = now_iso()
        rows = conn.execute("SELECT source, next_due, reviews FROM flashcards").fetchall()
        axis_due = 0
        axis_new = 0
        for r in rows:
            src = (r["source"] if "source" in r.keys() else None) or ""
            if not str(src).startswith("axis:"):
                continue
            due = r["next_due"] if "next_due" in r.keys() else None
            if due is None or str(due) <= now:
                axis_due += 1
            reviews = int(r["reviews"] or 0) if "reviews" in r.keys() else 0
            if reviews == 0:
                axis_new += 1
        return {"axisCardsDue": axis_due, "axisCardsCreatedToday": axis_new}


def create_flashcard(front: str, back: str, subject: str | None, topic: str | None, source: str = "manual") -> dict[str, Any]:
    with db() as conn:
        now = time_now()
        # Cards de eixos (debrief) entram due na hora para aparecer no loop do aluno (Ciclo AK).
        if (source or "").startswith("axis:"):
            due = now.isoformat(timespec="seconds")
        else:
            due = (now + timedelta(days=1)).isoformat(timespec="seconds")
        cur = conn.execute(
            """
            INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews)
            VALUES (?, ?, ?, ?, ?, ?, 0)
            """,
            (
                front,
                back,
                subject,
                topic,
                source,
                due,
            ),
        )
        conn.commit()
        return {"id": cur.lastrowid, "front": front, "back": back, "source": source, "next_due": due}


def review_flashcard(card_id: int, remembered: bool) -> dict[str, Any]:
    with db() as conn:
        row = conn.execute("SELECT * FROM flashcards WHERE id=?", (card_id,)).fetchone()
        if not row:
            return {"ok": False, "message": "Cartão não encontrado"}
        reviews = row["reviews"] + (1 if remembered else 0)
        idx = min(reviews, len(INTERVALS) - 1) if remembered else 0
        interval = INTERVALS[idx]
        next_due = iso_in(interval)
        conn.execute(
            "UPDATE flashcards SET reviews=?, next_due=? WHERE id=?",
            (reviews if remembered else row["reviews"], next_due, card_id),
        )
        conn.commit()
        gap = None
        if remembered and row["subject"] and row["topic"]:
            try:
                from services_extra import mark_gap_card_remembered

                gap = mark_gap_card_remembered(row["subject"], row["topic"])
            except Exception:  # noqa: BLE001
                gap = None
        out = {"ok": True, "nextDue": next_due, "intervalDays": interval}
        if gap:
            out["gap"] = gap
        return out


def delete_flashcard(card_id: int) -> dict[str, Any]:
    with db() as conn:
        conn.execute("DELETE FROM flashcards WHERE id=?", (card_id,))
        conn.commit()
        return {"ok": True}


def set_plan_day_done(days: int, day_index: int, done: bool) -> dict[str, Any]:
    with db() as conn:
        conn.execute(
            "UPDATE study_plan SET done=? WHERE plan_days=? AND day_index=?",
            (1 if done else 0, days, day_index),
        )
        conn.commit()
        return {"ok": True, "days": days, "day": day_index, "done": done}


def adaptive_training(subject: str, topic: str, n_similar: int = 10, n_harder: int = 20, n_generated: int = 0) -> dict[str, Any]:
    """Treino adaptativo. n_generated default 0 (Ciclo G/H) — stubs só se pedido."""
    official_first = stats_basis()["officialCount"] >= 10
    # Soft priority: if this topic has recent misses, pull a few more similar
    dominant_error: str | None = None
    boosted = False
    try:
        from services_core import dashboard_stats

        dash = dashboard_stats()
        hot = {item["key"] for item in dash.get("errorHotTopics", [])}
        if f"{subject}::{topic}" in hot:
            n_similar = min(n_similar + 3, 15)
            boosted = True
        # Dominant error type for this topic (recent wrong answers)
        with db() as conn:
            rows = conn.execute(
                """
                SELECT error_type FROM answers
                WHERE subject=? AND topic=? AND correct=0 AND error_type IS NOT NULL
                ORDER BY answered_at DESC LIMIT 20
                """,
                (subject, topic),
            ).fetchall()
        if rows:
            from collections import Counter

            dominant_error = Counter(r["error_type"] for r in rows).most_common(1)[0][0]
            if dominant_error in ("conceito", "interpretacao"):
                n_similar = min(n_similar + 2, 15)
            elif dominant_error == "calculo":
                n_harder = min(n_harder + 2, 22)
    except Exception:
        pass
    same = list_questions(subject=subject, topic=topic, source_kind="oficial" if official_first else None)
    if official_first and not same:
        same = list_questions(subject=subject, topic=topic)
    similar = [q for q in same if q.get("difficulty") in ("Fácil", "Média")][:n_similar]
    if len(similar) < n_similar:
        similar = same[:n_similar]

    harder = [q for q in same if q.get("difficulty") == "Difícil"]
    if len(harder) < n_harder:
        # completar com outras difíceis da mesma disciplina
        all_subj = list_questions(subject=subject, source_kind="oficial" if official_first else None)
        if official_first and not all_subj:
            all_subj = list_questions(subject=subject)
        harder = (harder + [q for q in all_subj if q.get("difficulty") == "Difícil" and q["id"] not in {x["id"] for x in harder}])[
            :n_harder
        ]

    generated = []
    for _ in range(n_generated):
        generated.append(generate_similar_question_stub(topic, subject))

    return {
        "subject": subject,
        "topic": topic,
        "similar": similar,
        "harder": harder,
        "generated": generated,
        "preferOfficial": official_first,
        "boostedByErrors": boosted,
        "dominantErrorType": dominant_error,
        "note": "Inéditas marcadas generated=true — revise antes de simulado sério.",
        "counts": {"similar": len(similar), "harder": len(harder), "generated": len(generated)},
    }


def _tokenize(text: str) -> list[str]:
    return [t for t in re.findall(r"[a-zA-ZÀ-ÿ0-9]{3,}", text.lower())]


def local_embedding(text: str, dim: int = 64) -> list[float]:
    """Embedding offline determinístico (hashing trick) — fallback sem OpenAI."""
    vec = [0.0] * dim
    for tok in _tokenize(text):
        h = hash(tok) % dim
        vec[h] += 1.0
    norm = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [v / norm for v in vec]


def openai_embedding(text: str) -> list[float] | None:
    key = os.getenv("OPENAI_API_KEY", "").strip()
    if not key or key == "cole_sua_chave_aqui":
        return None
    try:
        from openai import OpenAI

        client = OpenAI(api_key=key)
        resp = client.embeddings.create(model="text-embedding-3-small", input=text[:8000])
        return list(resp.data[0].embedding)
    except Exception:
        return None


def cosine(a: list[float], b: list[float]) -> float:
    n = min(len(a), len(b))
    if n == 0:
        return 0.0
    a = a[:n]
    b = b[:n]
    dot = sum(x * y for x, y in zip(a, b, strict=True))
    na = math.sqrt(sum(x * x for x in a)) or 1.0
    nb = math.sqrt(sum(x * x for x in b)) or 1.0
    return dot / (na * nb)


def upsert_embedding(ref_type: str, ref_id: str, text: str) -> str:
    vec = openai_embedding(text)
    model = "text-embedding-3-small" if vec else "local-hash-64"
    if vec is None:
        vec = local_embedding(text)
    with db() as conn:
        ensure_embeddings_table(conn)
        conn.execute(
            """
            INSERT INTO embeddings (ref_type, ref_id, model, vector_json, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(ref_type, ref_id) DO UPDATE SET
              model=excluded.model,
              vector_json=excluded.vector_json,
              updated_at=excluded.updated_at
            """,
            (ref_type, ref_id, model, json.dumps(vec), now_iso()),
        )
        conn.commit()
        return model


def index_all_questions(limit: int = 500) -> dict[str, Any]:
    from services_core import is_official_source, stats_basis

    with db() as conn:
        rows = conn.execute(
            "SELECT id, subject, topic, statement, resolution, macete, source, generated FROM questions LIMIT ?",
            (limit,),
        ).fetchall()
        syllabus = [dict(r) for r in conn.execute("SELECT subject, topic, subtopic, weight FROM syllabus").fetchall()]
    n = 0
    model = "local"
    prefer_official = stats_basis()["officialCount"] >= 10
    for r in rows:
        if prefer_official and not is_official_source(r["source"], r["generated"]):
            continue
        blob = f"{r['subject']} {r['topic']} {r['statement']} {r['resolution'] or ''} {r['macete'] or ''}"
        model = upsert_embedding("question", r["id"], blob)
        n += 1
    # Index edital/syllabus as dedicated chunks
    edital_n = 0
    for i, s in enumerate(syllabus[:200]):
        blob = f"EDITAL {s['subject']} {s['topic']} {s.get('subtopic') or ''} peso={s.get('weight')}"
        upsert_embedding("edital", f"syl-{i}-{s['subject'][:12]}-{s['topic'][:20]}", blob)
        edital_n += 1
    return {"indexed": n, "editalChunks": edital_n, "model": model, "preferOfficial": prefer_official}


def build_rag_context_embedded(query: str, limit: int = 8) -> tuple[str, str]:
    """Retorna (contexto, modo: embedded|keyword)."""
    context, mode, _ = build_rag_context_embedded_full(query, limit)
    return context, mode


def build_rag_context_embedded_full(query: str, limit: int = 8) -> tuple[str, str, list[dict[str, Any]]]:
    """Retorna (contexto, modo, citações)."""
    from services_core import is_official_source, stats_basis
    from services_extra import build_rag_context_with_citations, prioritize_rag_citations

    basis = stats_basis()
    prefer_official = basis["officialCount"] >= 10
    qvec = openai_embedding(query) or local_embedding(query)
    with db() as conn:
        ensure_embeddings_table(conn)
        emb_rows = conn.execute("SELECT * FROM embeddings WHERE ref_type IN ('question','edital')").fetchall()
        questions = {r["id"]: dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()}
        syllabus = [dict(r) for r in conn.execute("SELECT * FROM syllabus").fetchall()]
        lessons = [dict(r) for r in conn.execute("SELECT * FROM lessons ORDER BY created_at DESC LIMIT 10").fetchall()]

    if not emb_rows:
        index_all_questions(200)
        with db() as conn:
            emb_rows = conn.execute("SELECT * FROM embeddings WHERE ref_type IN ('question','edital')").fetchall()
            questions = {r["id"]: dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()}

    scored: list[tuple[float, str, str]] = []
    for e in emb_rows:
        vec = loads_json(e["vector_json"], [])
        if not vec:
            continue
        if abs(len(vec) - len(qvec)) > 8:
            continue
        scored.append((cosine(qvec, vec), e["ref_type"], e["ref_id"]))
    scored.sort(key=lambda x: -x[0])

    if not scored:
        ctx, cites = build_rag_context_with_citations(query, limit)
        disclaimer = (
            ""
            if prefer_official
            else "\n\n[AVISO] Base ainda em treino — citações não são oficiais PAES."
        )
        return ctx + disclaimer, "keyword", cites

    mode = "embedded"
    chunks: list[str] = ["=== EDITAL ==="]
    if not prefer_official:
        chunks.insert(0, "[AVISO] officialCount < 10 — RAG pode citar treino. Não invente incidência oficial.")
    citations: list[dict[str, Any]] = []
    for s in syllabus[:25]:
        chunks.append(f"- {s['subject']} > {s['topic']} peso={s['weight']}")
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

    chunks.append("=== QUESTÕES (top similaridade) ===")
    used = 0
    for score, ref_type, qid in scored:
        if ref_type != "question":
            continue
        q = questions.get(qid)
        if not q:
            continue
        if prefer_official and not is_official_source(q.get("source"), q.get("generated")):
            continue
        chunks.append(
            f"[sim={score:.3f}] [{q['year']}] {q['subject']}/{q['topic']} id={q['id']}\n"
            f"{q['statement']}\nResolução: {q.get('resolution') or 'n/d'}\nMacete: {q.get('macete') or 'n/d'}"
        )
        citations.append(
            {
                "type": "question",
                "id": q["id"],
                "label": f"{q['subject']} · {q['topic']} ({q['year']})",
                "snippet": (q["statement"] or "")[:140],
                "score": round(float(score), 3),
                "official": is_official_source(q.get("source"), q.get("generated")),
                "subject": q["subject"],
                "topic": q["topic"],
            }
        )
        used += 1
        if used >= limit:
            break

    if lessons:
        chunks.append("=== AULAS ===")
        for lesson in lessons[:3]:
            chunks.append(f"{lesson['title']}: {lesson.get('summary') or ''}")
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

    return "\n\n".join(chunks), mode, prioritize_rag_citations(citations, limit)
