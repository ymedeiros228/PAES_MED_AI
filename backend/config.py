"""Configuracao lida do ambiente (backend/.env)."""

from __future__ import annotations

import os

from dotenv import load_dotenv

load_dotenv()

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()

OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1-mini").strip()

# Origens locais (app desktop, Flutter web em porta aleatoria, emulador Android).
# Sites externos abertos no navegador do usuario nao podem falar com a API local.
LOCAL_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1|\[::1\]|10\.0\.2\.2)(:\d+)?$"

EXTRA_ORIGINS = [o.strip() for o in os.getenv("PAES_ALLOWED_ORIGINS", "").split(",") if o.strip()]

MAX_UPLOAD_BYTES = int(os.getenv("PAES_MAX_UPLOAD_MB", "50")) * 1024 * 1024
