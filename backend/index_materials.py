# -*- coding: utf-8 -*-
"""Indexa todos os 92 PDFs no banco de dados (tabela materials).

Extrai o CONTENT de cada gerador de PDF e insere no banco para que
o frontend possa mostrar "Abrir" em vez de "Gerar" para cada topico.
"""

from __future__ import annotations

import sys
import io
import os
import json
import importlib
import inspect
import re
from datetime import datetime, timezone
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.path.insert(0, str(Path(__file__).resolve().parent))

from db import db, init_db

# Inicializa o banco
init_db()

# Mapeia codigo de disciplina -> nome completo
SUBJECT_MAP = {
    "BI": "Biologia",
    "QU": "Quimica",
    "FI": "Fisica",
    "MA": "Matematica",
    "MT": "Matematica",
    "PO": "Portugues",
    "PT": "Portugues",
    "HI": "Historia",
    "GE": "Geografia",
    "FILO": "Filosofia",
    "FIL": "Filosofia",
    "SOC": "Sociologia",
    "ING": "Ingles",
    "ESP": "Espanhol",
}

# Lista de geradores de PDF (exclui diagramas, flashcards, lessons, etc)
PDF_GENERATORS = [
    # Biologia (geradores antigos com CONTENT direto)
    "generate_pdf_intro_biologia",
    "generate_pdf_material",  # Membrana Plasmatica
    "generate_pdf_citoplasma",
    "generate_pdf_organelas",
    "generate_pdf_nucleo",
    "generate_pdf_ciclo",
    "generate_pdf_metabolismo",
    "generate_pdf_gametogenese",
    "generate_pdf_reproducao",
    "generate_pdf_anomalias",
    "generate_pdf_histologia",
    "generate_pdf_ecologia",
    "generate_pdf_classificacao",
    "generate_pdf_microbiologia",
    "generate_pdf_botanica",
    "generate_pdf_zoologia",
    "generate_pdf_genetica",
    "generate_pdf_evolucao",
    "generate_pdf_saude_doencas",
    "generate_pdf_principios_elementares",
    # Quimica
    "generate_quimica_batch1",
    "generate_quimica_batch2",
    "generate_quimica_batch3",
    # Fisica
    "generate_fisica_batch1",
    "generate_fisica_batch2",
    "generate_fisica_batch3",
    # Matematica
    "generate_matematica_batch1",
    "generate_matematica_batch2",
    # Portugues
    "generate_portugues_batch1",
    "generate_portugues_batch2",
    # Ingles
    "generate_ingles_batch",
    # Espanhol
    "generate_espanhol_batch",
    # Historia
    "generate_historia_batch1",
    "generate_historia_batch2",
    # Geografia
    "generate_geografia_batch",
    # Filosofia
    "generate_filosofia_batch1",
    "generate_filosofia_batch2",
    # Sociologia
    "generate_sociologia_batch1",
    "generate_sociologia_batch2",
    "generate_sociologia_batch3",
]


def _material_id(subject: str, topic: str, subtopic: str | None) -> str:
    """Gera ID deterministico para o material."""
    base = f"{subject}_{topic}"
    if subtopic:
        base += f"_{subtopic}"
    slug = (
        base.lower()
        .replace(" ", "_")
        .replace("á", "a").replace("é", "e").replace("í", "i")
        .replace("ó", "o").replace("ú", "u").replace("ã", "a")
        .replace("õ", "o").replace("ç", "c").replace("/", "_")
        .replace("(", "").replace(")", "").replace(",", "")
        .replace("—", "_").replace("–", "_").replace(":", "")
        .replace(";", "").replace("?", "").replace("!", "")
        .replace("º", "").replace("ª", "").replace("°", "")
    )
    return f"mat_{slug[:200]}"


def _find_content_vars(module) -> list[dict]:
    """Encontra todas as variaveis CONTENT/dicts com estrutura de material em um modulo."""
    contents = []
    src = inspect.getsource(module)
    # Procura variaveis que sao dicts com 'titulo' e 'secoes'
    for name, val in vars(module).items():
        if name.startswith("_"):
            continue
        if isinstance(val, dict) and "titulo" in val and "secoes" in val:
            val["_var_name"] = name
            contents.append(val)
    return contents


def _find_pdf_mappings(module) -> list[tuple[str, str]]:
    """Encontra mapeamentos (content_var, pdf_filename) no modulo."""
    mappings = []
    src = inspect.getsource(module)
    # Procura padroes como (VARIAVEL, "ARQUIVO.pdf", ...)
    pattern = r'\(([A-Z_]+),\s*"([^"]+\.pdf)"'
    for m in re.finditer(pattern, src):
        var_name = m.group(1)
        pdf_name = m.group(2)
        mappings.append((var_name, pdf_name))
    return mappings


