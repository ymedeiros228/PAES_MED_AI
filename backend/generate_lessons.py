"""Gerador de aulas estruturadas com IA para tópicos do edital.

Gera aulas com resumo, macetes, keywords, flashcards e questões exemplo
para cada tópico do syllabus, usando Gemini/Groq como provedor.
"""

from __future__ import annotations

import json
import re
import time
import uuid
from typing import Any

from db import db
from timeutil import now_iso


def _ask_ai(instructions: str, content: str) -> str:
    """Chama o provedor de IA configurado (Gemini primeiro, Groq fallback)."""
    from api_helpers import _ask_gemini, _ask_groq
    from ai_state import provider_configured

    if provider_configured("gemini"):
        try:
            return _ask_gemini(instructions, content)
        except Exception:
            pass
    if provider_configured("groq"):
        try:
            return _ask_groq(instructions, content)
        except Exception:
            pass
    if provider_configured("openrouter"):
        try:
            from api_helpers import _ask_openrouter
            return _ask_openrouter(instructions, content)
        except Exception:
            pass
    raise RuntimeError("Nenhum provedor de IA disponível.")


_LESSON_PROMPT = """Você é professor especialista do PAES/UEMA. Crie uma aula estruturada sobre o tópico abaixo.

Disciplina: {subject}
Tópico: {topic}
Subtopic: {subtopic}

Responda EM PORTUGUÊS BRASILEIRO no formato JSON abaixo (sem markdown, sem blocos de código):
{{
  "summary": "resumo didático em 5-8 linhas explicando o conceito principal",
  "macetes": ["macete 1 prático", "macete 2 de memorização", "macete 3 de prova"],
  "keywords": ["palavra-chave 1", "palavra-chave 2", "palavra-chave 3", "palavra-chave 4", "palavra-chave 5"],
  "flashcards": [
    {{"front": "pergunta direta sobre o conceito", "back": "resposta clara e objetiva"}},
    {{"front": "outra pergunta", "back": "outra resposta"}},
    {{"front": "terceira pergunta", "back": "terceira resposta"}}
  ],
  "questions": [
    {{"q": "pergunta exemplo no estilo PAES", "a": "resposta comentada"}}
  ]
}

Seja didático, direto e focado no que cai na prova PAES/UEMA."""


def _parse_lesson_response(text: str) -> dict[str, Any]:
    """Extrai JSON da resposta da IA (pode vir com markdown ou texto extra)."""
    text = text.strip()
    # Remove markdown code blocks se houver
    text = re.sub(r"^```(?:json)?\s*", "", text)
    text = re.sub(r"\s*```$", "", text)
    text = text.strip()
    # Tenta parsear como JSON diretamente
    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return _normalize_lesson_data(data)
    except json.JSONDecodeError:
        pass
    # Tenta encontrar o primeiro { e último } e parsear
    first_brace = text.find("{")
    last_brace = text.rfind("}")
    if first_brace >= 0 and last_brace > first_brace:
        candidate = text[first_brace : last_brace + 1]
        try:
            data = json.loads(candidate)
            if isinstance(data, dict):
                return _normalize_lesson_data(data)
        except json.JSONDecodeError:
            pass
    # Fallback: estruturar manualmente a partir do texto
    return {
        "summary": text[:500],
        "macetes": [],
        "keywords": [],
        "flashcards": [],
        "questions": [],
    }


def _normalize_lesson_data(data: dict[str, Any]) -> dict[str, Any]:
    """Normaliza os dados da aula garantindo campos válidos."""
    summary = str(data.get("summary") or "").strip()
    macetes = data.get("macetes") or []
    if not isinstance(macetes, list):
        macetes = []
    macetes = [str(m) for m in macetes if m]
    keywords = data.get("keywords") or []
    if not isinstance(keywords, list):
        keywords = []
    keywords = [str(k) for k in keywords if k]
    flashcards = data.get("flashcards") or []
    if not isinstance(flashcards, list):
        flashcards = []
    clean_flashcards = []
    for fc in flashcards:
        if isinstance(fc, dict):
            clean_flashcards.append({
                "front": str(fc.get("front") or ""),
                "back": str(fc.get("back") or ""),
            })
    questions = data.get("questions") or []
    if not isinstance(questions, list):
        questions = []
    clean_questions = []
    for q in questions:
        if isinstance(q, dict):
            clean_questions.append({
                "q": str(q.get("q") or ""),
                "a": str(q.get("a") or ""),
            })
    return {
        "summary": summary,
        "macetes": macetes,
        "keywords": keywords,
        "flashcards": clean_flashcards,
        "questions": clean_questions,
    }


