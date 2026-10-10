"""PAES MED AI — API local (FastAPI + SQLite + OpenAI opcional)."""

from __future__ import annotations

import logging
import os
import sys
import threading
import time
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import datetime
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from config import EXTRA_ORIGINS, LOCAL_ORIGIN_REGEX
from db import DATA_DIR, init_db
from routers import (
    ai,
    essays,
    flashcards,
    ingest,
    library,
    materials,
    media,
    meta,
    questions,
    simulations,
    stats,
    study,
)
from seed import seed


_log = logging.getLogger("paes.startup")


def _setup_logging() -> None:
    """Log do backend em DATA_DIR/logs/paes_backend.log (rotativo, 1 MB x 3).

    Idempotente: reimportar main (testes) não duplica handlers.
    """
    root = logging.getLogger("paes")
    if getattr(root, "_paes_configured", False):
        return
    root.setLevel(logging.INFO)
    fmt = logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
    try:
        log_dir = DATA_DIR / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)
        fh = RotatingFileHandler(
            log_dir / "paes_backend.log", maxBytes=1_000_000, backupCount=3, encoding="utf-8"
        )
        fh.setFormatter(fmt)
        root.addHandler(fh)
    except OSError:
        # Pasta de dados somente-leitura: segue só com stderr.
        pass
    if sys.stderr is not None:  # PyInstaller sem console pode não ter stderr
        sh = logging.StreamHandler()
        sh.setFormatter(fmt)
        root.addHandler(sh)
    root._paes_configured = True  # type: ignore[attr-defined]


def _env_flag(name: str, default: str = "") -> bool:
    return os.getenv(name, default).strip().lower() in ("1", "true", "yes")


def _startup_heavy() -> None:
    """Trabalho pesado do startup (índice RAG, sanitize, backup diário).

    Roda em thread de background para a API ficar disponível na hora; cada
    etapa é independente e uma falha só é registrada no log (não é fatal).
    """
    started = time.perf_counter()
    # Em produção (Render), ingere PDFs oficiais se o banco estiver vazio
    if _env_flag("PAES_BOOTSTRAP_PROD"):
        try:
            from bootstrap_prod import bootstrap_production

            bootstrap_production()
        except Exception:
            _log.exception("Bootstrap prod falhou (não fatal)")
    else:
        try:
            from services_advanced import index_all_questions

            index_all_questions(limit=300, allow_remote=False)
        except Exception:
            _log.exception("Indexação local das questões falhou (não fatal)")

    # Limpa rodapé/cabeçalho PDF colado em alternativas (banco antigo do instalador)
    if not _env_flag("PAES_SKIP_OPTION_SANITIZE"):
        try:
            from ingest_pdf import sanitize_questions_full

            cleaned = sanitize_questions_full()
            _log.info(
                "Sanitize opções/enunciados: stmts=%s opts=%s",
                cleaned.get("statements", 0),
                cleaned.get("options", 0),
            )
        except Exception:
            _log.exception("Sanitize opções falhou (não fatal)")

    # Backup automático do progresso do usuário (apenas desktop, nao no Render)
    if _env_flag("PAES_AUTO_BACKUP", "1"):
        try:
            from services_extra import create_backup, last_backup_status

            bk = last_backup_status()
            needs_backup = True
            if bk.get("ok"):
                at = bk.get("at") or bk.get("createdAt") or bk.get("timestamp")
                if at:
                    try:
                        dt = datetime.fromisoformat(str(at).replace("Z", ""))
                        needs_backup = (datetime.now() - dt).days >= 1
                    except ValueError:
                        _log.warning("Data do último backup ilegível (%r); refazendo backup", at)
                        needs_backup = True
            if needs_backup:
                result = create_backup()
                _log.info("Backup automático: %s | ok=%s", result.get("path"), result.get("ok"))
        except Exception:
            _log.exception("Backup automático falhou (não fatal)")
    _log.info("Tarefas de startup em background concluídas em %.1fs", time.perf_counter() - started)


_startup_thread: threading.Thread | None = None


def _run_startup() -> None:
    """Startup rápido (pastas, schema, seed) + tarefas pesadas em background.

    PAES_STARTUP_SYNC=1 roda tudo de forma síncrona (testes/diagnóstico).
    """
    global _startup_thread
    _setup_logging()
    for sub in ("provas", "gabaritos", "edital", "aulas", "backups", "inventory"):
        (DATA_DIR / sub).mkdir(parents=True, exist_ok=True)
    init_db()
    seed(force=False)
    if _env_flag("PAES_STARTUP_SYNC"):
        _startup_heavy()
        return
    _startup_thread = threading.Thread(target=_startup_heavy, name="paes-startup", daemon=True)
    _startup_thread.start()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    _run_startup()
    yield


app = FastAPI(title="PAES MED AI API", version="1.0.0", lifespan=lifespan)
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
    materials,
    ai,
):
    app.include_router(module.router)


# --- Servir front web (deploy unificado) ---
# Se a pasta build/web existir, serve o app Flutter compilado.
# Em desenvolvimento: <repo>/build/web. Em Docker: <backend>/build/web.
_REPO_WEB = Path(__file__).resolve().parent.parent / "build" / "web"
_BACKEND_WEB = Path(__file__).resolve().parent / "build" / "web"
_WEB_BUILD = _REPO_WEB if _REPO_WEB.is_dir() else _BACKEND_WEB
if _WEB_BUILD.is_dir():
    # Diretórios estáticos do Flutter web
    for _subdir in ("assets", "canvaskit", "icons"):
        _subdir_path = _WEB_BUILD / _subdir
        if _subdir_path.is_dir():
            app.mount(f"/{_subdir}", StaticFiles(directory=str(_subdir_path)), name=f"flutter-{_subdir}")
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
        # Rotas de API não encontradas devolvem JSON 404, não HTML
        if full_path.startswith("api/") or full_path in ("health", "docs", "openapi.json"):
            from fastapi import HTTPException

            raise HTTPException(404, f"Endpoint não encontrado: /{full_path}")
        return FileResponse(str(_WEB_BUILD / "index.html"))

