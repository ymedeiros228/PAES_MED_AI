"""Banco do app — questões, edital, progresso, aulas, redações, flashcards.

Dois motores, a mesma interface (a do sqlite3):
- SQLite local (desktop, testes): padrão quando DATABASE_URL está vazio.
- Postgres (Supabase, versão web no Vercel): quando DATABASE_URL aponta para postgres.
  O SQL do app é escrito no dialeto do SQLite; ``_pg_sql`` traduz o pouco que difere.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import threading
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from datetime import date, datetime
from functools import lru_cache
from pathlib import Path
from typing import Any

import config  # noqa: F401  (carrega o backend/.env antes de ler DATABASE_URL)

ROOT = Path(__file__).resolve().parent.parent


def _resolve_data_dir() -> Path:
    """Uma pasta canônica: PAES_DATA_DIR (launcher) → senão <repo|pacote>/data."""
    override = (os.getenv("PAES_DATA_DIR") or os.getenv("PAES_MED_AI_DATA") or "").strip().strip('"')
    if override:
        return Path(override).expanduser().resolve()
    return (ROOT / "data").resolve()


DATA_DIR = _resolve_data_dir()
DB_PATH = DATA_DIR / "paes_med_ai.db"

DATABASE_URL = (os.getenv("DATABASE_URL") or "").strip()
USE_PG = DATABASE_URL.startswith(("postgres://", "postgresql://"))

# Tabelas com id numérico automático (INSERT precisa de RETURNING id para o lastrowid).
_AUTO_ID_TABLES = {
    "answers", "revisions", "study_plan", "essays", "flashcards",
    "ingest_jobs", "study_gaps",
}
# Chave usada no lugar do INSERT OR REPLACE do SQLite.
_PRIMARY_KEYS = {
    "questions": "id", "materials": "id", "syllabus": "id", "settings": "key",
    "lessons": "id", "ingest_previews": "id", "embeddings": "ref_type, ref_id",
}


# --------------------------------------------------------------------------- SQLite


def _sqlite_connect() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH, timeout=30.0)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


# --------------------------------------------------------------------------- Postgres


class PgRow:
    """Linha com a mesma cara do sqlite3.Row: r[0], r["col"], keys(), dict(r)."""

    __slots__ = ("_cols", "_vals")

    def __init__(self, cols: dict[str, int], vals: Sequence[Any]) -> None:
        self._cols = cols
        self._vals = vals

    def __getitem__(self, key: int | str) -> Any:
        if isinstance(key, str):
            return self._vals[self._cols[key]]
        return self._vals[key]

    def keys(self) -> list[str]:
        return list(self._cols)

    def __iter__(self) -> Iterator[Any]:
        return iter(self._vals)

    def __len__(self) -> int:
        return len(self._vals)

    def __repr__(self) -> str:
        return f"PgRow({dict(zip(self._cols, self._vals, strict=True))!r})"


def _pg_row_factory(cursor: Any) -> Any:
    desc = cursor.description or []
    cols = {d.name: i for i, d in enumerate(desc)}

    def make(values: Sequence[Any]) -> PgRow:
        return PgRow(cols, values)

    return make


_INSERT_OR = re.compile(r"^\s*INSERT\s+OR\s+(REPLACE|IGNORE)\s+INTO\s+(\w+)\s*\(([^)]*)\)", re.I | re.S)
_INSERT_INTO = re.compile(r"^\s*INSERT\s+INTO\s+(\w+)", re.I)
_SKIP = re.compile(r"^\s*(PRAGMA|CREATE\s+(TABLE|INDEX|UNIQUE\s+INDEX)\s+IF\s+NOT\s+EXISTS)\b", re.I)


def _placeholders(sql: str) -> str:
    """? → %s e % → %% (fora de strings), como o psycopg espera."""
    out: list[str] = []
    in_str = False
    for ch in sql:
        if ch == "'":
            in_str = not in_str
            out.append(ch)
        elif ch == "%":
            out.append("%%")
        elif ch == "?" and not in_str:
            out.append("%s")
        else:
            out.append(ch)
    return "".join(out)


@lru_cache(maxsize=1024)
def _pg_sql(sql: str) -> tuple[str | None, bool]:
    """Traduz SQL do dialeto SQLite. Devolve (sql, precisa_returning_id); sql=None = ignorar."""
    if _SKIP.match(sql):
        # Esquema e PRAGMA vivem na migração (scripts/migrar_para_postgres.py), não no runtime.
        return None, False
    returning = False
    m = _INSERT_OR.match(sql)
    if m:
        kind, table, cols = m.group(1).upper(), m.group(2), m.group(3)
        sql = sql[: m.start()] + f"INSERT INTO {table} ({cols})" + sql[m.end():]
        if kind == "IGNORE":
            sql = sql.rstrip().rstrip(";") + " ON CONFLICT DO NOTHING"
        else:
            key = _PRIMARY_KEYS.get(table.lower(), "id")
            keys = {k.strip() for k in key.split(",")}
            sets = ", ".join(
                f"{c.strip()}=EXCLUDED.{c.strip()}" for c in cols.split(",") if c.strip() and c.strip() not in keys
            )
            sql = sql.rstrip().rstrip(";") + f" ON CONFLICT ({key}) DO UPDATE SET {sets}"
    else:
        m = _INSERT_INTO.match(sql)
        if m and m.group(1).lower() in _AUTO_ID_TABLES and "RETURNING" not in sql.upper():
            sql = sql.rstrip().rstrip(";") + " RETURNING id"
            returning = True
    # LIKE do SQLite ignora maiúsculas; no Postgres o equivalente é ILIKE.
    sql = re.sub(r"\bLIKE\b", "ILIKE", sql, flags=re.I)
    return _placeholders(sql), returning


def _pg_param(value: Any) -> Any:
    # O SQLite grava bool como 0/1 e datetime como texto; as colunas aqui são as mesmas.
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, datetime):
        return value.isoformat(" ")
    if isinstance(value, date):
        return value.isoformat()
    return value


class PgCursor:
    """Resultado de execute(): fetchone/fetchall/rowcount/lastrowid como no sqlite3."""

    def __init__(self, cur: Any = None, lastrowid: int | None = None) -> None:
        self._cur = cur
        self.lastrowid = lastrowid
        self.rowcount = cur.rowcount if cur is not None else 0

    def fetchone(self) -> Any:
        if self._cur is None or self._cur.description is None:
            return None
        return self._cur.fetchone()

    def fetchall(self) -> list[Any]:
        if self._cur is None or self._cur.description is None:
            return []
        return self._cur.fetchall()

    def __iter__(self) -> Iterator[Any]:
        return iter(self.fetchall())


class PgConnection:
    """Conexão Postgres com a interface que o app usa do sqlite3.Connection."""

    def __init__(self, raw: Any) -> None:
        self._raw = raw

    def execute(self, sql: str, params: Sequence[Any] | None = None) -> PgCursor:
        translated, returning = _pg_sql(sql)
        if translated is None:
            return PgCursor()
        cur = self._raw.cursor(row_factory=_pg_row_factory)
        # Sempre uma lista (mesmo vazia): com None o psycopg não converteria %% de volta em %.
        cur.execute(translated, [_pg_param(p) for p in params] if params else [])
        lastrowid = None
        if returning:
            row = cur.fetchone()
            lastrowid = row[0] if row else None
        return PgCursor(cur, lastrowid)

    def executemany(self, sql: str, seq: Sequence[Sequence[Any]]) -> PgCursor:
        translated, _ = _pg_sql(sql)
        if translated is None:
            return PgCursor()
        cur = self._raw.cursor()
        cur.executemany(translated.replace(" RETURNING id", ""), [[_pg_param(p) for p in ps] for ps in seq])
        return PgCursor(cur)

    def executescript(self, script: str) -> None:
        for stmt in script.split(";"):
            if stmt.strip():
                self.execute(stmt)

    def commit(self) -> None:
        self._raw.commit()

    def rollback(self) -> None:
        self._raw.rollback()

    def close(self) -> None:
        pass  # quem devolve a conexão ao pool é db()


_pool: Any = None
_pool_lock = threading.Lock()


def _pg_pool() -> Any:
    """Pool pequeno: a função do Vercel reaproveita conexões entre requisições."""
    global _pool
    if _pool is None:
        with _pool_lock:
            if _pool is None:
                from psycopg.types.numeric import FloatLoader
                from psycopg_pool import ConnectionPool

                def _configure(conn: Any) -> None:
                    # AVG/SUM/ROUND voltam como numeric → float, como no SQLite.
                    conn.adapters.register_loader("numeric", FloatLoader)
                    # BEGIN READ WRITE em toda transação: no pooler de transação um
                    # SET de sessão de outro cliente pode vazar para esta conexão.
                    conn.read_only = False

                _pool = ConnectionPool(
                    DATABASE_URL,
                    min_size=0,
                    max_size=int(os.getenv("PAES_PG_POOL", "4")),
                    # prepare_threshold=None: obrigatório no pooler de transação do Supabase.
                    kwargs={"prepare_threshold": None, "connect_timeout": 10},
                    configure=_configure,
                    check=ConnectionPool.check_connection,
                    open=True,
                )
    return _pool


# --------------------------------------------------------------------------- interface pública


def connect() -> Any:
    """Conexão avulsa (quem chama fecha). Prefira ``with db() as conn``."""
    if USE_PG:
        import psycopg
        from psycopg.types.numeric import FloatLoader

        raw = psycopg.connect(DATABASE_URL, prepare_threshold=None, connect_timeout=10)
        raw.adapters.register_loader("numeric", FloatLoader)
        raw.read_only = False
        conn = PgConnection(raw)
        conn.close = raw.close  # type: ignore[method-assign]
        return conn
    return _sqlite_connect()


@contextmanager
def db() -> Iterator[Any]:
    """Conexão com fechamento garantido: `with db() as conn:`."""
    if USE_PG:
        with _pg_pool().connection() as raw:
            conn = PgConnection(raw)
            yield conn
            # Como no sqlite3: o que não teve commit() explícito é descartado.
            raw.rollback()
        return
    conn = _sqlite_connect()
    try:
        yield conn
    finally:
        conn.close()


# Contas de acesso da versão web (auth.py). No Postgres do Vercel o init_db não roda:
# a tabela é criada pelo scripts/criar_usuario.py.
SQL_USUARIOS = """
    CREATE TABLE IF NOT EXISTS usuarios (
        usuario TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        senha_hash TEXT NOT NULL,
        papel TEXT NOT NULL DEFAULT 'aluno',
        criado_em TEXT NOT NULL,
        ultimo_acesso TEXT,
        falhas INTEGER NOT NULL DEFAULT 0,
        bloqueado_ate TEXT
    )
