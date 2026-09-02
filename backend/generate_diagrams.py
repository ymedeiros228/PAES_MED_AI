"""Gera diagramas proprios em PT-BR usando reportlab graphics.

Vantagens:
- Texto 100% PT-BR (Portugues Brasileiro)
- Alta qualidade (vetorial -> PNG em alta resolucao)
- Sem dependencia de SVGs de terceiros
- Controle total do conteudo
"""

from pathlib import Path

from reportlab.graphics.renderPM import drawToFile
from reportlab.graphics.shapes import Circle, Drawing, Line, Polygon, Rect, String
from reportlab.lib.colors import HexColor, white

ROOT = Path(__file__).resolve().parent.parent
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)

# Cores
C_PHOSPHO_HEAD = HexColor("#4CAF50")  # verde - cabeca hidrofilica
C_PHOSPHO_TAIL = HexColor("#FF9800")  # laranja - cauda hidrofobica
C_PROTEIN = HexColor("#2196F3")       # azul - proteina
C_CHOLESTEROL = HexColor("#9C27B0")   # roxo - colesterol
C_GLYCO = HexColor("#FF5722")         # vermelho-laranja - glicocalix
C_CYTOPLASM = HexColor("#E8F5E9")     # verde claro - citoplasma
C_EXTRA = HexColor("#E3F2FD")         # azul claro - extracelular
C_TEXT = HexColor("#1A1A2E")
C_ARROW = HexColor("#333333")
C_NA = HexColor("#FFC107")            # amarelo - Na+
C_K = HexColor("#00BCD4")             # cyan - K+
C_WATER = HexColor("#81D4FA")         # azul agua
C_CELL = HexColor("#A5D6A7")          # verde celula


def draw_phospholipid(x, y, scale=1.0, drawing=None):
    """Desenha um fosfolipidio (cabeca + 2 caudas)."""
    s = scale
    # Cabeca (circulo verde)
    head = Circle(x, y, 8*s, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=0.5)
    # Caudas (2 linhas)
    tail1 = Line(x-3*s, y-8*s, x-3*s, y-25*s, strokeWidth=2*s, strokeColor=C_PHOSPHO_TAIL)
    tail2 = Line(x+3*s, y-8*s, x+3*s, y-25*s, strokeWidth=2*s, strokeColor=C_PHOSPHO_TAIL)
    drawing.add(tail1)
    drawing.add(tail2)
    drawing.add(head)


