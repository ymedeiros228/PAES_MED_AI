"""Mantém a suíte local determinística, sem credenciais do ambiente do executor."""

import os

# Define como string vazia (em vez de remover): o config.py roda
# load_dotenv(override=False), que recarregaria as chaves reais do backend/.env
# se a variável não existisse — e os testes passariam a chamar as APIs de verdade.
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
    os.environ[_name] = ""

# Sem PAES_DATA_DIR, nenhum teste lê ou grava o .env de dados do usuário.
os.environ.pop("PAES_DATA_DIR", None)