def _normalize_subject(disciplina: str) -> str:
    """Normaliza o nome da disciplina."""
    d = disciplina.strip()
    # Mapeia nomes variados para o padrao do syllabus
    mapping = {
        "Biologia": "Biologia",
        "Química": "Quimica",
        "Quimica": "Quimica",
        "Física": "Fisica",
        "Fisica": "Fisica",
        "Matemática": "Matematica",
        "Matematica": "Matematica",
        "Português": "Portugues",
        "Portugues": "Portugues",
        "Língua Portuguesa": "Portugues",
        "Língua Portuguesa e Literatura": "Portugues",
        "Inglês": "Ingles",
        "Ingles": "Ingles",
        "Língua Inglesa": "Ingles",
        "Espanhol": "Espanhol",
        "Língua Espanhola": "Espanhol",
        "História": "Historia",
        "Historia": "Historia",
        "Geografia": "Geografia",
        "Filosofia": "Filosofia",
        "Sociologia": "Sociologia",
    }
    return mapping.get(d, d)


def index_material(content: dict, pdf_filename: str | None = None) -> dict | None:
    """Insere ou atualiza um material no banco."""
    if not content.get("titulo") or not content.get("secoes"):
        return None

    subject = _normalize_subject(content.get("disciplina", ""))
    topic = content.get("topico", content.get("titulo", ""))
    subtopic = content.get("subtopico", "")

    if not subject or not topic:
        return None

    mat_id = _material_id(subject, topic, subtopic)
    title = content.get("titulo", topic)
    now = datetime.now(timezone.utc).isoformat()

    # Conteudo estruturado (sem campos internos)
    content_json = {
        "titulo": title,
        "introducao": content.get("introducao", ""),
        "secoes": content.get("secoes", []),
        "resumo": content.get("resumo", ""),
        "dicas": content.get("dicas", []),
        "pegadinhas": content.get("pegadinhas", []),
        "relacionado": content.get("relacionado", []),
    }

    # Imagens vazias por enquanto (o PDF tem as imagens)
    images_json = []

    # wiki_url opcional
    wiki_url = content.get("wiki_url")

    with db() as conn:
        conn.execute(
            """
            INSERT OR REPLACE INTO materials
                (id, subject, topic, subtopic, title, content_json, images_json,
                 wiki_url, generated_at, approved)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
            """,
            (
                mat_id,
                subject,
                topic,
                subtopic,
                title,
                json.dumps(content_json, ensure_ascii=False),
                json.dumps(images_json, ensure_ascii=False),
                wiki_url,
                now,
            ),
        )
        conn.commit()

    return {
        "id": mat_id,
        "subject": subject,
        "topic": topic,
        "subtopic": subtopic,
        "title": title,
        "pdf": pdf_filename,
    }


def main():
    print("=" * 60)
    print("Indexando 92 PDFs no banco de dados...")
    print("=" * 60)

    total = 0
    errors = 0
    indexed = []

    for mod_name in PDF_GENERATORS:
        try:
            mod = importlib.import_module(mod_name)
        except Exception as e:
            print(f"  ERRO ao importar {mod_name}: {e}")
            errors += 1
            continue

        # Encontra contents no modulo
        contents = _find_content_vars(mod)
        if not contents:
            print(f"  {mod_name}: nenhum CONTENT encontrado")
            continue

        # Encontra mapeamentos PDF
        pdf_maps = _find_pdf_mappings(mod)
        pdf_map_dict = {var: pdf for var, pdf in pdf_maps}

        for content in contents:
            var_name = content.pop("_var_name", "")
            pdf_name = pdf_map_dict.get(var_name)
            result = index_material(content, pdf_name)
            if result:
                total += 1
                indexed.append(result)
                print(f"  OK: {result['subject']} - {result['topic']} ({result['title'][:40]})")
            else:
                print(f"  SKIP: {var_name} em {mod_name}")

    print()
    print("=" * 60)
    print(f"Total indexado: {total}")
    print(f"Erros: {errors}")
    print("=" * 60)

    # Verifica no banco
    with db() as conn:
        count = conn.execute("SELECT COUNT(*) FROM materials").fetchone()[0]
        print(f"Materiais no banco: {count}")

        # Por disciplina
        rows = conn.execute(
            "SELECT subject, COUNT(*) as cnt FROM materials GROUP BY subject ORDER BY cnt DESC"
        ).fetchall()
        print("\nPor disciplina:")
        for r in rows:
            print(f"  {r[0]}: {r[1]}")

    return total


if __name__ == "__main__":
    main()
