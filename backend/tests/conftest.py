"""Mantém a suíte local determinística, sem credenciais do ambiente do executor.

Também isola os DADOS: antes, a suíte rodava contra o ``data/`` real do
repositório (o lifespan do TestClient executa sanitize/índice/backup e alguns
testes gravam em ``data/provas``). Agora cada sessão de testes trabalha numa
cópia temporária do banco + pastas pequenas, apontada por PAES_DATA_DIR.
"""

import atexit
import os
import shutil
import sqlite3
import tempfile
from pathlib import Path

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

# Nunca gerar zip de backup durante os testes (o startup faria 1x por dia).
os.environ["PAES_AUTO_BACKUP"] = "0"
# Startup síncrono nos testes: evita a thread de background disputando o banco.
os.environ["PAES_STARTUP_SYNC"] = "1"
# Nunca o Postgres de produção: a suíte usa a cópia SQLite abaixo. Para rodar contra um
# Postgres de TESTE, defina PAES_TEST_DATABASE_URL (esquema descartável).
os.environ["DATABASE_URL"] = os.environ.get("PAES_TEST_DATABASE_URL", "")
os.environ.pop("VERCEL", None)

_REAL_DATA = Path(__file__).resolve().parents[2] / "data"


def _make_isolated_data_dir() -> Path:
    tmp = Path(tempfile.mkdtemp(prefix="paes_tests_data_"))
    atexit.register(shutil.rmtree, tmp, True)
    real_db = _REAL_DATA / "paes_med_ai.db"
    if real_db.is_file():
        # API de backup do SQLite: cópia consistente mesmo com WAL aberto.
        src = sqlite3.connect(f"file:{real_db.as_posix()}?mode=ro", uri=True)
        dst = sqlite3.connect(tmp / "paes_med_ai.db")
        try:
            src.backup(dst)
        finally:
            dst.close()
            src.close()
    # Pastas pequenas usadas por leitura (edital/inventário) — cópia integral.
    for sub in ("edital", "inventory", "media"):
        if (_REAL_DATA / sub).is_dir():
            shutil.copytree(_REAL_DATA / sub, tmp / sub, dirs_exist_ok=True)
    manifest = _REAL_DATA / "ACERVO_MANIFEST.json"
    if manifest.is_file():
        shutil.copy2(manifest, tmp / manifest.name)
    # Materiais: só um PDF + capa (os testes de capa precisam de 1 exemplo).
    mat = _REAL_DATA / "materiais"
    if (mat / "BI_GENETICA.pdf").is_file():
        (tmp / "materiais" / "imagens").mkdir(parents=True, exist_ok=True)
        shutil.copy2(mat / "BI_GENETICA.pdf", tmp / "materiais" / "BI_GENETICA.pdf")
        for img in (mat / "imagens").glob("bi_gene*"):
            shutil.copy2(img, tmp / "materiais" / "imagens" / img.name)
    return tmp


# Sem o .env de dados do usuário: o diretório temporário não tem .env.
os.environ["PAES_DATA_DIR"] = str(_make_isolated_data_dir())
