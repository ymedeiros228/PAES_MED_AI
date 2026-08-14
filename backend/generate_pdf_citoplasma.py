# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Citoplasma.

Texto 100% PT-BR (Português Brasileiro) com acentuação correta.
Imagens de sites educacionais brasileiros.
Referências em formato ABNT.
"""

import os
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from PIL import Image as PILImage

# Diretorios
ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
PDF_DIR = ROOT / "data" / "materiais"

# Cores do app
PRIMARY = HexColor("#0D7C66")
PRIMARY_DARK = HexColor("#0A5D4D")
PRIMARY_LIGHT = HexColor("#E0F2F1")
ACCENT = HexColor("#FFB74D")
TEXT_DARK = HexColor("#1A1A2E")
TEXT_LIGHT = HexColor("#666666")
BG_LIGHT = HexColor("#F8F9FA")
TIP_GREEN = HexColor("#2E7D32")
WARN_RED = HexColor("#C62828")

HEADERS = {"User-Agent": "PAESMedAI/1.0 (educational project; https://paesmedai.com)"}


# ---------------------------------------------------------------------------
# Registrar fontes com suporte a acentos
# ---------------------------------------------------------------------------

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
_FONT_NORMAL = "Normal" if _HAS_TTF else "Helvetica"
_FONT_BOLD = "Bold" if _HAS_TTF else "Helvetica-Bold"
_FONT_ITALIC = "Italic" if _HAS_TTF else "Helvetica-Oblique"
_FONT_BOLD_ITALIC = "BoldItalic" if _HAS_TTF else "Helvetica-BoldOblique"


# ---------------------------------------------------------------------------
# Conteúdo científico detalhado (PT-BR, com acentuação correta)
# ---------------------------------------------------------------------------

CONTENT = {
    "titulo": "Citoplasma",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Citoplasma",
    "introducao": (
        "O citoplasma é o espaço entre a membrana plasmática e o núcleo da célula. "
        "Nas células eucarióticas, ele é preenchido por um fluido chamado hialoplasma "
        "(ou citosol), onde estão mergulhadas as organelas celulares, o citoesqueleto "
        "e inclusões diversas. É no citoplasma que ocorre a maior parte das reações "
        "metabólicas da célula, incluindo a glicólise, a síntese de proteínas e a "
        "maior parte do transporte de substâncias.\n\n"
        "Compreender a organização do citoplasma é fundamental para a Biologia Celular "
        "e para a Medicina, pois muitas doenças resultam de disfunções em processos "
        "que ocorrem nesse compartimento — desde erros metabólicos até problemas no "
        "transporte intracelular e na divisão celular."
    ),
    "secoes": [
        {
            "titulo": "1. Organização Geral do Citoplasma",
            "conteudo": (
                "O citoplasma das células eucarióticas é dividido em três componentes "
                "principais:\n\n"
                "HIALOPLASMA (citosol): é a porção líquida do citoplasma, uma solução "
                "aquosa e viscosa composta por água (cerca de 70-80%), íons, moléculas "
                "pequenas (aminoácidos, glicose, nucleotídeos) e proteínas solúveis. "
                "É nele que ocorre a glicólise (primeira etapa da respiração celular) "
                "e muitas reações do metabolismo. O hialoplasma não é um líquido "
                "homogêneo: apresenta diferentes viscosidades em distintas regiões, "
                "formando um gradiente que facilita o transporte de moléculas.\n\n"
                "ORGANELAS: são estruturas especializadas, membranosas ou não, que "
                "realizam funções específicas. As membranosas incluem mitocôndrias, "
                "retículo endoplasmático, complexo de Golgi, lisossomos e peroxissomos. "
                "As não membranosas incluem ribossomos e o citoesqueleto. Cada organela "
                "tem uma função definida e sua organização permite que a célula opere "
                "como uma unidade eficiente.\n\n"
                "CITOESQUELETO: é uma rede de filamentos proteicos que dá forma à "
                "célula, mantém a posição das organelas e permite movimentos celulares. "
                "É composto por três tipos de filamentos: microtúbulos, microfilamentos "
                "e filamentos intermediários.\n\n"
                "INCLUSÕES: são estruturas temporárias, geralmente não metabolicamente "
                "ativas, como gotas de lipídios, grânulos de glicogênio e pigmentos. "
                "Diferem das organelas por não serem essenciais à sobrevivência da "
                "célula e por serem armazenamento de substâncias."
            ),
            "exemplo": (
                "Analogia: imagine uma fábrica. O hialoplasma é o galpão principal onde "
                "tudo acontece. As organelas são as máquinas e estações de trabalho "
                "especializadas. O citoesqueleto é a estrutura do prédio e os corredores "
                "que conectam tudo. As inclusões são os depósitos de matéria-prima e "
                "produtos prontos."
            ),
        },
        {
            "titulo": "2. Hialoplasma (Citosol)",
            "conteudo": (
                "O hialoplasma é a matriz citoplasmática líquida onde as organelas "
                "estão suspensas. Sua composição inclui:\n\n"
                "ÁGUA: é o componente mais abundante (70-80%), funcionando como solvente "
                "universal onde as reações bioquímicas ocorrem.\n\n"
                "ÍONS INORGÂNICOS: potássio (K+), sódio (Na+), cálcio (Ca2+), magnésio "
                "(Mg2+), cloreto (Cl-). A concentração de K+ é alta no hialoplasma "
                "(cerca de 150 mM), enquanto a de Na+ é baixa — o oposto do meio "
                "extracelular. Essa diferença é mantida pela bomba Na+/K+ e é "
                "essencial para o potencial de membrana.\n\n"
                "MOLÉCULAS ORGÂNICAS PEQUENAS: aminoácidos, glicose, ácidos graxos, "
                "nucleotídeos — precursores para a síntese de macromoléculas.\n\n"
                "MACROMOLÉCULAS: proteínas solúveis (enzimas da glicólise, fatores de "
                "transcrição, proteínas estruturais), RNA mensageiro e RNA transportador.\n\n"
                "O hialoplasma tem pH próximo do neutro (7,0-7,4) e sua viscosidade varia "
                "de acordo com a concentração de proteínas e com a organização do "
                "citoesqueleto. Em algumas regiões, o hialoplasma é mais fluido (sol); "
                "em outras, mais viscoso (gel). Essa transição sol-gel é importante "
                "para movimentos celulares como a emissão de pseudópodos."
            ),
            "exemplo": (
                "A glicólise — primeira etapa da respiração celular, onde uma molécula "
                "de glicose é quebrada em duas de piruvato — ocorre inteiramente no "
                "hialoplasma. Todas as enzimas da glicólise (hexoquinase, fosfofrutoquinase, "
                "piruvato quinase, etc.) estão dissolvidas no citosol. Por isso, mesmo "
                "células sem mitocôndrias (como alguns parasitos) conseguem gerar ATP "
                "via fermentação no hialoplasma."
            ),
        },
        {
            "titulo": "3. Citoesqueleto",
            "conteudo": (
                "O citoesqueleto é uma rede dinâmica de filamentos proteicos que "
                "permeia o citoplasma. Suas principais funções são:\n\n"
                "- Manter a forma da célula (especialmente em células animais, que "
                "não têm parede celular);\n"
                "- Posicionar e ancorar as organelas em locais específicos;\n"
                "- Permitir movimentos celulares (locomoção, divisão, endocitose);\n"
                "- Formar vias para o transporte intracelular de vesículas e organelas.\n\n"
                "O citoesqueleto é composto por três tipos de filamentos:\n\n"
                "MICROTÚBULOS: são os mais espessos (cerca de 25 nm de diâmetro). "
                "Formados por tubulina (heterodímero de alfa e beta tubulina), "
                "organizam-se em cilindros ocos. Crescem a partir do centrossomo "
                "(organizador de microtúbulos). Funções: mantêm a forma, formam o "
                "fuso mitótico (separa os cromossomos na divisão), formam cílios e "
                "flagelos, e servem como trilhos para o transporte de vesículas "
                "(as proteínas motoras cinesina e dineína se movem sobre eles).\n\n"
                "MICROFILAMENTOS: são os mais finos (cerca de 7 nm). Formados por "
                "actina, organizam-se em hélices. Funções: contração muscular (com "
                "miosina), movimento celular (pseudópodos), citocinese (divisão do "
                "citoplasma), manutenção da forma em microvillosidades.\n\n"
                "FILAMENTOS INTERMEDIÁRIOS: têm diâmetro intermediário (cerca de 10 nm). "
                "São os mais estáveis e duradouros. Formados por diferentes proteínas "
                "conforme o tecido: queratina (epitélio), vimentina (tecido conjuntivo), "
                "neurofilamentos (neurônios), lamina (núcleo). Função: resistência "
                "mecânica e ancoragem de organelas."
            ),
            "exemplo": (
                "O fuso mitótico é formado por microtúbulos que partem dos centrossomos "
                "e se conectam aos cromossomos. Durante a anáfase, os microtúbulos "
                "encurtam e puxam as cromátides irmãs para os polos opostos da célula. "
                "Drogas como a colchicina (usada no tratamento de gota) inibem a "
                "polimerização dos microtúbulos, impedindo a divisão celular. O Taxol "
                "(paclitaxel), usado em quimioterapia, estabiliza os microtúbulos e "
                "também bloqueia a divisão das células tumorais."
            ),
        },
        {
            "titulo": "4. Diferenças entre Células Animais e Vegetais",
            "conteudo": (
                "O citoplasma das células animais e vegetais apresenta semelhanças, "
                "mas também diferenças importantes:\n\n"
                "CÉLULAS ANIMAIS:\n"
                "- Citoplasma delimitado apenas pela membrana plasmática;\n"
                "- Possuem centrossomos e lisossomos;\n"
                "- Armazenam glicogênio como reserva de energia;\n"
                "- Podem ter microvillosidades, cílios e flagelos;\n"
                "- Forma determinada pelo citoesqueleto (sem parede celular).\n\n"
                "CÉLULAS VEGETAIS:\n"
                "- Possuem parede celular de celulose externa à membrana;\n"
                "- Geralmente não têm centrossomos (exceto em algas e fungos);\n"
                "- Raramente possuem lisossomos (a função é feita pelos vacúolos);\n"
                "- Possuem cloroplastos (fotossíntese) e vacúolo central grande;\n"
                "- Armazenam amido como reserva de energia;\n"
                "- Forma determinada pela parede celular rígida.\n\n"
                "O vacúolo central das células vegetais pode ocupar até 90% do volume "
                "celular. Ele armazena água, íons, nutrientes e pigmentos, e mantém a "
                "pressão de turgescência que dá rigidez às células vegetais — é por "
                "isso que uma planta sem água murcha (perde a turgescência)."
            ),
            "exemplo": (
                "A parede celular de celulose é o que dá rigidez às plantas e permite "
                "que elas cresçam em altura sem esqueleto interno. É também o que "
                "distingue as células vegetais das animais na microscopia: a parede "
                "aparece como uma linha dupla ao redor da célula. Na digestão humana, "
                "a celulose não é absorvida (não temos celulase) — é a fibra alimentar, "
                "importante para o trânsito intestinal."
            ),
        },
        {
            "titulo": "5. Inclusões Citoplasmáticas",
            "conteudo": (
                "Inclusões são acúmulos temporários de substâncias no citoplasma. "
                "Diferem das organelas por não serem metabolicamente ativas e por "
                "serem produtos de armazenamento ou de excreção. Os principais tipos:\n\n"
                "GLICOGÊNIO: polímero de glicose, principal reserva de carboidratos "
                "em células animais. É abundante no fígado (hepatócitos) e nos "
                "músculos (miócitos). Em microscopia eletrônica, aparece como grânulos "
                "densos e irregulares (partículas beta e alfa).\n\n"
                "GOTÍCULAS DE LIPÍDIOS: esferas de triglicerídeos armazenadas "
                "principalmente em adipócitos (células de gordura) e, em menor "
                "quantidade, em hepatócitos e músculos. São envoltas por uma monocamada "
                "lipídica, não por uma bicamada.\n\n"
                "GRÂNULOS DE AMIDO: reserva de carboidratos em células vegetais. "
                "Formam grãos com estratificação concêntrica, visíveis ao microscópio "
                "óptico. São encontrados em amiloplastos (tipo de plasto).\n\n"
                "PIGMENTOS: melanina (proteção contra UV, na pele e nos olhos), "
                "lipofuscina (produto do envelhecimento celular, em neurônios e "
                "células cardíacas), hemoglobina (em hemácias).\n\n"
                "CRISTAIS: algumas células formam cristais de oxalato de cálcio "
                "(plantas) ou de urato (em gota, em articulações)."
            ),
            "exemplo": (
                "O glicogênio hepático é a principal reserva de glicose do corpo. "
                "Entre as refeições, o fígado quebra o glicogênio e libera glicose "
                "no sangue para manter a glicemia. Em uma pessoa saudável, o fígado "
                "armazena cerca de 100 g de glicogênio — o suficiente para manter "
                "a glicemia por 12-24 horas de jejum. Em pacientes com diabetes, "
                "a regulação desse processo é deficiente."
            ),
        },
    ],
    "resumo": (
        "- O citoplasma é o espaço entre a membrana plasmática e o núcleo, preenchido pelo hialoplasma.\n"
        "- Hialoplasma (citosol): 70-80% água, íons, moléculas pequenas e proteínas solúveis. Local da glicólise.\n"
        "- Citoesqueleto: microtúbulos (tubulina, 25 nm), microfilamentos (actina, 7 nm) e filamentos intermediários (10 nm).\n"
        "- Microtúbulos: fuso mitótico, cílios, flagelos, transporte de vesículas (cinesina e dineína).\n"
        "- Microfilamentos: contração (com miosina), pseudópodos, citocinese, microvillosidades.\n"
        "- Filamentos intermediários: resistência mecânica (queratina, vimentina, neurofilamentos, lamina).\n"
        "- Inclusões: glicogênio (animais), amido (vegetais), lipídios, pigmentos, cristais.\n"
        "- Células animais: centrossomos, lisossomos, glicogênio. Vegetais: parede de celulose, cloroplastos, vacúolo central, amido."
    ),
    "dicas": [
        "Decore os três tipos de filamentos do citoesqueleto com seus diâmetros: microfilamentos (7 nm, actina), filamentos intermediários (10 nm, vários) e microtúbulos (25 nm, tubulina).",
        "Microtúbulos = fuso mitótico + cílios/flagelos + transporte. Microfilamentos = contração + movimentos celulares. Filamentos intermediários = resistência mecânica.",
        "Cinesina move vesículas para o polo (+) do microtúbulo; dineína para o polo (-). Cai em prova!",
        "Glicólise ocorre no hialoplasma, não na mitocôndria. Erro comum!",
        "Células vegetais não têm centrossomo (exceção: algas) nem lisossomos (função dos vacúolos).",
        "Colchicina inibe e Taxol estabiliza microtúbulos — ambos bloqueiam a divisão celular.",
    ],
    "pegadinhas": [
        "Confundir hialoplasma com citoplasma: o citoplasma é o conjunto (hialoplasma + organelas + inclusões); o hialoplasma é só a parte líquida.",
        "Achar que a glicólise ocorre na mitocôndria: ela ocorre no hialoplasma. A mitocôndria faz o ciclo de Krebs e a cadeia respiratória.",
        "Confundir cinesina com dineína: cinesina = anterógrado (para o +); dineína = retrógrado (para o -).",
        "Esquecer que células vegetais geralmente não têm centrossomos: o fuso mitótico se organiza de outra forma.",
        "Achar que filamentos intermediários participam da contração muscular: a contração é actina + miosina (microfilamentos).",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "NELSON, D. L.; COX, M. M. Lehninger Princípios de Bioquímica. 7. ed. São Paulo: Sarvier, 2017.",
        "COOPER, G. M.; HAUSMAN, R. E. A Célula: Uma Abordagem Molecular. 7. ed. Porto Alegre: Artmed, 2019.",
    ],
}


# ---------------------------------------------------------------------------
# Gerar PDF
# ---------------------------------------------------------------------------

def _header_footer(canvas_obj, doc):
    canvas_obj.saveState()
    width, height = A4
    if LOGO_PATH.exists():
        canvas_obj.drawImage(
            str(LOGO_PATH), 1.5*cm, height - 1.8*cm,
            width=1.2*cm, height=1.2*cm, preserveAspectRatio=True, mask='auto'
        )
    canvas_obj.setFillColor(PRIMARY)
    canvas_obj.setFont(_FONT_BOLD, 9)
    canvas_obj.drawString(3*cm, height - 1.2*cm, "PAES MED AI")
    canvas_obj.setFont(_FONT_NORMAL, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Citoplasma")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FONT_NORMAL, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_CITOPLASMA.pdf"

    images_data = [
        {
            "file": "br_cito_celula_eucarionte.jpg",
            "caption": "Estrutura geral de uma célula eucarionte com suas organelas",
            "source": "Mundo Educação",
            "source_url": "https://mundoeducacao.uol.com.br/biologia/citoplasma.htm",
        },
        {
            "file": "br_cito_celula_vegetal.jpg",
            "caption": "Célula vegetal: parede celular, cloroplastos e vacúolo central",
            "source": "Mundo Educação",
            "source_url": "https://mundoeducacao.uol.com.br/biologia/citoplasma.htm",
        },
        {
            "file": "br_cito_citoesqueleto_be.jpg",
            "caption": "Citoesqueleto: rede de filamentos que dá forma e sustentação à célula",
            "source": "Brasil Escola",
            "source_url": "https://brasilescola.uol.com.br/biologia/citoesqueleto.htm",
        },
        {
            "file": "br_cito_microtubulos.jpg",
            "caption": "Microtúbulos: formados por tubulina, participam do fuso mitótico e do transporte",
            "source": "InfoEscola",
            "source_url": "https://www.infoescola.com/citologia/citoesqueleto/",
        },
        {
            "file": "br_cito_anatomia_celula.jpg",
            "caption": "Anatomia de uma célula humana com detalhes do citoplasma",
            "source": "Toda Matéria",
            "source_url": "https://www.todamateria.com.br/citoplasma/",
        },
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
                "is_pt": True,
            })
            print(f"  OK: {img_data['file']}")
        else:
            print(f"  FALTANDO: {img_data['file']}")

    # Estilos
    styles = getSampleStyleSheet()
    style_title = ParagraphStyle('TitleCustom', parent=styles['Title'],
        fontName=_FONT_BOLD, fontSize=24, textColor=PRIMARY, spaceAfter=6, alignment=TA_CENTER)
    style_subtitle = ParagraphStyle('SubtitleCustom', parent=styles['Normal'],
        fontName=_FONT_ITALIC, fontSize=12, textColor=TEXT_LIGHT, spaceAfter=20, alignment=TA_CENTER)
    style_h2 = ParagraphStyle('H2Custom', parent=styles['Heading2'],
        fontName=_FONT_BOLD, fontSize=15, textColor=PRIMARY_DARK, spaceBefore=18, spaceAfter=8)
    style_body = ParagraphStyle('BodyCustom', parent=styles['Normal'],
        fontName=_FONT_NORMAL, fontSize=11, textColor=TEXT_DARK, leading=16, alignment=TA_JUSTIFY, spaceAfter=8)
    style_example = ParagraphStyle('ExampleCustom', parent=style_body,
        fontName=_FONT_ITALIC, fontSize=10, textColor=PRIMARY_DARK,
        leftIndent=15, rightIndent=15, borderColor=PRIMARY, borderWidth=0.5,
        borderPadding=8, backColor=PRIMARY_LIGHT, spaceBefore=8, spaceAfter=12)
    style_caption = ParagraphStyle('CaptionCustom', parent=styles['Normal'],
        fontName=_FONT_ITALIC, fontSize=9, textColor=TEXT_LIGHT, alignment=TA_CENTER, spaceAfter=4)
    style_ref = ParagraphStyle('RefCustom', parent=styles['Normal'],
        fontName=_FONT_NORMAL, fontSize=10, textColor=TEXT_DARK, leading=14, spaceAfter=6, leftIndent=15, firstLineIndent=-15)

    story = []

    # Capa
    story.append(Spacer(1, 3*cm))
    if LOGO_PATH.exists():
        img = Image(str(LOGO_PATH), width=3*cm, height=3*cm)
        img.hAlign = 'CENTER'
        story.append(img)
    story.append(Spacer(1, 1*cm))
    story.append(Paragraph(CONTENT["titulo"], style_title))
    story.append(Paragraph(f'{CONTENT["disciplina"]} — {CONTENT["topico"]}', style_subtitle))
    story.append(HRFlowable(width="60%", thickness=2, color=PRIMARY, hAlign='CENTER'))
    story.append(Spacer(1, 0.8*cm))
    story.append(Paragraph(CONTENT["introducao"].replace('\n\n', '<br/><br/>'), style_body))
    story.append(PageBreak())

    # Seções
    img_idx = 0
    for sec in CONTENT["secoes"]:
        story.append(Paragraph(sec["titulo"], style_h2))
        story.append(Paragraph(sec["conteudo"].replace('\n\n', '<br/><br/>').replace('\n', '<br/>'), style_body))
        if sec.get("exemplo"):
            story.append(Paragraph(f'<b>Exemplo clínico/prático:</b><br/>{sec["exemplo"]}', style_example))
        # Inserir imagem a cada 2 seções
        img_idx += 1
        if img_idx % 2 == 0 and img_idx <= len(downloaded_images) * 2:
            img_pos = (img_idx // 2) - 1
            if img_pos < len(downloaded_images):
                img_data = downloaded_images[img_pos]
                try:
                    pil_img = PILImage.open(img_data["path"])
                    w, h = pil_img.size
                    max_w = 14 * cm
                    max_h = 10 * cm
                    ratio = min(max_w / w, max_h / h)
                    img = Image(img_data["path"], width=w*ratio, height=h*ratio)
                    img.hAlign = 'CENTER'
                    story.append(Spacer(1, 0.3*cm))
                    story.append(img)
                    story.append(Paragraph(
                        f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                        style_caption))
                    story.append(Spacer(1, 0.3*cm))
                except Exception as e:
                    print(f"  Erro imagem {img_data['file']}: {e}")

    # Imagens restantes
    used = max(0, (len(CONTENT["secoes"]) // 2))
    for img_data in downloaded_images[used:]:
        try:
            pil_img = PILImage.open(img_data["path"])
            w, h = pil_img.size
            max_w = 14 * cm
            max_h = 10 * cm
            ratio = min(max_w / w, max_h / h)
            img = Image(img_data["path"], width=w*ratio, height=h*ratio)
            img.hAlign = 'CENTER'
            story.append(Spacer(1, 0.3*cm))
            story.append(img)
            story.append(Paragraph(
                f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                style_caption))
            story.append(Spacer(1, 0.3*cm))
        except Exception as e:
            print(f"  Erro imagem: {e}")

    # Resumo
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Resumo", style_h2))
    story.append(Paragraph(CONTENT["resumo"].replace('\n', '<br/>'), style_body))

    # Dicas
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Dicas para a Prova", style_h2))
    for dica in CONTENT["dicas"]:
        story.append(Paragraph(f'• {dica}', style_body))

    # Pegadinhas
    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Pegadinhas Comuns", style_h2))
    for peg in CONTENT["pegadinhas"]:
        story.append(Paragraph(f'⚠ {peg}', style_body))

    # Referências
    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Referências", style_h2))
    for ref in CONTENT["referencias"]:
        story.append(Paragraph(ref, style_ref))

    # Gerar
    doc = SimpleDocTemplate(
        str(pdf_path), pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm,
        topMargin=2.5*cm, bottomMargin=2*cm,
        title=f'PAES MED AI — {CONTENT["titulo"]}',
        author='PAES MED AI'
    )
    doc.build(story, onFirstPage=_header_footer, onLaterPages=_header_footer)

    size_kb = pdf_path.stat().st_size / 1024
    print(f"\nPDF gerado: {pdf_path}")
    print(f"Tamanho: {size_kb:.1f} KB")
    return pdf_path


if __name__ == "__main__":
    generate_pdf()
