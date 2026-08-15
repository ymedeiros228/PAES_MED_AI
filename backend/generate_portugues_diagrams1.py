# -*- coding: utf-8 -*-
"""Gera diagramas para Lingua Portuguesa — topicos 5.1 a 5.4."""

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


def draw_comunicacao(d):
    d.text((60, 30), "Processo de comunicacao", fill="#0D7C66", font=font(24, bold=True))
    # caixas
    boxes = [
        (80, 150, "Emissor", "quem fala/"),
        (300, 150, "Mensagem", "conteudo"),
        (520, 150, "Receptor", "quem ouve"),
    ]
    for x, y, title, sub in boxes:
        d.rectangle([(x, y), (x+150, y+80)], fill="#E0F2F1", outline="#0D7C66", width=3)
        d.text((x+20, y+15), title, fill="#1A1A2E", font=font(20, bold=True))
        d.text((x+20, y+45), sub, fill="#1A1A2E", font=font(16))
    # setas
    d.line([(230, 190), (300, 190)], fill="#0D7C66", width=3)
    d.polygon([(290, 185), (300, 190), (290, 195)], fill="#0D7C66")
    d.line([(450, 190), (520, 190)], fill="#0D7C66", width=3)
    d.polygon([(510, 185), (520, 190), (510, 195)], fill="#0D7C66")
    # feedback
    d.line([(590, 230), (590, 280), (155, 280), (155, 230)], fill="red", width=2)
    d.polygon([(165, 225), (155, 230), (165, 235)], fill="red")
    d.text((300, 300), "Codigo = Lingua", fill="#0D7C66", font=font(20, bold=True))


def draw_semantica(d):
    d.text((60, 30), "Denotacao e conotacao", fill="#0D7C66", font=font(24, bold=True))
    # palavra centro
    d.rectangle([(300, 200), (500, 280)], fill="#E0F2F1", outline="#0D7C66", width=3)
    d.text((330, 225), "Sol", fill="#1A1A2E", font=font(30, bold=True))
    d.text((120, 120), "Denotacao", fill="blue", font=font(22, bold=True))
    d.text((120, 150), "astro celeste", fill="blue", font=font(18))
    d.line([(300, 170), (350, 200)], fill="blue", width=2)
    d.text((520, 120), "Conotacao", fill="red", font=font(22, bold=True))
    d.text((520, 150), "alegria", fill="red", font=font(18))
    d.text((520, 175), "esperanca", fill="red", font=font(18))
    d.line([(500, 170), (450, 200)], fill="red", width=2)


def draw_textualidade(d):
    d.text((60, 30), "Elementos da textualidade", fill="#0D7C66", font=font(24, bold=True))
    elements = [
        ("Coerencia", "sentido logico"),
        ("Coesao", "conectores"),
        ("Intencionalidade", "proposito"),
        ("Situacionalidade", "contexto"),
        ("Intertextualidade", "outros textos"),
    ]
    y = 100
    for tit, desc in elements:
        d.rectangle([(100, y), (700, y+50)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+12), tit, fill="#1A1A2E", font=font(20, bold=True))
        d.text((400, y+15), desc, fill="#1A1A2E", font=font(18))
        y += 65
    d.text((150, 440), "Sem coesao e coerencia nao ha texto", fill="#0D7C66", font=font(18, bold=True))


def draw_morfossintaxe(d):
    d.text((60, 30), "Classes gramaticais", fill="#0D7C66", font=font(24, bold=True))
    classes = [
        ("Substantivo", "medico"),
        ("Verbo", "curar"),
        ("Adjetivo", "sadio"),
        ("Pronome", "ele"),
        ("Advérbio", "hoje"),
    ]
    y = 100
    for c, ex in classes:
        d.rectangle([(100, y), (700, y+50)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+12), c, fill="#1A1A2E", font=font(20, bold=True))
        d.text((400, y+12), f'ex.: {ex}', fill="#0D7C66", font=font(20))
        y += 65


def main():
    draw_functions = [
        ("pt_comunicacao", draw_comunicacao),
        ("pt_semantica", draw_semantica),
        ("pt_textualidade", draw_textualidade),
        ("pt_morfossintaxe", draw_morfossintaxe),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
