"""
PAES MED AI - Release automatizado para Windows

Um comando gera uma nova versao completa:
  python tools/release_windows.py 1.0.0.18

O que o script faz:
1. Atualiza a versao em pubspec.yaml, lib/core/app_version.dart, VERSION, installer/paes_med_ai.iss
2. Build Flutter Windows (release)
3. Rebuild do banco e copia de materiais
4. Compila o instalador com Inno Setup
5. Commita e pusha as alteracoes
6. Cria o release no GitHub com o instalador anexado

Requisitos:
- Flutter no PATH
- Inno Setup 6 instalado
- gh (GitHub CLI) logado
- Python 3.11+
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
FLUTTER = Path(r"C:\Users\Yuri\flutter\bin\flutter.bat")
INNO = Path(r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe")


def _run(cmd: list[str] | str, *, cwd: Path | None = None, check: bool = True) -> str:
    if isinstance(cmd, list):
        cmd_str = " ".join(str(c) for c in cmd)
    else:
        cmd_str = cmd
    print(f"$ {cmd_str}")
    result = subprocess.run(
        cmd_str,
        cwd=str(cwd or REPO_ROOT),
        shell=True,
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        raise RuntimeError(f"Falhou: {cmd_str}")
    return result.stdout.strip()


def _update_pubspec(version: str) -> None:
    path = REPO_ROOT / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"^version:\s*[\d.+]+", f"version: {version}", text, flags=re.M)
    path.write_text(text, encoding="utf-8")
    print("[OK] pubspec.yaml atualizado")


def _update_app_version(version: str) -> None:
    path = REPO_ROOT / "lib" / "core" / "app_version.dart"
    text = path.read_text(encoding="utf-8")
    text = re.sub(
        r"const String kAppVersionLabel = '[\d.+]+';",
        f"const String kAppVersionLabel = '{version}';",
        text,
    )
    path.write_text(text, encoding="utf-8")
    print("[OK] lib/core/app_version.dart atualizado")


def _update_version_file(version: str) -> None:
    path = REPO_ROOT / "VERSION"
    path.write_text(f"{version}\n", encoding="utf-8")
    print("[OK] VERSION atualizado")


def _update_installer_version(version: str) -> None:
    path = REPO_ROOT / "installer" / "paes_med_ai.iss"
    text = path.read_text(encoding="utf-8")
    text = re.sub(
        r"#define MyAppVersion\s+\"[\d.]+\"",
        f"#define MyAppVersion \"{version}\"",
        text,
    )
    text = re.sub(
        r"OutputBaseFilename=PAESMedAI_Setup_[\d.]+",
        f"OutputBaseFilename=PAESMedAI_Setup_{version}",
        text,
    )
    path.write_text(text, encoding="utf-8")
    print("[OK] installer/paes_med_ai.iss atualizado")


def _build_windows() -> None:
    _run([str(FLUTTER), "build", "windows", "--release", "--no-pub"], cwd=REPO_ROOT)
    print("[OK] Build Flutter Windows concluido")


def _build_web() -> None:
    _run([str(FLUTTER), "build", "web", "--release", "--no-pub"], cwd=REPO_ROOT)
    # Copia para deploy/web
    deploy_web = REPO_ROOT / "deploy" / "web"
    build_web = REPO_ROOT / "build" / "web"
    if deploy_web.exists():
        shutil.rmtree(deploy_web)
    shutil.copytree(build_web, deploy_web)
    print("[OK] Build Flutter Web concluido e copiado para deploy/web")


def _sync_deploy_data() -> None:
    """Copia banco e materiais para deploy/data."""
    deploy_data = REPO_ROOT / "deploy" / "data"
    deploy_data.mkdir(parents=True, exist_ok=True)
    shutil.copy2(REPO_ROOT / "data" / "paes_med_ai.db", deploy_data / "paes_med_ai.db")
    materiais_src = REPO_ROOT / "data" / "materiais"
    materiais_dst = deploy_data / "materiais"
    if materiais_dst.exists():
        shutil.rmtree(materiais_dst)
    shutil.copytree(materiais_src, materiais_dst)
    print("[OK] deploy/data sincronizado")


def _compile_installer() -> None:
    iss = REPO_ROOT / "installer" / "paes_med_ai.iss"
    _run([str(INNO), str(iss)])
    print("[OK] Instalador compilado")


def _git_commit_and_push(version: str) -> None:
    _run("git add -A")
    _run(f'git commit -m "release: v{version}" --no-verify', check=False)
    _run("git push origin main")
    print("[OK] Codigo commitado e pushado")


def _create_github_release(version: str, asset: Path) -> None:
    notes = (
        f"PAES MED AI v{version}\\n\\n"
        f"- Build Windows e instalador\\n"
        f"- Build web para deploy\\n"
        f"- Banco e materiais atualizados"
    )
    _run(
        [
            "gh",
            "release",
            "create",
            f"v{version}",
            f"--title",
            f"PAES MED AI v{version}",
            f"--notes",
            notes,
            str(asset),
        ]
    )
    print(f"[OK] Release v{version} criado no GitHub: {asset.name}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Release automatizado PAES MED AI para Windows")
    parser.add_argument("version", help="Nova versao, ex: 1.0.0.18")
    parser.add_argument("--no-web", action="store_true", help="Pula build web (só desktop)")
    parser.add_argument("--no-release", action="store_true", help="Pula criacao do release no GitHub")
    args = parser.parse_args()

    version = args.version.strip()
    if not re.match(r"^\d+\.\d+\.\d+(\.\d+)?$", version):
        print("Versao invalida. Use formato: 1.0.0.18")
        return 1

    # Converte 1.0.0.18 para pubspec (1.0.0+18)
    pubspec_version = version.replace(".", "+", 3).replace(".", "+", 2) if version.count(".") == 3 else version
    # Na verdade pubspec usa 1.0.0+18 (build number com +)
    # Versao do .iss e app_version usam 1.0.0.18
    parts = version.split(".")
    if len(parts) == 4:
        pubspec_version = f"{parts[0]}.{parts[1]}.{parts[2]}+{parts[3]}"
    else:
        pubspec_version = version

    print(f"=== RELEASE PAES MED AI v{version} ===")

    try:
        _update_pubspec(pubspec_version)
        _update_app_version(version)
        _update_version_file(version)
        _update_installer_version(version)

        _build_windows()
        if not args.no_web:
            _build_web()

        _sync_deploy_data()
        _compile_installer()

        _git_commit_and_push(version)

        if not args.no_release:
            asset = REPO_ROOT / "installer" / "Output" / f"PAESMedAI_Setup_{version}.exe"
            if not asset.exists():
                raise FileNotFoundError(f"Instalador nao encontrado: {asset}")
            _create_github_release(version, asset)

        print(f"\\n🎉 Release v{version} publicado com sucesso!")
        print(f"Download: https://github.com/ymedeiros228/PAES_MED_AI/releases/tag/v{version}")
        return 0

    except Exception as exc:
        print(f"\\n❌ Erro: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
