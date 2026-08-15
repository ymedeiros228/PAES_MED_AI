# -*- coding: utf-8 -*-
"""Gera PDFs de Fisica — batch 3 (topicos 3.9 a 3.11)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 3.9 Eletrodinamica
# ============================================================
ELETRODINAMICA = {
    "titulo": "Eletrodinâmica",
    "disciplina": "Física",
    "topico": "Eletrodinamica",
    "subtopico": "Corrente eletrica, resistencia, potencia e circuitos",
    "introducao": (
    "A Eletrodinamica estuda o movimento ordenado de cargas "
        "eletricas, ou seja, a corrente eletrica. Esses conceitos "
        "explicam o funcionamento de aparelhos, musculos e ate do "
        "proprio corpo humano."
    ),
    "secoes": [
        {
            "titulo": "1. Corrente eletrica e resistencia",
            "conteudo": (
                "CORRENTE ELETRICA: fluxo ordenado de cargas. A "
                "intensidade e i = Delta Q / Delta t, medida em "
                "ampere (A). 1 A = 1 C/s.\n\n"
                "TIPOS DE CORRENTE:\n"
                "- Continua (DC): sentido constante, como em pilhas.\n"
                "- Alternada (AC): sentido muda periodicamente, como "
                "na rede eletrica.\n\n"
                "RESISTENCIA ELETRICA: oposicao a passagem da "
                "corrente. A primeira lei de Ohm: V = R . i, onde "
                "V e a ddp, R a resistencia e i a corrente.\n\n"
                "SEGUNDA LEI DE OHM: a resistencia de um fio e "
                "R = ro . L / A, onde ro e a resistividade, L o "
                "comprimento e A a area da secao transversal.\n\n"
                "CONDUTORES E ISOLANTES: metais conduzem bem por "
                "terem eletrons livres. Materiais como borracha "
                "e plastico sao isolantes."
            ),
            "exemplo": (
                "O eletrocardiograma registra correntes ionicas no "
                "coracao. Pequenas diferencas de potencial geram "
                "correntes eletricas que se propagam pelo corpo. "
                "Eletrodos captam esses sinais e os registram em "
                "um grafico de voltagem versus tempo. Em "
                "desfibriladores, correntes de alto valor corrigem "
                "arritmias, restabelecendo o ritmo cardiaco."
            ),
        },
        {
            "titulo": "2. Associacao de resistores e circuitos",
            "conteudo": (
                "ASSOCIACAO EM SERIE:\n"
                "- Corrente e a mesma em todos os resistores.\n"
                "- R_total = R1 + R2 + ...\n"
                "- A ddp se divide entre os resistores.\n\n"
                "ASSOCIACAO EM PARALELO:\n"
                "- Ddp e a mesma em todos os resistores.\n"
                "- 1/R_total = 1/R1 + 1/R2 + ...\n"
                "- A corrente se divide entre os resistores.\n\n"
                "POTENCIA ELETRICA: P = V . i. Tambem pode ser "
                "escrita como P = R . i^2 ou P = V^2 / R.\n\n"
                "UNIDADE: watt (W). 1 W = 1 J/s.\n\n"
                "ENERGIA CONSUMIDA: E = P . t. Usualmente medida em "
                "quilowatt-hora (kWh). 1 kWh = 3,6 x 10^6 J."
            ),
            "exemplo": (
                "Um ventilador domestico de 100 W ligado por 8 horas "
                "consome E = 0,1 kW . 8 h = 0,8 kWh. Em um hospital, "
                "o consumo de equipamentos e monitorado para evitar "
                "sobrecarga. Cirurgias eletricas usam correntes "
                "controladas para cauterizar tecidos sem danificar "
                "zonas vizinhas, aproveitando o efeito Joule."
            ),
        },
        {
            "titulo": "3. Efeito Joule e seguranca eletrica",
            "conteudo": (
                "EFEITO JOULE: o calor liberado num condutor devido a "
                "passagem da corrente. Q = R . i^2 . t. Quanto "
                "maior a corrente ou a resistencia, mais calor.\n\n"
                "POTENCIA DISSIPADA: P = R . i^2. E a energia "
                "transformada em calor por segundo.\n\n"
                "SEGURANCA ELETRICA:\n"
                "- Fuga de corrente pode causar choques. O "
                "disjuntor residual (DR) desarma quando detecta "
                "diferenca de corrente.\n"
                "- Curto-circuito: corrente muito alta por caminho "
                "de baixa resistencia.\n"
                "- Aterramento: conduz correntes indesejadas para a "
                "Terra, protegendo pessoas e equipamentos.\n\n"
                "RESISTIVIDADE DO CORPO HUMANO: a pele seca e um "
                "isolante, mas internamente o corpo conduz "
                "corrente. Correntes acima de 10 mA podem causar "
                "contracoes musculares; acima de 100 mA, fibrilacao "
                "ventricular."
            ),
            "exemplo": (
                "Cauterizadores eletricos cirurgicos aquecem um fio "
                "metalico pela passagem de corrente. A potencia "
                "dissipada P = R . i^2 provoca calor suficiente "
                "para coagular proteinas e cortar tecidos com "
                "minimo sangramento. O controle preciso da "
                "corrente e essencial para nao queimar tecidos "
                "saudaveis."
            ),
        },
    ],
    "resumo": (
        "- Corrente: i = Delta Q / Delta t. Unidade: ampere (A).\n"
        "- 1a Lei de Ohm: V = R . i.\n"
        "- Serie: R_total = R1 + R2 + ... Paralelo: 1/R_total = 1/R1 + 1/R2 + ...\n"
        "- Potencia: P = V . i = R . i^2 = V^2 / R.\n"
        "- Energia: E = P . t, geralmente em kWh.\n"
        "- Efeito Joule: Q = R . i^2 . t."
    ),
    "dicas": [
    "Em serie, a corrente e igual; em paralelo, a ddp e igual.",
    "A potencia mede energia por segundo; a energia e potencia vezes tempo.",
        "1 kWh = 3,6 x 10^6 J.",
    "Curto-circuito ocorre quando a resistencia e muito baixa e a corrente explode.",
    "Pele seca tem alta resistencia; pele molhada ou tecidos internos conduzem bem.",
    "DR protege contra choques, disjuntor protege contra sobrecarga.",
    ],
    "pegadinhas": [
    "Confundir corrente com tensao: tensao (V) e forca, corrente (i) e fluxo.",
    "Esquecer que em paralelo a ddp e a mesma, nao a corrente.",
    "Achar que resistencia em serie e o produto: e a soma.",
    "Usar P = V^2/R em dispositivos com corrente constante.",
    "Esquecer de converter kWh para joules quando necessario.",
    "Achar que materiais com alta resistencia nao conduzem: conduzem pouco, mas ainda conduzem.",
    ],
    "referencias": [
    "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
    "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
    "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
    "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
    "NUSSENZVEIG, H. M. Curso de Fisica Basica. 4. ed. Sao Paulo: E. Blucher, 2002.",
    "FEYNMAN, R. P. Lectures on Physics: Eletromagnetismo. Sao Paulo: Bookman, 2008.",
    ],
}

IMG_ELETRODINAMICA = []

# ============================================================
# 3.10 Eletromagnetismo
# ============================================================
ELETROMAGNETISMO = {
    "titulo": "Eletromagnetismo",
    "disciplina": "Física",
    "topico": "Eletromagnetismo",
    "subtopico": "Campo magnetico, forca magnetica, inducao e ondas eletromagneticas",
    "introducao": (
    "O Eletromagnetismo une a eletricidade e o magnetismo. "
    "Correntes eletricas criam campos magneticos e campos "
        "magneticos variaveis geram correntes. Esses fenomenos "
        "sao a base de motores, geradores, ressonancia magnetica "
        "e comunicacoes."
    ),
    "secoes": [
        {
            "titulo": "1. Campo magnetico e forca magnetica",
            "conteudo": (
                "IMAS E POLOS: todo ima tem polo norte e polo sul. "
                "Polos iguais se repelem, opostos se atraem. Monopolos "
                "magneticos nao existem na natureza.\n\n"
                "CAMPO MAGNETICO: regiao onde uma forca magnetica "
                "atua. Representado por linhas de campo que saem do "
                "polo norte e entram no polo sul.\n\n"
                "FORCA SOBRE CARGA EM MOVIMENTO: "
                "F = |q| . v . B . sen teta, onde q e a carga, v a "
                "velocidade, B a inducao magnetica e teta o angulo "
                "entre v e B.\n\n"
                "UNIDADE DE B: tesla (T).\n\n"
                "FORCA SOBRE CONDUTOR RETO: F = B . i . L . sen teta, "
                "onde L e o comprimento do condutor, i a corrente e "
                "B a inducao."
            ),
            "exemplo": (
                "A ressonancia magnetica (RM) utiliza um campo "
                "magnetico intenso para alinhar os nucleos de "
                "hidrogenio do corpo. Um segundo campo de radio "
                "frequencia desalinha alguns nucleos. Quando o campo "
                "de RF e desligado, os nucleos relaxam e emitem "
                "sinais que formam a imagem. Sem campo magnetico, "
                "nao ha alinhamento; sem RF, nao ha perturbacao."
            ),
        },
        {
            "titulo": "2. Inducao eletromagnetica",
            "conteudo": (
                "FLUXO MAGNETICO: medida da quantidade de linhas de "
                "campo atraves de uma area. Phi = B . A . cos teta. "
                "Unidade: weber (Wb).\n\n"
                "LEI DE FARADAY: uma forca eletromotriz (fem) e "
                "induzida num circuito sempre que o fluxo magnetico "
                "atraves dele varia. fem = - N . Delta Phi / Delta t.\n\n"
                "LEI DE LENZ: a corrente induzida se opoe a variacao "
                "do fluxo que a originou. O sinal negativo na lei de "
                "Faraday exprime essa oposicao.\n\n"
                "GERADORES: a rotacao de uma espira dentro de um "
                "campo magnetico gera corrente alternada. O "
                "transformador muda niveis de tensao usando inducao."
            ),
            "exemplo": (
                "Aparelhos de estimulacao magnetica transcraniana "
                "(TMS) usam campos magneticos variaveis para induzir "
                "correntes eletricas no cerebro. A variacao rapida do "
                "campo cria uma corrente que despolariza neuronios, "
                "sendo usada no tratamento de depressao e estudos "
                "de funcao cerebral. A inducao e direta e previsivel "
                "pela lei de Faraday."
            ),
        },
        {
            "titulo": "3. Ondas eletromagneticas e espectro",
            "conteudo": (
                "ONDAS ELETROMAGNETICAS: perturbacoes oscillantes dos "
                "campos eletrico e magnetico que se propagam no vacuo "
                "a velocidade c = 3 x 10^8 m/s.\n\n"
                "ESPECTRO ELETROMAGNETICO: organizado por frequencia "
                "e comprimento de onda.\n"
                "- Ondas de radio: menor frequencia, maior lambda.\n"
                "- Micro-ondas: usadas em comunicacoes e aquecimento.\n"
                "- Infravermelho: calor.\n"
                "- Luz visivel: pequena faixa, de 400 a 700 nm.\n"
                "- Ultravioleta: maior energia, causa queimaduras.\n"
                "- Raios X: atravessam tecidos moles.\n"
                "- Raios gama: muito energeticos, usados em radioterapia.\n\n"
                "RELAÇAO: c = lambda . f. Maior frequencia significa "
                "menor comprimento de onda e maior energia."
            ),
            "exemplo": (
                "Os raios X sao usados em radiografias porque atravessam "
        "partes moles do corpo e sao absorvidos pelos ossos. A "
                "tomografia computadorizada usa multiplos feixes de "
                "raios X para reconstruir imagens tridimensionais. "
                "A radioterapia com raios gama destroi celulas "
                "tumorosas aproveitando a alta energia dessas ondas."
            ),
        },
    ],
    "resumo": (
        "- Polos iguais repetem, opostos atraem.\n"
        "- Forca magnetica: F = |q|.v.B.sen teta.\n"
        "- Fluxo: Phi = B.A.cos teta. Faraday: fem = -N.Delta Phi / Delta t.\n"
        "- Lei de Lenz: corrente induzida se opoe a variacao do fluxo.\n"
        "- Ondas eletromagneticas: c = lambda . f = 3 x 10^8 m/s.\n"
        "- Espectro: radio, micro-ondas, IV, visivel, UV, raios X, gama."
    ),
    "dicas": [
    "A forca magnetica e maxima quando v e perpendicular a B (teta = 90).",
    "A forca magnetica e nula quando v e paralelo a B (teta = 0 ou 180).",
    "A corrente induzida aparece so quando o fluxo magnetico varia.",
    "Transformador so funciona com corrente alternada (fluxo variavel).",
    "Quanto maior a frequencia, maior a energia do foton e menor o comprimento de onda.",
    "Raios X atravessam tecidos moles; raios gama sao ainda mais penetrantes.",
    ],
    "pegadinhas": [
    "Achar que existe monopolo magnetico: nao existe na natureza; polos sempre vem aos pares.",
    "Esquecer que forca magnetica so atua em cargas em movimento.",
    "Confundir campo magnetico B com forca F: B e a causa, F e o efeito sobre a carga.",
    "Achar que fluxo nulo significa campo nulo: se B e paralelo a area, o fluxo e zero.",
    "Esquecer a lei de Lenz: a corrente induzida se opoe a variacao.",
    "Usar c = lambda . f com unidades misturadas: c em m/s, lambda em m, f em Hz.",
    ],
    "referencias": [
    "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
    "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
    "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
    "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
    "NUSSENZVEIG, H. M. Curso de Fisica Basica. 4. ed. Sao Paulo: E. Blucher, 2002.",
    "FEYNMAN, R. P. Lectures on Physics: Eletromagnetismo. Sao Paulo: Bookman, 2008.",
    ],
}

IMG_ELETROMAGNETISMO = []

# ============================================================
# 3.11 Fisica Moderna
# ============================================================
FISICA_MODERNA = {
    "titulo": "Física Moderna",
    "disciplina": "Física",
    "topico": "Fisica Moderna",
    "subtopico": "Relatividade, quantica, atomo e nucleo",
    "introducao": (
    "A Fisica Moderna revolucionou nossa compreensao do universo "
        "no seculo XX. Ela inclui a teoria da relatividade, a "
        "mecanica quantica e o estudo do atomo e do nucleo."
    ),
    "secoes": [
        {
            "titulo": "1. Relatividade especial",
    "conteudo": (
                "A teoria da relatividade restrita, proposta por "
                "Einstein em 1905, baseia-se em dois postulados.\n\n"
                "POSTULADOS:\n"
                "1. As leis da Fisica sao as mesmas em todos os "
                "referenciais inerciais.\n"
                "2. A velocidade da luz no vacuo e constante, "
                "independente do movimento da fonte.\n\n"
                "DILATACAO DO TEMPO: relogios em movimento atrasam em "
                "relacao a um observador parado. Quanto maior a "
                "velocidade, mais lento o tempo.\n\n"
                "CONTRACAO DO ESPACO: comprimentos na direcao do "
                "movimento parecem menores para um observador externo.\n\n"
                "ENERGIA E MASSA: E = m . c^2. Massa e energia sao "
                "equivalentes."
            ),
            "exemplo": (
                "Medicina nuclear usa isotopos radioativos emitindo "
                "raios gama. A massa do nucleo antes e depois de uma "
                "reacao nuclear difere ligeiramente; essa diferenca "
                "e convertida em energia, conforme E = m . c^2. Em "
                "tratamentos com cobalto-60, a energia liberada "
                "destroi celulas tumorais."
            ),
        },
        {
            "titulo": "2. Mecanica quantica e atomo",
            "conteudo": (
                "LUZ: ONDA OU PARTICULA? A luz apresenta tanto "
                "comportamento ondulatorio (interferencia, difracao) "
                "quanto corpuscular (efeito fotoeletrico).\n\n"
                "EFEITO FOTOELETRICO: eletrons sao arrancados de um "
                "metal quando a luz incidente tem frequencia acima de "
                "um limiar. Cada foton transfere sua energia E = h . f "
                "para um eletron.\n\n"
                "EQUACAO DE PLANCK: E = h . f, onde h = 6,63 x 10^-34 "
                "J.s e a constante de Planck.\n\n"
                "MODELO ATOMICO DE BOHR: eletrons orbitam o nucleo em "
                "niveis de energia quantizados. Saltos entre niveis "
                "absorvem ou emitem fotons de energia bem definida."
            ),
            "exemplo": (
                "Tomografias por emissao de positrons (PET) usam "
                "radioisotopos que emitem positrons. Quando um "
                "positron encontra um eletron, aniquilam-se e "
                "emitem dois raios gama em sentidos opostos. O "
                "detector capta esses raios gama e reconstroi uma "
                "imagem do metabolismo celular, muito usada em "
                "oncologia."
            ),
        },
        {
            "titulo": "3. Radioatividade e fisica nuclear",
            "conteudo": (
                "RADIOATIVIDADE: emissao espontanea de particulas ou "
                "ondas pelo nucleo instavel.\n\n"
                "TIPOS DE RADIACAO:\n"
                "- Alfa (a): nucleo de helio (2 protons + 2 neutrons). "
                "Baixo poder de penetracao.\n"
                "- Beta (b): eletron ou positron emitido pelo nucleo. "
                "Penetracao media.\n"
                "- Gama (g): onda eletromagnetica de alta energia. "
                "Alta penetracao.\n\n"
                "MEIA-VIDA: tempo necessario para que metade dos "
                "nucleos de uma amostra se desintegre. Apos uma "
                "meia-vida, resta metade; apos duas, um quarto; apos "
                "tres, um oitavo, e assim por diante.\n\n"
                "Fissao e fusao: fissao e a ruptura de um nucleo "
                "pesado; fusao e a uniao de nucleos leves. Ambas "
                "liberam grande quantidade de energia."
            ),
            "exemplo": (
                "O iodo-131 e usado no diagnostico e tratamento de "
                "doencas da tireoide. E um emissor beta com meia-vida "
                "de cerca de 8 dias. O isotopo se concentra na "
                "tireoide e emite radiacao que destroi celulas "
                "hiperativas. A meia-vida curta reduz o tempo de "
                "exposicao do paciente, mas exige planejamento "
                "cuidadoso."
            ),
        },
    ],
    "resumo": (
        "- Relatividade: leis iguais em referenciais inerciais; c e constante.\n"
        "- Dilatacao do tempo e contracao do espaco para corpos em alta velocidade.\n"
        "- E = m . c^2.\n"
        "- Efeito fotoeletrico: E = h . f.\n"
        "- Modelo de Bohr: niveis quantizados e emissao/absorcao de fotons.\n"
        "- Radiacoes alfa, beta, gama. Meia-vida: metade da amostra decai no tempo dado.\n"
        "- Fissao e fusao liberam energia nuclear."
    ),
    "dicas": [
        "c = 3 x 10^8 m/s e constante no vacuo para todos os observadores.",
    "Efeitos relativisticos so sao notaveis em velocidades proximas a c.",
    "Foton e a 'particula' de luz. Energia do foton: E = h . f.",
    "Radiacao alfa e a menos penetrante; gama, a mais penetrante.",
    "Meia-vida e um conceito estatistico; nao se aplica a um unico atomo.",
    "Fissao: nucleo pesado se divide; fusao: nucleos leves se unem.",
    ],
    "pegadinhas": [
    "Achar que relatividade so afeta tempo e espaco em viagens cotidianas: so e relevante em velocidades muito altas.",
    "Confundir E = h . f com energia cinetica classica.",
    "Esquecer que emissor alfa e nucleo de helio com carga +2.",
    "Achar que meia-vida e o tempo para desaparecer completamente: e o tempo para cair pela metade.",
    "Confundir fissao e fusao: fissao e divisao; fusao e uniao.",
    "Esquecer que raios gama sao ondas eletromagneticas, nao particulas carregadas.",
    ],
    "referencias": [
    "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
    "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
    "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
    "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
    "EISBERG, R.; RESNICK, R. Fisica Quantica. Sao Paulo: Campus, 1985.",
    "TOWNSEND, J. S. Fisica Moderna. 2. ed. Porto Alegre: Bookman, 2010.",
    ],
}

IMG_FISICA_MODERNA = []

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (ELETRODINAMICA, "FI_ELETRODINAMICA.pdf", IMG_ELETRODINAMICA, "Fisica — Eletrodinamica"),
        (ELETROMAGNETISMO, "FI_ELETROMAGNETISMO.pdf", IMG_ELETROMAGNETISMO, "Fisica — Eletromagnetismo"),
        (FISICA_MODERNA, "FI_FISICA_MODERNA.pdf", IMG_FISICA_MODERNA, "Fisica — Fisica Moderna"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
