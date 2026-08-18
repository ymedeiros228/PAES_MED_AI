# -*- mode: python ; coding: utf-8 -*-
"""Spec PyInstaller para o backend PAES MED AI.

Gera `paes_backend.exe` (modo onedir) com Python + todas as dependencias
embutidas. O cliente nao precisa instalar Python nem pip install.

Build:
    cd backend
    ..\\backend\\venv\\Scripts\\python.exe -m PyInstaller paes_backend.spec --noconfirm

Saida:
    backend/dist/paes_backend/paes_backend.exe
    backend/dist/paes_backend/_internal/   (deps + modulos)

Dados (SQLite, PDFs, edital) ficam FORA do exe, em PAES_DATA_DIR,
definido pelo launcher Flutter ao subir o processo.
"""

from PyInstaller.utils.hooks import collect_all, collect_submodules

# --- Coleta completa de pacotes com modulos/imports dinamicos ---
# uvicorn: carrega loops/protocols/lifespan dinamicamente por string.
# fastapi/pydantic: usam introspeccao e plugins de validacao.
# aiosqlite: importa drivers sqlite async sob demanda.
# pypdf: plugins de criptografia/criba lazy.
# python-multipart: parsers de form-data carregados dinamicamente.
# openai: usa httpx + introspeccao de modelos.
_PACKAGES = [
    "uvicorn",
    "fastapi",
    "pydantic",
    "pydantic_core",
    "aiosqlite",
    "pypdf",
    "multipart",
    "openai",
    "httpx",
    "dotenv",
]

datas: list = []
binaries: list = []
hiddenimports: list = []

for pkg in _PACKAGES:
    d, b, h = collect_all(pkg)
    datas += d
    binaries += b
    hiddenimports += h

# uvicorn[standard] usa estes submodulos carregados por nome em runtime.
hiddenimports += collect_submodules("uvicorn")
hiddenimports += [
    "uvicorn.loops.auto",
    "uvicorn.loops.asyncio",
    "uvicorn.protocols.http.auto",
    "uvicorn.protocols.http.h11_impl",
    "uvicorn.protocols.websockets.auto",
    "uvicorn.protocols.websockets.wsproto_impl",
    "uvicorn.lifespan.on",
    "uvicorn.lifespan.off",
    "uvicorn.logging",
    "httptools",
    "websockets",
    "email.mime.multipart",
    "email.mime.text",
]

# Modulos do proprio backend (nao sao pacotes instalados, sao .py locais).
# PyInstaller os descobre via analise estatica do import chain a partir de
# paes_backend_entry.py -> main.py -> routers/* -> services_*.py etc.
# Mas alguns sao importados lazy (dentro de funcoes), entao listamos explicitos.
hiddenimports += [
    "main",
    "config",
    "db",
    "seed",
    "seed_expand",
    "schemas",
    "timeutil",
    "text_utils",
    "ai_state",
    "api_helpers",
    "material_service",
    "ingest_pdf",
    "bootstrap_prod",
    "services_core",
    "services_advanced",
    "services_edital",
    "services_extra",
    "services_media",
    "wiki_images",
    "routers.ai",
    "routers.essays",
    "routers.flashcards",
    "routers.ingest",
    "routers.library",
    "routers.materials",
    "routers.media",
    "routers.meta",
    "routers.questions",
    "routers.simulations",
    "routers.stats",
    "routers.study",
]

a = Analysis(
    ["paes_backend_entry.py"],
    pathex=["."],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    runtime_hooks=[],
    excludes=[
        # Nao usados em runtime pelo servidor (apenas em scripts de geracao).
        "reportlab",
        "PIL",
        "pytesseract",
        "pdf2image",
        "matplotlib",
        "numpy",
        "pandas",
        "tkinter",
        "pytest",
    ],
    noarchive=False,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="paes_backend",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,  # console=False: roda silencioso em background
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="paes_backend",
)
