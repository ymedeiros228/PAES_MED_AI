"""
Gera icones distintos para PWA (web) com fundo teal.
O icone desktop (.ico) mantem o original em assets/branding/app_icon.ico.
"""

from pathlib import Path
from PIL import Image
import shutil
import sys

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
OUT_WEB = ROOT / "web" / "icons"


def load_source():
    if not SRC.exists():
        return None
    return Image.open(SRC).convert("RGBA")


def make_icon(size, bg_color):
    img = Image.new("RGBA", (size, size), bg_color)
    src = load_source()
    if src is not None:
        fit = int(size * 0.72)
        src.thumbnail((fit, fit), Image.LANCZOS)
        sw, sh = src.size
        img.paste(src, ((size - sw) // 2, (size - sh) // 2), src)
    else:
        from PIL import ImageDraw, ImageFont
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype("arialbd.ttf", size // 3)
        except:
            font = ImageFont.load_default()
        draw.text((size // 2, size // 2), "PAES", fill="white", anchor="mm", font=font)
    return img


def main():
    if not SRC.exists():
        print(f"ERRO: source nao encontrado: {SRC}")
        return 1

    OUT_WEB.mkdir(parents=True, exist_ok=True)
    for s in [192, 512]:
        make_icon(s, "#0d6e6e").save(OUT_WEB / f"Icon-{s}.png")
        margin = int(s * 0.125)
        ns = s - 2 * margin
        inner = make_icon(ns, "#0d6e6e")
        base = Image.new("RGBA", (s, s), "#0d6e6e")
        base.paste(inner, (margin, margin))
        base.save(OUT_WEB / f"Icon-maskable-{s}.png")

    # Restaura o icone desktop original (o .ico multi-resolucao valido)
    desktop_icon = ROOT / "assets" / "branding" / "app_icon.ico"
    if desktop_icon.exists():
        dst = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(desktop_icon, dst)
        print(f"[OK] Icone desktop restaurado: {dst}")

    print("[OK] Icones PWA gerados em", OUT_WEB)
    return 0


if __name__ == "__main__":
    sys.exit(main())
