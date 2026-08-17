"""
Gera o Manual do Usuario do PAES MED AI em PDF.
Versao simplificada, intuitiva, em portugues, sem termos tecnicos.
Com imagens grandes e anotacoes (setas/circulos) apontando elementos.
"""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage,
    Frame, PageTemplate, PageBreak, Table, TableStyle, NextPageTemplate
)
from reportlab.pdfgen import canvas
from PIL import Image as PILImage, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "docs" / "screenshots" / "manual"
ANNO = ROOT / "docs" / "screenshots" / "manual_annotated"
ANNO.mkdir(parents=True, exist_ok=True)
OUT = ROOT / "docs" / "PAES_MED_AI_Manual_Usuario.pdf"

# Paleta do app
C_NAVY = colors.HexColor("#0A1628")
C_NAVY_SOFT = colors.HexColor("#132337")
C_TEAL = colors.HexColor("#1FA887")
C_TEAL_DEEP = colors.HexColor("#0C7A63")
C_MINT = colors.HexColor("#E6F6F1")
C_SAND = colors.HexColor("#F6F4F1")
C_WHITE = colors.white
C_MUTED = colors.HexColor("#5A6B6E")
C_INK = colors.HexColor("#0E1726")
C_ALERT = colors.HexColor("#E8A04B")
C_DANGER = colors.HexColor("#D3544A")
C_SUCCESS = colors.HexColor("#2E9B6B")

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm
CONTENT_W = PAGE_W - 2 * MARGIN
CONTENT_H = PAGE_H - 2 * MARGIN

styles = {
    "title": ParagraphStyle("title", fontName="Helvetica-Bold", fontSize=30, textColor=C_WHITE, alignment=TA_CENTER, spaceAfter=6, leading=34),
    "subtitle": ParagraphStyle("subtitle", fontName="Helvetica-Bold", fontSize=16, textColor=C_TEAL, alignment=TA_CENTER, spaceAfter=4, leading=20),
    "meta": ParagraphStyle("meta", fontName="Helvetica", fontSize=11, textColor=C_MINT, alignment=TA_CENTER, leading=15),
    "h1": ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=20, textColor=C_NAVY, spaceBefore=14, spaceAfter=6, leading=24),
    "h2": ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=14, textColor=C_TEAL_DEEP, spaceBefore=10, spaceAfter=4, leading=18),
    "body": ParagraphStyle("body", fontName="Helvetica", fontSize=12, textColor=C_INK, alignment=TA_JUSTIFY, spaceAfter=6, leading=17),
    "bullet": ParagraphStyle("bullet", fontName="Helvetica", fontSize=12, textColor=C_INK, leftIndent=18, bulletIndent=6, spaceAfter=4, leading=16),
    "caption": ParagraphStyle("caption", fontName="Helvetica-Oblique", fontSize=10, textColor=C_MUTED, alignment=TA_CENTER, spaceBefore=4, spaceAfter=10, leading=13),
    "tip": ParagraphStyle("tip", fontName="Helvetica", fontSize=11, textColor=C_NAVY_SOFT, leftIndent=10, rightIndent=10, spaceAfter=8, leading=15),
    "step": ParagraphStyle("step", fontName="Helvetica-Bold", fontSize=13, textColor=C_TEAL_DEEP, spaceBefore=8, spaceAfter=3, leading=17),
    "footer": ParagraphStyle("footer", fontName="Helvetica", fontSize=8, textColor=C_MUTED, alignment=TA_CENTER, leading=10),
    "intro": ParagraphStyle("intro", fontName="Helvetica", fontSize=13, textColor=C_INK, alignment=TA_LEFT, spaceAfter=8, leading=18),
}


# ============================================================
# ANOTACAO DE IMAGENS (setas, circulos, labels)
# ============================================================

