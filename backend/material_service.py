"""Serviço de geração de material de estudo com IA + imagens da Wikipédia (Português do Brasil).

Para cada tópico do edital:
1. Gera teoria estruturada via IA (Gemini/Groq/OpenRouter)
2. Busca imagens reais na Wikipédia (Português do Brasil)
3. Armazena no banco (tabela materials)
4. Retorna conteúdo rico para o frontend renderizar
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from ai_state import configured_provider
from api_helpers import _ask_gemini, _ask_groq, _ask_openai, _ask_openrouter
from db import db, row_to_dict
from wiki_images import fetch_images_for_topic

# Prompt para gerar material de estudo estruturado
_MATERIAL_PROMPT = """Você é um professor especializado em {subject} para o vestibular PAES UEMA Medicina.

Crie material de estudo completo e rico para o tópico: "{topic}"{subtopic_text}.

O material deve ser em PORTUGUÊS, didático, com profundidade adequada para vestibular médico.

Retorne APENAS um JSON válido (sem markdown, sem comentários) com esta estrutura:
{{
  "titulo": "Título do material",
  "introducao": "Parágrafo de introdução (2-3 frases)",
  "secoes": [
    {{
      "titulo": "Nome da seção",
      "conteudo": "Texto da seção (pode ter múltiplos parágrafos separados por \\n\\n)",
      "exemplo": "Exemplo prático ou aplicação (opcional)"
    }}
  ],
  "resumo": "Resumo final com pontos-chave (bullet points separados por \\n)",
  "dicas": ["Dica 1 para a prova", "Dica 2", "Dica 3"],
  "pegadinhas": ["Pegadinha comum 1", "Pegadinha 2"],
  "relacionado": ["Tópico relacionado 1", "Tópico relacionado 2"]
}}

