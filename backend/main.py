"""PAES MED AI — API local (FastAPI + SQLite + OpenAI opcional)."""

from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import EXTRA_ORIGINS, LOCAL_ORIGIN_REGEX
from db import DATA_DIR, init_db
from routers import (
    ai,
    essays,
    flashcards,
    ingest,
    library,
    media,
    meta,
    questions,
    simulations,
    stats,
    study,
)
from seed import seed

app = FastAPI(title="PAES MED AI API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=EXTRA_ORIGINS,
    allow_origin_regex=LOCAL_ORIGIN_REGEX,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

for module in (
    meta,
    questions,
    stats,
    study,
    simulations,
    ingest,
    library,
    media,
    essays,
    flashcards,
    ai,
):
    app.include_router(module.router)


@app.on_event("startup")
def on_startup() -> None:
    for sub in ("provas", "gabaritos", "edital", "aulas", "backups", "inventory"):
        (DATA_DIR / sub).mkdir(parents=True, exist_ok=True)
    init_db()
    seed(force=False)
    try:
        from services_advanced import index_all_questions

        index_all_questions(limit=300)
    except Exception:
        pass
