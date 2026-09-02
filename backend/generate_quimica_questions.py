"""Gera questões inéditas de Química com IA para o banco PAES MED AI.

Cobre tópicos sub-representados:
- Soluções
- Termoquímica
- Cinética e Equilíbrio
- Eletroquímica
- Ligações Químicas
- Teoria Atômica
- Gases
- Funções Inorgânicas
- Classificação Periódica
- Transformações Químicas
- Princípios Elementares

Também gera questões para completar 2019 (só tem 7).
"""

from __future__ import annotations

import io
import json
import sys
import time
import uuid
from typing import Any

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))

from db import db, init_db

init_db()

# ---------------------------------------------------------------------------
# Helper: chamar IA
# ---------------------------------------------------------------------------

def _ask_ai(instructions: str, content: str) -> str:
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


# ---------------------------------------------------------------------------
# Prompt para gerar questão
# ---------------------------------------------------------------------------

_QUESTION_PROMPT = """Você é professora especialista em Química do PAES/UEMA. Crie uma questão inédita de alta qualidade no estilo da banca.

Disciplina: Química
Tópico: {topic}
Ano: {year}
Nível: {difficulty}

Requisitos:
- Enunciado claro e contextualizado (3-6 linhas)
- 5 alternativas (A-E)
- Uma alternativa claramente correta
- Distratores plausíveis (erros comuns de aluno)
- Resolução estruturada em 4 eixos
- Em português brasileiro com acentuação correta

Responda EM JSON válido com esta estrutura exata:
{{
  "statement": "enunciado da questão",
  "options": ["alt A", "alt B", "alt C", "alt D", "alt E"],
  "correct_index": 0,
  "resolution": "1) Comando: ...\\n2) Conceito: ...\\n3) Gabarito: ...\\n4) Distrator: ...",
  "banca_intent": "o que a banca quer avaliar",
  "macete": "dica rápida",
  "pegadinha": "pegadinha comum"
}}

O correct_index é 0-4 (0=A, 1=B, etc). Gere UMA questão apenas."""


# ---------------------------------------------------------------------------
# Tópicos a gerar
# ---------------------------------------------------------------------------

QUIMICA_TOPICS = [
    ("Soluções", 2024, "Média"),
    ("Soluções", 2025, "Média"),
    ("Soluções", 2022, "Média"),
    ("Soluções", 2023, "Difícil"),
    ("Termoquímica", 2024, "Média"),
    ("Termoquímica", 2025, "Média"),
    ("Termoquímica", 2022, "Difícil"),
    ("Termoquímica", 2023, "Média"),
    ("Cinética e Equilíbrio", 2024, "Média"),
    ("Cinética e Equilíbrio", 2025, "Difícil"),
    ("Cinética e Equilíbrio", 2022, "Média"),
    ("Eletroquímica", 2024, "Média"),
    ("Eletroquímica", 2025, "Difícil"),
    ("Eletroquímica", 2022, "Média"),
    ("Eletroquímica", 2023, "Média"),
    ("Ligações Químicas", 2024, "Fácil"),
    ("Ligações Químicas", 2025, "Média"),
    ("Ligações Químicas", 2022, "Média"),
    ("Teoria Atômica", 2024, "Fácil"),
    ("Teoria Atômica", 2025, "Média"),
    ("Teoria Atômica", 2022, "Média"),
    ("Gases", 2024, "Média"),
    ("Gases", 2025, "Média"),
    ("Gases", 2022, "Difícil"),
    ("Funções Inorgânicas", 2024, "Fácil"),
    ("Funções Inorgânicas", 2025, "Média"),
    ("Funções Inorgânicas", 2022, "Média"),
    ("Classificação Periódica", 2024, "Fácil"),
    ("Classificação Periódica", 2025, "Média"),
    ("Transformações Químicas", 2024, "Média"),
    ("Transformações Químicas", 2025, "Média"),
    ("Princípios Elementares", 2024, "Fácil"),
    ("Química Orgânica", 2024, "Média"),
    ("Química Orgânica", 2025, "Difícil"),
    ("Química Orgânica", 2022, "Média"),
    ("Estequiometria", 2024, "Difícil"),
    ("Estequiometria", 2025, "Difícil"),
    ("Estequiometria", 2022, "Média"),
]

