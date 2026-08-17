"""
Gera PDF da documentação completa do PAES MED AI.
Layout profissional com logo, screenshots, capa elegante, contra-capa e tipografia cuidada.
Todas as células de tabela usam Paragraph para wrap automático (sem texto saindo da tabela).
"""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, Image as RLImage, KeepTogether, Frame, PageTemplate, NextPageTemplate
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY, TA_RIGHT
from reportlab.pdfgen import canvas
from PIL import Image as PILImage

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "PAES_MED_AI_Documentacao_Completa.pdf"
SHOTS = ROOT / "docs" / "screenshots"
LOGO = SHOTS / "logo.png"

# === Paleta PAES MED AI (identidade visual real do app) ===
# Extraída de lib/core/theme/app_theme.dart
# Teal clínico + Navy + Mint + Sand
C_NAVY = colors.HexColor("#0A1628")         # navy (escuro principal)
C_NAVY_SOFT = colors.HexColor("#132337")    # navy suave
C_TEAL = colors.HexColor("#1FA887")         # teal (cor de marca)
C_TEAL_DEEP = colors.HexColor("#0C7A63")    # teal profundo (primária)
C_MINT = colors.HexColor("#E6F6F1")         # mint (fundo claro teal)
C_SAND = colors.HexColor("#F6F4F1")         # sand (fundo neutro quente)
C_INK = colors.HexColor("#0E1726")          # ink (texto escuro)
C_ALERT = colors.HexColor("#E8A04B")        # alerta (âmbar)
C_DANGER = colors.HexColor("#D3544A")       # danger (vermelho)
C_SUCCESS = colors.HexColor("#2E9B6B")      # success (verde)
C_INFO = colors.HexColor("#3B82F6")         # info (azul)

# Aliases para o PDF
C_PRIMARY = C_TEAL_DEEP                     # primária = teal profundo
C_SECONDARY = C_NAVY                        # secundária = navy
C_ACCENT = C_TEAL                           # destaque = teal
C_DARK = C_NAVY                             # fundo escuro (capa) = navy
C_TEXT = C_INK                              # texto principal = ink
C_MUTED = colors.HexColor("#5A6B6E")        # texto secundário
C_LIGHT = C_MINT                            # fundo claro = mint
C_LIGHTER = colors.HexColor("#F5F8F7")      # fundo mais claro
C_WHITE = colors.white
C_TABLE_HEAD = C_TEAL_DEEP                  # cabeçalho tabelas = teal profundo
C_TABLE_ALT = C_MINT                        # linha alternada = mint
C_DIVIDER = colors.HexColor("#C9D4CE")      # divisórias (outline do app)

PAGE_W, PAGE_H = A4
MARGIN_L = 20 * mm
MARGIN_R = 20 * mm
MARGIN_T = 28 * mm
MARGIN_B = 22 * mm
CONTENT_W = PAGE_W - MARGIN_L - MARGIN_R


# ============================================================
#  PÁGINAS ESPECIAIS (capa, contra-capa, header/footer)
# ============================================================

def draw_cover(c, doc):
    """Capa profissional com logo, fundo escuro e assinaturas."""
    c.saveState()

    # Fundo azul-marinho profundo
    c.setFillColor(C_DARK)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    # Faixa coral superior
    c.setFillColor(C_ACCENT)
    c.rect(0, PAGE_H - 6 * mm, PAGE_W, 6 * mm, fill=1, stroke=0)

    # Faixa azul-marinho inferior
    c.setFillColor(C_PRIMARY)
    c.rect(0, 0, PAGE_W, 6 * mm, fill=1, stroke=0)

    # Logo centralizado
    if LOGO.exists():
        logo_size = 55 * mm
        logo_x = (PAGE_W - logo_size) / 2
        logo_y = PAGE_H - 95 * mm
        c.setFillColor(C_WHITE)
        c.circle(PAGE_W / 2, logo_y + logo_size / 2, logo_size / 2 + 4 * mm, fill=1, stroke=0)
        c.drawImage(str(LOGO), logo_x, logo_y, logo_size, logo_size, mask='auto')

    # Título
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 34)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 130 * mm, "PAES MED AI")

    # Subtítulo
    c.setFillColor(C_SECONDARY)
    c.setFont("Helvetica", 15)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 142 * mm, "Plataforma Inteligente de Estudos")

    c.setFillColor(C_ACCENT)
    c.setFont("Helvetica-Oblique", 12)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 152 * mm, "PAES / UEMA Medicina")

    # Linha decorativa coral
    c.setStrokeColor(C_ACCENT)
    c.setLineWidth(2)
    c.line(PAGE_W / 2 - 45 * mm, PAGE_H - 160 * mm, PAGE_W / 2 + 45 * mm, PAGE_H - 160 * mm)

    # Caixa de destaque para o tipo de documento
    doc_title = "DOCUMENTAÇÃO TÉCNICA COMPLETA"
    doc_title_y = PAGE_H - 176 * mm
    doc_title_h = 16 * mm
    doc_title_w = PAGE_W - 40 * mm
    doc_title_x = 20 * mm

    c.setFillColor(C_TEAL)
    c.roundRect(doc_title_x, doc_title_y - 3 * mm, doc_title_w, doc_title_h, 3 * mm, fill=1, stroke=0)

    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(PAGE_W / 2, doc_title_y + 3 * mm, doc_title)

    # Versão/data abaixo
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 9)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 198 * mm, "Versão 1.0.0.26  |  16 de agosto de 2026")

    # Card de informações (maior e mais centralizado, sem assinaturas)
    card_x = 35 * mm
    card_y = 38 * mm
    card_w = PAGE_W - 70 * mm
    card_h = 75 * mm

    c.setFillColor(C_LIGHT)
    c.roundRect(card_x, card_y, card_w, card_h, 5 * mm, fill=1, stroke=0)

    # Borda coral esquerda
    c.setFillColor(C_ACCENT)
    c.roundRect(card_x, card_y, 3 * mm, card_h, 1.5 * mm, fill=1, stroke=0)

    items = [
        ("DESENVOLVEDOR", "Yuri Medeiros Bandeira"),
        ("CLIENTE", "Jonas Almeida Medeiros"),
        ("VERSÃO", "1.0.0.26"),
        ("DATA", "16 de agosto de 2026"),
        ("LICENÇA", "Uso controlado"),
        ("REPOSITÓRIO", "github.com/ymedeiros228/PAES_MED_AI"),
    ]
    for i, (label, value) in enumerate(items):
        y = card_y + card_h - 14 * mm - i * 10.5 * mm
        c.setFillColor(C_PRIMARY)
        c.setFont("Helvetica-Bold", 8)
        c.drawString(card_x + 10 * mm, y, label)
        c.setFillColor(C_TEXT)
        c.setFont("Helvetica", 10)
        c.drawString(card_x + 45 * mm, y, value)

    # Texto de copyright discreto no rodapé da capa
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica-Oblique", 7.5)
    c.drawCentredString(PAGE_W / 2, 18 * mm, "© 2026 PAES MED AI — Documentação Técnica Completa")

    c.restoreState()


