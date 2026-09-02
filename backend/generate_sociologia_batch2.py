"""Gera PDFs de Sociologia — batch 2 (topicos 11.4 a 11.6)."""

from pdf_base import generate_educational_pdf
from sociologia_real_images import REAL_IMAGES

# ============================================================
# 11.4 Mudanca Social
# ============================================================
MUDANCA = {
    "titulo": "Mudanca Social",
    "disciplina": "Sociologia",
    "topico": "Mudanca Social",
    "subtopico": "Estratificacao, mobilidade e desigualdade",
    "introducao": (
        "A mudanca social estuda como sociedades se transformam. "
        "Estratificacao, mobilidade e desigualdade sao conceitos "
        "centrais para entender como grupos se organizam e "
        "mudam ao longo do tempo."
    ),
    "secoes": [
        {
            "titulo": "1. Estratificacao social",
            "conteudo": (
                "ESTRATIFICACAO: divisao da sociedade em camadas "
                "(estratos) hierarquizadas.\n\n"
                "TIPOS HISTORICOS:\n"
                "- Caste: hereditaria, religiosa (India).\n"
                "- Estado: baseada em riqueza e poder.\n"
                "- Classe: economica (Marx, Weber).\n\n"
                "CLASSE SOCIAL:\n"
                "- Marx: classe em si (posicao) x classe para si "
                "(consciencia).\n"
                "- Weber: classe (economia), status (prestigio), "
                "partido (poder).\n"
                "- Classes: burguesia, proletariado, classe media.\n\n"
                "ESTRATIFICACAO NO BRASIL:\n"
                "- Classes A/B (elite), C (media), D/E (baixa).\n"
                "- Mobilidade restrita: heranca reproduz posicao."
            ),
            "exemplo": (
                "No Brasil, um filho de familia de classe A tem "
                "muito mais chance de permanecer na classe A do "
                "que um filho de classe E chegar la. A escola "
                "privada, as conexoes, a heranca reproduzem a "
                "posicao social. Isso mostra que a estratificacao "
                "nao e so economica: e tambem cultural e social."
            ),
        },
        {
            "titulo": "2. Mobilidade social",
            "conteudo": (
                "MOBILIDADE SOCIAL: movimento de pessoas entre "
                "estratos sociais.\n\n"
                "TIPOS:\n"
                "- Vertical: sobe (ascendente) ou desce (descendente).\n"
                "- Horizontal: muda de posicao, mesma hierarquia.\n"
                "- Intergeracional: entre geracoes (pai->filho).\n"
                "- Intragageracional: na propria carreira.\n\n"
                "FATORES DE MOBILIDADE:\n"
                "- Educacao: principal canal de ascensao.\n"
                "- Economia: crescimento cria oportunidades.\n"
                "- Politicas publicas: cotas, bolsa-familia.\n"
                "- Migracoes: campo->cidade, internacional.\n\n"
                "MOBILIDADE NO BRASIL:\n"
                "- Ascendente nos anos 2000 (commodities, programas sociais).\n"
                "- Estagnacao apos 2014 (crise).\n"
                "- Mobilidade intergeracional ainda baixa."
            ),
            "exemplo": (
                "Um filho de pais analfabetos que se forma medico "
                "teve mobilidade vertical ascendente intergeracional. "
                "Nos anos 2000, o Brasil teve mobilidade ascendente "
                "com programas sociais (bolsa-familia, ProUni, "
                "cotas). Mas a crise apos 2014 estagnou essa "
                "mobilidade, mostrando que ela depende do contexto "
                "economico."
            ),
        },
        {
            "titulo": "3. Desigualdade economica e social",
            "conteudo": (
                "DESIGUALDADE ECONOMICA:\n"
                "- Distribuição de renda e riqueza.\n"
                "- Brasil: um dos paises mais desiguais do mundo.\n"
                "- 1% mais rico concentra ~30% da renda.\n"
                "- 50% mais pobre fica com ~10% da renda.\n\n"
                "DESIGUALDADE DE GENERO:\n"
                "- Mulheres recebem ~80% do salario masculino.\n"
                "- Feminicidio: violencia extrema.\n"
                "- Machismo estrutural.\n"
                "- Lei Maria da Penha (2006).\n\n"
                "DESIGUALDADE RACIAL:\n"
                "- Negros: 2x mais probabilidade de pobreza.\n"
                "- Racismo estrutural e institucional.\n"
                "- Encarceramento: 75% negros.\n"
                "- Homicidios: juventude negra principal vitima.\n\n"
                "INTERSECCIONALIDADE: raca + genero + classe se "
                "cruzam. Mulher negra, pobre sofre tripla "
                "desigualdade."
            ),
            "exemplo": (
                "Uma mulher negra, pobre, do Maranhao enfrenta "
                "desigualdade interseccional: raca (racismo), "
                "genero (machismo), classe (pobreza), regiao "
                "(Norte-Nordeste). Cada eixo se reforca. Por isso, "
                "politicas publicas precisam considerar a "
                "interseccionalidade, nao so um fator isolado."
            ),
        },
    ],
    "resumo": (
        "- Estratificacao: sociedade em camadas. Caste, estado, classe.\n"
        "- Classe: Marx (economia), Weber (classe, status, partido).\n"
        "- Mobilidade: vertical, horizontal, intergeracional, intragageracional.\n"
        "- Educacao: principal canal de mobilidade.\n"
        "- Desigualdade: economica, genero, raca, interseccional.\n"
        "- Brasil: um dos paises mais desiguais do mundo."
    ),
    "dicas": [
        "Classe em si (posicao) x classe para si (consciencia) - Marx.",
        "Weber: classe (economia), status (prestigio), partido (poder).",
        "Mobilidade intergeracional: entre geracoes (pai->filho).",
        "Educacao e principal canal de mobilidade social.",
        "Interseccionalidade: raca + genero + classe se cruzam.",
        "Brasil: 1% mais rico concentra ~30% da renda.",
    ],
    "pegadinhas": [
        "Confundir classe (Marx) com status (Weber): classe e economico, status e prestigio.",
        "Achar que mobilidade e so ascendente: tambem pode ser descendente.",
        "Esquecer a interseccionalidade: desigualdades se cruzam.",
        "Achar que racismo e so individual: tambem e estrutural e institucional.",
        "Confundir mobilidade horizontal com vertical: horizontal nao muda hierarquia.",
        "Esquecer que a escola pode reproduzir desigualdade (Bourdieu).",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "MARX, K. O 18 brumario de Luis Bonaparte. Sao Paulo: Boitempo, 2011.",
        "WEBER, M. Economia e sociedade. Brasilia: UnB, 2004.",
        "BOURDIEU, P. A reproducao. Rio de Janeiro: Francisco Alves, 2008.",
        "PIKETTY, T. O capital no seculo XXI. Rio de Janeiro: Intrinseca, 2014.",
    ],
}