"""


def init_db() -> None:
    if USE_PG:
        return  # o esquema no Postgres é criado pela migração, não a cada partida
    with db() as conn:
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
                passage TEXT,
                figures_json TEXT DEFAULT '[]',
                number INTEGER,
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

            CREATE TABLE IF NOT EXISTS materials (
                id TEXT PRIMARY KEY,
                subject TEXT NOT NULL,
                topic TEXT NOT NULL,
                subtopic TEXT,
                title TEXT NOT NULL,
                content_json TEXT NOT NULL,
                images_json TEXT DEFAULT '[]',
                wiki_url TEXT,
                generated_at TEXT NOT NULL,
                approved INTEGER DEFAULT 0,
                UNIQUE(subject, topic, subtopic)
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
        conn.execute(SQL_USUARIOS)
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
        # Prova oficial reextraída do caderno: texto-base (compartilhado por várias
        # questões), figuras recortadas do PDF e o número da questão na prova.
        if "passage" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN passage TEXT")
        if "figures_json" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN figures_json TEXT DEFAULT '[]'")
        if "number" not in cols:
            conn.execute("ALTER TABLE questions ADD COLUMN number INTEGER")
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
        # Índices para acelerar consultas frequentes (listagens, filtros, dashboards).
        # CREATE INDEX IF NOT EXISTS é idempotente — seguro rodar a cada startup.
        conn.executescript(
            """
            CREATE INDEX IF NOT EXISTS idx_questions_subject_topic
                ON questions(subject, topic);
            CREATE INDEX IF NOT EXISTS idx_questions_year
                ON questions(year);
            CREATE INDEX IF NOT EXISTS idx_questions_exam_board
                ON questions(exam_board);
            CREATE INDEX IF NOT EXISTS idx_questions_approved
                ON questions(approved);
            CREATE INDEX IF NOT EXISTS idx_answers_question_id
                ON answers(question_id);
            CREATE INDEX IF NOT EXISTS idx_answers_answered_at
                ON answers(answered_at);
            CREATE INDEX IF NOT EXISTS idx_answers_subject_topic
                ON answers(subject, topic);
            CREATE INDEX IF NOT EXISTS idx_revisions_next_due
                ON revisions(next_due);
            CREATE INDEX IF NOT EXISTS idx_flashcards_next_due
                ON flashcards(next_due);
            CREATE INDEX IF NOT EXISTS idx_study_plan_plan_day
                ON study_plan(plan_days, day_index);
            CREATE INDEX IF NOT EXISTS idx_study_gaps_status
                ON study_gaps(status);
            CREATE INDEX IF NOT EXISTS idx_lessons_subject_topic
                ON lessons(subject, topic);
            CREATE INDEX IF NOT EXISTS idx_essays_created_at
                ON essays(created_at);
            CREATE INDEX IF NOT EXISTS idx_ingest_jobs_status
                ON ingest_jobs(status);
            CREATE INDEX IF NOT EXISTS idx_materials_subject_topic
                ON materials(subject, topic);
            """
        )
        conn.commit()


def row_to_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    if row is None:
        return None
    return dict(row)


def loads_json(value: str | None, default: Any) -> Any:
    if not value:
        return default
    return json.loads(value)
