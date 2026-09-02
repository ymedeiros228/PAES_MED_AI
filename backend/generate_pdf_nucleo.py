"""Gera PDF profissional ABNT do material de Biologia - Núcleo e Carriótipos.

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
    "titulo": "Núcleo e Carriótipos",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Núcleo e Carriótipos",
    "introducao": (
        "O núcleo é a maior organela da célula eucariótica e abriga o material "
        "genético (DNA). É o centro de controle da célula: coordena o metabolismo, "
        "a divisão celular e a síntese de proteínas. Sem núcleo, a célula perde "
        "a capacidade de se dividir e de manter suas funções a longo prazo.\n\n"
        "O estudo do núcleo inclui sua estrutura (envoltório nuclear, nucleoplasma, "
        "nucléolo e cromatina), a organização do DNA em cromossomos e a análise "
        "dos cariótipos — os conjuntos completos de cromossomos de uma espécie. "
        "Para a Medicina, esse conhecimento é fundamental: alterações cromossômicas "
        "causam síndromes genéticas como Down, Turner e Klinefelter, e o cariótipo "
        "é uma ferramenta diagnóstica essencial."
    ),
    "secoes": [
        {
            "titulo": "1. Estrutura do Núcleo",
            "conteudo": (
                "O núcleo é envolvido por uma membrana dupla chamada envoltório "
                "nuclear (ou carioteca), que separa o conteúdo nuclear do citoplasma. "
                "Suas principais estruturas são:\n\n"
                "ENVOLTÓRIO NUCLEAR: membrana dupla (membrana externa e interna) "
                "com espaço entre elas chamado de perinuclear. A membrana externa "
                "é contínua com o retículo endoplasmático rugoso e pode ter "
                "ribossomos aderidos. O envoltório se desfunde durante a divisão "
                "celular (prófase) e se reorganiza ao final (telófase).\n\n"
                "POROS NUCLEARES: são aberturas no envoltório que permitem a "
                "passagem seletiva de moléculas entre o núcleo e o citoplasma. "
                "RNA mensageiro e ribossomos saem do núcleo; proteínas que atuam "
                "no núcleo (como DNA polimerase e histonas) entram. Cada poro é "
                "um complexo proteico grande (complexo do poro nuclear).\n\n"
                "NUCLEOPLASMA (cariolinfa): líquido interno do núcleo, onde estão "
                "suspensos a cromatina e o nucléolo. É rico em enzimas envolvidas "
                "na replicação e transcrição do DNA.\n\n"
                "NUCLÉOLO: estrutura densa, não membranosa, presente no núcleo. "
                "É o local de síntese do RNA ribossomal (rRNA) e de montagem dos "
                "ribossomos. Uma célula pode ter vários nucléolos. É especialmente "
                "grande em células com alta taxa de síntese proteica (como "
                "neurônios e hepatócitos)."
            ),
            "exemplo": (
                "Em tumores malignos, o nucléolo costuma ser muito grande e "
                "proeminente, pois as células tumorais têm alta taxa de divisão "
                "e de síntese de proteínas. Por isso, a análise do núcleo ao "
                "microscópio é um critério importante no diagnóstico de câncer — "
                "o chamado \"grau nuclear\" é usado, por exemplo, na classificação "
                "de tumores renais e de próstata."
            ),
        },
        {
            "titulo": "2. Cromatina e Cromossomos",
            "conteudo": (
                "A cromatina é o complexo de DNA e proteínas (histonas e não "
                "histonas) presente no núcleo. Quando a célula não está em divisão, "
                "a cromatina está dispersa como fios longos — é a eucromatina "
                "(ativa, genes sendo transcritos) e a heterocromatina (condensada, "
                "genes inativos). Durante a divisão celular, a cromatina se "
                "condensa em estruturas compactas chamadas cromossomos.\n\n"
                "NUCLEOSSOMO: a unidade básica da cromatina. É formado por um "
                "octâmero de histonas (8 proteínas: 2 H2A, 2 H2B, 2 H3 e 2 H4) "
                "com cerca de 146 pares de bases de DNA enrolados ao redor. "
                "Parece um \"contas em um colar\" — as contas são os nucleossomos "
                "e o fio é o DNA ligante.\n\n"
                "ESTRUTURA DO CROMOSSOMO: cada cromossomo tem um centromero "
                "(região que liga as duas cromátides irmãs) e dois braços: "
                "p (curto) e q (longo). O centromero pode estar em posições "
                "diferentes, definindo o tipo de cromossomo (veja seção 3).\n\n"
                "CROMÁTIDES IRMÃS: antes da divisão, cada cromossomo se duplica "
                "formando duas cromátides irmãs idênticas, ligadas pelo centromero. "
                "Na anáfase da mitose, elas se separam e vão para células-filhas "
                "diferentes."
            ),
            "exemplo": (
                "A condensação da cromatina em cromossomos é essencial para a "
                "divisão celular: sem ela, o DNA longo e fino se quebraria ao "
                "ser puxado para os polos da célula. É como enrolar um fio longo "
                "em um carretel para transportá-lo sem que ele se embole. Por "
                "isso, os cromossomos só são visíveis ao microscópio óptico "
                "durante a divisão (metáfase), quando estão mais condensados."
            ),
        },
        {
            "titulo": "3. Tipos de Cromossomos",
            "conteudo": (
                "Os cromossomos são classificados conforme a posição do centromero:\n\n"
                "METACÊNTRICO: centromero no meio, braços p e q de tamanho "
                "igual ou quase igual. Exemplo: cromossomos 1, 3 e 19 humanos.\n\n"
                "SUBMETACÊNTRICO: centromero um pouco deslocado do centro, "
                "braço p mais curto que o q. Exemplo: cromossomos 2, 4, 5 e 6.\n\n"
                "ACROCÊNTRICO: centromero muito próximo de uma extremidade, "
                "braço p muito curto. Exemplo: cromossomos 13, 14, 15, 21, 22 "
                "e o Y. Os cromossomos acrocêntricos têm satélites (pequenas "
                "estruturas) no braço curto, onde estão os genes do RNA "
                "ribossomal (organizadores nucleolares).\n\n"
                "TELOCÊNTRICO: centromero na extremidade, só um braço. Não "
                "existem cromossomos telocêntricos em humanos, mas ocorrem "
                "em outras espécies (como alguns roedores).\n\n"
                "CROMOSSOMOS SEXUAIS: em humanos, os cromossomos X e Y "
                "determinam o sexo. As fêmeas têm XX e os machos XY. O X é "
                "grande e submetacêntrico; o Y é pequeno e acrocêntrico. "
                "Os demais 44 cromossomos (22 pares) são chamados de "
                "autossomos."
            ),
            "exemplo": (
                "A posição do centromero é importante para identificar "
                "cromossomos no cariótipo. Por exemplo, o cromossomo 21 é "
                "acrocêntrico e pequeno — é o menor autossomo. Por isso, "
                "a trissomia do 21 (síndrome de Down) é a aneuploidia "
                "autossômica mais comum: cromossomos menores causam menos "
                "desequilíbrio genético e permitem a sobrevivência do feto "
                "até o nascimento. Trissomias de cromossomos grandes (como "
                "o 1 ou o 2) são incompatíveis com a vida."
            ),
        },
        {
            "titulo": "4. Cariótipo Humano",
            "conteudo": (
                "O cariótipo é o conjunto completo de cromossomos de uma célula, "
                "organizado em pares e ordenado por tamanho e posição do "
                "centromero. O cariótipo humano normal tem 46 cromossomos: "
                "22 pares de autossomos (numerados de 1 a 22, do maior para o "
                "menor) e 1 par de cromossomos sexuais (XX nas fêmeas, XY nos "
                "machos). Escreve-se: 46,XX (fêmea) ou 46,XY (macho).\n\n"
                "COMO SE OBTÉM O CARIÓTIPO: colhe-se células em divisão "
                "(geralmente linfócitos do sangue cultivados), interrompe-se "
                "a divisão na metáfase com colchicina (impede a formação do "
                "fuso), cora-se com corantes como o Giemsa (produz bandas "
                "características — bandamento G) e fotografa-se os "
                "cromossomos. Depois, recortam-se e organizam-se em pares.\n\n"
                "BANDAMENTO G (Giemsa): cada cromossomo tem um padrão de "
                "bandas claras e escuras único, que permite identificar "
                "cromossomos e detectar alterações estruturais (deleções, "
                "duplicações, translocações).\n\n"
                "APLICAÇÕES CLÍNICAS: o cariótipo é usado para diagnosticar "
                "síndromes cromossômicas, investigar abortos de repetição, "
                "identificar alterações em tumores (como o cromossomo "
                "Philadelphia na leucemia mieloide crônica) e determinar o "
                "sexo em casos de ambiguidade genital."
            ),
            "exemplo": (
                "O cromossomo Philadelphia é uma translocação recíproca entre "
                "os cromossomos 9 e 22 — t(9;22). Resulta na fusão dos genes "
                "BCR e ABL, produzindo uma proteína quimérica com atividade "
                "tirosina quinase constitutiva, que causa a leucemia mieloide "
                "crônica. É um exemplo clássico de como uma alteração "
                "cromossômica específica pode causar câncer. O tratamento "
                "com imatinibe (Gleevec) inibe essa proteína — um dos primeiros "
                "exemplos de terapia alvo molecular em oncologia."
            ),
        },
        {
            "titulo": "5. Euploidias e Aneuploidias",
            "conteudo": (
                "O número de cromossomos de uma espécie é chamado de número "
                "haploide (n) ou diploide (2n). Em humanos, n=23 e 2n=46.\n\n"
                "EUPLOIDIA: o conjunto cromossômico é múltiplo inteiro de n. "
                "Exemplos: haploide (n, 23 — gametas), diploide (2n, 46 — "
                "células somáticas humanas), triploide (3n, 69 — raro, "
                "incompatível com a vida). A poliploidia é comum em plantas, "
                "mas rara em animais.\n\n"
                "ANEUPLOIDIA: há um cromossomo a mais ou a menos, não múltiplo "
                "inteiro de n. Resulta de erro na separação dos cromossomos "
                "durante a meiose (nãodisjunção). Tipos:\n"
                "- Monossomia (2n-1): falta um cromossomo. Exemplo: síndrome "
                "de Turner (45,X) — única monossomia autossômica compatível "
                "com a vida em humanos.\n"
                "- Trissomia (2n+1): sobra um cromossomo. Exemplos: síndrome "
                "de Down (47,XX,+21 ou 47,XY,+21), síndrome de Patau "
                "(trissomia do 13), síndrome de Edwards (trissomia do 18).\n"
                "- Tetrassomia (2n+2): sobram dois cromossomos. Rara.\n\n"
                "NÃODISJUNÇÃO: é o erro que causa as aneuploidias. Ocorre "
                "quando os cromossomos homólogos (na meiose I) ou as "
                "cromátides irmãs (na meiose II ou mitose) não se separam "
                "corretamente. Pode ocorrer na ovogênese ou na "
                "espermatogênese. A frequência de nãodisjunção aumenta com "
                "a idade materna — por isso, o risco de síndrome de Down "
                "aumenta em mulheres acima de 35 anos."
            ),
            "exemplo": (
                "A síndrome de Down é a aneuploidia mais comum e conhecida. "
                "Causada pela trissomia do cromossomo 21, caracteriza-se por: "
                "fisionomia típica (fendas palpebrais oblíquas, ponte nasal "
                "achatada, orelhas pequenas), hipotonia, cardiopatias "
                "congênitas (em cerca de 40% dos casos), e deficiência "
                "intelectual de grau variável. O risco aumenta com a idade "
                "materna: 1 em 1.250 aos 25 anos, 1 em 100 aos 40 anos e "
                "1 em 30 aos 45 anos. Por isso, mulheres acima de 35 anos "
                "são encaminhadas para diagnóstico pré-natal (amniocentese "
                "ou exame de vilo corial)."
            ),
        },
    ],
    "resumo": (
        "- Núcleo: envoltório nuclear (membrana dupla), poros, nucleoplasma, nucléolo (síntese de rRNA).\n"
        "- Cromatina = DNA + histonas. Nucleossomo: 8 histonas + 146 pb de DNA.\n"
        "- Cromossomo: centromero + braços p (curto) e q (longo). Cromátides irmãs são idênticas.\n"
        "- Tipos: metacêntrico (centro), submetacêntrico (deslocado), acrocêntrico (extremidade), telocêntrico (ausente em humanos).\n"
        "- Cromossomos sexuais: X (grande, submetacêntrico) e Y (pequeno, acrocêntrico). Autossomos: 22 pares.\n"
        "- Cariótipo humano: 46,XX (fêmea) ou 46,XY (macho). Bandamento G identifica cromossomos.\n"
        "- Aneuploidias: Turner (45,X), Down (47,+21), Patau (47,+13), Edwards (47,+18).\n"
        "- Nãodisjunção causa aneuploidias; risco aumenta com idade materna."
    ),
    "dicas": [
        "Decore: 46 cromossomos humanos, 22 pares de autossomos + 1 par de sexuais. 46,XX ou 46,XY.",
        "Tipos de cromossomo: metacêntrico (centro), submetacêntrico (deslocado), acrocêntrico (perto da ponta). Não há telocêntrico em humanos.",
        "Cromossomo 21 é o menor autossomo e é acrocêntrico — por isso a trissomia do 21 é a mais comum e compatível com a vida.",
        "Síndromes: Down = 21, Patau = 13, Edwards = 18. Turner = 45,X (monossomia). Klinefelter = 47,XXY.",
        "Nucléolo = síntese de rRNA + montagem de ribossomos. Não tem membrana.",
        "Nãodisjunção aumenta com a idade materna — risco de Down sobe após 35 anos.",
    ],
    "pegadinhas": [
        "Confundir cromátides irmãs com cromossomos homólogos: irmãs são idênticas (mesma origem); homólogos são um do pai e um da mãe (mesmo tipo, mas não idênticos).",
        "Achar que o nucléolo tem membrana: ele é uma estrutura não membranosa, formada por rRNA e proteínas.",
        "Confundir euploidia com aneuploidia: euploidia é múltiplo inteiro de n (2n, 3n, 4n); aneuploidia é 2n±1 ou 2n±2.",
        "Esquecer que a síndrome de Turner é a única monossomia compatível com a vida em humanos — todas as outras monossomias autossômicas são letais.",
        "Achar que o cromossomo Y é grande: ele é um dos menores cromossomos humanos, acrocêntrico.",
        "Confundir nãodisjunção na meiose I (homólogos não se separam) com na meiose II (cromátides irmãs não se separam).",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Núcleo e Carriótipos")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_NUCLEO_CARIOTIPOS.pdf"

    images_data = [
        {"file": "br_nuc_nucleo_1.jpg",
         "caption": "Estrutura do núcleo celular: envoltório, nucleoplasma e nucléolo",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/nucleo-celular/"},
        {"file": "br_nuc_cromossomo_estrutura.jpg",
         "caption": "Estrutura de um cromossomo: centromero, braços p e q, cromátides irmãs",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/cromossomos/"},
        {"file": "br_nuc_tipos_cromossomo.jpg",
         "caption": "Tipos de cromossomos: metacêntrico, submetacêntrico e acrocêntrico",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/cromossomos/"},
        {"file": "br_nuc_cariotipo_humano.jpg",
         "caption": "Cariótipo humano normal: 46 cromossomos organizados em pares",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/cromossomos/"},
        {"file": "br_nuc_cariotipo_be.jpg",
         "caption": "Cariótipo humano com bandamento G para identificação dos cromossomos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/cariotipo.htm"},
        {"file": "br_nuc_nucleo_3.jpg",
         "caption": "Visão detalhada do núcleo e do envoltório nuclear com poros",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/nucleo-celular/"},
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
