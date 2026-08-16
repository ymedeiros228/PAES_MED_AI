# -*- coding: utf-8 -*-
"""Gera diagramas para Lingua Inglesa — topicos 6.1 a 6.3."""

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


def draw_leitura(d):
    d.text((60, 30), "Reading strategies: skimming and scanning", fill="#0D7C66", font=font(24, bold=True))
    # Skimming box
    d.rectangle([(80, 100), (380, 280)], fill="#E0F2F1", outline="#0D7C66", width=3)
    d.text((110, 120), "SKIMMING", fill="#1A1A2E", font=font(22, bold=True))
    d.text((100, 160), "general idea", fill="#0D7C66", font=font(18))
    d.text((100, 190), "read quickly", fill="#1A1A2E", font=font(16))
    d.text((100, 215), "titles, headings", fill="#1A1A2E", font=font(16))
    d.text((100, 240), "first/last paragraphs", fill="#1A1A2E", font=font(16))
    # Scanning box
    d.rectangle([(420, 100), (720, 280)], fill="#C8E6C9", outline="#0D7C66", width=3)
    d.text((450, 120), "SCANNING", fill="#1A1A2E", font=font(22, bold=True))
    d.text((440, 160), "specific info", fill="#0D7C66", font=font(18))
    d.text((440, 190), "look for keywords", fill="#1A1A2E", font=font(16))
    d.text((440, 215), "numbers, dates", fill="#1A1A2E", font=font(16))
    d.text((440, 240), "names, places", fill="#1A1A2E", font=font(16))
    # arrow
    d.text((300, 330), "Both are fast reading techniques", fill="#0D7C66", font=font(20, bold=True))
    d.text((200, 380), "Use skimming for the 'big picture'", fill="#1A1A2E", font=font(18))
    d.text((200, 410), "Use scanning for a specific detail", fill="#1A1A2E", font=font(18))


def draw_lexico(d):
    d.text((60, 30), "Cognates and false friends", fill="#0D7C66", font=font(24, bold=True))
    # True cognates
    d.rectangle([(80, 100), (380, 250)], fill="#E0F2F1", outline="#4CAF50", width=3)
    d.text((110, 115), "TRUE COGNATES", fill="#4CAF50", font=font(20, bold=True))
    pairs_t = [("doctor", "doctor"), ("medicine", "medicina"), ("hospital", "hospital")]
    y = 150
    for en, pt in pairs_t:
        d.text((100, y), f"{en} = {pt}", fill="#1A1A2E", font=font(18))
        y += 30
    # False friends
    d.rectangle([(420, 100), (720, 250)], fill="#FFEBEE", outline="#F44336", width=3)
    d.text((440, 115), "FALSE FRIENDS", fill="#F44336", font=font(20, bold=True))
    pairs_f = [("actually", "na verdade"), ("parents", "pais"), ("recipe", "receita")]
    y = 150
    for en, pt in pairs_f:
        d.text((440, y), f"{en} != {pt}", fill="#1A1A2E", font=font(18))
        y += 30
    d.text((150, 300), "Cognates help; false friends trick you", fill="#0D7C66", font=font(20, bold=True))
    d.text((200, 350), "Always check the context", fill="#1A1A2E", font=font(18))


def draw_gramatica(d):
    d.text((60, 30), "Verb tenses overview", fill="#0D7C66", font=font(24, bold=True))
    # timeline
    d.line([(80, 250), (720, 250)], fill="#1A1A2E", width=3)
    # past
    d.ellipse([(150-8, 250-8), (150+8, 250+8)], fill="#2196F3", outline="black", width=2)
    d.text((100, 270), "PAST", fill="#2196F3", font=font(20, bold=True))
    d.text((80, 300), "I worked", fill="#1A1A2E", font=font(16))
    # present
    d.ellipse([(400-8, 250-8), (400+8, 250+8)], fill="#4CAF50", outline="black", width=2)
    d.text((360, 270), "PRESENT", fill="#4CAF50", font=font(20, bold=True))
    d.text((360, 300), "I work", fill="#1A1A2E", font=font(16))
    # future
    d.ellipse([(650-8, 250-8), (650+8, 250+8)], fill="#FF9800", outline="black", width=2)
    d.text((610, 270), "FUTURE", fill="#FF9800", font=font(20, bold=True))
    d.text((600, 300), "I will work", fill="#1A1A2E", font=font(16))
    # arrows
    d.line([(160, 250), (390, 250)], fill="#0D7C66", width=2)
    d.polygon([(380, 245), (390, 250), (380, 255)], fill="#0D7C66")
    d.line([(410, 250), (640, 250)], fill="#0D7C66", width=2)
    d.polygon([(630, 245), (640, 250), (630, 255)], fill="#0D7C66")
    d.text((150, 380), "Simple, continuous, perfect and perfect continuous forms", fill="#0D7C66", font=font(18, bold=True))
    d.text((200, 420), "Each tense has 4 aspects", fill="#1A1A2E", font=font(18))


def main():
    draw_functions = [
        ("ing_leitura", draw_leitura),
        ("ing_lexico", draw_lexico),
        ("ing_gramatica", draw_gramatica),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
