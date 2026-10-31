"""Backup completo do banco da versão web (Supabase), só leitura.

Uso (na raiz do repositório):
    python scripts/backup_supabase.py                 # esquema paes (progresso do Jonas + conteúdo)
    python scripts/backup_supabase.py --esquema paes_yuri

Grava data/backups/supabase_<esquema>_<data>.json.gz com todas as linhas de todas as tabelas
do esquema e confere, no fim, que o número de linhas do arquivo bate com o do banco.
Não altera nada no banco. Usa o DATABASE_URL do backend/.env.
"""

from __future__ import annotations

import argparse
import gzip
import json
import sys
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "backend"))

from db import DATABASE_URL, USE_PG  # noqa: E402


def _json(valor: Any) -> Any:
    if isinstance(valor, (datetime, date)):
        return valor.isoformat()
    if isinstance(valor, Decimal):
        return float(valor)
    if isinstance(valor, (bytes, memoryview)):
        return bytes(valor).hex()
    return str(valor)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--esquema", default="paes")
    args = ap.parse_args()
    if not USE_PG:
        print("DATABASE_URL não aponta para o Postgres (backend/.env): nada a copiar.")
        return 1
    import psycopg

    destino = RAIZ / "data" / "backups"
    destino.mkdir(parents=True, exist_ok=True)
    arquivo = destino / f"supabase_{args.esquema}_{datetime.now():%Y%m%d_%H%M%S}.json.gz"
    copia: dict[str, Any] = {"esquema": args.esquema, "feito_em": datetime.now().isoformat(), "tabelas": {}}
    with psycopg.connect(DATABASE_URL, prepare_threshold=None, connect_timeout=15) as pg:
        pg.read_only = True
        tabelas = [
            r[0]
            for r in pg.execute(
                "SELECT table_name FROM information_schema.tables"
                " WHERE table_schema = %s AND table_type = 'BASE TABLE' ORDER BY table_name",
                [args.esquema],
            ).fetchall()
        ]
        if not tabelas:
            print(f"Esquema '{args.esquema}' sem tabelas (ou sem permissão).")
            return 1
        for tabela in tabelas:
            cur = pg.execute(f'SELECT * FROM "{args.esquema}"."{tabela}"')
            colunas = [d.name for d in cur.description or []]
            linhas = cur.fetchall()
            copia["tabelas"][tabela] = {"colunas": colunas, "linhas": [list(l) for l in linhas]}
            print(f"  {tabela}: {len(linhas)} linhas")
    with gzip.open(arquivo, "wt", encoding="utf-8") as f:
        json.dump(copia, f, ensure_ascii=False, default=_json)
    # confere lendo de volta o que foi gravado
    with gzip.open(arquivo, "rt", encoding="utf-8") as f:
        lido = json.load(f)
    total = sum(len(t["linhas"]) for t in lido["tabelas"].values())
    esperado = sum(len(t["linhas"]) for t in copia["tabelas"].values())
    if total != esperado:
        print(f"ERRO: o arquivo tem {total} linhas, o banco tinha {esperado}.")
        return 1
    print(f"Backup OK: {len(tabelas)} tabelas, {total} linhas -> {arquivo}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
