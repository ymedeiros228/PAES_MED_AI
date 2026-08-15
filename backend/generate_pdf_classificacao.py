# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Classificação e Sistemática.

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
    "titulo": "Classificação e Sistemática",
    "disciplina": "Biologia",
    "topico": "Classificação e Sistemática",
    "subtopico": "Taxonomia, Reinos e Filogenia",
    "introducao": (
        "A classificação dos seres vivos é a ciência que organiza e nomeia os "
        "organismos, estabelecendo relações entre eles. A Sistemática estuda "
        "a diversidade dos seres vivos e suas relações evolutivas. Ambas são "
        "fundamentais para a Biologia e para a Medicina: conhecer os "
        "organismos é essencial para identificar agentes causadores de "
        "doenças, vetores, hospedeiros e medicamentos naturais.\n\n"
        "A classificação biológica tem raízes antigas, mas foi formalizada "
        "por Lineu no século XVIII com a nomenclatura binomial. Hoje, com "
        "a genética e a filogenética molecular, a classificação reflete "
        "relações evolutivas reais, não apenas semelhanças superficiais."
    ),
    "secoes": [
        {
            "titulo": "1. Taxonomia e Nomenclatura",
            "conteudo": (
                "A Taxonomia é a ciência que classifica, nomeia e identifica "
                "os seres vivos. A nomenclatura binomial foi proposta por "
                "Carlos Lineu (1707-1778) no livro \"Systema Naturae\". "
                "Segundo esse sistema, cada espécie recebe um nome "
                "científico composto por dois termos em latim:\n\n"
                "1. Gênero (com inicial maiúscula);\n"
                "2. Epíteto específico (com inicial minúscula).\n\n"
                "Exemplo: Homo sapiens (gênero Homo, espécie sapiens). "
                "Deve ser sublinhado quando manuscrito ou escrito em "
                "itálico quando impresso.\n\n"
                "CATEGORIAS TAXONÔMICAS (da mais ampla para a mais específica):\n\n"
                "Reino → Filo → Classe → Ordem → Família → Gênero → "
                "Espécie.\n"
                "Mnemônico: Reis Felizes Chamaram Ouvintes Generosos e "
                "Especiais.\n\n"
                "Cada nível se subdivide em subníveis (subreino, infraordem, "
                "superfamília etc.). Quanto mais características "
                "compartilhadas os organismos têm, mais próximas são as "
                "categorias.\n\n"
                "CONCEITO DE ESPÉCIE: é a unidade básica da classificação. "
                "Espécies são grupos de organismos semelhantes que se "
                "reproduzem entre si, produzindo descendentes férteis, e "
                "são isoladas reprodutivamente de outras espécies. No "
                "entanto, esse conceito biológico nem sempre se aplica "
                "(bactérias se reproduzem assexuadamente, e algumas espécies "
                "hibridizam).\n\n"
                "MORFOESPÉCIE: conceito baseado apenas em semelhanças "
                "morfológicas. Criouespécie: baseada em histórico "
                "evolutivo e relações de parentesco."
            ),
            "exemplo": (
                "A nomenclatura binomial evita confusão porque o nome "
                "científico é o mesmo em todo o mundo. O urso-pardo, por "
                "exemplo, pode ser chamado de 'grizzly' nos EUA, 'oso "
                "pardo' na Espanha ou 'urso-pardo' no Brasil, mas seu "
                "nome científico é sempre Ursus arctos. O urso-polar, "
                "que era considerado uma espécie separada (Ursus "
                "maritimus), sabe-se hoje que pode hibridizar com o "
                "urso-pardo em regiões de sobreposição (hibridização "
                "grizzly-polar). Isso levanta debates sobre os limites "
                "entre espécies."
            ),
        },
        {
            "titulo": "2. Domínios e Reinos",
            "conteudo": (
                "A classificação mais moderna (baseada em análises "
                "moleculares do RNA ribossômico) divide a vida em três "
                "domínios:\n\n"
                "BACTÉRIA: procariontes (sem núcleo definido). Parede "
                "celular com peptidoglicano. Exemplos: Escherichia coli, "
                "Streptococcus, Cyanobacteria.\n\n"
                "ARCHAEA: procariontes, mas com diferenças bioquímicas "
                "importantes. Parede celular sem peptidoglicano. Vivem em "
                "ambientes extremos (termófilos, halófilos, metanogênicos). "
                "Exemplos: metanogênicos de lama, bactérias de fontes "
                "termais.\n\n"
                "EUKARYA: eucariontes (com núcleo definido). Abrange os "
                "reinos Protista, Fungi, Plantae e Animalia.\n\n"
                "REINOS (sistema de 5 reinos proposto por Whittaker em 1969, "
                "atualizado):\n\n"
                "MONERA (ou Bactéria + Archaea): procariontes, "
                "unicelulares. Reprodução assexuada. Heterotróficos, "
                "autotróficos (quimiossíntese, fotossíntese).\n\n"
                "PROTISTA: eucariontes unicelulares (ou poucas células). "
                "Grupo basal, não natural (parafilético). Inclui protozoários "
                "(heterotróficos), algas (autotróficas) e bolor-do-água. "
                "Exemplos: Paramecium, Amoeba, Plasmodium (malária), "
                "Euglena.\n\n"
                "FUNGI: eucariontes, heterotróficos por absorção (saprofíticos "
                "ou parasitas), parede celular de quitina. Podem ser "
                "unicelulares (leveduras) ou multicelulares (cogumelos, "
                "bolores). Exemplos: Saccharomyces cerevisiae (levedura), "
                "Penicillium, Candida albicans, Agaricus.\n\n"
                "PLANTAE: eucariontes autotróficos fotossintetizantes, "
                "parede celular de celulose, multicelulares. Exemplos: "
                "musgos, samambaias, coníferas, angiospermas.\n\n"
                "ANIMALIA: eucariontes heterotróficos, multicelulares, sem "
                "parede celular. Exemplos: esponjas, insetos, peixes, répteis, "
                "aves, mamíferos.\n\n"
                "CRITÉRIOS DE CLASSIFICAÇÃO DOS REINOS:\n"
                "- Tipo de célula (procarionte/eucarionte);\n"
                "- Número de células (unicelular/multicelular);\n"
                "- Tipo de nutrição (autotrófico/heterotrófico);\n"
                "- Tipo de parede celular."
            ),
            "exemplo": (
                "A classificação correta de fungos é importante para a "
                "Medicina. Os fungos podem causar micoses superficiais "
                "(micose de unha, candidíase), sistêmicas (histoplasmose, "
                "coccidioidomicose) ou oportunistas em pacientes "
                "imunocomprometidos (aspergilose, criptococose). O "
                "antibiótico penicilina vem do fungo Penicillium notatum. "
                "Já os antibióticos que atuam contra bactérias não funcionam "
                "contra fungos, porque o metabolismo do fungo é eucariótico, "
                "similar ao humano — por isso as antifúngicos são mais "
                "tóxicos e menos eficazes."
            ),
        },
        {
            "titulo": "3. O Sistema de Linneu",
            "conteudo": (
                "Carlos Lineu (1707-1778) criou o sistema de classificação "
                "hierárquica e a nomenclatura binomial. Ele publicou "
                "\"Systema Naturae\" (1735), classificando cerca de 7.700 "
                "plantas e 4.400 animais.\n\n"
                "PRINCÍPIOS DO SISTEMA LINNEANO:\n"
                "- Classificação baseada em características morfológicas "
                "(anatomia, fisiologia);\n"
                "- Uso do latim para nomes científicos (linguagem universal "
                "da ciência na época);\n"
                "- Hierarquia taxonômica organizada;\n"
                "- Cada espécie recebe um nome binomial.\n\n"
                "LIMITAÇÕES:\n"
                "- Linneu acreditava na fixação das espécies — não "
                "reconhecia a evolução;\n"
                "- A classificação por semelhanças morfológicas nem sempre "
                "reflete a história evolutiva real;\n"
                "- Organismos com semelhanças convergentes podem ser "
                "agrupados incorretamente.\n\n"
                "EXEMPLOS DE NOMES CIENTÍFICOS:\n"
                "- Homo sapiens: humano moderno.\n"
                "- Canis lupus: lobo.\n"
                "- Canis lupus familiaris: cão doméstico.\n"
                "- Panthera leo: leão.\n"
                "- Panthera tigris: tigre.\n"
                "- Escherichia coli: bactéria do intestino.\n"
                "- Plasmodium falciparum: parasita da malária.\n\n"
                "O sistema de Linneu ainda é usado, mas complementado por "
                "dados moleculares de DNA e RNA."
            ),
            "exemplo": (
                "A nomeação dos patógenos segue a nomenclatura binomial. "
                "Mycobacterium tuberculosis (bactéria que causa tuberculose) "
                "e Mycobacterium leprae (bactéria que causa hanseníase) "
                "pertencem ao mesmo gênero Mycobacterium, mas a espécies "
                "diferentes. Isso indica que elas compartilham muitas "
                "características (parede celular com ácido micólico, "
                "crescimento lento), mas causam doenças distintas. "
                "A tuberculose afeta principalmente os pulmões; a "
                "hanseníase afeta a pele e os nervos."
            ),
        },
        {
            "titulo": "4. Sistemática Filogenética",
            "conteudo": (
                "A sistemática filogenética (ou cladística) classifica os "
                "organismos com base em sua história evolutiva e relações "
                "de parentesco. O objetivo é produzir grupos naturais "
                "(monofiléticos).\n\n"
                "CLADOGRAMA: diagrama que representa as relações evolutivas "
                "entre os organismos. Mostra grupos que compartilham um "
                "ancestral comum. Os ramos indicam linhagens; os nós "
                "indicam ancestrais comuns.\n\n"
                "CARACTERES DERIVADOS (apomorfias): características "
                "evolutivamente novas, que apareceram em um grupo. Exemplo: "
                "quatro membros em tetrapódes, penas em aves, glândulas "
                "mamárias em mamíferos.\n\n"
                "CARACTERES ANCESTRAIS (plesiomorfias): características "
                "antigas, herdadas do ancestral comum. Exemplo: notocorda "
                "em cordados.\n\n"
                "GRUPOS TAXONÔMICOS:\n"
                "- Monofilético (ou natural): inclui o ancestral comum e "
                "TODOS os seus descendentes. Exemplo: mamíferos.\n"
                "- Polifilético: reúne organismos de diferentes ancestrais "
                "por semelhança convergente. Exemplo: 'insetos voadores' "
                "(abelha, borboleta, morcego — o morcego é mamífero).\n"
                "- Parafilético: inclui o ancestral comum, mas NÃO todos os "
                "seus descendentes. Exemplo: répteis (excluem aves, que "
                "surgiram de dinossauros répteis).\n\n"
                "HOMOPLASIA: semelhança que NÃO resulta de ancestral "
                "comum, mas de convergência evolutiva. Exemplo: asas de "
                "aves e de insetos; olhos de polvo e de humano; "
                "condicionamento seco de cactos e euphorbias."
            ),
            "exemplo": (
                "A filogenética molecular revolucionou a classificação. "
                "Análises de DNA mostraram que os hipopótamos são os "
                "parentes vivos mais próximos das baleias, não dos "
                "suínos. Por isso, as baleias foram reclassificadas no "
                "grupo Cetartiodactyla (junto com artiodáctilos como "
                "gado e cervos), e o antigo grupo 'Cetacea' foi "
                "incorporado. Outro exemplo: as aves são, filogeneticamente, "
                "dinossauros (um ramo sobrevivente dos terópodes). Isso "
                "mostra que conceitos morfológicos antigos podem esconder "
                "relações evolutivas."
            ),
        },
        {
            "titulo": "5. Grupos Principais de Plantas e Animais",
            "conteudo": (
                "PLANTAS (divisões principais):\n"
                "- Briófitas (musgos): não têm vasos condutores (avascular). "
                "Dependem da água para reprodução. Gametófito dominante.\n"
                "- Pteridófitas (samambaias, avencas): têm vasos. Não têm "
                "sementes. Esporófito dominante. Reprodução por esporos.\n"
                "- Gimnospermas (pinheiros, cicas): têm sementes, mas não "
                "flores. Sementes desprotegidas (nuas).\n"
                "- Angiospermas (floríferas): têm flores e frutos. Sementes "
                "protegidas pelo fruto. São as mais diversas e abundantes.\n\n"
                "ANIMAIS (filos principais):\n"
                "- Porífera (esponjas): multicelulares, sem tecidos, filtração.\n"
                "- Cnidários (águas-vivas, corais, hidras): simetria radial, "
                "células cnidoblastas.\n"
                "- Platelmitos (planárias, tenias): acelomados, simetria "
                "bilateral.\n"
                "- Nematódeos (lombrigas): pseudocelomados.\n"
                "- Anelídeos (minhocas, sanguessugas): celomados, "
                "metameria.\n"
                "- Moluscos (caracóis, lulas, ostras): celoma, musculo pé, "
                "manto.\n"
                "- Artrópodes (insetos, aranhas, crustáceos): exoesqueleto "
                "de quitina, apêndices articulados. Maior filo em número de "
                "espécies.\n"
                "- Equinodermos (estrelas-do-mar, ouriços): simetria radial "
                "adulta, sistema ambulacral.\n"
                "- Cordados (peixes, anfíbios, répteis, aves, mamíferos): "
                "notocorda em alguma fase da vida. Vertebrados são um "
                "subgrupo.\n\n"
                "Importante: vírus NÃO são seres vivos — não têm "
                "metabolismo próprio e dependem de células hospedeiras. "
                "Prions e viroides também não são vivos."
            ),
            "exemplo": (
                "A identificação de artrópodes vetores de doenças exige "
                "conhecimento de Sistemática. A malária é transmitida pelo "
                "Anopheles (ordem Diptera, família Culicidae), enquanto a "
                "dengue, zika e chikungunya são transmitidas pelo Aedes "
                "aegypti (mesma ordem e família, gênero diferente). "
                "Conhecer a taxonomia permite identificar corretamente o "
                "vetor e aplicar o controle adequado. Por exemplo, o Aedes "
                "aegypti reproduz em água limpa e parada (vasos de plantas, "
                "pneus, garrafas), enquanto o Anopheles prefere água limpa "
                "com algas."
            ),
        },
    ],
    "resumo": (
        "- Taxonomia: classifica, nomeia e identifica. Nomenclatura binomial: Gênero + espécie.\n"
        "- Categorias: Reino, Filo, Classe, Ordem, Família, Gênero, Espécie.\n"
        "- Domínios: Bacteria, Archaea, Eukarya. Reinos: Monera, Protista, Fungi, Plantae, Animalia.\n"
        "- Linneu: criou nomenclatura binomial e hierarquia. Baseada em morfologia.\n"
        "- Filogenética: classifica por história evolutiva. Cladograma, apomorfias, plesiomorfias.\n"
        "- Grupos: monofilético (natural), polifilético (convergência), parafilético (sem todos descendentes).\n"
        "- Plantas: briófitas, pteridófitas, gimnospermas, angiospermas.\n"
        "- Animais: porífera, cnidários, platelmintos, nematódeos, anelídeos, moluscos, artrópodes, equinodermos, cordados.\n"
        "- Vírus não são seres vivos."
    ),
    "dicas": [
        "Decore a hierarquia taxonômica: Reino, Filo, Classe, Ordem, Família, Gênero, Espécie.",
        "Nomenclatura binomial: gênero maiúsculo, espécie minúscula. Homo sapiens, Canis lupus, Felis catus.",
        "Archaea e Bactéria são procariontes. Diferença: parede celular (peptidoglicano nas bactérias).",
        "Monofilético = ancestral + todos descendentes. Parafilético = ancestral + alguns descendentes. Polifilético = sem ancestral comum.",
        "Angiospermas = flores e frutos. Gimnospermas = sementes nuas. Briófitas = sem vasos. Pteridófitas = vasos, sem sementes.",
        "Artrópodes são o maior filo. Insetos = 6 patas; aranhas = 8 patas; crustáceos = mais de 10 patas (decápodes).",
    ],
    "pegadinhas": [
        "Achar que vírus e bactérias são classificados no reino Animalia: vírus não são vivos; bactérias são Monera.",
        "Confundir fungos com plantas: fungos são heterotróficos por absorção, parede de quitina (não celulose).",
        "Achar que Linneu entendia evolução: ele acreditava na fixação das espécies (imutáveis).",
        "Confundir monofilético com polifilético: monofilético tem ancestral comum real; polifilético não.",
        "Esquecer que artrópodes têm exoesqueleto de QUITINA, não de celulose (plantas) nem cartilagem.",
        "Achar que plantas sem sementes são briófitas: briófitas não têm vasos; pteridófitas têm vasos mas não têm sementes.",
    ],
    "referencias": [
        "RIDLEY, M. Evolução. 3. ed. Porto Alegre: Artmed, 2009.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "MARGULIS, L.; SCHWARTZ, K. V. Cinco Reinos: Uma Guia Ilustrada dos Filos da Vida na Terra. 3. ed. Rio de Janeiro: Guanabara Koogan, 2011.",
        "JUDD, W. S. et al. Sistemática Vegetal: Um Enfoque Filogenético. 3. ed. Porto Alegre: Artmed, 2009.",
        "HICKMAN, C. P. et al. Princípios Integrados de Zoologia. 15. ed. Rio de Janeiro: Guanabara Koogan, 2016.",
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Classificação e Sistemática")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CLASSIFICACAO_SISTEMATICA.pdf"

    images_data = [
        {"file": "br_cls_taxonomia.jpg",
         "caption": "Hierarquia taxonômica: das categorias mais amplas às mais específicas",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/classificacao-dos-seres-vivos.htm"},
        {"file": "br_cls_reinos.jpg",
         "caption": "Classificação dos seres vivos em cinco reinos",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/classificacao-dos-seres-vivos/"},
        {"file": "br_cls_arvore.jpg",
         "caption": "Árvore filogenética: relações evolutivas entre os seres vivos",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/filogenia.htm"},
        {"file": "br_cls_grupos_plantas.jpg",
         "caption": "Grupos de plantas: briófitas, pteridófitas, gimnospermas e angiospermas",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/reino-plantae.htm"},
        {"file": "br_cls_exec20.jpg",
         "caption": "Classificação dos seres vivos: reino, filo, classe, ordem, família, gênero e espécie",
         "source": "InfoEscola",
         "source_url": "https://www.infoescola.com/zoologia/vertebrados/"},
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