# 2019 — completar com questões de várias disciplinas
TOPICS_2019 = [
    ("Biologia", "Genética", 2019, "Média"),
    ("Biologia", "Citologia", 2019, "Média"),
    ("Biologia", "Ecologia", 2019, "Fácil"),
    ("Biologia", "Fisiologia humana", 2019, "Média"),
    ("Biologia", "Evolução", 2019, "Média"),
    ("Química", "Estequiometria", 2019, "Média"),
    ("Química", "Soluções", 2019, "Média"),
    ("Química", "Química Orgânica", 2019, "Média"),
    ("Química", "Eletroquímica", 2019, "Difícil"),
    ("Física", "Cinemática", 2019, "Fácil"),
    ("Física", "Dinâmica", 2019, "Média"),
    ("Física", "Eletromagnetismo", 2019, "Média"),
    ("Física", "Hidrostática", 2019, "Média"),
    ("Matemática", "Funções", 2019, "Média"),
    ("Matemática", "Geometria Plana", 2019, "Fácil"),
    ("Matemática", "Trigonometria", 2019, "Média"),
    ("Matemática", "Análise Combinatória", 2019, "Difícil"),
    ("História", "Brasil Contemporâneo", 2019, "Média"),
    ("História", "Idade Contemporânea", 2019, "Média"),
    ("História", "Maranhão", 2019, "Fácil"),
    ("Geografia", "Geografia Física", 2019, "Média"),
    ("Geografia", "Maranhão", 2019, "Fácil"),
    ("Filosofia", "Ética", 2019, "Média"),
    ("Filosofia", "Política", 2019, "Média"),
    ("Sociologia", "Cultura e Ideologia", 2019, "Média"),
    ("Sociologia", "Perspectivas Clássicas", 2019, "Média"),
    ("Língua Portuguesa e Literatura", "Interpretação", 2019, "Média"),
    ("Língua Portuguesa e Literatura", "Literatura", 2019, "Média"),
]


# ---------------------------------------------------------------------------
# Prompt genérico para outras disciplinas (2019)
# ---------------------------------------------------------------------------

_GENERIC_PROMPT = """Você é professor especialista do PAES/UEMA. Crie uma questão inédita de alta qualidade no estilo da banca.

Disciplina: {subject}
Tópico: {topic}
Ano: {year}
Nível: {difficulty}

Requisitos:
- Enunciado claro e contextualizado (3-6 linhas)
- 5 alternativas (A-E)
- Uma alternativa claramente correta
- Distratores plausíveis (erros comuns de aluno)
- Resolução estruturada em 4 eixos
- Em português brasileiro com acentuação correta

Responda EM JSON válido com esta estrutura exata:
{{
  "statement": "enunciado da questão",
  "options": ["alt A", "alt B", "alt C", "alt D", "alt E"],
  "correct_index": 0,
  "resolution": "1) Comando: ...\\n2) Conceito: ...\\n3) Gabarito: ...\\n4) Distrator: ...",
  "banca_intent": "o que a banca quer avaliar",
  "macete": "dica rápida",
  "pegadinha": "pegadinha comum"
}}

O correct_index é 0-4 (0=A, 1=B, etc). Gere UMA questão apenas."""


def _parse_json_response(text: str) -> dict[str, Any] | None:
    """Tenta extrair JSON da resposta da IA."""
    text = text.strip()
    # Remove markdown code blocks
    if text.startswith("```"):
        lines = text.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        text = "\n".join(lines)
    # Tenta parsear
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Tenta encontrar JSON entre chaves
        start = text.find("{")
        end = text.rfind("}") + 1
        if start >= 0 and end > start:
            try:
                return json.loads(text[start:end])
            except json.JSONDecodeError:
                pass
    return None