def draw_back_cover(c, doc):
    """Contra-capa profissional — página final do documento."""
    c.saveState()

    # Fundo escuro (igual à capa)
    c.setFillColor(C_DARK)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    # Faixa azul-marinho superior (espelho da capa)
    c.setFillColor(C_PRIMARY)
    c.rect(0, PAGE_H - 6 * mm, PAGE_W, 6 * mm, fill=1, stroke=0)

    # Faixa coral inferior (espelho da capa)
    c.setFillColor(C_ACCENT)
    c.rect(0, 0, PAGE_W, 6 * mm, fill=1, stroke=0)

    # Logo centralizado
    if LOGO.exists():
        logo_size = 40 * mm
        logo_x = (PAGE_W - logo_size) / 2
        logo_y = PAGE_H - 70 * mm
        c.setFillColor(C_WHITE)
        c.circle(PAGE_W / 2, logo_y + logo_size / 2, logo_size / 2 + 3 * mm, fill=1, stroke=0)
        c.drawImage(str(LOGO), logo_x, logo_y, logo_size, logo_size, mask='auto')

    # Título
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 85 * mm, "PAES MED AI")

    c.setFillColor(C_SECONDARY)
    c.setFont("Helvetica", 11)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 93 * mm, "Plataforma Inteligente de Estudos")

    # Linha decorativa
    c.setStrokeColor(C_ACCENT)
    c.setLineWidth(1.5)
    c.line(PAGE_W / 2 - 35 * mm, PAGE_H - 100 * mm, PAGE_W / 2 + 35 * mm, PAGE_H - 100 * mm)

    # QR Code centralizado
    qr_path = SHOTS / "qrcode_web.png"
    if qr_path.exists():
        qr_size = 55 * mm
        qr_x = (PAGE_W - qr_size) / 2
        qr_y = PAGE_H - 175 * mm
        c.setFillColor(C_WHITE)
        c.roundRect(qr_x - 5 * mm, qr_y - 5 * mm, qr_size + 10 * mm, qr_size + 10 * mm, 3 * mm, fill=1, stroke=0)
        c.drawImage(str(qr_path), qr_x, qr_y, qr_size, qr_size, mask='auto')

    # Texto abaixo do QR
    c.setFillColor(C_ACCENT)
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 188 * mm, "Escaneie para acessar a versão Web")

    c.setFillColor(C_WHITE)
    c.setFont("Helvetica", 9)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 196 * mm, "https://paes-med-ai.onrender.com")

    # Card de contato
    card_x = 30 * mm
    card_y = 35 * mm
    card_w = PAGE_W - 60 * mm
    card_h = 45 * mm

    c.setFillColor(C_LIGHT)
    c.roundRect(card_x, card_y, card_w, card_h, 4 * mm, fill=1, stroke=0)

    # Borda coral direita (espelho da capa)
    c.setFillColor(C_ACCENT)
    c.roundRect(card_x + card_w - 3 * mm, card_y, 3 * mm, card_h, 1.5 * mm, fill=1, stroke=0)

    contact = [
        ("DESENVOLVEDOR", "Yuri Medeiros Bandeira"),
        ("CLIENTE", "Jonas Almeida Medeiros"),
        ("REPOSITÓRIO", "github.com/ymedeiros228/PAES_MED_AI"),
        ("DATA", "16 de agosto de 2026"),
    ]
    for i, (label, value) in enumerate(contact):
        y = card_y + card_h - 10 * mm - i * 9 * mm
        c.setFillColor(C_PRIMARY)
        c.setFont("Helvetica-Bold", 8)
        c.drawString(card_x + 8 * mm, y, label)
        c.setFillColor(C_TEXT)
        c.setFont("Helvetica", 9)
        c.drawString(card_x + 38 * mm, y, value)

    # Copyright
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica-Oblique", 7.5)
    c.drawCentredString(PAGE_W / 2, 12 * mm, "© 2026 PAES MED AI — Todos os direitos reservados")

    c.restoreState()


def draw_landscape_header(c, doc):
    """Cabeçalho e rodapé em páginas paisagem da galeria."""
    c.saveState()
    # c.page e doc estão em landscape: PAGE_W=297, PAGE_H=210
    w, h = doc.pagesize

    # Faixa teal superior
    c.setStrokeColor(C_TEAL)
    c.setLineWidth(1.5)
    c.line(18 * mm, h - 15 * mm, w - 18 * mm, h - 15 * mm)

    c.setFillColor(C_PRIMARY)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(18 * mm, h - 11 * mm, "PAES MED AI — Galeria de Telas")
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 9)
    c.drawRightString(w - 18 * mm, h - 11 * mm, f"Página {doc.page}")

    # Faixa inferior
    c.setStrokeColor(C_PRIMARY)
    c.setLineWidth(0.8)
    c.line(18 * mm, 14 * mm, w - 18 * mm, 14 * mm)
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawCentredString(w / 2, 9 * mm, "Documentação Técnica Completa · v1.0.0.26")

    c.restoreState()


def draw_header_footer(c, doc):
    """Cabeçalho e rodapé elegantes em cada página de conteúdo."""
    c.saveState()

    # Cabeçalho — faixa fina coral
    c.setStrokeColor(C_ACCENT)
    c.setLineWidth(1.2)
    c.line(MARGIN_L, PAGE_H - 18 * mm, PAGE_W - MARGIN_R, PAGE_H - 18 * mm)

    # Logo pequeno
    if LOGO.exists():
        c.drawImage(str(LOGO), MARGIN_L, PAGE_H - 16 * mm, 6 * mm, 6 * mm, mask='auto')

    c.setFillColor(C_PRIMARY)
    c.setFont("Helvetica-Bold", 8)
    c.drawString(MARGIN_L + 8 * mm, PAGE_H - 14 * mm, "PAES MED AI")
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - MARGIN_R, PAGE_H - 14 * mm, "Documentação Técnica Completa")

    # Rodapé — linha azul-marinho
    c.setStrokeColor(C_PRIMARY)
    c.setLineWidth(0.6)
    c.line(MARGIN_L, 16 * mm, PAGE_W - MARGIN_R, 16 * mm)

    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 7.5)
    c.drawString(MARGIN_L, 11 * mm, "Yuri Medeiros Bandeira  ·  Cliente: Jonas Almeida Medeiros")
    c.drawRightString(PAGE_W - MARGIN_R, 11 * mm, f"Página {doc.page}")
    c.setFillColor(C_ACCENT)
    c.setFont("Helvetica-Oblique", 7)
    c.drawCentredString(PAGE_W / 2, 11 * mm, "v1.0.0.26")

    c.restoreState()


# ============================================================
#  ESTILOS DE PARÁGRAFO
# ============================================================