def annotate_image(src_path, dst_path, annotations):
    """
    Adiciona anotacoes em uma imagem.
    annotations: lista de dicts com:
      - type: 'arrow' | 'circle' | 'label'
      - x, y: coordenadas em porcentagem (0-1) da imagem
      - x2, y2: coordenada final (para arrow)
      - text: texto do label
      - color: cor (R,G,B)
    """
    im = PILImage.open(src_path).convert("RGBA")
    w, h = im.size
    overlay = PILImage.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    try:
        font = ImageFont.truetype("arial.ttf", size=int(h * 0.035))
        font_small = ImageFont.truetype("arial.ttf", size=int(h * 0.028))
    except IOError:
        font = ImageFont.load_default()
        font_small = font

    for ann in annotations:
        atype = ann.get("type", "label")
        color = ann.get("color", (229, 160, 75, 255))  # laranja por padrao
        x = int(ann["x"] * w)
        y = int(ann["y"] * h)

        if atype == "arrow":
            x2 = int(ann["x2"] * w)
            y2 = int(ann["y2"] * h)
            # linha
            draw.line([(x2, y2), (x, y)], fill=color, width=max(4, int(w * 0.004)))
            # ponta da seta
            import math
            angle = math.atan2(y - y2, x - x2)
            arrow_len = int(w * 0.015)
            for da in [0.4, -0.4]:
                ax = x - arrow_len * math.cos(angle + da)
                ay = y - arrow_len * math.sin(angle + da)
                draw.line([(x, y), (ax, ay)], fill=color, width=max(4, int(w * 0.004)))

        elif atype == "circle":
            r = int(ann.get("r", 0.02) * w)
            draw.ellipse([x - r, y - r, x + r, y + r], outline=color, width=max(4, int(w * 0.004)))

        elif atype == "label":
            text = ann.get("text", "")
            # fundo do label
            tw = int(len(text) * h * 0.022)
            th = int(h * 0.045)
            bx, by = x, y
            draw.rounded_rectangle([bx, by, bx + tw, by + th], radius=th // 3, fill=color)
            # texto
            draw.text((bx + tw * 0.1, by + th * 0.15), text, fill=(255, 255, 255, 255), font=font_small)

    result = PILImage.alpha_composite(im, overlay)
    result = result.convert("RGB")
    result.save(dst_path, "PNG", optimize=True)
    return dst_path


def get_annotated(name, annotations):
    """Pega imagem anotada (ou cria se nao existir)."""
    src = SHOTS / name
    if not src.exists():
        return None
    dst = ANNO / name
    annotate_image(src, dst, annotations)
    return dst


# ============================================================
# LAYOUT DAS PAGINAS
# ============================================================

def draw_cover(c, doc):
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 8 * mm, PAGE_W, 8 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 8 * mm, fill=1, stroke=0)

    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 34)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 75 * mm, "PAES MED AI")
    c.setFillColor(C_TEAL)
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 92 * mm, "MANUAL DO USUARIO")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 12)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 108 * mm, "Guia simples e pratico para usar a plataforma")

    c.setFillColor(C_NAVY_SOFT)
    c.roundRect(35 * mm, PAGE_H - 175 * mm, PAGE_W - 70 * mm, 55 * mm, 4 * mm, fill=1, stroke=0)
    c.setFillColor(C_MINT)
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 135 * mm, "PARA")
    c.setFont("Helvetica-Bold", 14)
    c.setFillColor(C_WHITE)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 148 * mm, "Jonas Almeida Medeiros")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 162 * mm, "Versao 1.0.0.26  |  17 de agosto de 2026")

    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 9)
    c.drawCentredString(PAGE_W / 2, 20 * mm, "Desenvolvido por Yuri Medeiros Bandeira")
    c.restoreState()


def draw_page(c, doc):
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, PAGE_H - 14 * mm, PAGE_W, 14 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 15 * mm, PAGE_W, 1 * mm, fill=1, stroke=0)
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(MARGIN, PAGE_H - 9 * mm, "PAES MED AI")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 9 * mm, "Manual do Usuario")

    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 1 * mm, fill=1, stroke=0)
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawCentredString(PAGE_W / 2, 6 * mm, f"Pagina {doc.page}  |  PAES MED AI")
    c.restoreState()


def draw_backcover(c, doc):
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 8 * mm, PAGE_W, 8 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 8 * mm, fill=1, stroke=0)

    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 22)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 60 * mm, "Bons estudos!")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 13)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 80 * mm, "PAES MED AI - Estudos para Medicina")
    c.setFillColor(C_TEAL)
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 105 * mm, "Precisa de ajuda?")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 11)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 118 * mm, "Entre em contato com Yuri Medeiros Bandeira")

    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawCentredString(PAGE_W / 2, 20 * mm, "Versao 1.0.0.26  |  Agosto de 2026")
    c.restoreState()


