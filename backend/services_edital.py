"""Leitura operacional do edital e cobertura por questões oficiais."""
from __future__ import annotations

import ast
import hashlib
import json
import re
import unicodedata
from typing import Any

from db import DATA_DIR, db
from ingest_pdf import extract_pdf_text
from services_core import is_official_source


def parse_edital_markdown(text: str) -> list[dict[str, Any]]:
    """Converte títulos e tópicos Markdown em registros de syllabus."""
    entries: list[dict[str, Any]] = []
    subject = "Geral"
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("<!--"):
            continue
        heading = re.match(r"^#{1,3}\s+(.+)$", line)
        if heading:
            candidate = heading.group(1).strip()
            if not candidate.lower().startswith(("conteúdo", "sumário", "edital")):
                subject = candidate
            continue
        bullet = re.match(r"^(?:[-*+]|\d+[.)])\s+(.+)$", line)
        if not bullet:
            continue
        value = re.sub(r"\s+", " ", bullet.group(1)).strip()
        topic, separator, rest = value.partition(":")
        if separator:
            subtopics = [part.strip(" .") for part in re.split(r"[,;]|\be\b", rest) if part.strip(" .")]
            if subtopics:
                entries.extend(
                    {"subject": subject, "topic": topic.strip(), "subtopic": subtopic, "weight": 1.0}
                    for subtopic in subtopics
                )
                continue
        entries.append({"subject": subject, "topic": value.strip(" ."), "subtopic": None, "weight": 1.0})
    return entries


def _entry_id(entry: dict[str, Any]) -> str:
    key = "|".join(str(entry.get(k) or "") for k in ("subject", "topic", "subtopic"))
    return f"edital-{hashlib.sha1(key.encode('utf-8')).hexdigest()[:16]}"


def sync_syllabus_from_edital_file() -> dict[str, Any]:
    """Lê .md/PDF de data/edital e faz upsert no syllabus."""
    edital_dir = DATA_DIR / "edital"
    edital_dir.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, Any]] = []
    sources: list[str] = []
    for path in sorted(edital_dir.glob("*.md")):
        entries.extend(parse_edital_markdown(path.read_text(encoding="utf-8", errors="ignore")))
        sources.append(path.name)
    for path in sorted(edital_dir.glob("*.pdf")):
        entries.extend(parse_edital_markdown(extract_pdf_text(path)))
        sources.append(path.name)
    unique = {(e["subject"], e["topic"], e.get("subtopic")): e for e in entries}
    with db() as conn:
        for entry in unique.values():
            conn.execute(
                """INSERT INTO syllabus (id, subject, topic, subtopic, weight) VALUES (?, ?, ?, ?, ?)
                   ON CONFLICT(id) DO UPDATE SET subject=excluded.subject, topic=excluded.topic,
                   subtopic=excluded.subtopic, weight=excluded.weight""",
                (_entry_id(entry), entry["subject"], entry["topic"], entry.get("subtopic"), entry["weight"]),
            )
        conn.commit()
    return {"ok": True, "sources": sources, "upserted": len(unique)}


_STOPWORDS = {
    "para", "como", "com", "das", "dos", "uma", "umas", "uns", "por", "pela", "pelo",
    "entre", "sobre", "seus", "suas", "geral", "conceitos",
}


def _fold(text: str | None) -> str:
    """Minúsculas sem acento (materiais usam 'Fisica', questões 'Física')."""
    norm = unicodedata.normalize("NFKD", str(text or ""))
    return "".join(ch for ch in norm if not unicodedata.combining(ch)).lower().strip()


def _topic_tokens(text: str | None) -> set[str]:
    return {
        tok
        for tok in re.findall(r"[a-z0-9]+", _fold(text))
        if len(tok) >= 4 and tok not in _STOPWORDS
    }


def clean_markdown(text: str | None) -> str:
    """Remove marcação Markdown crua ('## Título', '- item', '**negrito**') para leitura.

    Títulos viram linha simples, bullets viram '• ', ênfases somem.
    """
    out: list[str] = []
    for raw in str(text or "").splitlines():
        stripped = raw.strip()
        if stripped.startswith("<!--"):
            continue
        stripped = re.sub(r"^#{1,6}\s+", "", stripped)
        stripped = re.sub(r"^[-*+]\s+", "• ", stripped)
        stripped = re.sub(r"(\*\*|__)(.+?)\1", r"\2", stripped)
        stripped = re.sub(r"`([^`]*)`", r"\1", stripped)
        out.append(stripped)
    blob = "\n".join(out)
    return re.sub(r"\n{3,}", "\n\n", blob).strip()