Requisitos:
- Mínimo 4 seções com conteúdo substancial
- Use linguagem clara e acessível
- Inclua exemplos do cotidiano quando possível
- Destaque o que mais cai na prova da UEMA
- NÃO invente dados — use conhecimento estabelecido
- Retorne SOMENTE o JSON, sem texto antes ou depois"""


def _ask_ai(instructions: str, content: str) -> str:
    """Chama o provedor de IA configurado."""
    provider = configured_provider()
    if not provider:
        raise RuntimeError("Nenhum provedor de IA configurado. Configure nas Definições.")
    askers = {
        "gemini": _ask_gemini,
        "groq": _ask_groq,
        "openrouter": _ask_openrouter,
        "openai": _ask_openai,
    }
    return askers[provider](instructions, content, None)


def _parse_ai_json(raw: str) -> dict[str, Any]:
    """Extrai JSON da resposta da IA (tolerante a markdown code blocks)."""
    text = raw.strip()
    # Remove markdown code blocks se presentes
    if text.startswith("```"):
        lines = text.split("\n")
        # Remove primeira e última linha (```json e ```)
        lines = [l for l in lines if not l.strip().startswith("```")]
        text = "\n".join(lines)
    # Tenta encontrar o JSON
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        text = text[start : end + 1]
    return json.loads(text)


def _material_id(subject: str, topic: str, subtopic: str | None) -> str:
    """Gera ID determinístico para o material."""
    base = f"{subject}_{topic}"
    if subtopic:
        base += f"_{subtopic}"
    # Slug simples
    slug = (
        base.lower()
        .replace(" ", "_")
        .replace("á", "a")
        .replace("é", "e")
        .replace("í", "i")
        .replace("ó", "o")
        .replace("ú", "u")
        .replace("ã", "a")
        .replace("õ", "o")
        .replace("ç", "c")
        .replace("/", "_")
        .replace("(", "")
        .replace(")", "")
    )
    return f"mat_{slug}"


def get_material(subject: str, topic: str, subtopic: str | None = None) -> dict[str, Any] | None:
    """Recupera material já gerado do banco."""
    with db() as conn:
        if subtopic:
            row = conn.execute(
                "SELECT * FROM materials WHERE subject=? AND topic=? AND subtopic=?",
                (subject, topic, subtopic),
            ).fetchone()
        else:
            row = conn.execute(
                "SELECT * FROM materials WHERE subject=? AND topic=? AND (subtopic IS NULL OR subtopic='')",
                (subject, topic),
            ).fetchone()
        if not row:
            return None
        result = row_to_dict(row)
        if result:
            result["content"] = json.loads(result.pop("content_json"))
            result["images"] = json.loads(result.pop("images_json") or "[]")
        return result


async def generate_material(
    subject: str,
    topic: str,
    subtopic: str | None = None,
    force: bool = False,
) -> dict[str, Any]:
    """Gera material de estudo completo: teoria via IA + imagens da Wikipédia (Português do Brasil).

    Args:
        subject: Disciplina (ex: "Biologia")
        topic: Tópico (ex: "Citologia")
        subtopic: Subtópico opcional (ex: "Membrana")
        force: Se True, regenera mesmo se já existir

    Returns:
        Material completo com content (teoria) e images (imagens reais)
    """
    # Verifica se já existe
    if not force:
        existing = get_material(subject, topic, subtopic)
        if existing:
            return existing

    subtopic_text = f" — subtopico: {subtopic}" if subtopic else ""
    prompt = _MATERIAL_PROMPT.format(
        subject=subject,
        topic=topic,
        subtopic_text=subtopic_text,
    )

    # 1. Gera teoria via IA
    ai_response = _ask_ai(prompt, f"Gere o material para: {topic}{subtopic_text}")
    content = _parse_ai_json(ai_response)

    # 2. Busca imagens reais na Wikipédia (Português do Brasil)
    search_topic = subtopic or topic
    wiki_data = await fetch_images_for_topic(search_topic, subject, max_images=5)
    images = wiki_data.get("images", [])

    # 3. Armazena no banco
    mat_id = _material_id(subject, topic, subtopic)
    title = content.get("titulo", f"{topic}" + (f" — {subtopic}" if subtopic else ""))
    now = datetime.now(timezone.utc).isoformat()

    with db() as conn:
        conn.execute(
            """
            INSERT OR REPLACE INTO materials
                (id, subject, topic, subtopic, title, content_json, images_json,
                 wiki_url, generated_at, approved)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
            """,
            (
                mat_id,
                subject,
                topic,
                subtopic or "",
                title,
                json.dumps(content, ensure_ascii=False),
                json.dumps(images, ensure_ascii=False),
                wiki_data.get("article_url"),
                now,
            ),
        )
        conn.commit()

    return {
        "id": mat_id,
        "subject": subject,
        "topic": topic,
        "subtopic": subtopic or "",
        "title": title,
        "content": content,
        "images": images,
        "wiki_url": wiki_data.get("article_url"),
        "generated_at": now,
        "approved": False,
    }


def list_materials(subject: str | None = None) -> list[dict[str, Any]]:
    """Lista todos os materiais gerados, opcionalmente filtrados por disciplina."""
    with db() as conn:
        if subject:
            rows = conn.execute(
                "SELECT id, subject, topic, subtopic, title, generated_at, approved FROM materials WHERE subject=? ORDER BY topic, subtopic",
                (subject,),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT id, subject, topic, subtopic, title, generated_at, approved FROM materials ORDER BY subject, topic, subtopic",
            ).fetchall()
        return [dict(r) for r in rows]


def list_syllabus_with_status(subject: str | None = None) -> list[dict[str, Any]]:
    """Lista syllabus com status de material (gerado ou não)."""
    with db() as conn:
        if subject:
            rows = conn.execute(
                """
                SELECT s.id, s.subject, s.topic, s.subtopic, s.weight,
                       CASE WHEN m.id IS NOT NULL THEN 1 ELSE 0 END as has_material,
                       m.title as material_title
                FROM syllabus s
                LEFT JOIN materials m ON s.subject = m.subject AND s.topic = m.topic
                    AND COALESCE(s.subtopic,'') = COALESCE(m.subtopic,'')
                WHERE s.subject = ?
                ORDER BY s.subject, s.topic, s.subtopic
                """,
                (subject,),
            ).fetchall()
        else:
            rows = conn.execute(
                """
                SELECT s.id, s.subject, s.topic, s.subtopic, s.weight,
                       CASE WHEN m.id IS NOT NULL THEN 1 ELSE 0 END as has_material,
                       m.title as material_title
                FROM syllabus s
                LEFT JOIN materials m ON s.subject = m.subject AND s.topic = m.topic
                    AND COALESCE(s.subtopic,'') = COALESCE(m.subtopic,'')
                ORDER BY s.subject, s.topic, s.subtopic
                """,
            ).fetchall()
        return [dict(r) for r in rows]


def delete_material(material_id: str) -> bool:
    """Remove um material gerado."""
    with db() as conn:
        cursor = conn.execute("DELETE FROM materials WHERE id=?", (material_id,))
        conn.commit()
        return cursor.rowcount > 0
