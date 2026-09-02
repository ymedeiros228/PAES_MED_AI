"""Gera PDF profissional ABNT do material de Biologia - Anomalias Cromossômicas.

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
    "titulo": "Anomalias Cromossômicas",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Anomalias Cromossômicas",
    "introducao": (
        "As anomalias cromossômicas são alterações no número ou na estrutura dos "
        "cromossomos. Elas ocorrem durante a divisão celular (mitose ou meiose) "
        "e podem ser herdadas dos pais ou surgir espontaneamente. São uma das "
        "principais causas de aborto espontâneo, malformações congênitas e "
        "deficiências intelectuais.\n\n"
        "Estima-se que cerca de 1 em 150 recém-nascidos tenha alguma anomalia "
        "cromossômica, e que até 50% dos abortos espontâneos do primeiro "
        "trimestre sejam causados por alterações cromossômicas. Por isso, o "
        "estudo dessas anomalias é essencial para a Medicina — especialmente "
        "para a genética clínica, a obstetrícia e a pediatria.\n\n"
        "As anomalias cromossômicas dividem-se em dois grandes grupos: "
        "numéricas (aneuploidias e euploidias) e estruturais (deleções, "
        "duplicações, translocações, inversões). Cada uma tem características "
        "próprias e consequências clínicas distintas."
    ),
    "secoes": [
        {
            "titulo": "1. Anomalias Numéricas — Aneuploidias",
            "conteudo": (
                "As aneuploidias são alterações no número de cromossomos em que "
                "há um cromossomo a mais ou a menos (não múltiplo inteiro do "
                "número haploide n). Resultam de erros na separação dos "
                "cromossomos durante a divisão celular — processo chamado "
                "nãodisjunção.\n\n"
                "NÃODISJUNÇÃO NA MEIOSE I: os cromossomos homólogos não se "
                "separam. Ambos vão para o mesmo polo. Resultado: dois gametas "
                "com n+1 cromossomos e dois com n-1.\n\n"
                "NÃODISJUNÇÃO NA MEIOSE II: as cromátides irmãs não se separam. "
                "Resultado: um gameta com n+1, um com n-1 e dois normais.\n\n"
                "NÃODISJUNÇÃO NA MITOSE: ocorre nas primeiras divisões do zigoto. "
                "Pode gerar mosaicismo — quando o indivíduo tem duas linhagens "
                "celulares diferentes (uma normal e uma aneuploide). Exemplo: "
                "mosaico de Down (parte das células tem 46 e parte tem 47 "
                "cromossomos).\n\n"
                "TIPOS DE ANEUPLOIDIA:\n"
                "- Monossomia (2n-1): falta um cromossomo. Em humanos, a única "
                "monossomia autossômica é letal. A única compatível com a vida "
                "é a monossomia do X (síndrome de Turner, 45,X).\n"
                "- Trissomia (2n+1): sobra um cromossomo. É o tipo mais comum. "
                "Exemplos: trissomia do 21 (Down), do 18 (Edwards), do 13 "
                "(Patau) e dos cromossomos sexuais (XXX, XXY, XYY).\n"
                "- Tetrassomia (2n+2): sobram dois cromossomos. Rara.\n\n"
                "A gravidade da aneuploidia depende do cromossomo afetado. "
                "Cromossomos grandes têm muitos genes — sua trissomia causa "
                "desequilíbrio enorme e é geralmente letal. Cromossomos "
                "pequenos (como o 21, o menor) têm poucos genes — por isso a "
                "trissomia do 21 é a mais comum e compatível com a vida."
            ),
            "exemplo": (
                "A frequência de nãodisjunção aumenta com a idade materna. "
                "Isso ocorre porque os ovócitos ficam parados na prófase I da "
                "meiose desde a vida fetal. Quanto mais tempo os cromossomos "
                "permanecem pareados, maior o risco de falha na separação. "
                "Por isso, o risco de síndrome de Down é de 1 em 1.250 aos "
                "25 anos, mas sobe para 1 em 30 aos 45 anos. Esse fato é a "
                "base dos programas de rastreamento pré-natal para mulheres "
                "acima de 35 anos."
            ),
        },
        {
            "titulo": "2. Síndrome de Down (Trissomia do 21)",
            "conteudo": (
                "A síndrome de Down é a aneuploidia autossômica mais comum e "
                "mais conhecida. Foi descrita pelo médico inglês John Langdon "
                "Down em 1866. A causa genética (trissomia do 21) só foi "
                "descoberta em 1959 por Jérôme Lejeune.\n\n"
                "CARIÓTIPO: 47,XX,+21 (fêmea) ou 47,XY,+21 (macho). Em 95% dos "
                "casos, a trissomia é livre (cromossomo 21 extra). Em 4% dos "
                "casos, é por translocação (o cromossomo 21 extra está ligado "
                "a outro cromossomo, geralmente o 14). Em 1% dos casos, é "
                "mosaico (parte das células normal, parte trissômica).\n\n"
                "CARACTERÍSTICAS CLÍNICAS:\n"
                "- Fisionomia: fendas palpebrais oblíquas (puxadas para cima), "
                "epicanto (prega de pele no canto interno do olho), ponte "
                "nasal achatada, orelhas pequenas e de implantação baixa, "
                "boca pequena com língua protusa (macroglossia);\n"
                "- Hipotonia (tônus muscular reduzido) desde o nascimento;\n"
                "- Prega palmar única (linha simiesca) em uma ou ambas as mãos;\n"
                "- Cardiopatias congênitas em cerca de 40-50% dos casos "
                "(principalmente defeito do septo atrioventricular);\n"
                "- Deficiência intelectual de grau variável (geralmente leve "
                "a moderado);\n"
                "- Maior risco de leucemia na infância e de Alzheimer precoce "
                "(o gene da APP, no cromossomo 21, leva à produção excessiva "
                "de proteína amiloide);\n"
                "- Hipotireoidismo e problemas digestivos comuns.\n\n"
                "EXPECTATIVA DE VIDA: com os avanços da medicina (cirurgia "
                "cardíaca, tratamento de infecções), a expectativa de vida "
                "passou de menos de 10 anos na década de 1950 para mais de "
                "60 anos atualmente."
            ),
            "exemplo": (
                "A translocação na síndrome de Down tem importância genética: "
                "enquanto a trissomia livre é esporádica (risco de repetição "
                "baixo, cerca de 1%), a translocação pode ser herdada de um "
                "pai ou mãe portador de translocação equilibrada. Nesses "
                "casos, o risco de repetição em futuras gestações pode chegar "
                "a 10-15%. Por isso, todo recém-nascido com Down deve ter o "
                "cariótipo feito para determinar o tipo — e os pais devem ser "
                "testados se for translocação."
            ),
        },
        {
            "titulo": "3. Síndromes de Edwards e Patau",
            "conteudo": (
                "SÍNDROME DE EDWARDS (Trissomia do 18):\n"
                "Cariótipo: 47,XX,+18 ou 47,XY,+18. É a segunda trissomia "
                "autossômica mais comum, com incidência de 1 em 6.000 "
                "nascimentos. Mais comum em filhos de mães idosas.\n\n"
                "Características: defeitos graves do desenvolvimento, "
                "microcefalia (cabeça pequena), orelhas mal formadas e baixas, "
                "micrognatia (queixo pequeno), defeitos cardíacos congênitos "
                "(90% dos casos), pé boto, dedos sobrepostos (mãos fechadas "
                "com dedos cruzados), retardo mental severo. A maioria nasce "
                "com baixo peso. A expectativa de vida é muito curta: "
                "cerca de 50% morrem antes dos 2 meses e apenas 5-10% "
                "sobrevivem ao primeiro ano.\n\n"
                "SÍNDROME DE PATAU (Trissomia do 13):\n"
                "Cariótipo: 47,XX,+13 ou 47,XY,+13. Incidência de 1 em "
                "10.000 nascimentos. Também mais comum em mães idosas.\n\n"
                "Características: defeitos muito graves do desenvolvimento, "
                "incluindo holoprosencefalia (o cérebro não se divide em dois "
                "hemisférios), fenda labial e palatina, polidactilia (dedos "
                "extra), microftalmia (olhos pequenos) ou anoftalmia (ausência "
                "de olhos), defeitos cardíacos congênitos (80% dos casos), "
                "rins policísticos. A expectativa de vida é extremamente "
                "curta: a maioria morre nas primeiras semanas de vida, "
                "apenas 5-10% sobrevivem ao primeiro ano.\n\n"
                "Ambas as síndromes são consideradas incompatíveis com a vida "
                "a longo prazo. Por isso, o diagnóstico pré-natal é "
                "importante para preparar a família e a equipe médica."
            ),
            "exemplo": (
                "O diagnóstico pré-natal dessas trissomias pode ser feito por:\n"
                "1. NIPT (teste não invasivo): analisa DNA fetal no sangue "
                "materno a partir de 10 semanas. Sensibilidade >99% para "
                "Down, Edwards e Patau, sem risco para o feto.\n"
                "2. Ultrassom morfológico: procura marcadores como "
                "translucência nucal aumentada (acima de 3,5 mm), ossos "
                "nasais ausentes e defeitos cardíacos.\n"
                "3. Amniocentese ou vilo corial: exame invasivo com "
                "cariótipo fetal, confirmatório. Tem pequeno risco de "
                "aborto (0,5-1%)."
            ),
        },
        {
            "titulo": "4. Anomalias dos Cromossomos Sexuais",
            "conteudo": (
                "As anomalias dos cromossomos sexuais são geralmente menos "
                "graves que as autossômicas, porque o cromossomo Y tem poucos "
                "genes e um dos cromossomos X é inativado nas fêmeas (corpúsculo "
                "de Barr). Por isso, indivíduos com cromossomos sexuais extra "
                "sobrevivem e têm fenótipo relativamente normal.\n\n"
                "SÍNDROME DE TURNER (45,X):\n"
                "Monossomia do X. Incidência: 1 em 2.500 meninas. A única "
                "monossomia compatível com a vida em humanos.\n"
                "Características: fenótipo feminino, baixa estatura (cerca de "
                "1,45 m sem tratamento), disgenesia gonadal (ovários não se "
                "desenvolvem — são faixas fibrosas), amenorreia primária "
                "(não menstruam), infertilidade, pescoço alado (pregas de pele "
                "no pescoço), tórax largo com mamilos distantes, linfedema "
                "de mãos e pés ao nascimento. A inteligência é geralmente "
                "normal. Tratamento: hormônio de crescimento na infância e "
                "estrogênio na puberdade para desenvolver características "
                "sexuais.\n\n"
                "SÍNDROME DE KLINEFELTER (47,XXY):\n"
                "Trissomia dos cromossomos sexuais. Incidência: 1 em 500 a "
                "1.000 homens. É a anomalia cromossômica mais comum.\n"
                "Características: fenótipo masculino, mas com características "
                "femininas: ginecomastia (desenvolvimento de mamas), "
                "testículos pequenos e firmes, infertilidade (azospermia — "
                "não produzem espermatozoides), baixa produção de testosterona, "
                "estatura alta, pernas longas, pouco pelos corporais. A "
                "inteligência é geralmente normal, mas pode haver leve "
                "deficiência cognitiva. Tratamento: reposição de testosterona.\n\n"
                "SÍNDROME DO TRIPLO X (47,XXX):\n"
                "Fêmeas com três cromossomos X. Incidência: 1 em 1.000. "
                "Geralmente assintomática — fenótipo normal, fertilidade "
                "normal. Pode haver leve deficiência intelectual. Muitas "
                "mulheres com 47,XXX nunca são diagnosticadas.\n\n"
                "SÍNDROME DE JACOBS (47,XYY):\n"
                "Machos com dois cromossomos Y. Incidência: 1 em 1.000. "
                "Fenótipo masculino normal, estatura alta, fertilidade "
                "normal. Pode haver leve deficiência intelectual e problemas "
                "de comportamento. Antigamente achava-se que causava "
                "agressividade (síndrome do \"macho extra Y\"), mas isso "
                "foi desmentido — a maioria leva vida normal."
            ),
            "exemplo": (
                "Corpúsculo de Barr: nas fêmeas normais (XX), um dos "
                "cromossomos X é inativado ao acaso em cada célula, "
                "formando uma massa de cromatina condensada visível no "
                "núcleo — o corpúsculo de Barr. Por isso, fêmeas têm 1 "
                "corpúsculo de Barr e machos (XY) não têm nenhum. Na "
                "síndrome de Turner (45,X), não há corpúsculo de Barr. "
                "Na síndrome de Klinefelter (47,XXY), há 1 corpúsculo de "
                "Barr (mesmo sendo macho). No triplo X (47,XXX), há 2. "
                "Essa regra é útil para diagnóstico rápido: número de "
                "corpúsculos de Barr = número de cromossomos X - 1."
            ),
        },
        {
            "titulo": "5. Anomalias Estruturais",
            "conteudo": (
                "As anomalias estruturais são alterações na estrutura de um "
                "cromossomo, sem mudar o número total. Resultam de quebras "
                "do DNA seguidas de reparo incorreto. Os principais tipos:\n\n"
                "DELEÇÃO: perda de um segmento do cromossomo. O indivíduo "
                "tem apenas uma cópia dos genes da região deletada (haplo-"
                "insuficiência). Exemplos:\n"
                "- Síndrome do cri-du-chat (5p-): deleção do braço curto do "
                "cromossomo 5. Características: choro semelhante ao miado "
                "de gato (devido a anomalia da laringe), microcefalia, "
                "deficiência intelectual severa, fendas faciais.\n"
                "- Síndrome de Wolf-Hirschhorn (4p-): deleção do braço curto "
                "do cromossomo 4. Características: deficiência intelectual, "
                "convulsões, malformações.\n"
                "- Síndrome de DiGeorge (22q11.2): microdeleção do "
                "cromossomo 22. Causa imunodeficiência (sem timo), "
                "cardiopatias, fendas palatais, hipocalcemia.\n\n"
                "DUPLICAÇÃO: um segmento do cromossomo é duplicado, "
                "resultando em três cópias dos genes daquela região. "
                "Pode causar desequilíbrio genético.\n\n"
                "TRANSLOCAÇÃO: troca de segmentos entre cromossomos não "
                "homólogos. Pode ser:\n"
                "- Recíproca: dois cromossomos trocam pedaços. Se não houver "
                "perda de material, é equilibrada (o portador é normal, mas "
                "pode gerar filhos com anomalias);\n"
                "- Robertsoniana: dois cromossomos acrocêntricos se fundem "
                "próximo ao centromero. O portador tem 45 cromossomos, mas é "
                "fenotipicamente normal. Pode gerar filhos com trissomia "
                "(exemplo: translocação do 21 com o 14 causa Down familiar).\n\n"
                "INVERSÃO: um segmento do cromossomo é invertido (gira 180°). "
                "Pode ser paracêntrica (não inclui o centromero) ou "
                "pericêntrica (inclui o centromero). Geralmente não causa "
                "problemas no portador, mas pode gerar gametas anormais por "
                "problemas no pareamento durante a meiose.\n\n"
                "ANEL: um cromossomo perde as duas extremidades (telômeros) "
                "e as pontas se unem, formando um anel. Geralmente causa "
                "anomalias porque há perda de material nas extremidades."
            ),
            "exemplo": (
                "O cromossomo Philadelphia é uma translocação recíproca "
                "entre os cromossomos 9 e 22 — t(9;22)(q34;q11). O gene ABL "
                "do cromossomo 9 se funde com o gene BCR do cromossomo 22, "
                "formando o gene quimérico BCR-ABL. Esse gene produz uma "
                "proteína com atividade tirosina quinase constitutiva, que "
                "estimula a proliferação celular sem controle — causando a "
                "leucemia mieloide crônica (LMC). O imatinibe (Gleevec) "
                "inibe essa proteína e revolucionou o tratamento da LMC, "
                "convertendo uma doença fatal em uma condição controlável. "
                "É um dos maiores exemplos de terapia alvo molecular em "
                "oncologia."
            ),
        },
    ],
    "resumo": (
        "- Aneuploidias: nãodisjunção na meiose I (homólogos) ou II (cromátides irmãs).\n"
        "- Monossomia (2n-1): Turner (45,X) — única compatível com a vida.\n"
        "- Trissomias: Down (21), Edwards (18), Patau (13). Down é a mais comum e compatível com a vida.\n"
        "- Cromossomos sexuais: Turner (45,X), Klinefelter (47,XXY), Triplo X (47,XXX), Jacobs (47,XYY).\n"
        "- Corpúsculo de Barr = número de X - 1. Fêmeas XX = 1; macho XY = 0; Klinefelter XXY = 1.\n"
        "- Deleções: cri-du-chat (5p-), Wolf-Hirschhorn (4p-), DiGeorge (22q11.2).\n"
        "- Translocações: recíproca, robertsoniana. Philadelphia t(9;22) causa leucemia mieloide crônica.\n"
        "- Inversões: paracêntrica (sem centromero) e pericêntrica (com centromero).\n"
        "- Idade materna > 35 anos aumenta o risco de aneuploidias."
    ),
    "dicas": [
        "Decore as trissomias: Down = 21, Edwards = 18, Patau = 13. Down é a mais comum e leve.",
        "Corpúsculo de Barr = número de cromossomos X - 1. XX = 1, XY = 0, XXY = 1, XXX = 2, X0 = 0.",
        "Turner (45,X) é a única monossomia compatível com a vida. Klinefelter (47,XXY) é a anomalia cromossômica mais comum.",
        "Cri-du-chat = deleção 5p. O nome vem do choro de gato (anomalia da laringe).",
        "Cromossomo Philadelphia = t(9;22) → leucemia mieloide crônica. Gene BCR-ABL. Tratamento: imatinibe.",
        "Translocação equilibrada: portador é normal, mas pode gerar filhos com anomalias. Importante em aconselhamento genético.",
    ],
    "pegadinhas": [
        "Confundir nãodisjunção na meiose I (homólogos não se separam) com na meiose II (cromátides irmãs não se separam).",
        "Achar que a síndrome de Turner é trissomia: é monossomia (45,X) — falta um cromossomo X.",
        "Esquecer que a translocação na síndrome de Down pode ser familiar (risco de repetição alto), enquanto a trissomia livre é esporádica.",
        "Confundir inversão paracêntrica (não inclui centromero) com pericêntrica (inclui centromero).",
        "Achar que o cromossomo Y extra (47,XYY) causa agressividade: mito desmentido. O fenótipo é praticamente normal.",
        "Esquecer que as trissomias de cromossomos grandes (1, 2, 3...) são letais — só as de cromossomos pequenos (21, 18, 13) permitem sobrevivência.",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "GRIFFITHS, A. J. F. et al. Introdução à Genética. 11. ed. Rio de Janeiro: Guanabara Koogan, 2018.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "MOORE, K. L.; PERSAUD, T. V. N. Embriologia Clínica. 10. ed. Rio de Janeiro: Elsevier, 2016.",
        "Nussbaum, R. L.; McInnes, R. R.; Willard, H. F. Thompson & Thompson Genética Médica. 8. ed. Rio de Janeiro: Guanabara Koogan, 2016.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Anomalias Cromossômicas")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_ANOMALIAS_CROMOSSOMICAS.pdf"

    images_data = [
        {"file": "br_ano_cariotipo_normal.jpg",
         "caption": "Cariótipo humano normal: 46 cromossomos (44 autossomos + XX ou XY)",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/cariotipo.htm"},
        {"file": "br_ano_cariotipo_down.jpg",
         "caption": "Cariótipo da síndrome de Down: trissomia do cromossomo 21 (47,XX,+21)",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/aneuploidia.htm"},
        {"file": "br_ano_turner_cariotipo.jpg",
         "caption": "Cariótipo da síndrome de Turner: monossomia do X (45,X)",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/sindrome-de-turner.htm"},
        {"file": "br_ano_patau.jpg",
         "caption": "Síndrome de Patau: trissomia do cromossomo 13",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/sindrome-de-patau/"},
        {"file": "br_ano_alteracoes1.jpg",
         "caption": "Alterações cromossômicas estruturais: deleção, duplicação, translocação e inversão",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/alteracoes-cromossomicas/"},
        {"file": "br_ano_alteracoes2.jpg",
         "caption": "Tipos de anomalias cromossômicas estruturais e suas consequências",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/alteracoes-cromossomicas/"},
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