def _as_list(value: Any) -> list[str]:
    """Campos de material às vezes vêm como lista, às vezes como repr de lista em string."""
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v).strip() for v in value if str(v).strip()]
    text = str(value).strip()
    if not text:
        return []
    if text.startswith("["):
        for parser in (json.loads, ast.literal_eval):
            try:
                parsed = parser(text)
            except (ValueError, SyntaxError):
                continue
            if isinstance(parsed, list):
                return [str(v).strip() for v in parsed if str(v).strip()]
    return [text]


def _subject_matches(a: str | None, b: str | None) -> bool:
    fa, fb = _fold(a), _fold(b)
    if not fa or not fb:
        return False
    return fa == fb or fa.startswith(fb) or fb.startswith(fa)


def find_topic_material(subject: str | None, topic: str | None) -> dict[str, Any] | None:
    """Material didático (tabela materials) que melhor casa com disciplina + tópico.

    Casa sem acento; tópico exato vale mais que sobreposição de palavras com
    tópico/subtópico/título (ex.: 'Estequiometria' → 'Cálculos Químicos … Estequiometria').
    """
    if not subject or not topic:
        return None
    want_topic = _fold(topic)
    want_tokens = _topic_tokens(topic)
    with db() as conn:
        rows = conn.execute(
            "SELECT id, subject, topic, subtopic, title, content_json, pdf_filename FROM materials"
        ).fetchall()
    best: tuple[int, dict[str, Any]] | None = None
    for row in rows:
        if not _subject_matches(row["subject"], subject):
            continue
        if _fold(row["topic"]) == want_topic:
            score = 100
        else:
            have = _topic_tokens(f"{row['topic']} {row['subtopic'] or ''} {row['title'] or ''}")
            score = 10 * len(want_tokens & have)
        if score and (best is None or score > best[0]):
            best = (score, dict(row))
    return best[1] if best else None


def _material_sections(material: dict[str, Any]) -> list[dict[str, Any]]:
    try:
        content = json.loads(material.get("content_json") or "{}")
    except (TypeError, ValueError):
        return []
    if not isinstance(content, dict):
        return []
    source = f"material:{material.get('id')}"
    sections: list[dict[str, Any]] = []
    intro = clean_markdown(content.get("introducao"))
    if intro:
        sections.append({"title": "Introdução", "body": intro, "source": source})
    for sec in content.get("secoes") or []:
        if not isinstance(sec, dict):
            continue
        body = clean_markdown(sec.get("conteudo"))
        example = clean_markdown(sec.get("exemplo"))
        if example:
            body = f"{body}\n\nExemplo: {example}" if body else f"Exemplo: {example}"
        if body:
            sections.append(
                {"title": clean_markdown(sec.get("titulo")) or "Seção", "body": body, "source": source}
            )
    resumo = clean_markdown(content.get("resumo"))
    if resumo:
        sections.append({"title": "Resumo", "body": resumo, "source": source})
    for key, label in (("dicas", "Dicas de prova"), ("pegadinhas", "Pegadinhas")):
        items = [clean_markdown(i) for i in _as_list(content.get(key))]
        items = [i for i in items if i]
        if items:
            body = "\n".join(i if i.startswith("• ") else f"• {i}" for i in items)
            sections.append({"title": label, "body": body, "source": source})
    return sections


def _lesson_text(summary: str | None) -> str:
    """Resumo da aula em texto puro.

    Parte das aulas antigas guardou a resposta inteira do gerador
    ('{"summary": "...", "macetes": [...]}', às vezes com '{{ }}'): fica só o resumo.
    """
    text = (summary or "").strip()
    if not text.startswith("{"):
        return text
    bruto = text
    while bruto.startswith("{{") and bruto.endswith("}}"):
        bruto = bruto[1:-1].strip()
    try:
        data = json.loads(bruto)
        if isinstance(data, dict) and isinstance(data.get("summary"), str):
            return data["summary"].strip()
    except ValueError:
        pass
    achado = re.search(r'"summary"\s*:\s*"((?:[^"\\]|\\.)*)"', text)
    if achado:
        try:
            return str(json.loads(f'"{achado.group(1)}"')).strip()
        except ValueError:
            return achado.group(1).strip()
    return ""


