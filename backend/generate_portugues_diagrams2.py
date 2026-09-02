"""Gera diagramas para Lingua Portuguesa — topicos 5.5 a 5.7."""

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


def draw_sintaxe_periodo(d):
    d.text((60, 30), "Periodo composto por coordenacao", fill="#0D7C66", font=font(24, bold=True))
    # oracoes em caixas
    oracoes = [
        (80, 150, "O paciente chegou", "oração 1"),
        (330, 150, "e foi atendido", "oração 2"),
        (580, 150, "rapidamente", "adverbio"),
    ]
    for x, y, text, label in oracoes:
        d.rectangle([(x, y), (x+210, y+80)], fill="#E0F2F1", outline="#0D7C66", width=3)
        d.text((x+15, y+15), text, fill="#1A1A2E", font=font(18, bold=True))
        d.text((x+15, y+50), label, fill="#0D7C66", font=font(16))
    # conectores
    d.line([(290, 190), (330, 190)], fill="#0D7C66", width=3)
    d.text((290, 165), "e", fill="#0D7C66", font=font(20, bold=True))
    d.line([(540, 190), (580, 190)], fill="#0D7C66", width=3)


def draw_literatura(d):
    d.text((60, 30), "Etapas da literatura brasileira", fill="#0D7C66", font=font(24, bold=True))
    periods = [
        ("Arcadismo", "sec XVIII"),
        ("Romantismo", "sec XIX"),
        ("Realismo", "sec XIX"),
        ("Modernismo", "sec XX"),
    ]
    y = 100
    for p, s in periods:
        d.rectangle([(100, y), (700, y+60)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+15), p, fill="#1A1A2E", font=font(22, bold=True))
        d.text((500, y+18), s, fill="#0D7C66", font=font(20))
        y += 75
    d.text((200, 420), "literatura: movimentos e contextos historicos", fill="#0D7C66", font=font(18))


def draw_obras(d):
    d.text((60, 30), "Obras de leitura obrigatoria", fill="#0D7C66", font=font(24, bold=True))
    obras = [
        "Memorias Postumas de Bras Cubas",
        "O Cortico",
        "Vidas Secas",
        "Grande Sertao: Veredas",
    ]
    y = 120
    for obra in obras:
        d.rectangle([(100, y), (700, y+55)], fill="#E0F2F1", outline="#0D7C66", width=2)
        d.text((110, y+15), obra, fill="#1A1A2E", font=font(20, bold=True))
        y += 70
    d.text((150, 430), "autores, enredo, personagens e contexto", fill="#0D7C66", font=font(18))


def main():
    draw_functions = [
        ("pt_sintaxe_periodo", draw_sintaxe_periodo),
        ("pt_literatura", draw_literatura),
        ("pt_obras", draw_obras),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
