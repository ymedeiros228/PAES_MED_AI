# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Evolução.

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
    "titulo": "Evolução",
    "disciplina": "Biologia",
    "topico": "Evolução",
    "subtopico": "Teorias, Seleção Natural, Especiação, Evidências e Evolução Humana",
    "introducao": (
        "A Evolução é o processo de mudanças nas características "
        "hereditárias das populações ao longo das gerações. É o "
        "princípio unificador da Biologia: todas as formas de vida "
        "compartilham um ancestral comum e se diversificaram por "
        "processos evolutivos.\n\n"
        "A compreensão da evolução é fundamental para a Medicina "
        "moderna. Ela explica a resistência bacteriana a antibióticos, "
        "a emergência de novas doenças virais, as predisposições "
        "genéticas, a resposta imune e as semelhanças anatômicas "
        "entre espécies, que permitem o uso de modelos animais em "
        "pesquisa biomédica."
    ),
    "secoes": [
        {
            "titulo": "1. Teorias Evolutivas",
            "conteudo": (
                "LAMARCKISMO: Jean-Baptiste Lamarck (1744-1829) propôs "
                "que os seres vivos evoluíam por herança de "
                "características adquiridas. Segundo ele, o uso "
                "intenso de um órgão o desenvolveria, e o desuso o "
                "atenuaria; essas modificações seriam transmitidas aos "
                "descendentes. O exemplo clássico é a girafa: o "
                "esticamento do pescoço ao alcançar folhas altas "
                "geraria descendentes com pescoço mais longo. "
                "Lamarckismo foi refutado pela genética moderna, pois "
                "as características adquiridas não alteram o DNA "
                "germinativo. No entanto, Lamarck foi pioneiro ao "
                "propor que os seres vivos se modificam ao longo do "
                "tempo.\n\n"
                "DARWINISMO: Charles Darwin (1809-1882) e Alfred "
                "Russel Wallace propuseram a seleção natural como "
                "mecanismo evolutivo. A obra 'A Origem das Espécies' "
                "(1859) fundamentou a biologia evolutiva. Darwin "
                "desenvolveu a teoria após a viagem no HMS Beagle, "
                "observando os tentilhões das ilhas Galápagos.\n\n"
                "PRINCÍPIOS DO DARWINISMO:\n"
                "1. Variabilidade: os indivíduos de uma população apresentam "
                "diferenças;\n"
                "2. Hereditariedade: as diferenças são passadas às "
                "gerações;\n"
                "3. Superpopulação: nascem mais indivíduos do que podem "
                "sobreviver;\n"
                "4. Luta pela existência: competição por recursos;\n"
                "5. Diferencial de sobrevivência e reprodução: os "
                "indivíduos mais adaptados deixam mais descendentes.\n\n"
                "NEODARWINISMO (Síntese Moderna): união da seleção "
                "natural com a genética. A variação vem das mutações; "
                "a seleção atua sobre essas variações. Outros "
                "mecanismos evolutivos são reconhecidos: deriva "
                "genética, fluxo gênico, endogamia, seleção sexual."
            ),
            "exemplo": (
                "A resistência de bactérias aos antibióticos é evolução "
                "em tempo real. Uma população bacteriana apresenta "
                "variação: algumas células têm mutações que conferem "
                "resistência. Quando expostas ao antibiótico, as "
                "suscetíveis morrem e as resistentes sobrevivem e "
                "se reproduzem. Em poucas horas, a população torna-se "
                "predominantemente resistente. Por isso, o uso "
                "indevido de antibióticos acelera a evolução de "
                "superbactérias — um problema de saúde pública global."
            ),
        },
        {
            "titulo": "2. Seleção Natural e Outros Mecanismos",
            "conteudo": (
                "SELEÇÃO NATURAL: mecanismo em que os indivíduos com "
                "características mais vantajosas para o ambiente "
                "deixam mais descendentes. Tipos:\n"
                "- Estabilizadora: favorece os indivíduos intermediários, "
                "reduzindo a variação (ex.: peso ao nascer em humanos).\n"
                "- Direcional: favorece um dos extremos, deslocando a "
                "média (ex.: bicos de tentilhões durante secas).\n"
                "- Disruptiva: favorece os dois extremos, aumentando a "
                "variação (ex.: caranguejos com grandes ou pequenas "
                "conchas, dependendo de predadores).\n\n"
                "OUTROS MECANISMOS:\n"
                "- Deriva genética: mudanças aleatórias nas frequências "
                "alélicas, especialmente em populações pequenas. O "
                "efeito fundador ocorre quando um grupo pequeno "
                "coloniza uma nova área. O efeito gargalo ocorre após "
                "redução drástica da população.\n"
                "- Fluxo gênico: troca de genes entre populações por "
                "migração. Aumenta a variabilidade.\n"
                "- Mutação: origem da variabilidade genética. Todas as "
                "outras variações derivam dela.\n"
                "- Endogamia: reprodução entre parentes. Aumenta a "
                "frequência de homozigotos e pode revelar alelos "
                "recessivos deletérios.\n"
                "- Seleção sexual: escolha de parceiros por "
                "características que aumentam o sucesso reprodutivo, "
                "mesmo que não aumentem a sobrevivência (cauda de "
                "pavão, canto de pássaros).\n\n"
                "EQUILÍBRIO DE HARDY-WEINBERG: descreve uma população "
                "que não está evoluindo. Condições: população grande, "
                "acaso não atua, sem mutação, sem migração, sem seleção, "
                "reprodução aleatória. Frequências: p² + 2pq + q² = 1 "
                "e p + q = 1, onde p e q são frequências dos alelos."
            ),
            "exemplo": (
                "O famoso estudo dos tentilhões de Galápagos mostrou "
                "seleção direcional. Durante secas prolongadas, as "
                "ervilhas secas e duras ficam mais comuns. Os "
                "tentilhões com bicos maiores e mais fortes conseguem "
                "quebrá-las e sobrevivem melhor. Após gerações, a "
                "média do tamanho do bico aumenta. Quando chove e as "
                "sementes pequenas voltam a abundar, a seleção pode "
                "mudar de direção. Isso mostra que a seleção natural "
                "não é progressiva, mas responde ao ambiente."
            ),
        },
        {
            "titulo": "3. Especiação",
            "conteudo": (
                "Especiação é o processo pelo qual uma espécie dá "
                "origem a novas espécies. Requer isolamento "
                "reprodutivo: as populações deixam de trocar genes e "
                "acumulam diferenças.\n\n"
                "MECANISMOS DE ISOLAMENTO:\n"
                "- Pré-zigóticos: ocorrem antes da fecundação. "
                "Ecológicos (hábitats diferentes), temporais (épocas "
                "diferentes de reprodução), comportamentais "
                "(cantos/rituais diferentes), mecânicos "
                "(incompatibilidade de órgãos), gaméticos "
                "(espermatozoides não fertilizam óvulos).\n"
                "- Pós-zigóticos: ocorrem após a fecundação. Hibridismo "
                "invável (zigoto morre), hibridismo estéril (mula, "
                "híbrido estéril), degradação (descendentes menos "
                "adaptados).\n\n"
                "TIPOS DE ESPECIAÇÃO:\n"
                "- Alopátrica: separação por barreira geográfica (rios, "
                "montanhas, oceanos). É a forma mais comum.\n"
                "- Simpátrica: sem barreira geográfica; pode ocorrer por "
                "poliploidia (comum em plantas) ou especialização "
                "ecológica.\n"
                "- Parapátrica: populações adjacentes em gradientes "
                "ambientais.\n"
                "- Peripátrica: população periférica isolada (efeito "
                "fundador).\n\n"
                "CONCEITO BIOLÓGICO DE ESPÉCIE: grupo de populações que "
                "se cruzam naturalmente, produzindo descendentes férteis, "
                "e são reproductivamente isoladas de outros grupos. "
                "Outros conceitos: ecológica, filogenética, morfológica."
            ),
            "exemplo": (
                "As ciclídeos do Lago Vitória, na África, são um exemplo "
                "de especiação simpátrica. Cerca de 500 espécies "
                "surgiram em poucos milhares de anos, provavelmente por "
                "especialização ecológica e escolha sexual. Diferentes "
                "espécies têm cores, tamanhos e preferências "
                "alimentares distintas. Esse lago demonstra como "
                "pequenas populações podem se diversificar "
                "rapidamente quando submetidas a pressões ecológicas e "
                "reprodutivas."
            ),
        },
        {
            "titulo": "4. Evidências da Evolução",
            "conteudo": (
                "As evidências da evolução vêm de várias áreas da "
                "biologia e da geologia:\n\n"
                "FÓSSEIS: restos preservados de organismos antigos. "
                "Mostram mudanças ao longo do tempo e transições entre "
                "grupos (arqueoptérix — réptil com penas; Tiktaalik — "
                "peixe com membros; Australopithecus — hominídeo "
                "bípede). A datação é feita pela posição nas camadas "
                "(estratigrafia) e métodos radiométricos.\n\n"
                "ANATOMIA COMPARADA: homologia (estruturas com mesma "
                "origem embrionária, mas funções diferentes — asa de "
                "morcego, nadadeira de baleia, braço humano). "
                "Analogia (funções semelhantes, origens diferentes — "
                "asa de abelha e asa de ave; olho de polvo e olho de "
                "humano). Vestigialidade (órgãos reduzidos — apêndice, "
                "dentes do siso, ossos do rabo).\n\n"
                "EMBRIOLOGIA COMPARADA: embriões de vertebrados são "
                "muito semelhantes nas fases iniciais, indicando "
                "ancestral comum. Fendas faríngeas, cauda e notocorda "
                "aparecem em peixes, anfíbios, répteis, aves e "
                "mamíferos.\n\n"
                "BIOGEOGRAFIA: distribuição geográfica das espécies. "
                "Espécies em ilhas próximas são mais relacionadas entre "
                "si do que com espécies de continentes com clima "
                "semelhante.\n\n"
                "BIOQUÍMICA E GENÉTICA MOLECULAR: DNA e proteínas são "
                "semelhantes entre espécies próximas. O citocromo c, "
                "uma proteína respiratória, difere em poucos "
                "aminoácidos entre humanos e chimpanzés, mas em muitos "
                "entre humanos e leveduras. Genomas mostram a árvore "
                "evolutiva com precisão."
            ),
            "exemplo": (
                "O gene FOXP2 está relacionado à linguagem. O gene é "
                "quase idêntico em humanos e chimpanzés — apenas 2 "
                "aminoácidos diferem. Mutações em FOXP2 causam "
                "distúrbios de fala e linguagem em humanos. A "
                "comparação genética confirma que humanos e "
                "chimpanzés compartilham cerca de 98,7% do DNA. Essa "
                "homologia molecular é uma das evidências mais fortes "
                "da evolução e do parentesco próximo entre primatas."
            ),
        },
        {
            "titulo": "5. Evolução Humana",
            "conteudo": (
                "Os humanos pertencem à ordem Primates, família "
                "Hominidae. Nossos parentes vivos mais próximos são os "
                "chimpanzés e bonobos, com os quais compartilhamos um "
                "ancestral comum há cerca de 6-7 milhões de anos.\n\n"
                "TRAJETÓRIA EVOLUTIVA (fósseis principais):\n"
                "- Sahelanthropus (7 milhões de anos): possível "
                "hominídeo bípede.\n"
                "- Ardipithecus (4,4 milhões): bípede, mas com dedos "
                "curvados para escalada.\n"
                "- Australopithecus (4-2 milhões): bípede completo. "
                "A. afarensis ('Lucy') viveu há 3,2 milhões de anos.\n"
                "- Homo habilis (2,4-1,4 milhões): 'homem hábil'. "
                "Usava ferramentas de pedra.\n"
                "- Homo erectus (1,9 milhões - 100 mil): fogo, ferramentas "
                "Avanceadas, migração para fora da África.\n"
                "- Homo neanderthalensis (400-40 mil): parente próximo, "
                "viveu na Europa e Ásia. Extinto. Hibridização com "
                "humanos modernos.\n"
                "- Homo sapiens (300 mil anos - presente): humanos "
                "modernos. Origem na África, migração pelo mundo.\n\n"
                "CARACTERÍSTICAS HUMANAS: bipedalismo, cérebro grande "
                "em relação ao corpo, uso de ferramentas, linguagem "
                "simbólica, cultura, fogo, organização social complexa.\n\n"
                "SAÍDA DA ÁFRICA: humanos modernos migraram da África há "
                "cerca de 60-70 mil anos. Encontraram e hibridizaram "
                "com neandertais e denisovanos. Hoje, povos fora da "
                "África carregam 1-4% de DNA neandertal."
            ),
            "exemplo": (
                "A evolução da lactase persistente é um exemplo clássico "
                "de evolução recente (últimos 10 mil anos). Na "
                "infância, todos produzem lactase para digerir o leite. "
                "Em populações de pastores, a seleção natural favoreceu "
                "a manutenção da lactase na vida adulta (lactase "
                "persistente), porque a capacidade de beber leite "
                "oferecia vantagem nutricional. Hoje, cerca de 35% dos "
                "humanos adultos são tolerantes à lactose, com maior "
                "frequência em populações europeias e de pastores "
                "africanos."
            ),
        },
    ],
    "resumo": (
        "- Lamarckismo: herança de características adquiridas — refutado.\n"
        "- Darwinismo: seleção natural agindo sobre variações hereditárias.\n"
        "- Neodarwinismo: seleção + genética (mutação, deriva, fluxo gênico, seleção sexual).\n"
        "- Seleção: estabilizadora, direcional, disruptiva. Hardy-Weinberg: população sem evolução.\n"
        "- Especiação: requer isolamento reprodutivo (pré ou pós-zigótico). Alopátrica é a mais comum.\n"
        "- Evidências: fósseis, anatomia comparada (homologia/analogia), embriologia, biogeografia, genética molecular.\n"
        "- Evolução humana: bípedalismo, cérebro grande, ferramentas, linguagem. Saída da África e hibridização."
    ),
    "dicas": [
        "Darwin propôs seleção natural; Lamarck propôs uso e desuso + herança de características adquiridas.",
        "Seleção natural NÃO é aleatória: atua sobre variações geradas aleatoriamente pelas mutações.",
        "Deriva genética é mais forte em populações pequenas (efeito fundador, gargalo).",
        "Homologia = mesma origem, função diferente. Analogia = mesma função, origem diferente.",
        "Especiação alopátrica = barreira geográfica. Simpátrica = mesmo ambiente (poliploidia em plantas).",
        "Humanos e chimpanzés compartilham ~98,7% do DNA. Divergiram há ~6-7 milhões de anos.",
    ],
    "pegadinhas": [
        "Achar que seleção natural faz os seres 'melhorarem' absolutamente: ela favorece o que é adaptado AO AMBIENTE, não a perfeição.",
        "Confundir homologia com analogia: homologia = origem comum; analogia = convergência (asa de abelha vs ave).",
        "Achar que evolução é sinônimo de progresso: a evolução é mudança nas frequências alélicas, não melhora linear.",
        "Esquecer que seleção sexual pode favorecer características desvantajosas para a sobrevivência (cauda do pavão).",
        "Achar que os humanos evoluíram dos macacos atuais: humanos e macacos compartilham ancestral comum, mas não somos descendentes dos atuais.",
        "Confundir endogamia com seleção natural: endogamia é reprodução entre parentes, não um mecanismo adaptativo de evolução.",
    ],
    "referencias": [
        "DARWIN, C. A Origem das Espécies. Tradução: L. D. V. São Paulo: Editora 34, 2009.",
        "RIDLEY, M. Evolução. 3. ed. Porto Alegre: Artmed, 2009.",
        "FUTUYMA, D. J. Biologia Evolutiva. 4. ed. Ribeirão Preto: Sociedade Brasileira de Genética, 2013.",
        "GOULD, S. J. A Diversidade da Vida. São Paulo: Companhia das Letras, 1999.",
        "STRINGER, C. A Origem dos Humanos Modernos. Lisboa: Fim de Século, 2013.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Evolução")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_EVOLUCAO.pdf"

    images_data = [
        {"file": "br_evo_darwinismo.jpg",
         "caption": "Darwinismo: seleção natural como mecanismo evolutivo",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/darwinismo/"},
        {"file": "br_evo_tentilhoes.jpg",
         "caption": "Tentilhões de Galápagos: exemplo clássico de seleção natural",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/selecao-natural.htm"},
        {"file": "br_evo_selecao.jpg",
         "caption": "Mecanismos da evolução: seleção natural, deriva e fluxo gênico",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/selecao-natural/"},
        {"file": "br_evo_selecao2.jpg",
         "caption": "Seleção natural: variações hereditárias e adaptação ao ambiente",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/selecao-natural.htm"},
        {"file": "br_evo_hominideos.jpg",
         "caption": "Evolução humana: linhagem dos hominídeos e fósseis",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/teoria-da-evolucao/"},
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
