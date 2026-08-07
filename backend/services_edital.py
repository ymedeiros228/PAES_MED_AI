"""Leitura operacional do edital e cobertura por questões oficiais."""
from __future__ import annotations

import hashlib
import re
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


def theory_snippets_for(subject: str | None, topic: str | None, limit: int = 6) -> list[str]:
    """Trechos multilinha do edital + bites de resolução para a fase teoria da sessão."""
    snippets: list[str] = []
    tokens = [t.lower() for t in f"{subject or ''} {topic or ''}".split() if len(t) > 3]
    edital_dir = DATA_DIR / "edital"
    edital_dir.mkdir(parents=True, exist_ok=True)
    # MD primeiro
    for path in sorted(edital_dir.glob("*.md")):
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
        for i, line in enumerate(lines):
            low = line.lower()
            if not tokens or not any(tok in low for tok in tokens):
                continue
            block: list[str] = []
            for j in range(max(0, i - 1), min(len(lines), i + 3)):
                piece = lines[j].strip()
                if piece and not piece.startswith("<!--"):
                    block.append(piece)
            text = "\n".join(block)
            if text and text not in snippets:
                snippets.append(text)
            if len(snippets) >= max(3, limit // 2):
                break
        if len(snippets) >= max(3, limit // 2):
            break
    # PDF texto (fallback) se ainda pouco
    if len(snippets) < max(2, limit // 3):
        for path in sorted(edital_dir.glob("*.pdf"))[:3]:
            try:
                text = extract_pdf_text(path) or ""
            except Exception:  # noqa: BLE001
                continue
            lines = text.splitlines()
            for i, line in enumerate(lines):
                low = line.lower()
                if not tokens or not any(tok in low for tok in tokens):
                    continue
                block = []
                for j in range(max(0, i - 1), min(len(lines), i + 3)):
                    piece = lines[j].strip()
                    if piece:
                        block.append(piece)
                blob = "\n".join(block)
                if blob and blob not in snippets:
                    snippets.append(blob[:500])
                if len(snippets) >= max(3, limit // 2):
                    break
            if len(snippets) >= max(3, limit // 2):
                break

    if subject:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT topic, subtopic, weight FROM syllabus
                WHERE subject=? ORDER BY topic, subtopic LIMIT 12
                """,
                (subject,),
            ).fetchall()
            qrows = []
            if topic:
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
        for row in rows:
            label = f"{subject} · {row['topic']}"
            if row["subtopic"]:
                label += f" ({row['subtopic']})"
            label += f" — peso {row['weight']}"
            if label not in snippets:
                snippets.append(label)
        for row in qrows:
            if row["resolution"]:
                snippets.append(f"Resolução ({row['topic']}):\n{str(row['resolution'])[:320]}")
            if row["macete"]:
                snippets.append(f"Macete ({row['topic']}):\n{str(row['macete'])[:220]}")
            if row["pegadinha"]:
                snippets.append(f"Pegadinha ({row['topic']}):\n{str(row['pegadinha'])[:220]}")

    return snippets[:limit]


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
