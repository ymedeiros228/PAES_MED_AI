"""Gera PDF profissional ABNT do material de Biologia - Gametogênese.

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
    "titulo": "Gametogênese",
    "disciplina": "Biologia",
    "topico": "Citologia",
    "subtopico": "Gametogênese",
    "introducao": (
        "A gametogênese é o processo de formação dos gametas — os espermatozoides "
        "(gametas masculinos) e os óvulos (gametas femininos). Ela ocorre nas "
        "gônadas: testículos (espermatogênese) e ovários (ovogênese). Em ambos "
        "os casos, células germinativas diploides (2n) sofrem meiose e "
        "diferenciação, originando células haploides (n) especializadas na "
        "fecundação.\n\n"
        "Compreender a gametogênese é fundamental para a Medicina: ela explica "
        "desde a base da herança genética até causas de infertilidade, "
        "malformações congênitas e o aumento de aneuploidias com a idade "
        "materna. Além disso, os conhecimentos sobre gametogênese são a base "
        "das técnicas de reprodução assistida, como a fertilização in vitro."
    ),
    "secoes": [
        {
            "titulo": "1. Espermatogênese",
            "conteudo": (
                "A espermatogênese ocorre nos túbulos seminíferos dos testículos. "
                "Começa na puberdade e continua por toda a vida do homem. "
                "Divide-se em três fases:\n\n"
                "FASE PROLIFERATIVA (mitoses): as espermatogônias (células "
                "germinativas diploides, 2n) se multiplicam por mitose. "
                "Algumas permanecem como reserva (espermatogônias germinativas); "
                "outras se diferenciam em espermatogônias de tipo A e B. "
                "As do tipo B crescem e se transformam em espermatócitos I "
                "(primários), que são diploides (2n) e maiores.\n\n"
                "FASE DE CRESCIMENTO: os espermatócitos I crescem e duplicam "
                "o DNA, ficando prontos para a meiose.\n\n"
                "FASE DE MATURAÇÃO (meiose): os espermatócitos I sofrem a "
                "meiose I, originando dois espermatócitos II (secundários), "
                "haploides (n) mas com cromátides irmãs ainda unidas. Cada "
                "espermatócito II sofre a meiose II, originando duas "
                "espermatides — totalizando quatro espermatides a partir de "
                "cada espermatócito I.\n\n"
                "ESPERMIOGÊNESE (diferenciação): as espermatides sofrem "
                "modificações morfológicas para se transformarem em "
                "espermatozoides. As principais mudanças são:\n"
                "- O complexo de Golgi forma o acrossomo (vesícula com enzimas "
                "hidrolíticas, que vai ficar na cabeça do espermatozoide);\n"
                "- Os centriolos migram para a base do núcleo e originam o "
                "flagelo (cauda);\n"
                "- As mitocôndrias se concentram na peça intermediária, "
                "fornecendo energia para o movimento do flagelo;\n"
                "- O citoplasma é reduzido (quase todo é eliminado), tornando "
                "o espermatozoide mais leve e rápido;\n"
                "- O núcleo se condensa fortemente.\n\n"
                "RESULTADO: cada espermatogônia que entra no processo origina "
                "quatro espermatozoides funcionais, todos do mesmo tamanho."
            ),
            "exemplo": (
                "A espermatogênese dura cerca de 64-74 dias em humanos. As "
                "espermatogônias ficam na periferia dos túbulos seminíferos e, "
                "à medida que se diferenciam, migram para o lúmen. Ao final, "
                "os espermatozoides são liberados no lúmen e seguem para o "
                "epidídimo, onde terminam a maturação e adquirem motilidade. "
                "Um homem adulto produz cerca de 200-300 milhões de "
                "espermatozoides por dia — um número enorme, que explica por "
                "que a infertilidade masculina por baixa produção é menos "
                "comum que a feminina."
            ),
        },
        {
            "titulo": "2. Estrutura do Espermatozoide",
            "conteudo": (
                "O espermatozoide é uma célula altamente especializada para a "
                "fecundação. Tem formato alongado e é dividido em quatro partes:\n\n"
                "CABEÇA: contém o núcleo com o material genético (cromatina "
                "muito condensada) e o acrossomo na porção anterior. O "
                "acrossomo é uma vesícula derivada do complexo de Golgi que "
                "contém enzimas hidrolíticas (hialuronidase e acrosina). "
                "Essas enzimas são liberadas quando o espermatozoide encontra "
                "o óvulo, digerindo as camadas externas (corona radiata e "
                "zona pelúcida) e permitindo a penetração.\n\n"
                "PEÇA INTERMEDIÁRIA: contém numerosas mitocôndrias dispostas "
                "em espiral ao redor do flagelo. Essas mitocôndrias produzem "
                "ATP para o movimento do flagelo. É o \"motor\" do "
                "espermatozoide.\n\n"
                "PEÇA PRINCIPAL: é a porção mais longa, formada pelo flagelo "
                "responsável pela motilidade. Os microtúbulos do flagelo têm "
                "arranjo 9+2 (nove duplas externas + duas centrais).\n\n"
                "PEÇA TERMINAL: porção final do flagelo, mais fina.\n\n"
                "O espermatozoide é uma das menores células do corpo humano: "
                "cerca de 50-60 micrômetros de comprimento total, sendo a "
                "cabeça apenas 5 micrômetros. Quase não tem citoplasma — é "
                "essencialmente um núcleo com um motor."
            ),
            "exemplo": (
                "A análise do sêmen (espermograma) avalia a quantidade, "
                "motilidade e morfologia dos espermatozoides. Valores "
                "normais: mais de 15 milhões de espermatozoides por mL, "
                "com pelo menos 40% móveis e 4% com morfologia normal. "
                "Defeitos no acrossomo impedem a penetração do óvulo — "
                "uma causa de infertilidade masculina. A ICSI (injeção "
                "intracitoplasmática de espermatozoide) contorna esse "
                "problema injetando o espermatozoide diretamente no óvulo."
            ),
        },
        {
            "titulo": "3. Ovogênese",
            "conteudo": (
                "A ovogênese ocorre nos ovários. Diferente da espermatogênese, "
                "começa na vida fetal e tem um longo período de pausa. "
                "Divide-se em três fases:\n\n"
                "FASE PROLIFERATIVA (mitoses): na vida fetal, as ovogônias "
                "(células diploides, 2n) se multiplicam por mitose. Ao todo, "
                "formam-se cerca de 400 mil a 2 milhões de ovogônias. "
                "A maioria degenera (atresia) ainda na vida fetal.\n\n"
                "FASE DE CRESCIMENTO: as ovogônias crescem e se transformam "
                "em ovócitos I (primários), que entram na meiose I ainda na "
                "vida fetal. Porém, param no diplotêno da prófase I "
                "(estágio dictióteno) e permanecem assim até a puberdade. "
                "Durante o crescimento, os ovócitos acumulam vitelo (reserva "
                "nutritiva) e formam camadas de células foliculares ao redor "
                "(folículos primários).\n\n"
                "FASE DE MATURAÇÃO (meiose): a partir da puberdade, a cada "
                "ciclo menstrual, um (ou poucos) ovócito I retoma a meiose. "
                "Ele completa a meiose I, mas a divisão é desigual: origina "
                "uma célula grande (ovócito II) e uma pequena (primeiro "
                "corpúsculo polar). O corpúsculo polar é um resíduo com "
                "pouco citoplasma — praticamente só o núcleo.\n\n"
                "O ovócito II começa a meiose II, mas para na metáfase II. "
                "SÓ TERMINA A MEIOSE II SE FOR FECUNDADO. Se não houver "
                "fecundação, o ovócito II degenera em 24-48 horas.\n\n"
                "Se houver fecundação, a meiose II se completa, originando "
                "o ovótide (que se transforma em óvulo) e o segundo corpúsculo "
                "polar. Portanto, a ovogênese só termina com a fecundação.\n\n"
                "RESULTADO: cada ovogônia que completa o processo origina "
                "apenas UM óvulo funcional (e três corpúsculos polares que "
                "degeneram). Isso é diferente da espermatogênese, que "
                "produz quatro espermatozoides funcionais."
            ),
            "exemplo": (
                "A mulher nasce com todos os ovócitos I que terá na vida "
                "(cerca de 1-2 milhões na vida fetal, reduzidos a cerca de "
                "300-400 mil na puberdade). Apenas cerca de 400 ovócitos "
                "serão ovulados ao longo da vida reprodutiva. Os demais "
                "degeneram por atresia. Por isso, a reserva ovariana "
                "diminui com a idade — aos 35 anos, a fertilidade cai "
                "significativamente, e aos 40-45 anos, a menopausa se "
                "aproxima. É por isso que a fertilização in vitro com "
                "doação de óvulos é uma opção para mulheres mais velhas."
            ),
        },
        {
            "titulo": "4. Diferenças entre Espermatogênese e Ovogênese",
            "conteudo": (
                "ESPERMATOGÊNESE:\n"
                "- Ocorre nos testículos (túbulos seminíferos);\n"
                "- Começa na puberdade e continua por toda a vida;\n"
                "- Produz 4 espermatozoides funcionais por célula inicial;\n"
                "- As quatro células resultantes têm o mesmo tamanho;\n"
                "- A meiose é contínua, sem pausas;\n"
                "- Produz milhões de gametas por dia;\n"
                "- O espermatozoide é pequeno e móvel (flagelo);\n"
                "- A diferenciação (espermiogênese) ocorre após a meiose.\n\n"
                "OVOGÊNESE:\n"
                "- Ocorre nos ovários;\n"
                "- Começa na vida fetal e tem pausa na prófase I;\n"
                "- Produz 1 óvulo funcional (e 3 corpúsculos polares) por célula inicial;\n"
                "- A divisão é desigual: o óvulo fica com quase todo o citoplasma;\n"
                "- A meiose tem pausa longa (dictióteno) e só termina com a fecundação;\n"
                "- Produz apenas 1 gameta por ciclo (mensal);\n"
                "- O óvulo é grande (maior célula do corpo) e imóvel;\n"
                "- O crescimento ocorre antes da meiose.\n\n"
                "A divisão desigual da ovogênese é uma adaptação evolutiva: "
                "o óvulo precisa acumular muito citoplasma, organelas e "
                "reservas nutritivas para sustentar o desenvolvimento "
                "embrionário inicial. Se o citoplasma fosse dividido "
                "igualmente, as quatro células resultantes seriam pequenas "
                "demais para iniciar o desenvolvimento. Por isso, a "
                "natureza \"joga fora\" três corpúsculos polares e "
                "concentra tudo em um único óvulo."
            ),
            "exemplo": (
                "A divisão desigual da ovogênese é importante para a "
                "reprodução assistida. Na fertilização in vitro (FIV), "
                "os corpúsculos polares podem ser biopsiados para análise "
                "genética (diagnóstico genético pré-implantacional, DGP) "
                "sem prejudicar o óvulo. O primeiro corpúsculo polar "
                "reflete o material genético do ovócito — se ele tem uma "
                "trissomia, o óvulo provavelmente também tem. Isso "
                "permite selecionar embriões saudáveis antes da implantação."
            ),
        },
        {
            "titulo": "5. Anomalias Cromossômicas na Gametogênese",
            "conteudo": (
                "A meiose é um processo complexo e sujeito a erros. O erro "
                "mais comum é a nãodisjunção — quando os cromossomos "
                "homólogos (meiose I) ou as cromátides irmãs (meiose II) "
                "não se separam corretamente. Isso gera gametas com um "
                "cromossomo a mais (n+1) ou a menos (n-1), que, ao "
                "fecundarem, originam aneuploidias.\n\n"
                "NA MEIOSE I: os homólogos não se separam. Ambos vão para "
                "o mesmo gameta. Resultado: dois gametas n+1 e dois n-1.\n\n"
                "NA MEIOSE II: as cromátides irmãs não se separam. "
                "Resultado: um gameta n+1, um n-1 e dois normais.\n\n"
                "EXEMPLOS DE ANEUPLOIDIAS:\n"
                "- Síndrome de Down (trissomia do 21): o gameta tem dois "
                "cromossomos 21; ao fecundar um gameta normal, o embrião "
                "fica com três. É a aneuploidia mais comum.\n"
                "- Síndrome de Turner (45,X): o gameta não tem o "
                "cromossomo X. Monossomia compatível com a vida.\n"
                "- Síndrome de Klinefelter (47,XXY): o gameta tem XXY. "
                "Macho com características femininas.\n"
                "- Síndrome de Edwards (trissomia do 18) e Patau "
                "(trissomia do 13): graves, geralmente letais no primeiro "
                "ano de vida.\n\n"
                "IDADE MATERNA: o risco de nãodisjunção aumenta com a "
                "idade materna porque os ovócitos permanecem na prófase I "
                "por décadas. Quanto mais tempo os cromossomos ficam "
                "pareados, maior o risco de falha na separação. Por isso, "
                "mulheres acima de 35 anos são encaminhadas para "
                "diagnóstico pré-natal (amniocentese, vilo corial ou "
                "exames de sangue como o NIPT)."
            ),
            "exemplo": (
                "O risco de síndrome de Down aumenta com a idade materna: "
                "1 em 1.250 aos 25 anos, 1 em 400 aos 35 anos, 1 em 100 "
                "aos 40 anos e 1 em 30 aos 45 anos. Por isso, o "
                "rastreamento pré-natal é recomendado para mulheres acima "
                "de 35 anos. O NIPT (teste não invasivo de pré-natal) "
                "analisa DNA fetal no sangue materno e detecta trissomias "
                "com mais de 99% de sensibilidade para a síndrome de Down, "
                "sem risco para o feto — uma revolução no diagnóstico "
                "pré-natal dos últimos anos."
            ),
        },
    ],
    "resumo": (
        "- Espermatogênese: mitose + crescimento + meiose + espermiogênese. 4 espermatozoides por célula.\n"
        "- Espermiogênese: acrossomo (Golgi), flagelo (centriolos), mitocôndrias (peça intermediária).\n"
        "- Espermatozoide: cabeça (núcleo + acrossomo), peça intermediária (mitocôndrias), flagelo (9+2).\n"
        "- Ovogênese: mitose (vida fetal) + crescimento + meiose (com pausa no dictióteno).\n"
        "- Ovogênese produz 1 óvulo + 3 corpúsculos polares. Divisão desigual (óvulo fica com o citoplasma).\n"
        "- Meiose feminina para na metáfase II e só termina com a fecundação.\n"
        "- Nãodisjunção causa aneuploidias: Down (21), Turner (45,X), Klinefelter (47,XXY), Edwards (18), Patau (13).\n"
        "- Risco de aneuploidia aumenta com a idade materna (ovócitos parados na prófase I por décadas)."
    ),
    "dicas": [
        "Espermatogênese = 4 espermatozoides iguais. Ovogênese = 1 óvulo + 3 corpúsculos polares. Decore!",
        "Espermiogênese: Golgi → acrossomo; centriolos → flagelo; mitocôndrias → peça intermediária.",
        "Espermatozoide: cabeça (núcleo + acrossomo), peça intermediária (mitocôndrias), flagelo (9+2).",
        "Ovogênese: começa na vida fetal, para no dictióteno (prófase I), só termina com a fecundação.",
        "Divisão desigual da ovogênese: óvulo fica com todo o citoplasma; corpúsculos polares são resíduos.",
        "Idade materna > 35 anos = maior risco de nãodisjunção e aneuploidias (especialmente Down).",
    ],
    "pegadinhas": [
        "Achar que a ovogênese produz 4 óvulos: ela produz 1 óvulo funcional e 3 corpúsculos polares (que degeneram).",
        "Confundir a pausa da meiose feminina: ela para no dictióteno (prófase I) na vida fetal e na metáfase II após a ovulação.",
        "Esquecer que a meiose feminina só termina se houver fecundação — sem fecundação, o ovócito II degenera.",
        "Achar que o espermatozoide tem muito citoplasma: ele é quase só núcleo e flagelo, com citoplasma reduzido.",
        "Confundir acrossomo com núcleo: o acrossomo é uma vesícula com enzimas (Golgi), na frente do núcleo.",
        "Achar que a espermatogênese tem pausa: ela é contínua da puberdade até a morte, sem interrupções.",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "GRIFFITHS, A. J. F. et al. Introdução à Genética. 11. ed. Rio de Janeiro: Guanabara Koogan, 2018.",
        "MOORE, K. L.; PERSAUD, T. V. N. Embriologia Clínica. 10. ed. Rio de Janeiro: Elsevier, 2016.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Citologia — Gametogênese")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_CITOLOGIA_GAMETOGENESE.pdf"

    images_data = [
        {"file": "br_gam_gametogenese.jpg",
         "caption": "Gametogênese: formação de espermatozoides e óvulos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/gametogenese.htm"},
        {"file": "br_gam_esp_fases.jpg",
         "caption": "Fases da espermatogênese: proliferação, crescimento e maturação",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/espermatogenese/"},
        {"file": "br_gam_espermiogenese.jpg",
         "caption": "Espermiogênese: diferenciação da espermatide em espermatozoide",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/espermatogenese/"},
        {"file": "br_gam_ovogenese_fases.jpg",
         "caption": "Fases da ovogênese: mitose fetal, crescimento e meiose com pausa",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/gametogenese/"},
        {"file": "br_gam_esp_ovogenese.jpg",
         "caption": "Comparação entre espermatogênese e ovogênese",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/gametogenese.htm"},
        {"file": "br_gam_estrutura_esp.jpg",
         "caption": "Estrutura do espermatozoide: cabeça, peça intermediária e flagelo",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/espermatogenese.htm"},
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
