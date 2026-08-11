"""PAES MED AI — API local (FastAPI + SQLite + OpenAI opcional)."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

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
# Comprime respostas JSON > 1KB — listas de questões/respostas ficam 70-80% menores.
app.add_middleware(GZipMiddleware, minimum_size=1000)
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
    # Em produção (Render), ingere PDFs oficiais se o banco estiver vazio
    if os.getenv("PAES_BOOTSTRAP_PROD", "").strip().lower() in ("1", "true", "yes"):
        try:
            from bootstrap_prod import bootstrap_production

            bootstrap_production()
        except Exception as exc:
            print(f"Bootstrap prod falhou (não fatal): {exc}")
    else:
        try:
            from services_advanced import index_all_questions

            index_all_questions(limit=300, allow_remote=False)
        except Exception:
            pass


# --- Servir front web (deploy unificado) ---
# Se a pasta build/web existir ao lado do backend, serve o app Flutter compilado.
# Em desenvolvimento web, o flutter run usa sua própria porta; em produção (Render),
# este mount permite que o mesmo servidor entregue API + front.
_WEB_BUILD = Path(__file__).resolve().parent.parent / "build" / "web"
if _WEB_BUILD.is_dir():
    # Assets do Flutter (main.dart.js, ícones, etc.) sob /assets
    app.mount("/assets", StaticFiles(directory=str(_WEB_BUILD / "assets")), name="flutter-assets")
    # Arquivos soltos na raiz do build web (manifest.json, favicon, etc.)
    for _f in _WEB_BUILD.iterdir():
        if _f.is_file():
            _rel = _f.name

            def _make_static(name: str, fpath: Path) -> Any:
                def _serve() -> FileResponse:
                    return FileResponse(str(fpath))

                _serve.__name__ = f"_serve_{name.replace('.', '_')}"
                return _serve

            app.add_api_route(f"/{_rel}", _make_static(_rel, _f), methods=["GET"], include_in_schema=False)

    @app.get("/{full_path:path}")
    def spa_fallback(full_path: str) -> FileResponse:
        """SPA fallback: qualquer rota não-API retorna index.html (go_router cuida)."""
        return FileResponse(str(_WEB_BUILD / "index.html"))

