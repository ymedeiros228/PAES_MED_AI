# -*- coding: utf-8 -*-
"""Gera diagramas educacionais simples para os PDFs de Fisica.

Usa PIL para criar PNGs claros, sem pessoas, focados em conceitos.
"""

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


def draw_grandezas(d):
    d.text((40, 30), "Sistema Internacional (SI) - unidades fundamentais", fill="#0D7C66", font=font(24, bold=True))
    rows = [
        ("Comprimento", "metro (m)"),
        ("Massa", "quilograma (kg)"),
        ("Tempo", "segundo (s)"),
        ("Corrente", "ampere (A)"),
        ("Temperatura", "kelvin (K)"),
    ]
    y = 90
    for nome, un in rows:
        d.rectangle([(40, y), (780, y+45)], outline="#0D7C66", width=2)
        d.text((50, y+10), nome, fill="#1A1A2E", font=font(20))
        d.text((400, y+10), un, fill="#0D7C66", font=font(20, bold=True))
        y += 60


def draw_cinematica(d):
    d.text((60, 20), "Grafico s x t no movimento uniforme", fill="#0D7C66", font=font(24, bold=True))
    # Eixos
    d.line([(80, 420), (720, 420)], fill="#1A1A2E", width=2)  # eixo t
    d.line([(80, 420), (80, 80)], fill="#1A1A2E", width=2)   # eixo s
    d.text((740, 410), "t", fill="#1A1A2E", font=font(18))
    d.text((60, 60), "s", fill="#1A1A2E", font=font(18))
    # Reta crescente
    d.line([(80, 360), (600, 120)], fill="#0D7C66", width=4)
    d.text((100, 380), "A inclinacao da reta e a velocidade", fill="#0D7C66", font=font(18))


def draw_dinamica(d):
    d.text((60, 30), "Forcas em um bloco sobre plano inclinado", fill="#0D7C66", font=font(24, bold=True))
    # plano
    d.polygon([(150, 420), (650, 420), (650, 150)], fill="#E0F2F1", outline="#0D7C66", width=2)
    # bloco
    d.rectangle([(530, 130), (620, 200)], fill="#2196F3", outline="black", width=2)
    # peso
    d.line([(575, 165), (575, 320)], fill="red", width=4)
    d.text((590, 330), "Peso (P)", fill="red", font=font(18))
    # normal
    d.line([(575, 165), (575, 60)], fill="green", width=4)
    d.text((590, 40), "Normal (N)", fill="green", font=font(18))
    # componente paralela
    d.line([(575, 165), (670, 230)], fill="orange", width=4)
    d.text((680, 240), "P.sen(alfa)", fill="orange", font=font(18))


def draw_hidrostatica(d):
    d.text((60, 30), "Pressao hidrostatica aumenta com a profundidade", fill="#0D7C66", font=font(22, bold=True))
    # recipiente
    d.rectangle([(250, 120), (550, 420)], outline="#0D7C66", width=3)
    # agua
    d.rectangle([(250, 220), (550, 420)], fill="#81D4FA", outline="#0D7C66", width=2)
    # linhas de pressao
    for i, y in enumerate([260, 310, 360, 410]):
        x = 560
        d.line([(x, y), (x+80+(i*15), y)], fill="red", width=3)
        d.polygon([(x+75+(i*15), y-5), (x+95+(i*15), y), (x+75+(i*15), y+5)], fill="red")
    d.text((580, 80), "p = p0 + d.g.h", fill="#0D7C66", font=font(22, bold=True))


def draw_termologia(d):
    d.text((60, 30), "Escalas termometricas", fill="#0D7C66", font=font(24, bold=True))
    # termometro
    d.ellipse([(360, 390), (440, 470)], fill="#FF5722", outline="black", width=2)
    d.rectangle([(385, 100), (415, 400)], fill="#FFCCBC", outline="black", width=2)
    # marcas
    for y, label in [(160, "100 oC - 212 oF - 373 K"), (260, "0 oC - 32 oF - 273 K"), (360, "-273 oC - 0 K")]:
        d.line([(340, y), (460, y)], fill="#0D7C66", width=2)
        d.text((470, y-10), label, fill="#1A1A2E", font=font(17))


def draw_optica(d):
    d.text((60, 30), "Refracao da luz: ar para agua", fill="#0D7C66", font=font(24, bold=True))
    # superficie
    d.line([(50, 280), (750, 280)], fill="#1A1A2E", width=2)
    d.text((60, 300), "agua (n maior)", fill="#0D7C66", font=font(18))
    d.text((60, 230), "ar (n menor)", fill="#0D7C66", font=font(18))
    # raio incidente
    d.line([(150, 50), (400, 280)], fill="red", width=4)
    d.text((80, 60), "incidente", fill="red", font=font(18))
    # raio refratado
    d.line([(400, 280), (650, 420)], fill="blue", width=4)
    d.text((660, 430), "refratado", fill="blue", font=font(18))
    # normal
    d.line([(400, 80), (400, 450)], fill="black", width=2)
    d.text((410, 460), "normal", fill="#1A1A2E", font=font(18))
    d.text((450, 90), "n1.sen(teta1) = n2.sen(teta2)", fill="#0D7C66", font=font(20, bold=True))


