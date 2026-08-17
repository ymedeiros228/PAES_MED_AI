"""
Tira screenshots profissionais das telas do PAES MED AI.
Usa win32 para encontrar a janela do Flutter pelo PID.
Navega pelo menu lateral (NavigationRail) com coordenadas precisas.
"""
import time
import ctypes
from pathlib import Path

import pyautogui
from PIL import Image

pyautogui.FAILSAFE = False

OUT = Path(__file__).resolve().parent.parent / "docs" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)

user32 = ctypes.windll.user32


class RECT(ctypes.Structure):
    _fields_ = [("left", ctypes.c_long), ("top", ctypes.c_long),
                ("right", ctypes.c_long), ("bottom", ctypes.c_long)]


def find_window_by_pid(pid):
    result = []
    def callback(hwnd, _):
        pid_wnd = ctypes.c_ulong()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid_wnd))
        if pid_wnd.value == pid and user32.IsWindowVisible(hwnd):
            length = user32.GetWindowTextLengthW(hwnd)
            if length > 0:
                rect = RECT()
                user32.GetWindowRect(hwnd, ctypes.byref(rect))
                w = rect.right - rect.left
                h = rect.bottom - rect.top
                if w > 300 and h > 300:
                    result.append((hwnd, w, h, rect.left, rect.top))
        return True
    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    user32.EnumWindows(WNDENUMPROC(callback), 0)
    return result


def get_pid_by_name(name):
    import subprocess
    r = subprocess.run(
        ["powershell", "-NoProfile", "-Command",
         f"Get-Process -Name '{name}' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Id"],
        capture_output=True, text=True)
    try:
        return int(r.stdout.strip())
    except ValueError:
        return None


def get_window_rect(hwnd):
    rect = RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(rect))
    return rect.left, rect.top, rect.right, rect.bottom


def focus_window(hwnd):
    user32.SetForegroundWindow(hwnd)
    user32.ShowWindow(hwnd, 9)  # SW_RESTORE
    time.sleep(1.5)


def capture(name, hwnd, delay=2):
    """Captura a janela pelo HWND."""
    focus_window(hwnd)
    time.sleep(delay)
    left, top, right, bottom = get_window_rect(hwnd)
    w = right - left
    h = bottom - top
    print(f"  Screenshot '{name}': {w}x{h} em ({left},{top})")
    img = pyautogui.screenshot(region=(left, top, w, h))
    path = OUT / f"{name}.png"
    img.save(str(path))
    return path


def click_nav_item(hwnd, item_index, total_items=6):
    """
    Clica em um item do NavigationRail.
    O rail fica no canto esquerdo (~10% da largura).
    Itens comecam apos header (~20% da altura) e sao distribuidos verticalmente.
    """
    left, top, right, bottom = get_window_rect(hwnd)
    w = right - left
    h = bottom - top

    # Rail expandido (janela >= 1180px): largura 236px, centro em ~118px
    # Rail recolhido: largura 84px, centro em ~42px
    if w >= 1180:
        x = left + 118
    else:
        x = left + 42

    # Header ocupa ~18% da altura, itens comecam apos isso
    header_h = h * 0.18
    nav_area_h = h * 0.55  # area dos itens de navegacao
    item_h = nav_area_h / total_items
    y = top + header_h + item_h * item_index + item_h / 2

    print(f"  Clicando item {item_index}: pixel ({x},{y})")
    pyautogui.click(x=int(x), y=int(y))
    time.sleep(3)


def main():
    print("=== Screenshots do PAES MED AI ===\n")

    pid = get_pid_by_name("paes_med_ai")
    if not pid:
        print("ERRO: Processo paes_med_ai nao encontrado!")
        return
    print(f"PID: {pid}")

    windows = find_window_by_pid(pid)
    if not windows:
        print("ERRO: Janela nao encontrada!")
        return

    hwnd, w, h, l, t = windows[0]
    print(f"Janela: {w}x{h} em ({l},{t})")

    # Maximiza para garantir rail expandido
    user32.ShowWindow(hwnd, 3)  # SW_MAXIMIZE
    time.sleep(2)

    # Re-obtem dimensoes
    hwnd, w, h, l, t = find_window_by_pid(pid)[0]
    print(f"Apos maximizar: {w}x{h}")

    # === Screenshot 1: Dashboard (Inicio) ===
    print("\n[1/6] Dashboard (Inicio)...")
    click_nav_item(hwnd, 0)  # Inicio
    capture("01-dashboard", hwnd)

    # === Screenshot 2: Estudar (Sessao) ===
    print("[2/6] Estudar (Sessao)...")
    click_nav_item(hwnd, 1)  # Estudar
    capture("02-study", hwnd)

    # === Screenshot 3: Progresso ===
    print("[3/6] Progresso...")
    click_nav_item(hwnd, 2)  # Progresso
    capture("03-progress", hwnd)

    # === Screenshot 4: Biblioteca ===
    print("[4/6] Biblioteca...")
    click_nav_item(hwnd, 3)  # Biblioteca
    capture("04-library", hwnd)

    # === Screenshot 5: Materiais ===
    print("[5/6] Materiais...")
    click_nav_item(hwnd, 4)  # Materiais
    capture("05-materials", hwnd)

    # === Screenshot 6: Configuracoes (Ajustes) ===
    print("[6/6] Configuracoes (Ajustes)...")
    click_nav_item(hwnd, 5)  # Ajustes
    capture("06-settings", hwnd)

    print("\n=== Concluido! ===")
    print(f"Salvos em: {OUT}")


if __name__ == "__main__":
    main()
