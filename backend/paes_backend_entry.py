"""Entry point para PyInstaller — roda o backend FastAPI via uvicorn.

Este modulo e o alvo do `pyinstaller`. Ele garante que, quando congelado,
o diretorio do exe esteja no sys.path para que os modulos do backend
(config, db, routers, seed, services_*, etc.) sejam importaveis.

Uso (dev):
    python paes_backend_entry.py

Uso (frozen):
    paes_backend.exe   # host=127.0.0.1 port=8000 (defaults)
    paes_backend.exe --host 127.0.0.1 --port 8000

Variaveis de ambiente:
    PAES_DATA_DIR       -> pasta de dados (SQLite, PDFs, edital)
    PAES_BACKEND_HOST   -> host (default 127.0.0.1)
    PAES_BACKEND_PORT   -> porta (default 8000)
    OPENAI_API_KEY etc. -> lidos por config.py / ai_state.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Quando congelado pelo PyInstaller, sys.executable aponta para o exe
# e os modulos .py do backend sao empacotados dentro do bundle. Adicionamos
# o diretorio do exe ao sys.path para que imports como `from config import ...`
# e `from routers import ...` funcionem tanto em dev quanto frozen.
if getattr(sys, "frozen", False):
    _exe_dir = Path(sys.executable).resolve().parent
    sys.path.insert(0, str(_exe_dir))
else:
    # Em dev, garante que o diretorio deste arquivo esta no path.
    _here = Path(__file__).resolve().parent
    sys.path.insert(0, str(_here))

import uvicorn  # noqa: E402

from main import app  # noqa: E402


def _parse_args() -> tuple[str, int]:
    """Host/porta via CLI (--host/--port) ou env (PAES_BACKEND_HOST/PORT)."""
    host = os.getenv("PAES_BACKEND_HOST", "127.0.0.1")
    port = int(os.getenv("PAES_BACKEND_PORT", "8000"))
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        a = args[i]
        if a in ("--host", "-h") and i + 1 < len(args):
            host = args[i + 1]
            i += 2
            continue
        if a in ("--port", "-p") and i + 1 < len(args):
            try:
                port = int(args[i + 1])
            except ValueError:
                pass
            i += 2
            continue
        i += 1
    return host, port


def main() -> int:
    host, port = _parse_args()
    # log_level info para diagnosticar problemas no cliente; sem access_log
    # para nao poluir o log com cada requisicao.
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        access_log=False,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