def _insert_question(q: dict[str, Any], subject: str, topic: str, year: int, difficulty: str) -> str:
    """Insere questão no banco e retorna o ID."""
    qid = f"gen-{uuid.uuid4().hex[:8]}"
    statement = q.get("statement", "")
    options = q.get("options", [])
    correct_index = int(q.get("correct_index", 0))
    resolution = q.get("resolution", "")
    banca_intent = q.get("banca_intent", "")
    macete = q.get("macete", "")
    pegadinha = q.get("pegadinha", "")

    if not statement or len(options) != 5:
        raise ValueError(f"Questão inválida: statement={bool(statement)}, options={len(options)}")

    with db() as conn:
        conn.execute(
            """
            INSERT INTO questions (
                id, year, subject, topic, statement, options_json, correct_index, difficulty,
                source, resolution, banca_intent, macete, pegadinha, generated, approved, avg_text_len
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'gerada_ia_paes', ?, ?, ?, ?, 1, 0, ?)
            """,
            (
                qid,
                year,
                subject,
                topic,
                statement,
                json.dumps(options, ensure_ascii=False),
                correct_index,
                difficulty,
                resolution,
                banca_intent,
                macete,
                pegadinha,
                len(statement),
            ),
        )
        conn.commit()
    return qid


def generate_batch(
    items: list[tuple[str, str, int, str]],
    *,
    delay_seconds: float = 3.0,
    prompt_template: str,
) -> dict[str, Any]:
    """Gera um lote de questões com IA."""
    generated = 0
    failed = 0
    errors: list[str] = []

    for i, item in enumerate(items):
        subject, topic, year, difficulty = item
        try:
            prompt = prompt_template.format(
                subject=subject,
                topic=topic,
                year=year,
                difficulty=difficulty,
            )
            instructions = "Você é professor do PAES/UEMA. Produza uma questão inédita em JSON."
            raw = _ask_ai(instructions, prompt)
            q = _parse_json_response(raw)
            if q is None:
                raise ValueError("Resposta não é JSON válido")
            qid = _insert_question(q, subject, topic, year, difficulty)
            generated += 1
            print(f"  [{i+1}/{len(items)}] OK: {qid} — {subject}/{topic} ({year})")
        except Exception as exc:
            failed += 1
            errors.append(f"{subject}/{topic}/{year}: {exc}")
            print(f"  [{i+1}/{len(items)}] FALHA: {subject}/{topic} ({year}): {exc}")
        if i < len(items) - 1:
            time.sleep(delay_seconds)

    return {
        "ok": True,
        "total": len(items),
        "generated": generated,
        "failed": failed,
        "errors": errors[:10],
    }


def main():
    print("=" * 60)
    print("GERAÇÃO DE QUESTÕES DE QUÍMICA COM IA")
    print("=" * 60)

    # Lote 1: Química
    [(t[0], t[1], a, d) for (t, a, d) in [(x, x[1], x[2]) for x in []]]
    # Reformular
    [(topic, topic, year, diff) for (topic, year, diff) in QUIMICA_TOPICS]
    # Ajustar: subject=Química, topic=topic
    quimica_batch = [("Química", topic, year, diff) for (topic, year, diff) in QUIMICA_TOPICS]

    print(f"\nLote 1: {len(quimica_batch)} questões de Química")
    result1 = generate_batch(
        quimica_batch,
        delay_seconds=3.0,
        prompt_template=_QUESTION_PROMPT,
    )
    print(f"  Geradas: {result1['generated']}, Falhas: {result1['failed']}")

    # Lote 2: 2019
    print(f"\nLote 2: {len(TOPICS_2019)} questões de 2019 (várias disciplinas)")
    result2 = generate_batch(
        TOPICS_2019,
        delay_seconds=3.0,
        prompt_template=_GENERIC_PROMPT,
    )
    print(f"  Geradas: {result2['generated']}, Falhas: {result2['failed']}")

    print("\n" + "=" * 60)
    print(f"TOTAL: {result1['generated'] + result2['generated']} questões geradas")
    print(f"Falhas: {result1['failed'] + result2['failed']}")
    print("=" * 60)


if __name__ == "__main__":
    main()
