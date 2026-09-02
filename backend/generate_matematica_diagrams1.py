"""Gera diagramas matematicos para os topicos 4.1 a 4.5."""

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


def draw_aritmetica(d):
    d.text((60, 30), "Porcentagem e fracao", fill="#0D7C66", font=font(24, bold=True))
    # pizza
    cx, cy, r = 400, 280, 140
    d.ellipse([(cx-r, cy-r), (cx+r, cy+r)], fill="#E0F2F1", outline="#0D7C66", width=3)
    # 25 por cento
    d.pieslice([(cx-r, cy-r), (cx+r, cy+r)], start=0, end=90, fill="#4CAF50", outline="#0D7C66", width=2)
    d.text((cx+50, cy-100), "25%", fill="white", font=font(22, bold=True))
    d.text((cx-60, cy+40), "75%", fill="#1A1A2E", font=font(22, bold=True))
    d.text((470, 80), "25% = 1/4 = 0,25", fill="#0D7C66", font=font(22, bold=True))
    d.text((470, 120), "75% = 3/4 = 0,75", fill="#0D7C66", font=font(22))


def draw_conjuntos(d):
    d.text((60, 30), "Diagrama de Venn: intersecao de conjuntos", fill="#0D7C66", font=font(24, bold=True))
    # Dois circulos sobrepostos
    d.ellipse([(150, 150), (400, 400)], outline="#2196F3", width=4)
    d.ellipse([(400, 150), (650, 400)], outline="#F44336", width=4)
    d.text((240, 130), "A", fill="#2196F3", font=font(26, bold=True))
    d.text((520, 130), "B", fill="#F44336", font=font(26, bold=True))
    d.text((240, 240), "1, 2", fill="#1A1A2E", font=font(22))
    d.text((520, 240), "5, 6", fill="#1A1A2E", font=font(22))
    d.text((370, 240), "3, 4", fill="#0D7C66", font=font(22, bold=True))
    d.text((330, 420), "A inter B = {3, 4}", fill="#0D7C66", font=font(22, bold=True))


def draw_funcoes(d):
    d.text((60, 30), "Funcao do 1o grau: f(x) = ax + b", fill="#0D7C66", font=font(24, bold=True))
    # eixos
    d.line([(80, 420), (720, 420)], fill="#1A1A2E", width=2)
    d.line([(80, 420), (80, 80)], fill="#1A1A2E", width=2)
    d.text((740, 410), "x", fill="#1A1A2E", font=font(18))
    d.text((60, 60), "y", fill="#1A1A2E", font=font(18))
    # reta
    d.line([(80, 340), (600, 120)], fill="#0D7C66", width=4)
    # pontos
    d.ellipse([(150-5, 310-5), (150+5, 310+5)], fill="red", outline="red")
    d.ellipse([(420-5, 190-5), (420+5, 190+5)], fill="red", outline="red")
    d.text((100, 340), "(0, b)", fill="red", font=font(18))
    d.text((440, 170), "reta crescente", fill="red", font=font(18))


def draw_geo_plana(d):
    d.text((60, 30), "Areas de figuras planas", fill="#0D7C66", font=font(24, bold=True))
    # triangulo
    d.polygon([(150, 350), (300, 350), (150, 150)], fill="#E0F2F1", outline="#0D7C66", width=3)
    d.text((170, 360), "A = (b . h)/2", fill="#0D7C66", font=font(18))
    # retangulo
    d.rectangle([(400, 150), (650, 350)], fill="#C8E6C9", outline="#0D7C66", width=3)
    d.text((480, 360), "A = b . h", fill="#0D7C66", font=font(18))
    d.text((430, 100), "base (b)", fill="#1A1A2E", font=font(18))
    d.text((350, 220), "altura (h)", fill="#1A1A2E", font=font(18))


def draw_geo_espacial(d):
    d.text((60, 30), "Volumes de solidos geometricos", fill="#0D7C66", font=font(24, bold=True))
    # cubo
    d.rectangle([(120, 180), (320, 380)], fill="#E0F2F1", outline="#0D7C66", width=3)
    d.text((140, 390), "Cubo: V = a^3", fill="#0D7C66", font=font(20, bold=True))
    # cilindro
    d.rectangle([(450, 180), (700, 380)], fill="#C8E6C9", outline="#0D7C66", width=3)
    d.ellipse([(450, 160), (700, 210)], fill="#C8E6C9", outline="#0D7C66", width=2)
    d.ellipse([(450, 350), (700, 400)], fill="#C8E6C9", outline="#0D7C66", width=2)
    d.text((500, 100), "V = pi . r^2 . h", fill="#0D7C66", font=font(20, bold=True))


def main():
    draw_functions = [
        ("mat_aritmetica", draw_aritmetica),
        ("mat_conjuntos", draw_conjuntos),
        ("mat_funcoes", draw_funcoes),
        ("mat_geo_plana", draw_geo_plana),
        ("mat_geo_espacial", draw_geo_espacial),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
