"""
Gera icones distintos para PWA (web) e desktop (Windows).
- PWA: fundo teal (#0d6e6e), simbolo branco
- Desktop: fundo navy (#0A1628), simbolo branco
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import sys

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
OUT_WEB = ROOT / "web" / "icons"
OUT_DESKTOP = ROOT / "windows" / "runner" / "resources"


def make_background(size, color):
    img = Image.new("RGBA", (size, size), color)
    return img


def add_badge(img, text, color):
    draw = ImageDraw.Draw(img)
    w, h = img.size
    # Desenha um circulo com a cor
    r = w // 4
    cx, cy = w - r, h - r
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    # Tenta colocar a letra
    try:
        font = ImageFont.truetype("arialbd.ttf", r)
    except:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw / 2, cy - th / 2 - r / 8), text, fill="white", font=font)
    return img


def create_pwa_icon():
    size = 512
    if not SRC.exists():
        # Gera um icone generico se nao houver source
        img = make_background(size, "#0d6e6e")
        draw = ImageDraw.Draw(img)
        draw.text((size // 2, size // 2), "PAES", fill="white", anchor="mm")
    else:
        src = Image.open(SRC).convert("RGBA")
        # Fundo teal
        img = make_background(size, "#0d6e6e")
        # Redimensiona mantendo proporcao
        src.thumbnail((int(size * 0.75), int(size * 0.75)), Image.LANCZOS)
        # Cola no centro
        sw, sh = src.size
        img.paste(src, ((size - sw) // 2, (size - sh) // 2), src)

    # Salva 192 e 512
    OUT_WEB.mkdir(parents=True, exist_ok=True)
    img.resize((192, 192), Image.LANCZOS).save(OUT_WEB / "Icon-192.png")
    img.resize((512, 512), Image.LANCZOS).save(OUT_WEB / "Icon-512.png")

    # Maskable (com margem de seguranca)
    margin = int(size * 0.12)
    maskable = make_background(size, "#0d6e6e")
    new_size = size - 2 * margin
    src_mask = src.resize((new_size, new_size), Image.LANCZOS)
    maskable.paste(src_mask, (margin, margin), src_mask)
    maskable.resize((192, 192), Image.LANCZOS).save(OUT_WEB / "Icon-maskable-192.png")
    maskable.resize((512, 512), Image.LANCZOS).save(OUT_WEB / "Icon-maskable-512.png")

    print(f"[OK] Icones PWA gerados em {OUT_WEB}")


def create_desktop_icon():
    size = 256
    if not SRC.exists():
        img = make_background(size, "#0A1628")
        draw = ImageDraw.Draw(img)
        draw.text((size // 2, size // 2), "MED", fill="white", anchor="mm")
    else:
        src = Image.open(SRC).convert("RGBA")
        img = make_background(size, "#0A1628")
        src.thumbnail((int(size * 0.75), int(size * 0.75)), Image.LANCZOS)
        sw, sh = src.size
        img.paste(src, ((size - sw) // 2, (size - sh) // 2), src)

    # Salva ico multiplo tamanho
    sizes = [16, 32, 48, 64, 128, 256]
    ico_images = []
    for s in sizes:
        ico_images.append(img.resize((s, s), Image.LANCZOS))

    OUT_DESKTOP.mkdir(parents=True, exist_ok=True)
    ico_path = OUT_DESKTOP / "app_icon.ico"
    ico_images[0].save(ico_path, format="ICO", sizes=[(x.width, x.height) for x in ico_images])
    print(f"[OK] Icone desktop gerado em {ico_path}")


def main():
    if not SRC.exists():
        print(f"AVISO: source nao encontrado: {SRC}")
    create_pwa_icon()
    create_desktop_icon()
    return 0


if __name__ == "__main__":
    sys.exit(main())
