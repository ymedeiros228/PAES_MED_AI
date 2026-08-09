"""Mantém a suíte local determinística, sem credenciais do ambiente do executor."""

import os

for _name in ("OPENAI_API_KEY", "GEMINI_API_KEY", "GEMINI_MODEL"):
    os.environ.pop(_name, None)