def _lesson_sections(subject: str, topic: str) -> list[dict[str, Any]]:
    with db() as conn:
        rows = conn.execute(
            """
            SELECT id, title, summary FROM lessons
            WHERE subject=? AND topic=? AND summary IS NOT NULL AND TRIM(summary) != ''
            ORDER BY created_at DESC
            """,
            (subject, topic),
        ).fetchall()
    seen: set[str] = set()
    sections: list[dict[str, Any]] = []
    for row in rows:
        body = clean_markdown(_lesson_text(row["summary"]))
        key = re.sub(r"\s+", " ", body).lower()
        if not body or key in seen:  # aulas duplicadas (mesmo resumo) aparecem 1x
            continue
        seen.add(key)
        sections.append({"title": "Resumo de aula", "body": body, "source": f"lesson:{row['id']}"})
    return sections


def _edital_lines(subject: str | None, topic: str | None, limit: int) -> list[str]:
    """Linhas do edital local (MD/PDF) que citam o TÓPICO (não a disciplina inteira).

    Antes casava qualquer palavra de 'subject topic' (ex.: 'biologia') com janela
    deslizante de 4 linhas → vários blocos repetindo o edital inteiro.
    """
    tokens = _topic_tokens(topic) or _topic_tokens(subject)
    if not tokens:
        return []
    edital_dir = DATA_DIR / "edital"
    edital_dir.mkdir(parents=True, exist_ok=True)
    texts: list[str] = [
        p.read_text(encoding="utf-8", errors="ignore") for p in sorted(edital_dir.glob("*.md"))
    ]
    if not texts:
        for path in sorted(edital_dir.glob("*.pdf"))[:3]:
            try:
                texts.append(extract_pdf_text(path) or "")
            except Exception:  # noqa: BLE001 — PDF ilegível: só ignora
                continue
    out: list[str] = []
    for text in texts:
        for line in text.splitlines():
            if not (_topic_tokens(line) & tokens):
                continue
            clean = clean_markdown(line)
            if clean and clean not in out:
                out.append(clean)
            if len(out) >= limit:
                return out
    return out


def _stem(token: str) -> str:
    """Radical grosseiro (6 letras) para casar plural/gênero: 'mutacoes'~'mutacao'."""
    return token[:6]


_STEM_RE = re.compile(r"[a-z0-9]+")


def _text_stems(text: str | None) -> set[str]:
    return {_stem(t) for t in _STEM_RE.findall(_fold(text)) if len(t) >= 4 and t not in _STOPWORDS}


class TopicRelevance:
    """Pontua quão "do tópico" é uma questão (nº de radicais distintivos no texto).

    Necessário porque o classificador de importação rotulou muitas oficiais com
    um tópico padrão (ex.: 51 de Biologia como 'Genética/Mendel', inclusive
    protozoários e até química). Assim a sessão prioriza o conteúdo real.
    """

    def __init__(self, keywords: set[str]) -> None:
        self.keywords = keywords

    def __call__(self, question: dict[str, Any]) -> int:
        if not self.keywords:
            return 0
        opts = question.get("options") or []
        blob = " ".join([str(question.get("statement") or ""), *map(str, opts)])
        return len(_text_stems(blob) & self.keywords)


def topic_relevance_scorer(subject: str | None, topic: str | None) -> TopicRelevance:
    """Monta o vocabulário distintivo do tópico.

    Fontes: nome do tópico, sinônimos do classificador, títulos/subtópico do
    material e termos frequentes no material do tópico que são raros nos
    materiais dos outros tópicos (tipo TF-IDF simples).
    """
    keywords = _text_stems(topic)
    if not topic:
        return TopicRelevance(keywords)
    try:
        from ingest_pdf import SYLLABUS_SYNONYMS

        want = _fold(topic)
        keywords |= {_stem(_fold(k)) for k, v in SYLLABUS_SYNONYMS.items() if _fold(v) == want and len(k) >= 4}
    except ImportError:
        pass
    material = find_topic_material(subject, topic)
    if not material:
        return TopicRelevance(keywords)
    keywords |= _text_stems(f"{material.get('subtopic') or ''} {material.get('title') or ''}")
    keywords |= _distinctive_stems(str(material.get("id")))
    return TopicRelevance(keywords)


