"""Gera diagramas matematicos para os topicos 4.6 a 4.10."""

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


def draw_matrizes(d):
    d.text((60, 30), "Matriz 3 x 3", fill="#0D7C66", font=font(24, bold=True))
    # linhas horizontais e verticais
    x0, y0, w, h = 250, 120, 60, 50
    for i in range(4):
        d.line([(x0, y0 + i*h), (x0 + 3*w, y0 + i*h)], fill="#0D7C66", width=2)
    for j in range(4):
        d.line([(x0 + j*w, y0), (x0 + j*w, y0 + 3*h)], fill="#0D7C66", width=2)
    values = [["2", "3", "1"], ["0", "-1", "4"], ["5", "2", "-2"]]
    for i, row in enumerate(values):
        for j, val in enumerate(row):
            d.text((x0 + j*w + 15, y0 + i*h + 12), val, fill="#1A1A2E", font=font(20))
    d.text((500, 150), "determinante", fill="#0D7C66", font=font(20, bold=True))
    d.text((500, 190), "usando regra de Sarrus", fill="#0D7C66", font=font(18))
    d.text((500, 230), "ou Laplace", fill="#0D7C66", font=font(18))


def draw_trigonometria(d):
    d.text((60, 30), "Triangulo retangulo e razoes trigonometricas", fill="#0D7C66", font=font(22, bold=True))
    # triangulo retangulo
    d.polygon([(150, 100), (150, 400), (600, 400)], fill="#E0F2F1", outline="#0D7C66", width=3)
    # angulo reto
    d.rectangle([(150, 370), (180, 400)], fill="white", outline="#0D7C66", width=2)
    # catetos e hipotenusa
    d.text((60, 230), "cateto oposto", fill="red", font=font(18))
    d.text((350, 420), "cateto adjacente", fill="blue", font=font(18))
    d.text((380, 230), "hipotenusa", fill="green", font=font(18))
    d.text((170, 80), "teta", fill="#1A1A2E", font=font(20, bold=True))
    d.text((450, 100), "sen teta = oposto/hipotenusa", fill="#0D7C66", font=font(18))
    d.text((450, 130), "cos teta = adjacente/hipotenusa", fill="#0D7C66", font=font(18))
    d.text((450, 160), "tan teta = oposto/adjacente", fill="#0D7C66", font=font(18))


def draw_combinatoria(d):
    d.text((60, 30), "Arvore de possibilidades", fill="#0D7C66", font=font(24, bold=True))
    # arvore simples
    d.text((60, 120), "Inicio", fill="#1A1A2E", font=font(18))
    d.line([(120, 140), (250, 210)], fill="#0D7C66", width=2)
    d.line([(120, 140), (250, 120)], fill="#0D7C66", width=2)
    d.text((260, 100), "A", fill="#2196F3", font=font(20, bold=True))
    d.text((260, 200), "B", fill="#2196F3", font=font(20, bold=True))
    # ramificacoes
    d.line([(270, 110), (400, 80)], fill="#F44336", width=2)
    d.line([(270, 110), (400, 130)], fill="#F44336", width=2)
    d.line([(270, 220), (400, 190)], fill="#F44336", width=2)
    d.line([(270, 220), (400, 240)], fill="#F44336", width=2)
    d.text((410, 70), "1", fill="#1A1A2E", font=font(18))
    d.text((410, 120), "2", fill="#1A1A2E", font=font(18))
    d.text((410, 180), "1", fill="#1A1A2E", font=font(18))
    d.text((410, 230), "2", fill="#1A1A2E", font=font(18))
    d.text((500, 100), "A1, A2, B1, B2", fill="#0D7C66", font=font(20, bold=True))
    d.text((500, 140), "4 possibilidades", fill="#0D7C66", font=font(18))


def draw_estatistica(d):
    d.text((60, 30), "Grafico de barras: frequencia de notas", fill="#0D7C66", font=font(22, bold=True))
    # eixos
    d.line([(80, 420), (720, 420)], fill="#1A1A2E", width=2)
    d.line([(80, 420), (80, 80)], fill="#1A1A2E", width=2)
    # barras
    bars = [(150, 300, "3-5"), (280, 200, "5-7"), (410, 350, "7-9"), (540, 120, "9-10")]
    for x, h, label in bars:
        d.rectangle([(x, h), (x+80, 420)], fill="#4CAF50", outline="#0D7C66", width=2)
        d.text((x+15, 440), label, fill="#1A1A2E", font=font(16))
    d.text((300, 60), "media, moda e mediana", fill="#0D7C66", font=font(20, bold=True))


def draw_geo_analitica(d):
    d.text((60, 30), "Plano cartesiano e equacao da reta", fill="#0D7C66", font=font(22, bold=True))
    # eixos
    d.line([(400, 50), (400, 450)], fill="#1A1A2E", width=2)
    d.line([(50, 250), (750, 250)], fill="#1A1A2E", width=2)
    d.text((410, 60), "y", fill="#1A1A2E", font=font(18))
    d.text((730, 260), "x", fill="#1A1A2E", font=font(18))
    d.text((410, 260), "O", fill="#1A1A2E", font=font(18))
    # reta crescente
    d.line([(200, 350), (600, 150)], fill="#0D7C66", width=4)
    # ponto
    d.ellipse([(480-6, 190-6), (480+6, 190+6)], fill="red", outline="red")
    d.text((500, 170), "y = a.x + b", fill="red", font=font(20, bold=True))
    d.text((100, 360), "coeficiente angular = a", fill="#0D7C66", font=font(18))


def main():
    draw_functions = [
        ("mat_matrizes", draw_matrizes),
        ("mat_trigonometria", draw_trigonometria),
        ("mat_combinatoria", draw_combinatoria),
        ("mat_estatistica", draw_estatistica),
        ("mat_geo_analitica", draw_geo_analitica),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
