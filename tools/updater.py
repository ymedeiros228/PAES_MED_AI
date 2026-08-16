"""
PAES MED AI - Updater

Verifica se existe uma versao mais recente no GitHub e baixa
o instalador automaticamente. Usado pelo instalador e pelo app desktop.

Fluxo:
1. Le a versao instalada do registro Windows
2. Compara com o arquivo VERSION no GitHub (raw)
3. Se houver versao nova, baixa o instalador do release
4. Executa o instalador silenciosamente

Uso:
    python tools/updater.py --check      # so verifica
    python tools/updater.py --install    # verifica e instala se houver
    python tools/updater.py --force      # forca reinstalacao
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
import winreg
from pathlib import Path


GITHUB_USER = "ymedeiros228"
GITHUB_REPO = "PAES_MED_AI"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_USER}/{GITHUB_REPO}/main/VERSION"
RELEASES_URL = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/releases/latest"
SETUP_NAME = "PAESMedAI_Setup"


def _open_key() -> winreg.HKEYType | None:
    try:
        return winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\PAES_MED_AI")
    except FileNotFoundError:
        return None


def _read_reg(name: str, default: str = "") -> str:
    key = _open_key()
    if not key:
        return default
    try:
        value, _ = winreg.QueryValueEx(key, name)
        return str(value) if value else default
    except FileNotFoundError:
        return default
    finally:
        winreg.CloseKey(key)


def get_installed_version() -> str:
    """Pega a versao instalada no registro ou retorna vazio."""
    return _read_reg("Version", "").strip()


def get_install_path() -> str:
    """Pega o caminho de instalacao no registro."""
    return _read_reg("InstallPath", "").strip()


def fetch_latest_version() -> str:
    """Busca a versao mais recente no GitHub."""
    try:
        with urllib.request.urlopen(VERSION_URL, timeout=15) as resp:
            return resp.read().decode("utf-8").strip()
    except Exception as exc:
        raise RuntimeError(f"Nao foi possivel verificar a versao: {exc}") from exc


def is_newer(current: str, latest: str) -> bool:
    """Compara versoes no formato X.Y.Z.W."""
    if not latest:
        return False
    if not current:
        return True  # nunca teve? nova

    def to_tuple(v: str) -> tuple[int, ...]:
        # Normaliza: 1.0.0.17 -> (1, 0, 0, 17)
        parts = re.split(r"[.-]", v)
        nums = []
        for p in parts:
            m = re.search(r"\d+", p)
            nums.append(int(m.group()) if m else 0)
        return tuple(nums)

    return to_tuple(latest) > to_tuple(current)


def download_setup(version: str, dest: Path) -> Path:
    """Baixa o instalador da ultima release para o destino."""
    try:
        with urllib.request.urlopen(RELEASES_URL, timeout=15) as resp:
            import json

            data = json.loads(resp.read().decode("utf-8"))
    except Exception as exc:
        raise RuntimeError(f"Nao foi possivel ler releases do GitHub: {exc}") from exc

    expected = f"{SETUP_NAME}_{version}.exe"
    for asset in data.get("assets", []):
        name = asset.get("name", "")
        if name.startswith(SETUP_NAME) and name.endswith(".exe"):
            url = asset.get("browser_download_url")
            if not url:
                continue
            dest_file = dest / name
            try:
                urllib.request.urlretrieve(url, str(dest_file))
                return dest_file
            except Exception as exc:
                raise RuntimeError(f"Falha ao baixar instalador: {exc}") from exc

    # Fallback: tenta URL direta
    direct = (
        f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/download/"
        f"v{version}/{expected}"
    )
    try:
        dest_file = dest / expected
        urllib.request.urlretrieve(direct, str(dest_file))
        return dest_file
    except Exception as exc:
        raise RuntimeError(f"Falha ao baixar instalador por fallback: {exc}") from exc


def run_update(setup_path: Path, silent: bool = True) -> None:
    """Executa o instalador baixado."""
    args = [str(setup_path)]
    if silent:
        args.extend(["/SILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/CLOSEAPPLICATIONS"])
    try:
        subprocess.Popen(args, close_fds=True)
    except Exception as exc:
        raise RuntimeError(f"Falha ao executar instalador: {exc}") from exc


def check_update() -> tuple[bool, str, str]:
    """Retorna (precisa_atualizar, versao_instalada, versao_mais_recente)."""
    current = get_installed_version()
    try:
        latest = fetch_latest_version()
    except RuntimeError:
        return False, current, ""
    return is_newer(current, latest), current, latest


def main() -> int:
    parser = argparse.ArgumentParser(description="Atualizador do PAES MED AI")
    parser.add_argument("--check", action="store_true", help="So verifica sem instalar")
    parser.add_argument("--install", action="store_true", help="Verifica e instala se houver nova versao")
    parser.add_argument("--force", action="store_true", help="Forca reinstalacao da ultima versao")
    args = parser.parse_args()

    current = get_installed_version()
    print(f"Versao instalada: {current or 'desconhecida'}")

    try:
        latest = fetch_latest_version()
    except RuntimeError as exc:
        print(f"Erro: {exc}")
        return 1

    print(f"Versao mais recente: {latest}")

    if not args.force and not is_newer(current, latest):
        print("Ja esta na versao mais recente.")
        return 0

    if args.check:
        print("Nova versao disponivel (use --install para atualizar).")
        return 0

    if not args.install and not args.force:
        print("Nova versao disponivel. Use --install para atualizar.")
        return 0

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        print(f"Baixando instalador {latest}...")
        try:
            setup = download_setup(latest, tmp_path)
            print(f"Instalador baixado: {setup}")
            print("Executando instalador...")
            run_update(setup)
            print("Instalador iniciado. O update sera concluido em alguns segundos.")
            return 0
        except RuntimeError as exc:
            print(f"Erro: {exc}")
            return 1


if __name__ == "__main__":
    sys.exit(main())
