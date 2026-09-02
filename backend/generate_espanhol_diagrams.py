"""Gera diagramas para Lingua Espanhola — topicos 7.1 a 7.3."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

IMG_DIR = Path(__file__).resolve().parent.parent / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)

FONT = "C:/Windows/Fonts/arial.ttf"
FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"

def font(size, bold=False):
    try:
        return ImageFont.truetype(FONT_BOLD if bold else FONT, size)
    except Exception:
        return ImageFont.load_default()


def save(diagram_name, draw_fn):
    out = IMG_DIR / f"{diagram_name}.png"
    img = Image.new("RGB", (800, 500), "white")
    d = ImageDraw.Draw(img)
    draw_fn(d)
    img.save(out, "PNG")
    print(f"  Diagrama: {out}")
    return out


def draw_comprension(d):
    d.text((60, 30), "Comprension de textos", fill="#0D7C66", font=font(24, bold=True))
    generos = [
        ("Vineta", "historieta"),
        ("Noticia", "hecho real"),
        ("Publicidad", "persuadir"),
        ("Tira comica", "humor"),
    ]
    y = 100
    for g, desc in generos:
        d.rectangle([(100, y), (700, y+55)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+15), g, fill="#1A1A2E", font=font(20, bold=True))
        d.text((400, y+18), desc, fill="#0D7C66", font=font(18))
        y += 70
    d.text((200, 420), "Identificar el genero ayuda a comprender", fill="#0D7C66", font=font(18))


def draw_semantica(d):
    d.text((60, 30), "Relaciones semanticas", fill="#0D7C66", font=font(24, bold=True))
    rels = [
        ("Sinonimia", "igual significado"),
        ("Antonimia", "significado opuesto"),
        ("Homonimia", "igual forma, distinto significado"),
        ("Polisemia", "varios significados"),
        ("Paronimia", "palabras parecidas"),
    ]
    y = 100
    for r, desc in rels:
        d.rectangle([(100, y), (700, y+55)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+15), r, fill="#1A1A2E", font=font(20, bold=True))
        d.text((400, y+18), desc, fill="#0D7C66", font=font(18))
        y += 65


def draw_gramatica(d):
    d.text((60, 30), "Modos verbales en espanol", fill="#0D7C66", font=font(24, bold=True))
    modos = [
        ("Indicativo", "realidad, hechos"),
        ("Subjuntivo", "deseo, duda"),
        ("Imperativo", "orden, ruego"),
    ]
    y = 120
    colors = ["#2196F3", "#FF9800", "#4CAF50"]
    for (m, desc), c in zip(modos, colors, strict=False):
        d.rectangle([(100, y), (700, y+70)], fill="#E0F2F1", outline=c, width=3)
        d.text((110, y+15), m, fill=c, font=font(22, bold=True))
        d.text((400, y+20), desc, fill="#1A1A2E", font=font(18))
        y += 90
    d.text((200, 410), "Tres modos, varios tiempos, muchas formas", fill="#0D7C66", font=font(18))


def main():
    draw_functions = [
        ("esp_comprension", draw_comprension),
        ("esp_semantica", draw_semantica),
        ("esp_gramatica", draw_gramatica),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
