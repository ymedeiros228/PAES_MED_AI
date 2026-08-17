"""
PAES MED AI - Atualizador Visual com Interface Grafica (tkinter)

Mostra uma janela bonita com:
1. Verificacao de versao
2. Barra de progresso durante o download
3. Mensagem "Instalando..."
4. Fecha o app antigo
5. Instala a nova versao silenciosamente
6. Reabre o app na versao nova

Nao precisa de command line. Tudo visual, como qualquer app desktop.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
import threading
import urllib.request
import winreg
from pathlib import Path

import tkinter as tk
from tkinter import ttk, messagebox

GITHUB_USER = "ymedeiros228"
GITHUB_REPO = "PAES_MED_AI"
VERSION_URL = f"https://raw.githubusercontent.com/{GITHUB_USER}/{GITHUB_REPO}/main/VERSION"
RELEASES_URL = f"https://api.github.com/repos/{GITHUB_USER}/{GITHUB_REPO}/releases/latest"
SETUP_PREFIX = "PAESMedAI_Setup"

# Cores do app
C_NAVY = "#0A1628"
C_TEAL = "#1FA887"
C_TEAL_DEEP = "#0C7A63"
C_MINT = "#E6F6F1"
C_WHITE = "#FFFFFF"
C_MUTED = "#5A6B6E"


def read_reg(name: str, default: str = "") -> str:
    try:
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\PAES_MED_AI")
        value, _ = winreg.QueryValueEx(key, name)
        winreg.CloseKey(key)
        return str(value) if value else default
    except FileNotFoundError:
        return default
    except Exception:
        return default


def get_installed_version() -> str:
    return read_reg("Version", "").strip()


def get_install_path() -> str:
    return read_reg("InstallPath", "").strip()


def fetch_latest_version() -> str:
    try:
        with urllib.request.urlopen(VERSION_URL, timeout=15) as resp:
            return resp.read().decode("utf-8").strip()
    except Exception:
        return ""


def is_newer(current: str, latest: str) -> bool:
    if not latest:
        return False
    if not current:
        return True

    def to_tuple(v: str) -> tuple[int, ...]:
        parts = re.split(r"[.-]", v)
        nums = []
        for p in parts:
            m = re.search(r"\d+", p)
            nums.append(int(m.group()) if m else 0)
        return tuple(nums)

    return to_tuple(latest) > to_tuple(current)


def get_download_url(version: str) -> tuple[str, str]:
    """Retorna (url, filename) do instalador na release."""
    try:
        import json
        with urllib.request.urlopen(RELEASES_URL, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        for asset in data.get("assets", []):
            name = asset.get("name", "")
            if name.startswith(SETUP_PREFIX) and name.endswith(".exe"):
                return asset.get("browser_download_url", ""), name
    except Exception:
        pass
    # Fallback
    expected = f"{SETUP_PREFIX}_{version}.exe"
    url = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/releases/download/v{version}/{expected}"
    return url, expected


class UpdaterGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("PAES MED AI - Atualizador")
        self.root.geometry("480x320")
        self.root.resizable(False, False)
        self.root.configure(bg=C_NAVY)

        # Centraliza na tela
        self.root.update_idletasks()
        w = self.root.winfo_width()
        h = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() - w) // 2
        y = (self.root.winfo_screenheight() - h) // 2
        self.root.geometry(f"+{x}+{y}")

        # Header
        header = tk.Frame(self.root, bg=C_TEAL, height=6)
        header.pack(fill="x", side="top")

        # Titulo
        tk.Label(
            self.root, text="PAES MED AI", font=("Segoe UI", 20, "bold"),
            bg=C_NAVY, fg=C_WHITE
        ).pack(pady=(20, 5))
        tk.Label(
            self.root, text="Atualizador", font=("Segoe UI", 12),
            bg=C_NAVY, fg=C_TEAL
        ).pack(pady=(0, 15))

        # Frame de conteudo
        self.content = tk.Frame(self.root, bg=C_NAVY)
        self.content.pack(fill="both", expand=True, padx=30)

        # Status label
        self.status_var = tk.StringVar(value="Verificando versao...")
        self.status_label = tk.Label(
            self.content, textvariable=self.status_var,
            font=("Segoe UI", 11), bg=C_NAVY, fg=C_MINT,
            wraplength=400, justify="center"
        )
        self.status_label.pack(pady=(10, 10))

        # Barra de progresso
        self.progress = ttk.Progressbar(
            self.content, orient="horizontal", length=380, mode="determinate"
        )
        self.progress.pack(pady=(5, 5))

        # Label de porcentagem
        self.pct_var = tk.StringVar(value="")
        self.pct_label = tk.Label(
            self.content, textvariable=self.pct_var,
            font=("Segoe UI", 10), bg=C_NAVY, fg=C_MUTED
        )
        self.pct_label.pack(pady=(0, 10))

        # Botao
        self.btn_var = tk.StringVar(value="Atualizar agora")
        self.btn = tk.Button(
            self.content, textvariable=self.btn_var,
            font=("Segoe UI", 11, "bold"),
            bg=C_TEAL, fg=C_WHITE, activebackground=C_TEAL_DEEP,
            activeforeground=C_WHITE, relief="flat", cursor="hand2",
            width=20, height=2, command=self.on_button,
            state="disabled"
        )
        self.btn.pack(pady=(10, 5))

        # Versao info no rodape
        self.ver_var = tk.StringVar(value="")
        tk.Label(
            self.root, textvariable=self.ver_var,
            font=("Segoe UI", 9), bg=C_NAVY, fg=C_MUTED
        ).pack(side="bottom", pady=(0, 8))

        # Rodape
        footer = tk.Frame(self.root, bg=C_TEAL_DEEP, height=4)
        footer.pack(fill="x", side="bottom")

        # Estilo da progressbar
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("Horizontal.TProgressbar",
                        troughcolor=C_NAVY,
                        background=C_TEAL,
                        darkcolor=C_TEAL,
                        lightcolor=C_TEAL,
                        bordercolor=C_NAVY,
                        thickness=12)

        self.current_version = ""
        self.latest_version = ""
        self.download_path = ""
        self.is_updating = False

        # Inicia verificacao em thread separada
        threading.Thread(target=self.check_version, daemon=True).start()

    def set_status(self, text: str):
        self.status_var.set(text)

    def set_pct(self, value: int, text: str = ""):
        self.progress["value"] = value
        self.pct_var.set(text)

    def check_version(self):
        """Verifica versao em thread separada."""
        self.current_version = get_installed_version()
        self.latest_version = fetch_latest_version()

        if not self.latest_version:
            self.root.after(0, lambda: self.set_status("Nao foi possivel verificar atualizacao.\nVerifique sua conexao com a internet."))
            return

        self.root.after(0, lambda: self.ver_var.set(
            f"Instalada: {self.current_version or 'desconhecida'}  |  Disponivel: {self.latest_version}"
        ))

        if is_newer(self.current_version, self.latest_version):
            self.root.after(0, lambda: self.set_status(f"Nova versao disponivel: {self.latest_version}\nClique para atualizar."))
            self.root.after(0, lambda: self.btn.config(state="normal"))
        else:
            self.root.after(0, lambda: self.set_status(f"Voce ja esta na versao mais recente ({self.current_version})."))
            self.root.after(0, lambda: self.btn_var.set("Fechar"))
            self.root.after(0, lambda: self.btn.config(state="normal", command=self.root.quit))

    def on_button(self):
        if self.is_updating:
            return
        if self.latest_version and not is_newer(self.current_version, self.latest_version):
            self.root.quit()
            return
        self.is_updating = True
        self.btn.config(state="disabled")
        threading.Thread(target=self.do_update, daemon=True).start()

    def do_update(self):
        """Faz o download e instalacao em thread separada."""
        try:
            # 1. Obtem URL de download
            self.root.after(0, lambda: self.set_status("Preparando download..."))
            url, filename = get_download_url(self.latest_version)
            if not url:
                self.root.after(0, lambda: self.set_status("Erro: instalador nao encontrado no GitHub."))
                self.root.after(0, lambda: self.btn.config(state="normal"))
                self.is_updating = False
                return

            # 2. Baixa o instalador com progresso
            self.root.after(0, lambda: self.set_status("Baixando atualizacao..."))
            tmp_dir = Path(tempfile.gettempdir()) / "PAES_MED_AI_Update"
            tmp_dir.mkdir(parents=True, exist_ok=True)
            self.download_path = os.path.abspath(str(tmp_dir / filename))

            # Apaga arquivo antigo se existir
            if os.path.exists(self.download_path):
                try:
                    os.remove(self.download_path)
                except Exception:
                    pass

            # Download com progresso
            self.download_with_progress(url, self.download_path)

            # Verifica se o arquivo foi baixado
            if not os.path.exists(self.download_path):
                self.root.after(0, lambda: self.set_status("Erro: o download falhou.\nTente novamente."))
                self.root.after(0, lambda: self.btn.config(state="normal"))
                self.is_updating = False
                return

            file_size = os.path.getsize(self.download_path)
            if file_size < 1_000_000:  # menor que 1MB = erro
                self.root.after(0, lambda: self.set_status(f"Erro: arquivo baixado muito pequeno ({file_size} bytes).\nTente novamente."))
                self.root.after(0, lambda: self.btn.config(state="normal"))
                self.is_updating = False
                return

            self.root.after(0, lambda: self.set_status(f"Download concluido: {file_size // (1024*1024)} MB\nFechando aplicativo..."))

            # 3. Fecha o app antigo
            self.root.after(0, lambda: self.set_pct(100, "100%"))
            self.kill_app()

            import time
            time.sleep(2)

            # 4. Instala silenciosamente (com elevacao UAC)
            self.root.after(0, lambda: self.set_status("Instalando nova versao...\nClique SIM se o Windows pedir permissao."))
            self.root.after(0, lambda: self.set_pct(0, ""))
            ok = self.run_installer(self.download_path)

            # 4b. Verifica se a versao mudou no registro
            import time as _time
            _time.sleep(3)
            new_ver = get_installed_version()

            if not ok or (new_ver and new_ver != self.latest_version):
                # Instalador pode ter falhado; tenta de novo sem /SILENT
                self.root.after(0, lambda: self.set_status("Instalando... aguarde a janela do instalador."))
                ok2 = self.run_installer_interactive(self.download_path)
                _time.sleep(3)
                new_ver = get_installed_version()

            if new_ver == self.latest_version:
                # 5. Reabre o app
                self.root.after(0, lambda: self.set_status("Abrindo PAES MED AI..."))
                self.reopen_app()

                # 6. Aviso final
                self.root.after(0, lambda: self.set_status(f"Atualizacao concluida!\nVersao {self.latest_version} instalada com sucesso."))
                self.root.after(0, lambda: self.btn_var.set("Fechar"))
                self.root.after(0, lambda: self.btn.config(state="normal", command=self.root.quit))
            else:
                self.root.after(0, lambda: self.set_status(
                    f"A instalacao pode nao ter concluido.\n"
                    f"Versao atual: {new_ver or 'desconhecida'}\n"
                    f"Tente instalar manualmente o arquivo baixado."
                ))
                self.root.after(0, lambda: self.btn_var.set("Fechar"))
                self.root.after(0, lambda: self.btn.config(state="normal", command=self.root.quit))

        except Exception as e:
            self.root.after(0, lambda: self.set_status(f"Erro na atualizacao: {e}"))
            self.root.after(0, lambda: self.btn.config(state="normal"))
            self.is_updating = False

    def download_with_progress(self, url: str, dest: str):
        """Baixa arquivo mostrando progresso na barra. Trata redirecionamentos do GitHub."""
        # GitHub faz redirecionamento 302 - urllib segue automaticamente
        req = urllib.request.Request(url, headers={
            "User-Agent": "PAES-MED-AI-Updater",
            "Accept": "application/octet-stream",
        })
        with urllib.request.urlopen(req, timeout=300) as resp:
            total = int(resp.headers.get("Content-Length", 0))
            if total == 0:
                # Tenta pegar do Content-Range ou assume 160MB
                total = 160 * 1024 * 1024
            downloaded = 0
            chunk_size = 256 * 1024  # 256KB - mais rapido

            with open(dest, "wb") as f:
                while True:
                    chunk = resp.read(chunk_size)
                    if not chunk:
                        break
                    f.write(chunk)
                    downloaded += len(chunk)
                    pct = int(100 * downloaded / total)
                    mb_done = downloaded / (1024 * 1024)
                    mb_total = total / (1024 * 1024)
                    self.root.after(0, lambda p=pct, d=mb_done, t=mb_total: self.set_pct(p, f"{d:.0f} MB / {t:.0f} MB ({p}%)"))

            # Garante que o arquivo foi salvo
            f.flush()
            os.fsync(f.fileno())

    def kill_app(self):
        """Fecha o paes_med_ai.exe se estiver rodando."""
        try:
            subprocess.run(
                ["taskkill", "/F", "/IM", "paes_med_ai.exe"],
                capture_output=True, timeout=10
            )
        except Exception:
            pass

    def run_installer(self, setup_path: str) -> bool:
        """Executa o instalador silenciosamente com elevacao UAC via ShellExecute."""
        try:
            # Verifica se o arquivo existe
            if not os.path.exists(setup_path):
                self.root.after(0, lambda: self.set_status(f"Erro: arquivo nao encontrado:\n{setup_path}"))
                return False

            import ctypes
            from ctypes import wintypes

            SEE_MASK_NOCLOSEPROCESS = 0x00000040
            SEE_MASK_NO_CONSOLE = 0x00008000
            SEE_MASK_FLAG_NO_UI = 0x00000400

            class SHELLEXECUTEINFO(ctypes.Structure):
                _fields_ = [
                    ("cbSize", wintypes.DWORD),
                    ("fMask", wintypes.ULONG),
                    ("hwnd", wintypes.HWND),
                    ("lpVerb", wintypes.LPCWSTR),
                    ("lpFile", wintypes.LPCWSTR),
                    ("lpParameters", wintypes.LPCWSTR),
                    ("lpDirectory", wintypes.LPCWSTR),
                    ("nShow", ctypes.c_int),
                    ("hInstApp", wintypes.HINSTANCE),
                    ("lpIDList", wintypes.LPVOID),
                    ("lpClass", wintypes.LPCWSTR),
                    ("hkeyClass", wintypes.HKEY),
                    ("dwHotKey", wintypes.DWORD),
                    ("hIcon", wintypes.HANDLE),
                    ("hProcess", wintypes.HANDLE),
                ]

            SW_SHOWNORMAL = 1
            SW_HIDE = 0

            sei = SHELLEXECUTEINFO()
            sei.cbSize = ctypes.sizeof(SHELLEXECUTEINFO)
            sei.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NO_CONSOLE | SEE_MASK_FLAG_NO_UI
            sei.hwnd = None
            sei.lpVerb = "runas"  # pede elevacao UAC
            sei.lpFile = setup_path
            sei.lpParameters = "/SILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS"
            sei.lpDirectory = None
            sei.nShow = SW_SHOWNORMAL  # mostra a janela do instalador

            ok = ctypes.windll.shell32.ShellExecuteExW(ctypes.byref(sei))
            if not ok:
                err = ctypes.windll.kernel32.GetLastError()
                self.root.after(0, lambda: self.set_status(f"Erro ao iniciar instalador (codigo {err}).\nTente executar manualmente:\n{setup_path}"))
                return False

            # Espera o processo terminar (ate 5 minutos)
            INFINITE = 0xFFFFFFFF
            WAIT_TIMEOUT = 300000
            ctypes.windll.kernel32.WaitForSingleObject(sei.hProcess, WAIT_TIMEOUT)
            ctypes.windll.kernel32.CloseHandle(sei.hProcess)
            return True
        except Exception:
            return False

    def run_installer_interactive(self, setup_path: str) -> bool:
        """Executa o instalador de forma visivel (sem /SILENT) com elevacao UAC."""
        try:
            import ctypes
            from ctypes import wintypes

            SW_SHOWNORMAL = 1

            ret = ctypes.windll.shell32.ShellExecuteW(
                None,
                "runas",
                setup_path,
                "/NORESTART /CLOSEAPPLICATIONS",
                None,
                SW_SHOWNORMAL
            )
            return ret > 32
        except Exception:
            return False

    def reopen_app(self):
        """Reabre o app apos a instalacao."""
        install_path = get_install_path()
        if not install_path:
            # Tenta caminho padrao
            install_path = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Programs", "PAES_MED_AI")

        # Tenta pelo VBS (sem tela preta)
        vbs = Path(install_path) / "Iniciar_PAES_MED_AI.vbs"
        if vbs.exists():
            try:
                subprocess.Popen(["wscript.exe", str(vbs)], close_fds=True)
                return
            except Exception:
                pass

        # Tenta pelo exe direto
        exe = Path(install_path) / "app" / "paes_med_ai.exe"
        if exe.exists():
            try:
                subprocess.Popen([str(exe)], close_fds=True)
                return
            except Exception:
                pass

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    app = UpdaterGUI()
    app.run()
