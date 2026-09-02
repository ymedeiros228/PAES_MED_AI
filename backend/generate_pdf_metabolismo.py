"""Gera PDF profissional ABNT do material de Biologia - Metabolismo Celular.

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
    "titulo": "Metabolismo Celular",
    "disciplina": "Biologia",
    "topico": "Metabolismo Celular",
    "subtopico": "Respiração, Fermentação e Fotossíntese",
    "introducao": (
        "O metabolismo celular é o conjunto de todas as reações químicas que "
        "ocorrem nas células para obter energia e produzir as moléculas "
        "necessárias à vida. Divide-se em duas grandes categorias: catabolismo "
        "(quebra de moléculas com liberação de energia) e anabolismo (síntese "
        "de moléculas com consumo de energia).\n\n"
        "A molécula universal de energia é o ATP (adenosina trifosfato). Ele "
        "é produzido principalmente pela respiração celular (aeróbica) e pela "
        "fermentação (anaeróbica). As plantas, além de respirar, realizam a "
        "fotossíntese — processo que converte energia luminosa em energia "
        "química, produzindo glicose e oxigênio.\n\n"
        "Para a Medicina, o metabolismo celular é fundamental: doenças como "
        "diabetes, obesidade, doenças mitocondriais e câncer resultam de "
        "disfunções metabólicas. Além disso, muitos fármacos atuam em vias "
        "metabólicas específicas."
    ),
    "secoes": [
        {
            "titulo": "1. ATP — A Moeda Energética",
            "conteudo": (
                "O ATP (adenosina trifosfato) é a principal molécula de "
                "armazenamento e transferência de energia das células. É "
                "composto por:\n\n"
                "- Adenina (base nitrogenada);\n"
                "- Ribose (açúcar de 5 carbonos — pentose);\n"
                "- Três grupos fosfato ligados por ligações anidrido.\n\n"
                "As ligações entre os fosfatos são chamadas de \"ligações "
                "ricas em energia\" porque sua hidrólise libera muita energia "
                "livre (cerca de 7,3 kcal/mol em condições padrão, até 12 "
                "kcal/mol na célula). Quando o ATP perde um fosfato, vira ADP "
                "(adenosina difosfato); se perde dois, vira AMP (adenosina "
                "monofosfato).\n\n"
                "O ATP é continuamente regenerado: a célula recicla o ADP e o "
                "fosfato inorgânico (Pi) para formar novo ATP. Um humano adulto "
                "consome e regenera cerca de 50-75 kg de ATP por dia — mas, "
                "como é reciclado, o corpo tem apenas cerca de 50 gramas de "
                "ATP em qualquer momento. Essa reciclagem é feita principalmente "
                "pela respiração celular.\n\n"
                "O ATP fornece energia para: contração muscular, transporte "
                "ativo (bomba Na+/K+), síntese de proteínas e DNA, divisão "
                "celular, condução de impulsos nervosos, e muitas outras "
                "funções. Sem ATP, a célula morre em segundos (no cérebro) "
                "a minutos (em outros tecidos)."
            ),
            "exemplo": (
                "O cianeto é uma das substâncias mais tóxicas conhecidas porque "
                "bloqueia a cadeia respiratória, impedindo a produção de ATP "
                "pela mitocôndria. Sem ATP, as células — especialmente os "
                "neurônios e as células cardíacas, que consomem muita energia "
                "— param de funcionar em segundos. É por isso que o cianeto "
                "causa morte rápida: o cérebro e o coração param quase "
                "instantaneamente. O cianeto liga-se à citocromo oxidase "
                "(complexo IV da cadeia respiratória), bloqueando a transferência "
                "de elétrons para o oxigênio."
            ),
        },
        {
            "titulo": "2. Respiração Celular Aeróbica",
            "conteudo": (
                "A respiração celular aeróbica é o processo de obtenção de ATP "
                "a partir da glicose, com uso de oxigênio. É a principal fonte "
                "de energia das células eucarióticas. A equação geral é:\n\n"
                "C6H12O6 + 6 O2 → 6 CO2 + 6 H2O + 36-38 ATP\n\n"
                "Divide-se em quatro etapas:\n\n"
                "ETAPA 1 — GLICÓLISE (no hialoplasma):\n"
                "Uma molécula de glicose (6 carbonos) é quebrada em duas "
                "moléculas de piruvato (3 carbonos cada). Não precisa de "
                "oxigênio. Produz: 2 ATP (líquido), 2 NADH e 2 piruvatos. "
                "É a única etapa que ocorre fora da mitocôndria e que é "
                "comum à respiração e à fermentação.\n\n"
                "ETAPA 2 — DESCARBOXILAÇÃO OXIDATIVA (matriz mitocondrial):\n"
                "Cada piruvato entra na mitocôndria e é convertido em "
                "acetil-CoA (2 carbonos) pela enzima piruvato desidrogenase. "
                "Libera 1 CO2 e produz 1 NADH por piruvato. Como são dois "
                "piruvatos: 2 CO2, 2 NADH e 2 acetil-CoA.\n\n"
                "ETAPA 3 — CICLO DE KREBS (matriz mitocondrial):\n"
                "Cada acetil-CoA (2C) se liga ao oxaloacetato (4C) formando "
                "citrato (6C). Ao longo do ciclo, liberam-se 2 CO2, 3 NADH, "
                "1 FADH2 e 1 ATP (ou GTP) por volta. Como são dois acetil-CoA, "
                "o resultado total é: 4 CO2, 6 NADH, 2 FADH2 e 2 ATP.\n\n"
                "ETAPA 4 — CADEIA RESPIRATÓRIA E FOSFORILAÇÃO OXIDATIVA "
                "(membrana interna mitocondrial):\n"
                "Os NADH e FADH2 (carregadores de elétrons) doam seus elétrons "
                "para a cadeia de transporte de elétrons (complexos I, II, III "
                "e IV). Os elétrons passam de um complexo a outro, liberando "
                "energia que é usada para bombear prótons (H+) da matriz para "
                "o espaço intermembranas, criando um gradiente de prótons. "
                "No final, os elétrons são aceitos pelo oxigênio, que se "
                "combina com H+ para formar água (H2O). O gradiente de prótons "
                "volta para a matriz pela enzima ATP sintase, que produz ATP. "
                "Cada NADH gera cerca de 3 ATP; cada FADH2, cerca de 2 ATP.\n\n"
                "BALANÇO TOTAL: 36-38 ATP por glicose (depende do transporte "
                "do NADH citoplasmático para a mitocôndria)."
            ),
            "exemplo": (
                "O oxigênio é o aceptor final de elétrons na cadeia respiratória. "
                "Sem O2, a cadeia para, os NADH e FADH2 se acumulam, e o ciclo "
                "de Krebs para por falta de NAD+ e FAD. A célula passa a "
                "depender apenas da glicólise (que produz apenas 2 ATP por "
                "glicose). Para regenerar o NAD+ necessário à glicólise, a "
                "célula faz fermentação. É por isso que, em exercício intenso, "
                "quando o O2 não dá conta, os músculos produzem ácido lático "
                "(fermentação lática) — causando a dor muscular e a fadiga."
            ),
        },
        {
            "titulo": "3. Fermentação",
            "conteudo": (
                "A fermentação é um processo anaeróbico (sem oxigênio) que "
                "permite a célula obter ATP apenas pela glicólise. Como a "
                "glicólise produz apenas 2 ATP por glicose, a fermentação é "
                "muito menos eficiente que a respiração (que produz 36-38 "
                "ATP). Mas, em condições anaeróbias, é a única opção.\n\n"
                "O problema da glicólise é que ela consome NAD+ e produz NADH. "
                "Sem mitocôndria funcionando (por falta de O2), o NADH se "
                "acumula e o NAD+ se esgota. Sem NAD+, a glicólise para. A "
                "fermentação resolve isso: converte o piruvato em outra "
                "molécula, oxidando o NADH de volta a NAD+.\n\n"
                "TIPOS DE FERMENTAÇÃO:\n\n"
                "FERMENTAÇÃO LÁTICA: o piruvato é convertido em ácido lático "
                "(lactato) pela enzima lactato desidrogenase, regenerando NAD+. "
                "Ocorre em:\n"
                "- Células musculares humanas em exercício intenso (quando o "
                "O2 é insuficiente);\n"
                "- Bactérias láticas (Lactobacillus) — usadas na produção de "
                "iogurte, queijo, chucrute e picles.\n\n"
                "FERMENTAÇÃO ALCOÓLICA: o piruvato é convertido em etanol e "
                "CO2 em duas etapas: primeiro, descarboxilação (piruvato → "
                "acetaldeído + CO2); depois, redução do acetaldeído a etanol, "
                "regenerando NAD+. Ocorre em:\n"
                "- Leveduras (Saccharomyces cerevisiae) — usadas na produção "
                "de pão (o CO2 faz a massa crescer) e de bebidas alcoólicas "
                "(cerveja, vinho, cachaça).\n\n"
                "FERMENTAÇÃO ACÉTICA: bactérias do gênero Acetobacter "
                "convertetem etanol em ácido acético (vinagre). Não é uma "
                "fermentação estrita, pois usa O2.\n\n"
                "BALANÇO ENERGÉTICO: a fermentação produz apenas 2 ATP por "
                "glicose (os mesmos da glicólise). O restante da energia "
                "fica no produto final (lactato ou etanol), que ainda pode "
                "ser oxidado posteriormente."
            ),
            "exemplo": (
                "Na produção de pão, as leveduras realizam fermentação "
                "alcoólica. O CO2 liberado fica preso na massa, formando "
                "bolhas que fazem o pão crescer e ficarem leve. O etanol "
                "produzido evapora durante o cozimento. Por isso, a massa "
                "de pão cheira a fermento. Já na produção de cerveja e "
                "vinho, o que interessa é o etanol — o CO2 escapa (ou é "
                "mantido para dar efervescência, como na champanhe)."
            ),
        },
        {
            "titulo": "4. Fotossíntese",
            "conteudo": (
                "A fotossíntese é o processo pelo qual as plantas, algas e "
                "algumas bactérias convertem energia luminosa em energia "
                "química, produzindo glicose e oxigênio. É a base de toda a "
                "vida na Terra, pois é a principal fonte de energia e de "
                "oxigênio do planeta. A equação geral é:\n\n"
                "6 CO2 + 6 H2O + luz → C6H12O6 + 6 O2\n\n"
                "A fotossíntese ocorre nos cloroplastos (organelas vegetais "
                "que contêm clorofila). Divide-se em duas fases:\n\n"
                "FASE CLARA (fotoquímica): ocorre nas membranas dos tilacoides "
                "(dentro dos cloroplastos). A clorofila absorve luz, excitando "
                "seus elétrons. Esses elétrons passam por uma cadeia de "
                "transporte (fotossistemas I e II), produzindo ATP (por "
                "fotofosforilação) e NADPH. A água é fotolisada (quebrada "
                "pela luz), liberando O2, elétrons e prótons. É a fase que "
                "produz o oxigênio que respiramos.\n\n"
                "FASE ESCURA (ciclo de Calvin): ocorre no estroma do "
                "cloroplasto (fluido interno). Não precisa de luz direta, "
                "mas usa o ATP e o NADPH produzidos na fase clara. O CO2 é "
                "fixado pela enzima RuBisCO (ribulose-1,5-bifosfato "
                "carboxilase/oxigenase) e convertido em glicose através de "
                "um ciclo de reações. A RuBisCO é a proteína mais abundante "
                "da Terra.\n\n"
                "FOTOFOSFORILAÇÃO: pode ser não-cíclica (produz ATP + NADPH "
                "+ O2) ou cíclica (produz apenas ATP, sem O2 nem NADPH). A "
                "não-cíclica é a principal.\n\n"
                "DIFERENÇA RESPIRAÇÃO vs FOTOSSÍNTESE:\n"
                "- Respiração: consome O2 e glicose, produz CO2 e H2O, "
                "libera energia. Ocorre em todas as células, dia e noite.\n"
                "- Fotossíntese: consome CO2 e H2O, usa luz, produz glicose "
                "e O2, armazena energia. Ocorre apenas em células com "
                "clorofila, apenas com luz.\n"
                "- Ambas usam cadeia de transporte de elétrons e ATP sintase."
            ),
            "exemplo": (
                "A fotossíntese é responsável por quase todo o oxigênio da "
                "atmosfera terrestre. Há cerca de 2,5 bilhões de anos, as "
                "cianobactérias começaram a fazer fotossíntese e liberar O2. "
                "Esse processo, chamado \"Grande Oxidação\", transformou a "
                "atmosfera de anaeróbica para aeróbica, permitindo o "
                "surgimento de organismos aeróbios (como nós). Sem "
                "fotossíntese, não haveria O2 para respirar nem alimento "
                "(a glicose produzida pelas plantas é a base de todas as "
                "cadeias alimentares)."
            ),
        },
        {
            "titulo": "5. Quimiossíntese e Balanço Energético",
            "conteudo": (
                "QUIMIOSSÍNTESE: algumas bactérias não usam luz como fonte "
                "de energia, mas sim reações químicas inorgânicas. Elas "
                "oxidam compostos como H2S (sulfeto de hidrogênio), NH3 "
                "(amônia), Fe2+ (ferro) ou CH4 (metano) para obter energia "
                "e produzir ATP. Com essa energia, fixam CO2 e produzem "
                "glicose — como na fotossíntese, mas sem luz.\n\n"
                "Exemplos: bactérias sulfurosas (em fontes termais e "
                "fumarolas submarinas), bactérias nitrificantes (no solo, "
                "oxidam amônia a nitrito e nitrito a nitrato — importante "
                "para o ciclo do nitrogênio), bactérias ferro-oxidantes.\n\n"
                "As comunidades de fumarolas submarinas (hidrotermais) são "
                "baseadas em quimiossíntese: sem luz (a milhares de metros "
                "de profundidade), as bactérias quimiossintéticas são a base "
                "da cadeia alimentar, sustentando vermes tubícolas, "
                "crustáceos e outros organismos.\n\n"
                "BALANÇO ENERGÉTICO COMPARADO:\n"
                "- Respiração aeróbica: 36-38 ATP por glicose. Muito "
                "eficiente. Ocorre na maioria das células.\n"
                "- Fermentação: 2 ATP por glicose. Pouco eficiente, mas "
                "permite sobrevivência sem O2.\n"
                "- Fotossíntese: consome energia luminosa para produzir "
                "glicose. Não produz ATP para a célula diretamente, mas "
                "armazena energia na glicose que será usada na respiração.\n"
                "- Quimiossíntese: consome energia química inorgânica para "
                "produzir glicose. Similar à fotossíntese, mas sem luz.\n\n"
                "ANABOLISMO vs CATABOLISMO:\n"
                "- Catabolismo: quebra moléculas grandes em pequenas, "
                "liberando energia (ex: respiração, fermentação, digestão).\n"
                "- Anabolismo: sintetiza moléculas grandes a partir de "
                "pequenas, consumindo energia (ex: fotossíntese, síntese de "
                "proteínas, síntese de gorduras)."
            ),
            "exemplo": (
                "O metabolismo dos tumores é diferente do normal. As células "
                "tumorais, mesmo com oxigênio disponível, preferem fazer "
                "fermentação lática em vez de respiração aeróbica — fenômeno "
                "conhecido como \"efeito Warburg\", descoberto por Otto Warburg "
                "em 1924 (ele recebeu o Nobel de Fisiologia em 1931 por outro "
                "trabalho). A razão: a fermentação é menos eficiente em ATP, "
                "mas permite que a célula tumoral use os intermediários da "
                "glicólise para sintetizar aminoácidos, nucleotídeos e lipídios "
                "necessários à sua rápida multiplicação. O exame PET com "
                "FDG (fluordesoxiglicose marcada com flúor-18) explora esse "
                "fato: tumores consomem muita glicose e aparecem como pontos "
                "brilhantes no exame."
            ),
        },
    ],
    "resumo": (
        "- ATP: moeda energética. Hidrólise libera ~7,3 kcal/mol. Reciclado continuamente.\n"
        "- Respiração aeróbica: glicose + O2 → CO2 + H2O + 36-38 ATP. 4 etapas.\n"
        "- Glicólise (hialoplasma): glicose → 2 piruvato + 2 ATP + 2 NADH. Sem O2.\n"
        "- Descarboxilação: piruvato → acetil-CoA + CO2 + NADH (mitocôndria).\n"
        "- Ciclo de Krebs (matriz): acetil-CoA → 2 CO2 + 3 NADH + 1 FADH2 + 1 ATP por volta.\n"
        "- Cadeia respiratória (membrana interna): NADH→3 ATP, FADH2→2 ATP. O2 é aceptor final.\n"
        "- Fermentação: anaeróbica, 2 ATP. Lática (músculo, iogurte) ou alcoólica (levedura, pão, cerveja).\n"
        "- Fotossíntese: CO2 + H2O + luz → glicose + O2. Fase clara (tilacoide, produz ATP+NADPH+O2) e fase escura (Calvin, fixa CO2).\n"
        "- Quimiossíntese: bactérias usam energia química inorgânica em vez de luz.\n"
        "- Efeito Warburg: tumores preferem fermentação mesmo com O2 disponível."
    ),
    "dicas": [
        "Decore as 4 etapas da respiração: glicólise (hialoplasma), descarboxilação, Krebs e cadeia respiratória (mitocôndria).",
        "Glicólise: 2 ATP, 2 NADH, 2 piruvato. Não precisa de O2 nem mitocôndria. É comum à respiração e à fermentação.",
        "Cadeia respiratória: NADH = 3 ATP, FADH2 = 2 ATP. O2 é o aceptor final de elétrons (forma H2O).",
        "Fermentação: lática (músculo + Lactobacillus) ou alcoólica (levedura: etanol + CO2). Só 2 ATP.",
        "Fotossíntese: fase clara (tilacoide, O2, ATP, NADPH) e fase escura (estroma, ciclo de Calvin, fixa CO2).",
        "Efeito Warburg: tumores preferem glicólise/fermentação. Base do exame PET-FDG.",
    ],
    "pegadinhas": [
        "Achar que a glicólise ocorre na mitocôndria: ela ocorre no hialoplasma. Só as demais etapas são na mitocôndria.",
        "Confundir o O2 na respiração com o O2 na fotossíntese: na respiração, O2 é consumido e é o aceptor final de elétrons; na fotossíntese, O2 é produzido pela fotólise da água.",
        "Achar que a fermentação produz muito ATP: ela produz apenas 2 ATP (da glicólise). O restante da energia fica no lactato ou etanol.",
        "Confundir fase clara com fase escura da fotossíntese: a clara produz ATP, NADPH e O2; a escura (Calvin) usa esses produtos para fixar CO2 em glicose.",
        "Esquecer que a RuBisCO é a proteína mais abundante da Terra — cai em prova!",
        "Achar que a quimiossíntese usa luz: ela usa energia de reações químicas inorgânicas (H2S, NH3, Fe2+).",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "NELSON, D. L.; COX, M. M. Lehninger Princípios de Bioquímica. 7. ed. São Paulo: Sarvier, 2017.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Metabolismo Celular")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_METABOLISMO_CELULAR.pdf"

    images_data = [
        {"file": "br_met_respiracao_be.jpg",
         "caption": "Respiração celular aeróbica: glicose + O2 → CO2 + H2O + ATP",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/respiracao-celular.htm"},
        {"file": "br_met_glicolise_tm.jpg",
         "caption": "Glicólise: glicose é quebrada em dois piruvatos no hialoplasma",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/respiracao-celular/"},
        {"file": "br_met_krebs_be.jpg",
         "caption": "Ciclo de Krebs: oxidação do acetil-CoA na matriz mitocondrial",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/respiracao-celular.htm"},
        {"file": "br_met_fosforilacao.jpg",
         "caption": "Fosforilação oxidativa: cadeia respiratória e ATP sintase",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/respiracao-celular/"},
        {"file": "br_met_fermentacao_me1.jpg",
         "caption": "Fermentação lática e alcoólica: processos anaeróbicos de obtenção de ATP",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/fermentacao.htm"},
        {"file": "br_met_fotossintese.jpg",
         "caption": "Fotossíntese: conversão de energia luminosa em energia química",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/fotossintese.htm"},
        {"file": "br_met_ciclo_calvin.jpg",
         "caption": "Ciclo de Calvin (fase escura): fixação do CO2 em glicose",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/fotossintese/"},
        {"file": "br_met_cloroplasto.jpg",
         "caption": "Cloroplasto: organela onde ocorre a fotossíntese",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/fotossintese.htm"},
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