# ============================================================
# HELPERS DE CONTEUDO
# ============================================================

def img_flowable(path, max_w=None, max_h=None):
    if max_w is None:
        max_w = CONTENT_W
    if max_h is None:
        max_h = 135 * mm
    with PILImage.open(path) as im:
        iw, ih = im.size
    ratio = min(max_w / iw, max_h / ih)
    w = iw * ratio
    h = ih * ratio
    return RLImage(str(path), width=w, height=h)


def tip_box(text):
    p = Paragraph(f"<b>Dica:</b> {text}", styles["tip"])
    t = Table([[p]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), C_MINT),
        ("BOX", (0, 0), (-1, -1), 0.5, C_TEAL),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def warning_box(text):
    p = Paragraph(f"<b>Atencao:</b> {text}", styles["tip"])
    t = Table([[p]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FFF3E0")),
        ("BOX", (0, 0), (-1, -1), 0.5, C_ALERT),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def section(num, title):
    return Paragraph(f"{num}. {title}", styles["h1"])


def subsection(title):
    return Paragraph(title, styles["h2"])


def step(num, text):
    return Paragraph(f"Passo {num}: {text}", styles["step"])


def body(text):
    return Paragraph(text, styles["body"])


def bullet(text):
    return Paragraph(f"• {text}", styles["bullet"])


def caption(text):
    return Paragraph(text, styles["caption"])


def anno_img(name, annotations, max_h=None):
    """Imagem anotada com setas/circulos."""
    p = get_annotated(name, annotations)
    if p:
        return img_flowable(p, max_h=max_h)
    return None


# ============================================================
# CONSTRUCAO DO MANUAL
# ============================================================

def build_manual():
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=20 * mm,
        bottomMargin=14 * mm,
    )

    frame_cover = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="cover")
    frame_content = Frame(MARGIN, 10 * mm, CONTENT_W, PAGE_H - 30 * mm, id="content")
    frame_back = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="back")

    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame_cover], onPage=draw_cover),
        PageTemplate(id="content", frames=[frame_content], onPage=draw_page),
        PageTemplate(id="backcover", frames=[frame_back], onPage=draw_backcover),
    ])

    story = []

    # === CAPA ===
    story.append(PageBreak())

    # === CONTEUDO ===
    story.append(NextPageTemplate("content"))
    story.append(PageBreak())

    # 1. Bem-vindo
    story.append(section("1", "Bem-vindo!"))
    story.append(body(
        "O <b>PAES MED AI</b> e a sua plataforma de estudos para o "
        "vestibular de Medicina. Com ele voce tem tudo em um so lugar: "
        "questoes, resumos, materiais e um assistente inteligente que "
        "te ajuda a entender qualquer topico."
    ))
    story.append(body(
        "Este manual e curto e direto. Vai te mostrar como usar cada "
        "parte do aplicativo, sem complicacao."
    ))
    story.append(Spacer(1, 4 * mm))

    story.append(subsection("O que voce tem no app"))
    story.append(bullet("Mais de <b>700 questoes</b> de provas reais"))
    story.append(bullet("Mais de <b>700 cartoes de revisao</b>"))
    story.append(bullet("Mais de <b>200 aulas resumidas</b>"))
    story.append(bullet("Mais de <b>90 materiais completos</b> em PDF"))
    story.append(bullet("Um <b>assistente inteligente</b> que explica tudo"))
    story.append(bullet("Acompanhamento do seu <b>progresso</b>"))
    story.append(bullet("Funciona <b>sem internet</b>"))

    story.append(Spacer(1, 4 * mm))
    story.append(subsection("O menu lateral"))
    story.append(body(
        "No lado esquerdo da tela voce sempre ve o menu. E por ele que "
        "voce navega entre as partes do app:"
    ))
    story.append(bullet("<b>Inicio</b> — sua tela principal, com o resumo do dia"))
    story.append(bullet("<b>Estudar</b> — onde voce faz questoes e revisa cartoes"))
    story.append(bullet("<b>Progresso</b> — graficos do seu desempenho"))
    story.append(bullet("<b>Biblioteca</b> — aulas e materiais para ler"))
    story.append(bullet("<b>Ajustes</b> — configuracoes do app"))

    # Imagem do dashboard com anotacoes
    story.append(Spacer(1, 3 * mm))
    p = anno_img("01-dashboard.png", [
        {"type": "label", "x": 0.02, "y": 0.10, "text": "Menu", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.10, "y": 0.30, "x2": 0.03, "y2": 0.12, "color": (229, 160, 75, 255)},
        {"type": "label", "x": 0.40, "y": 0.10, "text": "Seu resumo", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.50, "y": 0.35, "x2": 0.45, "y2": 0.12, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Tela inicial — menu a esquerda, resumo no centro"))

    # 2. Primeiros passos
    story.append(PageBreak())
    story.append(section("2", "Comecando a usar"))
    story.append(body(
        "Para abrir o app, basta dar <b>dois cliques</b> no icone "
        "<b>PAES MED AI</b> que esta na sua Area de Trabalho."
    ))
    story.append(step(1, "Dois cliques no icone da Area de Trabalho"))
    story.append(body(
        "O app abre em poucos segundos. Na primeira vez, "
        "espere uns 10 segundos para tudo carregar."
    ))
    story.append(tip_box(
        "Se o icone nao estiver na Area de Trabalho, procure no "
        "Menu Iniciar digitando \"PAES MED AI\"."
    ))

    # 3. Tela Inicial
    story.append(PageBreak())
    story.append(section("3", "Tela Inicial"))
    story.append(body(
        "Ao abrir, voce ve a tela inicial. Ela mostra um resumo "
        "rapido de como estao seus estudos."
    ))

    story.append(subsection("O que aparece na tela inicial"))
    story.append(bullet("Quantas questoes voce ja respondeu"))
    story.append(bullet("Quantos cartoes voce ja revisou"))
    story.append(bullet("Quantos dias faltam para a prova"))
    story.append(bullet("Quantos dias seguidos voce estudou"))
    story.append(bullet("O que e sugerido estudar hoje"))

    p = anno_img("02-dashboard-2.png", [
        {"type": "label", "x": 0.35, "y": 0.08, "text": "Estatisticas", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.45, "y": 0.25, "x2": 0.40, "y2": 0.10, "color": (31, 168, 135, 255)},
        {"type": "label", "x": 0.65, "y": 0.45, "text": "Estudar agora", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.75, "y": 0.55, "x2": 0.70, "y2": 0.47, "color": (229, 160, 75, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Tela inicial com estatisticas e botao de estudar"))

    story.append(tip_box(
        "Clique em \"Continuar\" para voltar de onde parou, "
        "ou em \"Nova sessao\" para comecar algo novo."
    ))

    # 4. Estudando
    story.append(PageBreak())
    story.append(section("4", "Estudando"))
    story.append(body(
        "A aba <b>Estudar</b> e onde voce passa a maior parte do tempo. "
        "Aqui voce responde questoes e revisa cartoes."
    ))

    story.append(subsection("Como comecar uma sessao"))
    story.append(step(1, "Clique em \"Estudar\" no menu a esquerda"))
    story.append(step(2, "Escolha a materia ou aceite a sugestao do dia"))
    story.append(step(3, "Clique em \"Iniciar\""))

    p = anno_img("03-sessao.png", [
        {"type": "label", "x": 0.35, "y": 0.08, "text": "Escolha a materia", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.45, "y": 0.30, "x2": 0.40, "y2": 0.10, "color": (31, 168, 135, 255)},
        {"type": "label", "x": 0.65, "y": 0.60, "text": "Iniciar", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.72, "y": 0.70, "x2": 0.68, "y2": 0.62, "color": (229, 160, 75, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Tela de estudo — escolha a materia e clique em Iniciar"))

    # 5. Questoes
    story.append(PageBreak())
    story.append(section("5", "Respondendo Questoes"))
    story.append(body(
        "Cada questao aparece com o enunciado e 5 alternativas. "
        "Leia com atencao e escolha a que acha correta."
    ))

    story.append(subsection("Como responder"))
    story.append(step(1, "Leia o enunciado com calma"))
    story.append(step(2, "Clique na alternativa desejada"))
    story.append(step(3, "Clique em \"Confirmar\""))
    story.append(step(4, "Veja se acertou ou errou, com a explicacao"))

    p = anno_img("04-questao.png", [
        {"type": "label", "x": 0.30, "y": 0.05, "text": "Enunciado", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.35, "y": 0.20, "x2": 0.32, "y2": 0.07, "color": (31, 168, 135, 255)},
        {"type": "label", "x": 0.30, "y": 0.55, "text": "Alternativas", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.35, "y": 0.65, "x2": 0.32, "y2": 0.57, "color": (229, 160, 75, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Questao — enunciado em cima, alternativas embaixo"))

    story.append(subsection("Depois de responder"))
    story.append(body("O app mostra:"))
    story.append(bullet("Se voce <b>acertou</b> ou <b>errou</b>"))
    story.append(bullet("A <b>explicacao completa</b> da questao"))
    story.append(bullet("Uma <b>dica rapida</b> para lembrar"))
    story.append(bullet("Se a questao tem alguma <b>pegadinha</b>"))
    story.append(bullet("Um botao para pedir mais explicacao ao <b>assistente</b>"))

    p = anno_img("05-questao-resolvida.png", [
        {"type": "label", "x": 0.30, "y": 0.05, "text": "Resultado", "color": (46, 155, 107, 255)},
        {"type": "arrow", "x": 0.35, "y": 0.15, "x2": 0.32, "y2": 0.07, "color": (46, 155, 107, 255)},
        {"type": "label", "x": 0.55, "y": 0.50, "text": "Explicacao", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.60, "y": 0.60, "x2": 0.57, "y2": 0.52, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Questao respondida — resultado e explicacao"))

    # 6. Progresso
    story.append(PageBreak())
    story.append(section("6", "Seu Progresso"))
    story.append(body(
        "A aba <b>Progresso</b> mostra graficos do seu desempenho. "
        "E aqui voce descobre onde esta indo bem e onde precisa melhorar."
    ))

    story.append(subsection("Grafico de evolucao"))
    story.append(body(
        "Mostra como seu desempenho mudou ao longo do tempo. "
        "Cada ponto e uma sessao de estudo."
    ))
    p = anno_img("06-progresso-evolucao.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Seu desempenho", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.30, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=115 * mm)
    if p:
        story.append(p)
        story.append(caption("Grafico de evolucao — quanto mais alto, melhor"))

    story.append(subsection("Radar por materia"))
    story.append(body(
        "O grafico de teia mostra como voce esta em cada materia. "
        "Quanto mais cheia, melhor."
    ))
    p = anno_img("07-progresso-radar.png", [
        {"type": "label", "x": 0.40, "y": 0.08, "text": "Teia de materias", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.50, "y": 0.30, "x2": 0.45, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=115 * mm)
    if p:
        story.append(p)
        story.append(caption("Radar — cada ponta e uma materia"))

    story.append(tip_box(
        "Estude mais as materias onde a teia esta mais vazia. "
        "Sao as que voce mais precisa melhorar."
    ))

    # Analise detalhada
    story.append(PageBreak())
    story.append(subsection("Analise detalhada"))
    story.append(body(
        "A analise mostra seus numeros por materia e por topico. "
        "Use para saber exatamente onde focar."
    ))
    p = anno_img("08-progresso-analise.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Por materia", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.25, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Analise detalhada — desempenho por materia"))

    # 7. Biblioteca
    story.append(PageBreak())
    story.append(section("7", "Biblioteca de Aulas"))
    story.append(body(
        "A aba <b>Biblioteca</b> tem aulas resumidas organizadas por materia. "
        "Cada aula cobre um topico do edital."
    ))

    story.append(step(1, "Clique em \"Biblioteca\" no menu"))
    story.append(step(2, "Escolha a materia"))
    story.append(step(3, "Clique na aula que quer ler"))
    story.append(step(4, "A aula abre dentro do app"))

    p = anno_img("09-biblioteca-aulas.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Lista de aulas", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.25, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Biblioteca — aulas organizadas por materia"))

    # 8. Materiais
    story.append(PageBreak())
    story.append(section("8", "Materiais de Estudo"))
    story.append(body(
        "A aba <b>Materiais</b> tem mais de 90 textos completos para "
        "estudo profundo. Cada um cobre um topico com detalhes."
    ))

    story.append(step(1, "Clique em \"Materiais\" no menu"))
    story.append(step(2, "Navegue ou use a busca"))
    story.append(step(3, "Clique no material desejado"))
    story.append(step(4, "O texto abre dentro do app"))

    p = anno_img("10-biblioteca-materiais.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Lista de materiais", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.25, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Materiais — lista de textos para estudo"))

    p = anno_img("11-material-aberto.png", [
        {"type": "label", "x": 0.35, "y": 0.05, "text": "Texto aberto", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.45, "y": 0.20, "x2": 0.40, "y2": 0.07, "color": (31, 168, 135, 255)},
    ], max_h=130 * mm)
    if p:
        story.append(p)
        story.append(caption("Material aberto — leitura dentro do app"))

    story.append(tip_box(
        "Todos os materiais funcionam sem internet. "
        "Voce pode estudar em qualquer lugar."
    ))

    # 9. Cartoes de revisao (flashcards) - NOVA IMAGEM
    story.append(PageBreak())
    story.append(section("9", "Cartoes de Revisao"))
    story.append(body(
        "Os cartoes de revisao sao como fichas de estudo. "
        "Cada cartao tem uma pergunta na frente e a resposta no verso. "
        "Servem para memorizar rapido."
    ))

    story.append(subsection("Como usar"))
    story.append(step(1, "Va em \"Estudar\" no menu"))
    story.append(step(2, "Escolha \"Cartoes\" em vez de \"Questoes\""))
    story.append(step(3, "Leia a pergunta na tela"))
    story.append(step(4, "Pense na resposta e clique em \"Mostrar\""))
    story.append(step(5, "Marque se voce \"Acertou\" ou \"Errou\""))

    p = anno_img("15-flashcards.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Pergunta", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.30, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
        {"type": "label", "x": 0.60, "y": 0.70, "text": "Mostrar resposta", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.65, "y": 0.80, "x2": 0.62, "y2": 0.72, "color": (229, 160, 75, 255)},
    ], max_h=130 * mm)
    if p:
        story.append(p)
        story.append(caption("Cartao de revisao — pergunta na frente, resposta no verso"))

    story.append(tip_box(
        "Estude cartoes por 10 a 15 minutos por dia. "
        "E melhor do que estudar 1 hora uma vez por semana."
    ))

    # 10. Assistente Inteligente (Tutor IA) - NOVA IMAGEM + antiga
    story.append(PageBreak())
    story.append(section("10", "Assistente Inteligente"))
    story.append(body(
        "O assistente inteligente e como ter um professor particular "
        "dentro do app. Ele explica questoes, tira duvidas e da exemplos."
    ))

    story.append(subsection("Como usar"))
    story.append(step(1, "Responda uma questao (certa ou errada)"))
    story.append(step(2, "Clique no botao \"Explicar\" ou \"Assistente\""))
    story.append(step(3, "O assistente vai explicar tudo em detalhes"))
    story.append(step(4, "Voce pode fazer mais perguntas se quiser"))

    p = anno_img("16-tutor-ia-novo.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Explicacao", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.25, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
        {"type": "label", "x": 0.60, "y": 0.65, "text": "Pergunte mais", "color": (229, 160, 75, 255)},
        {"type": "arrow", "x": 0.65, "y": 0.75, "x2": 0.62, "y2": 0.67, "color": (229, 160, 75, 255)},
    ], max_h=130 * mm)
    if p:
        story.append(p)
        story.append(caption("Assistente explicando uma questao em detalhes"))

    # Imagem antiga do tutor (tema branco) como exemplo adicional
    p2 = anno_img("13-ajustes-claro.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Tema claro", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.20, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=115 * mm)
    if p2:
        story.append(p2)
        story.append(caption("O app tambem pode ser usado com tema claro"))

    story.append(tip_box(
        "Faca perguntas especificas. Em vez de \"nao entendi\", "
        "tente \"por que a alternativa C esta errada?\""
    ))

    # 11. Ajustes
    story.append(PageBreak())
    story.append(section("11", "Configuracoes"))
    story.append(body(
        "A aba <b>Ajustes</b> deixa voce personalizar o app."
    ))

    story.append(subsection("Tema claro e escuro"))
    story.append(body(
        "Voce pode trocar entre tema claro e escuro. "
        "O tema escuro e melhor para estudar a noite."
    ))

    p = anno_img("12-ajustes-escuro.png", [
        {"type": "label", "x": 0.30, "y": 0.08, "text": "Tema escuro", "color": (31, 168, 135, 255)},
        {"type": "arrow", "x": 0.40, "y": 0.25, "x2": 0.35, "y2": 0.10, "color": (31, 168, 135, 255)},
    ], max_h=120 * mm)
    if p:
        story.append(p)
        story.append(caption("Ajustes — tema escuro"))

    story.append(subsection("Data da prova"))
    story.append(body(
        "Configure a data da sua prova para o app calcular "
        "a contagem regressiva e sugerir um plano de estudo."
    ))

    story.append(subsection("Assistente inteligente"))
    story.append(body(
        "O assistente ja vem pronto para uso. Voce nao precisa "
        "configurar nada — e so usar."
    ))

    # 12. Dicas
    story.append(PageBreak())
    story.append(section("12", "Dicas para Aproveitar ao Maximo"))

    story.append(subsection("Rotina de estudos"))
    story.append(bullet("Estude <b>todos os dias</b>, mesmo que seja pouco"))
    story.append(bullet("Faca pelo menos <b>1 sessao de questoes</b> por dia"))
    story.append(bullet("Revise <b>cartoes</b> por 10-15 minutos por dia"))
    story.append(bullet("Leia <b>1 material</b> por semana"))
    story.append(bullet("Use o <b>assistente</b> sempre que tiver duvida"))

    story.append(subsection("Estrategia de revisao"))
    story.append(bullet("Foque nas materias com <b>menor acerto</b>"))
    story.append(bullet("Refaca questoes que voce <b>errou</b>"))
    story.append(bullet("Use a <b>teia</b> para ver quais materias estao fracas"))
    story.append(bullet("Preste atencao nas <b>pegadinhas</b> marcadas"))

    story.append(tip_box(
        "O segredo e a <b>constancia</b>. Estudar 30 minutos por dia "
        "e melhor do que 4 horas uma vez por semana."
    ))

    # 13. Problemas comuns
    story.append(PageBreak())
    story.append(section("13", "Problemas Comuns"))

    story.append(subsection("O app nao abre"))
    story.append(body(
        "Procure o icone na Area de Trabalho ou no Menu Iniciar. "
        "Se nao abrir, reinicie o computador e tente de novo."
    ))

    story.append(subsection("Aparece \"Sem conexao\""))
    story.append(body(
        "Espere 10 segundos e feche/reabra o app. "
        "O resto do app funciona normalmente sem internet."
    ))

    story.append(subsection("O assistente nao responde"))
    story.append(body(
        "O assistente precisa de internet para funcionar. "
        "Verifique sua conexao. O restante do app funciona offline."
    ))

    story.append(warning_box(
        "Se nada funcionar, entre em contato: "
        "Yuri Medeiros Bandeira"
    ))

    # 14. Acesso Web
    story.append(PageBreak())
    story.append(section("14", "Acessar pelo Navegador"))
    story.append(body(
        "Alem do aplicativo no computador, voce tambem pode usar "
        "o PAES MED AI pelo navegador de internet, de qualquer lugar."
    ))

    story.append(step(1, "Abra o navegador (Chrome, Edge, Firefox)"))
    story.append(step(2, "Digite: paes-med-ai.onrender.com"))
    story.append(step(3, "Use normalmente"))

    story.append(tip_box(
        "Pelo navegador voce pode estudar de qualquer computador "
        "ou celular com internet."
    ))

    # === CONTRA CAPA ===
    story.append(NextPageTemplate("backcover"))
    story.append(PageBreak())

    doc.build(story)
    print(f"Manual gerado: {OUT}")
    print(f"Tamanho: {OUT.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    build_manual()
