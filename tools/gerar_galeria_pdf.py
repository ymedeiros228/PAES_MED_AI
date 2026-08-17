"""
Gera um PDF separado com a galeria de telas do PAES MED AI.
Paisagem total (A4 landscape), uma imagem por pagina, imagens nitidas.
"""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage, Frame, PageTemplate, PageBreak
)
from reportlab.pdfgen import canvas
from PIL import Image as PILImage

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "docs" / "screenshots" / "user"
OUT = ROOT / "docs" / "PAES_MED_AI_Galeria_Telas.pdf"

# Paleta do app
C_NAVY = colors.HexColor("#0A1628")
C_TEAL = colors.HexColor("#1FA887")
C_TEAL_DEEP = colors.HexColor("#0C7A63")
C_MINT = colors.HexColor("#E6F6F1")
C_WHITE = colors.white
C_MUTED = colors.HexColor("#5A6B6E")

# A4 paisagem: (297, 210)
PAGE_W, PAGE_H = A4[1], A4[0]
MARGIN = 15 * mm
CONTENT_W = PAGE_W - 2 * MARGIN
CONTENT_H = PAGE_H - 2 * MARGIN


def draw_landscape_cover(c, doc):
    """Capa do PDF de galeria em paisagem."""
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    # Faixas
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 6 * mm, PAGE_W, 6 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 6 * mm, fill=1, stroke=0)

    # Titulo
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 36)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 90 * mm, "PAES MED AI")
    c.setFillColor(C_TEAL)
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 115 * mm, "GALERIA DE TELAS")
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 12)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 135 * mm, "Documentação Técnica Completa")

    # Info
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 10)
    c.drawCentredString(PAGE_W / 2, 45 * mm, "Yuri Medeiros Bandeira · Cliente: Jonas Almeida Medeiros")
    c.drawCentredString(PAGE_W / 2, 35 * mm, "v1.0.0.26 · 16 de agosto de 2026")

    # Copyright
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica-Oblique", 8)
    c.drawCentredString(PAGE_W / 2, 15 * mm, "© 2026 PAES MED AI — Todos os direitos reservados")

    c.restoreState()


def draw_landscape_page(c, doc):
    """Cabeçalho e rodape para paginas paisagem da galeria."""
    c.saveState()

    c.setStrokeColor(C_TEAL)
    c.setLineWidth(1)
    c.line(MARGIN, PAGE_H - 12 * mm, PAGE_W - MARGIN, PAGE_H - 12 * mm)

    c.setFillColor(C_TEAL_DEEP)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(MARGIN, PAGE_H - 9 * mm, "PAES MED AI — Galeria de Telas")
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 9 * mm, f"Página {doc.page}")

    c.setStrokeColor(C_TEAL_DEEP)
    c.setLineWidth(0.6)
    c.line(MARGIN, 12 * mm, PAGE_W - MARGIN, 12 * mm)
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 7)
    c.drawCentredString(PAGE_W / 2, 8 * mm, "v1.0.0.26 · Documentação Técnica Completa")

    c.restoreState()


def build_gallery_pdf():
    story = []

    # Capa
    story.append(Spacer(1, 1))
    story.append(PageBreak())

    images = [
        ("dashboard.png", "Dashboard principal com atalhos e tópico do dia"),
        ("sessao.png", "Sessão guiada: meta do dia e botão de estudo"),
        ("questao.png", "Tela de questão com enunciado e alternativas"),
        ("progresso-analise.png", "Progresso — análise 0-10 por disciplina"),
        ("progresso-radar.png", "Progresso — constelação de habilidades"),
        ("progresso-evolucao.png", "Progresso — evolução temporal"),
        ("biblioteca-aulas.png", "Biblioteca de aulas organizadas por disciplina"),
        ("biblioteca-materiais.png", "Estante de materiais em PDF por matéria"),
        ("material-botanica.png", "Leitor PDF integrado — material de Botânica"),
        ("ajustes-escuro.png", "Ajustes — tema escuro"),
        ("ajustes-claro.png", "Ajustes — tema claro"),
    ]

    for filename, caption in images:
        path = SHOTS / filename
        if not path.exists():
            continue

        # Calcula tamanho ideal mantendo nitidez
        img = PILImage.open(str(path))
        img_w, img_h = img.size

        # Area util: 267x180mm. Imagem e widescreen.
        # Queremos aproveitar ao maximo a pagina paisagem.
        avail_w = CONTENT_W      # 267 mm
        avail_h = CONTENT_H - 25 * mm  # 155 mm, deixa espaco para legenda

        ratio = img_h / img_w
        h = avail_w * ratio
        if h > avail_h:
            h = avail_h
            w = h / ratio
        else:
            w = avail_w

        # Centraliza
        story.append(Spacer(1, 8 * mm))
        story.append(RLImage(str(path), width=w, height=h))
        story.append(Spacer(1, 6 * mm))
        story.append(Paragraph(
            f"<font color='#0C7A63'><b>{caption}</b></font>",
            ParagraphStyle(
                name="Legend",
                fontName="Helvetica",
                fontSize=10,
                leading=12,
                textColor=colors.HexColor("#0E1726"),
                alignment=1,
            )
        ))
        story.append(PageBreak())

    # Contra-capa paisagem
    story.append(Spacer(1, 1))

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=(PAGE_W, PAGE_H),
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=MARGIN,
        title="PAES MED AI — Galeria de Telas",
        author="Yuri Medeiros Bandeira",
    )

    frame_full = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
    frame_gallery = Frame(MARGIN, MARGIN, CONTENT_W, CONTENT_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)

    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame_full], onPage=draw_landscape_cover),
        PageTemplate(id="gallery", frames=[frame_gallery], onPage=draw_landscape_page),
    ])

    doc.build(story)
    print(f"PDF da galeria gerado: {OUT}")
    print(f"Tamanho: {OUT.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    build_gallery_pdf()
