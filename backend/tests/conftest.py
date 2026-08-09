"""Mantém a suíte local determinística, sem credenciais do ambiente do executor."""

import os

for _name in (
    "OPENAI_API_KEY",
    "OPENAI_MODEL",
    "GEMINI_API_KEY",
    "GEMINI_MODEL",
    "GROQ_API_KEY",
    "GROQ_MODEL",
    "OPENROUTER_API_KEY",
    "OPENROUTER_MODEL",
):
    os.environ.pop(_name, None)
