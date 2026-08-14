# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Ciclo Celular (Mitose e Meiose).

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
    "titulo": "Ciclo Celular — Mitose e Meiose",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Ciclo Celular",
    "introducao": (
        "O ciclo celular é a sequência de eventos que ocorre desde a formação de "
        "uma célula até ela se dividir em duas células-filhas. Ele é dividido em "
        "duas grandes fases: a intérfase (período de crescimento e duplicação do "
        "DNA) e a divisão celular (mitose ou meiose, com a citocinese).\n\n"
        "A mitose é a divisão equacional: uma célula diploide (2n) origina duas "
        "células-filhas diploides (2n) geneticamente idênticas à célula-mãe. "
        "É responsável pelo crescimento, regeneração e reprodução assexuada.\n\n"
        "A meiose é a divisão reducional: uma célula diploide (2n) origina quatro "
        "células-filhas haploides (n), geneticamente diferentes entre si. É "
        "responsável pela formação dos gametas e pela variabilidade genética.\n\n"
        "Compreender o ciclo celular é essencial para a Medicina: o câncer "
        "resulta da perda de controle do ciclo celular, e vários quimioterápicos "
        "atuam em fases específicas da divisão."
    ),
    "secoes": [
        {
            "titulo": "1. Intérfase",
            "conteudo": (
                "A intérfase é o período entre duas divisões celulares. Embora "
                "antigamente fosse chamada de \"fase de repouso\", a célula é "
                "intensamente ativa: cresce, sintetiza proteínas e duplica o "
                "DNA. Divide-se em três subfases:\n\n"
                "G1 (Gap 1): período de crescimento celular. A célula aumenta "
                "de volume, sintetiza proteínas e organelas. A duração varia "
                "muito: algumas células passam horas em G1, outras permanecem "
                "indefinidamente em um estado chamado G0 (células que não se "
                "dividem mais, como neurônios e fibras musculares cardíacas).\n\n"
                "S (Síntese): duplicação do DNA. Cada cromossomo é replicado, "
                "formando duas cromátides irmãs idênticas ligadas pelo "
                "centromero. Ao final, a célula continua com 46 cromossomos, "
                "mas cada um tem duas cromátides. Dura cerca de 6-8 horas em "
                "células humanas.\n\n"
                "G2 (Gap 2): período de crescimento adicional e preparação "
                "para a divisão. A célula sintetiza as proteínas necessárias "
                "para a mitose (como tubulina para os microtúbulos do fuso). "
                "Dura cerca de 2-5 horas.\n\n"
                "PONTO DE CHECAGEM: ao final de G1, a célula avalia se tem "
                "condições de se dividir (tamanho adequado, DNA intacto, "
                "sinais externos favoráveis). Se não, entra em G0 ou aguarda. "
                "Em G2, há outro ponto de checagem: verifica se o DNA foi "
                "duplicado corretamente. Esses pontos são controlados por "
                "proteínas como p53 — o \"guardião do genoma\"."
            ),
            "exemplo": (
                "A p53 é uma proteína supressora de tumor que atua no ponto de "
                "checagem G1. Se o DNA está danificado, a p53 interrompe o "
                "ciclo celular e ativa a reparação do DNA. Se o dano é "
                "irreparável, a p53 induz a apoptose (morte celular programada). "
                "Mutações no gene p53 estão presentes em mais de 50% dos "
                "cânceres humanos — sem a p53 funcional, células com DNA "
                "danificado continuam se dividindo, acumulando mutações e "
                "formando tumores."
            ),
        },
        {
            "titulo": "2. Mitose",
            "conteudo": (
                "A mitose é a divisão do núcleo que produz duas células-filhas "
                "geneticamente idênticas à célula-mãe. Ocorre em células "
                "somáticas (do corpo) e é dividida em cinco fases:\n\n"
                "PRÓFASE: a cromatina se condensa em cromossomos visíveis. O "
                "envoltório nuclear se desfunde. O centrossomo se duplica e "
                "os dois pares de centríolos migram para os polos da célula, "
                "formando o fuso mitótico (feixe de microtúbulos). Os "
                "microtúbulos se conectam aos cromossomos pelo cinetócoro "
                "(proteína no centromero).\n\n"
                "PROMETÁFASE: os microtúbulos do fuso se conectam aos "
                "cromossomos e os movem para o equador da célula.\n\n"
                "METÁFASE: os cromossomos alinham-se no equador da célula "
                "(placa equatorial). Esta é a fase em que os cromossomos estão "
                "mais condensados e visíveis — é o momento ideal para "
                "montar o cariótipo.\n\n"
                "ANÁFASE: as cromátides irmãs se separam (o centromero se "
                "divide) e são puxadas para os polos opostos pelos "
                "microtúbulos do fuso, que encurtam. Cada polo recebe um "
                "conjunto completo de 46 cromossomos (agora com uma só "
                "cromátide).\n\n"
                "TELÓFASE: os cromossomos chegaram aos polos e se "
                "descondensam. O envoltório nuclear se reorganiza ao redor "
                "de cada conjunto. O fuso mitótico se desfaz. O nucléolo "
                "reaparece.\n\n"
                "CITOCINESE: divisão do citoplasma, que geralmente começa "
                "na anáfase e se completa na telófase. Em células animais, "
                "ocorre por estrangulamento: um anel de actina e miosina "
                "contrai-se no equador, dividindo a célula em duas. Em "
                "células vegetais, ocorre por formação de uma placa celular "
                "(fragmoplasto) no equador, que cresce de dentro para fora "
                "até se encontrar com a parede celular."
            ),
            "exemplo": (
                "A colchicina e o Taxol (paclitaxel) são exemplos de drogas "
                "que atuam na mitose. A colchicina inibe a polimerização dos "
                "microtúbulos, impedindo a formação do fuso — por isso é usada "
                "para parar a divisão na metáfase ao montar cariótipos. O "
                "Taxol estabiliza os microtúbulos, impedindo seu encurtamento "
                "na anáfase — usado em quimioterapia para bloquear a divisão "
                "de células tumorais. Outros quimioterápicos, como a "
                "vincristina e a vinblastina, também inibem o fuso mitótico."
            ),
        },
        {
            "titulo": "3. Meiose",
            "conteudo": (
                "A meiose é a divisão celular que produz gametas (espermatozoides "
                "e óvulos) e esporos. É uma divisão reducional: uma célula "
                "diploide (2n) origina quatro células haploides (n). É composta "
                "por duas divisões consecutivas — meiose I e meiose II — sem "
                "duplicação do DNA entre elas.\n\n"
                "MEIOSE I (reducional):\n"
                "Prófase I: a fase mais longa e complexa. Divide-se em cinco "
                "subfases: leptóteno (cromossomos começam a condensar), "
                "zigóteno (homólogos se pareiam — sinapse), paquíteno "
                "(ocorre o crossing-over: troca de segmentos entre cromátides "
                "não irmãs de cromossomos homólogos), diplotêno (homólogos "
                "começam a se separar, mas permanecem unidos nos pontos de "
                "crossing-over — quiasmas) e diacinese (condensação máxima, "
                "envoltório nuclear desaparece).\n"
                "Metáfase I: os pares de homólogos (bivalentes ou tétrades) "
                "alinham-se no equador da célula.\n"
                "Anáfase I: os cromossomos homólogos se separam (cada um vai "
                "para um polo com suas duas cromátides ainda unidas). É aqui "
                "que ocorre a redução do número de cromossomos: de 2n para n.\n"
                "Telófase I: formam-se dois núcleos haploides, cada um com "
                "n cromossomos (cada um com duas cromátides). Citocinese.\n\n"
                "MEIOSE II (equacional): é semelhante à mitose, mas ocorre em "
                "células haploides.\n"
                "Prófase II: condensação, envoltório desaparece, fuso se forma.\n"
                "Metáfase II: cromossomos alinham-se no equador.\n"
                "Anáfase II: cromátides irmãs se separam.\n"
                "Telófase II: formam-se quatro núcleos haploides, cada um com "
                "n cromossomos (uma cromátide cada). Citocinese.\n\n"
                "RESULTADO: quatro células haploides, geneticamente diferentes "
                "entre si e da célula-mãe."
            ),
            "exemplo": (
                "O crossing-over é a principal fonte de variabilidade genética "
                "na meiose. Ao trocar segmentos entre cromossomos homólogos, "
                "gera combinações alélicas novas. Sem crossing-over, os "
                "cromossomos que herdamos do pai e da mãe seriam transmitidos "
                "intactos. Com ele, cada gameta recebe cromossomos \"mestiços\" "
                "— parte do avô paterno, parte da avó paterna, por exemplo. "
                "Isso, somado à segregação independente dos homólogos, explica "
                "porque cada gameta é único e porque irmãos não são idênticos "
                "(exceto gêmeos monozigóticos)."
            ),
        },
        {
            "titulo": "4. Importância da Meiose e Variabilidade",
            "conteudo": (
                "A meiose tem duas funções essenciais: reduzir o número de "
                "cromossomos pela metade (para que, na fecundação, se restaure "
                "o número diploide) e gerar variabilidade genética. A "
                "variabilidade resulta de três mecanismos:\n\n"
                "CROSSING-OVER: na prófase I, cromossomos homólogos trocam "
                "segmentos. Cada crossing-over gera cromossomos recombinantes, "
                "com combinações alélicas que não existiam nos pais. Ocorre "
                "em média 2-3 crossing-overs por par de cromossomos em humanos.\n\n"
                "SEGREGAÇÃO INDEPENDENTE: na anáfase I, cada par de homólogos "
                "se orienta independentemente dos demais. Para 23 pares, há "
                "2^23 (mais de 8 milhões) de combinações possíveis só por "
                "esse mecanismo. Somado ao crossing-over, a variabilidade é "
                "praticamente infinita.\n\n"
                "FECUNDAÇÃO AO ACASO: qualquer um dos milhões de "
                "espermatozoides pode fecundar qualquer um dos óvulos, "
                "multiplicando ainda mais a variabilidade.\n\n"
                "SEM MEIOSE: sem a meiose, a reprodução sexuada não seria "
                "possível. Se os gametas fossem diploides, a fecundação "
                "produziria 4n, depois 8n, e assim por diante — o número de "
                "cromossomos dobraria a cada geração. A meiose mantém o "
                "número constante ao longo das gerações."
            ),
            "exemplo": (
                "A variabilidade genética é a matéria-prima da evolução por "
                "seleção natural. Sem variabilidade, todas as células seriam "
                "idênticas e uma única pressão ambiental (como uma nova "
                "doença) poderia extinguir a espécie. Com variabilidade, "
                "alguns indivíduos podem ter características que os tornam "
                "resistentes — e sobrevivem para transmitir esses genes. É "
                "por isso que a reprodução sexuada (com meiose) é tão "
                "bem-sucedida na natureza, apesar de ser mais complexa que "
                "a assexuada."
            ),
        },
        {
            "titulo": "5. Mitose vs. Meiose — Comparação",
            "conteudo": (
                "MITOSE:\n"
                "- Uma divisão celular (prófase, metáfase, anáfase, telófase);\n"
                "- Resultado: 2 células-filhas;\n"
                "- Ploidia: 2n → 2n (mantém o número de cromossomos);\n"
                "- Cromátides irmãs se separam na anáfase;\n"
                "- Não há pareamento de homólogos nem crossing-over;\n"
                "- Células-filhas geneticamente idênticas à célula-mãe;\n"
                "- Ocorre em células somáticas;\n"
                "- Função: crescimento, regeneração, reprodução assexuada.\n\n"
                "MEIOSE:\n"
                "- Duas divisões consecutivas (meiose I e II);\n"
                "- Resultado: 4 células-filhas;\n"
                "- Ploidia: 2n → n (reduz pela metade);\n"
                "- Homólogos se separam na anáfase I; cromátides irmãs na anáfase II;\n"
                "- Há pareamento de homólogos (sinapse) e crossing-over na prófase I;\n"
                "- Células-filhas geneticamente diferentes entre si e da célula-mãe;\n"
                "- Ocorre em células germinativas (germinativas);\n"
                "- Função: formação de gametas, variabilidade genética.\n\n"
                "DURAÇÃO: a mitose dura geralmente 1-2 horas. A meiose é "
                "muito mais longa — pode durar dias, semanas ou até anos. "
                "Na mulher, a meiose da ovogênese começa na vida fetal e "
                "só se completa na ovulação, décadas depois."
            ),
            "exemplo": (
                "Na ovogênese, as ovogônias entram em meiose I ainda na vida "
                "fetal, mas param no diplotêno da prófase I (estágio "
                "dictióteno). A meiose só prossegue a partir da puberdade, "
                "a cada ciclo menstrual: um ovócito completa a meiose I e "
                "começa a meiose II, mas para na metáfase II. Só termina a "
                "meiose II se for fecundado. Por isso, uma mulher de 40 anos "
                "tem ovócitos \"presos\" na prófase I há 40 anos — o que "
                "explica o aumento de aneuploidias (como a síndrome de Down) "
                "com a idade materna: quanto mais tempo os cromossomos "
                "permanecem pareados, maior o risco de nãodisjunção."
            ),
        },
    ],
    "resumo": (
        "- Intérfase: G1 (crescimento) → S (duplicação do DNA) → G2 (preparação para divisão).\n"
        "- Mitose: prófase, metáfase, anáfase, telófase + citocinese. 2n → 2n, 2 células idênticas.\n"
        "- Meiose: duas divisões (I reducional, II equacional). 2n → n, 4 células diferentes.\n"
        "- Prófase I: leptóteno, zigóteno, paquíteno (crossing-over), diplotêno (quiasmas), diacinese.\n"
        "- Anáfase I: homólogos se separam (redução). Anáfase II: cromátides irmãs se separam.\n"
        "- Crossing-over + segregação independente = variabilidade genética.\n"
        "- Mitose: células somáticas, crescimento. Meiose: gametas, reprodução sexuada.\n"
        "- p53 controla o ponto de checagem G1; mutações em p53 causam câncer."
    ),
    "dicas": [
        "Decore as fases da mitose: Pró-Met-Ana-Telo. \"PMA-T\" — Prófase, Metáfase, Anáfase, Telófase.",
        "Na mitose, cromátides irmãs se separam na anáfase. Na meiose I, homólogos se separam na anáfase I; na meiose II, cromátides irmãs na anáfase II.",
        "Crossing-over ocorre na prófase I da meiose (paquíteno). É a principal fonte de variabilidade.",
        "Mitose = 2 células idênticas, 2n. Meiose = 4 células diferentes, n. Decore esta diferença!",
        "Citocinese em animais = estrangulamento (actina/miosina). Em vegetais = placa celular (fragmoplasto).",
        "p53 = guardião do genoma. Mutado em 50%+ dos cânceres. Controla G1.",
    ],
    "pegadinhas": [
        "Confundir anáfase da mitose com anáfase I da meiose: na mitose, cromátides irmãs se separam; na meiose I, cromossomos homólogos se separam (cada um com duas cromátides).",
        "Achar que a intérfase é \"repouso\": a célula cresce e duplica o DNA em S. É a fase mais longa do ciclo.",
        "Esquecer que a meiose II é equacional (igual à mitose): só ocorre em células haploides.",
        "Confundir crossing-over (entre cromátides não irmãs de homólogos) com segregação independente (orientação ao acaso dos pares na metáfase I).",
        "Achar que a citocinese é uma fase da mitose: ela é um processo paralelo, que se inicia na anáfase e termina na telófase.",
        "Esquecer que a meiose feminina para na prófase I (dictióteno) e só termina se houver fecundação.",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "NELSON, D. L.; COX, M. M. Lehninger Princípios de Bioquímica. 7. ed. São Paulo: Sarvier, 2017.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "GRIFFITHS, A. J. F. et al. Introdução à Genética. 11. ed. Rio de Janeiro: Guanabara Koogan, 2018.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Ciclo Celular")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_CICLO_CELULAR.pdf"

    images_data = [
        {"file": "br_ciclo_celular_be.jpg",
         "caption": "Ciclo celular: intérfase (G1, S, G2) e mitose com pontos de checagem",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/ciclo-celular.htm"},
        {"file": "br_mitose_fases.jpg",
         "caption": "Fases da mitose: prófase, metáfase, anáfase e telófase",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/mitose.htm"},
        {"file": "br_mitose_citocinese.jpg",
         "caption": "Citocinese em células animais (estrangulamento) e vegetais (placa celular)",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/mitose.htm"},
        {"file": "br_meiose_etapas.jpg",
         "caption": "Etapas da meiose I e II: divisão reducional seguida de equacional",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/meiose.htm"},
        {"file": "br_meiose_crossing.jpg",
         "caption": "Crossing-over: troca de segmentos entre cromossomos homólogos na prófase I",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/meiose.htm"},
        {"file": "br_ciclo_interfase_mitose.jpg",
         "caption": "Intérfase e mitose: visão geral do ciclo celular",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/ciclo-celular/"},
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
        fontSize=22, textColor=PRIMARY, spaceAfter=6, alignment=TA_CENTER)
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
