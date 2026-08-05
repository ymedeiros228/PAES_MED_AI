"""SQLite local — questões, edital, progresso, aulas, redações, flashcards."""

from __future__ import annotations

import json
import os
import sqlite3
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent


def _resolve_data_dir() -> Path:
    """Uma pasta canônica: PAES_DATA_DIR (launcher) → senão <repo|pacote>/data."""
    override = (os.getenv("PAES_DATA_DIR") or os.getenv("PAES_MED_AI_DATA") or "").strip().strip('"')
    if override:
        return Path(override).expanduser().resolve()
    return (ROOT / "data").resolve()


DATA_DIR = _resolve_data_dir()
DB_PATH = DATA_DIR / "paes_med_ai.db"


def connect() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    conn = connect()
    try:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS syllabus (
                id TEXT PRIMARY KEY,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                subtopic TEXT,
                weight REAL DEFAULT 1.0
            );

            CREATE TABLE IF NOT EXISTS questions (
                id TEXT PRIMARY KEY,
                year INTEGER NOT NULL,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                subtopic TEXT,
                statement TEXT NOT NULL,
                options_json TEXT NOT NULL,
                correct_index INTEGER NOT NULL,
                difficulty TEXT NOT NULL,
                tags_json TEXT DEFAULT '[]',
                syllabus_id TEXT,
                source TEXT DEFAULT 'treino',
                resolution TEXT,
                banca_intent TEXT,
                macete TEXT,
                pegadinha TEXT,
                related_topics_json TEXT DEFAULT '[]',
                keywords_json TEXT DEFAULT '[]',
                statement_verbs_json TEXT DEFAULT '[]',
                has_graph INTEGER DEFAULT 0,
                has_table INTEGER DEFAULT 0,
                has_image INTEGER DEFAULT 0,
                avg_text_len INTEGER DEFAULT 0,
                generated INTEGER DEFAULT 0,
                exam_board TEXT DEFAULT 'TREINO',
                similarity_of TEXT,
                similarity_note TEXT,
                FOREIGN KEY (syllabus_id) REFERENCES syllabus(id)
            );

            CREATE TABLE IF NOT EXISTS answers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                question_id TEXT NOT NULL,
                correct INTEGER NOT NULL,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                error_type TEXT,
                time_ms INTEGER,
                answered_at TEXT NOT NULL,
                FOREIGN KEY (question_id) REFERENCES questions(id)
            );

            CREATE TABLE IF NOT EXISTS revisions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                next_due TEXT NOT NULL,
                interval_days INTEGER NOT NULL,
                reviews INTEGER DEFAULT 0,
                UNIQUE(subject, topic)
            );

            CREATE TABLE IF NOT EXISTS study_plan (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                plan_days INTEGER NOT NULL,
                day_index INTEGER NOT NULL,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                reason TEXT,
                done INTEGER DEFAULT 0,
                UNIQUE(plan_days, day_index, subject, topic)
            );

            CREATE TABLE IF NOT EXISTS lessons (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                source_type TEXT NOT NULL,
                source_ref TEXT,
                transcript TEXT,
                subject TEXT,
                topic TEXT,
                difficulty TEXT,
                summary TEXT,
                macetes_json TEXT DEFAULT '[]',
                keywords_json TEXT DEFAULT '[]',
                flashcards_json TEXT DEFAULT '[]',
                questions_json TEXT DEFAULT '[]',
                incidence_note TEXT,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS essays (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                theme TEXT NOT NULL,
                text TEXT NOT NULL,
                score REAL,
                feedback_json TEXT,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS flashcards (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                front TEXT NOT NULL,
                back TEXT NOT NULL,
                subject TEXT,
                topic TEXT,
                source TEXT,
                next_due TEXT,
                reviews INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS ingest_jobs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT NOT NULL,
                kind TEXT NOT NULL,
                status TEXT NOT NULL,
                message TEXT,
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS session_checkpoint (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                payload_json TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );

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
            );
            """
        )
        # Migrações leves (colunas novas sem quebrar DB existente)
        cols = {r[1] for r in conn.execute("PRAGMA table_info(questions)").fetchall()}
        if "approved" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN approved INTEGER DEFAULT 1")
            # Questões geradas ficam pendentes até revisão humana
            conn.execute("UPDATE questions SET approved=0 WHERE generated=1")
        if "exam_board" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN exam_board TEXT DEFAULT 'TREINO'")
        if "similarity_of" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN similarity_of TEXT")
        if "similarity_note" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN similarity_note TEXT")
        # Backfill banca a partir da fonte
        conn.execute(
            """
            UPDATE questions SET exam_board='UEMA_PAES'
            WHERE COALESCE(exam_board,'') IN ('', 'TREINO')
              AND COALESCE(generated,0)=0
              AND (
                LOWER(COALESCE(source,'')) LIKE '%pdf%'
                OR LOWER(COALESCE(source,'')) LIKE '%oficial%'
                OR LOWER(COALESCE(source,'')) LIKE '%ingest%'
              )
            """
        )
        conn.execute(
            """
            UPDATE questions SET exam_board='TREINO'
            WHERE exam_board IS NULL OR TRIM(exam_board)=''
            """
        )
        conn.commit()
    finally:
        conn.close()


def row_to_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    if row is None:
        return None
    return dict(row)


def loads_json(value: str | None, default: Any) -> Any:
    if not value:
        return default
    return json.loads(value)
