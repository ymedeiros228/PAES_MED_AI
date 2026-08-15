# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Botânica.

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
    "titulo": "Botânica",
    "disciplina": "Biologia",
    "topico": "Botânica",
    "subtopico": "Briófitas, Pteridófitas, Gimnospermas, Angiospermas e Tecidos Vegetais",
    "introducao": (
        "A Botânica estuda as plantas. As plantas são organismos "
        "eucariontes, multicelulares, autotróficos fotossintetizantes, "
        "com parede celular de celulose. São essenciais para a vida "
        "na Terra: produzem oxigênio, servem de alimento, abrigo e "
        "matéria-prima, regulam o clima e ciclos de nutrientes.\n\n"
        "As plantas terrestres evoluíram há cerca de 500 milhões de "
        "anos. A transição para o ambiente terrestre exigiu adaptações: "
        "parede celular, corteja, vasos condutores, raízes, folhas, "
        "estômatos, sementes, flores e frutos. A reprodução evoluiu "
        "do gametófito dominante (briófitas) para o esporófito "
        "dominante com sementes e flores (angiospermas)."
    ),
    "secoes": [
        {
            "titulo": "1. Briófitas",
            "conteudo": (
                "As briófitas são plantas pequenas, não vasculares, que "
                "vivem em ambientes úmidos. Incluem musgos, antóceros e "
                "hepáticas. Não têm vasos condutores (xilema e floema), "
                "por isso dependem da difusão e do tamanho reduzido.\n\n"
                "CARACTERÍSTICAS:\n"
                "- Gametófito dominante (fase mais visível);\n"
                "- Esporófito dependente do gametófito (fixado nele);\n"
                "- Reprodução dependente de água (espermatozoides "
                "flagelados);\n"
                "- Sem raízes verdadeiras (rizoides);\n"
                "- Sem folhas com vasos;\n"
                "- Sem sementes, flores e frutos.\n\n"
                "CICLO DE VIDA: alternância de gerações heteromórfica, "
                "com gametófito haploide (n) e esporófito diploide (2n). "
                "O esporófito produz esporos por meiose. Os esporos "
                "germinam formando o gametófito. Nos gametângios "
                "(arquegônio e anterídio), formam-se gametas. A "
                "fecundação requer água para o espermatozoide nadar até "
                "o arquegônio. O zigoto desenvolve o esporófito, que "
                "permanece dependente.\n\n"
                "IMPORTÂNCIA: cobertura do solo, retenção de água, "
                "formaçãã de turfeiras (carvão vegetal), indicadores de "
                "umidade e qualidade do ar, substrato para outras plantas."
            ),
            "exemplo": (
                "Musgos são excelentes bioindicadores de poluição do ar. "
                "Eles absorvem água e nutrientes por toda a superfície, "
                "sem raízes com seletividade, o que os torna sensíveis a "
                "metais pesados e dióxido de enxofre. Em cidades com ar "
                "poluído, os musgos desaparecem. Em áreas limpas, formam "
                "tapetes verdes. Por isso, a presença de musgos em um "
                "ambiente urbano indica boa qualidade do ar."
            ),
        },
        {
            "titulo": "2. Pteridófitas",
            "conteudo": (
                "As pteridófitas são plantas vasculares (têm xilema e "
                "floema), mas não produzem sementes. Reproduzem-se por "
                "esporos. Incluem samambaias, cavalinhas, avencas, "
                "licopódios e selaginelas.\n\n"
                "CARACTERÍSTICAS:\n"
                "- Esporófito dominante (fase mais visível);\n"
                "- Têm vasos condutores, permitindo maior porte;\n"
                "- Reprodução ainda depende de água (espermatozoides "
                "flagelados);\n"
                "- Raízes verdadeiras, caules e folhas (frondes);\n"
                "- Esporos formados em soros na face inferior das frondes;\n"
                "- Sem flores, frutos e sementes.\n\n"
                "CICLO DE VIDA: o esporófito (2n) produz esporos por "
                "meiose nos soros. O esporo germina formando um "
                "protalo (gametófito pequeno e independente). No protalo, "
                "formam-se anterídios e arquegônios. A fecundação exige "
                "água. O zigoto desenvolve um novo esporófito.\n\n"
                "IMPORTÂNCIA: ornamentais, alimentação (cavalinha em "
                "sopas e saladas), indústria (fibras, taninos), "
                "fósseis (carvão mineral vem principalmente de "
                "pteridófitas gigantes do Carbonífero, como lepidodendros)."
            ),
            "exemplo": (
                "As pteridófitas do Carbonífero, como Lepidodendron e "
                "Sigillaria, chegavam a 40 metros de altura e formaram "
                "extensos pântanos há 350 milhões de anos. Ao morrerem, "
                "seu material orgânico foi parcialmente decomposto e "
                "transformado em turfa, que, por pressão e calor, virou "
                "carvão mineral. É por isso que o carvão é considerado "
                "um combustível fóssil não-renovável e sua queima "
                "libera CO2 acumulado há milhões de anos."
            ),
        },
        {
            "titulo": "3. Gimnospermas",
            "conteudo": (
                "As gimnospermas são plantas vasculares com sementes, "
                "mas sem flores e frutos. As sementes ficam 'nuas', sem "
                "cobertura de fruto (ginno = nu, sperma = semente). "
                "Incluem coníferas, cicas, ginkgo e gnetófitas.\n\n"
                "CARACTERÍSTICAS:\n"
                "- Sementes nuas, em cones ou estrobilos;\n"
                "- Não têm flores nem frutos;\n"
                "- Geralmente perenes e lenhosas;\n"
                "- Folhas geralmente aciculares (agulhas) ou em leque;\n"
                "- Gametófito muito reduzido, dependente do esporófito;\n"
                "- Polinização por vento (anemofilia);\n"
                "- Reprodução não depende mais de água (espermas não "
                "flagelados na maioria, exceto cicas e ginkgo).\n\n"
                "EXEMPLOS: pinheiros (Pinus), ciprestes, araucárias "
                "(Araucaria angustifolia — pinheiro-do-paraná), cicas "
                "(Cycas), ginkgo (Ginkgo biloba, fóssil vivo), gnetos "
                "(Gnetum, Ephedra, Welwitschia).\n\n"
                "IMPORTÂNCIA: madeira, resinas (breu, terebintina), "
                "papel, alimentos (sementes de pinhão, castanhas), "
                "óleos essenciais, ornamentação, combate à desertificação."
            ),
            "exemplo": (
                "O pinheiro-do-paraná (Araucaria angustifolia) é uma "
                "gimnosperma nativa do sul do Brasil, símbolo do Paraná. "
                "Produz o pinhão, semente comestível rica em amido e "
                "proteína. A espécie está ameaçada de extinção devido ao "
                "desmatamento e à extração desordenada. Sua conservação "
                "é importante não só ecológica, mas também cultural e "
                "econômica, pois o pinhão é parte da gastronomia e "
                "tradição de comunidades do sul do Brasil."
            ),
        },
        {
            "titulo": "4. Angiospermas",
            "conteudo": (
                "As angiospermas (floríferas) são as plantas mais "
                "diversas e abundantes do planeta. Têm flores, frutos e "
                "sementes protegidas pelo fruto. Apareceram há cerca de "
                "140 milhões de anos e dominaram a Terra desde o Cretáceo.\n\n"
                "CARACTERÍSTICAS:\n"
                "- Flores: estruturas reprodutivas que atraem polinizadores;\n"
                "- Frutos: protegem as sementes e auxiliam na dispersão;\n"
                "- Sementes com endosperma (nutrientes);\n"
                "- Vaso condutores bem desenvolvidos;\n"
                "- Gametófito extremamente reduzido;\n"
                "- Polinização por vento, água, animais (zoofilia), "
                "insetos (entomofilia), pássaros (ornitofilia), morcegos.\n\n"
                "FLOR: estruturas em verticilos — cálice (sépalas), "
                "corola (pétalas), androceu (estames com anteras), "
                "gineceu (carpelos com ovário, estilete e estigma).\n\n"
                "FRUTO: desenvolve-se do ovário após a fecundação. "
                "Classifica-se em secos (aveia, feijão) e carnosos "
                "(maçã, laranja, uva). Carnosos: drupas (pêssego, "
                "amêndoa com caroço), bagas (uva, tomate), hesperídios "
                "(laranja, limão — casca com óleos), pômos (maçã, pera).\n\n"
                "CLASSIFICAÇÃO POR COTILEDONES:\n"
                "- Monocotiledôneas: 1 cotilédone. Folhas com nervura "
                "paralela, raiz fasciculada, flores com partes em múltiplos "
                "de 3. Exemplos: gramas, milho, arroz, trigo, bananeira, "
                "orquídeas, palmeiras.\n"
                "- Dicotiledôneas: 2 cotilédones. Folhas com nervura "
                "reticulada, raiz pivotante, flores com partes em múltiplos "
                "de 4 ou 5. Exemplos: feijão, soja, girassol, eucalipto, "
                "mangueira, roseira, carvalho.\n\n"
                "REPRODUÇÃO SEXUADA: pólen grão microgametófito, ovos "
                "no ovário. Após a fecundação, forma-se o zigoto "
                "(embrião) e o endosperma (2n+1n = triplo, na maioria). "
                "Dá-se o nome de dupla fecundação: um núcleo espermático "
                "fecunda o óvulo (formando o embrião 2n) e outro fecunda "
                "o núcleo secundário (formando o endosperma 3n)."
            ),
            "exemplo": (
                "A banana é uma monocotiledônea, mas as sementes que "
                "conhecemos em bananas cultivadas são quase inexistentes "
                "porque a variedade Cavendish é estéril (triploide). Ela "
                "se propaga assexuadamente por brotos laterais (filhos "
                "de coqueiro). Isso torna a bananeira muito vulnerável a "
                "doenças, como o Mal de Panama (Foc TR4), um fungo do "
                "solo que já destruiu a variedade Gros Michel e agora "
                "ameaça a Cavendish. A reprodução clonal reduz a "
                "diversidade genética, dificultando a resistência."
            ),
        },
        {
            "titulo": "5. Tecidos Vegetais",
            "conteudo": (
                "Os tecidos vegetais são conjuntos de células que "
                "exercem funções semelhantes. Dividem-se em meristemáticos "
                "(células em divisão) e adultos/permanentes.\n\n"
                "TECIDOS MERISTEMÁTICOS:\n"
                "- Apical: pontas de raiz e caule; crescimento em "
                "comprimento (primário).\n"
                "- Lateral (câmbio e felogênio): crescimento em espessura "
                "(secundário); formam a madeira e o suber.\n"
                "- Intercalares: entre tecidos adultos; permitem crescimento "
                "de nós internos (gramíneas).\n\n"
                "TECIDOS ADULTOS:\n"
                "- Tecidos de revestimento: epiderme (proteção, estômatos, "
                "tricomas) e periderme (casca, suber).\n"
                "- Tecidos de sustentação: colenquima (células vivas, "
                "paredes irregulares, flexibilidade) e esclerênquima "
                "(células mortas, parede lignificada, rigidez — fibras e "
                "esclereides).\n"
                "- Tecidos de condução: xilema (água e sais minerais — "
                "vasos e traqueídes) e floema (seiva elaborada — "
                "tubos crivados e células companheiras).\n"
                "- Tecidos fundamentais (paranquima): preenchimento, "
                "fotossíntese, armazenamento. Incluem colênquima e "
                "esclerênquima em algumas classificações.\n\n"
                "ÓRGÃOS VEGETAIS: raiz (absorção e fixação), caule "
                "(sustentação e condução), folha (fotossíntese). Cada "
                "órgão tem tecidos especializados.\n\n"
                "RAIZ: epiderne com pêlos absorventes, córtex, cilindro "
                "vascular. A endoderme com bainha de Caspari controla a "
                "entrada de água e sais no xilema.\n\n"
                "CAULE: revestido por epiderme ou periderme, córtex, "
                "fascículos vasculares (xilema e floema), medula. O "
                "crescimento secundário forma os anéis de crescimento.\n\n"
                "FOLHA: epiderme com cutícula e estômatos, mesofilo "
                "(paranquima clorofiliano em paliçada e lacunoso), nervuras "
                "(xilema e floema)."
            ),
            "exemplo": (
                "A bainha de Caspari é uma 'vedação' na endoderme da raiz "
                "que obriga a água e os sais minerais a passar pelo "
                "interior das células endodérmicas, em vez de escoar pelo "
                "espaço entre elas. Isso permite o controle seletivo do "
                "que entra no xilema. Plantas em solos salinos ou "
                "contaminados por metais pesados dependem dessa seleção "
                "para sobreviver. Em medicina, o entendimento da "
                "absorção radicular explica por que algumas plantas "
                "acumulam e hiperacumulam poluentes — e podem ser usadas "
                "na fitoextração de solos contaminados."
            ),
        },
    ],
    "resumo": (
        "- Briófitas: não vasculares, gametófito dominante, dependem de água.\n"
        "- Pteridófitas: vasculares, esporos, esporófito dominante, dependem de água.\n"
        "- Gimnospermas: sementes nuas, cones, não dependem de água (exceto cicas/ginkgo).\n"
        "- Angiospermas: flores e frutos, dupla fecundação, monocots (1 cotilédone) e dicots (2).\n"
        "- Tecidos: meristemáticos (apical, lateral, intercalar) e adultos (revestimento, sustentação, condução, fundamental).\n"
        "- Xilema = água e sais; floema = seiva elaborada. Bainha de Caspari na endoderme."
    ),
    "dicas": [
        "Briófitas NÃO têm vasos. Pteridófitas têm vasos mas não sementes.",
        "Gimnospermas têm sementes nuas (sem fruto). Angiospermas têm flores e frutos.",
        "Dupla fecundação é exclusiva das angiospermas: embrião (2n) e endosperma (3n).",
        "Monocots: 1 cotilédone, nervura paralela, raiz fasciculada. Dicots: 2, reticulada, pivotante.",
        "Xilema sobe água; floema desce açúcar (seiva elaborada).",
        "Colenquima = flexível (células vivas); esclerênquima = rígido (células mortas, lignina).",
    ],
    "pegadinhas": [
        "Achar que gimnospermas têm flores: têm cones (estrobolos), não flores.",
        "Confundir pteridófitas com gimnospermas: pteridófitas não têm sementes, têm esporos.",
        "Achar que briófitas têm raízes: têm rizoides, sem vasos e sem função de absorção como raiz.",
        "Esquecer que a dupla fecundação dá endosperma triploide (3n), não diploide.",
        "Confundir xilema com floema: xilema sobe água; floema transporta açúcares (seiva elaborada).",
        "Achar que dicotiledôneas têm raiz fasciculada: raiz fasciculada é de monocots; dicots têm pivotante.",
    ],
    "referencias": [
        "RAVEN, P. H.; EVERT, R. F.; EICHHORN, S. E. Biologia Vegetal. 8. ed. Rio de Janeiro: Guanabara Koogan, 2017.",
        "ESAU, K. Anatomia das Plantas com Sementes. São Paulo: Blucher, 2006.",
        "APPEZZATO-DA-GLÓRIA, B.; HAYASHI, A. H. Morfologia de Plantas: Aspectos Notáveis de Morfogenesis. Viçosa: UFV, 2011.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "ALBERTS, B. et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "LORENZI, H.; MATOS, F. J. A. Plantas Medicinais no Brasil: Nativas e Exóticas. Nova Odessa: Instituto Plantarum, 2008.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Botânica")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_BOTANICA.pdf"

    images_data = [
        {"file": "br_bot_briofitas.jpg",
         "caption": "Ciclo de vida das briófitas: gametófito e esporófito",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/briofitas.htm"},
        {"file": "br_bot_pteridofitas.jpg",
         "caption": "Ciclo de vida das pteridófitas: esporos, soro e protalo",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/pteridofitas.htm"},
        {"file": "br_bot_gimnospermas.jpg",
         "caption": "Ciclo de vida das gimnospermas: cones, pólen e sementes nuas",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/gimnospermas.htm"},
        {"file": "br_bot_angiospermas.jpg",
         "caption": "Ciclo de vida das angiospermas: flores, polinização, frutos e sementes",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/angiospermas.htm"},
        {"file": "br_bot_tecidos.jpg",
         "caption": "Sistemas de tecidos vegetais: revestimento, sustentação, condução e fundamental",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecidos-vegetais.htm"},
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
