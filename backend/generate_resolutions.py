"""Gerador de resoluções didáticas com IA para questões do banco.

Gera resoluções estruturadas em 4 eixos (Comando, Conceito, Gabarito, Distrator)
usando Gemini/Groq como provedor de IA.
"""

from __future__ import annotations

import json
import re
import time
from typing import Any

from db import db
from services_core import resolution_quality


def _ask_ai(instructions: str, content: str) -> str:
    """Chama o provedor de IA configurado (Gemini primeiro, Groq fallback)."""
    from ai_state import provider_configured
    from api_helpers import _ask_gemini, _ask_groq

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


_RESOLUTION_PROMPT = """Você é professor especialista do PAES/UEMA. Crie uma resolução didática para a questão abaixo.

Disciplina: {subject}
Tópico: {topic}
Enunciado: {statement}
Alternativas:
{options_list}
Gabarito: {correct_letter}) {correct_text}

Formate sua resposta EXATAMENTE assim (4 blocos numerados):
1) Comando: [em 1-2 linhas, o que a banca pede ao candidato]
2) Conceito: [em 2-3 linhas, a teoria necessária para resolver]
3) Gabarito: [qual alternativa correta e por quê, em 2-3 linhas]
4) Distrator: [como eliminar as alternativas erradas, em 2-3 linhas]

Seja direto e didático. Use português brasileiro."""


def _build_prompt(question: dict[str, Any]) -> str:
    opts = question.get("options") or []
    options_list = "\n".join(
        f"{chr(65 + i)}) {o}" for i, o in enumerate(opts[:5])
    )
    ci = int(question.get("correctIndex") or 0)
    correct_letter = chr(65 + ci) if 0 <= ci < len(opts) else "?"
    correct_text = opts[ci] if 0 <= ci < len(opts) else ""
    return _RESOLUTION_PROMPT.format(
        subject=question.get("subject", "Geral"),
        topic=question.get("topic", "Geral"),
        statement=question.get("statement", ""),
        options_list=options_list,
        correct_letter=correct_letter,
        correct_text=correct_text[:200],
    )


def _parse_resolution(text: str) -> str:
    """Garante que a resolução tem os 4 eixos numerados."""
    text = text.strip()
    # Se já tem os 4 eixos, retorna como está
    has_all = all(f"{i})" in text for i in range(1, 5))
    if has_all:
        return text
    # Tenta extrair eixos por labels
    axes = {"Comando": "", "Conceito": "", "Gabarito": "", "Distrator": ""}
    for key in axes:
        pat = re.compile(rf"(?im)(?:\d+\)?\s*)?{key}\s*[:\-–]\s*(.+?)(?=\d+\)?\s*(?:Comando|Conceito|Gabarito|Distrator)|$)", re.DOTALL)
        m = pat.search(text)
        if m:
            axes[key] = m.group(1).strip()
    result = f"1) Comando: {axes['Comando']}\n2) Conceito: {axes['Conceito']}\n3) Gabarito: {axes['Gabarito']}\n4) Distrator: {axes['Distrator']}"
    return result


def generate_resolutions(
    *,
    limit: int = 20,
    offset: int = 0,
    delay_seconds: float = 2.0,
) -> dict[str, Any]:
    """Gera resoluções com IA para questões com resolução template.

    Args:
        limit: Máximo de questões a processar.
        offset: Pular primeiras N questões template.
        delay_seconds: Pausa entre requisições (rate limiting).
    """
    with db() as conn:
        rows = conn.execute(
            """
            SELECT id, year, subject, topic, statement, options_json, correct_index
            FROM questions
            ORDER BY year DESC, id
            """,
        ).fetchall()

    # Filtrar só questões com resolução template
    template_questions = []
    for r in rows:
        r["statement"]  # placeholder
        # Buscar resolução real
        with db() as conn:
            row = conn.execute(
                "SELECT resolution FROM questions WHERE id=?", (r["id"],)
            ).fetchone()
        resolution = row["resolution"] if row else ""
        if resolution_quality(resolution) == "template":
            opts = json.loads(r["options_json"]) if r["options_json"] else []
            template_questions.append({
                "id": r["id"],
                "year": r["year"],
                "subject": r["subject"],
                "topic": r["topic"],
                "statement": r["statement"],
                "options": opts,
                "correctIndex": int(r["correct_index"] or 0),
            })

    total_templates = len(template_questions)
    batch = template_questions[offset : offset + limit]

    generated = 0
    failed = 0
    errors: list[str] = []

    for i, q in enumerate(batch):
        try:
            prompt = _build_prompt(q)
            instructions = "Você é professor do PAES/UEMA. Produza uma resolução didática estruturada em 4 eixos."
            raw = _ask_ai(instructions, prompt)
            resolution = _parse_resolution(raw)
            with db() as conn:
                conn.execute(
                    "UPDATE questions SET resolution=? WHERE id=?",
                    (resolution, q["id"]),
                )
                conn.commit()
            generated += 1
        except Exception as exc:
            failed += 1
            errors.append(f"{q['id']}: {exc}")
        # Rate limiting
        if i < len(batch) - 1:
            time.sleep(delay_seconds)

    return {
        "ok": True,
        "totalTemplates": total_templates,
        "processed": len(batch),
        "generated": generated,
        "failed": failed,
        "errors": errors[:10],
        "message": (
            f"{generated} resoluções geradas com IA"
            + (f" · {failed} falharam" if failed else "")
            + f" · {total_templates - generated - failed} restantes"
        ),
    }