def generate_lessons(
    *,
    limit: int = 10,
    offset: int = 0,
    delay_seconds: float = 3.0,
    replace_existing: bool = True,
) -> dict[str, Any]:
    """Gera aulas com IA para tópicos do syllabus.

    Args:
        limit: Máximo de tópicos a processar.
        offset: Pular primeiros N tópicos.
        delay_seconds: Pausa entre requisições.
        replace_existing: Se True, deleta lessons antigas (template) antes de gerar.
    """
    with db() as conn:
        syllabus = conn.execute(
            "SELECT id, subject, topic, subtopic FROM syllabus ORDER BY subject, topic"
        ).fetchall()

    total_topics = len(syllabus)
    batch = syllabus[offset : offset + limit]

    generated = 0
    failed = 0
    errors: list[str] = []

    for i, s in enumerate(batch):
        try:
            prompt = _LESSON_PROMPT.replace("{subject}", s["subject"]).replace("{topic}", s["topic"]).replace("{subtopic}", s["subtopic"] if s["subtopic"] else "—")
            instructions = "Você é professor do PAES/UEMA. Produza uma aula estruturada em JSON."
            raw = _ask_ai(instructions, prompt)
            data = _parse_lesson_response(raw)

            lesson_id = str(uuid.uuid4())
            now = now_iso()
            title = f"{s['subject']} · {s['topic']}"

            with db() as conn:
                if replace_existing:
                    conn.execute(
                        "DELETE FROM lessons WHERE subject=? AND topic=? AND source_type='legenda'",
                        (s["subject"], s["topic"]),
                    )
                conn.execute(
                    """
                    INSERT INTO lessons (
                        id, title, source_type, source_ref, transcript, subject, topic,
                        difficulty, summary, macetes_json, keywords_json, flashcards_json,
                        questions_json, incidence_note, created_at
                    ) VALUES (?, ?, 'ia_gerada', ?, ?, ?, ?, 'Média', ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        lesson_id,
                        title,
                        s["subtopic"] if s["subtopic"] else "",
                        data.get("summary", ""),
                        s["subject"],
                        s["topic"],
                        data.get("summary", ""),
                        json.dumps(data.get("macetes", []), ensure_ascii=False),
                        json.dumps(data.get("keywords", []), ensure_ascii=False),
                        json.dumps(data.get("flashcards", []), ensure_ascii=False),
                        json.dumps(data.get("questions", []), ensure_ascii=False),
                        f"Aula gerada por IA sobre {s['topic']}.",
                        now,
                    ),
                )
                conn.commit()
            generated += 1
        except Exception as exc:
            failed += 1
            errors.append(f"{s['subject']}/{s['topic']}: {exc}")
        # Rate limiting
        if i < len(batch) - 1:
            time.sleep(delay_seconds)

    return {
        "ok": True,
        "totalTopics": total_topics,
        "processed": len(batch),
        "generated": generated,
        "failed": failed,
        "errors": errors[:10],
        "message": (
            f"{generated} aulas geradas com IA"
            + (f" · {failed} falharam" if failed else "")
            + f" · {total_topics - generated - failed} tópicos restantes"
        ),
    }


def lesson_stats() -> dict[str, Any]:
    """Estatísticas das aulas."""
    with db() as conn:
        total = conn.execute("SELECT COUNT(*) FROM lessons").fetchone()[0]
        ia = conn.execute("SELECT COUNT(*) FROM lessons WHERE source_type='ia_gerada'").fetchone()[0]
        template = conn.execute("SELECT COUNT(*) FROM lessons WHERE source_type='legenda'").fetchone()[0]
        syllabus_count = conn.execute("SELECT COUNT(*) FROM syllabus").fetchone()[0]
    return {
        "total": total,
        "iaGerada": ia,
        "template": template,
        "syllabusTopics": syllabus_count,
        "message": (
            f"{ia} aulas geradas por IA · "
            f"{template} templates · "
            f"{syllabus_count} tópicos no edital"
        ),
    }


if __name__ == "__main__":
    result = generate_lessons(limit=3, delay_seconds=3.0)
    print(json.dumps(result, indent=2, ensure_ascii=False))
