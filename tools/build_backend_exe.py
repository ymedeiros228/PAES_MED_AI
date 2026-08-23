"""Build do backend PAES MED AI como exe standalone (PyInstaller).

Gera `backend/dist/paes_backend/paes_backend.exe` com Python + todas as
dependencias (fastapi, uvicorn, openai, etc.) embutidas. O cliente nao
precisa ter Python instalado.

Uso:
    python tools/build_backend_exe.py
    python tools/build_backend_exe.py --clean   # limpa build/cache antes

Requisitos:
    - backend/venv com todas as deps de requirements.txt instaladas
    - pyinstaller instalado no venv (instalado automaticamente se faltar)

Saida:
    backend/dist/paes_backend/paes_backend.exe
    backend/dist/paes_backend/_internal/...
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BACKEND = ROOT / "backend"
_VENV = BACKEND / "venv" / "Scripts" / "python.exe"
VENV_PY = _VENV if _VENV.exists() else Path(sys.executable)
DIST = BACKEND / "dist"
BUILD = BACKEND / "build"
SPEC = BACKEND / "paes_backend.spec"


def _ensure_pyinstaller() -> None:
    """Garante que pyinstaller esta instalado no venv."""
    result = subprocess.run(
        [str(VENV_PY), "-c", "import PyInstaller; print(PyInstaller.__version__)"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("[..] PyInstaller nao encontrado no venv. Instalando...")
        subprocess.run(
            [str(VENV_PY), "-m", "pip", "install", "--upgrade", "pyinstaller>=6.11"],
            check=True,
        )
        print("[OK] PyInstaller instalado")
    else:
        print(f"[OK] PyInstaller {result.stdout.strip()} presente")


def _clean(clean: bool) -> None:
    if not clean:
        return
    for d in (DIST, BUILD):
        if d.exists():
            print(f"[..] Removendo {d}")
            shutil.rmtree(d)
    print("[OK] Build/dist limpos")


def _build() -> Path:
    """Roda pyinstaller com o spec. Retorna o diretorio de saida."""
    cmd = [
        str(VENV_PY),
        "-m",
        "PyInstaller",
        str(SPEC),
        "--noconfirm",
        "--distpath",
        str(DIST),
        "--workpath",
        str(BUILD),
    ]
    print(f"$ {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=str(BACKEND))
    if result.returncode != 0:
        raise RuntimeError("PyInstaller falhou")
    out = DIST / "paes_backend"
    exe = out / "paes_backend.exe"
    if not exe.exists():
        raise FileNotFoundError(f"exe nao gerado: {exe}")
    return out


def _report(out: Path) -> None:
    total = sum(f.stat().st_size for f in out.rglob("*") if f.is_file())
    print(f"\n[OK] Backend exe gerado em: {out}")
    print(f"     Tamanho: {total / (1024 * 1024):.1f} MB")
    print(f"     exe: {out / 'paes_backend.exe'}")


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Build backend exe (PyInstaller)")
    parser.add_argument("--clean", action="store_true", help="Limpa build/dist antes")
    args = parser.parse_args()

    if not VENV_PY.exists():
        print(f"ERRO: Python nao encontrado em {VENV_PY}")
        return 1
    if not SPEC.exists():
        print(f"ERRO: spec nao encontrado: {SPEC}")
        return 1

    try:
        _ensure_pyinstaller()
        _clean(args.clean)
        out = _build()
        _report(out)
        return 0
    except Exception as exc:
        print(f"\nERRO: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