IMG_MUDANCA = [
    {"file": "socio_mudanca.png", "caption": "Mudanca social: estratificacao, mobilidade e desigualdade", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_mudanca", [])

# ============================================================
# 11.5 Sociologia da Violencia
# ============================================================
VIOLENCIA = {
    "titulo": "Sociologia da Violencia",
    "disciplina": "Sociologia",
    "topico": "Sociologia da Violencia",
    "subtopico": "Conceito, criminalizacao e tipos de violencia",
    "introducao": (
        "A violencia e fenomeno social, nao so individual. A "
        "sociologia da violencia estuda suas causas estruturais, "
        "seus tipos e a seletividade do sistema penal."
    ),
    "secoes": [
        {
            "titulo": "1. Conceito de violencia",
            "conteudo": (
                "VIOLENCIA: uso de forca para dominar, ferir ou "
                "destruir. Mas vai alem da fisica.\n\n"
                "TIPOS (Galtung):\n"
                "- Direta: agressao fisica, visivel.\n"
                "- Estrutural: sistema que explora, exclui.\n"
                "- Cultural: simbolos que legitimam violencia.\n\n"
                "VIOLENCIA SIMBOLICA (Bourdieu):\n"
                "- Violencia sutíl, naturalizada.\n"
                "- Dominacao que nao parece violencia.\n"
                "- Ex: machismo, racismo internalizados.\n\n"
                "VIOLENCIA ESTRUTURAL:\n"
                "- Desigualdade que mata (pobreza, falta de saude).\n"
                "- Sistema que exclui (sem acesso a educacao).\n"
                "- Nao tem autor direto, mas e real."
            ),
            "exemplo": (
                "A violencia estrutural se manifesta quando uma "
                "crianca negra, pobre, morre de doenca evitavel "
                "por falta de atendimento medico. Nao ha agressor "
                "direto, mas o sistema (desigualdade, racismo) e "
                "violento. Bourdieu diria que a naturalizacao "
                "dessa morte e violencia simbolica."
            ),
        },
        {
            "titulo": "2. Criminalizacao e seletividade",
            "conteudo": (
                "CRIME: conduta tipificada por lei. Nem todo desvio "
                "e crime.\n\n"
                "CRIMINALIZACAO:\n"
                "- Primaria: legislacao define o que e crime.\n"
                "- Secundaria: policia seleciona quem prender.\n\n"
                "SELETIVIDADE DO SISTEMA PENAL:\n"
                "- Pobres e negros sao alvos preferenciais.\n"
                "- Crimes de colarinho branco (corporativos) sao "
                "menos perseguidos.\n"
                "- Encarceramento em massa: EUA, Brasil.\n"
                "- Brasil: 3a maior populacao carceraria do mundo.\n\n"
                "LABELING THEORY (Becker):\n"
                "- O rotulo de 'criminoso' e atribuido pela sociedade.\n"
                "- Quem e rotulado passa a agir como tal.\n"
                "- Criminalidade e construcao social."
            ),
            "exemplo": (
                "Um jovem negro da periferia que fuma maconha e "
                "um executivo branco que usa cocaina cometem "
                "crimes. Mas a policia prende o jovem negro, nao "
                "o executivo. Essa seletividade mostra que o "
                "sistema penal nao e neutro: pune mais pobres e "
                "negros, como revela o encarceramento."
            ),
        },
        {
            "titulo": "3. Tipos de violencia e contexto brasileiro",
            "conteudo": (
                "TIPOS DE VIOLENCIA:\n"
                "- Fisica: agressao, homicidio, tortura.\n"
                "- Sexual: estupro, assedio, pedofilia.\n"
                "- Psicologica: ameaca, humilhacao, gaslighting.\n"
                "- Simbolica: naturalizada (Bourdieu).\n"
                "- Patrimonial: roubo, destruicao de bens.\n"
                "- Domestica: dentro de casa (Lei Maria da Penha).\n\n"
                "VIOLENCIA NO BRASIL:\n"
                "- ~60 mil homicidios/ano (uma das maiores taxas).\n"
                "- Juventude negra: 75% das vitimas.\n"
                "- Feminicidio: Lei 13.104/2015.\n"
                "- Lei Maria da Penha (2006): violencia domestica.\n"
                "- Narcotrafico: faccoes (CV, PCC, ADA).\n"
                "- Violencia policial: racismo estrutural.\n"
                "- Genocidio da juventude negra."
            ),
            "exemplo": (
                "O feminicidio e crime hediondo desde 2015. A Lei "
                "Maria da Penha (2006) criou mecanismos para "
                "proteger mulheres. Ainda assim, o Brasil tem "
                "altas taxas de violencia de genero. A juventude "
                "negra e a principal vitima de homicidios: o "
                "racismo estrutural se manifesta na violencia "
                "policial e no narcotrafico."
            ),
        },
    ],
    "resumo": (
        "- Violencia: direta, estrutural, cultural (Galtung).\n"
        "- Simbolica: naturalizada, sutíl (Bourdieu).\n"
        "- Criminalizacao: primaria (lei) x secundaria (policia).\n"
        "- Seletividade: pobres e negros mais perseguidos.\n"
        "- Labeling: rotulo de criminoso e construcao social.\n"
        "- Tipos: fisica, sexual, psicologica, simbolica, patrimonial, domestica.\n"
        "- Brasil: 60 mil homicidios/ano, juventude negra principal vitima."
    ),
    "dicas": [
        "Violencia estrutural: sistema que mata sem agressor direto.",
        "Bourdieu: violencia simbolica e naturalizada, sutíl.",
        "Seletividade: pobres e negros sao alvos do sistema penal.",
        "Labeling: ser rotulado de criminoso faz agir como tal.",
        "Lei Maria da Penha (2006), feminicidio (2015).",
        "Brasil: 3a maior populacao carceraria do mundo.",
    ],
    "pegadinhas": [
        "Achar que violencia e so fisica: tambem estrutural e simbolica.",
        "Confundir violencia estrutural com direta: estrutural nao tem autor direto.",
        "Esquecer a seletividade do sistema penal: nao e neutro.",
        "Achar que crime e desvio sao a mesma coisa: crime e desvio formal.",
        "Confundir violencia simbolica com psicologica: simbolica e naturalizada.",
        "Esquecer que o racismo estrutural se manifesta na violencia.",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "GALTUNG, J. Paz pelo desenvolvimento. Sao Paulo: Palas Athena, 2010.",
        "BOURDIEU, P. O poder simbolico. 13. ed. Rio de Janeiro: Bertrand, 2010.",
        "BECKER, H. Outsiders: estudos de sociologia do desvio. Rio de Janeiro: Zahar, 2008.",
        "WAISELFISZ, J. J. Mapa da violencia. Sao Paulo: FLACSO, 2015.",
    ],
}

IMG_VIOLENCIA = [
    {"file": "socio_violencia.png", "caption": "Sociologia da violencia: conceitos e tipos", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_violencia", [])

# ============================================================
# 11.6 Cultura e Ideologia
# ============================================================
CULTURA_IDEO = {
    "titulo": "Cultura e Ideologia",
    "disciplina": "Sociologia",
    "topico": "Cultura e Ideologia",
    "subtopico": "Popular, massa, identidade, racismo, etnocentrismo e contracultura",
    "introducao": (
        "Cultura e ideologia sao conceitos centrais para entender "
        "como sentidos e poder circulam na sociedade. Da cultura "
        "popular a industria cultural, do etnocentrismo ao "
        "relativismo, esses temas explicam nossa diversidade."
    ),
    "secoes": [
        {
            "titulo": "1. Cultura popular, erudita e de massa",
            "conteudo": (
                "CULTURA POPULAR: do povo, tradicional, anonima. "
                "Folclore, musica caipira, artesanato.\n\n"
                "CULTURA ERUDITA: elite, refinada, autoral. "
                "Musica classica, literatura, artes plasticas.\n\n"
                "CULTURA DE MASSA: produzida para consumo em larga "
                "escala. TV, cinema hollywoodiano, musica pop.\n\n"
                "INDUSTRIA CULTURAL (Adorno e Horkheimer):\n"
                "- Cultura como mercadoria.\n"
                "- Padronizacao: todos consomem o mesmo.\n"
                "- Falsa individualizacao: ilusao de escolha.\n"
                "- Entretenimento: alienacao, nao reflexao.\n"
                "- Cultura de massa: passividade."
            ),
            "exemplo": (
                "A novel a das 9h e cultura de massa: milhoes "
                "veem a mesma historia, com formulas repetidas "
                "(amor, traicao, vinganca). A industria cultural "
                "produz para vender, nao para questionar. Ja o "
                "forro de raiz e cultura popular (tradicional), "
                "e a opera e cultura erudita (refinada)."
            ),
        },
        {
            "titulo": "2. Identidade, multiculturalismo e racismo",
            "conteudo": (
                "IDENTIDADE: como nos definimos e somos definidos. "
                "Pessoal, social, coletiva.\n\n"
                "MULTICULTURALISMO: diversidade cultural convivendo. "
                "Reconhecimento das diferencas.\n\n"
                "IDENTIDADES:\n"
                "- Genero: feminino, masculino, nao-binario.\n"
                "- Raca: negra, branca, indigena.\n"
                "- Etnia: quilombola, indigena, ciganos.\n"
                "- Sexual: LGBTQIA+.\n\n"
                "RACISMO, PRECONCEITO, DISCRIMINACAO:\n"
                "- Preconceito: atitude (pensar).\n"
                "- Discriminacao: acao (fazer).\n"
                "- Racismo: discriminacao por raca.\n"
                "- Racismo estrutural: no sistema.\n"
                "- Racismo institucional: nas instituicoes.\n"
                "- Racismo recreativo: piadas, 'humor'."
            ),
            "exemplo": (
                "Preconceito e pensar 'negros sao menos "
                "inteligentes' (atitude). Discriminacao e nao "
                "contratar negro (acao). Racismo estrutural e o "
                "sistema que produz desigualdade racial (escola "
                "pior na periferia, encarceramento seletivo). "
                "Os tres se articulam: o individual reflete o "
                "estrutural."
            ),
        },
        {
            "titulo": "3. Contracultura, etnocentrismo e relativismo",
            "conteudo": (
                "CONTRACULTURA: movimentos que recusam a cultura "
                "hegemonica.\n"
                "- Hippie (anos 60): paz e amor.\n"
                "- Punk (anos 70): rebeldia, ruido.\n"
                "- Hip hop: periferia, critica social.\n"
                "- Feminista, LGBTQIA+: identidade e direitos.\n\n"
                "ETNOCENTRISMO: minha cultura e o padrao, as "
                "outras sao inferiores.\n"
                "- Colonizacao europeia: europeus como 'civilizados'.\n"
                "- Racismo cientifico (sec XIX).\n\n"
                "RELATIVISMO CULTURAL: cada cultura tem valor "
                "proprio, nao ha superior/inferior.\n"
                "- Levi-Strauss: respeito a diferenca.\n"
                "- Boas: cada cultura deve ser entendida em seus "
                "termos.\n\n"
                "IDEOLOGIA:\n"
                "- Marx: falsa consciencia, ideias da classe "
                "dominante.\n"
                "- Althusser: aparelhos ideologicos (escola, "
                "igreja, midia).\n"
                "- Gramsci: hegemonia, consenso, direcao "
                "intelectual e moral."
            ),
            "exemplo": (
                "O etnocentrismo europeu viu os indigenas como "
                "'selvagens' e os europeus como 'civilizados'. "
                "O relativismo cultural de Levi-Strauss mostra "
                "que cada cultura tem logica propria: o canibalismo "
                "ritual de alguns povos nao e 'selvagem', e "
                "significativo em seu contexto. Respeitar a "
                "diferenca nao e relativizar tudo, e entender "
                "em contexto."
            ),
        },
    ],
    "resumo": (
        "- Popular (do povo), erudita (elite), massa (para consumo).\n"
        "- Industria cultural: cultura como mercadoria (Adorno).\n"
        "- Identidade: como nos definimos. Multiculturalismo: diversidade.\n"
        "- Preconceito (atitude), discriminacao (acao), racismo (sistema).\n"
        "- Contracultura: recusa o hegemonico (hippie, punk, hip hop).\n"
        "- Etnocentrismo: minha cultura e superior. Relativismo: cada cultura tem valor.\n"
        "- Ideologia: Marx (falsa consciencia), Althusser (aparelhos), Gramsci (hegemonia)."
    ),
    "dicas": [
        "Cultura popular: do povo. Erudita: elite. Massa: para consumo.",
        "Adorno: industria cultural padroniza e aliena.",
        "Preconceito = atitude. Discriminacao = acao. Racismo = sistema.",
        "Etnocentrismo: minha cultura e padrao. Relativismo: cada uma tem valor.",
        "Gramsci: hegemonia e consenso, nao so forca.",
        "Contracultura resiste: hippie, punk, hip hop.",
    ],
    "pegadinhas": [
        "Confundir cultura popular com cultura de massa: popular e tradicional, massa e industrial.",
        "Achar que preconceito e discriminacao sao a mesma coisa: um e atitude, outro acao.",
        "Confundir etnocentrismo com relativismo: sao opostos.",
        "Achar que relativismo significa 'tudo e permitido': nao, e respeito ao contexto.",
        "Esquecer que ideologia (Marx) e falsa consciencia, nao so 'ideias'.",
        "Confundir hegemonia (Gramsci) com dominacao (Weber): hegemonia e consenso.",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "ADORNO, T.; HORKHEIMER, M. Dialetica do esclarecimento. Rio de Janeiro: Zahar, 1985.",
        "LEVI-STRAUSS, C. Antropologia estrutural. Rio de Janeiro: Tempo Brasileiro, 2008.",
        "GRAMSCI, A. Concepcao dialética da historia. Rio de Janeiro: Civilizacao Brasileira, 2008.",
        "HALL, S. A identidade cultural na pos-modernidade. 11. ed. Rio de Janeiro: DP&A, 2011.",
    ],
}

IMG_CULTURA_IDEO = [
    {"file": "socio_cultura.png", "caption": "Cultura e ideologia: popular, massa, identidade e racismo", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_cultura", [])

# ============================================================
def main():
    pdfs = [
        (MUDANCA, "SOC_MUDANCA_SOCIAL.pdf", IMG_MUDANCA, "Sociologia — Mudanca Social"),
        (VIOLENCIA, "SOC_VIOLENCIA.pdf", IMG_VIOLENCIA, "Sociologia — Sociologia da Violencia"),
        (CULTURA_IDEO, "SOC_CULTURA_IDEOLOGIA.pdf", IMG_CULTURA_IDEO, "Sociologia — Cultura e Ideologia"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
