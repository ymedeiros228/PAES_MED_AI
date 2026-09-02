"""Gera PDF profissional ABNT do material de Biologia - Ecologia.

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
    "titulo": "Ecologia",
    "disciplina": "Biologia",
    "topico": "Ecologia",
    "subtopico": "Fluxo de Energia, Ciclos Biogeoquímicos, Relações Ecológicas, Biomas",
    "introducao": (
        "A ecologia é o estudo das relações dos seres vivos entre si e com o "
        "ambiente. É uma ciência interdisciplinar que envolve biologia, "
        "química, física e geografia. Compreender a ecologia é essencial para "
        "a Medicina: muitos agentes causadores de doenças têm ciclos de vida "
        "que dependem de vetores e hospedeiros ambientais, e as mudanças "
        "ambientais afetam diretamente a saúde humana.\n\n"
        "Os principais conceitos da ecologia incluem: fluxo de energia nos "
        "ecossistemas, ciclos biogeoquímicos (carbono, nitrogênio, água), "
        "relações ecológicas entre os seres vivos, dinâmica de populações, "
        "biomas e problemas ambientais."
    ),
    "secoes": [
        {
            "titulo": "1. Fluxo de Energia e Cadeias Alimentares",
            "conteudo": (
                "O fluxo de energia nos ecossistemas é unidirecional: entra "
                "como luz solar, é capturada pelos produtores (fotossíntese), "
                "passa pelos consumidores e é dissipada como calor. Diferente "
                "da energia, a MATÉRIA é reciclada (ciclos biogeoquímicos).\n\n"
                "NÍVEIS TRÓFICOS:\n"
                "- Produtores: autotróficos — capturam energia luminosa e a "
                "convertem em energia química (glicose). Plantas, algas e "
                "cianobactérias.\n"
                "- Consumidores: heterotróficos — se alimentam de outros "
                "seres. Dividem-se em:\n"
                "  * Consumidores primários (herbívoros): comem produtores.\n"
                "  * Consumidores secundários (carnívoros): comem herbívoros.\n"
                "  * Consumidores terciários: comem carnívoros.\n"
                "  * Onívoros: comem plantas e animais (humano, urso, porco).\n"
                "- Decompositores: bactérias e fungos que decompõem cadáveres "
                "e fezes, devolvendo nutrientes ao ambiente.\n\n"
                "CADEIA ALIMENTAR: sequência linear de organismos em que "
                "cada um se alimenta do anterior. Exemplo:\n"
                "planta → gafanhoto → sapo → cobra → águia.\n\n"
                "TEIA ALIMENTAR: conjunto de cadeias alimentares "
                "interconectadas. Mais realista, pois a maioria dos "
                "organismos se alimenta de vários seres.\n\n"
                "PIRÂMIDE DE ENERGIA: a cada nível trófico, apenas cerca de "
                "10% da energia é transferida para o próximo nível — os "
                "90% restantes são perdidos como calor (respiração, "
                "metabolismo). Por isso:\n"
                "- As pirâmides de energia são sempre crescentes (mais "
                "energia na base, menos no topo);\n"
                "- As pirâmides de números geralmente são crescentes, mas "
                "podem ser invertidas (uma árvore sustenta milhares de "
                "insetos);\n"
                "- As pirâmides de biomassa geralmente são crescentes, mas "
                "podem ser invertidas em ecossistemas aquáticos (o "
                "fitoplâncton se reproduz rápido e é consumido rápido).\n\n"
                "Por isso, uma cadeia alimentar raramente tem mais de 4-5 "
                "níveis tróficos — não há energia suficiente para sustentar "
                "mais níveis."
            ),
            "exemplo": (
                "O bioacumulação e a magnificação trófica são fenômenos "
                "importantes em saúde pública. Substâncias tóxicas que não "
                "são degradadas (como mercúrio, DDT, chumbo) acumulam-se nos "
                "organismos. Como a energia diminui a cada nível trófico, "
                "mas o poluente não, a concentração do poluente AUMENTA a "
                "cada nível. Por isso, predadores de topo (águia, tubarão, "
                "humano) têm as maiores concentrações. O caso clássico é o "
                "de Minamata (Japão, 1950s): uma indústria despejou mercúrio "
                "na baía, os peixes acumularam, e a população que os consumiu "
                "desenvolveu intoxicação por mercúrio (síndrome de "
                "Minamata — danos neurológicos graves)."
            ),
        },
        {
            "titulo": "2. Ciclos Biogeoquímicos",
            "conteudo": (
                "Os ciclos biogeoquímicos são as rotas percorridas pelos "
                "elementos químicos no ambiente, passando por componentes "
                "biológicos (bio) e geológicos (geo). Os principais são:\n\n"
                "CICLO DO CARBONO:\n"
                "- Fotossíntese: plantas capturam CO2 da atmosfera e o "
                "convertem em glicose (C6H12O6);\n"
                "- Respiração: todos os seres vivos quebram glicose e "
                "liberam CO2 de volta;\n"
                "- Decomposição: decompositores liberam CO2 dos cadáveres;\n"
                "- Combustão: queima de combustíveis fósseis (carvão, "
                "petróleo) libera CO2 acumulado por milhões de anos;\n"
                "- Sedimentação: organismos marinhos com conchas (CaCO3) "
                "morrem e formam rochas (calcário), retirando C da "
                "circulação por milhões de anos.\n\n"
                "CICLO DO NITROGÊNIO:\n"
                "O N2 é o gás mais abundante da atmosfera (78%), mas a "
                "maioria dos seres não pode usá-lo diretamente. Etapas:\n"
                "- Fixação: bactérias (Rhizobium, em nódulos de leguminosas; "
                "Azotobacter, no solo livre; cianobactérias, na água) "
                "convertem N2 em amônia (NH3) — usável pelas plantas.\n"
                "- Nitrificação: bactérias nitrificantes (Nitrosomonas: "
                "NH3 → NO2-; Nitrobacter: NO2- → NO3-) convertem amônia "
                "em nitrito e nitrato — a forma preferida pelas plantas.\n"
                "- Assimilação: plantas absorvem nitrato e o convertem em "
                "proteínas. Animais obtêm N comendo plantas ou outros "
                "animais.\n"
                "- Ammonificação: decompositores convertem o N orgânico "
                "dos cadáveres e fezes em amônia.\n"
                "- Desnitrificação: bactérias (Pseudomonas) convertem "
                "nitrato em N2, devolvendo-o à atmosfera.\n\n"
                "CICLO DA ÁGUA:\n"
                "- Evaporação: a água dos oceanos, rios e lagos evapora;\n"
                "- Evapotranspiração: as plantas liberam água por "
                "transpiração;\n"
                "- Condensação: o vapor se condensa formando nuvens;\n"
                "- Precipitação: a água volta como chuva, neve, granizo;\n"
                "- Infiltração: parte da água infiltra no solo formando "
                "lençóis freáticos;\n"
                "- Escoamento: parte escoa pela superfície formando rios.\n\n"
                "A água é o solvente universal e essencial à vida. "
                "A escassez de água potável é um dos maiores problemas "
                "ambientais atuais."
            ),
            "exemplo": (
                "O efeito estufa é natural e essencial — sem ele, a Terra "
                "seria muito fria (-18°C em vez de 15°C). O problema é o "
                "AUMENTO do efeito estufa pela queima de combustíveis "
                "fósseis, que libera CO2 acumulado por milhões de anos em "
                "poucas décadas. O CO2 aumenta, a temperatura sobe, "
                "causando aquecimento global. As consequências incluem: "
                "derretimento das calotas, aumento do nível do mar, "
                "eventos climáticos extremos, expansão de doenças "
                "transmitidas por vetores (dengue, malária) para regiões "
                "antes livres, e perda de biodiversidade."
            ),
        },
        {
            "titulo": "3. Relações Ecológicas",
            "conteudo": (
                "As relações ecológicas são as interações entre os seres "
                "vivos. Dividem-se em intraespecíficas (entre indivíduos da "
                "mesma espécie) e interespecíficas (entre espécies "
                "diferentes). Também podem ser harmônicas (ambos se "
                "beneficiam ou um se beneficia sem prejudicar o outro) ou "
                "desarmônicas (um se beneficia prejudicando o outro).\n\n"
                "RELÇÕES INTRAESPECÍFICAS:\n"
                "- Colônia: indivíduos anatomicamente ligados (corais, "
                "caravela-portuguesa). Harmônica.\n"
                "- Sociedade: indivíduos independentes mas com divisão de "
                "trabalho (abelhas, formigas, cupins). Harmônica.\n"
                "- Competição: disputa por recursos (alimento, território, "
                "parceiro). Desarmônica.\n"
                "- Canibalismo: um indivíduo come outro da mesma espécie. "
                "Desarmônica.\n\n"
                "RELÇÕES INTERESPECÍFICAS:\n"
                "- Mutualismo: ambos se beneficiam, com dependência. "
                "Obrigatório — um não vive sem o outro. Exemplo: liquens "
                "(alga + fungo), bactérias do rumen dos ruminantes. "
                "Harmônica.\n"
                "- Protocooperação: ambos se beneficiam, mas sem "
                "dependência. Facultativa. Exemplo: anu-andorinha e "
                "gado (tira carrapatos), paguro e anêmona. Harmônica.\n"
                "- Comensalismo: um se beneficia, o outro não é afetado. "
                "Exemplo: rêmora e tubarão, urubu e leão. Harmônica.\n"
                "- Inquilinismo: um usa o outro como abrigo, sem "
                "prejudicá-lo. Exemplo: epífitas (orquídeas) em árvores. "
                "Harmônica.\n"
                "- Predatismo: um caça e mata o outro. Exemplo: leão e "
                "zebra, cobra e sapo. Desarmônica.\n"
                "- Parasitismo: um se alimenta do outro, sem matá-lo "
                "imediatamente. Exemplo: pulga e cachorro, plasmódio e "
                "humano (malária). Desarmônica.\n"
                "- Competição: duas espécies disputam os mesmos recursos. "
                "Desarmônica.\n"
                "- Amensalismo: um inibe o outro, sem se beneficiar "
                "diretamente. Exemplo: antibiose (fungos produzem "
                "antibióticos que inibem bactérias), eucalipto inibe "
                "plantas ao redor (alelopatia). Desarmônica.\n"
                "- Esclavagismo: um se beneficia do trabalho do outro. "
                "Exemplo: formiga amazônica captura outras formigas para "
                "trabalhar. Desarmônica.\n"
                "- Foresia: um se transporta no outro. Exemplo: ácaros em "
                "insetos. Harmônica."
            ),
            "exemplo": (
                "O parasitismo é a relação ecológica mais importante para "
                "a Medicina. As principais doenças parasitárias humanas "
                "resultam de relações parasitárias:\n"
                "- Malária: Plasmodium (protozoário) parasita o humano. "
                "Vetor: Anopheles.\n"
                "- Doença de Chagas: Trypanosoma cruzi parasita o humano. "
                "Vetor: barbeiro.\n"
                "- Leishmaniose: Leishmania. Vetor: flebótomo.\n"
                "- Esquistossomose: Schistosoma mansoni (verme). "
                "Hospedeiro intermediário: caramujo Biomphalaria.\n"
                "- Ascaridíase, oxiuríase, teníase: vermes intestinais.\n"
                "Compreender o ciclo de vida do parasita é essencial para "
                "o controle da doença — muitas vezes, é mais fácil combater "
                "o vetor do que o parasita."
            ),
        },
        {
            "titulo": "4. Biomas e Biodiversidade",
            "conteudo": (
                "Biomas são grandes comunidades ecológicas determinadas "
                "principalmente pelo clima (temperatura e precipitação). "
                "Cada bioma tem vegetação e fauna características.\n\n"
                "BIOMAS BRASILEIROS:\n\n"
                "FLORESTA AMAZÔNICA: maior floresta tropical do mundo. "
                "Clima quente e úmido. Biodiversidade altíssima. Solos "
                "pobres (nutrientes estão na biomassa). Importante para o "
                "ciclo do carbono e da água.\n\n"
                "MATA ATLÂNTICA: floresta tropical da costa brasileira. "
                "Originalmente cobria 1,3 milhão de km²; hoje restam cerca "
                "de 12%. Altamente devastada. Endemismo alto (mico-leão-"
                "dourado, papagaio-de-cara-roxa).\n\n"
                "CERRADO: savana brasileira. Clima sazonal (seca e chuva). "
                "Vegetação com árvores tortuosas, casca grossa (resistência "
                "ao fogo) e raízes profundas. Segundo bioma mais biodiversos "
                "do Brasil. Importante para a agricultura (água — nascentes).\n\n"
                "CAATINGA: vegetação do sertão nordestino. Semiárido. "
                "Vegetação xerófita (cactáceas, bromélias, árvores com "
                "espinhos). Animais adaptados à seca.\n\n"
                "PAMPA: campos do sul do Brasil. Vegetação rasteira, "
                "gramíneas. Clima subtropical. Pecuária extensiva.\n\n"
                "PANTANAL: maior planície alagável do mundo. Clima sazonal "
                "(cheia e seca). Biodiversidade alta (onça-pintada, "
                "jacarés, capivaras, aves).\n\n"
                "MANGUEZAIS: vegetação litorânea, entre o mar e o rio. "
                "Raízes aéreas (pneumatóforos) para respirar no lodo. "
                "Berçário de peixes e crustáceos.\n\n"
                "BIOMAS MUNDIAIS: tundra (polar), taiga (floresta de "
                "coníferas), floresta temperada, pradaria, savana, "
                "deserto, floresta tropical, manguezal.\n\n"
                "BIODIVERSIDADE: o Brasil é o país com a maior "
                "biodiversidade do mundo (megadiverso). Abriga cerca de "
                "20% de todas as espécies do planeta. A perda de "
                "biodiversidade é um problema grave — a extinção de "
                "espécies é irreversível e pode levar à perda de "
                "substâncias medicinais importantes (muitos fármacos "
                "vêm de plantas e animais)."
            ),
            "exemplo": (
                "A perda de biodiversidade tem consequências diretas para "
                "a saúde humana. Cerca de 70% dos fármacos atuais são "
                "derivados ou inspirados em produtos naturais: a aspirina "
                "(salgueiro), a penicilina (fungo Penicillium), o taxol "
                "(teixo — câncer de ovário), a digitalídea (dedaleira — "
                "insuficiência cardíaca), a quinina (quina — malária), o "
                "curare (indígenas — relaxante muscular em anestesia). A "
                "perda de espécies pode significar a perda de futuros "
                "tratamentos para doenças ainda sem cura."
            ),
        },
        {
            "titulo": "5. Problemas Ambientais e Sustentabilidade",
            "conteudo": (
                "Os principais problemas ambientais atuais:\n\n"
                "AQUECIMENTO GLOBAL: aumento da temperatura média da Terra "
                "pela emissão de gases de efeito estufa (CO2, CH4, N2O). "
                "Consequências: derretimento das calotas, aumento do nível "
                "do mar, eventos extremos, expansão de doenças.\n\n"
                "DESMATAMENTO: perda de florestas, principalmente na "
                "Amazônia e Mata Atlântica. Consequências: perda de "
                "biodiversidade, erosão do solo, alteração do ciclo da "
                "água, aumento do CO2.\n\n"
                "POLUIÇÃO:\n"
                "- Do ar: indústrias, veículos. Causa doenças respiratórias "
                "(asma, bronquite), chuva ácida e aumento do efeito estufa.\n"
                "- Da água: esgoto, agrotóxicos, metais pesados. Causa "
                "doenças de veiculação hídrica (cólera, hepatite A, "
                "leptospirose) e eutrofização (excesso de nutrientes em "
                "rios e lagos, levando à proliferação de algas e morte "
                "de peixes).\n"
                "- Do solo: agrotóxicos, lixo, metais pesados.\n"
                "- Sonora: trânsito, indústrias. Causa estresse e perda "
                "de audição.\n\n"
                "BURACO DA CAMADA DE OZÔNIO: destruição do O3 estratosférico "
                "por CFCs (clorofluorcarbonos). A camada de ozônio filtra "
                "a radiação UV, que causa câncer de pele e catarata. O "
                "Protocolo de Montreal (1987) reduziu o uso de CFCs e o "
                "buraco está se fechando — um exemplo de ação global "
                "bem-sucedida.\n\n"
                "EXTINÇÃO DE ESPÉCIES: a taxa atual de extinção é cerca de "
                "1000x maior que a natural. Causas: destruição de habitat, "
                "caça, pesca predatória, introdução de espécies exóticas, "
                "mudanças climáticas.\n\n"
                "SUSTENTABILIDADE: é o uso dos recursos naturais de forma "
                "a não comprometer as futuras gerações. Envolve:\n"
                "- Conservação de ecossistemas;\n"
                "- Uso de energias renováveis (solar, eólica, hídrica);\n"
                "- Reciclagem e economia circular;\n"
                "- Agricultura sustentável;\n"
                "- Controle demográfico;\n"
                "- Educação ambiental.\n\n"
                "AGENDA 2030: 17 Objetivos de Desenvolvimento Sustentável "
                "(ODS) da ONU, incluindo vida terrestre, vida aquática, "
                "energia limpa, água potável e ação climática."
            ),
            "exemplo": (
                "As mudanças climáticas afetam a saúde humana de várias "
                "formas: expansão de doenças transmitidas por vetores "
                "(Aedes aegypti se espalha para regiões antes mais frias, "
                "aumentando dengue, zika e chikungunya); ondas de calor "
                "causam mortes, especialmente em idosos e cardiopatas; "
                "eventos extremos (enchentes, secas) deslocam populações "
                "e favorecem surtos de doenças (leptospirose em enchentes, "
                "meningite em campos de refugiados). A Organização "
                "Mundial da Saúde (OMS) considera a mudança climática a "
                "maior ameaça à saúde do século XXI."
            ),
        },
    ],
    "resumo": (
        "- Fluxo de energia: unidirecional, entra como luz, sai como calor. Matéria é reciclada.\n"
        "- Níveis tróficos: produtores → consumidores (1º, 2º, 3º) → decompositores.\n"
        "- Pirâmide de energia: 10% transferido a cada nível. Por isso, máx. 4-5 níveis.\n"
        "- Ciclo do carbono: fotossíntese capta CO2, respiração libera, combustão acelera.\n"
        "- Ciclo do nitrogênio: fixação (Rhizobium) → nitrificação → assimilação → desnitrificação.\n"
        "- Ciclo da água: evaporação → condensação → precipitação → infiltração/escoamento.\n"
        "- Relações: mutualismo (obrigatório), protocooperação (facultativo), comensalismo, predatismo, parasitismo.\n"
        "- Biomas brasileiros: Amazônia, Mata Atlântica, Cerrado, Caatinga, Pampa, Pantanal, Manguezal.\n"
        "- Problemas: aquecimento global, desmatamento, poluição, buraco do ozônio, extinção.\n"
        "- Sustentabilidade: uso consciente para não comprometer futuras gerações. Agenda 2030 (ODS)."
    ),
    "dicas": [
        "Fluxo de energia = unidirecional (não recicla). Matéria = reciclada (ciclos biogeoquímicos).",
        "Pirâmide de energia é SEMPRE crescente. De números e biomassa podem ser invertidas.",
        "Mutualismo = obrigatório (liquens). Protocooperação = facultativo (anu e gado). Decore a diferença!",
        "Fixação do N2: Rhizobium (nódulos de leguminosas), Azotobacter (solo), cianobactérias (água).",
        "Predatismo = mata a presa. Parasitismo = não mata imediatamente. Ambos são desarmônicos.",
        "Brasil = megadiverso (20% das espécies do planeta). Amazônia e Mata Atlântica são os mais ameaçados.",
    ],
    "pegadinhas": [
        "Confundir mutualismo com protocooperação: mutualismo é obrigatório (um não vive sem o outro); protocooperação é facultativo.",
        "Achar que a pirâmide de energia pode ser invertida: nunca. A energia sempre diminui a cada nível (10%).",
        "Confundir comensalismo com inquilinismo: no comensalismo, um se alimenta do outro; no inquilinismo, usa como abrigo.",
        "Achar que o efeito estufa é ruim: é natural e essencial. O problema é o AUMENTO pela emissão de CO2.",
        "Confundir colônia com sociedade: colônia = indivíduos anatomicamente ligados; sociedade = independentes com divisão de trabalho.",
        "Esquecer que a amônia (NH3) é convertida em nitrito (NO2-) e depois em nitrato (NO3-) — a forma que as plantas absorvem.",
    ],
    "referencias": [
        "ODUM, E. P.; BARRETT, G. W. Fundamentos de Ecologia. 5. ed. São Paulo: Cengage Learning, 2011.",
        "RICKLEFS, R. E. A Economia da Natureza. 6. ed. Rio de Janeiro: Guanabara Koogan, 2010.",
        "BEGON, M.; TOWNSEND, C. R.; HARPER, J. L. Ecologia: de Indivíduos a Ecossistemas. 4. ed. Porto Alegre: Artmed, 2007.",
        "TOWNSEND, C. R. et al. Fundamentos em Ecologia. 2. ed. Porto Alegre: Artmed, 2010.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "LEWINSOHN, T. M.; PRADO, P. I. (Org.). Biodiversidade Brasileira: Conhecimento Atual e Perspectivas. São Paulo: Editora da USP, 2005.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Ecologia")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_ECOLOGIA.pdf"

    images_data = [
        {"file": "br_eco_cadeia_exemplo.jpg",
         "caption": "Cadeia alimentar: produtores, consumidores e decompositores",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/cadeia-alimentar/"},
        {"file": "br_eco_teia.jpg",
         "caption": "Teia alimentar: cadeias ecológicas interconectadas",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/teia-alimentar.htm"},
        {"file": "br_eco_carbono_etapas.jpg",
         "caption": "Ciclo do carbono: fotossíntese, respiração, combustão e sedimentação",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/ciclo-carbono.htm"},
        {"file": "br_eco_nitrogenio_etapas.jpg",
         "caption": "Ciclo do nitrogênio: fixação, nitrificação, assimilação e desnitrificação",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/ciclo-nitrogenio.htm"},
        {"file": "br_eco_agua_etapas.jpg",
         "caption": "Ciclo da água: evaporação, condensação, precipitação e infiltração",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/ciclo-agua.htm"},
        {"file": "br_eco_relacoes.jpg",
         "caption": "Relações ecológicas: harmônicas e desarmônicas, intra e interespecíficas",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/relacoes-ecologicas.htm"},
        {"file": "br_eco_efeito_estufa.jpg",
         "caption": "Efeito estufa: radiação solar retida pelos gases na atmosfera",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/ciclo-carbono.htm"},
        {"file": "br_eco_biomas_mapa.jpg",
         "caption": "Biomas brasileiros: Amazônia, Mata Atlântica, Cerrado, Caatinga, Pampa e Pantanal",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/biomas-brasileiros/"},
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
