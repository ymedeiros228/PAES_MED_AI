"""Gera PDFs de Geografia — topicos 9.1 a 9.4."""

from geografia_real_images import REAL_IMAGES
from pdf_base import generate_educational_pdf

# ============================================================
# 9.1 Geografia Fisica
# ============================================================
FISICA = {
    "titulo": "Geografia Fisica",
    "disciplina": "Geografia",
    "topico": "Geografia Fisica",
    "subtopico": "Terra, coordenadas, clima, relevo e hidrografia",
    "introducao": (
        "A geografia fisica estuda os elementos naturais da "
        "superficie terrestre: estrutura da Terra, coordenadas "
        "geograficas, clima, relevo, vegetacao e hidrografia. "
        "E a base para entender a distribuicao da vida humana."
    ),
    "secoes": [
        {
            "titulo": "1. Estrutura da Terra, rotacao e translação",
            "conteudo": (
                "ESTRUTURA INTERNA:\n"
                "- Crosta: camada externa, solida, 5-70 km.\n"
                "- Manto: camada intermediaria, plastica.\n"
                "- Nucleo: ferro e niquel. Externo (liquido) e "
                "interno (solido).\n\n"
                "ROTACAO: movimento em torno do proprio eixo. "
                "Duracao: 24 horas. Consequencias: dia e noite, "
                "fuso horario, achatamento polar.\n\n"
                "TRANSLACAO: movimento em torno do Sol. "
                "Duracao: 365 dias 6 horas. Consequencias: "
                "ano bissexto, estacoes do ano.\n\n"
                "PLACAS TECTONICAS: crosta dividida em placas "
                "que se movem. Causa terremotos, vulcoes, "
                "tsunamis e formacao de montanhas."
            ),
            "exemplo": (
                "A teoria da deriva continental, proposta por "
                "Wegener, afirma que os continentes ja formaram "
                "um unico bloco (Pangeia). A America do Sul e "
                "a Africa ainda se encaixam, evidencia dessa "
                "teoria. As placas tectonicas explicam terremotos "
                "no Chile e no Japao."
            ),
        },
        {
            "titulo": "2. Coordenadas geograficas e cartografia",
            "conteudo": (
                "COORDENADAS GEOGRAFICAS:\n"
                "- Latitude: distancia angular em relacao ao "
                "Equador (0 a 90 graus N/S).\n"
                "- Longitude: distancia angular em relacao a "
                "Greenwich (0 a 180 graus L/O).\n"
                "- Paralelos: linhas horizontais (Equador, "
                "Tropico de Cancer, Capricornio).\n"
                "- Meridianos: linhas verticais (Greenwich).\n\n"
                "FUSOS HORARIOS: 24 fusos, cada um com 15 graus. "
                "Hora GMT/UTC de referencia.\n\n"
                "CARTOGRAFIA:\n"
                "- Projeções: Mercator (navegacao), Robinson "
                "(compreensiva), conica, azimutal.\n"
                "- Escala: razao entre mapa e realidade "
                "(1:100000 = 1cm = 1km).\n"
                "- Convenções: simbolos padronizados."
            ),
            "exemplo": (
                "Sao Luis (MA) esta a aproximadamente 2 graus "
                "Sul e 44 graus Oeste. Como esta a 44 graus Oeste "
                "de Greenwich, seu fuso horario e UTC-3. Quando "
                "sao 12h em Londres, sao 9h em Sao Luis. A "
                "projeção de Mercator distorce areas polares, "
                "fazendo a Groenlandia parecer maior que a Africa."
            ),
        },
        {
            "titulo": "3. Clima, relevo, vegetacao e hidrografia",
            "conteudo": (
                "CLIMA:\n"
                "- Elementos: temperatura, umidade, precipitacao, "
                "ventos, pressao.\n"
                "- Fatores: latitude, altitude, maritimidade, "
                "correntes maritimas, continentalidade.\n"
                "- Massas de ar: mT (tropical atlantica), mE "
                "(equatorial atlantica), mP (polar), mPA "
                "(polar atlantica).\n\n"
                "RELEVO: montanhas, planaltos, planicies, "
                "depressoes. No Brasil: planaltos predominam.\n\n"
                "VEGETACAO BRASILEIRA:\n"
                "- Floresta Amazonica (equatorial).\n"
                "- Cerrado (savana tropical).\n"
                "- Caatinga (semiarida).\n"
                "- Mata Atlantica (tropical umida).\n"
                "- Pampa (campos subtropicais).\n"
                "- Pantanal (umido).\n\n"
                "HIDROGRAFIA: bacias hidrograficas. Brasil: "
                "Amazonica (maior), Sao Francisco, Parana, "
                "Tocantins-Araguaia, Uruguai."
            ),
            "exemplo": (
                "A Floresta Amazonica e a maior floresta tropical "
                "do mundo, com biodiversidade incomparavel. O rio "
                "Amazonas, na bacia Amazonica, e o maior rio em "
                "volume de agua do mundo. A construcao de usinas "
                "hidreletricas no rio Sao Francisco (Sobradinho, "
                "Itaparica) alterou seu regime natural."
            ),
        },
    ],
    "resumo": (
        "- Terra: crosta, manto, nucleo. Rotacao (24h), translacao (365 dias).\n"
        "- Placas tectonicas: terremotos, vulcoes, montanhas.\n"
        "- Coordenadas: latitude (Equador), longitude (Greenwich).\n"
        "- Fusos horarios: 24 fusos de 15 graus.\n"
        "- Clima: elementos (temp, umidade) e fatores (latitude, altitude).\n"
        "- Vegetacao Brasil: Amazonia, Cerrado, Caatinga, Mata Atlantica, Pampa, Pantanal.\n"
        "- Bacias: Amazonica, Sao Francisco, Parana, Tocantins-Araguaia."
    ),
    "dicas": [
        "Rotacao = dia/noite. Translacao = estacoes do ano.",
        "Latitude vai de 0 a 90. Longitude de 0 a 180.",
        "Projeção de Mercator distorce areas polares.",
        "Massa tropical atlantica (mT) influencia o clima do Brasil.",
        "Bacia Amazonica e a maior do mundo em volume de agua.",
        "Cerrado e a savana brasileira, segundo maior bioma.",
    ],
    "pegadinhas": [
        "Confundir rotacao com translacao: rotacao = dia/noite, translacao = estacoes.",
        "Achar que Greenwich e o Equador: Greenwich e meridiano (longitude).",
        "Esquecer que a projeção de Mercator distorce tamanho real.",
        "Confundir bacia hidrografica com rio: bacia e a area drenada.",
        "Achar que Caatinga e floresta: e vegetacao xerofita, semiarida.",
        "Confundir planalto com planicie: planalto e elevado, planicie e plano e baixo.",
    ],
    "referencias": [
        "MORAES, A. C. R. Geografia: pequena historia critica. 20. ed. Sao Paulo: Hucitec, 2005.",
        "ROSS, J. L. S. Geografia do Brasil. 5. ed. Sao Paulo: Edusp, 2009.",
        "TUBAKI, K. et al. Geografia: conceitos e dinamicas. Sao Paulo: Atica, 2013.",
        "CONTI, J. B. Clima e meio ambiente. Sao Paulo: Contexto, 2010.",
        "AB SABER, A. N. Os dominios de natureza no Brasil. Sao Paulo: Atelie Editorial, 2003.",
        "SANTOS, M. A natureza do espaco. 4. ed. Sao Paulo: Edusp, 2006.",
    ],
}

