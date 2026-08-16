# -*- coding: utf-8 -*-
"""Gera questoes ineditas de qualidade para Sociologia, Geografia e Filosofia.

Baseado nos topicos do syllabus PAES/UEMA, com 5 alternativas,
gabarito, resolucao, macete e pegadinha — estilo banca UEMA.
"""

from __future__ import annotations

import sys
import io
import json
import uuid
from datetime import datetime

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))

from db import db, init_db

init_db()

# ---------------------------------------------------------------------------
# Questoes de SOCIOLOGIA
# ---------------------------------------------------------------------------
SOCIOLOGIA_QUESTIONS = [
    {
        "id": "soc-2024-01",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Surgimento",
        "subtopic": "Contexto histórico da Sociologia",
        "statement": (
            "A Sociologia nasce como disciplina cientifica no seculo XIX, "
            "impulsionada por transformacoes sociais decorrentes da Revolucao "
            "Industrial e da Revolucao Francesa. Sobre o contexto historico "
            "do surgimento da Sociologia, e correto afirmar que:"
        ),
        "options": [
            "A Sociologia surgiu na Antiguidade classica, com os filosofos gregos.",
            "O surgimento da Sociologia esta ligado a crise do feudalismo e a consolidacao do capitalismo industrial.",
            "A Sociologia nasceu como resposta ao movimento iluminista, rejeitando a razao.",
            "O surgimento da Sociologia independe das mudancas economicas do seculo XIX.",
            "A Sociologia foi criada pela Igreja para combater o secularismo.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["surgimento", "revolucao industrial"],
        "resolution": (
            "A Sociologia surge no seculo XIX como resposta intelectual as "
            "profundas transformacoes trazidas pela Revolucao Industrial "
            "(urbanizacao, proletariado, desigualdades) e pela Revolucao "
            "Francesa (novos valores politicos). O capitalismo industrial "
            "criou novas contradies sociais que exigiam uma ciencia capaz "
            "de analisa-las."
        ),
        "banca_intent": "Verificar se o aluno compreende o contexto historico do surgimento da Sociologia.",
        "macete": "Sociologia = seculo XIX + Revolucao Industrial + Revolucao Francesa.",
        "pegadinha": "Marcar alternativa que confunde Sociologia com Filosofia grega antiga.",
        "related_topics": ["Perspectivas Classicas", "Conceitos Basicos"],
        "keywords": ["surgimento", "revolucao industrial", "capitalismo"],
    },
    {
        "id": "soc-2024-02",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Perspectivas Classicas",
        "subtopic": "Durkheim, Marx e Weber",
        "statement": (
            "Para Emile Durkheim, os fatos sociais sao exteriores ao individuo "
            "e exercem sobre ele uma coercao. Esse conceito fundamental da "
            "sociologia durkheimiana esta melhor expresso na nocao de:"
        ),
        "options": [
            "Luta de classes, como motor da historia.",
            "Acao social, orientada por sentidos subjetivos.",
            "Fato social, como modo de agir coercitivo e geral.",
            "Racionalizacao, como processo de desencantamento do mundo.",
            "Alienacao, como separacao entre trabalhador e produto.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["durkheim", "fato social"],
        "resolution": (
            "Durkheim define fato social como todo modo de agir, pensar e "
            "sentir exterior ao individuo e dotado de poder coercitivo. "
            "Exemplos: religiao, direito, costumes. A generalidade e a "
            "coercao sao caracteristicas essenciais."
        ),
        "banca_intent": "Cobrar o conceito central de Durkheim: fato social.",
        "macete": "Durkheim = fato social (exterior + coercitivo + geral).",
        "pegadinha": "Confundir fato social (Durkheim) com acao social (Weber) ou luta de classes (Marx).",
        "related_topics": ["Conceitos Basicos", "Surgimento"],
        "keywords": ["durkheim", "fato social", "coercao"],
    },
    {
        "id": "soc-2024-03",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Perspectivas Classicas",
        "subtopic": "Durkheim, Marx e Weber",
        "statement": (
            "Karl Marx analisa a sociedade capitalista a partir da nocao de "
            "luta de classes. Segundo Marx, nasocao fundamental que explica "
            "a exploracao do trabalhador no capitalismo e:"
        ),
        "options": [
            "A mais-valia, diferenca entre o valor produzido e o salario pago.",
            "O fato social, como norma coercitiva externa.",
            "A racionalizacao, como desencantamento do mundo.",
            "A solidariedade organica, propria de sociedades complexas.",
            "O status, como posicao social atribuida.",
        ],
        "correct_index": 0,
        "difficulty": "Media",
        "tags": ["marx", "mais-valia", "luta de classes"],
        "resolution": (
            "Marx afirma que o capitalista paga ao trabalhador apenas o "
            "necessario para sua reproducao (salario), mas se apropria do "
            "valor total produzido. Essa diferenca e a mais-valia, base da "
            "exploracao capitalista."
        ),
        "banca_intent": "Verificar compreensao do conceito de mais-valia em Marx.",
        "macete": "Marx = mais-valia (trabalho nao pago) + luta de classes.",
        "pegadinha": "Confundir mais-valia (Marx) com fato social (Durkheim).",
        "related_topics": ["Trabalho", "Conceitos Basicos"],
        "keywords": ["marx", "mais-valia", "capitalismo"],
    },
    {
        "id": "soc-2024-04",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Perspectivas Classicas",
        "subtopic": "Durkheim, Marx e Weber",
        "statement": (
            "Max Weber propoe a compreensao da sociedade a partir da acao "
            "social. Para Weber, a acao social orientada por valores "
            "absolutos, independentes de consequencias, classifica-se como:"
        ),
        "options": [
            "Acao instrumental-racional.",
            "Acao afetiva.",
            "Acao racional com relacao a valores.",
            "Acao tradicional.",
            "Acao coercitiva.",
        ],
        "correct_index": 2,
        "difficulty": "Dificil",
        "tags": ["weber", "acao social", "racionalidade"],
        "resolution": (
            "Weber classifica quatro tipos de acao social: (1) "
            "instrumental-racional (fins), (2) racional com relacao a "
            "valores (conviccoes), (3) afetiva (emocoes), (4) tradicional "
            "(costumes). A acao orientada por valores e guiada por etica "
            "de conviccao."
        ),
        "banca_intent": "Distinguir os quatro tipos de acao social weberiana.",
        "macete": "Weber: 4 tipos = instrumental, valores, afetiva, tradicional.",
        "pegadinha": "Confundir acao racional com relacao a valores com acao instrumental-racional.",
        "related_topics": ["Conceitos Basicos", "Cultura e Ideologia"],
        "keywords": ["weber", "acao social", "valores"],
    },
    {
        "id": "soc-2024-05",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Conceitos Basicos",
        "subtopic": "Socializacao e instituicoes",
        "statement": (
            "O processo pelo qual o individuo internaliza as normas, valores "
            "e papeis sociais de sua sociedade, tornando-se um membro "
            "integrado, e denominado:"
        ),
        "options": [
            "Coletivizacao.",
            "Socializacao.",
            "Estratificacao.",
            "Institucionalizacao.",
            "Alienacao.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["socializacao", "instituicoes"],
        "resolution": (
            "A socializacao e o processo continuo pelo qual o individuo "
            "aprende e internaliza normas, valores e papeis sociais. "
            "Ocorre em duas fases: socializacao primaria (familia) e "
            "secundaria (escola, trabalho)."
        ),
        "banca_intent": "Conceito basico de socializacao.",
        "macete": "Socializacao = aprender a viver em sociedade (familia + escola).",
        "pegadinha": "Confundir socializacao com institucionalizacao.",
        "related_topics": ["Cultura e Ideologia", "Estado e Poder"],
        "keywords": ["socializacao", "normas", "valores"],
    },
    {
        "id": "soc-2024-06",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Mudanca Social",
        "subtopic": "Estratificacao e desigualdade",
        "statement": (
            "A mobilidade social que ocorre quando um individuo melhora ou "
            "piora sua posicao social sem que a estrutura de classes se "
            "altere, e chamada de:"
        ),
        "options": [
            "Mobilidade social intergeracional.",
            "Mobilidade social intrageracional.",
            "Mobilidade social estrutural.",
            "Mobilidade social absoluta.",
            "Mobilidade social relativa.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["mobilidade social", "estratificacao"],
        "resolution": (
            "A mobilidade intrageracional ocorre dentro da mesma geracao "
            "(ex: pessoa que nasce pobre e enriquece). A intergeracional "
            "compara geracoes diferentes (ex: filho de operario torna-se "
            "medico). A estrutural ocorre quando a estrutura de classes "
            "se modifica."
        ),
        "banca_intent": "Distinguir tipos de mobilidade social.",
        "macete": "Intra = mesma geracao. Inter = entre geracoes. Estrutural = muda a estrutura.",
        "pegadinha": "Confundir intra com intergeracional.",
        "related_topics": ["Conceitos Basicos", "Estado e Poder"],
        "keywords": ["mobilidade social", "estratificacao", "classes"],
    },
    {
        "id": "soc-2024-07",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Cultura e Ideologia",
        "subtopic": "Cultura e multiculturalismo",
        "statement": (
            "O conceito de etnocentrismo refere-se a tendencia de:"
        ),
        "options": [
            "Valorizar todas as culturas igualmente.",
            "Avaliar outras culturas a partir dos padroes da propria cultura.",
            "Rejeitar a propria cultura em favor de outra.",
            "Promover o dialogo entre diferentes tradicoes culturais.",
            "Estudar culturas a partir de seus proprios valores.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["etnocentrismo", "cultura"],
        "resolution": (
            "Etnocentrismo e a tendencia de julgar outras culturas usando "
            "como criterio os valores e padroes da propria cultura, "
            "frequentemente considerada superior. O relativismo cultural e "
            "a postura oposta."
        ),
        "banca_intent": "Conceito fundamental de etnocentrismo.",
        "macete": "Etnocentrismo = minha cultura e o centro/padrao de tudo.",
        "pegadinha": "Confundir etnocentrismo com relativismo cultural.",
        "related_topics": ["Conceitos Basicos", "Cultura e sociedade"],
        "keywords": ["etnocentrismo", "cultura", "relativismo"],
    },
    {
        "id": "soc-2024-08",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Trabalho",
        "subtopic": "Fordismo, Taylorismo e Toyotismo",
        "statement": (
            "O sistema de producao que introduziu a linha de montagem, "
            "produtos padronizados e controle rigido do tempo do "
            "trabalhador, caracterizando o seculo XX, e denominado:"
        ),
        "options": [
            "Toyotismo.",
            "Taylorismo.",
            "Fordismo.",
            "Artesanato.",
            "Producao flexivel.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["fordismo", "trabalho", "producao"],
        "resolution": (
            "O fordismo, criado por Henry Ford no inicio do seculo XX, "
            "introduziu a linha de montagem, producao em massa e "
            "padronizacao. O taylorismo foca na organizacao cientifica "
            "do trabalho (estudo de tempos e movimentos). O toyotismo, "
            "japones, e flexivel e foca em producao just-in-time."
        ),
        "banca_intent": "Distinguir fordismo, taylorismo e toyotismo.",
        "macete": "Ford = linha de montagem + massa. Taylor = tempo/movimento. Toyota = flexivel.",
        "pegadinha": "Confundir fordismo (linha de montagem) com taylorismo (estudo de movimentos).",
        "related_topics": ["Mudanca Social", "Contemporaneo"],
        "keywords": ["fordismo", "linha de montagem", "producao"],
    },
    {
        "id": "soc-2024-09",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Estado e Poder",
        "subtopic": "Democracia e cidadania",
        "statement": (
            "Segundo Max Weber, o Estado moderno se caracteriza pelo "
            "monopolio:"
        ),
        "options": [
            "Da violencia fisica legitima.",
            "Da producao economica.",
            "Da verdade cientifica.",
            "Da educacao publica.",
            "Da religiao oficial.",
        ],
        "correct_index": 0,
        "difficulty": "Media",
        "tags": ["weber", "estado", "poder"],
        "resolution": (
            "Weber define o Estado como a instituicao que reivindica o "
            "monopolio do uso legitimo da forca fisica dentro de um "
            "determinado territorio. A legitimidade pode ser tradicional, "
            "carismatica ou racional-legal."
        ),
        "banca_intent": "Conceito weberiano de Estado.",
        "macete": "Estado (Weber) = monopolio da violencia legitima.",
        "pegadinha": "Confundir com conceitos economicos do Estado.",
        "related_topics": ["Perspectivas Classicas", "Conceitos Basicos"],
        "keywords": ["weber", "estado", "violencia legitima"],
    },
    {
        "id": "soc-2024-10",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Violencia",
        "subtopic": "Tipos de violencia",
        "statement": (
            "A violencia simbolica, conceito desenvolvido por Pierre "
            "Bourdieu, caracteriza-se por:"
        ),
        "options": [
            "Uso explicito da forca fisica contra o individuo.",
            "Coercao invisivel exercida por meio de simbolos e habitus incorporados.",
            "Violencia institucionalizada nas leis penais.",
            "Violencia domestica contra mulheres e criancas.",
            "Violencia estrutural decorrente da desigualdade economica.",
        ],
        "correct_index": 1,
        "difficulty": "Dificil",
        "tags": ["bourdieu", "violencia simbolica", "habitus"],
        "resolution": (
            "Bourdieu define violencia simbolica como uma forma de "
            "dominacao invisivel, exercida atraves de simbolos, habitus "
            "e disposicoes incorporados. Nao ha uso explicito da forca; "
            "o dominado aceita a dominacao como natural."
        ),
        "banca_intent": "Conceito avancado de violencia simbolica em Bourdieu.",
        "macete": "Violencia simbolica (Bourdieu) = dominacao invisivel + habitus.",
        "pegadinha": "Confundir violencia simbolica com violencia fisica ou estrutural.",
        "related_topics": ["Cultura e Ideologia", "Conceitos Basicos"],
        "keywords": ["bourdieu", "violencia simbolica", "habitus"],
    },
    {
        "id": "soc-2024-11",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Contemporaneo",
        "subtopic": "Globalizacao e neoliberalismo",
        "statement": (
            "O neoliberalismo, enquanto projeto politico-economico "
            "consolidado a partir dos anos 1980, caracteriza-se por:"
        ),
        "options": [
            "Fortalecimento do Estado de bem-estar social e ampliação de direitos.",
            "Intervencao estatal na economia e nacionalizacao de empresas.",
            "Reducao do papel do Estado, privatizacoes e livre mercado.",
            "Controle estatal dos precos e subsidiamento de produtos basicos.",
            "Planificacao central da economia nos moldes sovieticos.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["neoliberalismo", "globalizacao", "estado minimo"],
        "resolution": (
            "O neoliberalismo defende a reducao do papel do Estado na "
            "economia, privatizacoes, desregulamentacao, livre mercado e "
            "flexibilizacao trabalhista. Pensadores: Hayek, Friedman. "
            "Implementado por Thatcher (UK) e Reagan (EUA)."
        ),
        "banca_intent": "Compreender o projeto neoliberal contemporaneo.",
        "macete": "Neoliberalismo = Estado minimo + privatizacao + livre mercado.",
        "pegadinha": "Confundir neoliberalismo com Estado de bem-estar social.",
        "related_topics": ["Estado e Poder", "Trabalho"],
        "keywords": ["neoliberalismo", "privatizacao", "globalizacao"],
    },
    {
        "id": "soc-2024-12",
        "year": 2024,
        "subject": "Sociologia",
        "topic": "Cultura e sociedade",
        "subtopic": "Identidade",
        "statement": (
            "O conceito de identidade na sociologia contemporanea e "
            "compreendido como:"
        ),
        "options": [
            "Uma essencia fixa e imutavel do individuo.",
            "Uma construcao social, fluida e contextual, negociada nas interacoes.",
            "Determinada exclusivamente pela genetica.",
            "Definida apenas pelo Estado atraves de documentos.",
            "Inexistente nas sociedades modernas.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["identidade", "cultura", "construcao social"],
        "resolution": (
            "Na sociologia contemporanea (Hall, Bauman), a identidade e "
            "vista como uma construcao social, fluida e negociada nas "
            "interacoes. Nao e essencia fixa, mas resultado de processos "
            "de identificacao em contextos culturais especificos."
        ),
        "banca_intent": "Conceito contemporaneo de identidade.",
        "macete": "Identidade = construcao social + fluida (Bauman/Hall).",
        "pegadinha": "Tratar identidade como essencia fixa e imutavel.",
        "related_topics": ["Cultura e Ideologia", "Mudanca Social"],
        "keywords": ["identidade", "construcao social", "cultura"],
    },
]

# ---------------------------------------------------------------------------
# Questoes de GEOGRAFIA
# ---------------------------------------------------------------------------
GEOGRAFIA_QUESTIONS = [
    {
        "id": "geo-2024-01",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Fisica",
        "subtopic": "Terra, coordenadas e fusos",
        "statement": (
            "O sistema de coordenadas geograficas permite localizar qualquer "
            "ponto na superficie terrestre. As linhas imaginarias paralelas "
            "ao Equador, que medem a latitude, sao chamadas de:"
        ),
        "options": [
            "Meridianos.",
            "Paralelos.",
            "Isoietas.",
            "Isotermas.",
            "Trópicos apenas.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["coordenadas", "paralelos", "latitude"],
        "resolution": (
            "Os paralelos sao linhas imaginarias horizontais, paralelas ao "
            "Equador, que medem a latitude (distancia angular em relacao "
            "ao Equador). Os meridianos sao verticais e medem a longitude."
        ),
        "banca_intent": "Distinguir paralelos e meridianos no sistema de coordenadas.",
        "macete": "Paralelo = horizontal (latitude). Meridiano = vertical (longitude).",
        "pegadinha": "Inverter paralelos e meridianos.",
        "related_topics": ["Geografia Fisica", "Geografia do Maranhao"],
        "keywords": ["paralelos", "latitude", "coordenadas"],
    },
    {
        "id": "geo-2024-02",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Fisica",
        "subtopic": "Clima e vegetacao",
        "statement": (
            "O bioma que predomina na regiao Norte do Brasil, caracterizado "
            "por alta pluviosidade, temperatura media elevada e grande "
            "biodiversidade, e a:"
        ),
        "options": [
            "Caatinga.",
            "Cerrado.",
            "Floresta Amazonica.",
            "Mata Atlantica.",
            "Pampa.",
        ],
        "correct_index": 2,
        "difficulty": "Facil",
        "tags": ["bioma", "amazonia", "clima"],
        "resolution": (
            "A Floresta Amazonica (Floresta Tropical Umida) predomina na "
            "regiao Norte. Caracteriza-se por clima equatorial (alta "
            "temperatura e pluviosidade), estratificacao vegetal e "
            "enorme biodiversidade."
        ),
        "banca_intent": "Identificar biomas brasileiros.",
        "macete": "Norte = Amazonia (equatorial). Nordeste = Caatinga. Centro = Cerrado.",
        "pegadinha": "Confundir Floresta Amazonica com Mata Atlantica.",
        "related_topics": ["Geografia do Brasil", "Temas Contemporaneos"],
        "keywords": ["bioma", "amazonia", "equatorial"],
    },
    {
        "id": "geo-2024-03",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Fisica",
        "subtopic": "Relevo e hidrografia",
        "statement": (
            "A bacia hidrografica do rio Amazonas destaca-se por:"
        ),
        "options": [
            "Ser a maior bacia hidrografica do mundo em extensao.",
            "Possuir o maior potencial hidreletrico do Brasil.",
            "Localizar-se integralmente no Nordeste brasileiro.",
            "Apresentar clima semi-arido e rios intermitentes.",
            "Ser a mais populosa do pais.",
        ],
        "correct_index": 0,
        "difficulty": "Media",
        "tags": ["hidrografia", "amazonas", "bacia"],
        "resolution": (
            "A bacia Amazonica e a maior bacia hidrografica do mundo, com "
            "aproximadamente 7 milhoes de km2. O rio Amazonas e o mais "
            "extenso e volumoso do planeta. Drena areas de Brasil, Peru, "
            "Colombia e outros paises."
        ),
        "banca_intent": "Conhecer a bacia amazonica e sua importancia.",
        "macete": "Amazonas = maior bacia do mundo + rio mais volumoso.",
        "pegadinha": "Confundir com Sao Francisco (Nordeste) ou Parana (Sul).",
        "related_topics": ["Geografia do Brasil", "Geografia Fisica"],
        "keywords": ["amazonas", "bacia hidrografica", "hidrografia"],
    },
    {
        "id": "geo-2024-04",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Humana",
        "subtopic": "Demografia e migracoes",
        "statement": (
            "O conceito demografico de transicao demografica refere-se a:"
        ),
        "options": [
            "Movimento de pessoas entre paises diferentes.",
            "Passagem de altos niveis de natalidade e mortalidade para niveis baixos.",
            "Crescimento absoluto da populacao urbana.",
            "Reducao da expectativa de vida por doencas.",
            "Aumento da densidade demografica em areas rurais.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["demografia", "transicao demografica"],
        "resolution": (
            "A transicao demografica e o processo pelo qual uma sociedade "
            "passa de altos padroes de natalidade e mortalidade (tipico "
            "pre-industrial) para padroes baixos (sociedade desenvolvida). "
            "Gera envelhecimento populacional."
        ),
        "banca_intent": "Conceito central de demografia.",
        "macete": "Transicao demografica = altas taxas -> baixas taxas (natalidade + mortalidade).",
        "pegadinha": "Confundir com migracao ou urbanizacao.",
        "related_topics": ["Geografia Humana", "Temas Contemporaneos"],
        "keywords": ["demografia", "transicao demografica", "natalidade"],
    },
    {
        "id": "geo-2024-05",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Humana",
        "subtopic": "Urbanizacao",
        "statement": (
            "O processo de metropolizacao caracteriza-se por:"
        ),
        "options": [
            "Apenas o crescimento de cidades pequenas.",
            "Formacao de grandes aglomerados urbanos com cidades conurbadas.",
            "Reducao da populacao nas capitais estaduais.",
            "Retorno da populacao urbana para o campo.",
            "Criacao exclusiva de novos municipios rurais.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["urbanizacao", "metropolizacao", "conurbacao"],
        "resolution": (
            "A metropolizacao e o processo de formacao de grandes "
            "aglomerados urbanos, onde cidades vizinhas se conurbam, "
            "formando metropoles com intenso fluxo de pessoas, mercadorias "
            "e servicos. Exemplos: Sao Paulo, Rio de Janeiro."
        ),
        "banca_intent": "Conceito de metropolizacao.",
        "macete": "Metropolizacao = cidades conurbadas + grandes fluxos.",
        "pegadinha": "Confundir com urbanizacao simples.",
        "related_topics": ["Geografia Humana", "Geografia Economica"],
        "keywords": ["metropolizacao", "conurbacao", "urbanizacao"],
    },
    {
        "id": "geo-2024-06",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Economica",
        "subtopic": "Agricultura e industria",
        "statement": (
            "A Revolucao Verde, a partir dos anos 1960, caracterizou-se por:"
        ),
        "options": [
            "Promocao da agricultura organica e agroecologia.",
            "Modernizacao agricola com uso de sementes melhoradas, agrotoxicos e maquinario.",
            "Reforma agraria e distribuicao de terras a pequenos produtores.",
            "Retorno ao sistema de agricultura familiar tradicional.",
            "Nacionalizacao das terras produtivas pelo Estado.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["agricultura", "revolucao verde", "modernizacao"],
        "resolution": (
            "A Revolucao Verde introduziu pacotes tecnologicos (sementes "
            "melhoradas, fertilizantes, agrotoxicos, maquinario) para "
            "aumentar a produtividade agricola. Concentrou terras, "
            "excluiu pequenos produtores e gerou impactos ambientais."
        ),
        "banca_intent": "Compreender a Revolucao Verde e seus impactos.",
        "macete": "Revolucao Verde = tecnologia + agrotoxicos + concentracao de terras.",
        "pegadinha": "Confundir com agroecologia ou reforma agraria.",
        "related_topics": ["Geografia Economica", "Temas Contemporaneos"],
        "keywords": ["revolucao verde", "agricultura", "agrotoxicos"],
    },
    {
        "id": "geo-2024-07",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia do Maranhao",
        "subtopic": "Economia e sociedade maranhense",
        "statement": (
            "O estado do Maranhao apresenta diversidade de biomas em seu "
            "territorio. Entre os biomas presentes no Maranhao, destaca-se:"
        ),
        "options": [
            "Apenas a Floresta Amazonica.",
            "Apenas a Caatinga.",
            "Amazonia, Cerrado e Caatinga, com transicoes entre eles.",
            "Apenas o Pantanal.",
            "Apenas a Mata Atlantica.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["maranhao", "bioma", "cerrado", "amazonia"],
        "resolution": (
            "O Maranhao e um estado de transicao, abrigando porcoes da "
            "Amazonia (oeste), Cerrado (centro-sul) e Caatinga (leste), "
            "alem de vegetacao litoranea (manguezais e restingas). Essa "
            "diversidade reflete sua posicao geografica de interface."
        ),
        "banca_intent": "Conhecer a diversidade de biomas do Maranhao.",
        "macete": "Maranhao = Amazonia (oeste) + Cerrado (centro) + Caatinga (leste).",
        "pegadinha": "Achar que o Maranhao so tem um bioma.",
        "related_topics": ["Geografia Fisica", "Geografia do Brasil"],
        "keywords": ["maranhao", "bioma", "cerrado", "amazonia"],
    },
    {
        "id": "geo-2024-08",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia Politica",
        "subtopic": "Geopolitica e megablocos",
        "statement": (
            "O bloco economico formado por paises da America do Sul, "
            "criado em 1991 com o objetivo de integrar economias e "
            "facilitar o comercio, e o:"
        ),
        "options": [
            "NAFTA.",
            "Mercosul.",
            "Uniao Europeia.",
            "OTAN.",
            "BRICS.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["mercosul", "bloco economico", "america do sul"],
        "resolution": (
            "O Mercosul (Mercado Comum do Sul) foi criado em 1991 pelo "
            "Tratado de Assuncao, integrando Brasil, Argentina, Uruguai "
            "e Paraguai. Posteriormente, Venezuela (suspensa) e Bolivia "
            "(em adesao) juntaram-se."
        ),
        "banca_intent": "Identificar blocos economicos.",
        "macete": "Mercosul = America do Sul (1991, Tratado de Assuncao).",
        "pegadinha": "Confundir Mercosul com NAFTA (America do Norte).",
        "related_topics": ["Geografia Economica", "Contemporaneo"],
        "keywords": ["mercosul", "bloco economico", "integracao"],
    },
    {
        "id": "geo-2024-09",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Temas Contemporaneos",
        "subtopic": "Questao ambiental e sustentabilidade",
        "statement": (
            "O conceito de desenvolvimento sustentavel, amplamente "
            "difundido a partir do Relatorio Brundtland (1987), define-se como:"
        ),
        "options": [
            "Crescimento economico a qualquer custo.",
            "Desenvolvimento que atende as necessidades do presente sem comprometer as geracoes futuras.",
            "Preservacao integral da natureza sem uso de recursos.",
            "Industrializacao acelerada dos paises em desenvolvimento.",
            "Retorno ao modo de vida pre-industrial.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["sustentabilidade", "brundtland", "desenvolvimento"],
        "resolution": (
            "O Relatorio Brundtland (1987) definiu desenvolvimento "
            "sustentavel como aquele que atende as necessidades do "
            "presente sem comprometer a capacidade das geracoes futuras "
            "de atender suas proprias necessidades. Integra dimensao "
            "economica, social e ambiental."
        ),
        "banca_intent": "Conceito fundamental de desenvolvimento sustentavel.",
        "macete": "Sustentavel = presente sem comprometer futuro (Brundtland, 1987).",
        "pegadinha": "Confundir com preservacao integral (sem uso) ou crescimento a qualquer custo.",
        "related_topics": ["Geografia Economica", "Contemporaneo"],
        "keywords": ["sustentabilidade", "brundtland", "desenvolvimento"],
    },
    {
        "id": "geo-2024-10",
        "year": 2024,
        "subject": "Geografia",
        "topic": "Geografia do Brasil",
        "subtopic": "Nordeste",
        "statement": (
            "A regiao Nordeste do Brasil apresenta grande diversidade "
            "natural. A sub-regiao que se caracteriza por clima semi-arido, "
            "vegetacao de caatinga e rios intermitentes e a:"
        ),
        "options": [
            "Zona da Mata.",
            "Agreste.",
            "Sertao.",
            "Meio-Norte.",
            "Litoral.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["nordeste", "sertao", "caatinga", "semi-arido"],
        "resolution": (
            "O Sertao nordestino e a sub-regiao de clima semi-arido (BSh), "
            "vegetacao de caatinga (xerofila), rios intermitentes e longos "
            "periodos de seca. Ocupa a maior parte da area do Nordeste."
        ),
        "banca_intent": "Conhecer as sub-regioes do Nordeste brasileiro.",
        "macete": "Sertao = semi-arido + caatinga + seca. Zona da Mata = umida + mata atlantica.",
        "pegadinha": "Confundir Sertao com Agreste (transicao) ou Zona da Mata (umida).",
        "related_topics": ["Geografia do Maranhao", "Geografia Fisica"],
        "keywords": ["sertao", "caatinga", "semi-arido", "nordeste"],
    },
]

# ---------------------------------------------------------------------------
# Questoes de FILOSOFIA
# ---------------------------------------------------------------------------
FILOSOFIA_QUESTIONS = [
    {
        "id": "filo-2024-01",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "A Filosofia",
        "subtopic": "Origem e periodos da filosofia",
        "statement": (
            "A filosofia ocidental tem sua origem historica na Grecia "
            "antiga, por volta do seculo VI a.C. O marco que distingue a "
            "filosofia do mito e:"
        ),
        "options": [
            "A explicacao racional e argumentativa em lugar da narrativa mitologica.",
            "A aceitacao de tradicoes religiosas sem questionamento.",
            "A submissao ao saber dos sacerdotes e oraculos.",
            "A negacao da razao humana como instrumento de conhecimento.",
            "A dependencia da revelacao divina para compreender o mundo.",
        ],
        "correct_index": 0,
        "difficulty": "Facil",
        "tags": ["origem", "mito", "razao"],
        "resolution": (
            "A filosofia nasce na Grecia (Mileto) quando pensadores como "
            "Tales, Anaximandro e Anaximenes propoem explicacoes racionais "
            "e naturais para o cosmos, substituindo narrativas mitologicas. "
            "O logos substitui o mitos."
        ),
        "banca_intent": "Compreender a origem da filosofia e a passagem do mito ao logos.",
        "macete": "Filosofia = passagem do mito (narrativa) ao logos (razao argumentativa).",
        "pegadinha": "Confundir filosofia com religiao ou mito.",
        "related_topics": ["Conhecimento", "Logica"],
        "keywords": ["origem", "mito", "logos", "grécia"],
    },
    {
        "id": "filo-2024-02",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "A Filosofia",
        "subtopic": "Origem e periodos da filosofia",
        "statement": (
            "Socrates, Plato e Aristoteles formam o auge da filosofia "
            "classica grega. O metodo socratico de investigacao filosofica "
            "baseia-se em:"
        ),
        "options": [
            "Ditar verdades prontas aos discipulos.",
            "Dialogo com perguntas e respostas para revelar contradicoes (maieutica).",
            "Estudo exclusivo dos textos sagrados.",
            "Experimentacao empirica controlada.",
            "Contemplacao solitaria sem dialogo.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["socrates", "maieutica", "dialogo"],
        "resolution": (
            "Socrates utilizava a ironia (perguntas que revelam ignorancia) "
            "e a maieutica (parto das ideias) no dialogo. Nao escreveu; "
            "seu metodo esta nos dialogos de Plato. Buscava a definicao "
            "de conceitos (justica, virtude) pelo exame critico."
        ),
        "banca_intent": "Conhecer o metodo socratico.",
        "macete": "Socrates = ironia + maieutica (perguntas que 'dão a luz' a ideias).",
        "pegadinha": "Confundir metodo socratico com dogmatismo.",
        "related_topics": ["Conhecimento", "Etica"],
        "keywords": ["socrates", "maieutica", "ironia"],
    },
    {
        "id": "filo-2024-03",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Conhecimento",
        "subtopic": "Tipos de conhecimento e ciencia",
        "statement": (
            "Na teoria do conhecimento, a posicao que afirma que o "
            "conhecimento verdadeiro se origina da experiencia sensorial "
            "e denominada:"
        ),
        "options": [
            "Racionalismo.",
            "Empirismo.",
            "Ceticismo.",
            "Dogmatismo.",
            "Agnosticismo.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["empirismo", "conhecimento", "experiencia"],
        "resolution": (
            "O empirismo (Locke, Hume, Bacon) sustenta que todo "
            "conhecimento deriva da experiencia sensorial. O racionalismo "
            "(Descartes, Spinoza) defende a razao como fonte primaria. "
            "Kant busca conciliar ambos."
        ),
        "banca_intent": "Distinguir empirismo e racionalismo.",
        "macete": "Empirismo = experiencia (sentidos). Racionalismo = razao (ideias inatas).",
        "pegadinha": "Inverter empirismo e racionalismo.",
        "related_topics": ["A Filosofia", "Logica"],
        "keywords": ["empirismo", "experiencia", "locke"],
    },
    {
        "id": "filo-2024-04",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Conhecimento",
        "subtopic": "Tipos de conhecimento e ciencia",
        "statement": (
            "Descartes e considerado o pai do racionalismo moderno. Sua "
            "famosa frase 'Cogito, ergo sum' expressa:"
        ),
        "options": [
            "A duvida sobre a existencia de Deus.",
            "A certeza indubitavel da propria existencia como sujeito pensante.",
            "A primazia dos sentidos sobre a razao.",
            "A impossibilidade do conhecimento verdadeiro.",
            "A subordinacao da filosofia a teologia.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["descartes", "cogito", "racionalismo"],
        "resolution": (
            "Descartes aplica a duvida hiperbolica a tudo: sentidos, "
            "matematica, existencia. Resto indubitavel: enquanto duvida, "
            "pensa; logo, existe. 'Penso, logo existo' e a primeira "
            "certeza do racionalismo."
        ),
        "banca_intent": "Compreender o cogito cartesiano.",
        "macete": "Cogito ergo sum = penso, logo existo (primeira certeza de Descartes).",
        "pegadinha": "Interpretar o cogito como duvida em vez de certeza.",
        "related_topics": ["A Filosofia", "Logica"],
        "keywords": ["descartes", "cogito", "racionalismo"],
    },
    {
        "id": "filo-2024-05",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Etica",
        "subtopic": "Teorias morais",
        "statement": (
            "A etica kantiana fundamenta-se no imperativo categorico. "
            "Segundo Kant, uma acao tem valor moral quando:"
        ),
        "options": [
            "Produz o maior bem para o maior numero de pessoas.",
            "E realizada por dever, conforme uma maxima universalizavel.",
            "Segue os mandamentos divinos.",
            "Resulta em prazer e felicidade pessoal.",
            "E determinada pelas consequencias positivas.",
        ],
        "correct_index": 1,
        "difficulty": "Dificil",
        "tags": ["kant", "imperativo categorico", "dever"],
        "resolution": (
            "Para Kant, a acao moralmente valida e a realizada por dever "
            "(nao por inclinacao), seguindo uma maxima que possa ser "
            "universalizada. O imperativo categorico nao depende de "
            "consequencias, mas da intencao racional."
        ),
        "banca_intent": "Conceito central da etica kantiana.",
        "macete": "Kant = imperativo categorico + dever + universalizavel.",
        "pegadinha": "Confundir Kant (deontologia) com utilitarismo (consequencias).",
        "related_topics": ["Politica", "Cultura"],
        "keywords": ["kant", "imperativo categorico", "dever"],
    },
    {
        "id": "filo-2024-06",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Etica",
        "subtopic": "Valores, moral e direitos humanos",
        "statement": (
            "O utilitarismo, etica desenvolvida por Bentham e Mill, "
            "estabelece que uma acao e moralmente correta quando:"
        ),
        "options": [
            "Segue um imperativo categorico universal.",
            "Produz o maior bem (felicidade) para o maior numero de pessoas.",
            "Obedece a tradicoes ancestrais.",
            "E determinada pela vontade divina.",
            "Promove o auto-interesse individual exclusivamente.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["utilitarismo", "bentham", "mill"],
        "resolution": (
            "O utilitarismo (Bentham, Mill) e uma etica consequencialista: "
            "uma acao e boa se produz o maior bem para o maior numero. "
            "Difere da etica kantiana (deontologica), que avalia a "
            "intenção e a maxima, nao as consequencias."
        ),
        "banca_intent": "Conceito de utilitarismo e contraste com Kant.",
        "macete": "Utilitarismo = maior bem para o maior numero (consequencias).",
        "pegadinha": "Confundir utilitarismo com etica do dever (Kant).",
        "related_topics": ["Politica", "Conhecimento"],
        "keywords": ["utilitarismo", "bentham", "mill", "consequencialismo"],
    },
    {
        "id": "filo-2024-07",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Logica",
        "subtopic": "Argumentacao e logica",
        "statement": (
            "Um silogismo e uma forma de raciocinio dedutivo composto por "
            "premissas e conclusao. O silogismo classico 'Todo homem e "
            "mortal. Socrates e homem. Logo, Socrates e mortal' e um "
            "exemplo de:"
        ),
        "options": [
            "Raciocinio indutivo.",
            "Raciocinio dedutivo valido.",
            "Falacia logica.",
            "Argumento por autoridade.",
            "Raciocinio abdutivo.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["silogismo", "deducao", "aristoteles"],
        "resolution": (
            "O silogismo aristotelico e a forma classica de deducao: a "
            "partir de duas premissas (maior e menor), infere-se uma "
            "conclusao necessaria. Se as premissas sao verdadeiras e a "
            "forma e valida, a conclusao e necessariamente verdadeira."
        ),
        "banca_intent": "Identificar silogismo dedutivo.",
        "macete": "Silogismo = premissa maior + premissa menor -> conclusao (deducao).",
        "pegadinha": "Confundir deducao com inducao (generalizacao a partir de casos).",
        "related_topics": ["Conhecimento", "A Filosofia"],
        "keywords": ["silogismo", "deducao", "aristoteles"],
    },
    {
        "id": "filo-2024-08",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Politica",
        "subtopic": "Estado e democracia",
        "statement": (
            "Em 'O Contrato Social', Jean-Jacques Rousseau defende que a "
            "legitimidade do Estado decorre de:"
        ),
        "options": [
            "Direito divino dos reis.",
            "Forca militar do soberano.",
            "Vontade geral expressa pelo contrato social.",
            "Tradicao e costumes ancestrais.",
            "Meritocracia economica dos governantes.",
        ],
        "correct_index": 2,
        "difficulty": "Media",
        "tags": ["rousseau", "contrato social", "vontade geral"],
        "resolution": (
            "Rousseau, em 'O Contrato Social' (1762), sustenta que o "
            "poder legitimo deriva da vontade geral (volonte generale), "
            "expressa pelo pacto social. O soberano e o povo reunido; "
            "cada individuo obedece a si mesmo enquanto parte do corpo "
            "politico."
        ),
        "banca_intent": "Conceito de contrato social em Rousseau.",
        "macete": "Rousseau = vontade geral + contrato social (povo e soberano).",
        "pegadinha": "Confundir Rousseau com Hobbes (soberano absoluto) ou Locke (propriedade).",
        "related_topics": ["Etica", "A Filosofia"],
        "keywords": ["rousseau", "contrato social", "vontade geral"],
    },
    {
        "id": "filo-2024-09",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Estetica",
        "subtopic": "O belo e a arte",
        "statement": (
            "Na filosofia da arte, Immanuel Kant distingue o belo do "
            "sublime. O sublime, segundo Kant, caracteriza-se por:"
        ),
        "options": [
            "Sentimento de prazer desinteressado diante da forma.",
            "Sentimento misto de atracao e temor diante do infinito ou da forca.",
            "Satisfacao utilitaria de uma necessidade pratica.",
            "Apreciacao exclusiva de obras classicas.",
            "Conformidade com regras academicas de composicao.",
        ],
        "correct_index": 1,
        "difficulty": "Dificil",
        "tags": ["kant", "sublime", "estetica"],
        "resolution": (
            "Kant, em 'Critica do Juizo', distingue belo (prazer "
            "desinteressado na forma) e sublime (sentimento que surge "
            "diante do imensuravel ou do poderoso, misturando atracao e "
            "temor). O sublime pode ser matematico (infinitude) ou "
            "dinamico (forca da natureza)."
        ),
        "banca_intent": "Distinguir belo e sublime em Kant.",
        "macete": "Belo = forma + prazer desinteressado. Sublime = infinito/forca + temor + atracao.",
        "pegadinha": "Confundir belo e sublime.",
        "related_topics": ["Cultura", "Conhecimento"],
        "keywords": ["kant", "sublime", "belo", "estetica"],
    },
    {
        "id": "filo-2024-10",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Cultura",
        "subtopic": "Natureza, cultura e sagrado",
        "statement": (
            "Na filosofia contemporanea, a disticao entre natureza e "
            "cultura e central. Pode-se afirmar que a cultura:"
        ),
        "options": [
            "E inata, determinada geneticamente.",
            "E construida socialmente, variando entre sociedades e epocas.",
            "E universal e identica em todos os povos.",
            "Depende exclusivamente do clima.",
            "E independente da linguagem e da educacao.",
        ],
        "correct_index": 1,
        "difficulty": "Facil",
        "tags": ["cultura", "natureza", "construcao social"],
        "resolution": (
            "A cultura e o conjunto de valores, costumes, linguagem e "
            "praticas construidos socialmente, variando entre sociedades "
            "e epocas. Distingue-se da natureza (biologicamente dado). "
            "Levi-Strauss e Geertz sao referencias centrais."
        ),
        "banca_intent": "Distinguir natureza e cultura.",
        "macete": "Natureza = dado biologico. Cultura = construido socialmente.",
        "pegadinha": "Tratar cultura como inata/genetica.",
        "related_topics": ["Etica", "A Filosofia"],
        "keywords": ["cultura", "natureza", "construcao social"],
    },
    {
        "id": "filo-2024-11",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Politica",
        "subtopic": "Estado e democracia",
        "statement": (
            "Thomas Hobbes, em 'Leviata', fundamenta o Estado absoluto "
            "a partir de uma concepcao pessimista da natureza humana. "
            "Para Hobbes, no estado de natureza:"
        ),
        "options": [
            "Reina a harmonia e a paz entre os homens.",
            "Ha guerra de todos contra todos (bellum omnium contra omnes).",
            "Os homens vivem em comunidade organizada por contratos.",
            "Existe propriedade privada garantida por lei natural.",
            "Predomina a vontade geral do povo.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["hobbes", "leviata", "estado de natureza"],
        "resolution": (
            "Hobbes descreve o estado de natureza como guerra de todos "
            "contra todos, onde a vida e 'solitaria, pobre, desagradavel, "
            "brutal e curta'. Para escapar, os homens pactuam o contrato "
            "social, abrindo mao da liberdade em favor do soberano "
            "(Leviata) absoluto."
        ),
        "banca_intent": "Conceito de estado de natureza em Hobbes.",
        "macete": "Hobbes = estado de natureza = guerra de todos contra todos -> soberano absoluto.",
        "pegadinha": "Confundir Hobbes (soberano absoluto) com Rousseau (vontade geral).",
        "related_topics": ["Etica", "A Filosofia"],
        "keywords": ["hobbes", "leviata", "estado de natureza"],
    },
    {
        "id": "filo-2024-12",
        "year": 2024,
        "subject": "Filosofia",
        "topic": "Logica",
        "subtopic": "Argumentacao e logica",
        "statement": (
            "Uma falacia logica e um argumento que parece valido mas nao "
            "e. O argumento 'Joao e um bom aluno, pois todos dizem isso' "
            "configura a falacia conhecida como:"
        ),
        "options": [
            "Peticao de principio.",
            "Argumento de autoridade (ad verecundiam).",
            "Espantalho.",
            "Falso dilema.",
            "Generalizacao apressada.",
        ],
        "correct_index": 1,
        "difficulty": "Media",
        "tags": ["falacia", "argumento de autoridade", "logica"],
        "resolution": (
            "O argumento de autoridade (ad verecundiam) ocorre quando se "
            "invoca a opiniao de outros ('todos dizem') como prova, sem "
            "apresentar evidencias proprias. Nem sempre e falacia: e "
            "legitimo citar especialistas qualificados em area tecnica."
        ),
        "banca_intent": "Identificar falacias logicas comuns.",
        "macete": "Ad verecundiam = apelo a autoridade/opiniao alheia sem prova.",
        "pegadinha": "Confundir com peticao de principio (assumir o que se quer provar).",
        "related_topics": ["Conhecimento", "A Filosofia"],
        "keywords": ["falacia", "argumento de autoridade", "ad verecundiam"],
    },
]


def insert_questions(questions: list[dict]) -> int:
    """Insere questoes no banco."""
    inserted = 0
    with db() as conn:
        for q in questions:
            try:
                conn.execute(
                    """
                    INSERT OR REPLACE INTO questions (
                        id, year, subject, topic, subtopic, statement, options_json,
                        correct_index, difficulty, tags_json, source, resolution,
                        banca_intent, macete, pegadinha, related_topics_json,
                        keywords_json, avg_text_len, generated, approved, exam_board
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, 'TREINO')
                    """,
                    (
                        q["id"],
                        q["year"],
                        q["subject"],
                        q["topic"],
                        q.get("subtopic"),
                        q["statement"],
                        json.dumps(q["options"], ensure_ascii=False),
                        q["correct_index"],
                        q["difficulty"],
                        json.dumps(q.get("tags", []), ensure_ascii=False),
                        "treino_paes_2024",
                        q.get("resolution"),
                        q.get("banca_intent"),
                        q.get("macete"),
                        q.get("pegadinha"),
                        json.dumps(q.get("related_topics", []), ensure_ascii=False),
                        json.dumps(q.get("keywords", []), ensure_ascii=False),
                        len(q["statement"]),
                    ),
                )
                inserted += 1
            except Exception as e:
                print(f"  ERRO: {q['id']}: {e}")
        conn.commit()
    return inserted


def main():
    print("=" * 60)
    print("Gerando questoes para Sociologia, Geografia e Filosofia")
    print("=" * 60)

    all_questions = (
        SOCIOLOGIA_QUESTIONS + GEOGRAFIA_QUESTIONS + FILOSOFIA_QUESTIONS
    )
    print(f"\nTotal de questoes: {len(all_questions)}")
    print(f"  Sociologia: {len(SOCIOLOGIA_QUESTIONS)}")
    print(f"  Geografia: {len(GEOGRAFIA_QUESTIONS)}")
    print(f"  Filosofia: {len(FILOSOFIA_QUESTIONS)}")

    inserted = insert_questions(all_questions)
    print(f"\nInseridas: {inserted}")

    # Relatorio final
    with db() as conn:
        rows = conn.execute(
            "SELECT subject, COUNT(*) as cnt FROM questions GROUP BY subject ORDER BY cnt DESC"
        ).fetchall()
        print("\n=== QUESTOES POR DISCIPLINA (apos insercao) ===")
        total = 0
        for r in rows:
            print(f"  {r[0]}: {r[1]}")
            total += r[1]
        print(f"  TOTAL: {total}")


if __name__ == "__main__":
    main()
