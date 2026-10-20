"""Cria uma conta de acesso à versão web ou troca a senha de uma que já existe.

Uso (na raiz do repositório):
    python scripts/criar_usuario.py ana --nome "Ana Souza" --papel admin
    python scripts/criar_usuario.py ana --nova-senha          # gera outra senha para a conta

A senha é gerada aqui (uma palavra e três números, fácil de digitar no celular) e aparece
uma única vez; no banco fica só o hash (PBKDF2). Grava no banco do backend/.env:
DATABASE_URL apontando para o Supabase = versão web; vazio = SQLite do app local.
Papéis: admin (acesso a tudo) e aluno.
"""

from __future__ import annotations

import argparse
import secrets
import sys
from datetime import datetime, timezone
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "backend"))

from auth import hash_senha  # noqa: E402
from db import DATABASE_URL, SQL_USUARIOS, USE_PG, db  # noqa: E402

PALAVRAS = (
    "sol mar rio lua flor pedra vento nuvem areia folha ponte farol barco ilha praia serra campo "
    "cedro caju manga coco jambo buriti bacuri murici pequi angico jatoba ipe palmeira babacu "
    "garca arara tucano sabia canario jabuti boto onca tatu cutia preguica lago dunas mangue "
    "cachoeira trilha rede tambor bumba sanfona viola zabumba matraca estrela cometa aurora "
    "neblina chuva trovao brisa orvalho"
).split()


def gera_senha() -> str:
    # simples de propósito (uma palavra e três números): o login trava 10 min após 5 erros
    return f"{secrets.choice(PALAVRAS)}{secrets.randbelow(900) + 100}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("usuario")
    ap.add_argument("--nome", help="nome mostrado no app (padrão: o usuário com inicial maiúscula)")
    ap.add_argument("--papel", choices=("admin", "aluno"), default="aluno")
    ap.add_argument("--nova-senha", action="store_true", help="troca a senha de uma conta existente")
    args = ap.parse_args()

    usuario = args.usuario.strip().lower()
    senha = gera_senha()
    agora = datetime.now(timezone.utc).isoformat()
    if USE_PG:
        # a camada de compatibilidade do db.py ignora DDL no Postgres: cria direto
        import psycopg

        with psycopg.connect(DATABASE_URL, prepare_threshold=None, connect_timeout=15) as pg:
            pg.execute(SQL_USUARIOS)
            # mesma regra das outras tabelas: a chave pública do Supabase não lê nada
            pg.execute("ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY")
    with db() as conn:
        if not USE_PG:
            conn.execute(SQL_USUARIOS)
        existe = conn.execute("SELECT nome FROM usuarios WHERE usuario = ?", (usuario,)).fetchone()
        if existe and not args.nova_senha:
            print(f"A conta '{usuario}' já existe. Para trocar a senha, use --nova-senha.")
            return 1
        if existe:
            conn.execute(
                "UPDATE usuarios SET senha_hash = ?, falhas = 0, bloqueado_ate = NULL"
                + (", papel = ?" if args.papel != "aluno" else "")
                + " WHERE usuario = ?",
                (hash_senha(senha), *([args.papel] if args.papel != "aluno" else []), usuario),
            )
        else:
            conn.execute(
                "INSERT INTO usuarios (usuario, nome, senha_hash, papel, criado_em) VALUES (?, ?, ?, ?, ?)",
                (usuario, args.nome or usuario.capitalize(), hash_senha(senha), args.papel, agora),
            )
        conn.commit()
    onde = "Supabase (versão web)" if USE_PG else "SQLite local"
    print(f"Conta '{usuario}' {'atualizada' if existe else 'criada'} no {onde}.")
    print(f"Usuário: {usuario}")
    print(f"Senha:   {senha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