def build_styles():
    s = getSampleStyleSheet()

    s.add(ParagraphStyle("PAESBody", parent=s["Normal"], fontName="Helvetica",
        fontSize=10, leading=15, textColor=C_TEXT, spaceAfter=7, alignment=TA_JUSTIFY))

    s.add(ParagraphStyle("PAESH1", parent=s["Heading1"], fontName="Helvetica-Bold",
        fontSize=20, leading=26, textColor=C_PRIMARY, spaceBefore=8, spaceAfter=4))

    s.add(ParagraphStyle("PAESH1Num", parent=s["Normal"], fontName="Helvetica-Bold",
        fontSize=28, leading=32, textColor=C_ACCENT, spaceAfter=0))

    s.add(ParagraphStyle("PAESH2", parent=s["Heading2"], fontName="Helvetica-Bold",
        fontSize=14, leading=18, textColor=C_SECONDARY, spaceBefore=16, spaceAfter=6))

    s.add(ParagraphStyle("PAESH3", parent=s["Heading3"], fontName="Helvetica-Bold",
        fontSize=11, leading=15, textColor=C_DARK, spaceBefore=10, spaceAfter=4))

    s.add(ParagraphStyle("PAESBullet", parent=s["Normal"], fontName="Helvetica",
        fontSize=10, leading=14, textColor=C_TEXT, leftIndent=16, bulletIndent=4, spaceAfter=3))

    s.add(ParagraphStyle("PAESCode", parent=s["Code"], fontName="Courier",
        fontSize=8.5, leading=12, textColor=C_DARK, backColor=C_LIGHT,
        borderPadding=8, spaceBefore=6, spaceAfter=8, leftIndent=4, rightIndent=4))

    s.add(ParagraphStyle("PAESCaption", parent=s["Normal"], fontName="Helvetica-Oblique",
        fontSize=8.5, leading=12, textColor=C_MUTED, spaceAfter=10, alignment=TA_CENTER))

    s.add(ParagraphStyle("PAESSmall", parent=s["Normal"], fontName="Helvetica",
        fontSize=9, leading=13, textColor=C_TEXT, spaceAfter=5))

    s.add(ParagraphStyle("PAESLead", parent=s["Normal"], fontName="Helvetica",
        fontSize=11, leading=17, textColor=C_TEXT, spaceAfter=10, alignment=TA_JUSTIFY))

    # Estilos para células de tabela (com wrap automático)
    s.add(ParagraphStyle("TCell", parent=s["Normal"], fontName="Helvetica",
        fontSize=9, leading=12, textColor=C_TEXT, alignment=TA_LEFT))

    s.add(ParagraphStyle("TCellBold", parent=s["Normal"], fontName="Helvetica-Bold",
        fontSize=9, leading=12, textColor=C_TEXT, alignment=TA_LEFT))

    s.add(ParagraphStyle("THead", parent=s["Normal"], fontName="Helvetica-Bold",
        fontSize=9.5, leading=12, textColor=C_WHITE, alignment=TA_LEFT))

    s.add(ParagraphStyle("TCellCenter", parent=s["Normal"], fontName="Helvetica",
        fontSize=9, leading=12, textColor=C_TEXT, alignment=TA_CENTER))

    s.add(ParagraphStyle("TCellBoldCenter", parent=s["Normal"], fontName="Helvetica-Bold",
        fontSize=9, leading=12, textColor=C_TEXT, alignment=TA_CENTER))

    s.add(ParagraphStyle("THeadCenter", parent=s["Normal"], fontName="Helvetica-Bold",
        fontSize=9.5, leading=12, textColor=C_WHITE, alignment=TA_CENTER))

    return s


# ============================================================
#  COMPONENTES REUTILIZÁVEIS
# ============================================================

def section_header(num, title, styles):
    """Cabeçalho de seção com número grande coral e título."""
    tbl = Table([
        [Paragraph(num, styles["PAESH1Num"]), Paragraph(title, styles["PAESH1"])]
    ], colWidths=[20*mm, CONTENT_W - 20*mm])
    tbl.setStyle(TableStyle([
        ("VALIGN", (0,0), (-1,-1), "BOTTOM"),
        ("LEFTPADDING", (0,0), (-1,-1), 0),
        ("RIGHTPADDING", (0,0), (-1,-1), 0),
        ("TOPPADDING", (0,0), (-1,-1), 0),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
        ("LINEBELOW", (0,0), (-1,-1), 2, C_ACCENT),
        ("BOTTOMPADDING", (0,0), (-1,0), 6),
    ]))
    return tbl


def P(text, style):
    """Atalho para criar Paragraph."""
    return Paragraph(text, style)


