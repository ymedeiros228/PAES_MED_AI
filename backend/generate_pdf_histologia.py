"""Gera PDF profissional ABNT do material de Biologia - Histologia.

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
    "titulo": "Histologia",
    "disciplina": "Biologia",
    "topico": "Histologia",
    "subtopico": "Tecidos Epitelial, Conjuntivo, Muscular e Nervoso",
    "introducao": (
        "A histologia é o estudo dos tecidos. Os tecidos são grupos de células "
        "semelhantes que atuam conjuntamente para desempenhar uma função. "
        "Os animais possuem quatro tipos básicos de tecidos: epitelial, "
        "conjuntivo, muscular e nervoso.\n\n"
        "Cada tecido tem características morfológicas e funcionais próprias. "
        "O estudo histológico é fundamental para a Medicina: o diagnóstico de "
        "muitas doenças (incluindo câncer) é feito pela análise microscópica "
        "de tecidos — a biópsia. Além disso, a compreensão da estrutura "
        "normal dos tecidos é a base para reconhecer as alterações "
        "patológicas."
    ),
    "secoes": [
        {
            "titulo": "1. Tecido Epitelial",
            "conteudo": (
                "O tecido epitelial é formado por células justapostas (muito "
                "próximas), com pouca ou nenhuma substância intercelular. "
                "Repousa sobre uma membrana basal (lâmina basal) que o separa "
                "do tecido conjuntivo subjacente. Não tem vasos sanguíneos — "
                "a nutrição ocorre por difusão a partir do conjuntivo. É "
                "inervado (tem terminações nervosas).\n\n"
                "FUNÇÕES:\n"
                "- Revestimento: protege o organismo (epiderme) e reveste "
                "cavidades (boca, estômago, intestino, vasos);\n"
                "- Absorção: epitélio intestinal absorve nutrientes;\n"
                "- Secreção: glândulas (sudaoríparas, sebáceas, salivares, "
                "tireoide, pâncreas);\n"
                "- Excreção: túbulos renais;\n"
                "- Sensorial: epitélio olfatório, retina, papilas gustativas.\n\n"
                "CLASSIFICAÇÃO DOS EPITÉLIOS DE REVESTIMENTO:\n\n"
                "Quanto ao número de camadas:\n"
                "- Simples: uma camada de células.\n"
                "- Estratificado: várias camadas.\n"
                "- Pseudoestratificado: uma camada, mas com núcleos em "
                "alturas diferentes — parece estratificado.\n\n"
                "Quanto à forma das células:\n"
                "- Pavimentoso: células achatadas.\n"
                "- Cúbico: células com altura ≈ largura.\n"
                "- Prismático (colunar): células mais altas que largas.\n\n"
                "EXEMPLOS:\n"
                "- Epitélio simples pavimentoso: alvéolos pulmonares, "
                "endotélio dos vasos (facilita a difusão).\n"
                "- Epitélio simples cúbico: túbulos renais, ovários, tireoide.\n"
                "- Epitélio simples prismático: estômago, intestino (com "
                "microvilosidades para absorção).\n"
                "- Epitélio pseudoestratificado ciliado: traqueia, brônquios "
                "(o cilio empurra o muco com partículas para fora).\n"
                "- Epitélio estratificado pavimentoso: epiderme (queratinizado) "
                "e boca/esôfago/vagina (não queratinizado).\n"
                "- Epitélio estratificado cúbico: glândulas sudoríparas.\n"
                "- Epitélio estratificado prismático: conjuntiva ocular.\n"
                "- Epitélio de transição (urotelio): bexiga — muda de forma "
                "conforme a bexiga enche ou esvazia.\n\n"
                "GLÂNDULAS: derivam do epitélio. Podem ser:\n"
                "- Exócrinas: liberam secreção em ductos (sudoríparas, "
                "salivares, sebáceas, mamárias). Classificam-se em "
                "merócrinas (exocitose — sudoríparas), apócrinas "
                "(parte do citoplasma se desprende — mamárias) e "
                "holócrinas (a célula inteira morre — sebáceas).\n"
                "- Endócrinas: liberam hormônios no sangue (tireoide, "
                "hipófise, suprarrenal). Não têm ductos.\n"
                "- Mistas: pâncreas (exócrina — suco pancreático; "
                "endócrina — insulina e glucagon)."
            ),
            "exemplo": (
                "O câncer de pele é o mais comum no Brasil. O carcinoma "
                "basocelular (células basais da epiderme) é o tipo mais "
                "frequente — geralmente não metastiza. O carcinoma "
                "espinocelular (células escamosas) é mais agressivo. O "
                "mel anoma (células que produzem melanina — melanócitos) "
                "é o mais letal, pois metastiza rapidamente. A regra ABCDE "
                "ajuda a suspeitar de melanoma: A (assimetria), B (bordas "
                "irregulares), C (cor variada), D (diâmetro > 6 mm), "
                "E (evolução — mudança de aspecto). O protetor solar é "
                "a principal forma de prevenção."
            ),
        },
        {
            "titulo": "2. Tecido Conjuntivo",
            "conteudo": (
                "O tecido conjuntivo é o mais abundante do corpo. Diferente "
                "do epitelial, tem muita substância intercelular (matriz "
                "extracelular) e células mais dispersas. A matriz é formada "
                "por fibras e substância fundamental amorfa.\n\n"
                "FUNÇÕES: sustentação, preenchimento, nutrição (o sangue "
                "é conjuntivo), defesa (macrófagos, linfócitos), "
                "armazenamento (gordura), reparo de tecidos.\n\n"
                "FIBRAS DA MATRIZ:\n"
                "- Colágenas: resistentes à tração (pele, tendões, ossos). "
                "São as mais abundantes.\n"
                "- Elásticas: elasticidade (parede de artérias, pulmões, "
                "ligamentos elásticos).\n"
                "- Reticulares: formam rede de sustentação em órgãos "
                "(baço, linfonodos, fígado, medula óssea).\n\n"
                "CÉLULAS:\n"
                "- Fibroblastos: produzem as fibras e a substância "
                "fundamental. São as mais comuns.\n"
                "- Macrófagos (histiócitos): fagocitam bactérias e "
                "restos celulares. São células de defesa.\n"
                "- Mastócitos: liberam histamina (vasodilatação e "
                "inflamação) e heparina (anticoagulante).\n"
                "- Plasmócitos: produzem anticorpos (imunoglobulinas).\n"
                "- Adipócitos: armazenam gordura.\n"
                "- Leucócitos: circulam pelo sangue e migram para o "
                "conjuntivo em infecções.\n\n"
                "TIPOS DE TECIDO CONJUNTIVO:\n\n"
                "CONJUNTIVO PROPRIAMENTE DITO:\n"
                "- Frouxo: muita substância fundamental, poucas fibras. "
                "Preenche espaços entre órgãos. É o mais comum.\n"
                "- Denso não-modelado: muitas fibras colágenas, dispostas "
                "em várias direções. Pele (derme).\n"
                "- Denso modelado: fibras colágenas paralelas. Tendões e "
                "ligamentos. Resistente à tração em uma direção.\n\n"
                "CONJUNTIVOS ESPECIALIZADOS:\n"
                "- Adiposo: predomínio de adipócitos. Tecido subcutâneo, "
                "omento. Reserva energética e isolante térmico.\n"
                "- Sanguíneo: plasma + células (hemácias, leucócitos, "
                "plaquetas). Transporta O2, nutrientes, hormônios.\n"
                "- Ósseo: matriz rica em cálcio e fósforo (rigidez). "
                "Células: osteócitos (dentro da matriz), osteoblastos "
                "(formam osso), osteoclastos (reabsorvem osso). Tipos: "
                "compacto (ostéons) e esponjoso (trabéculas).\n"
                "- Cartilaginoso: matriz firme mas flexível. Células: "
                "condrócitos. Sem vasos — nutre-se por difusão. Tipos: "
                "hialina (cartilagem das articulações, costelas, nariz), "
                "elástica (orelha, epiglote) e fibrosa (discos "
                "intervertebrais, sínfise púbica).\n"
                "- Reticular: fibras reticulares formam rede em órgãos "
                "hematopoiéticos (baço, linfonodos, medula óssea)."
            ),
            "exemplo": (
                "A osteoporose é a perda de massa óssea — os osteoclastos "
                "(que reabsorvem osso) ficam mais ativos que os osteoblastos "
                "(que formam osso), resultando em ossos frágeis. É comum em "
                "mulheres após a menopausa (a falta de estrogênio, que "
                "estimula os osteoblastos, acelera a perda). O tratamento "
                "inclui cálcio, vitamina D e bisfosfonatos (que inibem os "
                "osteoclastos). Já o escorbuto (deficiência de vitamina C) "
                "causa problemas no colágeno — a vitamina C é essencial "
                "para a síntese de colágeno, e sem ela os tecidos se "
                "desfazem: gengivas que sangram, feridas que não cicatrizam, "
                "hemorragias."
            ),
        },
        {
            "titulo": "3. Tecido Muscular",
            "conteudo": (
                "O tecido muscular é responsável pela contração — movimento "
                "do corpo, batimento do coração, peristaltismo. As células "
                "musculares são chamadas fibras musculares e contêm "
                "proteínas contráteis (actina e miosina).\n\n"
                "TIPOS:\n\n"
                "MUSCULO ESTRIADO ESQUELÉTICO:\n"
                "- Voluntário (controlado pelo sistema nervoso somático);\n"
                "- Células longas, cilíndricas, multinucleadas (núcleos na "
                "periferia);\n"
                "- Estrias transversais (bandas claras e escuras) devido ao "
                "arranjo organizado de actina e miosina em sarcômeros;\n"
                "- Contração rápida e vigorosa, mas fadiga facilmente;\n"
                "- Ligado aos ossos por tendões.\n\n"
                "MÚSCULO ESTRIADO CARDÍACO:\n"
                "- Involuntário (controlado pelo sistema nervoso autônomo);\n"
                "- Células ramificadas, com um ou dois núcleos centrais;\n"
                "- Estrias transversais;\n"
                "- Discos intercalares: junções entre as células que "
                "permitem a contração sincrônica do coração como um "
                "\"sincício funcional\";\n"
                "- Contração rápida, rítmica e incontrolável — não fadiga;\n"
                "- Autorritmico: gera seus próprios impulsos (nó sinusal).\n\n"
                "MÚSCULO LISO:\n"
                "- Involuntário (sistema nervoso autônomo);\n"
                "- Células fusiformes (afinadas nas pontas), com um núcleo "
                "central;\n"
                "- Sem estrias (actina e miosina em arranjo menos "
                "organizado);\n"
                "- Contração lenta e sustentada, não fadiga;\n"
                "- Presente em paredes de órgãos ocos (estômago, intestino, "
                "vasos, bexiga, útero). Responsável pelo peristaltismo.\n\n"
                "SARCÔMERO: é a unidade funcional do músculo estriado. "
                "Limitado pelas linhas Z. Contém filamentos de actina "
                "(finos, ancorados na linha Z) e miosina (grossos, no "
                "centro). Na contração, os filamentos de actina deslizam "
                "sobre os de miosina, encurtando o sarcômero — a teoria do "
                "deslizamento dos filamentos. A energia vem do ATP. O cálcio "
                "(liberado pelo retículo sarcoplasmático) é essencial — "
                "liga-se à troponina, que expõe os sítios de ligação da "
                "miosina na actina."
            ),
            "exemplo": (
                "A distrofia muscular de Duchenne é a forma mais comum e "
                "grave de distrofia muscular. É uma doença genética "
                "recessiva ligada ao X (afeta meninos). Causada por mutação "
                "no gene da distrofina — proteína que liga o citosqueleto "
                "das fibras musculares à membrana. Sem distrofina, as "
                "fibras musculares se danificam com a contração e são "
                "substituídas por tecido conjuntivo e gordura. Os sintomas "
                "começam aos 3-5 anos (fraqueza nos membros inferiores), "
                "evoluindo para perda da marcha (~12 anos) e morte por "
                "insuficiência respiratória ou cardíaca (~20-30 anos)."
            ),
        },
        {
            "titulo": "4. Tecido Nervoso",
            "conteudo": (
                "O tecido nervoso é responsável pela recepção, transmissão "
                "e processamento de informações. Forma o sistema nervoso "
                "(cérebro, medula, nervos, gânglios). Tem dois tipos de "
                "células: neurônios e células da glia.\n\n"
                "NEURÔNIOS: são as células funcionais. Estrutura:\n"
                "- Corpo celular (pericárioon): contém o núcleo e os "
                "orgânoides. É onde ocorre a síntese de proteínas.\n"
                "- Dendritos: prolongamentos curtos e ramificados que "
                "recebem os impulsos nervosos e os conduzem em direção ao "
                "corpo celular. Um neurônio pode ter vários dendritos.\n"
                "- Axônio: prolongamento longo (pode ter até 1 metro!) que "
                "conduz o impulso para fora do corpo celular. Um neurônio "
                "tem apenas um axônio. O axônio termina em botões "
                "sinápticos, que liberam neurotransmissores.\n\n"
                "CLASSIFICAÇÃO DOS NEURÔNIOS:\n"
                "- Quanto à função: sensoriais (af erentes — levam "
                "impulsos da periferia ao SNC), motores (e ferentes — "
                "levam impulsos do SNC aos músculos e glândulas) e "
                "associativos (interneurônios — ligam neurônios entre si, "
                "formando circuitos).\n"
                "- Quanto à estrutura: unipolares (um prolongamento — "
                "raros em adultos), bipolares (um dendrito e um axônio — "
                "retina, olfato) e multipolares (vários dendritos e um "
                "axônio — a maioria).\n\n"
                "CÉLULAS DA GLIA (neuroglia): são mais numerosas que os "
                "neurônios (10:1). Não transmitem impulsos, mas dão "
                "suporte, nutrição e proteção:\n"
                "- Astrócitos: os mais numerosos. Dão suporte estrutural, "
                "formam a barreira hematoencefálica e regulam a composição "
                "do líquido intersticial.\n"
                "- Oligodendrócitos (SNC) e células de Schwann (SNP): "
                "formam a bainha de mielina — camada de lipídios que "
                "envolve o axônio e acelera a transmissão do impulso. Um "
                "oligodendrócito mieliniza vários axônios; uma célula de "
                "Schwann mieliniza apenas um segmento de um axônio.\n"
                "- Micróglia: macrófagos do SNC — fazem defesa.\n"
                "- Ependimárias: revestem os ventrículos e produzem o "
                "líquor (líquido cefalorraquidiano).\n\n"
                "BAINHA DE MIELINA E CONDUÇÃO SALTATÓRIA: a mielina é "
                "interronpida em intervalos regulares — os nódulos de "
                "Ranvier. O impulso nervoso \"salta\" de um nódulo a "
                "outro (condução saltatória), o que é muito mais rápido "
                "que a condução contínua dos axônios não mielinizados. "
                "Por isso, neurônios mielinizados conduzem impulsos a "
                "até 120 m/s, enquanto os não mielinizados conduzem a "
                "apenas 0,5-2 m/s."
            ),
            "exemplo": (
                "A esclerose múltipla é uma doença autoimune em que o "
                "sistema imune ataca e destrói a bainha de mielina do SNC "
                "(oligodendrócitos). Sem mielina, a condução dos impulsos "
                "fica lenta e interrompida, causando sintomas como "
                "fraqueza, visão turva, perda de coordenação e fadiga. "
                "A doença tem períodos de surto e remissão. Já a síndrome "
                "de Guillain-Barré é uma doença autoimune que afeta a "
                "mielina do SNP (células de Schwann) — causa fraqueza "
                "ascendente que pode chegar aos músculos respiratórios. "
                "É frequentemente desencadeada por uma infecção anterior "
                "(como Campylobacter jejuni)."
            ),
        },
    ],
    "resumo": (
        "- Epitelial: células justapostas, sem substância intercelular, sobre membrana basal. Sem vasos.\n"
        "- Epitélios: simples/estratificado/pseudoestratificado × pavimentoso/cúbico/prismático. Transição na bexiga.\n"
        "- Glândulas: exócrinas (com ducto) e endócrinas (sem ducto, hormônios no sangue). Pâncreas é mista.\n"
        "- Conjuntivo: muita matriz, células dispersas. Fibras: colágeno, elastina, reticular.\n"
        "- Tipos: frouxo, denso (modelado/não-modelado), adiposo, sanguíneo, ósseo, cartilaginoso, reticular.\n"
        "- Osso: osteoblastos (formam), osteoclastos (reabsorvem), osteócitos (mantêm). Compacto e esponjoso.\n"
        "- Muscular: estriado esquelético (voluntário, multinucleado), cardíaco (involuntário, discos intercalares), liso (involuntário, fusiforme).\n"
        "- Sarcômero: unidade funcional. Actina desliza sobre miosina. ATP + cálcio essenciais.\n"
        "- Nervoso: neurônios (corpo, dendritos, axônio) e glia (astrócitos, oligodendrócitos/Schwann, micróglia, ependimárias).\n"
        "- Mielina: oligodendrócitos no SNC, Schwann no SNP. Condução saltatória nos nódulos de Ranvier."
    ),
    "dicas": [
        "Epitélios: simples (1 camada) × estratificado (várias) × pseudoestratificado (parece várias mas é 1).",
        "Glândulas exócrinas: merócrina (exocitose), apócrina (desprende citoplasma), holócrina (célula morre). Sebácea é holócrina!",
        "Conjuntivo denso modelado = fibras paralelas (tendão). Não-modelado = várias direções (derme).",
        "Osso: osteoblasto = forma, osteoclasto = reabsorve, osteócito = mantém (lembre: blasto = jovem/forma, clasto = quebra).",
        "Muscular: esquelético = voluntário + multinucleado; cardíaco = discos intercalares; liso = fusiforme + involuntário.",
        "Mielina: SNC = oligodendrócitos; SNP = células de Schwann. Esclerose múltipla afeta SNC; Guillain-Barré afeta SNP.",
    ],
    "pegadinhas": [
        "Achar que o epitélio tem vasos sanguíneos: não tem. Nutre-se por difusão do conjuntivo.",
        "Confundir pseudoestratificado com estratificado: o pseudoestratificado é uma camada só, mas os núcleos estão em alturas diferentes.",
        "Achar que as glândulas sebáceas são merócrinas: são holócrinas (a célula inteira morre para liberar a secreção).",
        "Confundir osteoblasto com osteoclasto: blasto FORMA, clasto QUEBRA. Na osteoporose, os clastos estão mais ativos.",
        "Achar que o músculo cardíaco é voluntário: é involuntário, mas é estriado (tem estrias, diferente do liso).",
        "Confundir oligodendrócitos com células de Schwann: oligodendrócitos mielinizam vários axônios no SNC; Schwann mieliniza um segmento no SNP.",
    ],
    "referencias": [
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "GARTNER, L. P.; HIATT, J. L. Tratado de Histologia. 3. ed. Rio de Janeiro: Elsevier, 2011.",
        "KIERZENBAUM, A. L.; TRES, L. L. Histologia e Biologia Celular: Uma Introdução à Patologia. 3. ed. Rio de Janeiro: Elsevier, 2016.",
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "STEVENS, A.; LOWE, J. S. Histologia Humana. 3. ed. São Paulo: Elsevier, 2002.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Histologia")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_HISTOLOGIA.pdf"

    images_data = [
        {"file": "br_hist_epitelial_classif.jpg",
         "caption": "Classificação do tecido epitelial: número de camadas e forma das células",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecido-epitelial.htm"},
        {"file": "br_hist_glandulas.jpg",
         "caption": "Tipos de glândulas: exócrinas (com ducto) e endócrinas (sem ducto)",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecido-epitelial.htm"},
        {"file": "br_hist_conjuntivo_tipos.jpg",
         "caption": "Tipos de tecido conjuntivo: frouxo, denso, adiposo, cartilaginoso e ósseo",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecido-conjuntivo.htm"},
        {"file": "br_hist_conjuntivo_sangue.jpg",
         "caption": "Tecido conjuntivo sanguíneo: hemácias, leucócitos e plaquetas",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/tecido-conjuntivo/"},
        {"file": "br_hist_muscular_tipos.jpg",
         "caption": "Tipos de tecido muscular: esquelético, cardíaco e liso",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecido-muscular.htm"},
        {"file": "br_hist_sarcomero.jpg",
         "caption": "Sarcômero: unidade funcional do músculo estriado com actina e miosina",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/tecido-muscular.htm"},
        {"file": "br_hist_neuronio.jpg",
         "caption": "Estrutura do neurônio: corpo celular, dendritos e axônio",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/tecido-nervoso.htm"},
        {"file": "br_hist_neuronios_glias.jpg",
         "caption": "Neurônios e células da glia: astrócitos, oligodendrócitos e micróglia",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/tecido-nervoso/"},
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
