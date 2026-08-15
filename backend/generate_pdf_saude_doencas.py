# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Saúde e Doenças.

Texto 100% PT-BR (Português Brasileiro) com acentuação correta.
Imagens de sites educacionais brasileiros.
Referências em formato ABNT.
"""

import os
from pathlib import Path

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

ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
PDF_DIR = ROOT / "data" / "materiais"

PRIMARY = HexColor("#0D7C66")
PRIMARY_DARK = HexColor("#0A5D4D")
PRIMARY_LIGHT = HexColor("#E0F2F1")
TEXT_DARK = HexColor("#1A1A2E")
TEXT_LIGHT = HexColor("#666666")


def _register_fonts():
    font_paths = {
        "Normal": "C:/Windows/Fonts/arial.ttf",
        "Bold": "C:/Windows/Fonts/arialbd.ttf",
        "Italic": "C:/Windows/Fonts/ariali.ttf",
        "BoldItalic": "C:/Windows/Fonts/arialbi.ttf",
    }
    registered = {}
    for name, path in font_paths.items():
        if os.path.exists(path):
            try:
                pdfmetrics.registerFont(TTFont(name, path))
                registered[name] = True
            except Exception:
                registered[name] = False
        else:
            registered[name] = False
    if all(registered.values()):
        from reportlab.pdfbase.pdfmetrics import registerFontFamily
        registerFontFamily("Normal", normal="Normal", bold="Bold",
                           italic="Italic", boldItalic="BoldItalic")
        return True
    return False


_HAS_TTF = _register_fonts()
_FN = "Normal" if _HAS_TTF else "Helvetica"
_FB = "Bold" if _HAS_TTF else "Helvetica-Bold"
_FI = "Italic" if _HAS_TTF else "Helvetica-Oblique"
_FBI = "BoldItalic" if _HAS_TTF else "Helvetica-BoldOblique"


CONTENT = {
    "titulo": "Saúde e Doenças",
    "disciplina": "Biologia",
    "topico": "Saúde e Doenças",
    "subtopico": "Imunidade, Doenças Infecciosas, Prevenção e Saúde Pública",
    "introducao": (
        "A saúde é um estado de completo bem-estar físico, mental e "
        "social, e não apenas a ausência de doenças. As doenças podem "
        "ser causadas por agentes infecciosos (vírus, bactérias, "
        "fungos, protozoários), fatores genéticos, ambientais, "
        "hábitos de vida e disfunções do sistema imunológico.\n\n"
        "A imunologia estuda o sistema de defesa do organismo. "
        "Compreender a imunidade, as formas de transmissão de "
        "doenças e as estratégias de prevenção é fundamental para "
        "a Medicina e para a saúde coletiva."
    ),
    "secoes": [
        {
            "titulo": "1. O Sistema Imunológico",
            "conteudo": (
                "O sistema imunológico protege o organismo contra "
                "agentes externos (patógenos) e células anormais "
                "(tumores). É formado por órgãos, células e moléculas.\n\n"
                "ÓRGÃOS LINFÓIDES:\n"
                "- Primários: medula óssea e timo (produção e maturação "
                "de linfócitos).\n"
                "- Secundários: linfonodos, baço, amígdalas, placas "
                "de Peyer, tecido linfoide associado a mucosas (MALT).\n\n"
                "CÉLULAS DE DEFESA:\n"
                "- Fagócitos: neutrófilos, macrófagos, células "
                "dendríticas. Fagocitam e destroem patógenos.\n"
                "- Linfócitos: células B (produzem anticorpos) e "
                "células T (T auxiliador, T citotóxico, T regulador).\n"
                "- Células NK (natural killer): destroem células "
                "infectadas e tumorais.\n"
                "- Mastócitos e basófilos: liberam histamina em "
                "respostas alérgicas.\n\n"
                "MOLECULAS DE DEFESA:\n"
                "- Anticorpos (imunoglobulinas): IgG, IgA, IgM, IgE, "
                "IgD. Ligam-se a antígenos e marcam patógenos para "
                "destruição.\n"
                "- Complemento: sistema de proteínas que auxilia a "
                "fagocitose e lise.\n"
                "- Citocinas: moléculas de sinalização que coordenam "
                "a resposta imune."
            ),
            "exemplo": (
                "A destruição de células tumorais pelo sistema imune é "
                "a base da imunoterapia. Os checkpoints imunológicos "
                "(como PD-1 e CTLA-4) freiam a resposta imune para "
                "evitar autoimunidade. Alguns tumores exploram esses "
                "mecanismos para escapar. Os inibidores de "
                "checkpoint (pembrolizumabe, nivolumabe) bloqueiam "
                "esses mecanismos e reativam as células T contra o "
                "câncer. Essa revolução transformou o tratamento de "
                "melanomas e cânceres de pulmão e rim."
            ),
        },
        {
            "titulo": "2. Imunidade Inata e Adaptativa",
            "conteudo": (
                "IMUNIDADE INATA: resposta rápida, não específica e "
                "sem memória. Barreiras físicas (pele, mucosas, "
                "cílios), químicas (lágrimas, ácido gástrico, lisozima, "
                "complemento), celulares (fagócitos, NK) e inflamação. "
                "Reconhece padrões conservados de patógenos (PAMPs) "
                "por receptores Toll-like.\n\n"
                "IMUNIDADE ADAPTATIVA: resposta específica, com "
                "memória. Divide-se em humoral (células B e "
                "anticorpos) e celular (células T). Demora dias para "
                "ser ativada na primeira exposição, mas na segunda "
                "é mais rápida e potente (memória imunológica).\n\n"
                "RESPOSTA PRIMÁRIA E SECUNDÁRIA:\n"
                "- Primária: lenta, baixa produção de anticorpos, "
                "predominância de IgM.\n"
                "- Secundária: rápida, alta produção de anticorpos, "
                "predominância de IgG, memória. É o princípio das "
                "vacinas.\n\n"
                "VACINAS: preparações biológicas que estimulam a "
                "imunidade adaptativa sem causar doença. Tipos: "
                "atenuadas (vírus vivos enfraquecidos), inativadas, "
                "subunidades, toxoides, mRNA, vetoriais (adenovírus). "
                "Vacinas de mRNA (COVID-19) ensinam as células a "
                "produzir uma proteína do patógeno."
            ),
            "exemplo": (
                "A vacina de mRNA contra COVID-19 é um marco "
                "tecnológico. O mRNA carrega instruções para produzir "
                "a proteína spike do SARS-CoV-2. As células do "
                "vacinado produzem temporariamente a proteína, o "
                "sistema imune a reconhece e gera anticorpos e "
                "células de memória. Se houver exposição posterior ao "
                "vírus, a resposta secundária neutraliza-o antes que "
                "cause doença grave. Essa plataforma promete vacinas "
                "contra câncer e outras doenças."
            ),
        },
        {
            "titulo": "3. Doenças Infecciosas",
            "conteudo": (
                "As doenças infecciosas são causadas por agentes "
                "patogênicos e se transmitem de diferentes formas.\n\n"
                "AGENTES CAUSADORES:\n"
                "- Vírus: COVID-19, gripe, dengue, zika, chikungunya, "
                "HIV, hepatites, sarampo, caxumba, rubéola, poliomielite.\n"
                "- Bactérias: tuberculose, leptospirose, cólera, "
                "meningite, salmonelose, hanseníase, sífilis, gonorreia, "
                "infecção por H. pylori.\n"
                "- Fungos: candidíase, aspergilose, "
                "paracoccidioidomicose, dermatofitoses.\n"
                "- Protozoários: malária, doença de Chagas, "
                "leishmaniose, amebíase, giardíase, toxoplasmose.\n"
                "- Vermes (helmintos): esquistossomose, filariose, "
                "ascaridíase, oxiuríase, teníase.\n\n"
                "VIAS DE TRANSMISSÃO:\n"
                "- Ar (gripe, COVID-19, tuberculose);\n"
                "- Fecal-oral (hepatite A, cólera, giardíase, amebíase);\n"
                "- Sanguínea/sexual (HIV, hepatite B, sífilis);\n"
                "- Vetores (malária, dengue, Chagas, leishmaniose);\n"
                "- Contato direto (leptospirose, micoses, herpes);\n"
                "- Vertical (transplacental — toxoplasmose, sífilis, Zika).\n\n"
                "PREVENÇÃO: saneamento, água potável, lavagem das mãos, "
                "vacinas, controle de vetores, uso de preservativos, "
                "boas práticas de higiene, queima de cadáveres e "
                "resíduos, isolamento de doentes em casos graves."
            ),
            "exemplo": (
                "A transmissão fecal-oral é responsável por cerca de "
                "80% das doenças diarreicas no mundo. A cólera, por "
                "exemplo, é transmitida por água e alimentos "
                "contaminados com Vibrio cholerae. Em situações de "
                "falta de saneamento, a doença pode causar epidemias "
                "mortais (caso do Haiti após o terremoto de 2010). "
                "O tratamento é simples — hidratação oral —, mas a "
                "prevenção requer saneamento e água potável."
            ),
        },
        {
            "titulo": "4. Epidemiologia e Saúde Pública",
            "conteudo": (
                "A Epidemiologia estuda a distribuição e os "
                "determinantes de doenças em populações. Conceitos "
                "fundamentais:\n\n"
                "- ENDEMIA: doença presente de forma constante em uma "
                "região (dengue no Brasil).\n"
                "- EPIDEMIA: aumento súbito de casos em uma região.\n"
                "- PANDEMIA: epidemia que se espalha por vários "
                "países ou continentes (COVID-19, gripe espanhola).\n"
                "- SURTO: ocorrência localizada de casos.\n\n"
                "INDICADORES:\n"
                "- Incidência: novos casos em um período.\n"
                "- Prevalência: total de casos (novos + antigos).\n"
                "- Letalidade: porcentagem de óbitos entre os doentes.\n"
                "- Mortalidade: óbitos por população.\n\n"
                "CADEIA DE TRANSMISSÃO: agente → fonte (reservatório) "
                "→ meio de transmissão → portal de entrada → "
                "hospedeiro suscetível. O controle pode atuar em cada "
                "elo: eliminar o agente, tratar a fonte, bloquear a "
                "transmissão, fortalecer o hospedeiro.\n\n"
                "SAÚDE PÚBLICA: conjunto de ações do Estado para "
                "promover a saúde da população. Programas de vacinação, "
                "controle de endemias, saneamento básico, vigilância "
                "sanitária, promoção da alimentação saudável e "
                "prevenção de doenças crônicas."
            ),
            "exemplo": (
                "A erradicação da varíola é um dos maiores triunfos da "
                "saúde pública. Por meio de vacinação em massa e "
                "vigilância epidemiológica, a doença foi eliminada "
                "naturalmente em 1980. Campanhas de vacinação no "
                "Brasil erradicaram também a poliomielite e "
                "controlaram o sarampo, a rubéola, a difteria e o "
                "tétano neonatal. A vacinação é considerada a "
                "intervenção de saúde pública mais custo-efetiva "
                "já criada."
            ),
        },
        {
            "titulo": "5. Doenças Crônicas e Estilo de Vida",
            "conteudo": (
                "Além das infecciosas, as doenças crônicas não "
                "transmissíveis (DCNTs) são a principal causa de morte "
                "no mundo. Estão associadas a fatores genéticos, "
                "ambientais e, principalmente, hábitos de vida.\n\n"
                "PRINCIPAIS DCNTs:\n"
                "- Doenças cardiovasculares (hipertensão, infarto, AVC);\n"
                "- Diabetes mellitus tipo 2;\n"
                "- Cânceres;\n"
                "- Doenças respiratórias crônicas (DPOC, asma);\n"
                "- Doenças neurodegenerativas (Alzheimer, Parkinson).\n\n"
                "FATORES DE RISCO MODIFICÁVEIS:\n"
                "- Tabagismo;\n"
                "- Consumo excessivo de álcool;\n"
                "- Alimentação desequilibrada;\n"
                "- Sedentarismo;\n"
                "- Obesidade;\n"
                "- Estresse crônico.\n\n"
                "PREVENÇÃO: alimentação rica em frutas, vegetais e "
                "grãos integrais; prática regular de atividade física; "
                "não fumar; consumo moderado de álcool; controle do "
                "peso; sono adequado; vacinação; consultas "
                "periódicas (prevenção primária, secundária, terciária "
                "e quaternária).\n\n"
                "EMERGÊNCIAS SANITÁRIAS: zoonoses, resistência a "
                "antimicrobianos, mudanças climáticas, desastres "
                "naturais e bioterrorismo desafiam a saúde global. A "
                "One Health (Saúde Única) integra saúde humana, "
                "animal e ambiental para prevenir epidemias."
            ),
            "exemplo": (
                "A resistência a antimicrobianos é uma crise silenciosa. "
                "Bactérias como Klebsiella pneumoniae e "
                "Mycobacterium tuberculosis desenvolvem resistência a "
                "múltiplos antibióticos. Sem ação coordenada, até 2050 "
                "as infecções resistentes podem causar 10 milhões de "
                "mortes anuais. A prevenção inclui: prescrição "
                "responsável, higiene hospitalar, controle de "
                "antimicrobianos em animais de criação e pesquisa "
                "para novos fármacos."
            ),
        },
    ],
    "resumo": (
        "- Sistema imunológico: inato (rápido, não específico) e adaptativo (específico, com memória).\n"
        "- Células: fagócitos, linfócitos B e T, células NK. Moléculas: anticorpos, complemento, citocinas.\n"
        "- Vacinas estimulam resposta primária e geram memória para resposta secundária.\n"
        "- Doenças infecciosas: vírus, bactérias, fungos, protozoários, vermes. Transmissão: ar, água, vetor, contato, sexual.\n"
        "- Epidemiologia: endemia, epidemia, pandemia. Cadeia de transmissão: agente, fonte, meio, portal, hospedeiro.\n"
        "- DCNTs: doenças crônicas ligadas a hábitos de vida. Prevenção: dieta, exercício, não fumar, vacinas."
    ),
    "dicas": [
        "Imunidade inata = sem memória. Adaptativa = com memória (vacinas).",
        "IgM aparece primeiro na resposta primária. IgG domina na secundária.",
        "Células B produzem anticorpos. Células T citotóxicas matam células infectadas.",
        "Vacinas de mRNA (COVID-19) não alteram o DNA humano.",
        "Água, saneamento e vacinação são as maiores conquistas da saúde pública.",
        "DCNTs: cardiovasculares, câncer, diabetes, DPOC. Causas: tabagismo, sedentarismo, obesidade, álcool.",
    ],
    "pegadinhas": [
        "Achar que imunidade adaptativa age imediatamente: demora dias na primeira exposição. A inata é rápida.",
        "Confundir endemia com epidemia: endemia = constante na região; epidemia = aumento súbito.",
        "Achar que vacinas causam a doença: vacinas modernas não causam doença, estimulam imunidade.",
        "Esquecer que vírus NÃO respondem a antibióticos — antibióticos são para bactérias.",
        "Confundir transmissão fecal-oral com sanguínea: hepatite A é fecal-oral; B e C são sanguíneas/sexuais.",
        "Achar que doenças crônicas não são preveníveis: até 80% das DCNTs são evitáveis com hábitos saudáveis.",
    ],
    "referencias": [
        "ABBAS, A. K.; LICHTMAN, A. H.; PILLAI, S. Imunologia Celular e Molecular. 9. ed. Rio de Janeiro: Elsevier, 2019.",
        "JANWAY, C. A. et al. Imunobiologia. 8. ed. Porto Alegre: Artmed, 2014.",
        "ROUBAUX, M. O. Epidemiologia Aplicada à Saúde Pública. 2. ed. São Paulo: Manole, 2011.",
        "PORTA, M. Dicionário de Epidemiologia. 5. ed. São Paulo: Artmed, 2008.",
        "WHO. Global Action Plan on Antimicrobial Resistance. Geneva: World Health Organization, 2015.",
        "BRASIL. Ministério da Saúde. Guia de Vigilância Epidemiológica. 7. ed. Brasília: Ministério da Saúde, 2009.",
    ],
}


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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Saúde e Doenças")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_SAUDE_DOENCAS.pdf"

    images_data = [
        {"file": "br_sau_orgaos.jpg",
         "caption": "Sistema imunológico: órgãos linfoides e linfócitos",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/sistema-imunologico/"},
        {"file": "br_sau_anticorpo.jpg",
         "caption": "Anticorpo: molécula de defesa produzida pelas células B",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/imunidade.htm"},
        {"file": "br_sau_resposta.jpg",
         "caption": "Resposta imunológica primária e secundária: memória imunológica",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/sistema-imunologico/"},
        {"file": "br_sau_sistema2.jpg",
         "caption": "Sistema imunológico: barreiras, inata e adaptativa",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/sistema-imunologico/"},
        {"file": "br_sau_tabela.jpg",
         "caption": "Tabela comparativa: imunidade inata, passiva, ativa e artificial",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/sistema-imunologico/"},
    ]

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
            print(f"  OK: {img_data['file']}")
        else:
            print(f"  FALTANDO: {img_data['file']}")

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

    story = []
    story.append(Spacer(1, 3*cm))
    if LOGO_PATH.exists():
        img = Image(str(LOGO_PATH), width=3*cm, height=3*cm)
        img.hAlign = 'CENTER'
        story.append(img)
    story.append(Spacer(1, 1*cm))
    story.append(Paragraph(CONTENT["titulo"], style_title))
    story.append(Paragraph(f'{CONTENT["disciplina"]} — {CONTENT["topico"]}', style_sub))
    story.append(HRFlowable(width="60%", thickness=2, color=PRIMARY, hAlign='CENTER'))
    story.append(Spacer(1, 0.8*cm))
    story.append(Paragraph(CONTENT["introducao"].replace('\n\n', '<br/><br/>'), style_body))
    story.append(PageBreak())

    for img_pos, sec in enumerate(CONTENT["secoes"]):
        story.append(Paragraph(sec["titulo"], style_h2))
        story.append(Paragraph(sec["conteudo"].replace('\n\n', '<br/><br/>').replace('\n', '<br/>'), style_body))
        if sec.get("exemplo"):
            story.append(Paragraph(f'<b>Exemplo clínico/prático:</b><br/>{sec["exemplo"]}', style_ex))
        if img_pos < len(downloaded_images):
            img_data = downloaded_images[img_pos]
            try:
                pil_img = PILImage.open(img_data["path"])
                w, h = pil_img.size
                ratio = min(14*cm / w, 10*cm / h)
                img = Image(img_data["path"], width=w*ratio, height=h*ratio)
                img.hAlign = 'CENTER'
                story.append(Spacer(1, 0.3*cm))
                story.append(img)
                story.append(Paragraph(
                    f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                    style_cap))
                story.append(Spacer(1, 0.3*cm))
            except Exception as e:
                print(f"  Erro imagem: {e}")

    used = len(CONTENT["secoes"])
    for img_data in downloaded_images[used:]:
        try:
            pil_img = PILImage.open(img_data["path"])
            w, h = pil_img.size
            ratio = min(14*cm / w, 10*cm / h)
            img = Image(img_data["path"], width=w*ratio, height=h*ratio)
            img.hAlign = 'CENTER'
            story.append(Spacer(1, 0.3*cm))
            story.append(img)
            story.append(Paragraph(
                f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                style_cap))
            story.append(Spacer(1, 0.3*cm))
        except Exception as e:
            print(f"  Erro imagem: {e}")

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Resumo", style_h2))
    story.append(Paragraph(CONTENT["resumo"].replace('\n', '<br/>'), style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Dicas para a Prova", style_h2))
    for dica in CONTENT["dicas"]:
        story.append(Paragraph(f'• {dica}', style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Pegadinhas Comuns", style_h2))
    for peg in CONTENT["pegadinhas"]:
        story.append(Paragraph(f'⚠ {peg}', style_body))

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Referências", style_h2))
    for ref in CONTENT["referencias"]:
        story.append(Paragraph(ref, style_ref))

    doc = SimpleDocTemplate(str(pdf_path), pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm, topMargin=2.5*cm, bottomMargin=2*cm,
        title=f'PAES MED AI — {CONTENT["titulo"]}', author='PAES MED AI')
    doc.build(story, onFirstPage=_header_footer, onLaterPages=_header_footer)

    size_kb = pdf_path.stat().st_size / 1024
    print(f"\nPDF gerado: {pdf_path}")
    print(f"Tamanho: {size_kb:.1f} KB")
    return pdf_path


if __name__ == "__main__":
    generate_pdf()