IMG_FISICA = [
    {"file": "geo_fisica.png", "caption": "Estrutura da Terra, coordenadas e clima", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("geo_fisica", [])

# ============================================================
# 9.2 Geografia Humana
# ============================================================
HUMANA = {
    "titulo": "Geografia Humana",
    "disciplina": "Geografia",
    "topico": "Geografia Humana",
    "subtopico": "Demografia, economia, urbanizacao e geopolitica",
    "introducao": (
        "A geografia humana estuda a relacao entre sociedade e "
        "espaco: distribuicao populacional, atividades economicas, "
        "urbanizacao, geopolitica e questoes ambientais."
    ),
    "secoes": [
        {
            "titulo": "1. Demografia e composicao populacional",
            "conteudo": (
                "DISTRIBUICAO: desigual no planeta. Densas: "
                "Asia, Europa. Vazias: desertos, polos, Amazonia.\n\n"
                "CRESCIMENTO POPULACIONAL:\n"
                "- Paises em desenvolvimento crescem mais.\n"
                "- Transicao demografica: queda de mortalidade, "
                "depois queda de natalidade.\n"
                "- Explosao demografica nos seculos XX-XXI.\n\n"
                "MIGRACOES:\n"
                "- Rural-urbano: urbanizacao.\n"
                "- Internacionais: refugiados, trabalho.\n"
                "- Causas: economicas, guerras, ambientais.\n\n"
                "COMPOSICAO: idade (jovem, adulta, idosa), "
                "genero, etnia, renda, educacao."
            ),
            "exemplo": (
                "O Brasil passou por transicao demografica: "
                "nas decadas de 1960-70 tinha alta natalidade "
                "e mortalidade em queda (explosao demografica). "
                "Hoje, natalidade e mortalidade estao baixas, "
                "com populacao envelhecendo. Isso exige ajustes "
                "na previdencia e na saude publica."
            ),
        },
        {
            "titulo": "2. Economia, industria e comercio",
            "conteudo": (
                "USO DA TERRA:\n"
                "- Agricultura: commodities (soja, cafe, cana).\n"
                "- Pecuaria: bovinos, suinos, aves.\n"
                "- Extrativismo: madeira, minerais, pesca.\n\n"
                "ATIVIDADES ECONOMICAS:\n"
                "- Primario: agropecuaria, extrativismo.\n"
                "- Secundario: industria, construcao.\n"
                "- Terciario: servicos, comercio.\n"
                "- Quaternario: conhecimento, tecnologia.\n\n"
                "ENERGIA: hidreletrica, petroleo, gas, nuclear, "
                "eolica, solar. Brasil: hidreletrica predominante.\n\n"
                "COMERCIO EXTERNO: exportacao e importacao. "
                "Brasil exporta commodities, importa tecnologia."
            ),
            "exemplo": (
                "O Brasil e um dos maiores exportadores de soja "
                "do mundo, especialmente para a China. A soja e "
                "cultivada no Centro-Oeste e transportada pela "
                "BR-163 ate o porto de Santarem (PA) e Itaqui (MA). "
                "Essa cadeia mostra a integracao entre agricultura, "
                "transporte e comercio exterior."
            ),
        },
        {
            "titulo": "3. Urbanizacao, geopolitica e questao ambiental",
            "conteudo": (
                "URBANIZACAO:\n"
                "- Crescimento acelerado desde a Revolucao Industrial.\n"
                "- Metropoles: Sao Paulo, Rio, Nova York, Tokyo.\n"
                "- Problemas: favelas, transito, poluicao, "
                "saneamento.\n"
                "- Cidades globais: centros financeiros.\n\n"
                "GEOPOLITICA (MEGABLOCOS):\n"
                "- UE (Uniao Europeia).\n"
                "- USMCA/NAFTA (EUA, Canada, Mexico).\n"
                "- Mercosul.\n"
                "- BRICS.\n"
                "- ASEAN.\n\n"
                "QUESTAO AMBIENTAL:\n"
                "- Aquecimento global: CO2, efeito estufa.\n"
                "- Desmatamento: Amazonia, Cerrado.\n"
                "- Poluicao: ar, agua, solo.\n"
                "- Biodiversidade: extincao de especies.\n"
                "- Desenvolvimento sustentavel."
            ),
            "exemplo": (
                "Sao Paulo e uma cidade global: concentra sedes "
                "de empresas, financas e servicos. Mas enfrenta "
                "problemas como transito, favelas e desigualdade. "
                "O aquecimento global, causado pelo excesso de CO2, "
                "afeta o Brasil com secas mais intensas no Nordeste "
                "e enchentes no Sul."
            ),
        },
    ],
    "resumo": (
        "- Distribuicao populacional desigual: Asia densa, desertos vazios.\n"
        "- Transicao demografica: queda de mortalidade, depois natalidade.\n"
        "- Migracoes: rural-urbano e internacionais.\n"
        "- Setores: primario, secundario, terciario, quaternario.\n"
        "- Urbanizacao: metropoles, favelas, cidades globais.\n"
        "- Megablocos: UE, USMCA, Mercosul, BRICS, ASEAN.\n"
        "- Questao ambiental: aquecimento, desmatamento, poluicao."
    ),
    "dicas": [
        "Transicao demografica: primeiro cai mortalidade, depois natalidade.",
        "Brasil: 70% do PIB vem do setor terciario (servicos).",
        "Cidades globais: Nova York, Londres, Tokyo, Sao Paulo.",
        "BRICS: Brasil, Russia, India, China, Africa do Sul.",
        "Desmatamento da Amazonia e questao ambiental global.",
        "Energia hidreletrica predomina no Brasil, mas eolica e solar crescem.",
    ],
    "pegadinhas": [
        "Achar que populacao mundial cresce igual em todos os paises.",
        "Confundir setor secundario com terciario: secundario e industria.",
        "Esquecer que urbanizacao traz problemas ambientais.",
        "Confundir Mercosul com Mercosul + UE (acordos comerciais).",
        "Achar que aquecimento global e so CO2: tambem metano, desmatamento.",
        "Confundir cidade global com megacidade: nem toda megacidade e global.",
    ],
    "referencias": [
        "SANTOS, M. Por uma outra globalizacao. 25. ed. Rio de Janeiro: Record, 2015.",
        "MORAES, A. C. R. Geografia: pequena historia critica. 20. ed. Sao Paulo: Hucitec, 2005.",
        "ROSS, J. L. S. Geografia do Brasil. 5. ed. Sao Paulo: Edusp, 2009.",
        "CASTELLS, M. A sociedade em rede. 10. ed. Sao Paulo: Paz e Terra, 2008.",
        "HARVEY, D. A condicao pos-moderna. 12. ed. Sao Paulo: Loyola, 2003.",
        "VESENTINI, J. W. Geografia: o mundo em transicao. Sao Paulo: Atica, 2011.",
    ],
}

IMG_HUMANA = [
    {"file": "geo_humana.png", "caption": "Demografia, economia e urbanizacao", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("geo_humana", [])

# ============================================================
# 9.3 Geografia do Maranhao
# ============================================================
GEO_MARANHAO = {
    "titulo": "Geografia do Maranhao",
    "disciplina": "Geografia",
    "topico": "Geografia do Maranhao",
    "subtopico": "Fisica, economia, sociedade e cultura maranhense",
    "introducao": (
        "O Maranhao tem posicao geografica unica: transicao entre "
        "a Amazonia e o Nordeste semiarido. Combina floresta, "
        "cerrado, caatinga e manguezais, com economia em "
        "transformacao e cultura rica."
    ),
    "secoes": [
        {
            "titulo": "1. Geografia fisica do Maranhao",
            "conteudo": (
                "POSICAO: estado do Nordeste, mas com caracteristicas "
                "amazonicas no oeste. Transicao Amazonia-Nordeste.\n\n"
                "RELEVO: predominio de planicies e planaltos "
                "baixos. Chapada do Maranhao ao sul.\n\n"
                "CLIMA:\n"
                "- Oeste: equatorial umido (Amazonia).\n"
                "- Centro: tropical com estacao seca (Cerrado).\n"
                "- Leste: semiarido (Caatinga, transicao).\n"
                "- Litoral: tropical umido (manguezais).\n\n"
                "VEGETACAO:\n"
                "- Floresta Amazonica (oeste).\n"
                "- Cerrado (centro, maior area).\n"
                "- Caatinga (leste, transicao).\n"
                "- Manguezais (litoral, Baixada Maranhense).\n"
                "- Cocais (transicao, babacu.\n\n"
                "RIOS: Pindare, Mearim, Itapecuru, Grajau, Turiacu."
            ),
            "exemplo": (
                "A Baixada Maranhense, no litoral, e uma area de "
                "manguezais e campos alagaveis. Abriga comunidades "
                "ribeirinhas e pesqueiras. Os manguezais sao "
                "bercarios de especies marinhas e protegem a costa "
                "da erosao. A vegetacao de cocais, com babacu, e "
                "caracteristica do Maranhao e sustenta as "
                "quebradeiras de coco."
            ),
        },
        {
            "titulo": "2. Economia do Maranhao",
            "conteudo": (
                "INDUSTRIA:\n"
                "- Alumar: producao de aluminio (Sao Luis).\n"
                "- Suzano: papel e celulose (Imperatriz).\n"
                "- Cimentos, fertilizantes, alimentos.\n\n"
                "PORTO DE ITAQUI: um dos maiores do Brasil. "
                "Exporta ferro, soja, combustiveis. Estrategico "
                "para a Amazonia e Centro-Oeste.\n\n"
                "AGROPECUARIA:\n"
                "- Soja: sul do estado, BR-163.\n"
                "- Pecuaria: bovinos, centro e sul.\n"
                "- Mandioca, arroz, milho: agricultura familiar.\n\n"
                "ENERGIA: hidreletrica (Boa Esperanca), gas natural "
                "(Bacia do Parnaiba), eolica (litoral).\n\n"
                "BR-163: corredor de exportacao ligando o "
                "Centro-Oeste ao porto de Itaqui."
            ),
            "exemplo": (
                "A Alumar, em Sao Luis, e um dos maiores complexos "
                "de aluminio do mundo. Consome muita energia "
                "eletrica para refinar a bauxita. O porto de Itaqui "
                "exporta o aluminio e tambem minério de ferro de "
                "Carajas (PA). A BR-163 traz soja do Mato Grosso "
                "para exportacao pelo Itaqui."
            ),
        },
        {
            "titulo": "3. Sociedade e cultura maranhense",
            "conteudo": (
                "POPULACAO: ~7 milhoes. Densidade ~20 hab/km2. "
                "Concentrada em Sao Luis e Imperatriz.\n\n"
                "ETNIAS: afrodescendentes (maioria), indigenas, "
                "europeus, mesticos.\n\n"
                "COMUNIDADES TRADICIONAIS:\n"
                "- Quilombolas: numerosas, especialmente na "
                "Baixada.\n"
                "- Quebradeiras de coco babacu.\n"
                "- Ribeirinhas, pesqueiras.\n"
                "- Indigenas: Guajajara, Ka'apor, Canela.\n\n"
                "CULTURA:\n"
                "- Bumba-meu-boi: principal manifestacao, "
                "patrimonio imaterial.\n"
                "- Tambor de crioula: danca afro-maranhense.\n"
                "- Tambor de mina: religiao afro-brasileira.\n"
                "- Cacuria, reggae de Sao Luis.\n"
                "- Culinaria: arroz de cuxa, torta de caju, "
                "pescada, vatapa.\n\n"
                "DESAFIOS: desigualdade, IDH baixo, "
                "coronelismo, transicao economica."
            ),
            "exemplo": (
                "O bumba-meu-boi e a maior festa popular do "
                "Maranhao, reconhecida como patrimonio cultural "
                "imaterial do Brasil. Combemora o ciclo vida-morte-"
                "renascimento do boi, com musica, danc,a e teatro. "
                "Os sotaques (matracado, zabumba, orquestra) "
                "variam por regiao. O tambor de crioula, danca "
                "afro-maranhense, e patrimonio imaterial estadual."
            ),
        },
    ],
    "resumo": (
        "- Maranhao: transicao Amazonia-Nordeste.\n"
        "- Clima: equatorial (oeste), tropical (centro), semiarido (leste).\n"
        "- Vegetacao: Amazonia, Cerrado, Caatinga, manguezais, cocais.\n"
        "- Economia: Alumar, Itaqui, soja, pecuaria, BR-163.\n"
        "- Comunidades: quilombolas, quebradeiras, indigenas.\n"
        "- Cultura: bumba-meu-boi, tambor de crioula, tambor de mina."
    ),
    "dicas": [
        "Maranhao e transicao Amazonia-Caatinga: unica no Brasil.",
        "Porto de Itaqui: estrategico para exportacao da Amazonia.",
        "Alumar: maior complexo de aluminio da America Latina.",
        "Bumba-meu-boi: patrimonio cultural imaterial do Brasil.",
        "Cocais: vegetacao de transicao com babacu, caracteristica maranhense.",
        "BR-163 liga Mato Grosso ao Itaqui, corredor de soja.",
    ],
    "pegadinhas": [
        "Achar que o Maranhao e so semiarido: tem Amazonia no oeste.",
        "Confundir Cerrado maranhense com Caatinga: sao diferentes.",
        "Esquecer os quilombolas no Maranhao: estado tem muitos.",
        "Achar que Itaqui exporta so do Maranhao: tambem de PA e MT.",
        "Confundir tambor de crioula com tambor de mina: crioula e danca, mina e religiao.",
        "Esquecer que o Maranhao tem manguezais no litoral.",
    ],
    "referencias": [
        "ABREU, A. A. Maranhao: historia e cultura. Sao Luis: EDUFMA, 2008.",
        "MEIRELES, M. M. Geografia do Maranhao. Sao Luis: Sicomp, 2010.",
        "ALMEIDA, A. L. O Maranhao no contexto da historia. Sao Luis: GEPE, 2005.",
        "FIGUEIREDO, A. M. Historia do Maranhao: da colonia a atualidade. Sao Luis: Lithos, 2015.",
        "ANDRADE, M. C. A terra e o homem no Nordeste. 8. ed. Recife: UFPE, 2010.",
        "NOVAES, W. A Floresta e o homem. Sao Paulo: Contexto, 2012.",
    ],
}

IMG_GEO_MARANHAO = [
    {"file": "geo_maranhao.png", "caption": "Mapa e regioes do Maranhao", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("geo_maranhao", [])

# ============================================================
# 9.4 Temas Contemporaneos
# ============================================================
CONTEMPORANEOS = {
    "titulo": "Temas Contemporaneos",
    "disciplina": "Geografia",
    "topico": "Temas Contemporaneos",
    "subtopico": "Trabalho, violencia, sustentabilidade, geopolitica e geotecnologias",
    "introducao": (
        "Os temas contemporaneos da geografia abordam os desafios "
        "do seculo XXI: precarizacao do trabalho, violencias, "
        "sustentabilidade, conflitos geopoliticos e geotecnologias."
    ),
    "secoes": [
        {
            "titulo": "1. Trabalho e condicao humana",
            "conteudo": (
                "PRECARIZACAO: perda de direitos trabalhistas. "
                "Trabalho informal, sem carteira, sem beneficios.\n\n"
                "UBERIZACAO: plataformas digitais como 'empregadoras'. "
                "Motoristas, entregadores sem vinculo formal.\n\n"
                "TRABALHO INFORMAL: mais de 50% no Brasil. Inclui "
                "vendedores ambulantes, diaristas, autonomos.\n\n"
                "DESEMPREGO ESTRUTURAL: automacao e IA substituem "
                "trabalhos. Nao e conjuntural, e permanente.\n\n"
                "TRABALHO ESCRAVO CONTEMPORANEO: ainda existe em "
                "fazendas, confecoes, construcao. Combate pelo "
                "Ministerio do Trabalho."
            ),
            "exemplo": (
                "Os entregadores de aplicativo (iFood, Uber Eats) "
                "trabalham sem carteira assinada, sem ferias, sem "
                "13o. Recebem por entrega, mas arcam com os custos "
                "de combustivel e manutencao. Esse modelo e a "
                "uberizacao: flexibilidade para a empresa, "
                "precariosidade para o trabalhador."
            ),
        },
        {
            "titulo": "2. Violencias e impasses politicos",
            "conteudo": (
                "VIOLENCIA URBANA: criminalidade nas cidades. "
                "Brasil: 60 mil+ homicidios por ano.\n\n"
                "VIOLENCIA DE GENERO: feminicidio, violencia "
                "domestica. Lei Maria da Penha (2006).\n\n"
                "VIOLENCIA RACIAL: genocidio da juventude negra. "
                "Negros sao 75% das vitimas de homicidio.\n\n"
                "NARCOTRAFICO: faccoes, territorios, violencia. "
                "Brasil: Comando Vermelho, PCC, ADA.\n\n"
                "IMPASSES POLITICOS: polarizacao, crise democratica, "
                "desinformacao, fake news."
            ),
            "exemplo": (
                "O feminicidio e crime hediondo no Brasil desde "
                "2015. A Lei Maria da Penha (2006) criou mecanismos "
                "para proteger mulheres. Ainda assim, o Brasil tem "
                "altas taxas de violencia de genero. A juventude "
                "negra e a principal vitima de homicidios, "
                "evidenciando a violencia racial estrutural."
            ),
        },
        {
            "titulo": "3. Sustentabilidade, geopolitica e geotecnologias",
            "conteudo": (
                "EDUCACAO AMBIENTAL E SUSTENTABILIDADE:\n"
                "- 3 pilares: social, economico, ambiental.\n"
                "- ODS (Objetivos de Desenvolvimento Sustentavel): "
                "17 metas da ONU, Agenda 2030.\n"
                "- Economia circular: reduzir, reutilizar, reciclar.\n"
                "- Energias renovaveis: solar, eolica, biomassa.\n\n"
                "GEOPOLITICA E CONFLITOS:\n"
                "- Guerra Russia-Ucrania.\n"
                "- Conflito Israel-Palestina.\n"
                "- Migracoes e refugiados.\n"
                "- Disputa EUA-China.\n\n"
                "GEOTECNOLOGIAS:\n"
                "- GPS: posicionamento global.\n"
                "- SIG (GIS): sistemas de informacao geografica.\n"
                "- Satelites: monitoramento ambiental.\n"
                "- Drones: mapeamento, agricultura de precisao.\n"
                "- Sensoriamento remoto: imagens de satelite."
            ),
            "exemplo": (
                "Os ODS da ONU incluem erradicar a pobreza, "
                "garantir educacao de qualidade, agua potavel e "
                "acao contra mudanca climatica. O Brasil se "
                "comprometeu com a Agenda 2030. Satelites como o "
                "CBERS (China-Brasil) monitoram o desmatamento da "
                "Amazonia em tempo real, exemplo de geotecnologia "
                "aplicada a sustentabilidade."
            ),
        },
    ],
    "resumo": (
        "- Trabalho: precarizacao, uberizacao, informalidade, desemprego estrutural.\n"
        "- Violencias: urbana, genero (feminicidio), racial, narcotrafico.\n"
        "- Sustentabilidade: 3 pilares, ODS, Agenda 2030, economia circular.\n"
        "- Geopolitica: Russia-Ucrania, Israel-Palestina, migracoes, EUA-China.\n"
        "- Geotecnologias: GPS, SIG, satelites, drones, sensoriamento remoto."
    ),
    "dicas": [
        "Uberizacao: app como patrao, sem direitos trabalhistas.",
        "Lei Maria da Penha (2006): protege mulheres contra violencia.",
        "ODS: 17 objetivos da ONU para 2030.",
        "CBERS: satelite sino-brasileiro para monitorar Amazonia.",
        "Economia circular: reduzir, reutilizar, reciclar.",
        "SIG (GIS): ferramenta para analise espacial.",
    ],
    "pegadinhas": [
        "Achar que uberizacao e liberdade: e precarizacao disfarcada.",
        "Confundir desemprego estrutural com conjuntural: estrutural e permanente.",
        "Esquecer que violencia racial e tema geografico, nao so sociologico.",
        "Achar que ODS sao apenas ambientais: sao sociais e economicos tambem.",
        "Confundir GPS com SIG: GPS posiciona, SIG analisa dados espaciais.",
        "Esquecer que geotecnologias sao ferramentas, nao solucoes por si so.",
    ],
    "referencias": [
        "SANTOS, M. A natureza do espaco. 4. ed. Sao Paulo: Edusp, 2006.",
        "HARVEY, D. A condicao pos-moderna. 12. ed. Sao Paulo: Loyola, 2003.",
        "ONU. Objetivos de Desenvolvimento Sustentavel. Nova York: ONU, 2015.",
        "BAUMAN, Z. Modernidade liquida. Rio de Janeiro: Zahar, 2001.",
        "CASTELLS, M. A sociedade em rede. 10. ed. Sao Paulo: Paz e Terra, 2008.",
        "FONSECA, R. Geotecnologias e meio ambiente. Sao Paulo: Oficina de Textos, 2015.",
    ],
}

IMG_CONTEMPORANEOS = [
    {"file": "geo_contemporaneos.png", "caption": "Temas contemporaneos: desafios do seculo XXI", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("geo_contemporaneos", [])

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (FISICA, "GEO_FISICA.pdf", IMG_FISICA, "Geografia — Geografia Fisica"),
        (HUMANA, "GEO_HUMANA.pdf", IMG_HUMANA, "Geografia — Geografia Humana"),
        (GEO_MARANHAO, "GEO_MARANHAO.pdf", IMG_GEO_MARANHAO, "Geografia — Geografia do Maranhao"),
        (CONTEMPORANEOS, "GEO_TEMAS_CONTEMPORANEOS.pdf", IMG_CONTEMPORANEOS, "Geografia — Temas Contemporaneos"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
