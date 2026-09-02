"""Gera PDF profissional ABNT do material de Biologia - Genética.

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
    "titulo": "Genética",
    "disciplina": "Biologia",
    "topico": "Genética",
    "subtopico": "Conceitos, Leis de Mendel, Herança, Mutações e Biotecnologia",
    "introducao": (
        "A Genética é a área da Biologia que estuda a hereditariedade, "
        "a variabilidade dos seres vivos e a expressão dos genes. "
        "Desde os experimentos de Gregor Mendel com ervilhas, no "
        "século XIX, a genética revolucionou a compreensão da vida.\n\n"
        "Na Medicina, a genética é fundamental para entender doenças "
        "hereditárias, predisposições a câncer, diagnóstico pré-natal, "
        "terapia gênica, medicina personalizada e a produção de "
        "medicamentos por organismos geneticamente modificados."
    ),
    "secoes": [
        {
            "titulo": "1. Conceitos Fundamentais",
            "conteudo": (
                "GENE: unidade fundamental da hereditariedade. É um "
                "segmento de DNA que contém a informação para a síntese "
                "de uma proteína ou RNA funcional. Os genes ocupam "
                "posições específicas nos cromossomos (locus).\n\n"
                "ALELOS: formas alternativas de um gene. Exemplo: gene "
                "da cor da flor da ervilha tem alelos B (roxa) e b "
                "(branca). O genótipo é o conjunto de alelos de um "
                "indivíduo; o fenótipo é a expressão observável.\n\n"
                "CROMOSSOMOS: estruturas formadas por DNA e proteínas "
                "(histonas). Os humanos têm 46 cromossomos (23 pares), "
                "sendo 22 pares de autossomos e 1 par de cromossomos "
                "sexuais (XX ou XY).\n\n"
                "GENOTIPO E FENOTIPO:\n"
                "- Genótipo: conjunto de alelos (ex.: AA, Aa, aa).\n"
                "- Fenótipo: característica observável (cor, altura, "
                "doença).\n"
                "- Fenótipo é resultado de genótipo + ambiente.\n\n"
                "HOMOZIGOTO E HETEROZIGOTO:\n"
                "- Homozigoto: alelos iguais (AA ou aa).\n"
                "- Heterozigoto: alelos diferentes (Aa).\n\n"
                "DOMINÂNCIA E RECESSIVIDADE: o alelo dominante se "
                "expressa no fenótipo mesmo na presença de um alelo "
                "recessivo. O recessivo só se expressa quando em "
                "duas cópias (homozigoto).\n\n"
                "GENOMA: todo o material genético de um organismo. "
                "Proteoma: todas as proteínas. Transcriptoma: todos os "
                "RNAs. Metaboloma: todos os metabólitos."
            ),
            "exemplo": (
                "Na fibrose cística, a doença só ocorre quando o "
                "indivíduo é homozigoto recessivo (cc) para o gene "
                "CFTR. Heterozigotos (Cc) são assintomáticos, mas "
                "portadores. Em populações europeias, cerca de 1 em 25 "
                "pessoas são portadoras. Por isso, o teste de "
                "heterozigose é feito em casais com história familiar "
                "para calcular o risco de filhos afetados (25% se ambos "
                "forem portadores)."
            ),
        },
        {
            "titulo": "2. Leis de Mendel",
            "conteudo": (
                "Gregor Mendel, monge austríaco, deduziu as leis da "
                "herança a partir de cruzamentos com ervilhas "
                "(Pisum sativum). Publicou o trabalho em 1866, mas só "
                "foi reconhecido em 1900.\n\n"
                "PRIMEIRA LEI (Lei da Segregação dos Fatores): cada "
                "característica é determinada por um par de fatores "
                "(alelos), que se separam na formação dos gametas. "
                "Cada gameta recebe apenas um fator. Cruzamento "
                "monohíbrido: P (AA x aa) → F1 (todos Aa) → F2 (3:1, "
                "se A dominante).\n\n"
                "SEGUNDA LEI (Lei da Independência dos Fatores): os "
                "fatores para características diferentes se separam de "
                "forma independente na formação dos gametas, desde que "
                "em cromossomos diferentes. Cruzamento dihíbrido: AaBb "
                "x AaBb → F2 com razão 9:3:3:1 (fenotípica).\n\n"
                "TIPOS DE CROUZAMENTO:\n"
                "- Monohíbrido: 1 característica, 2 alelos.\n"
                "- Dihíbrido: 2 características, 4 alelos.\n"
                "- Testcross: cruzamento de um indivíduo de fenótipo "
                "dominante com um recessivo, para descobrir o genótipo.\n"
                "- Retrocruzamento: cruzamento de F1 com um dos genitores.\n\n"
                "LIMITAÇÃO: as leis de Mendel valem para genes em "
                "cromossomos diferentes. Genes no mesmo cromossomo "
                "estão ligados (linkage) e tendem a ser herdados juntos, "
                "a menos que ocorra crossing-over."
            ),
            "exemplo": (
                "O grupo sanguíneo ABO é um exemplo de herança com "
                "alelos múltiplos e dominância incompleta. Os alelos "
                "IA e IB são codominantes entre si, mas dominantes sobre "
                "i. Assim, o genótipo IAIB produz fenótipo AB, enquanto "
                "IAi e IBi produzem A e B, respectivamente. O genótipo "
                "ii produz tipo O. Na doação de sangue, quem é tipo O "
                "é doador universal; quem é AB é receptor universal. "
                "Isso explica por que transfundir sangue incompatível "
                "pode causar reação aguda de hemólise."
            ),
        },
        {
            "titulo": "3. Interações Gênicas e Herança",
            "conteudo": (
                "INTERAÇÃO ALÉLICA:\n"
                "- Dominância completa: AA e Aa têm o mesmo fenótipo.\n"
                "- Codominância: ambos os alelos se expressam (grupo "
                "sanguíneo AB).\n"
                "- Dominância incompleta: fenótipo intermediário (flores "
                "de milho rosa entre vermelha e branca).\n"
                "- Alelos letais: causam morte quando homozigotos.\n"
                "- Alelos múltiplos: mais de 2 alelos para um gene (ABO, "
                "cor do pelo de coelhos).\n\n"
                "INTERAÇÃO GÊNICA NÃO ALÉLICA: genes de diferentes "
                "loci atuam juntos. Epistasia: um gene mascara a ação "
                "de outro. Complementariedade: dois genes precisam "
                "atuar juntos para uma cor. Herança poligênica: vários "
                "genes atuam em uma mesma característica (altura, cor "
                "da pele, pressão arterial).\n\n"
                "HERANÇA LIGADA AO SEXO: genes localizados no X ou Y. "
                "Doenças recessivas ligadas ao X afetam mais homens "
                "(XY têm um único X). Exemplos: hemofilia, daltonismo, "
                "distrofia muscular de Duchenne, síndrome do X frágil.\n\n"
                "HERANÇA MITOCONDRIAL: DNA mitocondrial é herdado "
                "exclusivamente da mãe. Doenças: síndrome de MELAS, "
                "síndrome de Leigh, doença de Kearns-Sayre.\n\n"
                "GENÉTICA QUANTITATIVA: características com variação "
                "contínua, influenciadas por muitos genes e ambiente. "
                "Altura, peso, pressão arterial, glicemia."
            ),
            "exemplo": (
                "A distrofia muscular de Duchenne (DMD) é uma doença "
                "recessiva ligada ao X. Homens (XY) com um X mutado já "
                "manifestam a doença; mulheres (XX) são geralmente "
                "portadoras, pois o X normal compensa. A mãe portadora "
                "tem 50% de chance de transmitir o X mutado a cada filho "
                "(que ficará doente) e 50% de chance de transmitir a "
                "cada filha (que será portadora). Por isso, o "
                "aconselhamento genético é essencial em famílias com "
                "histórico de doenças ligadas ao X."
            ),
        },
        {
            "titulo": "4. Mutações e Cariótipos",
            "conteudo": (
                "MUTAÇÃO: alteração na sequência de DNA. Podem ser "
                "pontuais (em um único nucleotídeo) ou cromossômicas.\n\n"
                "MUTAÇÕES PONTUAIS:\n"
                "- Substituição: troca de um nucleotídeo. Pode ser "
                "silenciosa, missense (muda aminoácido), nonsense "
                "(cria códon de parada), de início (perde início).\n"
                "- Deleção: perda de um nucleotídeo. Pode causar "
                "mudança do quadro de leitura (frameshift).\n"
                "- Inserção: adição de um nucleotídeo. Também pode "
                "causar frameshift.\n\n"
                "MUTAÇÕES CROMOSSÔMICAS:\n"
                "- Deleção de cromossomo;\n"
                "- Duplicação;\n"
                "- Inversão;\n"
                "- Translocação (trocas entre cromossomos);\n"
                "- Aneuploidia (alteração no número de cromossomos — "
                "síndrome de Down = trissomia 21, síndrome de Turner = "
                "monossomia X, síndrome de Klinefelter = XXY).\n\n"
                "MUTAGÊNESES: causas de mutação — radiação UV, raios X, "
                "substâncias químicas (benzeno, aflatoxina), vírus, "
                "erros na replicação do DNA, reagentes oxidantes.\n\n"
                "REPARO DO DNA: as células têm mecanismos de reparo "
                "(reparo por excisão, pareamento, recominação). Falhas "
                "no reparo aumentam o risco de câncer (síndromes de "
                "predisposição a tumores).\n\n"
                "CITOGENÉTICA: estudo dos cromossomos. O cariótipo "
                "permite identificar aneuploidias, translocações e "
                "rearranjos."
            ),
            "exemplo": (
                "A BRCA1 e BRCA2 são genes supressores de tumores que "
                "reparam danos no DNA. Mutações nesses genes aumentam "
                "o risco de câncer de mama, ovário, próstata e pâncreas. "
                "Mulheres com mutação BRCA1 têm risco de até 70% de "
                "câncer de mama até os 80 anos. Por isso, mulheres com "
                "história familiar forte devem fazer teste genético e, "
                "se positivas, acompanhamento intensivo ou cirurgia "
                "profilática (mastectomia, salpingo-ooforectomia)."
            ),
        },
        {
            "titulo": "5. Engenharia Genética e Biotecnologia",
            "conteudo": (
                "A engenharia genética permite manipular o DNA de "
                "organismos. Técnicas modernas revolucionaram a "
                "medicina, agricultura e indústria.\n\n"
                "PRINCIPAIS TÉCNICAS:\n"
                "- DNA recombinante: inserção de um gene de interesse "
                "em um plasmídeo ou vetor, introduzido em bactérias "
                "(clonagem).\n"
                "- PCR (Reação em Cadeia da Polimerase): amplifica "
                "segmentos específicos de DNA, permitindo diagnóstico "
                "de doenças, forense, identificação de patógenos.\n"
                "- Eletroforese em gel: separa fragmentos de DNA por "
                "tamanho.\n"
                "- Sequenciamento de DNA: determina a ordem dos "
                "nucleotídeos (Sanger, NGS — next-generation sequencing).\n"
                "- CRISPR-Cas9: ferramenta de edição gênica que permite "
                "cortar e modificar DNA com precisão. Usada em "
                "pesquisa, terapia gênica e desenvolvimento de "
                "modelos animais de doenças.\n"
                "- Clonagem: produção de cópias geneticamente idênticas "
                "(Dolly, ovelha clonada).\n"
                "- Terapia gênica: introdução de genes funcionais em "
                "células de pacientes com doenças genéticas.\n\n"
                "APLICAÇÕES MÉDICAS:\n"
                "- Produção de insulina humana em bactérias (E. coli "
                "recombinante);\n"
                "- Vacinas recombinantes (hepatite B, HPV);\n"
                "- Fator VIII recombinante para hemofilia;\n"
                "- Diagnóstico genético pré-natal e pré-implantacional;\n"
                "- Medicina de precisão/oncologia (alvo molecular, "
                "imunoterapia);\n"
                "- Cultura de tecidos e órgãos artificiais.\n\n"
                "ALIMENTOS TRANSGÊNICOS: organismos geneticamente "
                "modificados (OGMs). Exemplos: soja tolerante a "
                "glifosato, milho Bt resistente a pragas, arroz "
                "dourado (enriquecido em vitamina A). Há debates sobre "
                "segurança e impacto ambiental, mas organismos "
                "reguladores os avaliam cientificamente."
            ),
            "exemplo": (
                "A insulina humana recombinante revolucionou o "
                "tratamento do diabetes tipo 1. Antes, a insulina vinha "
                "de pâncreas de porcos e vacas, causando alergias e "
                "resistência. Com a engenharia genética, a bactéria "
                "Escherichia coli é transformada com o gene da insulina "
                "humana e produz o hormônio em quantidade industrial. "
                "Essa mesma tecnologia produz fator VIII, hormônios, "
                "vacinas e anticorpos monoclonais, reduzindo custos e "
                "aumentando a segurança."
            ),
        },
    ],
    "resumo": (
        "- Genes ocupam loci; alelos são formas alternativas. Genótipo → fenótipo.\n"
        "- 1ª Lei de Mendel: segregação dos alelos nos gametas (monohíbrido 3:1).\n"
        "- 2ª Lei de Mendel: independência de genes em cromossomos diferentes (9:3:3:1).\n"
        "- Dominância completa, incompleta, codominância, alelos múltiplos, epistasia.\n"
        "- Herança ligada ao X: hemofilia, daltonismo, DMD. Herança mitocondrial: apenas materna.\n"
        "- Mutações pontuais: substituição, deleção, inserção. Mutações cromossômicas: aneuploidias, translocações.\n"
        "- PCR, DNA recombinante, CRISPR, clonagem, terapia gênica. Insulina e vacinas recombinantes."
    ),
    "dicas": [
        "Cruzamento monohíbrido F2: 3:1 (fenótipo) e 1:2:1 (genótipo).",
        "Cruzamento dihíbrido F2: 9:3:3:1 (fenótipo) e 1:2:1:2:4:2:1:2:1 (genótipo).",
        "Codominância: os dois alelos se expressam juntos (sangue AB).",
        "Doenças ligadas ao X afetam mais homens; mãe portadora transmite 50% para filhos e filhas.",
        "Síndrome de Down = trissomia 21 (47 cromossomos); Turner = 45,X; Klinefelter = 47,XXY.",
        "CRISPR-Cas9 é a ferramenta de edição gênica mais precisa. Corte do DNA no local desejado.",
    ],
    "pegadinhas": [
        "Confundir dominância incompleta com codominância: incompleta = intermediário; codominância = ambos aparecem.",
        "Esquecer que a 2ª Lei de Mendel não vale para genes ligados (no mesmo cromossomo).",
        "Achar que homozigoto dominante e heterozigoto têm fenótipos diferentes: na dominância completa, são iguais.",
        "Confundir herança mitocondrial com autossômica: mitocôndrias vêm só da mãe.",
        "Achar que mutações são sempre ruins: muitas são silenciosas; algumas são benéficas e fornecem variabilidade.",
        "Confundir terapia gênica com clonagem: terapia gênica corrige genes; clonagem produz cópias idênticas.",
    ],
    "referencias": [
        "GRIFFITHS, A. J. F. et al. Introdução à Genética. 10. ed. Rio de Janeiro: Guanabara Koogan, 2013.",
        "SNUSTAD, D. P.; SIMMONS, M. J. Princípios de Genética. 7. ed. Rio de Janeiro: Guanabara Koogan, 2015.",
        "ALBERTS, B. et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "WATSON, J. D. et al. Biologia Molecular do Gene. 7. ed. Porto Alegre: Artmed, 2013.",
        "THOMPSON, M. W. et al. Genética Médica. 7. ed. Rio de Janeiro: Guanabara Koogan, 2010.",
        "PRITCHARD, D. J.; KORF, B. R. Genética Médica. 5. ed. Porto Alegre: Artmed, 2014.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Genética")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_GENETICA.pdf"

    images_data = [
        {"file": "br_gen_conceitos.jpg",
         "caption": "Conceitos fundamentais de Genética: gene, DNA, cromossomos e hereditariedade",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/genética.htm"},
        {"file": "br_gen_ervilha.jpg",
         "caption": "Cruzamento de ervilhas: experimentos de Mendel com cor e textura",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/leis-de-mendel/"},
        {"file": "br_gen_primeira_lei.jpg",
         "caption": "Primeira Lei de Mendel: segregação dos alelos nos gametas",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/leis-de-mendel/"},
        {"file": "br_gen_dna_recombinante.jpg",
         "caption": "DNA recombinante: inserção de genes em vetores bacterianos",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/engenharia-genetica/"},
        {"file": "br_gen_biotecnologia.jpg",
         "caption": "Biotecnologia: aplicações da engenharia genética na medicina e agricultura",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/engenharia-genetica/"},
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