def resolution_stats() -> dict[str, Any]:
    """Estatísticas de qualidade das resoluções."""
    with db() as conn:
        rows = conn.execute("SELECT resolution FROM questions").fetchall()
    total = len(rows)
    by_quality = {"template": 0, "draft": 0, "real": 0}
    for r in rows:
        q = resolution_quality(r["resolution"])
        by_quality[q] = by_quality.get(q, 0) + 1
    return {
        "total": total,
        "template": by_quality["template"],
        "draft": by_quality["draft"],
        "real": by_quality["real"],
        "message": (
            f"{by_quality['real']} resoluções reais · "
            f"{by_quality['draft']} rascunhos · "
            f"{by_quality['template']} templates restantes"
        ),
    }


_RESOLUTION_PROMPT_NO_GAB = """Você é professor especialista do PAES/UEMA. Crie uma resolução didática para a questão abaixo.

Disciplina: {subject}
Tópico: {topic}
Enunciado: {statement}
Alternativas:
{options_list}
Gabarito provável: {correct_letter}) {correct_text}

NOTA: Esta questão foi importada sem gabarito oficial. O gabarito acima é uma estimativa automática e pode estar incorreto. Analise o enunciado e as alternativas, identifique a resposta correta com base no conteúdo, e explique o raciocínio.

Formate sua resposta EXATAMENTE assim (4 blocos numerados):
1) Comando: [em 1-2 linhas, o que a banca pede ao candidato]
2) Conceito: [em 2-3 linhas, a teoria necessária para resolver]
3) Gabarito: [qual alternativa correta e por quê, em 2-3 linhas. Se o gabarito provável estiver errado, indique o correto.]
4) Distrator: [como eliminar as alternativas erradas, em 2-3 linhas]

Seja direto e didático. Use português brasileiro."""


def generate_resolutions_for_new_questions(
    *,
    limit: int = 250,
    delay_seconds: float = 3.0,
) -> dict[str, Any]:
    """Gera resoluções IA para as 232 questões importadas sem gabarito oficial."""
    with db() as conn:
        rows = conn.execute(
            "SELECT id, year, subject, topic, statement, options_json, correct_index "
            "FROM questions WHERE source LIKE '%pdf_ingest_sem_gabarito%' "
            "ORDER BY year, id"
        ).fetchall()

    questions = []
    for r in rows:
        opts = json.loads(r["options_json"]) if r["options_json"] else []
        questions.append({
            "id": r["id"],
            "year": r["year"],
            "subject": r["subject"],
            "topic": r["topic"],
            "statement": r["statement"],
            "options": opts,
            "correctIndex": int(r["correct_index"] or 0),
        })

    total = len(questions)
    batch = questions[:limit]
    generated = 0
    failed = 0
    errors: list[str] = []

    for i, q in enumerate(batch):
        try:
            opts = q.get("options") or []
            options_list = "\n".join(
                f"{chr(65 + j)}) {o}" for j, o in enumerate(opts[:5])
            )
            ci = int(q.get("correctIndex") or 0)
            correct_letter = chr(65 + ci) if 0 <= ci < len(opts) else "?"
            correct_text = opts[ci] if 0 <= ci < len(opts) else ""
            prompt = _RESOLUTION_PROMPT_NO_GAB.format(
                subject=q.get("subject", "Geral"),
                topic=q.get("topic", "Geral"),
                statement=q.get("statement", ""),
                options_list=options_list,
                correct_letter=correct_letter,
                correct_text=correct_text[:200],
            )
            instructions = "Você é professor do PAES/UEMA. Produza uma resolução didática estruturada em 4 eixos."
            raw = _ask_ai(instructions, prompt)
            resolution = _parse_resolution(raw)
            with db() as conn:
                conn.execute(
                    "UPDATE questions SET resolution=? WHERE id=?",
                    (resolution, q["id"]),
                )
                conn.commit()
            generated += 1
            if generated % 10 == 0:
                print(f"Progresso: {generated}/{len(batch)} resoluções geradas")
        except Exception as exc:
            failed += 1
            errors.append(f"{q['id']}: {exc}")
        if i < len(batch) - 1:
            time.sleep(delay_seconds)

    return {
        "ok": True,
        "totalNewQuestions": total,
        "processed": len(batch),
        "generated": generated,
        "failed": failed,
        "errors": errors[:10],
        "message": (
            f"{generated} resoluções geradas com IA para questões sem gabarito"
            + (f" · {failed} falharam" if failed else "")
            + f" · {total - generated - failed} restantes"
        ),
    }


if __name__ == "__main__":
    result = generate_resolutions_for_new_questions(limit=250, delay_seconds=3.0)
    print(json.dumps(result, indent=2, ensure_ascii=False))
