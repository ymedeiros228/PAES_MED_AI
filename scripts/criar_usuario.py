"""Cria uma conta de acesso à versão web ou troca a senha de uma que já existe.

Uso (na raiz do repositório):
    python scripts/criar_usuario.py ana --nome "Ana Souza" --papel admin
    python scripts/criar_usuario.py ana --nova-senha          # gera outra senha para a conta
    python scripts/criar_usuario.py yuri --papel admin --esquema-proprio

--esquema-proprio (só no Supabase): a conta ganha o esquema paes_<usuario>, com cópias VAZIAS
das tabelas de progresso (db.TABELAS_DE_PROGRESSO). O progresso dela fica separado do de
quem usa o esquema base `paes` (ex.: jonas), que não é alterado. As configurações (data da
prova etc.) começam como cópia das do esquema base e os flashcards das aulas vêm zerados.

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
from db import (  # noqa: E402
    DATABASE_URL,
    ESQUEMA_BASE,
    SQL_USUARIOS,
    TABELAS_DE_PROGRESSO,
    USE_PG,
    db,
    esquema_valido,
)

# configurações que são histórico de quem já usa o esquema base: não vão para a conta nova
CONFIGURACOES_PESSOAIS = ("study_reads",)
# flashcards que são conteúdo das aulas (não criados pelo aluno): copiados zerados
FONTES_DE_FLASHCARD_DAS_AULAS = ("lesson", "aula", "seed", "template")


def cria_esquema_proprio(pg: object, usuario: str) -> str:
    """Cria (se faltar) o esquema de progresso da conta. Só lê do esquema base."""
    esquema = f"paes_{usuario}"
    if not esquema_valido(esquema):
        raise SystemExit(f"Nome de usuário não serve para esquema: {usuario!r} (use letras, números e _).")
    existe = pg.execute("SELECT 1 FROM pg_namespace WHERE nspname = %s", [esquema]).fetchone()  # type: ignore[attr-defined]
    if not existe:
        # o paes_app não cria esquema (de propósito); quem cria é o postgres, no editor SQL do painel
        raise SystemExit(
            f"Crie antes o esquema no Supabase (SQL Editor): create schema {esquema};"
            f" grant usage, create on schema {esquema} to paes_app;"
        )
    for tabela in TABELAS_DE_PROGRESSO:
        pg.execute(  # type: ignore[attr-defined]
            f'CREATE TABLE IF NOT EXISTS "{esquema}"."{tabela}" (LIKE "{ESQUEMA_BASE}"."{tabela}" INCLUDING ALL)'
        )
        pg.execute(f'ALTER TABLE "{esquema}"."{tabela}" ENABLE ROW LEVEL SECURITY')  # type: ignore[attr-defined]
    # configurações começam iguais às do esquema base (a conta muda o que quiser depois)
    pg.execute(  # type: ignore[attr-defined]
        f'INSERT INTO "{esquema}".settings SELECT * FROM "{ESQUEMA_BASE}".settings'
        " WHERE key <> ALL(%s) ON CONFLICT DO NOTHING",
        [list(CONFIGURACOES_PESSOAIS)],
    )
    # baralho das aulas, sem o histórico de revisão de ninguém (só se ainda estiver vazio)
    vazio = pg.execute(f'SELECT NOT EXISTS (SELECT 1 FROM "{esquema}".flashcards)').fetchone()[0]  # type: ignore[attr-defined]
    if vazio:
        filtro = " OR ".join("source ILIKE %s" for _ in FONTES_DE_FLASHCARD_DAS_AULAS)
        pg.execute(  # type: ignore[attr-defined]
            f'INSERT INTO "{esquema}".flashcards (front, back, subject, topic, source, next_due, reviews)'
            f' SELECT front, back, subject, topic, source, NULL, 0 FROM "{ESQUEMA_BASE}".flashcards'
            f" WHERE {filtro} ORDER BY id",
            [f"{f}%" for f in FONTES_DE_FLASHCARD_DAS_AULAS],
        )
    pg.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS esquema TEXT")  # type: ignore[attr-defined]
    return esquema

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
    ap.add_argument("--esquema-proprio", action="store_true", help="progresso separado (só Supabase)")
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
            esquema = cria_esquema_proprio(pg, usuario) if args.esquema_proprio else None
            if esquema:
                print(f"Esquema de progresso pronto: {esquema}")
    elif args.esquema_proprio:
        print("--esquema-proprio só vale no Supabase (DATABASE_URL do backend/.env).")
        return 1
    else:
        esquema = None
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
        if esquema:
            conn.execute("UPDATE usuarios SET esquema = ? WHERE usuario = ?", (esquema, usuario))
        conn.commit()
    onde = "Supabase (versão web)" if USE_PG else "SQLite local"
    print(f"Conta '{usuario}' {'atualizada' if existe else 'criada'} no {onde}.")
    print(f"Usuário: {usuario}")
    print(f"Senha:   {senha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