def _json_strings(value: Any) -> list[str]:
    """Todas as strings de um JSON decodificado (evita '\\n' literal virar 'nheranca')."""
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        return [s for v in value.values() for s in _json_strings(v)]
    if isinstance(value, list):
        return [s for v in value for s in _json_strings(v)]
    return []


_DISTINCTIVE_CACHE: dict[tuple[str, int, str], set[str]] = {}


def _distinctive_stems(material_id: str) -> set[str]:
    """Radicais recorrentes (tf ≥ 3) no material e raros (≤ 2 materiais) no acervo."""
    with db() as conn:
        sig = conn.execute(
            "SELECT COUNT(*) AS n, COALESCE(MAX(generated_at), '') AS last FROM materials"
        ).fetchone()
        key = (material_id, int(sig["n"]), str(sig["last"]))
        if key in _DISTINCTIVE_CACHE:
            return _DISTINCTIVE_CACHE[key]
        rows = conn.execute("SELECT id, content_json FROM materials").fetchall()
    df: dict[str, int] = {}
    target_tf: dict[str, int] = {}
    for row in rows:
        try:
            text = " ".join(_json_strings(json.loads(row["content_json"] or "{}")))
        except (TypeError, ValueError):
            text = str(row["content_json"] or "")
        stems_list = [
            _stem(t) for t in _STEM_RE.findall(_fold(text)) if len(t) >= 5 and t not in _STOPWORDS
        ]
        for st in set(stems_list):
            df[st] = df.get(st, 0) + 1
        if str(row["id"]) == material_id:
            for st in stems_list:
                target_tf[st] = target_tf.get(st, 0) + 1
    distinctive = sorted(
        (st for st, tf in target_tf.items() if tf >= 3 and df.get(st, 0) <= 2),
        key=lambda st: -target_tf[st],
    )
    out = set(distinctive[:60])
    _DISTINCTIVE_CACHE.clear()  # 1 entrada basta (troca de tópico recalcula ~ms)
    _DISTINCTIVE_CACHE[key] = out
    return out


def rank_by_topic_relevance(
    questions: list[dict[str, Any]], subject: str | None, topic: str | None
) -> list[dict[str, Any]]:
    """Ordena questões: mais aderentes ao tópico primeiro (estável para empates).

    Grava `topicRelevance` (nº de radicais do tópico no texto) em cada questão.
    Rótulo igual ao tópico só desempata; não supera conteúdo.
    """
    scorer = topic_relevance_scorer(subject, topic)
    want = _fold(topic)
    scored = []
    for idx, q in enumerate(questions):
        sc = scorer(q)
        q["topicRelevance"] = sc
        label = 1 if _fold(q.get("topic")) == want else 0
        scored.append((-sc, -label, idx, q))
    scored.sort(key=lambda x: x[:3])
    return [x[3] for x in scored]


def is_same_topic(a: str | None, b: str | None) -> bool:
    return _fold(a) == _fold(b)


def theory_sections_for(
    subject: str | None, topic: str | None, limit: int = 10
) -> list[dict[str, Any]]:
    """Teoria do tópico em blocos {title, body, source}, sem Markdown cru e sem repetição.

    Ordem de preferência: material didático do tópico → resumos de aulas →
    linhas do edital que citam o tópico → subtópicos do syllabus.
    """
    subject = (subject or "").strip() or None
    topic = (topic or "").strip() or None
    sections: list[dict[str, Any]] = []
    material = find_topic_material(subject, topic)
    if material:
        sections.extend(_material_sections(material))
    if subject and topic and not sections:
        sections.extend(_lesson_sections(subject, topic)[:limit])
    if not sections:
        lines = _edital_lines(subject, topic, limit=6)
        if lines:
            body = "\n".join(ln if ln.startswith("• ") else f"• {ln}" for ln in lines)
            sections.append({"title": "Edital (resumo local)", "body": body, "source": "edital"})
        if subject and topic:
            with db() as conn:
                rows = conn.execute(
                    "SELECT subtopic FROM syllabus WHERE subject=? AND topic=? ORDER BY subtopic",
                    (subject, topic),
                ).fetchall()
            subs = [r["subtopic"] for r in rows if r["subtopic"]]
            if subs:
                sections.append(
                    {
                        "title": f"{subject} · {topic}",
                        "body": "Subtópicos: " + ", ".join(subs),
                        "source": "syllabus",
                    }
                )
    return sections[:limit]


