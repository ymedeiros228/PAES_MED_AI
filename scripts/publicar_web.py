"""Publica a versão web no Vercel (substitui o instalador do Windows).

Uso (na raiz do repositório):
    python scripts/publicar_web.py            # compila o Flutter, monta public/ e publica em produção
    python scripts/publicar_web.py --sem-build  # reaproveita o build/web atual
    python scripts/publicar_web.py --previa     # publica numa URL de teste, sem mexer na produção

O que vai para o ar:
- public/            → app Flutter web (build/web)
- public/data/...    → PDFs de provas, gabaritos, edital e materiais (entregues pela CDN)
- api/index.py       → o backend FastAPI (backend/), como função Python
O banco é o Postgres do Supabase (DATABASE_URL nas variáveis de ambiente do Vercel).
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
FLUTTER = Path.home() / "flutter" / "bin" / ("flutter.bat" if sys.platform == "win32" else "flutter")
PASTAS_DADOS = ("provas", "gabaritos", "edital", "materiais", "figuras")


def rodar(cmd: list[str]) -> None:
    print("›", " ".join(cmd))
    # no Windows, flutter e vercel são .bat/.cmd: resolve o caminho completo antes de chamar
    exe = shutil.which(cmd[0]) or cmd[0]
    subprocess.run([exe, *cmd[1:]], cwd=RAIZ, check=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sem-build", action="store_true")
    ap.add_argument("--previa", action="store_true")
    args = ap.parse_args()

    if not args.sem_build:
        flutter = str(FLUTTER) if FLUTTER.exists() else "flutter"
        rodar([flutter, "build", "web", "--release", "--base-href=/", "--no-wasm-dry-run"])

    web = RAIZ / "build" / "web"
    if not (web / "index.html").is_file():
        print("build/web não existe; rode sem --sem-build")
        return 1

    public = RAIZ / "public"
    if public.exists():
        shutil.rmtree(public)
    shutil.copytree(web, public)
    for pasta in PASTAS_DADOS:
        origem = RAIZ / "data" / pasta
        if origem.is_dir():
            shutil.copytree(origem, public / "data" / pasta, ignore=shutil.ignore_patterns(".gitkeep"))
    total = sum(f.stat().st_size for f in public.rglob("*") if f.is_file())
    print(f"public/ montado: {total / 1e6:.0f} MB")

    # materiais (PDFs e capas) não cabem na função (limite de 225 MB): ela lê só este índice
    materiais = RAIZ / "data" / "materiais"
    indice = {
        f.relative_to(RAIZ / "data").as_posix(): f.stat().st_size
        for f in materiais.rglob("*") if f.is_file() and f.name != ".gitkeep"
    }
    (RAIZ / "data" / "arquivos_web.json").write_text(json.dumps(indice, ensure_ascii=False), encoding="utf-8")
    print(f"data/arquivos_web.json: {len(indice)} arquivos de materiais")

    rodar(["vercel", "deploy", "--yes"] + ([] if args.previa else ["--prod"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
