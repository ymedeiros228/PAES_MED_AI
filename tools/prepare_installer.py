"""
Prepara staging do instalador PAES MED AI.
Copia apenas os arquivos necessarios, excluindo .venv, __pycache__ etc.
"""

from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parent.parent
STAGING = ROOT / "installer" / "staging"

EXCLUDED_DIRS = {".venv", "venv", "__pycache__", ".pytest_cache", "node_modules", "backups"}


def clean_staging():
    if STAGING.exists():
        shutil.rmtree(STAGING)
    STAGING.mkdir(parents=True)
    (STAGING / "app").mkdir()
    (STAGING / "backend").mkdir()
    (STAGING / "data").mkdir()
    (STAGING / "tools").mkdir()


def copy_tree(src: Path, dst: Path) -> None:
    for item in src.rglob("*"):
        if any(part in EXCLUDED_DIRS for part in item.parts):
            continue
        rel = item.relative_to(src)
        target = dst / rel
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, target)


def main():
    clean_staging()

    build_dir = ROOT / "build" / "windows" / "x64" / "runner" / "Release"
    if not build_dir.exists():
        print("ERRO: Build Windows nao encontrado. Rode: flutter build windows --release")
        return 1

    # App
    for item in build_dir.iterdir():
        if item.is_dir():
            shutil.copytree(item, STAGING / "app" / item.name, dirs_exist_ok=True)
        else:
            shutil.copy2(item, STAGING / "app" / item.name)

    # Backend
    copy_tree(ROOT / "backend", STAGING / "backend")

    # Dados
    copy_tree(ROOT / "data", STAGING / "data")

    # Tools
    copy_tree(ROOT / "tools", STAGING / "tools")

    # Launcher
    shutil.copy2(ROOT / "Iniciar_PAES_MED_AI.bat", STAGING / "Iniciar_PAES_MED_AI.bat")
    vbs = ROOT / "Iniciar_PAES_MED_AI.vbs"
    if vbs.exists():
        shutil.copy2(vbs, STAGING / "Iniciar_PAES_MED_AI.vbs")
    shutil.copy2(ROOT / "VERSION", STAGING / "VERSION.txt")

    print(f"Staging pronto em: {STAGING}")
    print(f"Tamanho: {sum(f.stat().st_size for f in STAGING.rglob('*') if f.is_file()) / (1024*1024):.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