def theory_snippets_for(subject: str | None, topic: str | None, limit: int = 6) -> list[str]:
    """Trechos de teoria (texto puro) para a fase teoria da sessão / Biblioteca.

    Mantém o contrato antigo (lista de strings): cada bloco de
    theory_sections_for vira "Título\\ncorpo". Sem teoria do tópico, cai para
    macete/resolução de questões do tópico.
    """
    snippets = [f"{s['title']}\n{s['body']}" for s in theory_sections_for(subject, topic, limit=limit)]
    if snippets or not (subject and topic):
        return snippets[:limit]
    with db() as conn:
        qrows = conn.execute(
            """
            SELECT resolution, macete, pegadinha, topic FROM questions
            WHERE subject=? AND topic=? AND (
                (resolution IS NOT NULL AND resolution != '')
                OR (macete IS NOT NULL AND macete != '')
            )
            LIMIT 3
            """,
            (subject, topic),
        ).fetchall()
    for row in qrows:
        if row["resolution"]:
            snippets.append(f"Resolução ({row['topic']}):\n{str(row['resolution'])[:320]}")
        if row["macete"]:
            snippets.append(f"Macete ({row['topic']}):\n{str(row['macete'])[:220]}")
        if row["pegadinha"]:
            snippets.append(f"Pegadinha ({row['topic']}):\n{str(row['pegadinha'])[:220]}")
    out: list[str] = []
    for snip in snippets:
        if snip not in out:
            out.append(snip)
    return out[:limit]


def edital_coverage() -> dict[str, Any]:
    """Compara tópicos do edital com contagem de itens oficiais importados."""
    edital_dir = DATA_DIR / "edital"
    edital_dir.mkdir(parents=True, exist_ok=True)
    md_files = list(edital_dir.glob("*.md"))
    pdf_files = list(edital_dir.glob("*.pdf"))
    has_files = bool(md_files or pdf_files)

    with db() as conn:
        syllabus = [dict(row) for row in conn.execute(
            "SELECT id, subject, topic, subtopic, weight FROM syllabus ORDER BY subject, topic, subtopic"
        )]
        questions = [dict(row) for row in conn.execute(
            "SELECT subject, topic, source, generated FROM questions"
        )]
        syl_n = len(syllabus)
    counts: dict[tuple[str, str], int] = {}
    for question in questions:
        if is_official_source(question["source"], question["generated"]):
            key = (question["subject"], question["topic"])
            counts[key] = counts.get(key, 0) + 1
    topics = []
    covered_list = []
    missing_list = []
    for entry in syllabus:
        n = counts.get((entry["subject"], entry["topic"]), 0)
        item = {
            **entry,
            "officialQuestionCount": n,
            "officialCount": n,
            "status": "cobrado" if n else "zero",
        }
        topics.append(item)
        slim = {
            "subject": entry["subject"],
            "topic": entry["topic"],
            "weight": entry.get("weight"),
            "officialCount": n,
        }
        if n:
            covered_list.append(slim)
        else:
            missing_list.append(slim)
    covered_list.sort(key=lambda x: -x["officialCount"])
    has_official = bool(counts)
    theory_ready = has_files and syl_n > 0
    has_pdf = bool(pdf_files)
    return {
        "topics": topics,
        "covered": covered_list,
        "missing": missing_list,
        "coveredCount": len(covered_list),
        "missingCount": len(missing_list),
        "syllabusCount": len(syllabus),
        "zero": len(missing_list),
        "hasEditalFiles": has_files,
        "hasEditalPdf": has_pdf,
        "editalFileCount": len(md_files) + len(pdf_files),
        "editalPdfCount": len(pdf_files),
        "editalMdCount": len(md_files),
        "theoryReady": theory_ready,
        "message": (
            "Painel edital × cobrado usa só questões oficiais importadas."
            if has_official
            else "Ainda não há oficiais commitadas — importe provas antes de interpretar cobertura."
        ),
        "studyHint": (
            "Teoria do dia disponível a partir do edital sincronizado."
            if theory_ready
            else "Coloque edital_*.pdf em data/edital e use Sync edital (MD resumo não substitui o PDF oficial)."
            if not has_pdf
            else "Coloque edital_*.pdf ou .md em data/edital e use Sync edital."
        ),
        "officialDocument": (
            "PDF oficial presente."
            if has_pdf
            else "Sem edital_*.pdf — usa-se só resumo MD local; não fingir edital oficial UEMA."
        ),
    }
