# -*- coding: utf-8 -*-
"""Template base reutilizável para geração de PDFs educacionais PAES MED AI.

Uso:
    from pdf_base import generate_educational_pdf, CONTENT_TEMPLATE
    content = {**CONTENT_TEMPLATE, "titulo": "...", "secoes": [...], ...}
    generate_educational_pdf(content, "QU_TEORIA_ATOMICA.pdf", [...images...])
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, HRFlowable, PageBreak
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image as PILImage

from text_utils import _normalize_text, _deep_normalize

ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
PDF_DIR = ROOT / "data" / "materiais"

PRIMARY = HexColor("#0D7C66")
PRIMARY_DARK = HexColor("#0A5D4D")
PRIMARY_LIGHT = HexColor("#E0F2F1")
TEXT_DARK = HexColor("#1A1A2E")
TEXT_LIGHT = HexColor("#666666")

_FONTS = {
    "Normal": "C:/Windows/Fonts/arial.ttf",
    "Bold": "C:/Windows/Fonts/arialbd.ttf",
    "Italic": "C:/Windows/Fonts/ariali.ttf",
    "BoldItalic": "C:/Windows/Fonts/arialbi.ttf",
}

_registered = False


def _register_fonts():
    global _registered
    if _registered:
        return True
    ok = True
    for name, path in _FONTS.items():
        if os.path.exists(path):
            try:
                pdfmetrics.registerFont(TTFont(name, path))
            except Exception:
                ok = False
        else:
            ok = False
    if ok:
        from reportlab.pdfbase.pdfmetrics import registerFontFamily
        registerFontFamily("Normal", normal="Normal", bold="Bold",
                           italic="Italic", boldItalic="BoldItalic")
    _registered = True
    return ok


def _fonts():
    ok = _register_fonts()
    if ok:
        return "Normal", "Bold", "Italic", "BoldItalic"
    return "Helvetica", "Helvetica-Bold", "Helvetica-Oblique", "Helvetica-BoldOblique"


def generate_educational_pdf(
    content: dict[str, Any],
    pdf_filename: str,
    images_data: list[dict[str, str]],
    header_subtitle: str = "",
) -> Path:
    """Gera um PDF educacional no padrão PAES MED AI.

    Args:
        content: dict com titulo, disciplina, topico, subtopico, introducao,
                 secoes (lista de dicts com titulo, conteudo, exemplo),
                 resumo, dicas (lista), pegadinhas (lista), referencias (lista).
        pdf_filename: nome do arquivo PDF (ex: "QU_TEORIA_ATOMICA.pdf").
        images_data: lista de dicts com file, caption, source, source_url.
        header_subtitle: texto do cabeçalho (ex: "Química — Teoria Atômica").

    Returns:
        Path do PDF gerado.
    """
    _FN, _FB, _FI, _FBI = _fonts()
    pdf_path = PDF_DIR / pdf_filename

    # Normaliza todo o conteudo e metadados das imagens
    content = _deep_normalize(content)
    images_data = _deep_normalize(images_data)

    # Verifica imagens
    downloaded_images = []
    for img_data in images_data:
        path = IMG_DIR / img_data["file"]
        if path.exists() and path.stat().st_size > 1000:
            downloaded_images.append({
                "path": str(path),
                "caption": img_data["caption"],
                "source": img_data["source"],
                "source_url": img_data["source_url"],
            })

    # Busca imagem de capa da Wikipedia pelo nome do PDF
    cover_image = None
    pdf_stem = Path(pdf_filename).stem
    try:
        from cover_images_all import COVER_IMAGES
        from pdf_cover_map import PDF_TO_COVER
        cover_prefix = PDF_TO_COVER.get(pdf_stem)
        if cover_prefix and cover_prefix in COVER_IMAGES:
            ci = COVER_IMAGES[cover_prefix]
            cp = IMG_DIR / ci["file"]
            if cp.exists() and cp.stat().st_size > 1000:
                cover_image = {
                    "path": str(cp),
                    "caption": ci.get("caption", ""),
                    "source": ci.get("source", "Wikipédia (Português do Brasil)"),
                    "source_url": ci.get("source_url", ""),
                }
    except Exception:
        pass

    styles = getSampleStyleSheet()
    style_title = ParagraphStyle('T', parent=styles['Title'], fontName=_FB,
        fontSize=24, textColor=PRIMARY, spaceAfter=6, alignment=TA_CENTER)
    style_sub = ParagraphStyle('S', parent=styles['Normal'], fontName=_FI,
        fontSize=12, textColor=TEXT_LIGHT, spaceAfter=20, alignment=TA_CENTER)
    style_h2 = ParagraphStyle('H', parent=styles['Heading2'], fontName=_FB,
        fontSize=15, textColor=PRIMARY_DARK, spaceBefore=18, spaceAfter=8)
    style_body = ParagraphStyle('B', parent=styles['Normal'], fontName=_FN,
        fontSize=11, textColor=TEXT_DARK, leading=16, alignment=TA_JUSTIFY, spaceAfter=8)
    style_ex = ParagraphStyle('E', parent=style_body, fontName=_FI, fontSize=10,
        textColor=PRIMARY_DARK, leftIndent=15, rightIndent=15,
        borderColor=PRIMARY, borderWidth=0.5, borderPadding=8,
        backColor=PRIMARY_LIGHT, spaceBefore=8, spaceAfter=12)
    style_cap = ParagraphStyle('C', parent=styles['Normal'], fontName=_FI,
        fontSize=9, textColor=TEXT_LIGHT, alignment=TA_CENTER, spaceAfter=4)
    style_ref = ParagraphStyle('R', parent=styles['Normal'], fontName=_FN,
        fontSize=10, textColor=TEXT_DARK, leading=14, spaceAfter=6,
        leftIndent=15, firstLineIndent=-15)

    subtitle = header_subtitle or f'{content["disciplina"]} — {content["topico"]}'

    def _header_footer(canvas_obj, doc):
        canvas_obj.saveState()
        width, height = A4
        if LOGO_PATH.exists():
            canvas_obj.drawImage(str(LOGO_PATH), 1.5*cm, height - 1.8*cm,
                width=1.2*cm, height=1.2*cm, preserveAspectRatio=True, mask='auto')
        canvas_obj.setFillColor(PRIMARY)
        canvas_obj.setFont(_FB, 9)
        canvas_obj.drawString(3*cm, height - 1.2*cm, "PAES MED AI")
        canvas_obj.setFont(_FN, 7)
        canvas_obj.setFillColor(TEXT_LIGHT)
        canvas_obj.drawString(3*cm, height - 1.6*cm, subtitle)
        canvas_obj.setStrokeColor(PRIMARY)
        canvas_obj.setLineWidth(0.5)
        canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
        canvas_obj.setFont(_FN, 7)
        canvas_obj.setFillColor(TEXT_LIGHT)
        canvas_obj.drawCentredString(width/2, 1*cm,
            f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
        canvas_obj.restoreState()

    # Se nao ha capa da Wikipedia, usa a primeira imagem como capa
    if cover_image is None and downloaded_images:
        cover_image = downloaded_images[0]
        section_images = downloaded_images[1:]
    else:
        section_images = downloaded_images

    story = []
    story.append(Spacer(1, 2.5*cm))
    story.append(Paragraph(content["titulo"], style_title))
    story.append(Paragraph(f'{content["disciplina"]} — {content["topico"]}', style_sub))
    story.append(HRFlowable(width="60%", thickness=2, color=PRIMARY, hAlign='CENTER'))
    story.append(Spacer(1, 0.5*cm))

    # Imagem de capa em destaque
    if cover_image:
        try:
            pil_img = PILImage.open(cover_image["path"])
            w, h = pil_img.size
            ratio = min(16*cm / w, 9*cm / h)
            img = Image(cover_image["path"], width=w*ratio, height=h*ratio)
            img.hAlign = 'CENTER'
            story.append(img)
            story.append(Spacer(1, 0.2*cm))
            story.append(Paragraph(
                f'<i>{cover_image["caption"]}</i><br/>'
                f'<font size="7" color="#999">Imagem: {cover_image["source"]}</font>',
                style_cap))
            story.append(Spacer(1, 0.3*cm))
        except Exception as e:
            print(f"  Erro imagem capa: {e}")

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph(content["introducao"].replace('\n\n', '<br/><br/>'), style_body))
    story.append(PageBreak())

    for img_pos, sec in enumerate(content["secoes"]):
        story.append(Paragraph(sec["titulo"], style_h2))
        story.append(Paragraph(
            sec["conteudo"].replace('\n\n', '<br/><br/>').replace('\n', '<br/>'),
            style_body))
        if sec.get("exemplo"):
            story.append(Paragraph(
                f'<b>Exemplo clínico/prático:</b><br/>{sec["exemplo"]}', style_ex))
        if img_pos < len(section_images):
            img_data = section_images[img_pos]
            try:
                pil_img = PILImage.open(img_data["path"])
                w, h = pil_img.size
                ratio = min(14*cm / w, 10*cm / h)
                img = Image(img_data["path"], width=w*ratio, height=h*ratio)
                img.hAlign = 'CENTER'
                story.append(Spacer(1, 0.3*cm))
                story.append(img)
                story.append(Paragraph(
                    f'<i>{img_data["caption"]}</i><br/>'
                    f'<font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                    style_cap))
                story.append(Spacer(1, 0.3*cm))
            except Exception as e:
                print(f"  Erro imagem: {e}")

    # Imagens extras
    used = len(content["secoes"])
    for img_data in section_images[used:]:
        try:
            pil_img = PILImage.open(img_data["path"])
            w, h = pil_img.size
            ratio = min(14*cm / w, 10*cm / h)
            img = Image(img_data["path"], width=w*ratio, height=h*ratio)
            img.hAlign = 'CENTER'
            story.append(Spacer(1, 0.3*cm))
            story.append(img)
            story.append(Paragraph(
                f'<i>{img_data["caption"]}</i><br/>'
                f'<font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                style_cap))
            story.append(Spacer(1, 0.3*cm))
        except Exception as e:
            print(f"  Erro imagem: {e}")

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Resumo", style_h2))
    story.append(Paragraph(content["resumo"].replace('\n', '<br/>'), style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Dicas para a Prova", style_h2))
    for dica in content["dicas"]:
        story.append(Paragraph(f'- {dica}', style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Pegadinhas Comuns", style_h2))
    for peg in content["pegadinhas"]:
        story.append(Paragraph(f'(!) {peg}', style_body))

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Referências", style_h2))
    for ref in content["referencias"]:
        story.append(Paragraph(ref, style_ref))

    doc = SimpleDocTemplate(str(pdf_path), pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm, topMargin=2.5*cm, bottomMargin=2*cm,
        title=f'PAES MED AI — {content["titulo"]}', author='PAES MED AI')
    doc.build(story, onFirstPage=_header_footer, onLaterPages=_header_footer)

    size_kb = pdf_path.stat().st_size / 1024
    print(f"  PDF gerado: {pdf_path} ({size_kb:.1f} KB)")
    return pdf_path
