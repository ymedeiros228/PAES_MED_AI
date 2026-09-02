"""Gera PDF profissional ABNT do material de Biologia - Organelas Celulares.

Texto 100% PT-BR (Português Brasileiro) com acentuação correta.
Imagens de sites educacionais brasileiros.
Referências em formato ABNT.
"""

import os
from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import HRFlowable, Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer

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
    "titulo": "Organelas Celulares",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Organelas Celulares",
    "introducao": (
        "As organelas celulares são estruturas especializadas presentes no citoplasma "
        "das células eucarióticas. Cada uma tem uma função específica e, juntas, "
        "funcionam como os órgãos de um corpo — daí o nome \"organelas\". Elas "
        "permitem que a célula divida seu trabalho em compartimentos, aumentando "
        "a eficiência dos processos metabólicos.\n\n"
        "As organelas podem ser membranosas (limitadas por membrana) ou não "
        "membranosas. As membranosas incluem mitocôndrias, retículo endoplasmático, "
        "complexo de Golgi, lisossomos e peroxissomos. As não membranosas incluem "
        "ribossomos e o citoesqueleto. Compreender cada organela é essencial para "
        "a Medicina, pois inúmeras doenças resultam de disfunções organelares — "
        "desde doenças mitocondriais até lysosomopatias como a doença de Tay-Sachs."
    ),
    "secoes": [
        {
            "titulo": "1. Mitocôndrias",
            "conteudo": (
                "As mitocôndrias são as organelas da respiração celular — são elas "
                "que produzem a maior parte do ATP da célula através do ciclo de "
                "Krebs e da cadeia respiratória (fosforilação oxidativa). Por isso, "
                "são chamadas de \"casas de força\" da célula.\n\n"
                "ESTRUTURA: possuem duas membranas. A membrana externa é lisa e "
                "permeável a pequenas moléculas. A membrana interna é pregueada, "
                "formando dobras chamadas cristas mitocondriais — essas dobras "
                "aumentam enormemente a superfície interna, onde estão as proteínas "
                "da cadeia respiratória. O espaço entre as duas membranas é chamado "
                "de espaço intermembranas. O espaço interno (matriz mitocondrial) "
                "contém o DNA mitocondrial, ribossomos próprios e enzimas do ciclo "
                "de Krebs.\n\n"
                "FUNÇÃO: oxidar o piruvato (proveniente da glicólise) e os ácidos "
                "graxos para produzir ATP. O oxigênio é o aceptor final de elétrons "
                "na cadeia respiratória — por isso, sem O2, a mitocôndria não "
                "consegue produzir ATP via fosforilação oxidativa.\n\n"
                "DNA PRÓPRIO: a mitocôndria tem seu próprio DNA circular (como "
                "bactérias), o que sustenta a Teoria da Endossimbiose — a ideia de "
                "que as mitocôndrias eram bactérias livres que foram englobadas por "
                "outra célula e estabeleceram uma relação simbiótica. O DNA "
                "mitocondrial é herdado apenas da mãe (via ovo)."
            ),
            "exemplo": (
                "As doenças mitocondriais afetam tecidos com alta demanda energética: "
                "músculos, cérebro e coração. Exemplos: distrofia miotônica, neuropatia "
                "óptica de Leber (perda de visão hereditária) e o síndrome MELAS. "
                "Como o DNA mitocondrial vem só da mãe, essas doenças têm herança "
                "materna — todos os filhos de uma mãe afetada podem herdar, mas "
                "um pai afetado não transmite."
            ),
        },
        {
            "titulo": "2. Retículo Endoplasmático (RE)",
            "conteudo": (
                "O retículo endoplasmático é uma rede de membranas interconectadas "
                "que formam túbulos e cisternas, estendendo-se do envoltório nuclear "
                "até a periferia da célula. Existem dois tipos:\n\n"
                "RE RUGOSO (granular): tem ribossomos aderidos à sua superfície "
                "externa, o que lhe dá o aspecto \"rugoso\" ao microscópio eletrônico. "
                "Função principal: síntese de proteínas que serão destinadas à "
                "secreção, à membrana plasmática ou aos lisossomos. As proteínas são "
                "sintetizadas pelos ribossomos e entram no lúmen do RE, onde sofrem "
                "modificações (glicosilação, folding) e são empacotadas em vesículas "
                "para o complexo de Golgi.\n\n"
                "RE LISO (agranular): não tem ribossomos. Funções: síntese de "
                "lipídios (fosfolipídios e colesterol), metabolismo de carboidratos, "
                "detoxificação de drogas e toxinas (especialmente no fígado, onde "
                "é abundante), e armazenamento de íons cálcio (importantíssimo para "
                "a contração muscular — o cálcio é liberado do RE liso do músculo, "
                "chamado de retículo sarcoplasmático).\n\n"
                "Nos hepatócitos (células do fígado), o RE liso é muito desenvolvido "
                "porque é ali que ocorre a detoxificação de medicamentos e álcool. "
                "O uso crônico de certas drogas induz a proliferação do RE liso — "
                "é por isso que pessoas que consomem certos medicamentos podem "
                "desenvolver tolerância (o fígado fica mais eficiente em degradar "
                "a droga)."
            ),
            "exemplo": (
                "O retículo sarcoplasmático é uma especialização do RE liso nas "
                "células musculares. Ele armazena cálcio e, quando o músculo recebe "
                "um estímulo nervoso, libera cálcio no citoplasma, desencadeando a "
                "contração. Quando o estímulo cessa, o cálcio é rebombado para o "
                "retículo. Drogas como a cafeína aumentam a liberação de cálcio, "
                "potencializando a contração muscular."
            ),
        },
        {
            "titulo": "3. Complexo de Golgi (Golgiense)",
            "conteudo": (
                "O complexo de Golgi é uma série de membranas achatadas empilhadas "
                "(cisternas) que funciona como central de classificação, modificação "
                "e empacotamento de proteínas e lipídios. Recebe vesículas do RE, "
                "modifica seu conteúdo e o envia para o destino correto.\n\n"
                "ORGANIZAÇÃO: tem duas faces distintas:\n"
                "- Face cis (imatura): voltada para o RE, recebe as vesículas;\n"
                "- Face trans (madura): voltada para a membrana plasmática, emite "
                "vesículas para seus destinos.\n\n"
                "FUNÇÕES:\n"
                "- Modificação de proteínas: glicosilação (adição de carboidratos), "
                "fosforilação, sulfatação;\n"
                "- Classificação: envia proteínas para a membrana, para secreção "
                "(exocitose) ou para os lisossomos;\n"
                "- Síntese de glicolipídios e glicoproteínas da membrana;\n"
                "- Formação dos lisossomos (as enzimas lisossomais são produzidas "
                "no RE, modificadas no Golgi e empacotadas em vesículas que se "
                "tornam lisossomos);\n"
                "- Formação do acrossomo dos espermatozoides (estrutura que contém "
                "enzimas para penetrar o óvulo);\n"
                "- Secreção de glicocálix e parede celular em plantas.\n\n"
                "O Golgi é especialmente desenvolvido em células secretoras: "
                "plasmócitos (anticorpos), células acinares do pâncreas (enzimas "
                "digestivas), neurônios (neurotransmissores)."
            ),
            "exemplo": (
                "Nas células caliciformes do intestino e das vias respiratórias, "
                "o Golgi produz mucina (glicoproteína que forma o muco). O muco "
                "protege e lubrifica as superfícies epiteliais. Na fibrose cística, "
                "uma mutação no gene CFTR afeta o transporte de cloreto e torna o "
                "muco espesso — o que obstrui os brônquios e os ductos do pâncreas. "
                "É uma das doenças genéticas mais comuns em populações caucasianas."
            ),
        },
        {
            "titulo": "4. Lisossomos e Peroxissomos",
            "conteudo": (
                "LISOSSOMOS: são vesículas membranosas que contêm enzimas hidrolíticas "
                "(hidrolases ácidas) capazes de degradar todas as classes de "
                "macromoléculas: proteínas, lipídios, carboidratos e ácidos nucleicos. "
                "Trabalham em pH ácido (cerca de 5,0), mantido por uma bomba de "
                "prótons. Funções: digestão intracelular (fagocitose, autofagia), "
                "digestão de organelas envelhecidas (autofagia) e de partículas "
                "englobadas (heterofagia).\n\n"
                "As enzimas lisossomais são produzidas no RE rugoso, modificadas no "
                "Golgi (recebem um marcador de manose-6-fosfato) e empacotadas em "
                "vesículas que se tornam lisossomos.\n\n"
                "Doenças lisossomais (lisosomopatias): resultam da ausência de uma "
                "enzima lisossomal específica, levando ao acúmulo de substrato não "
                "degradado. Exemplos: doença de Tay-Sachs (acúmulo de gangliosídio "
                "GM2, causa cegueira e morte na infância), doença de Gaucher "
                "(acúmulo de glicocerebrosídio, causa aumento de fígado e baço), "
                "doença de Pompe (acúmulo de glicogênio nos lisossomos, causa "
                "fraqueza muscular).\n\n"
                "PEROXISSOMOS: são pequenas organelas membranosas que contêm enzimas "
                "oxidativas, especialmente a catalase. Funções: degradação de ácidos "
                "graxos por beta-oxidação, detoxificação do peróxido de hidrogênio "
                "(H2O2 — substância tóxica) convertendo-o em água e oxigênio, e "
                "metabolismo do álcool (no fígado). São abundantes nas células do "
                "fígado e dos rins.\n\n"
                "Doença peroxissomal: o síndrome de Zellweger é uma doença genética "
                "rara em que os peroxissomos não se formam corretamente, levando ao "
                "acúmulo de substâncias tóxicas e à morte na infância."
            ),
            "exemplo": (
                "A doença de Tay-Sachs é uma lysosomopatia autossômica recessiva "
                "causada pela deficiência da enzima hexosaminidase A. Sem ela, o "
                "gangliosídio GM2 acumula-se nos neurônios, levando à degeneração "
                "neural progressiva: a criança parece normal ao nascer, mas por "
                "volta dos 6 meses começa a perder habilidades motoras, desenvolve "
                "cegueira e convulsões, e geralmente morre antes dos 5 anos. É mais "
                "comum em populações judaicas ashkenazi."
            ),
        },
        {
            "titulo": "5. Ribossomos e Outras Estruturas",
            "conteudo": (
                "RIBOSSOMOS: são as organelas responsáveis pela síntese de proteínas "
                "(tradução do mRNA). São formados por duas subunidades: menor (30S "
                "em procariotos, 40S em eucariotos) e maior (50S em procariotos, "
                "60S em eucariotos). Juntas, formam 70S (procariotos) ou 80S "
                "(eucariotos). Cada subunidade é composta por rRNA e proteínas.\n\n"
                "Os ribossomos podem estar livres no hialoplasma (sintetizam proteínas "
                "que ficam na célula) ou aderidos ao RE rugoso (sintetizam proteínas "
                "para secreção ou para a membrana).\n\n"
                "DIFERENÇA IMPORTANTE: os ribossomos procarióticos (70S) são "
                "diferentes dos eucarióticos (80S), e essa diferença é explorada "
                "por vários antibióticos: tetraciclina, cloranfenicol e eritromicina "
                "inibem os ribossomos 70S das bactérias sem afetar os 80S humanos. "
                "É por isso que esses antibióticos matam as bactérias sem prejudicar "
                "nossas células.\n\n"
                "CENTROSSOMO: presente apenas em células animais, é o organizador "
                "dos microtúbulos. Formado por dois centríolos perpendiculares, "
                "cada um com 9 tríades de microtúbulos (9+0). Duplica-se antes da "
                "divisão e origina o fuso mitótico.\n\n"
                "CLOROPLASTOS: presentes apenas em células vegetais, são as "
                "organelas da fotossíntese. Possuem DNA próprio (como as "
                "mitocôndrias) e também são explicados pela Teoria da Endossimbiose. "
                "Contêm clorofila, que capta a luz para converter CO2 e água em "
                "glicose e oxigênio.\n\n"
                "VACÚOLOS: grandes vesículas membranosas. Nas células vegetais, "
                "o vacúolo central é enorme e mantém a turgescência. Nas células "
                "animais, os vacúolos são pequenos e participam da digestão e "
                "do armazenamento temporário."
            ),
            "exemplo": (
                "A diferença entre ribossomos 70S (bactérias) e 80S (humanos) é "
                "a base de muitos antibióticos. A tetraciclina liga-se à subunidade "
                "menor 30S bacteriana, bloqueando a entrada do aminoacil-tRNA. "
                "A eritromicina liga-se à subunidade maior 50S, inibindo a "
                "translocação. Como nossos ribossomos são 80S, essas drogas não "
                "nos afetam — mas inibem a síntese de proteínas bacteriana, "
                "impedindo sua multiplicação."
            ),
        },
    ],
    "resumo": (
        "- Mitocôndrias: respiração celular, ATP, ciclo de Krebs e cadeia respiratória. DNA próprio, herança materna.\n"
        "- RE rugoso: síntese de proteínas (com ribossomos). RE liso: síntese de lipídios, detoxificação, cálcio.\n"
        "- Complexo de Golgi: modifica, classifica e empacota proteínas. Face cis (entra) e trans (sai).\n"
        "- Lisossomos: digestão intracelular, pH ácido, enzimas hidrolíticas. Doenças: Tay-Sachs, Gaucher, Pompe.\n"
        "- Peroxissomos: beta-oxidação, catalase (quebra H2O2). Doença: Zellweger.\n"
        "- Ribossomos: síntese de proteínas. 70S (procariotos) vs 80S (eucariotos) — alvo de antibióticos.\n"
        "- Centrossomo: organizador de microtúbulos (animais). Cloroplastos: fotossíntese (vegetais).\n"
        "- Teoria da Endossimbiose: mitocôndrias e cloroplastos eram bactérias livres."
    ),
    "dicas": [
        "Mitocôndria = ATP + DNA próprio + herança materna. Decore estes três pontos!",
        "RE rugoso = proteínas (ribossomos). RE liso = lipídios + detox + cálcio. A palavra \"rugoso\" lembra \"ribossomos\".",
        "Golgi = correio da célula: recebe, modifica e envia. Face cis = entrada, trans = saída.",
        "Lisossomos = digestão. Peroxissomos = catalase (quebra peróxido). A palavra \"peroxissomo\" tem \"peróxido\".",
        "Ribossomos 70S = bactérias (alvo de antibióticos). 80S = eucariotos. Decore: 70 < 80, bactéria é menor.",
        "Teoria da Endossimbiose explica o DNA circular de mitocôndrias e cloroplastos.",
    ],
    "pegadinhas": [
        "Confundir RE rugoso com liso: o rugoso tem ribossomos (síntese de proteínas); o liso não tem (lipídios, detox, cálcio).",
        "Achar que a glicólise ocorre na mitocôndria: ela ocorre no hialoplasma. A mitocôndria faz o ciclo de Krebs e a cadeia respiratória.",
        "Confundir lisossomo com peroxissomo: lisossomo = hidrolases ácidas (digestão); peroxissomo = catalase (H2O2).",
        "Esquecer que a herança mitocondrial é materna: todos os filhos herdam da mãe, nenhum do pai.",
        "Achar que ribossomos são membranosos: eles não têm membrana, são formados por rRNA + proteínas.",
        "Confundir centrossomo com centríolo: o centrossomo contém dois centríolos perpendiculares.",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "NELSON, D. L.; COX, M. M. Lehninger Princípios de Bioquímica. 7. ed. São Paulo: Sarvier, 2017.",
        "COOPER, G. M.; HAUSMAN, R. E. A Célula: Uma Abordagem Molecular. 7. ed. Porto Alegre: Artmed, 2019.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Organelas Celulares")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_ORGANELAS_CELULARES.pdf"

    images_data = [
        {"file": "br_org_organelas_1.jpg",
         "caption": "Visão geral das organelas celulares e suas funções",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/organelas-celulares/"},
        {"file": "br_org_mitocondria_estrutura.jpg",
         "caption": "Estrutura da mitocôndria: membranas, cristas e matriz",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/mitocondrias.htm"},
        {"file": "br_org_reticulo.jpg",
         "caption": "Retículo endoplasmático: liso e rugoso com ribossomos",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/reticulo-endoplasmatico.htm"},
        {"file": "br_org_golgi.jpg",
         "caption": "Complexo de Golgi: cisternas empilhadas com faces cis e trans",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/complexo-golgi.htm"},
        {"file": "br_org_ribossomo.jpg",
         "caption": "Ribossomo: subunidades que sintetizam proteínas",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/ribossomos.htm"},
        {"file": "br_org_organelas_2.jpg",
         "caption": "Esquema comparativo das organelas celulares",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/organelas-celulares/"},
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

    img_idx = 0
    for sec in CONTENT["secoes"]:
        story.append(Paragraph(sec["titulo"], style_h2))
        story.append(Paragraph(sec["conteudo"].replace('\n\n', '<br/><br/>').replace('\n', '<br/>'), style_body))
        if sec.get("exemplo"):
            story.append(Paragraph(f'<b>Exemplo clínico/prático:</b><br/>{sec["exemplo"]}', style_ex))
        img_idx += 1
        if img_idx % 2 == 0 and img_idx <= len(downloaded_images) * 2:
            img_pos = (img_idx // 2) - 1
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

    used = max(0, (len(CONTENT["secoes"]) // 2))
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
