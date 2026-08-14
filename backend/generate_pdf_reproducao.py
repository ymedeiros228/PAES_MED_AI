# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Reprodução e Embriologia.

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
    "titulo": "Reprodução e Embriologia",
    "disciplina": "Biologia",
    "topico": "Reprodução e Embriologia",
    "subtopico": "Reprodução, Sistemas Reprodutores e Desenvolvimento Embrionário",
    "introducao": (
        "A reprodução é a propriedade fundamental dos seres vivos de gerar "
        "descendentes, garantindo a continuidade da espécie. Existem dois "
        "tipos principais: assexuada (um único progenitor, sem gametas) e "
        "sexuada (dois progenitores, com gametas e fecundação).\n\n"
        "Nos seres humanos, a reprodução sexuada envolve os sistemas "
        "reprodutores masculino e feminino, a formação de gametas, a "
        "fecundação e o desenvolvimento embrionário. Compreender esses "
        "processos é essencial para a Medicina: é a base da obstetrícia, "
        "da genética clínica, da reprodução assistida e do aconselhamento "
        "contraceptivo.\n\n"
        "Este material aborda os tipos de reprodução, os sistemas "
        "reprodutores humanos, os métodos contraceptivos, as fases do "
        "desenvolvimento embrionário e os anexos embrionários."
    ),
    "secoes": [
        {
            "titulo": "1. Reprodução Assexuada",
            "conteudo": (
                "A reprodução assexuada ocorre sem a participação de gametas "
                "e sem fecundação. Um único indivíduo origina descendentes "
                "geneticamente idênticos a si (clones). É comum em bactérias, "
                "protozoários, fungos, plantas e alguns animais.\n\n"
                "PRINCIPAIS TIPOS:\n\n"
                "DIVISÃO BINÁRIA (cissiparidade): a célula se divide em duas "
                "iguais. Ocorre em bactérias e protozoários. É a forma mais "
                "simples e rápida de reprodução.\n\n"
                "BROTAMENTO (gemiparidade): formam-se brotos (gêmulas) no "
                "corpo do indivíduo, que crescem e se separam. Ocorre em "
                "esponjas, cnidários (hidra) e leveduras.\n\n"
                "FRAGMENTAÇÃO (esquizogênese): o corpo do indivíduo se "
                "fragmenta em pedaços, e cada pedaço regenera um indivíduo "
                "completo. Ocorre em planárias, estrelas-do-mar e algumas "
                "algas.\n\n"
                "PARTENOGENÊNESE: o óvulo se desenvolve sem ser fecundado. "
                "Ocorre em alguns insetos (abelhas — os machos (zangões) "
                "nascem de óvulos não fecundados), répteis (alguns lagartos) "
                "e peixes.\n\n"
                "PROPAGAÇÃO VEGETATIVA: nas plantas, estruturas como "
                "estolhos, rizomas, bulbos e tubérculos originam novos "
                "indivíduos. Exemplos: batata (tubérculo), cebola (bulbo), "
                "morango (estolho).\n\n"
                "VANTAGENS: rápida, não precisa de parceiro, útil em "
                "ambientes estáveis.\n"
                "DESVANTAGENS: não gera variabilidade genética — todos os "
                "descendentes são idênticos, vulneráveis às mesmas doenças "
                "e mudanças ambientais."
            ),
            "exemplo": (
                "A reprodução assexuada é explorada na agricultura e na "
                "biotecnologia. A propagação vegetativa por estacas permite "
                "multiplicar plantas com características desejáveis (como "
                "variedades de manga, uva e laranja) mantendo os mesmos "
                "genes. A clonagem por cultura de tecidos vegetais é usada "
                "para produzir milhares de mudas idênticas em laboratório. "
                "Na medicina, a divisão binária das bactérias é o motivo "
                "pelo qual uma única bactéria pode originar uma colônia "
                "inteira — e por isso os antibióticos precisam ser usados "
                "corretamente, para evitar a seleção de bactérias resistentes."
            ),
        },
        {
            "titulo": "2. Reprodução Sexuada e Fecundação",
            "conteudo": (
                "A reprodução sexuada envolve a participação de gametas "
                "(espermatozoide e óvulo) e a fecundação — a fusão dos dois "
                "gametas para formar o zigoto. Os descendentes são "
                "geneticamente diferentes dos pais e entre si.\n\n"
                "VANTAGENS: gera variabilidade genética (por crossing-over, "
                "segregação independente e fecundação ao acaso), o que "
                "aumenta a adaptação da espécie a ambientes variáveis.\n"
                "DESVANTAGENS: mais lenta, precisa de dois progenitores, "
                "investe mais energia na produção de gametas.\n\n"
                "FECUNDAÇÃO: pode ser:\n"
                "- Externa: ocorre fora do corpo da fêmea, no ambiente "
                "(água). Comum em peixes, anfíbios e alguns invertebrados "
                "aquáticos. Os gametas são liberados na água e se encontram "
                "ao acaso. Exige grande quantidade de gametas.\n"
                "- Interna: ocorre dentro do corpo da fêmea. Comum em "
                "répteis, aves, mamíferos e insetos. O macho deposita os "
                "espermatozoides no trato reprodutor da fêmea. Produz "
                "menos gametas, mas com maior chance de fecundação.\n\n"
                "TIPOS DE OVOS (segundo a quantidade de vitelo):\n"
                "- Oligolécitos: pouco vitelo, distribuição homogênea "
                "(mamíferos, equinodermos).\n"
                "- Mesolécitos: vitelo moderado, distribuição heterogênea "
                "(anfíbios, peixes ósseos).\n"
                "- Telolécitos: muito vitelo, polarizado (aves, répteis, "
                "peixes cartilaginosos).\n"
                "- Centrolécitos: vitelo no centro (insetos).\n\n"
                "TIPOS DE CLIVAGEM (divisões do zigoto):\n"
                "- Total (holoblástica): divide o ovo todo. Ocorre em "
                "oligolécitos e mesolécitos.\n"
                "- Parcial (meroblástica): divide só o disco germinativo. "
                "Ocorre em telolécitos (aves, répteis).\n"
                "- Superficial: o núcleo se divide, mas o citoplasma não "
                "logo de início. Ocorre em centrolécitos (insetos)."
            ),
            "exemplo": (
                "A fecundação humana é interna. Após a relação sexual, "
                "cerca de 200-300 milhões de espermatozoides são "
                "depositados na vagina. Apenas cerca de 200 chegam à "
                "trompa de Falópio, onde a fecundação ocorre. Apenas UM "
                "espermatozoide fecunda o óvulo. Após a penetração, o "
                "óvulo ativa o bloqueio de polispermia (mudanças na zona "
                "pelúcida) para impedir a entrada de outros espermatozoides. "
                "Se dois espermatozoides fecundarem o óvulo, pode resultar "
                "em mosaico ou trigêmeos — situações muito raras."
            ),
        },
        {
            "titulo": "3. Sistema Reprodutor Masculino",
            "conteudo": (
                "O sistema reprodutor masculino produz espermatozoides e "
                "hormônios sexuais (testosterona). É composto por:\n\n"
                "TESTÍCULOS: gônadas masculinas, localizadas na bolsa "
                "escrotal (fora do abdômen, a 2-3°C abaixo da temperatura "
                "corporal — necessário para a espermatogênese). Contêm os "
                "túbulos seminíferos (onde ocorre a espermatogênese) e as "
                "células de Leydig (que produzem testosterona).\n\n"
                "EPIDÍDIMO: tubo enrolado sobre cada testículo, onde os "
                "espermatozoides terminam a maturação e adquirem motilidade. "
                "Armazena os espermatozoides até a ejaculação.\n\n"
                "CANAL DEFERENTE: conduz os espermatozoides do epidídimo "
                "até a uretra.\n\n"
                "GLÂNDULAS ANEXAS:\n"
                "- Vesículas seminais: produzem o líquido seminal (rico em "
                "frutose, que fornece energia aos espermatozoides). "
                "Corresponde a cerca de 60% do volume do sêmen.\n"
                "- Próstata: produz o líquido prostático (levemente "
                "alcalino, neutraliza a acidez da vagina). Cerca de 30% "
                "do volume.\n"
                "- Glândulas bulbouretrais (de Cowper): produzem um "
                "muco que lubrifica a uretra e neutraliza a acidez. "
                "Pode conter espermatozoides — por isso o coito "
                "interrompido não é seguro.\n\n"
                "PÊNIS: órgão copulador. Apresenta corpos cavernosos e "
                "esponjoso, que se enchem de sangue durante a ereção.\n\n"
                "URETRA: canal que passa pelo pênis e conduz tanto a "
                "urina quanto o sêmen (nunca ao mesmo tempo).\n\n"
                "HORMÔNIOS: a testosterona é produzida pelas células de "
                "Leydig, estimulada pelo LH (hipófise). O FSH estimula a "
                "espermatogênese. A inibina (produzida pelos túbulos) "
                "inibe o FSH — feedback negativo."
            ),
            "exemplo": (
                "A hiperplasia benigna da próstata (HBP) é muito comum "
                "em homens acima de 50 anos — cerca de 50% dos homens "
                "acima de 60 anos têm algum grau. A próstata cresce e "
                "comprime a uretra, causando dificuldade para urinar, "
                "jato fraco e vontade frequente. O câncer de próstata é "
                "o segundo mais comum em homens (atrás apenas do câncer "
                "de pele). O rastreamento é feito pelo PSA (antígeno "
                "prostático específico) no sangue e pelo toque retal. "
                "Recomenda-se rastreamento a partir dos 50 anos (ou 45 "
                "se houver histórico familiar)."
            ),
        },
        {
            "titulo": "4. Sistema Reprodutor Feminino",
            "conteudo": (
                "O sistema reprodutor feminino produz óvulos e hormônios "
                "sexuais (estrogênio e progesterona). É composto por:\n\n"
                "OVÁRIOS: gônadas femininas, localizados na pelve. "
                "Produzem os óvulos (por ovogênese) e os hormônios "
                "estrogênio e progesterona. Ao nascer, a mulher tem cerca "
                "de 1-2 milhões de ovócitos; na puberdade, cerca de "
                "300-400 mil; ao longo da vida, apenas cerca de 400 serão "
                "ovulados.\n\n"
                "TROMPAS DE FALÓPIO (ovidutos): conduzem o óvulo do ovário "
                "ao útero. É onde ocorre a fecundação. Têm franjas "
                "(fímbrias) que capturam o óvulo na ovulação.\n\n"
                "ÚTERO: órgão muscular oco onde o embrião se implanta e "
                "se desenvolve. A parede interna é o endométrio (que se "
                "espessa a cada ciclo e descama na menstruação se não "
                "houver gravidez). A parede muscular é o miométrio "
                "(responsável pelas contrações do parto).\n\n"
                "VAGINA: canal que liga o útero ao exterior. Recebe o "
                "pênis na relação sexual e serve de canal de parto.\n\n"
                "VULVA: conjunto de estruturas externas (grandes e "
                "pequenos lábios, clitóris, vestíbulo).\n\n"
                "CICLO MENSTRUAL (duração média: 28 dias):\n"
                "- FASE FOLICULAR (dias 1-13): o FSH estimula o "
                "crescimento de folículos ovarianos, que produzem "
                "estrogênio. O estrogênio faz o endométrio se espessar.\n"
                "- OVULAÇÃO (dia 14): o pico de LH provoca a ruptura do "
                "folículo maduro e a liberação do óvulo.\n"
                "- FASE LÚTEA (dias 15-28): o folículo rompido vira "
                "corpo lúteo, que produz progesterona. A progesterona "
                "mantém o endométrio. Se não houver gravidez, o corpo "
                "lúteo degenera, os hormônios caem e o endométrio "
                "descama — menstruação (dia 1 do novo ciclo).\n"
                "- Se houver gravidez, o hCG (hormônio do embrião) "
                "mantém o corpo lúteo, que continua produzindo "
                "progesterona até a placenta assumir."
            ),
            "exemplo": (
                "O ciclo menstrual é a base de vários métodos "
                "contraceptivos hormonais. A pílula anticoncepcional "
                "combina estrogênio e progesterona, que inibem o pico de "
                "LH e, portanto, a ovulação. Sem ovulação, não há "
                "fecundação. A pílula também altera o muco cervical "
                "(fica mais espesso, dificultando a passagem dos "
                "espermatozoides) e o endométrio (fica mais fino, "
                "dificultando a implantação). Por isso, a pílula atua "
                "em três frentes, o que a torna muito eficaz (99,7% "
                "com uso correto)."
            ),
        },
        {
            "titulo": "5. Métodos Contraceptivos",
            "conteudo": (
                "Os métodos contraceptivos visam evitar a gravidez "
                "indesejada e, em alguns casos, proteger contra DSTs. "
                "Dividem-se em:\n\n"
                "MÉTODOS DE BARREIRA: impedem o encontro entre "
                "espermatozoide e óvulo.\n"
                "- Camisinha masculina: única que também protege contra "
                "DSTs. Eficácia: 98% com uso correto.\n"
                "- Camisinha feminina: também protege contra DSTs. "
                "Eficácia: 95%.\n"
                "- Diafragma: copa de silicone que cobre o colo do "
                "útero. Deve ser usado com espermicida. Eficácia: 88-94%.\n"
                "- Espermicidas: substâncias que matam ou imobilizam "
                "os espermatozoides. Eficácia baixa (72-82%).\n\n"
                "MÉTODOS HORMONAIS: inibem a ovulação.\n"
                "- Pílula anticoncepcional: estrogênio + progesterona. "
                "Eficácia: 99,7%.\n"
                "- Pílula do dia seguinte: alta dose de levonorgestrel. "
                "Toma-se até 72 horas após a relação. Não é abortiva — "
                "impede a ovulação. Se a fecundação já ocorreu, não "
                "funciona.\n"
                "- Injetável mensal/trimestral: estrogênio + progesterona.\n"
                "- Anel vaginal: libera hormônios gradualmente.\n"
                "- Adesivo cutâneo: libera hormônios pela pele.\n"
                "- Minipílula: só progesterona. Pode ser usada na "
                "amamentação.\n\n"
                "MÉTODOS INTRAUTERINOS:\n"
                "- DIU de cobre: libera íons de cobre, que são "
                "espermicidas. Dura 10 anos. Não tem hormônio.\n"
                "- DIU hormonal (Mirena): libera progesterona. Dura "
                "5 anos. Reduz o fluxo menstrual.\n\n"
                "MÉTODOS CIRÚRGICOS (definitivos):\n"
                "- Laqueadura tubária: ligadura das trompas. Impede o "
                "encontro entre óvulo e espermatozoide.\n"
                "- Vasectomia: ligadura dos canais deferentes. Impede "
                "a passagem dos espermatozoides. Não afeta a ereção "
                "nem a produção de testosterona.\n\n"
                "MÉTODOS COMPORTAMENTAIS (baixa eficácia):\n"
                "- Tabelinha (Ogino-Knaus): evitar relação no período "
                "fértil. Eficácia baixa (76-80%).\n"
                "- Coito interrompido: retirar o pênis antes da "
                "ejaculação. Eficácia muito baixa (78%) — o líquido "
                "pré-ejaculatório pode conter espermatozoides.\n"
                "- Amamentação (LAM): a amamentação inibe a ovulação "
                "nos primeiros 6 meses. Eficácia: 98% se seguido "
                "estritamente."
            ),
            "exemplo": (
                "A camisinha (masculina ou feminina) é o ÚNICO método "
                "contraceptivo que também protege contra DSTs (HIV, "
                "sífilis, gonorreia, HPV, herpes). Por isso, mesmo "
                "usando outro método (como a pílula), recomenda-se o "
                "uso da camisinha para proteção dupla. O HPV é a DST "
                "mais comum no mundo e a principal causa de câncer de "
                "colo de útero — a vacina contra HPV (recomendada para "
                "meninas de 9-14 anos e meninos de 11-14 anos) é uma "
                "estratégia fundamental de prevenção."
            ),
        },
        {
            "titulo": "6. Desenvolvimento Embrionário",
            "conteudo": (
                "O desenvolvimento embrionário começa com a fecundação "
                "e vai até a formação do feto. Divide-se em fases:\n\n"
                "FECUNDAÇÃO: espermatozoide + óvulo → zigoto (2n). "
                "Ocorre na trompa de Falópio. O zigoto é uma célula "
                "totipotente — pode originar um indivíduo completo.\n\n"
                "CLIVAGEM: o zigoto se divide por mitose em várias "
                "células menores (blastômeros), sem aumentar o tamanho "
                "total. Forma-se a mórula (16 células, parece uma "
                "amora).\n\n"
                "BLASTULAÇÃO: a mórula continua dividindo e forma uma "
                "cavidade (blastocele). Agora é uma blástula. Em "
                "mamíferos, chama-se blastocisto — tem uma massa "
                "celular interna (que formará o embrião) e uma camada "
                "externa (trofoblasto, que formará os anexos).\n\n"
                "GASTRULAÇÃO: as células se reorganizam, formando três "
                "folhetos embrionários (ectoderme, mesoderme e "
                "endoderme). Agora é uma gástrula. Cada folheto dará "
                "origem a tecidos específicos:\n"
                "- ECTODERME: epiderme, sistema nervoso (cérebro, "
                "medula), olhos, ouvidos, esmalte dentário.\n"
                "- MESODERME: músculos, ossos, sangue, coração, rins, "
                "gonadas, derme.\n"
                "- ENDODERME: tubo digestório, fígado, pâncreas, "
                "pulmões, tireoide, timo.\n\n"
                "NEURULAÇÃO: a ectoderme dorsal forma a placa neural, "
                "que se dobrada em tubo neural — origem do sistema "
                "nervoso. Falhas na neurulação causam anencefalia e "
                "espinha bífida.\n\n"
                "ORGANOGÊNESE: os folhetos se diferenciam em órgãos. "
                "O embrião já tem a forma básica do organismo.\n\n"
                "NOMENCLATURA:\n"
                "- Zigoto: da fecundação à primeira clivagem.\n"
                "- Embrião: da implantação (cerca de 7 dias) até a 8ª "
                "semana. Nesse período, os órgãos se formam.\n"
                "- Feto: da 9ª semana até o nascimento. Os órgãos já "
                "estão formados e amadurecem."
            ),
            "exemplo": (
                "A diferenciação dos folhetos embrionários explica "
                "várias malformações. O ácido fólico (vitamina B9) é "
                "essencial para a neurulação — sua deficiência nas "
                "primeiras semanas de gravidez aumenta o risco de "
                "espinha bífida (o tubo neural não fecha). Por isso, "
                "recomenda-se que mulheres em idade reprodutiva "
                "ingiram 400 mcg de ácido fólico por dia, mesmo antes "
                "de engravidar — pois a neurulação ocorre antes de a "
                "mulher saber que está grávida (cerca de 28 dias). A "
                "talidomida, usada nos anos 1960 contra enjoo na "
                "gravidez, causou malformações graves (focomelia — "
                "membros curtos) por afetar a organogênese. Por isso, "
                "medicamentos na gravidez devem ser avaliados com "
                "cuidado."
            ),
        },
        {
            "titulo": "7. Anexos Embrionários",
            "conteudo": (
                "Os anexos embrionários são estruturas que auxiliam o "
                "desenvolvimento do embrião. Nos mamíferos, são quatro:\n\n"
                "PLACENTA: órgão temporário formado pela associação do "
                "tecido embrionário (corião) com o tecido materno "
                "(endométrio). Funções:\n"
                "- Nutrição: passa nutrientes da mãe para o feto;\n"
                "- Respiração: O2 entra e CO2 sai;\n"
                "- Excreção: elimina resíduos do feto para a mãe;\n"
                "- Imunidade: passa anticorpos (IgG) da mãe para o "
                "feto, conferindo imunidade passiva nos primeiros "
                "meses de vida;\n"
                "- Hormônios: produz hCG (mantém o corpo lúteo), "
                "estrogênio e progesterona (mantêm a gravidez).\n"
                "A placenta NÃO liga o sangue da mãe ao do feto — "
                "há uma barreira placentária que impede a passagem "
                "de algumas substâncias, mas não todas. Vírus (HIV, "
                "rubéola, Zika), drogas, álcool e alguns medicamentos "
                "atravessam a placenta.\n\n"
                "CORDÃO UMBILICAL: liga o feto à placenta. Contém duas "
                "artérias (levam sangue do feto à placenta, com CO2 e "
                "resíduos) e uma veia (traz sangue da placenta ao "
                "feto, com O2 e nutrientes). É o inverso do que se "
                "espera — a veia traz sangue oxigenado.\n\n"
                "SACO AMNIÓTICO (âmnio): membrana que forma a bolsa "
                "de líquido amniótico, onde o feto fica suspenso. "
                "Funções: proteção mecânica (amortece impactos), "
                "manutenção da temperatura, permite movimentos. O "
                "líquido amniótico é renovado continuamente — o feto "
                "engole e urina. A amniocentese (análise do líquido) "
                "permite diagnosticar anomalias cromossômicas.\n\n"
                "CORIÓN: membrana externa que envolve o embrião e os "
                "demais anexos. Em mamíferos, participa da formação "
                "da placenta (porção fetal).\n\n"
                "EM OUTROS ANIMAIS:\n"
                "- Aves e répteis: saco vitelínico (nutrição), "
                "córion, âmnio e alantoide (respiração e excreção). "
                "O ovo é cleidoico (casca rígida).\n"
                "- Peixes e anfíbios: geralmente não têm âmnio — "
                "o desenvolvimento ocorre na água."
            ),
            "exemplo": (
                "A placenta é o único órgão formado por tecidos de "
                "dois indivíduos diferentes (mãe e feto). Doenças "
                "como pré-eclâmpsia (hipertensão na gravidez) "
                "resultam de problemas na formação placentária. O "
                "exame de NIPT (teste não invasivo de pré-natal) "
                "analisa fragmentos de DNA fetal que cruzam a "
                "placenta e chegam ao sangue materno — permitindo "
                "diagnosticar trissomias sem risco para o feto. "
                "A cordocentese (punctura do cordão umbilical) "
                "permite colher sangue fetal para exames genéticos "
                "e transfusões em casos de isoimunização Rh (quando "
                "a mãe é Rh- e o feto Rh+)."
            ),
        },
    ],
    "resumo": (
        "- Reprodução assexuada: sem gametas, clones. Tipos: divisão binária, brotamento, fragmentação, partenogênese.\n"
        "- Reprodução sexuada: com gametas e fecundação. Gera variabilidade genética.\n"
        "- Fecundação: externa (na água) ou interna (no corpo da fêmea).\n"
        "- Sistema masculino: testículos, epidídimo, deferente, vesículas seminais, próstata, pênis.\n"
        "- Sistema feminino: ovários, trompas, útero, vagina. Ciclo menstrual: folicular, ovulação, lútea.\n"
        "- Contraceptivos: barreira (camisinha), hormonais (pílula), DIU, cirúrgicos (laqueadura, vasectomia).\n"
        "- Camisinha é o ÚNICO que protege contra DSTs.\n"
        "- Desenvolvimento: zigoto → clivagem (mórula) → blástula → gastrulação (3 folhetos) → neurulação → órgãos.\n"
        "- Folhetos: ectoderme (pele, SNC), mesoderme (músculo, osso, sangue), endoderme (digestório, pulmão).\n"
        "- Anexos: placenta, cordão umbilical (2 artérias + 1 veia), âmnio, corião.\n"
        "- Ácido fólico previne espinha bífida. Talidomida causou focomelia."
    ),
    "dicas": [
        "Reprodução assexuada = clones, sem variabilidade. Sexuada = variabilidade, com fecundação.",
        "Cordão umbilical: 2 artérias (sangue do feto, com CO2) + 1 veia (sangue da placenta, com O2). É o inverso do esperado!",
        "Folhetos embrionários: ectoderme (fora — pele, SNC), mesoderme (meio — músculo, osso, sangue), endoderme (dentro — digestório, pulmão).",
        "Camisinha é o único contraceptivo que protege contra DSTs. Use sempre, mesmo com outro método.",
        "Ciclo menstrual: FSH → folículo cresce → estrogênio → pico LH → ovulação (dia 14) → corpo lúteo → progesterona.",
        "Ácido fólico antes e na gravidez previne defeitos do tubo neural (espinha bífida, anencefalia).",
    ],
    "pegadinhas": [
        "Achar que a veia umbilical leva sangue do feto: é o inverso — a veia traz sangue oxigenado da placenta para o feto.",
        "Confundir embrião com feto: embrião é até a 8ª semana (formação dos órgãos); feto é da 9ª semana em diante (amadurecimento).",
        "Achar que a pílula do dia seguinte é abortiva: ela impede a ovulação. Se a fecundação já ocorreu, não funciona.",
        "Esquecer que o líquido pré-ejaculatório pode conter espermatozoides — por isso o coito interrompido é pouco eficaz.",
        "Confundir fecundação externa com interna: externa ocorre na água (peixes, anfíbios); interna no corpo da fêmea (répteis, aves, mamíferos).",
        "Achar que a placenta mistura o sangue da mãe com o do feto: há uma barreira placentária. Substâncias passam por difusão, não por mistura direta.",
    ],
    "referencias": [
        "ALBERTS, Bruce et al. Biologia Molecular da Célula. 6. ed. Porto Alegre: Artmed, 2017.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "MOORE, K. L.; PERSAUD, T. V. N. Embriologia Clínica. 10. ed. Rio de Janeiro: Elsevier, 2016.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Reprodução e Embriologia")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_REPRODUCAO_EMBRIOLOGIA.pdf"

    images_data = [
        {"file": "br_rep_divisao_binaria.jpg",
         "caption": "Reprodução assexuada: divisão binária em bactérias e protozoários",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/reproducao-assexuada.htm"},
        {"file": "br_rep_fecundacao.jpg",
         "caption": "Fecundação: fusão do espermatozoide com o óvulo formando o zigoto",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/reproducao-sexuada.htm"},
        {"file": "br_rep_sist_masc.jpg",
         "caption": "Sistema reprodutor masculino: anatomia e órgãos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/sistema-reprodutor-masculino.htm"},
        {"file": "br_rep_sist_fem.jpg",
         "caption": "Sistema reprodutor feminino: ovários, trompas, útero e vagina",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/sistema-reprodutor-feminino.htm"},
        {"file": "br_rep_contracep.jpg",
         "caption": "Métodos contraceptivos: barreira, hormonais, DIU e cirúrgicos",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/metodos-contraceptivos.htm"},
        {"file": "br_rep_folhetos.jpg",
         "caption": "Folhetos embrionários: ectoderme, mesoderme e endoderme e suas derivações",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/folhetos-embrionarios/"},
        {"file": "br_rep_anexos_tm.jpg",
         "caption": "Anexos embrionários: placenta, cordão umbilical, âmnio e corião",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/anexos-embrionarios/"},
        {"file": "br_rep_placenta.jpg",
         "caption": "Placenta: órgão temporário de trocas entre mãe e feto",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/anexos-embrionarios.htm"},
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