def diagram_bicamada():
    """Diagrama da bicamada lipidica com proteinas e colesterol."""
    w, h = 1200, 800
    d = Drawing(w, h)

    # Fundo: extracelular (topo) e citoplasma (base)
    d.add(Rect(0, 600, w, 200, fillColor=C_EXTRA, strokeColor=None))  # extracelular
    d.add(Rect(0, 0, w, 200, fillColor=C_CYTOPLASM, strokeColor=None))  # citoplasma

    # Linhas divisorias
    d.add(Line(0, 600, w, 600, strokeColor=HexColor("#90CAF9"), strokeWidth=1))
    d.add(Line(0, 200, w, 200, strokeColor=HexColor("#A5D6A7"), strokeWidth=1))

    # Bicamada: fosfolipidios
    # Camada superior (cabecas para cima)
    for i in range(30):
        x = 20 + i * 40
        draw_phospholipid(x, 580, 1.0, d)  # cabeca na linha 580, caudas para baixo

    # Camada inferior (cabecas para baixo)
    for i in range(30):
        x = 20 + i * 40
        # Inverter: cabeca embaixo, caudas para cima
        head = Circle(x, 220, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=0.5)
        tail1 = Line(x-3, 228, x-3, 245, strokeWidth=2, strokeColor=C_PHOSPHO_TAIL)
        tail2 = Line(x+3, 228, x+3, 245, strokeWidth=2, strokeColor=C_PHOSPHO_TAIL)
        d.add(tail1)
        d.add(tail2)
        d.add(head)

    # Proteina transmembrana (atravessa a bicamada)
    px = 300
    d.add(Rect(px-25, 200, 50, 400, fillColor=C_PROTEIN, strokeColor=white, strokeWidth=1, rx=10, ry=10))

    # Proteina periferica externa
    d.add(Rect(550, 590, 60, 30, fillColor=C_PROTEIN, strokeColor=white, strokeWidth=1, rx=5, ry=5))

    # Proteina periferica interna
    d.add(Rect(700, 180, 60, 30, fillColor=C_PROTEIN, strokeColor=white, strokeWidth=1, rx=5, ry=5))

    # Proteina de canal
    px2 = 850
    d.add(Rect(px2-20, 220, 40, 360, fillColor=C_PROTEIN, strokeColor=white, strokeWidth=1, rx=8, ry=8))
    # Buraco do canal
    d.add(Rect(px2-8, 250, 16, 300, fillColor=C_EXTRA, strokeColor=None))

    # Colesterol (losangos roxos)
    for cx in [150, 450, 650, 950]:
        cy = 400
        d.add(Polygon([cx, cy+12, cx+10, cy, cx, cy-12, cx-10, cy],
                      fillColor=C_CHOLESTEROL, strokeColor=white, strokeWidth=0.5))

    # Glicocalix (linhas vermelhas na face externa)
    for i in range(15):
        gx = 60 + i * 75
        d.add(Line(gx, 610, gx, 625, strokeWidth=2, strokeColor=C_GLYCO))
        d.add(Circle(gx, 628, 3, fillColor=C_GLYCO, strokeColor=None))

    # Filamentos do citoesqueleto
    for i in range(5):
        fx = 680 + i * 8
        d.add(Line(fx, 180, fx, 140, strokeWidth=1.5, strokeColor=HexColor("#795548")))

    # === LABELS (PT-BR) ===
    font_size = 14
    font_bold = "Helvetica-Bold"

    labels = [
        ("Fluido extracelular", 600, 750, C_TEXT),
        ("Citoplasma", 600, 50, C_TEXT),
        ("Cabecas hidrofilicas", 80, 580, C_TEXT),
        ("Caudas hidrofobicas", 80, 400, C_TEXT),
        ("Cabecas hidrofilicas", 80, 220, C_TEXT),
        ("Fosfolipidio", 180, 580, C_TEXT),
        ("Proteina transmembrana", 300, 420, white),
        ("Proteina periferica", 580, 605, white),
        ("Proteina periferica", 730, 195, white),
        ("Canal proteico", 850, 400, white),
        ("Colesterol", 450, 370, C_TEXT),
        ("Glicocalix", 600, 660, C_GLYCO),
        ("Filamentos do citoesqueleto", 720, 130, HexColor("#795548")),
        ("Bicamada lipidica", 1050, 400, C_TEXT),
    ]

    for text, x, y, color in labels:
        d.add(String(x, y, text, fontSize=font_size, fontName=font_bold,
                     fillColor=color, textAnchor="middle"))

    # Setas indicadoras
    # Seta para cabeca hidrofilica
    d.add(Line(180, 565, 180, 545, strokeColor=C_ARROW, strokeWidth=1.5))
    # Seta para cauda
    d.add(Line(180, 385, 180, 365, strokeColor=C_ARROW, strokeWidth=1.5))

    # Salvar como PNG em alta resolucao
    outpath = IMG_DIR / "diag_bicamada.png"
    drawToFile(d, str(outpath), fmt="PNG", dpi=200)
    print(f"  Diagrama bicamada: {outpath.name}")
    return outpath


