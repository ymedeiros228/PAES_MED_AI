"""Migrações de conteúdo idempotentes, executadas no startup.

Rodam uma vez por versão (chave ``content_migration_version`` em ``settings``),
inclusive em bancos de quem já tem o app instalado.
"""

from __future__ import annotations

import json
import logging
import re
import unicodedata
from datetime import datetime, timedelta
from typing import Any

from db import db

_log = logging.getLogger("paes.content_migrations")

CONTENT_MIGRATION_VERSION = "1"

# Padrões de cartões gerados por template (sem valor de estudo).
_TEMPLATE_PATTERNS = (
    re.compile(r"\((eixo)\)", re.I),
    re.compile(r"^\s*macete r[aá]pido\s*[—–-]", re.I),
    re.compile(r"o que a banca costuma cobrar\?", re.I),
    re.compile(r"^\s*tema central\s*[—–-]", re.I),
    re.compile(r"^\s*detalhe da aula\s*[—–-]", re.I),
)
_AUTO_SOURCE_PREFIXES = ("axis:", "pack:")


def _norm(text: str | None) -> str:
    t = unicodedata.normalize("NFKD", str(text or "")).encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", t).strip().lower()


def _is_template(front: str | None, source: str | None) -> bool:
    src = (source or "").strip().lower()
    if src.startswith(_AUTO_SOURCE_PREFIXES):
        return True
    return any(p.search(front or "") for p in _TEMPLATE_PATTERNS)


def migrate_content() -> dict[str, Any]:
    """Limpa cartões-template e importa os flashcards das aulas. Idempotente."""
    with db() as conn:
        row = conn.execute(
            "SELECT value FROM settings WHERE key='content_migration_version'"
        ).fetchone()
        if row and str(row["value"]) == CONTENT_MIGRATION_VERSION:
            return {"skipped": True}

        # (a) apaga só cartões de template nunca revisados
        removed = 0
        for r in conn.execute("SELECT id, front, source FROM flashcards WHERE COALESCE(reviews,0)=0").fetchall():
            if _is_template(r["front"], r["source"]):
                conn.execute("DELETE FROM flashcards WHERE id=?", (r["id"],))
                removed += 1

        # (b) importa cartões das aulas
        existing = {_norm(r["front"]) for r in conn.execute("SELECT front FROM flashcards").fetchall()}
        today = datetime.now().replace(microsecond=0)
        added = 0
        for lesson in conn.execute(
            "SELECT id, subject, topic, flashcards_json FROM lessons WHERE flashcards_json IS NOT NULL AND flashcards_json != '[]'"
        ).fetchall():
            try:
                cards = json.loads(lesson["flashcards_json"] or "[]")
            except (ValueError, TypeError):
                continue
            if not isinstance(cards, list):
                continue
            for card in cards:
                if not isinstance(card, dict):
                    continue
                front = str(card.get("front") or "").strip()
                back = str(card.get("back") or "").strip()
                key = _norm(front)
                if not front or not back or key in existing:
                    continue
                existing.add(key)
                due = (today + timedelta(days=added % 7)).isoformat(timespec="seconds")
                conn.execute(
                    "INSERT INTO flashcards (front, back, subject, topic, source, next_due, reviews) "
                    "VALUES (?,?,?,?,?,?,0)",
                    (front, back, lesson["subject"], lesson["topic"], "aula", due),
                )
                added += 1

        # (c) grava a versão
        conn.execute(
            "INSERT INTO settings (key, value) VALUES ('content_migration_version', ?) "
            "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
            (CONTENT_MIGRATION_VERSION,),
        )
        conn.commit()
    _log.info("Migração de conteúdo: %s cartões removidos, %s importados", removed, added)
    return {"removed": removed, "added": added}