def make_table(data, col_widths=None, styles=None, header=True, center_cols=None):
    """
    Cria tabela estilizada com Paragraph em todas as células (wrap automático).
    `data` deve ser lista de listas de strings.
    `center_cols` = lista de índices de colunas para centralizar.
    """
    if styles is None:
        styles = build_styles()
    if col_widths is None:
        n = len(data[0])
        col_widths = [CONTENT_W / n] * n
    if center_cols is None:
        center_cols = []

    # Converte todas as células para Paragraph
    rows = []
    for r_idx, row in enumerate(data):
        new_row = []
        for c_idx, cell in enumerate(row):
            if isinstance(cell, (Paragraph, Table, RLImage, Spacer)):
                new_row.append(cell)
            else:
                cell_str = str(cell) if cell is not None else ""
                if r_idx == 0 and header:
                    style = styles["THeadCenter"] if c_idx in center_cols else styles["THead"]
                elif c_idx in center_cols:
                    style = styles["TCellBoldCenter"] if r_idx == 0 and not header else styles["TCellCenter"]
                else:
                    style = styles["TCell"]
                new_row.append(Paragraph(cell_str, style))
        rows.append(new_row)

    t = Table(rows, colWidths=col_widths, repeatRows=1 if header else 0)
    style = [
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("LEFTPADDING", (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING", (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("ROWBACKGROUNDS", (0,1 if header else 0), (-1,-1), [C_WHITE, C_TABLE_ALT]),
        ("LINEBELOW", (0,0), (-1,-1), 0.3, C_DIVIDER),
        ("BOX", (0,0), (-1,-1), 0.5, C_DIVIDER),
    ]
    if header:
        style += [
            ("BACKGROUND", (0,0), (-1,0), C_TABLE_HEAD),
            ("TOPPADDING", (0,0), (-1,0), 8),
            ("BOTTOMPADDING", (0,0), (-1,0), 8),
            ("LINEBELOW", (0,0), (-1,0), 1.5, C_ACCENT),
        ]
    t.setStyle(TableStyle(style))
    return t


def screenshot(name, caption_text, styles, width=None, max_height=None):
    """Insere um screenshot com legenda, se existir. 'name' pode conter subpastas."""
    path = SHOTS / f"{name}.png"
    if not path.exists():
        return []
    if width is None:
        width = CONTENT_W
    if max_height is None:
        max_height = 170 * mm
    from PIL import Image as PILImage
    img = PILImage.open(str(path))
    w, h = img.size
    aspect = h / w
    height = width * aspect
    if height > max_height:
        height = max_height
        width = height / aspect
    return [
        RLImage(str(path), width=width, height=height),
        Paragraph(caption_text, styles["PAESCaption"]),
    ]


# ============================================================
#  CONSTRUÇÃO DO PDF
# ============================================================

def build_pdf():
    styles = build_styles()
    story = []

    # ===== CAPA =====
    story.append(Spacer(1, 1))
    story.append(NextPageTemplate("content"))
    story.append(PageBreak())

    # ===== 01 SUMÁRIO EXECUTIVO =====
    story.append(section_header("01", "Sumário Executivo", styles))
    story.append(Spacer(1, 8))
    story.append(Paragraph(
        "O <b>PAES MED AI</b> é uma plataforma desktop <b>offline-first</b> desenvolvida para "
        "estudantes que se preparam para o exame PAES/UEMA Medicina. A plataforma centraliza "
        "<b>720 questões reais</b> de 13 anos de prova (2014–2026), <b>738 flashcards</b> com "
        "revisão espaçada, <b>92 materiais em PDF</b> organizados por disciplina e um "
        "<b>tutor de IA</b> opcional para tirar dúvidas.",
        styles["PAESLead"]
    ))
    story.append(Paragraph(
        "Diferente de plataformas online que dependem de internet, o PAES MED AI funciona "
        "<b>100% localmente</b> — nenhum dado do usuário sai do computador. O instalador "
        "Windows cria atalho na Área de Trabalho e o app abre em aproximadamente 2 segundos.",
        styles["PAESLead"]
    ))
    story.append(Spacer(1, 10))

    # Card de informações
    story.append(make_table([
        ["Campo", "Valor"],
        ["Projeto", "PAES MED AI — Plataforma Inteligente de Estudos"],
        ["Desenvolvedor", "Yuri Medeiros Bandeira"],
        ["Cliente", "Jonas Almeida Medeiros"],
        ["Versão", "1.0.0.26"],
        ["Data", "16 de agosto de 2026"],
        ["Licença", "Uso controlado (ver LICENSE)"],
        ["Repositório", "github.com/ymedeiros228/PAES_MED_AI"],
        ["Plataformas", "Windows desktop + PWA web"],
    ], col_widths=[40*mm, CONTENT_W - 40*mm], styles=styles))

    story.append(Spacer(1, 15))
    story.append(Paragraph("Destaques", styles["PAESH2"]))
    story.append(make_table([
        ["Métrica", "Valor"],
        ["Questões reais", "720 (2014–2026)"],
        ["Flashcards", "738"],
        ["Aulas em texto", "218"],
        ["Materiais PDF", "92"],
        ["Disciplinas", "9"],
        ["Anos de prova", "13"],
        ["Provedores de IA", "4 (OpenAI, Groq, Gemini, OpenRouter)"],
        ["Tempo de abertura", "~2 segundos"],
    ], col_widths=[60*mm, CONTENT_W - 60*mm], styles=styles))

    story.append(PageBreak())

    # ===== 02 INTRODUÇÃO =====
    story.append(section_header("02", "Introdução", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("2.1 Contexto", styles["PAESH2"]))
    story.append(Paragraph(
        "O <b>PAES</b> (Processo Seletivo Seriado) da <b>UEMA</b> (Universidade Estadual do "
        "Maranhão) é o principal caminho para ingresso no curso de <b>Medicina</b> da "
        "universidade. A prova cobre conteúdo de todo o ensino médio em 9 disciplinas, com "
        "peso maior para Biologia, Química e Física.",
        styles["PAESBody"]
    ))
    story.append(Paragraph(
        "Estudantes maranhenses precisam de uma ferramenta que centralize questões oficiais "
        "reais, ofereça resoluções detalhadas e macetes, permita revisão espaçada, forneça "
        "material de estudo organizado, funcione offline e tenha um tutor de IA. O "
        "<b>PAES MED AI</b> resolve todos esses pontos em uma única plataforma.",
        styles["PAESBody"]
    ))

    story.append(Paragraph("2.2 Objetivos", styles["PAESH2"]))
    story.append(Paragraph("<b>Objetivo geral:</b> Desenvolver uma plataforma desktop offline-first "
        "para preparação completa ao PAES/UEMA Medicina.", styles["PAESBody"]))
    story.append(Spacer(1, 4))
    story.append(Paragraph("<b>Objetivos específicos:</b>", styles["PAESBody"]))
    for b in [
        "Banco com <b>720 questões reais</b> de 13 anos de prova (2014–2026)",
        "<b>738 flashcards</b> para revisão espaçada (SRS)",
        "<b>218 aulas</b> em texto com teoria completa",
        "<b>92 materiais em PDF</b> organizados por disciplina",
        "<b>Resoluções detalhadas</b> para todas as questões",
        "Tutor de IA opcional (OpenAI, Groq, Gemini ou OpenRouter)",
        "Funcionamento <b>100% offline</b> (sem internet)",
        "Instalador Windows profissional com atalho na Área de Trabalho",
        "PWA para acesso via navegador",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(PageBreak())

    # ===== 03 FUNCIONALIDADES =====
    story.append(section_header("03", "Funcionalidades", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("3.1 Banco de Questões", styles["PAESH2"]))
    story.append(make_table([
        ["Recurso", "Descrição"],
        ["Questões reais", "720 questões de provas oficiais PAES/UEMA (2014–2026)"],
        ["9 disciplinas", "Biologia, Química, Física, História, Português, Matemática, Filosofia, Geografia, Sociologia"],
        ["Resoluções", "Cada questão tem resolução detalhada em português"],
        ["Macetes", "Dicas mnemônicas para memorização rápida"],
        ["Pegadinhas", "Avisos de armadilhas comuns da banca"],
        ["Filtros", "Por disciplina, ano, tópico, dificuldade"],
        ["Modo simulado", "Reproduz condições de prova cronometrada"],
    ], col_widths=[45*mm, CONTENT_W - 45*mm], styles=styles))

    story.append(Paragraph("3.2 Flashcards (Revisão Espaçada)", styles["PAESH2"]))
    for b in [
        "738 flashcards gerados a partir do conteúdo do edital",
        "Algoritmo de repetição espaçada (SRS) — revisa no momento certo",
        "Filtros por disciplina e tópico",
        "Marcação de acertei/errei",
        "Priorização automática de cards vencidos (due)",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(PageBreak())

    story.append(Paragraph("3.3 Material de Estudo", styles["PAESH2"]))
    for b in [
        "92 PDFs com teoria completa por disciplina",
        "Diagramas e imagens ilustrativas em cada material",
        "Indexação automática por tópico do edital",
        "Leitor PDF integrado — não precisa de software externo",
        "Cobertura completa do edital PAES",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("3.4 Tutor de IA", styles["PAESH2"]))
    for b in [
        "Suporte a 4 provedores: OpenAI, Groq, Gemini, OpenRouter",
        "Configuração via tela de Configurações (chave em .env)",
        "Funciona <b>offline</b> se nenhuma chave for configurada",
        "Explica conceitos, resolve dúvidas e sugere planos de estudo",
        "Histórico de conversas salvo localmente",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("3.5 Dashboard e Progresso", styles["PAESH2"]))
    for b in [
        "Estatísticas em tempo real: questões respondidas, taxa de acerto",
        "Gráficos de desempenho por disciplina (fl_chart)",
        "Streak de dias consecutivos de estudo",
        "Progresso por disciplina com barras visuais",
        "Recomendações de estudo personalizadas (coach IA)",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("3.6 Plano de Estudo e Simulados", styles["PAESH2"]))
    for b in [
        "Data da prova configurável — cronograma automático até o dia",
        "Distribuição de tópicos por dia com checkpoints",
        "Identificação de lacunas de conhecimento (study gaps)",
        "Simulados com cronômetro e correção automática",
        "Histórico de simulados anteriores com estatísticas",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(PageBreak())

    # ===== 04 ARQUITETURA =====
    story.append(section_header("04", "Arquitetura de Software", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("4.1 Stack Tecnológica", styles["PAESH2"]))
    story.append(make_table([
        ["Camada", "Tecnologia"],
        ["Frontend desktop", "Flutter 3.x + Riverpod + GoRouter"],
        ["Frontend web", "Flutter Web (PWA)"],
        ["Backend", "FastAPI (Python) + Uvicorn"],
        ["Banco de dados", "SQLite com WAL mode"],
        ["IA (opcional)", "OpenAI / Groq / Gemini / OpenRouter"],
        ["Empacotamento", "Inno Setup 6 (Windows)"],
        ["Tipografia", "Google Fonts (Inter, Poppins)"],
        ["Gráficos", "fl_chart"],
        ["PDFs", "pypdf (leitura) + reportlab (geração)"],
    ], col_widths=[50*mm, CONTENT_W - 50*mm], styles=styles))

    story.append(Paragraph("4.2 Estrutura de Pastas", styles["PAESH2"]))
    tree = (
        "PAES_MED_AI/<br/>"
        "├── lib/                          # Código Flutter (Dart)<br/>"
        "│   ├── main.dart                 # Entry point<br/>"
        "│   ├── app.dart                  # App + rotas<br/>"
        "│   ├── core/                     # Núcleo (API client, tema, versão)<br/>"
        "│   └── features/                 # 22 funcionalidades<br/>"
        "│       ├── dashboard/            # Tela principal<br/>"
        "│       ├── questions/            # Banco de questões<br/>"
        "│       ├── flashcards/           # Revisão espaçada<br/>"
        "│       ├── materials/            # Materiais PDF<br/>"
        "│       ├── ai_tutor/             # Tutor de IA<br/>"
        "│       ├── simulations/          # Simulados<br/>"
        "│       ├── study_plan/           # Plano de estudo<br/>"
        "│       └── ...                   # Outras features<br/>"
        "├── backend/                      # API FastAPI (Python)<br/>"
        "│   ├── main.py                   # Entry point da API<br/>"
        "│   ├── config.py                 # Configuração de ambiente<br/>"
        "│   ├── db.py                     # Conexão SQLite<br/>"
        "│   ├── routers/                  # 13 endpoints REST<br/>"
        "│   └── requirements.txt          # Dependências Python<br/>"
        "├── data/                         # Dados locais<br/>"
        "│   ├── paes_med_ai.db            # Banco SQLite (720 questões)<br/>"
        "│   ├── materiais/                # 92 PDFs de estudo<br/>"
        "│   ├── edital/                   # Edital PAES<br/>"
        "│   └── gabaritos/                # Gabaritos oficiais<br/>"
        "├── installer/                    # Inno Setup<br/>"
        "├── Iniciar_PAES_MED_AI.bat       # Launcher Windows<br/>"
        "├── Iniciar_PAES_MED_AI.vbs       # Wrapper invisível<br/>"
        "└── pubspec.yaml                  # Dependências Flutter"
    )
    story.append(Paragraph(tree, styles["PAESCode"]))

    story.append(Paragraph("4.3 Fluxo de Execução (Desktop)", styles["PAESH2"]))
    flow = (
        "Usuário clica no atalho \"PAES MED AI Desktop\"<br/>"
        "        ↓<br/>"
        "wscript.exe executa Iniciar_PAES_MED_AI.vbs (invisível)<br/>"
        "        ↓<br/>"
        "VBS chama Iniciar_PAES_MED_AI.bat (escondido)<br/>"
        "        ↓<br/>"
        "Launcher abre paes_med_ai.exe IMEDIATAMENTE (~2s)<br/>"
        "        ↓<br/>"
        "Em paralelo: sobe backend Uvicorn na porta 8000<br/>"
        "        ↓<br/>"
        "App Flutter conecta a http://127.0.0.1:8000<br/>"
        "        ↓<br/>"
        "Dados aparecem (dashboard, questões, flashcards)"
    )
    story.append(Paragraph(flow, styles["PAESCode"]))

    story.append(PageBreak())

    # ===== 05 CONTEÚDO =====
    story.append(section_header("05", "Conteúdo do Banco de Dados", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("5.1 Distribuição por Disciplina", styles["PAESH2"]))
    story.append(make_table([
        ["Disciplina", "Questões", "Prioridade PAES"],
        ["História", "167", "Alta"],
        ["Física", "149", "Alta (peso Medicina)"],
        ["Biologia", "90", "MÁXIMA (peso Medicina)"],
        ["Química", "80", "MÁXIMA (peso Medicina)"],
        ["Língua Portuguesa e Literatura", "69", "Média"],
        ["Matemática", "50", "Média"],
        ["Filosofia", "45", "Média"],
        ["Geografia", "39", "Média"],
        ["Sociologia", "31", "Baixa"],
        ["TOTAL", "720", "—"],
    ], col_widths=[75*mm, 30*mm, CONTENT_W - 105*mm], styles=styles, center_cols=[1]))

    story.append(Spacer(1, 12))
    story.append(Paragraph("5.2 Distribuição por Ano de Prova", styles["PAESH2"]))
    story.append(make_table([
        ["Ano", "Questões", "Ano", "Questões", "Ano", "Questões"],
        ["2014", "79", "2019", "34", "2023", "41"],
        ["2015", "59", "2020", "44", "2024", "81"],
        ["2016", "57", "2021", "48", "2025", "50"],
        ["2017", "66", "2022", "47", "2026", "46"],
        ["2018", "68", "", "", "", ""],
    ], col_widths=[28*mm, 28*mm, 28*mm, 28*mm, 28*mm, CONTENT_W - 148*mm],
       styles=styles, center_cols=[0,1,2,3,4,5]))

    story.append(Spacer(1, 12))
    story.append(Paragraph("5.3 Material de Estudo (92 PDFs)", styles["PAESH2"]))
    story.append(make_table([
        ["Disciplina", "PDFs", "Tópicos Cobertos"],
        ["Biologia", "19", "Citologia, Genética, Ecologia, Zoologia, Botânica, Microbiologia, Histologia, Reprodução, Saúde, Evolução"],
        ["Química", "13", "Princípios, Átomos, Ligações, Funções, Reações, Soluções, Gases, Cálculos, Termoquímica, Eletroquímica, Orgânica"],
        ["Física", "11", "Cinemática, Dinâmica, Eletrostática, Eletrodinâmica, Hidrostática, Ondulatória, Óptica, Termologia, Moderna"],
        ["Matemática", "11", "Aritmética, Conjuntos, Funções, Geometria, Matrizes, Trigonometria, Estatística, Combinatória"],
        ["Sociologia", "9", "Surgimento, Clássicas, Conceitos, Cultura, Estado, Trabalho, Mudança, Violência"],
        ["Português", "7", "Comunicação, Morfossintaxe, Semântica, Sintaxe, Texto, Literatura, Obras"],
        ["Filosofia", "7", "Filosofia, Conhecimento, Ética, Política, Cultura, Estética, Lógica"],
        ["História", "6", "Mundo Antigo, Medieval, Moderno, Contemporâneo, Brasil, Maranhão"],
        ["Geografia", "4", "Física, Humana, Maranhão, Temas Contemporâneos"],
        ["Espanhol", "3", "Compreensão, Gramática, Semântica"],
        ["Inglês", "3", "Gramática, Leitura, Léxico"],
    ], col_widths=[35*mm, 18*mm, CONTENT_W - 53*mm], styles=styles, center_cols=[1]))

    story.append(PageBreak())

    # ===== 06 INSTALAÇÃO =====
    story.append(section_header("06", "Instalação e Execução", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("6.1 Instalação para o Usuário Final (Windows)", styles["PAESH2"]))
    steps = [
        "Baixar o instalador <b>PAESMedAI_Setup_1.0.0.26.exe</b>",
        "Executar o instalador com duplo clique",
        "Seguir o assistente (Avançar → Avançar → Instalar)",
        "Ao final, será criado o atalho <b>PAES MED AI Desktop</b> na Área de Trabalho",
        "Atalhos no Menu Iniciar: Iniciar, Atualizar, Desinstalar",
        "Clicar no atalho <b>PAES MED AI Desktop</b> para abrir o aplicativo",
    ]
    for i, s in enumerate(steps, 1):
        story.append(Paragraph(f"{i}. {s}", styles["PAESBullet"]))

    story.append(Paragraph(
        "<b>Local de instalação:</b> C:\\Users\\&lt;usuario&gt;\\AppData\\Local\\Programs\\PAES_MED_AI\\",
        styles["PAESBody"]
    ))

    story.append(Paragraph("6.2 Estrutura Instalada", styles["PAESH2"]))
    tree2 = (
        "PAES_MED_AI/<br/>"
        "├── Iniciar_PAES_MED_AI.bat       # Launcher<br/>"
        "├── Iniciar_PAES_MED_AI.vbs       # Wrapper invisível<br/>"
        "├── VERSION.txt                   # Versão instalada<br/>"
        "├── app/<br/>"
        "│   ├── paes_med_ai.exe           # App Flutter<br/>"
        "│   ├── flutter_windows.dll       # Runtime Flutter<br/>"
        "│   └── data/                     # Assets do app<br/>"
        "├── backend/                      # API FastAPI<br/>"
        "│   ├── main.py<br/>"
        "│   ├── routers/<br/>"
        "│   └── requirements.txt<br/>"
        "├── data/                         # Dados locais<br/>"
        "│   ├── paes_med_ai.db            # Banco SQLite<br/>"
        "│   ├── materiais/                # 92 PDFs<br/>"
        "│   ├── edital/<br/>"
        "│   └── gabaritos/<br/>"
        "└── tools/                        # Scripts utilitários"
    )
    story.append(Paragraph(tree2, styles["PAESCode"]))

    story.append(Paragraph("6.3 Desenvolvimento Local", styles["PAESH2"]))
    story.append(Paragraph("<b>Pré-requisitos:</b> Python 3.10+, Flutter 3.x, Inno Setup 6", styles["PAESBody"]))
    dev = (
        "# 1. Clonar repositório<br/>"
        "git clone https://github.com/ymedeiros228/PAES_MED_AI.git<br/>"
        "cd PAES_MED_AI<br/>"
        "<br/>"
        "# 2. Backend<br/>"
        "cd backend<br/>"
        "python -m venv .venv<br/>"
        ".venv\\Scripts\\activate<br/>"
        "pip install -r requirements.txt<br/>"
        "uvicorn main:app --reload<br/>"
        "<br/>"
        "# 3. Frontend (outra janela)<br/>"
        "flutter pub get<br/>"
        "flutter run -d windows<br/>"
        "<br/>"
        "# 4. Compilar instalador<br/>"
        "flutter build windows --release<br/>"
        "python tools/prepare_installer.py<br/>"
        "cd installer && ISCC.exe paes_med_ai.iss"
    )
    story.append(Paragraph(dev, styles["PAESCode"]))

    story.append(PageBreak())

    # ===== 07 API =====
    story.append(section_header("07", "API REST", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("7.1 Endpoints Principais", styles["PAESH2"]))
    story.append(make_table([
        ["Método", "Rota", "Descrição"],
        ["GET", "/health", "Health check do servidor"],
        ["GET", "/api/dashboard", "Dashboard com estatísticas gerais"],
        ["GET", "/api/questions", "Lista questões (filtros: subject, year, topic)"],
        ["GET", "/api/questions/{id}", "Questão específica com resolução e macete"],
        ["POST", "/api/questions/{id}/answer", "Registra resposta do usuário"],
        ["GET", "/api/flashcards", "Lista flashcards (dueOnly=true para vencidos)"],
        ["POST", "/api/flashcards/{id}/review", "Registra revisão (acertei/errei)"],
        ["GET", "/api/materials", "Lista materiais PDF indexados"],
        ["GET", "/api/materials/{id}/file", "Download do PDF"],
        ["GET", "/api/lessons", "Lista aulas em texto"],
        ["GET", "/api/simulations", "Lista simulados"],
        ["POST", "/api/simulations", "Cria novo simulado"],
        ["GET", "/api/stats", "Estatísticas detalhadas do usuário"],
        ["GET", "/api/study/plan", "Plano de estudo personalizado"],
        ["POST", "/api/study/exam-date", "Define data da prova"],
        ["GET", "/api/coach/recommendations", "Recomendações de estudo (IA)"],
        ["POST", "/api/ai/chat", "Chat com tutor de IA"],
        ["GET", "/api/ai/config", "Configuração atual de IA"],
    ], col_widths=[20*mm, 60*mm, CONTENT_W - 80*mm], styles=styles, center_cols=[0]))

    story.append(Paragraph("7.2 Configuração de IA", styles["PAESH2"]))
    story.append(Paragraph(
        "O tutor de IA suporta 4 provedores configuráveis via arquivo <b>.env</b>:",
        styles["PAESBody"]
    ))
    story.append(make_table([
        ["Provedor", "Variáveis de Ambiente", "Modelo Padrão"],
        ["OpenAI", "OPENAI_API_KEY, OPENAI_MODEL", "gpt-4.1-mini"],
        ["Groq", "GROQ_API_KEY, GROQ_MODEL", "llama-3.3-70b-versatile"],
        ["Gemini", "GEMINI_API_KEY, GEMINI_MODEL", "gemini-3-flash-preview"],
        ["OpenRouter", "OPENROUTER_API_KEY, OPENROUTER_MODEL", "—"],
    ], col_widths=[35*mm, 70*mm, CONTENT_W - 105*mm], styles=styles))
    story.append(Paragraph(
        "<b>Sem chave configurada:</b> o app funciona 100% offline, apenas sem o tutor de IA.",
        styles["PAESBody"]
    ))

    story.append(PageBreak())

    # ===== 08 LAUNCHER =====
    story.append(section_header("08", "Launcher e Inicialização", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("8.1 Fluxo do Launcher", styles["PAESH2"]))
    story.append(Paragraph(
        "O launcher foi projetado para abrir o app em <b>~2 segundos</b>, sem tela preta, "
        "subindo o backend em paralelo. Isso resolve o problema de apps que parecem "
        "travados enquanto esperam o backend ficar pronto.",
        styles["PAESBody"]
    ))
    for b in [
        "<b>Abrir o app imediatamente</b> (~2s) — não espera o backend",
        "<b>Subir o backend em paralelo</b> — Uvicorn na porta 8000",
        "<b>Caminho completo do Python</b> — evita o Windows Store stub",
        "<b>Funciona sem Python</b> — app abre em modo offline",
        "<b>VBS wrapper invisível</b> — sem tela preta de cmd",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("8.2 Resolução de Problemas", styles["PAESH2"]))
    story.append(make_table([
        ["Problema", "Solução"],
        ["App não abre", "Verificar se app/paes_med_ai.exe existe"],
        ["Sem conexão", "Aguardar 5–10s (backend subindo) ou verificar Python"],
        ["Backend não sobe", "Verificar data/logs/launcher.log"],
        ["Python não encontrado", "Instalar Python 3.10+ de python.org"],
        ["Porta 8000 ocupada", "Launcher mata o processo automaticamente"],
        ["Versão antiga no painel", "Reinstalar — o exe tem a versão compilada dentro"],
    ], col_widths=[55*mm, CONTENT_W - 55*mm], styles=styles))

    story.append(PageBreak())

    # ===== 09 SEGURANÇA =====
    story.append(section_header("09", "Segurança e Privacidade", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("9.1 Dados do Usuário", styles["PAESH2"]))
    for b in [
        "<b>100% locais</b> — nenhum dado sai do computador do usuário",
        "Banco SQLite em data/paes_med_ai.db",
        "Respostas, progresso e configurações ficam no computador",
        "Backup automático em data/backups/",
        "Nenhum telemetry ou tracking enviado para servidores externos",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("9.2 Chaves de API", styles["PAESH2"]))
    for b in [
        "Chaves de IA ficam em backend/.env (não incluído no instalador)",
        "Nunca expostas no código-fonte ou logs",
        "Configuráveis via tela de Configurações do app",
        "Cada provedor (OpenAI, Groq, Gemini, OpenRouter) tem variáveis próprias",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(Paragraph("9.3 CORS e Acesso", styles["PAESH2"]))
    for b in [
        "Apenas origens locais permitidas (localhost, 127.0.0.1, [::1], 10.0.2.2)",
        "Em deploy web, configurar PAES_ALLOWED_ORIGINS com a URL do site",
        "Em deploy unificado (Render), o mesmo servidor serve front + API",
    ]:
        story.append(Paragraph(f"• {b}", styles["PAESBullet"]))

    story.append(PageBreak())

    # ===== 10 ROADMAP =====
    story.append(section_header("10", "Roadmap e Versões", styles))
    story.append(Spacer(1, 8))

    story.append(Paragraph("10.1 Roadmap de Desenvolvimento", styles["PAESH2"]))
    story.append(make_table([
        ["Fase", "Período", "Entregas"],
        ["1 — MVP", "Jan–Ago/2026", "App desktop, 720 questões, flashcards, materiais, instalador"],
        ["2 — IA", "Set/2026", "Tutor de IA com 4 provedores (OpenAI, Groq, Gemini, OpenRouter)"],
        ["3 — Web", "Out/2026", "PWA deployada em Render/Vercel com sincronização opcional"],
        ["4 — Mobile", "2027", "App Android/iOS com Flutter"],
        ["5 — Social", "2027", "Ranking, grupos de estudo, compartilhamento de simulados"],
    ], col_widths=[30*mm, 35*mm, CONTENT_W - 65*mm], styles=styles))

    story.append(Spacer(1, 12))
    story.append(Paragraph("10.2 Histórico de Versões", styles["PAESH2"]))
    story.append(make_table([
        ["Versão", "Data", "Principais Mudanças"],
        ["1.0.0.19", "Ago/2026", "Primeira versão com instalador Windows"],
        ["1.0.0.20", "Ago/2026", "Correção de contraste no modo escuro"],
        ["1.0.0.22", "Ago/2026", "Ícones PWA e desktop separados"],
        ["1.0.0.23", "Ago/2026", "Restauro do ícone desktop original"],
        ["1.0.0.24", "Ago/2026", "Correção do atalho (userdesktop) + VBS wrapper"],
        ["1.0.0.25", "Ago/2026", "App abre imediatamente (sem esperar backend)"],
        ["1.0.0.26", "Ago/2026", "Backend conecta (caminho completo do Python)"],
    ], col_widths=[25*mm, 30*mm, CONTENT_W - 55*mm], styles=styles))

    story.append(PageBreak())

    # ===== 11 ASSINATURAS =====
    story.append(section_header("11", "Assinaturas", styles))
    story.append(Spacer(1, 20))

    story.append(Paragraph(
        "Este documento técnico descreve a plataforma PAES MED AI versão 1.0.0.26, "
        "desenvolvida por Yuri Medeiros Bandeira para o cliente Jonas Almeida Medeiros, "
        "em 16 de agosto de 2026.",
        styles["PAESLead"]
    ))

    story.append(Spacer(1, 40))

    sig = Table([
        [
            Paragraph("<b>_______________________________</b>", styles["PAESBody"]),
            Paragraph("<b>_______________________________</b>", styles["PAESBody"]),
        ],
        [
            Paragraph("<b>Yuri Medeiros Bandeira</b>", styles["PAESBody"]),
            Paragraph("<b>Jonas Almeida Medeiros</b>", styles["PAESBody"]),
        ],
        [
            Paragraph("<i>Desenvolvedor</i>", styles["PAESCaption"]),
            Paragraph("<i>Cliente</i>", styles["PAESCaption"]),
        ],
        [
            Paragraph("16 de agosto de 2026", styles["PAESSmall"]),
            Paragraph("16 de agosto de 2026", styles["PAESSmall"]),
        ],
    ], colWidths=[(CONTENT_W - 20*mm) / 2, (CONTENT_W - 20*mm) / 2])
    sig.setStyle(TableStyle([
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING", (0,0), (-1,-1), 12),
        ("BOTTOMPADDING", (0,0), (-1,-1), 12),
    ]))
    story.append(sig)

    story.append(Spacer(1, 50))
    story.append(HRFlowable(width="100%", thickness=1, color=C_PRIMARY, spaceAfter=10))
    story.append(Paragraph(
        "© 2026 PAES MED AI — Todos os direitos reservados.<br/>"
        "Desenvolvido por Yuri Medeiros Bandeira para Jonas Almeida Medeiros.",
        styles["PAESCaption"]
    ))

    story.append(PageBreak())

    # ===== 12 QR CODE WEB =====
    story.append(section_header("12", "Acesso Web (PWA)", styles))
    story.append(Spacer(1, 12))

    story.append(Paragraph(
        "Além do aplicativo desktop, o PAES MED AI também está disponível como "
        "<b>PWA</b> (Progressive Web App) acessível pelo navegador. Escaneie o "
        "QR Code abaixo com a câmera do celular para acessar a versão web:",
        styles["PAESLead"]
    ))

    story.append(Spacer(1, 20))

    # QR Code centralizado com informações
    qr_path = SHOTS / "qrcode_web.png"
    if qr_path.exists():
        qr_img = RLImage(str(qr_path), width=70*mm, height=70*mm)

        qr_info = [
            [Paragraph("<b>PAES MED AI — Web</b>", styles["PAESBody"])],
            [Paragraph("Versão PWA para navegador", styles["PAESSmall"])],
            [Spacer(1, 8)],
            [Paragraph("<b>URL:</b>", styles["PAESSmall"])],
            [Paragraph(
                '<font color="#1B3A5B"><b>https://paes-med-ai.onrender.com</b></font>',
                styles["PAESSmall"])],
            [Spacer(1, 8)],
            [Paragraph("• Funciona em celular, tablet e computador", styles["PAESSmall"])],
            [Paragraph("• Pode ser instalado como app no celular", styles["PAESSmall"])],
            [Paragraph("• Mesmos dados do desktop (sincroniza via API)", styles["PAESSmall"])],
        ]
        info_table = Table(qr_info, colWidths=[CONTENT_W - 90*mm])

        qr_layout = Table([
            [qr_img, info_table]
        ], colWidths=[80*mm, CONTENT_W - 80*mm])
        qr_layout.setStyle(TableStyle([
            ("VALIGN", (0,0), (-1,-1), "TOP"),
            ("ALIGN", (0,0), (0,0), "CENTER"),
            ("LEFTPADDING", (0,0), (-1,-1), 10),
            ("RIGHTPADDING", (0,0), (-1,-1), 10),
            ("TOPPADDING", (0,0), (-1,-1), 10),
            ("BOTTOMPADDING", (0,0), (-1,-1), 10),
            ("BOX", (0,0), (0,0), 1.5, C_ACCENT),
            ("BACKGROUND", (0,0), (0,0), C_WHITE),
        ]))
        story.append(qr_layout)

    story.append(Spacer(1, 30))
    story.append(Paragraph(
        "Escaneie com a câmera do celular ou acesse diretamente a URL acima.",
        styles["PAESCaption"]
    ))

    # ===== 13 GALERIA DE TELAS (PAISAGEM) =====
    story.append(NextPageTemplate("landscape"))
    story.append(PageBreak())
    story.append(Paragraph("Galeria de Telas", styles["PAESH1"]))
    story.append(Paragraph(
        "Imagens reais do aplicativo PAES MED AI em funcionamento. "
        "As telas são apresentadas em páginas paisagem para melhor visualização.",
        styles["PAESBody"]
    ))

    gallery = [
        ("user/dashboard", "Dashboard principal"),
        ("user/sessao", "Sessão guiada"),
        ("user/questao", "Tela de questão"),
        ("user/progresso-analise", "Progresso — análise 0-10"),
        ("user/progresso-radar", "Progresso — constelação de habilidades"),
        ("user/progresso-evolucao", "Progresso — evolução temporal"),
        ("user/biblioteca-aulas", "Biblioteca de aulas"),
        ("user/biblioteca-materiais", "Estante de materiais"),
        ("user/material-botanica", "Leitor PDF — Botânica"),
        ("user/ajustes-escuro", "Ajustes — tema escuro"),
        ("user/ajustes-claro", "Ajustes — tema claro"),
    ]

    for name, caption in gallery:
        path = SHOTS / f"{name}.png"
        if not path.exists():
            continue
        # Página paisagem: 297x210mm. Imagem ocupa area util.
        # A4 paisagem = (297, 210). Margens 18mm.
        img = PILImage.open(str(path))
        img_w, img_h = img.size
        # Largura util ~261mm, altura util ~165mm. Imagem e widescreen (1024x372)
        avail_w = 261 * mm
        avail_h = 165 * mm
        ratio = img_h / img_w
        h = avail_w * ratio
        if h > avail_h:
            h = avail_h
            w = h / ratio
        else:
            w = avail_w
        story.append(Spacer(1, 10))
        story.append(RLImage(str(path), width=w, height=h))
        story.append(Paragraph(f"{caption}", styles["PAESCaption"]))
        story.append(PageBreak())

    # ===== CONTRA-CAPA =====
    story.append(NextPageTemplate("backcover"))
    story.append(PageBreak())
    story.append(Spacer(1, 1))

    # ===== CONSTRUIR PDF =====
    doc = SimpleDocTemplate(
        str(OUT), pagesize=A4,
        leftMargin=MARGIN_L, rightMargin=MARGIN_R,
        topMargin=MARGIN_T, bottomMargin=MARGIN_B,
        title="PAES MED AI — Documentação Técnica Completa",
        author="Yuri Medeiros Bandeira",
        subject="Documentação do projeto PAES MED AI v1.0.0.26",
    )

    frame_cover = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    frame_content = Frame(MARGIN_L, MARGIN_B, CONTENT_W, PAGE_H - MARGIN_T - MARGIN_B,
                          leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)

    # Paisagem (A4 girado): largura 297mm, altura 210mm
    LS_W, LS_H = A4[1], A4[0]  # 297, 210
    frame_landscape = Frame(18 * mm, 18 * mm, LS_W - 36 * mm, LS_H - 36 * mm,
                            leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)

    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame_cover], onPage=draw_cover),
        PageTemplate(id="content", frames=[frame_content], onPage=draw_header_footer),
        PageTemplate(id="landscape", frames=[frame_landscape], onPage=draw_landscape_header),
        PageTemplate(id="backcover", frames=[frame_cover], onPage=draw_back_cover),
    ])

    doc.build(story)
    print(f"PDF gerado: {OUT}")
    print(f"Tamanho: {OUT.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    build_pdf()