def diagram_transporte():
    """Diagrama dos tipos de transporte atraves da membrana."""
    w, h = 1400, 900
    d = Drawing(w, h)

    # 4 paineis: Difusao simples, Difusao facilitada, Osmose, Transporte ativo
    panel_w = 340
    panel_h = 700

    panels = [
        {"x": 10, "titulo": "Difusao Simples", "sub": "(Sem proteina, sem ATP)",
         "cor": HexColor("#E8F5E9")},
        {"x": 370, "titulo": "Difusao Facilitada", "sub": "(Com proteina, sem ATP)",
         "cor": HexColor("#E3F2FD")},
        {"x": 730, "titulo": "Osmose", "sub": "(Agua, sem ATP)",
         "cor": HexColor("#FFF3E0")},
        {"x": 1090, "titulo": "Transporte Ativo", "sub": "(Com proteina + ATP)",
         "cor": HexColor("#FCE4EC")},
    ]

    for p in panels:
        # Fundo do painel
        d.add(Rect(p["x"], 50, panel_w, panel_h, fillColor=p["cor"],
                   strokeColor=HexColor("#CCCCCC"), strokeWidth=1, rx=10, ry=10))
        # Titulo
        d.add(String(p["x"] + panel_w/2, 720, p["titulo"],
                     fontSize=16, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))
        d.add(String(p["x"] + panel_w/2, 700, p["sub"],
                     fontSize=11, fontName="Helvetica",
                     fillColor=HexColor("#666666"), textAnchor="middle"))

        # Membrana (bicamada simplificada)
        mx = p["x"] + 20
        mw = panel_w - 40

        # Linhas da bicamada
        for i in range(20):
            lx = mx + i * (mw/20)
            # Camada superior
            d.add(Circle(lx, 450, 6, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            d.add(Line(lx-2, 444, lx-2, 430, strokeWidth=1.5, strokeColor=C_PHOSPHO_TAIL))
            d.add(Line(lx+2, 444, lx+2, 430, strokeWidth=1.5, strokeColor=C_PHOSPHO_TAIL))
            # Camada inferior
            d.add(Circle(lx, 350, 6, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            d.add(Line(lx-2, 356, lx-2, 370, strokeWidth=1.5, strokeColor=C_PHOSPHO_TAIL))
            d.add(Line(lx+2, 356, lx+2, 370, strokeWidth=1.5, strokeColor=C_PHOSPHO_TAIL))

        # Labels
        d.add(String(p["x"] + panel_w/2, 660, "Extracelular",
                     fontSize=10, fontName="Helvetica",
                     fillColor=HexColor("#666"), textAnchor="middle"))
        d.add(String(p["x"] + panel_w/2, 150, "Intracelular",
                     fontSize=10, fontName="Helvetica",
                     fillColor=HexColor("#666"), textAnchor="middle"))

    # === PAINEL 1: Difusao Simples ===
    px = 10
    # Moleculas pequenas (O2, CO2) atravessando diretamente
    for i, y in enumerate([480, 460, 440, 420, 400, 380, 360, 340, 320, 300]):
        x = px + 170 + (i % 3) * 30 - 30
        d.add(Circle(x, y, 5, fillColor=HexColor("#FF7043"), strokeColor=white, strokeWidth=0.5))
    # Seta de gradiente
    d.add(String(px + 170, 580, "O2, CO2", fontSize=12, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(px + 170, 560, "esteroides", fontSize=10, fontName="Helvetica",
                 fillColor=HexColor("#666"), textAnchor="middle"))
    # Seta para baixo
    d.add(Line(px + 170, 540, px + 170, 520, strokeColor=C_ARROW, strokeWidth=2))
    d.add(Polygon([px+170, 515, px+165, 525, px+175, 525], fillColor=C_ARROW))
    d.add(String(px + 200, 530, "gradiente", fontSize=9, fontName="Helvetica-Oblique",
                 fillColor=HexColor("#666")))

    # === PAINEL 2: Difusao Facilitada ===
    px = 370
    # Proteina carrier
    d.add(Rect(px + 140, 350, 60, 100, fillColor=C_PROTEIN, strokeColor=white,
               strokeWidth=1, rx=15, ry=15))
    # Molecula (glicose)
    d.add(Circle(px + 170, 500, 8, fillColor=HexColor("#FFEB3B"),
                 strokeColor=HexColor("#F57F17"), strokeWidth=1))
    d.add(String(px + 170, 520, "glicose", fontSize=10, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    # Molecula passando pela proteina
    d.add(Circle(px + 170, 400, 8, fillColor=HexColor("#FFEB3B"),
                 strokeColor=HexColor("#F57F17"), strokeWidth=1))
    # Molecula do outro lado
    d.add(Circle(px + 170, 300, 8, fillColor=HexColor("#FFEB3B"),
                 strokeColor=HexColor("#F57F17"), strokeWidth=1))
    # Setas
    d.add(Line(px + 170, 490, px + 170, 460, strokeColor=C_ARROW, strokeWidth=2))
    d.add(Polygon([px+170, 455, px+165, 465, px+175, 465], fillColor=C_ARROW))
    d.add(String(px + 170, 580, "Proteina", fontSize=10, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(px + 170, 565, "carreadora", fontSize=10, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))

    # === PAINEL 3: Osmose ===
    px = 730
    # Agua (moleculas azuis)
    for i in range(20):
        x = px + 40 + (i % 5) * 50
        y = 580 + (i // 5) * 25
        d.add(Circle(x, y, 4, fillColor=C_WATER, strokeColor=HexColor("#0288D1"), strokeWidth=0.5))
    # Menos agua do lado intracelular (mais concentrado)
    for i in range(8):
        x = px + 40 + (i % 4) * 60
        y = 200 + (i // 4) * 30
        d.add(Circle(x, y, 4, fillColor=C_WATER, strokeColor=HexColor("#0288D1"), strokeWidth=0.5))
    # Seta de agua atravessando
    d.add(Line(px + 170, 480, px + 170, 370, strokeColor=C_WATER, strokeWidth=3))
    d.add(Polygon([px+170, 365, px+163, 378, px+177, 378], fillColor=C_WATER))
    d.add(String(px + 170, 580, "Agua (H2O)", fontSize=11, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(px + 170, 250, "Solucao", fontSize=10, fontName="Helvetica",
                 fillColor=HexColor("#666"), textAnchor="middle"))
    d.add(String(px + 170, 235, "hipertonica", fontSize=10, fontName="Helvetica",
                 fillColor=HexColor("#666"), textAnchor="middle"))

    # === PAINEL 4: Transporte Ativo (Bomba Na+/K+) ===
    px = 1090
    # Proteina da bomba
    d.add(Rect(px + 130, 340, 80, 120, fillColor=C_PROTEIN, strokeColor=white,
               strokeWidth=1, rx=10, ry=10))
    d.add(String(px + 170, 400, "Bomba", fontSize=11, fontName="Helvetica-Bold",
                 fillColor=white, textAnchor="middle"))
    d.add(String(px + 170, 385, "Na+/K+", fontSize=11, fontName="Helvetica-Bold",
                 fillColor=white, textAnchor="middle"))

    # Na+ (amarelo) saindo (para cima, contra gradiente)
    for i in range(3):
        y = 500 - i * 40
        d.add(Circle(px + 140, y, 7, fillColor=C_NA, strokeColor=HexColor("#F57F17"), strokeWidth=1))
        d.add(String(px + 140, y + 12, "Na+", fontSize=8, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))
    # Seta para cima (Na+ saindo)
    d.add(Line(px + 140, 470, px + 140, 460, strokeColor=C_NA, strokeWidth=2))
    d.add(Polygon([px+140, 455, px+135, 465, px+145, 465], fillColor=C_NA))

    # K+ (cyan) entrando (para baixo, contra gradiente)
    for i in range(2):
        y = 300 + i * 40
        d.add(Circle(px + 200, y, 7, fillColor=C_K, strokeColor=HexColor("#0097A7"), strokeWidth=1))
        d.add(String(px + 200, y + 12, "K+", fontSize=8, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))
    # Seta para baixo (K+ entrando)
    d.add(Line(px + 200, 340, px + 200, 350, strokeColor=C_K, strokeWidth=2))
    d.add(Polygon([px+200, 355, px+195, 345, px+205, 345], fillColor=C_K))

    # ATP
    d.add(String(px + 170, 280, "ATP", fontSize=14, fontName="Helvetica-Bold",
                 fillColor=HexColor("#E91E63"), textAnchor="middle"))
    d.add(String(px + 170, 265, "(energia)", fontSize=9, fontName="Helvetica-Oblique",
                 fillColor=HexColor("#666"), textAnchor="middle"))
    # Seta de ATP para a bomba
    d.add(Line(px + 170, 290, px + 170, 340, strokeColor=HexColor("#E91E63"), strokeWidth=1.5))

    # Seta "contra gradiente"
    d.add(String(px + 170, 580, "CONTRA gradiente", fontSize=10, fontName="Helvetica-Bold",
                 fillColor=HexColor("#C62828"), textAnchor="middle"))
    d.add(String(px + 170, 565, "(gasta energia)", fontSize=9, fontName="Helvetica-Oblique",
                 fillColor=HexColor("#666"), textAnchor="middle"))

    # Salvar
    outpath = IMG_DIR / "diag_transporte.png"
    drawToFile(d, str(outpath), fmt="PNG", dpi=200)
    print(f"  Diagrama transporte: {outpath.name}")
    return outpath


def diagram_endocitose():
    """Diagrama de endocitose e exocitose."""
    w, h = 1200, 600
    d = Drawing(w, h)

    # Dois paineis: Endocitose e Exocitose
    # === ENDOCITOSE (esquerda) ===
    ex = 50
    d.add(Rect(ex, 50, 500, 500, fillColor=HexColor("#E8F5E9"),
               strokeColor=HexColor("#CCC"), strokeWidth=1, rx=10, ry=10))
    d.add(String(ex + 250, 520, "Endocitose", fontSize=18, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 250, 500, "(entrada de material)", fontSize=11, fontName="Helvetica",
                 fillColor=HexColor("#666"), textAnchor="middle"))

    # 3 estagios da endocitose (esquerda para direita)
    for stage in range(3):
        sx = ex + 80 + stage * 150

        # Membrana (curva)
        if stage == 0:
            # Membrana plana
            d.add(Rect(sx-40, 300, 80, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            # Particula acima
            d.add(Circle(sx, 340, 15, fillColor=HexColor("#FF7043"), strokeColor=white, strokeWidth=1))
            d.add(String(sx, 370, "particula", fontSize=8, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))
        elif stage == 1:
            # Membrana curvada (invaginacao)
            d.add(Polygon([sx-40, 300, sx-40, 280, sx-20, 260, sx+20, 260, sx+40, 280, sx+40, 300],
                          fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            # Particula dentro
            d.add(Circle(sx, 310, 12, fillColor=HexColor("#FF7043"), strokeColor=white, strokeWidth=1))
        else:
            # Vesicula fechada
            d.add(Circle(sx, 280, 25, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=1))
            d.add(Circle(sx, 280, 12, fillColor=HexColor("#FF7043"), strokeColor=white, strokeWidth=1))
            # Membrana restaurada
            d.add(Rect(sx-40, 300, 80, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=None))

        # Citoplasma (abaixo)
        d.add(Rect(sx-50, 100, 100, 200, fillColor=C_CYTOPLASM, strokeColor=None))

        # Setas entre estagios
        if stage < 2:
            d.add(Line(sx + 50, 280, sx + 100, 280, strokeColor=C_ARROW, strokeWidth=2))
            d.add(Polygon([sx+100, 280, sx+93, 275, sx+93, 285], fillColor=C_ARROW))

    # Labels endocitose
    d.add(String(ex + 80, 230, "1. Particula", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 80, 218, "   se aproxima", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 230, 230, "2. Membrana", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 230, 218, "   invagina", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 380, 230, "3. Vesicula", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex + 380, 218, "   se forma", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))

    # === EXOCITOSE (direita) ===
    ex2 = 650
    d.add(Rect(ex2, 50, 500, 500, fillColor=HexColor("#E3F2FD"),
               strokeColor=HexColor("#CCC"), strokeWidth=1, rx=10, ry=10))
    d.add(String(ex2 + 250, 520, "Exocitose", fontSize=18, fontName="Helvetica-Bold",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 250, 500, "(saida de material)", fontSize=11, fontName="Helvetica",
                 fillColor=HexColor("#666"), textAnchor="middle"))

    for stage in range(3):
        sx = ex2 + 80 + stage * 150

        # Citoplasma (abaixo)
        d.add(Rect(sx-50, 100, 100, 200, fillColor=C_CYTOPLASM, strokeColor=None))

        if stage == 0:
            # Vesicula dentro da celula
            d.add(Circle(sx, 250, 25, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=1))
            d.add(Circle(sx, 250, 12, fillColor=HexColor("#4CAF50"), strokeColor=white, strokeWidth=1))
            # Membrana
            d.add(Rect(sx-40, 300, 80, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
        elif stage == 1:
            # Vesicula se aproximando da membrana
            d.add(Circle(sx, 270, 22, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=1))
            d.add(Circle(sx, 270, 10, fillColor=HexColor("#4CAF50"), strokeColor=white, strokeWidth=1))
            # Membrana
            d.add(Rect(sx-40, 300, 80, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
        else:
            # Vesicula fundida, conteudo liberado
            d.add(Rect(sx-40, 300, 80, 8, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            # Conteudo acima (liberado)
            d.add(Circle(sx, 340, 10, fillColor=HexColor("#4CAF50"), strokeColor=white, strokeWidth=1))
            d.add(Circle(sx-15, 350, 8, fillColor=HexColor("#4CAF50"), strokeColor=white, strokeWidth=1))
            d.add(Circle(sx+15, 345, 7, fillColor=HexColor("#4CAF50"), strokeColor=white, strokeWidth=1))

        # Setas
        if stage < 2:
            d.add(Line(sx + 50, 280, sx + 100, 280, strokeColor=C_ARROW, strokeWidth=2))
            d.add(Polygon([sx+100, 280, sx+93, 275, sx+93, 285], fillColor=C_ARROW))

    # Labels exocitose
    d.add(String(ex2 + 80, 220, "1. Vesicula", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 80, 208, "   intracelular", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 230, 220, "2. Vesicula se", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 230, 208, "   funde a membrana", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 380, 220, "3. Conteudo", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))
    d.add(String(ex2 + 380, 208, "   liberado", fontSize=9, fontName="Helvetica",
                 fillColor=C_TEXT, textAnchor="middle"))

    # Extracelular (acima)
    d.add(Rect(0, 400, w, 200, fillColor=C_EXTRA, strokeColor=None))
    d.add(String(600, 560, "Meio extracelular", fontSize=12, fontName="Helvetica-Oblique",
                 fillColor=HexColor("#666"), textAnchor="middle"))

    # Salvar
    outpath = IMG_DIR / "diag_endocitose.png"
    drawToFile(d, str(outpath), fmt="PNG", dpi=200)
    print(f"  Diagrama endocitose: {outpath.name}")
    return outpath


def diagram_osmose():
    """Diagrama de osmose em celulas animais e vegetais."""
    w, h = 1200, 700
    d = Drawing(w, h)

    # 3 colunas: Hipotonico, Isotonico, Hipertonico
    cols = [
        {"x": 50, "titulo": "Meio Hipotonico", "sub": "(menos concentrado)",
         "cor": HexColor("#E3F2FD"), "animal": "Lise (estouro)", "vegetal": "Turgida"},
        {"x": 450, "titulo": "Meio Isotonico", "sub": "(mesma concentracao)",
         "cor": HexColor("#E8F5E9"), "animal": "Normal", "vegetal": "Normal"},
        {"x": 850, "titulo": "Meio Hipertonico", "sub": "(mais concentrado)",
         "cor": HexColor("#FFEBEE"), "animal": "Crenacao", "vegetal": "Plasmolise"},
    ]

    for col in cols:
        cx = col["x"]
        # Fundo
        d.add(Rect(cx, 50, 300, 600, fillColor=col["cor"],
                   strokeColor=HexColor("#CCC"), strokeWidth=1, rx=10, ry=10))
        # Titulo
        d.add(String(cx + 150, 620, col["titulo"], fontSize=16, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))
        d.add(String(cx + 150, 600, col["sub"], fontSize=11, fontName="Helvetica",
                     fillColor=HexColor("#666"), textAnchor="middle"))

        # === Celula Animal (topo) ===
        d.add(String(cx + 150, 560, "Celula Animal", fontSize=12, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))

        # Meio (cor de fundo ja representa)
        # Celula animal (circulo)
        cell_y = 480
        if "Hipotonico" in col["titulo"]:
            # Celula inchada
            d.add(Circle(cx + 150, cell_y, 50, fillColor=C_CELL, strokeColor=C_PHOSPHO_HEAD, strokeWidth=2))
            # Agua entrando (setas)
            for angle in [0, 90, 180, 270]:
                import math
                ax = cx + 150 + 60 * math.cos(math.radians(angle))
                ay = cell_y + 60 * math.sin(math.radians(angle))
                d.add(String(ax, ay, "H2O", fontSize=8, fontName="Helvetica-Bold",
                             fillColor=C_WATER, textAnchor="middle"))
        elif "Isotonico" in col["titulo"]:
            # Celula normal
            d.add(Circle(cx + 150, cell_y, 40, fillColor=C_CELL, strokeColor=C_PHOSPHO_HEAD, strokeWidth=2))
        else:
            # Celula encolhida (crenacao)
            d.add(Circle(cx + 150, cell_y, 30, fillColor=C_CELL, strokeColor=C_PHOSPHO_HEAD, strokeWidth=2))
            # Agua saindo
            d.add(String(cx + 220, cell_y, "H2O", fontSize=8, fontName="Helvetica-Bold",
                         fillColor=C_WATER))

        # Resultado animal
        d.add(String(cx + 150, 410, col["animal"], fontSize=11, fontName="Helvetica-Bold",
                     fillColor=HexColor("#C62828") if "Lise" in col["animal"] or "Cren" in col["animal"] else HexColor("#2E7D32"),
                     textAnchor="middle"))

        # === Celula Vegetal (base) ===
        d.add(String(cx + 150, 380, "Celula Vegetal", fontSize=12, fontName="Helvetica-Bold",
                     fillColor=C_TEXT, textAnchor="middle"))

        # Celula vegetal (retangular com parede)
        cell_y2 = 200
        # Parede celular (retangulo externo)
        d.add(Rect(cx + 90, cell_y2 - 50, 120, 100, fillColor=None,
                   strokeColor=HexColor("#795548"), strokeWidth=3, rx=5, ry=5))
        # Membrana + conteudo
        if "Hipotonico" in col["titulo"]:
            # Turgida (membrana encostada na parede)
            d.add(Rect(cx + 93, cell_y2 - 47, 114, 94, fillColor=C_CELL,
                       strokeColor=C_PHOSPHO_HEAD, strokeWidth=1, rx=3, ry=3))
            # Vacuolo grande
            d.add(Circle(cx + 150, cell_y2, 30, fillColor=C_WATER, strokeColor=HexColor("#0288D1"), strokeWidth=1))
        elif "Isotonico" in col["titulo"]:
            # Normal
            d.add(Rect(cx + 93, cell_y2 - 45, 114, 90, fillColor=C_CELL,
                       strokeColor=C_PHOSPHO_HEAD, strokeWidth=1, rx=3, ry=3))
            d.add(Circle(cx + 150, cell_y2, 25, fillColor=C_WATER, strokeColor=HexColor("#0288D1"), strokeWidth=1))
        else:
            # Plasmolise (membrana encolhida dentro da parede)
            d.add(Rect(cx + 100, cell_y2 - 35, 100, 70, fillColor=C_CELL,
                       strokeColor=C_PHOSPHO_HEAD, strokeWidth=1, rx=3, ry=3))
            d.add(Circle(cx + 150, cell_y2, 20, fillColor=C_WATER, strokeColor=HexColor("#0288D1"), strokeWidth=1))

        # Resultado vegetal
        d.add(String(cx + 150, 110, col["vegetal"], fontSize=11, fontName="Helvetica-Bold",
                     fillColor=HexColor("#C62828") if "Plasm" in col["vegetal"] else HexColor("#2E7D32"),
                     textAnchor="middle"))

    # Setas de osmose (agua movendo)
    d.add(String(600, 670, "Osmose: agua move do hipotonico para o hipertonico",
                 fontSize=13, fontName="Helvetica-BoldOblique",
                 fillColor=C_TEXT, textAnchor="middle"))

    # Salvar
    outpath = IMG_DIR / "diag_osmose.png"
    drawToFile(d, str(outpath), fmt="PNG", dpi=200)
    print(f"  Diagrama osmose: {outpath.name}")
    return outpath


def diagram_componentes():
    """Diagrama dos componentes da membrana (fosfolipidio, proteina, colesterol, glicocalix)."""
    w, h = 1200, 600
    d = Drawing(w, h)

    # 4 quadros com cada componente
    items = [
        {"x": 50, "titulo": "Fosfolipidio", "cor": C_PHOSPHO_HEAD,
         "desc": "Cabeca hidrofilica\n+ 2 caudas hidrofobicas\nAnfipatico"},
        {"x": 350, "titulo": "Colesterol", "cor": C_CHOLESTEROL,
         "desc": "Regula a fluidez\nEstabiliza a membrana\nIntercala-se na bicamada"},
        {"x": 650, "titulo": "Proteinas", "cor": C_PROTEIN,
         "desc": "Integrais: atravessam\nPerifericas: superficie\nTransporte, receptores"},
        {"x": 950, "titulo": "Glicocalix", "cor": C_GLYCO,
         "desc": "Carboidratos\nReconhecimento celular\nGrupos sanguineos ABO"},
    ]

    for item in items:
        cx = item["x"]
        # Fundo
        d.add(Rect(cx, 50, 200, 500, fillColor=HexColor("#FAFAFA"),
                   strokeColor=item["cor"], strokeWidth=2, rx=10, ry=10))
        # Titulo
        d.add(String(cx + 100, 520, item["titulo"], fontSize=16, fontName="Helvetica-Bold",
                     fillColor=item["cor"], textAnchor="middle"))

        # Desenho do componente
        if "Fosfolipidio" in item["titulo"]:
            # Fosfolipidio grande
            d.add(Circle(cx + 100, 380, 30, fillColor=C_PHOSPHO_HEAD, strokeColor=white, strokeWidth=1))
            d.add(Line(cx + 90, 350, cx + 90, 280, strokeWidth=6, strokeColor=C_PHOSPHO_TAIL))
            d.add(Line(cx + 110, 350, cx + 110, 280, strokeWidth=6, strokeColor=C_PHOSPHO_TAIL))
            # Labels
            d.add(String(cx + 100, 420, "cabeca", fontSize=10, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))
            d.add(String(cx + 100, 408, "hidrofilica", fontSize=10, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))
            d.add(String(cx + 100, 265, "caudas", fontSize=10, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))
            d.add(String(cx + 100, 253, "hidrofobicas", fontSize=10, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))

        elif "Colesterol" in item["titulo"]:
            # Losango de colesterol
            d.add(Polygon([cx+100, 400, cx+120, 360, cx+100, 320, cx+80, 360],
                          fillColor=C_CHOLESTEROL, strokeColor=white, strokeWidth=1))
            # Anel (esteroide)
            d.add(Circle(cx + 100, 360, 15, fillColor=None, strokeColor=white, strokeWidth=1))

        elif "Proteinas" in item["titulo"]:
            # Proteina transmembrana
            d.add(Rect(cx + 70, 280, 60, 150, fillColor=C_PROTEIN, strokeColor=white,
                       strokeWidth=1, rx=15, ry=15))
            # Proteina periferica
            d.add(Rect(cx + 50, 430, 40, 20, fillColor=C_PROTEIN, strokeColor=white,
                       strokeWidth=1, rx=5, ry=5))
            d.add(Rect(cx + 110, 260, 40, 20, fillColor=C_PROTEIN, strokeColor=white,
                       strokeWidth=1, rx=5, ry=5))
            # Bicamada simplificada
            d.add(Line(cx + 30, 430, cx + 170, 430, strokeWidth=2, strokeColor=C_PHOSPHO_HEAD))
            d.add(Line(cx + 30, 280, cx + 170, 280, strokeWidth=2, strokeColor=C_PHOSPHO_HEAD))

        elif "Glicocalix" in item["titulo"]:
            # Membrana com glicocalix
            d.add(Rect(cx + 30, 320, 140, 20, fillColor=C_PHOSPHO_HEAD, strokeColor=None))
            # Glicocalix (cadeias de carboidratos)
            for i in range(7):
                gx = cx + 40 + i * 18
                d.add(Line(gx, 340, gx, 370, strokeWidth=2, strokeColor=C_GLYCO))
                d.add(Circle(gx, 375, 4, fillColor=C_GLYCO, strokeColor=None))
                d.add(Circle(gx, 385, 3, fillColor=C_GLYCO, strokeColor=None))

        # Descricao
        for i, line in enumerate(item["desc"].split("\n")):
            d.add(String(cx + 100, 200 - i * 18, line, fontSize=10, fontName="Helvetica",
                         fillColor=C_TEXT, textAnchor="middle"))

    # Salvar
    outpath = IMG_DIR / "diag_componentes.png"
    drawToFile(d, str(outpath), fmt="PNG", dpi=200)
    print(f"  Diagrama componentes: {outpath.name}")
    return outpath


def generate_all_diagrams():
    """Gera todos os diagramas e retorna a lista de caminhos."""
    print("Gerando diagramas proprios em PT-BR...")
    diagrams = [
        diagram_bicamada(),
        diagram_componentes(),
        diagram_transporte(),
        diagram_osmose(),
        diagram_endocitose(),
    ]
    print(f"{len(diagrams)} diagramas gerados com sucesso!")
    return diagrams


if __name__ == "__main__":
    generate_all_diagrams()
