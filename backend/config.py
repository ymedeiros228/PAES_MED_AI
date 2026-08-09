"""Configuracao lida do ambiente (backend/.env)."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

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
LOCAL_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1|\[::1\]|10\.0\.2\.2)(:\d+)?$"

EXTRA_ORIGINS = [o.strip() for o in os.getenv("PAES_ALLOWED_ORIGINS", "").split(",") if o.strip()]

MAX_UPLOAD_BYTES = int(os.getenv("PAES_MAX_UPLOAD_MB", "50")) * 1024 * 1024