def draw_ondulatoria(d):
    d.text((60, 30), "Onda: comprimento e amplitude", fill="#0D7C66", font=font(24, bold=True))
    # eixo
    d.line([(60, 250), (740, 250)], fill="black", width=2)
    # senoide
    pts = []
    for x in range(100, 700, 5):
        import math
        y = 250 + 100 * math.sin((x - 100) / 60.0)
        pts.append((x, y))
    if len(pts) > 1:
        d.line(pts, fill="#0D7C66", width=4)
    # labels
    d.line([(160, 150), (160, 350)], fill="red", width=2)
    d.line([(160, 350), (520, 350)], fill="red", width=2)
    d.text((250, 360), "comprimento (lambda)", fill="red", font=font(18))
    d.text((500, 130), "amplitude", fill="red", font=font(18))


def draw_eletrostatica(d):
    d.text((60, 30), "Cargas eletricas: opostos atraem, iguais repetem", fill="#0D7C66", font=font(22, bold=True))
    # cargas +
    d.ellipse([(120, 180), (220, 280)], fill="#F44336", outline="black", width=2)
    d.text((155, 210), "+", fill="white", font=font(40))
    d.ellipse([(580, 180), (680, 280)], fill="#2196F3", outline="black", width=2)
    d.text((615, 210), "-", fill="white", font=font(40))
    d.line([(230, 230), (560, 230)], fill="green", width=4)
    d.polygon([(560, 230-8), (580, 230), (560, 230+8)], fill="green")
    d.text((280, 250), "atrai", fill="green", font=font(20, bold=True))
    # iguais repelem embaixo
    d.ellipse([(120, 330), (220, 430)], fill="#F44336", outline="black", width=2)
    d.text((155, 360), "+", fill="white", font=font(40))
    d.ellipse([(580, 330), (680, 430)], fill="#F44336", outline="black", width=2)
    d.text((615, 360), "+", fill="white", font=font(40))
    d.line([(120, 330), (580, 330)], fill="orange", width=4)
    d.text((300, 290), "repelem", fill="orange", font=font(20, bold=True))


def draw_eletrodinamica(d):
    d.text((60, 30), "Circuito com resistores em serie", fill="#0D7C66", font=font(24, bold=True))
    # fonte
    d.rectangle([(80, 200), (180, 250)], fill="#FFEB3B", outline="black", width=2)
    d.text((100, 210), "pilha V", fill="black", font=font(18))
    # fios
    d.line([(180, 225), (700, 225)], fill="black", width=3)
    d.line([(700, 225), (700, 350)], fill="black", width=3)
    d.line([(700, 350), (80, 350)], fill="black", width=3)
    d.line([(80, 350), (80, 250)], fill="black", width=3)
    # resistores
    for x in [300, 450, 600]:
        d.rectangle([(x, 200), (x+60, 250)], fill="#2196F3", outline="black", width=2)
        d.text((x+15, 215), "R", fill="white", font=font(18, bold=True))
    d.text((250, 260), "A corrente e a mesma em todos os resistores", fill="#0D7C66", font=font(18))


def draw_eletromagnetismo(d):
    d.text((60, 30), "Campo magnetico ao redor de um fio com corrente", fill="#0D7C66", font=font(22, bold=True))
    # fio
    d.ellipse([(370, 200), (430, 260)], fill="#9E9E9E", outline="black", width=2)
    d.text((380, 215), "i", fill="white", font=font(22, bold=True))
    # circulos concentricos
    for r in [80, 130, 180]:
        d.ellipse([(400-r, 230-r), (400+r, 230+r)], outline="#0D7C66", width=3)
        d.polygon([(400+r-5, 230-8), (400+r+5, 230), (400+r-5, 230+8)], fill="#0D7C66")
    d.text((550, 230), "sentido pela regra da mao direita", fill="#0D7C66", font=font(18))


def draw_fisica_moderna(d):
    d.text((60, 30), "Radiacao: alfa, beta e gama", fill="#0D7C66", font=font(24, bold=True))
    # fonte
    d.ellipse([(80, 200), (180, 300)], fill="#333333", outline="black", width=2)
    d.text((110, 240), "nucleo", fill="white", font=font(18))
    # alfa
    d.line([(180, 220), (350, 150)], fill="red", width=4)
    d.text((360, 130), "alfa", fill="red", font=font(18, bold=True))
    # beta
    d.line([(180, 250), (360, 250)], fill="blue", width=3)
    d.text((370, 240), "beta", fill="blue", font=font(18, bold=True))
    # gama
    d.line([(180, 280), (350, 360)], fill="green", width=2)
    d.text((360, 360), "gama", fill="green", font=font(18, bold=True))
    d.text((450, 180), "poder de penetracao:", fill="#1A1A2E", font=font(20, bold=True))
    d.text((450, 210), "gama > beta > alfa", fill="#0D7C66", font=font(20))


def main():
    draw_functions = [
        ("fi_grandezas", draw_grandezas),
        ("fi_cinematica", draw_cinematica),
        ("fi_dinamica", draw_dinamica),
        ("fi_hidrostatica", draw_hidrostatica),
        ("fi_termologia", draw_termologia),
        ("fi_optica", draw_optica),
        ("fi_ondulatoria", draw_ondulatoria),
        ("fi_eletrostatica", draw_eletrostatica),
        ("fi_eletrodinamica", draw_eletrodinamica),
        ("fi_eletromagnetismo", draw_eletromagnetismo),
        ("fi_fisica_moderna", draw_fisica_moderna),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
