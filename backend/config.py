"""Configuracao lida do ambiente (backend/.env)."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Em PyInstaller (frozen), sys._MEIPASS aponta para _internal/ onde o .env
# foi copiado via spec datas. Em dev, usa o diretorio do proprio config.py.
if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
    BASE_DIR = Path(sys._MEIPASS)
else:
    BASE_DIR = Path(__file__).resolve().parent

# Carrega .env do PAES_DATA_DIR (gravavel) primeiro, depois do BASE_DIR (bundle).
# Isso permite que o usuario configure suas proprias chaves em PAES_DATA_DIR/.env
# sem precisar escrever no bundle (que pode ser read-only em Program Files).
_data_dir = os.getenv("PAES_DATA_DIR", "").strip().strip('"')
if _data_dir and Path(_data_dir).is_dir():
    load_dotenv(Path(_data_dir) / ".env", override=True)
# Carrega o .env do bundle (chaves pre-configuradas do desenvolvedor).
load_dotenv(BASE_DIR / ".env", override=False)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1-mini").strip()
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile").strip()
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "").strip()
OPENROUTER_MODEL = os.getenv("OPENROUTER_MODEL", "").strip()
try:
    OPENAI_TIMEOUT_SECONDS = max(5.0, float(os.getenv("OPENAI_TIMEOUT_SECONDS", "45")))
except ValueError:
    OPENAI_TIMEOUT_SECONDS = 45.0

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "").strip()
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3-flash-preview").strip()

# Origens locais (app desktop, Flutter web em porta aleatoria, emulador Android).
# Sites externos abertos no navegador do usuario nao podem falar com a API local.
# Em producao (web), set PAES_ALLOWED_ORIGINS=https://seu-site.vercel.app
LOCAL_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1|\[::1\]|10\.0\.2\.2)(:\d+)?$"

EXTRA_ORIGINS = [o.strip() for o in os.getenv("PAES_ALLOWED_ORIGINS", "").split(",") if o.strip()]

# Em deploy unificado (Render), o mesmo servidor serve front + API — permitir mesma origin.
RENDER_EXTERNAL_URL = os.getenv("RENDER_EXTERNAL_URL", "").strip()
if RENDER_EXTERNAL_URL:
    EXTRA_ORIGINS.append(RENDER_EXTERNAL_URL)

MAX_UPLOAD_BYTES = int(os.getenv("PAES_MAX_UPLOAD_MB", "50")) * 1024 * 1024
