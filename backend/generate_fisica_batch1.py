"""Gera PDFs de Fisica — batch 1 (topicos 3.1 a 3.4)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 3.1 Grandezas e Unidades
# ============================================================
GRANDEZAS_UNIDADES = {
    "titulo": "Grandezas e Unidades",
    "disciplina": "Física",
    "topico": "Grandezas e Unidades",
    "subtopico": "Medicao, Sistema Internacional, notacao cientifica e ordem de grandeza",
    "introducao": (
        "A Fisica e uma ciencia experimental baseada na medicao de "
        "grandezas. Para que uma medida seja compreendida em qualquer "
        "lugar do mundo, usamos padroes internacionais de unidades, "
        "simbologia e escrita numerica."
    ),
    "secoes": [
        {
            "titulo": "1. Grandezas escalares e vetoriais",
            "conteudo": (
                "GRANDEZA: qualquer propriedade que pode ser medida. "
                "Para ser medida, a grandeza precisa de um numero e de "
                "uma unidade.\n\n"
                "GRANDEZA ESCALAR: basta um valor numerico e uma "
                "unidade. Exemplos: massa (5 kg), temperatura (25 oC), "
                "tempo (10 s), energia (100 J).\n\n"
                "GRANDEZA VETORIAL: alem do modulo, precisa de "
                "direcao e sentido. Exemplos: forca, velocidade, "
                "aceleracao, campo eletrico. Representamos vetores por "
                "setas; o comprimento da seta indica o modulo e a "
                "ponta indica o sentido.\n\n"
                "MEDIDA DIRETA: compara a grandeza com um padrao. "
                "Exemplo: medir o comprimento de uma mesa com uma "
                "regua.\n\n"
                "MEDIDA INDIRETA: obtida por calculo. Exemplo: "
                "calcular a velocidade dividindo espaco pelo tempo."
            ),
            "exemplo": (
                "Na medicina, muitas grandezas sao escalares com unidades "
                "bem definidas: pressao arterial (mmHg), glicemia "
                "(mg/dL), frequencia cardiaca (batimentos por minuto). "
                "Ja a forca muscular aplicada em uma contracao e uma "
                "grandeza vetorial, pois depende de quanto a forca e "
                "intensa (modulo), para onde aponta (direcao) e se "
                "puxa ou empurra (sentido)."
            ),
        },
        {
            "titulo": "2. Sistema Internacional de Unidades (SI)",
            "conteudo": (
                "O SI e composto por sete unidades fundamentais, a partir "
                "das quais todas as outras unidades derivam.\n\n"
                "UNIDADES FUNDAMENTAIS:\n"
                "- metro (m) - comprimento\n"
                "- quilograma (kg) - massa\n"
                "- segundo (s) - tempo\n"
                "- ampere (A) - corrente eletrica\n"
                "- kelvin (K) - temperatura termodinamica\n"
                "- mol (mol) - quantidade de materia\n"
                "- candela (cd) - intensidade luminosa\n\n"
                "UNIDADES DERIVADAS COMUNS:\n"
                "- metro por segundo (m/s) - velocidade\n"
                "- metro por segundo ao quadrado (m/s^2) - aceleracao\n"
                "- newton (N = kg.m/s^2) - forca\n"
                "- pascal (Pa = N/m^2) - pressao\n"
                "- joule (J = N.m) - energia\n"
                "- watt (W = J/s) - potencia\n\n"
                "PREFIXOS:\n"
                "k (quilo) = 10^3; c (centi) = 10^-2; m (mili) = 10^-3; "
                "micro = 10^-6; n (nano) = 10^-9."
            ),
            "exemplo": (
                "Uma aspirina de 500 mg contem 500 x 10^-3 g = 0,5 g de "
                "substancia ativa. Uma gota de soro fisiologico de 1 "
                "mL e a mesma coisa que 1 x 10^-3 L ou 1 cm^3. No "
                "exame de sangue, o resultado de glicose em 90 mg/dL "
                "significa 90 miligramas por decilitro."
            ),
        },
        {
            "titulo": "3. Notacao cientifica e ordem de grandeza",
            "conteudo": (
                "NOTACAO CIENTIFICA: maneira de escrever numeros muito "
                "grandes ou muito pequenos usando potencias de 10. "
                "Forma: N = M x 10^n, onde 1 <= M < 10.\n\n"
                "EXEMPLOS:\n"
                "- 6500000 m = 6,5 x 10^6 m\n"
                "- 0,0000034 m = 3,4 x 10^-6 m = 3,4 micrometros\n"
                "- 9800000000 = 9,8 x 10^9\n\n"
                "OPERACOES:\n"
                "- Multiplicacao: (a x 10^m) . (b x 10^n) = "
                "(a.b) x 10^(m+n)\n"
                "- Divisao: (a x 10^m) / (b x 10^n) = (a/b) x 10^(m-n)\n"
                "- Soma/subtracao: iguala os exponentes antes de somar.\n\n"
                "ORDEM DE GRANDEZA: potencia de 10 mais proxima do "
                "numero. Exemplo: 8 x 10^4 tem ordem de grandeza 10^5; "
                "2 x 10^4 tem ordem 10^4."
            ),
            "exemplo": (
                "A densidade de um virus e da ordem de 10^-15 kg, ja a "
                "massa de um coracao humano e da ordem de 10^-1 kg. O "
                "numero de celulas no corpo humano e da ordem de 10^13. "
                "A ordem de grandeza ajuda a comparar sem precisar de "
                "valores exatos, o que e muito util em estimativas "
                "medicas."
            ),
        },
    ],
    "resumo": (
        "- Grandeza escalar: apenas modulo e unidade. Grandeza vetorial: modulo, direcao e sentido.\n"
        "- Sete unidades fundamentais do SI: m, kg, s, A, K, mol, cd.\n"
        "- Unidades derivadas: m/s, m/s^2, N, Pa, J, W.\n"
        "- Notacao cientifica: M x 10^n, com 1 <= M < 10.\n"
        "- Ordens de grandeza: aproximacao pela potencia de 10 mais proxima.\n"
        "- Prefixos: k, c, m, micro, n."
    ),
    "dicas": [
        "Sempre escreva a unidade junto com o numero; nunca deixe so o numero.",
        "Quando somar ou subtrair medidas, as unidades devem ser iguais.",
        "Use a virgula no padrao brasileiro: 1,5 kg, nao 1.5 kg, em textos (mas 1.5 em formulas).",
        "Para notacao cientifica, a parte decimal deve ficar entre 1 e 10.",
        "Ordem de grandeza: se o multiplicador for maior ou igual a raiz de 10 (~3,16), arredonde para cima.",
        "Velocidade em m/s; para converter de km/h para m/s, divida por 3,6.",
    ],
    "pegadinhas": [
        "Confundir km/h com m/s: 36 km/h = 10 m/s (dividir por 3,6).",
        "Esquecer que km e maior que m: 1 km = 1000 m, entao 1 km/h = 1/3,6 m/s.",
        "Achar que 0,002 m e 2 mm: 0,002 m = 2 x 10^-3 m = 2 mm; 0,002 m = 2 mm. Correto.",
        "Escrever 5,6 x 10^3 como 56 x 10^2; a primeira e notacao cientifica, a segunda nao.",
        "Confundir celsius com kelvin: K = oC + 273; variacao em K e igual a variacao em oC.",
        "Esquecer que no SI a massa e em kg, nao em gramas.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "Bureau International des Poids et Mesures. Le Systeme International d'Unites (SI), 9. ed. 2019.",
        "INMETRO. O Sistema Internacional de Unidades - SI. Rio de Janeiro: INMETRO, 2020.",
    ],
}

IMG_GRANDEZAS = [{"file": "fi_grandezas.png", "caption": "Tabela das unidades fundamentais do Sistema Internacional", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.2 Cinematica
# ============================================================
CINEMATICA = {
    "titulo": "Cinemática",
    "disciplina": "Física",
    "topico": "Cinemática",
    "subtopico": "Movimento, velocidade, aceleracao e graficos",
    "introducao": (
        "A Cinematica e a parte da Fisica que estuda o movimento "
        "dos corpos sem se preocupar com as causas desse movimento. "
        "Ela descreve onde o corpo esta, para onde vai e com que "
        "velocidade."
    ),
    "secoes": [
        {
            "titulo": "1. Conceitos basicos do movimento",
            "conteudo": (
                "REFERENCIAL: corpo ou ponto em relacao ao qual "
                "analisamos o movimento. Um passageiro dentro de um "
                "onibus esta parado em relacao ao onibus, mas em "
                "movimento em relacao a rua.\n\n"
                "POSICAO (s ou x): local do movel em relacao ao "
                "referencial. Pode ser positiva ou negativa.\n\n"
                "DESLOCAMENTO (Delta s): variacao da posicao, "
                "s_final - s_inicial. E uma grandeza vetorial.\n\n"
                "ESPACO PERCORRIDO: soma dos modulos dos "
                "deslocamentos, sempre positivo. Quando um carro "
                "vai e volta, o espaco percorrido e maior que o "
                "deslocamento.\n\n"
                "TRAJETORIA: linha descrita pelo movel. Pode ser "
                "retilinea, curvilinea ou circular."
            ),
            "exemplo": (
                "Uma ambulancia sai do hospital, percorre 6 km ate um "
                "acidente e retorna com o paciente por 6 km. O "
                "espaco percorrido e 12 km, mas o deslocamento "
                "resultante e zero, pois ela voltou ao ponto de "
                "partida. A posicao final e igual a inicial, apesar "
                "do carro ter andado bastante."
            ),
        },
        {
            "titulo": "2. Velocidade e aceleracao",
            "conteudo": (
                "VELOCIDADE MEDIA: v_m = Delta s / Delta t. E a "
                "razao entre deslocamento e intervalo de tempo. No SI, "
                "m/s.\n\n"
                "VELOCIDADE INSTANTANEA: a velocidade num instante "
                "bem pequeno, dada pela derivada do espaco em relacao "
                "ao tempo. No grafico s x t, e o coeficiente angular "
                "da reta tangente.\n\n"
                "ACELERACAO MEDIA: a_m = Delta v / Delta t. Mede a "
                "rapidez com que a velocidade muda. No SI, m/s^2.\n\n"
                "ACELERACAO INSTANTANEA: a = dv/dt. E a derivada da "
                "velocidade em relacao ao tempo. No grafico v x t, e "
                "o coeficiente angular da reta."
            ),
            "exemplo": (
                "Um trote de 10 s no eletrocardiograma mostra ondas P, "
                "QRS e T. A velocidade de propagacao do impulso "
                "eletrico no coracao nao e uniforme: acelera nas "
                "vias especiais e desacelera nos musculos. A "
                "aceleracao e essencial para entender arritmias e "
                "fibrilacao, onde a velocidade de propagacao se "
                "altera anormalmente."
            ),
        },
        {
            "titulo": "3. Movimento uniforme (MU) e uniformemente variado (MUV)",
            "conteudo": (
                "MOVIMENTO UNIFORME: velocidade constante; aceleracao "
                "nula.\n"
                "Equacao: s = s0 + v.t\n"
                "Grafico s x t: reta inclinada. Grafico v x t: reta "
                "horizontal. A area sob o grafico v x t e o "
                "deslocamento.\n\n"
                "MOVIMENTO UNIFORMEMENTE VARIADO: aceleracao constante "
                "e diferente de zero.\n"
                "Equacoes:\n"
                "- v = v0 + a.t\n"
                "- s = s0 + v0.t + (a.t^2)/2\n"
                "- v^2 = v0^2 + 2.a.Delta s\n\n"
                "Grafico v x t do MUV: reta inclinada. A area sob a "
                "reta entre dois instantes e o deslocamento."
            ),
            "exemplo": (
                "Na queda livre, um corpo solto de uma altura pequena "
                "tem aceleracao constante g = 9,8 m/s^2, aproximadamente "
                "10 m/s^2. Em 2 segundos, a velocidade passa de 0 para "
                "20 m/s para baixo. A altura caida e "
                "s = (10 . 2^2)/2 = 20 m. Esse calculo e essencial "
                "para entender traumas por queda e para projetar "
                "equipamentos de reabilitacao."
            ),
        },
    ],
    "resumo": (
        "- Referencial: ponto adotado para definir posicao.\n"
        "- Deslocamento e variacao de posicao; espaco e o total andado.\n"
        "- v_m = Delta s / Delta t; a_m = Delta v / Delta t.\n"
        "- MU: s = s0 + v.t, aceleracao nula.\n"
        "- MUV: v = v0 + a.t; s = s0 + v0.t + (a.t^2)/2; v^2 = v0^2 + 2.a.Delta s.\n"
        "- Area sob v x t = deslocamento. Coeficiente angular de v x t = aceleracao."
    ),
    "dicas": [
        "No MU, a velocidade media e igual a velocidade em qualquer instante.",
        "No MUV, a aceleracao e constante, entao a velocidade muda linearmente.",
        "Converta sempre km/h para m/s dividindo por 3,6.",
        "No grafico s x t, a inclinacao da reta e a velocidade.",
        "No grafico v x t, a inclinacao e a aceleracao e a area e o deslocamento.",
        "Queda livre e um MUV com aceleracao g, orientada para baixo.",
    ],
    "pegadinhas": [
        "Achar que velocidade e aceleracao sao iguais: corpo pode ter alta velocidade e aceleracao zero.",
        "Esquecer que Delta e sempre final menos inicial.",
        "Confundir deslocamento com espaco percorrido: se o corpo volta, sao diferentes.",
        "Achar que aceleracao negativa significa retardo: depende do sentido adotado.",
        "Esquecer de colocar sinais nas posicoes: a escolha do referencial define o sinal.",
        "Usar g = 10 m/s^2 sem verificar se a questao pede 9,8.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "PARAN, D. Fisica. 6. ed. Sao Paulo: Atual, 1996.",
        "BONJORNO, J. R.; BONJORNO, R. S.; RAMOS, C. M. Fisica para o Ensino Médio. Sao Paulo: FTD, 1999.",
    ],
}

IMG_CINEMATICA = [{"file": "fi_cinematica.png", "caption": "Grafico s x t de movimento uniforme: a inclinacao da reta e a velocidade", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.3 Dinamica
# ============================================================
DINAMICA = {
    "titulo": "Dinâmica",
    "disciplina": "Física",
    "topico": "Dinâmica",
    "subtopico": "Leis de Newton, forca, inercia e atrito",
    "introducao": (
        "A Dinamica estuda as causas do movimento. A grandeza "
        "responsavel por alterar o estado de movimento ou de repouso "
        "de um corpo e a forca. As tres leis de Newton sao a base "
        "para entender essas relacoes."
    ),
    "secoes": [
        {
            "titulo": "1. Primeira Lei de Newton (Inercia)",
            "conteudo": (
                "PRIMEIRA LEI DE NEWTON: todo corpo permanece em seu "
                "estado de repouso ou de movimento retilineo uniforme, "
                "a menos que uma forca resultante o obrigue a mudar de "
                "estado.\n\n"
                "INERCIA: tendencia dos corpos de manter seu estado de "
                "movimento. Quanto maior a massa, maior a inercia. "
                "Isso explica por que e mais dificil parar um onibus "
                "do que uma bicicleta.\n\n"
                "APLICACOES: cinto de seguranca, cabecalho no "
                "carro, estabilidade de equipamentos medicos em "
                "ambulancias."
            ),
            "exemplo": (
                "Em uma parada brusca, o cerebro continua se movendo "
                "para a frente dentro do cranio por inercia. Esse "
                "movimento relativo e a causa de concussao e traumas "
                "encefalicos em acidentes. O cinto de seguranca e "
                "os airbags aplicam forcas de frenagem no corpo de "
                "forma mais gradual, reduzindo o impacto no cerebro."
            ),
        },
        {
            "titulo": "2. Segunda Lei de Newton (Forca resultante)",
            "conteudo": (
                "SEGUNDA LEI DE NEWTON: a forca resultante aplicada a "
                "um corpo e igual ao produto da massa pela "
                "aceleracao.\n\n"
                "Fr = m.a\n\n"
                "A forca resultante e a soma vetorial de todas as "
                "forcas que atuam no corpo. Se Fr = 0, a aceleracao "
                "e zero.\n\n"
                "UNIDADE: newton (N), onde 1 N = 1 kg.m/s^2.\n\n"
                "O sentido da aceleracao e o mesmo da forca "
                "resultante. A massa e a medida da inercia do corpo."
            ),
            "exemplo": (
                "No coracao, o sangue e acelerado quando bombeado para "
                "a aorta. Se 70 g de sangue recebem uma forca de "
                "0,7 N, a aceleracao e a = F/m = 0,7/0,070 = 10 m/s^2. "
                "Em condicoes patologicas, como estenose aortica, a "
                "forca do coracao aumenta para vencer a resistencia, "
                "o que pode levar a hipertrofia do ventriculo esquerdo."
            ),
        },
        {
            "titulo": "3. Terceira Lei de Newton (Acao e reacao) e atrito",
            "conteudo": (
                "TERCEIRA LEI DE NEWTON: a toda acao corresponde uma "
                "reacao, de mesma intensidade e direcao, mas sentido "
                "oposto. As forcas de acao e reacao atuam em corpos "
                "diferentes.\n\n"
                "ATRITO: forca que se opoe ao movimento relativo entre "
                "duas superficies. Depende das superficies em contato "
                "e da forca normal.\n\n"
                "TIPOS DE ATRITO:\n"
                "- Estatico: atua quando as superficies tendem a se "
                "mover, mas ainda nao se movem. f_max = microe . N.\n"
                "- Cinetico: atua durante o movimento. f_c = microc . N.\n\n"
                "PLANO INCLINADO: o peso se decompoe em duas "
                "componentes: P. cos alfa (perpendicular) e "
                "P. sen alfa (paralela ao plano)."
            ),
            "exemplo": (
                "A marcha humana depende do atrito com o solo. Sem "
                "atrito (como em gelo), nao conseguimos empurrar o "
                "chao para a frente; o chao empurra nossos pes para "
                "tras e nos andamos para a frente (terceira lei). "
                "Em pacientes com mobilidade reduzida, calcados "
                "antideslizantes aumentam o atrito e reduzem quedas."
            ),
        },
    ],
    "resumo": (
        "- 1a Lei (Inercia): corpo mantem estado sem forca resultante.\n"
        "- 2a Lei: Fr = m.a. Forca resultante gera aceleracao.\n"
        "- 3a Lei: acao e reacao sao forcas iguais, opostas, em corpos diferentes.\n"
        "- Atrito estatico: opoe a tendencia de movimento. Atrito cinetico: opoe o movimento.\n"
        "- Peso = m.g; normal e a forca perpendicular a superficie.\n"
        "- Plano inclinado: P.cos alfa e P.sen alfa."
    ),
    "dicas": [
        "Fr e a soma vetorial de todas as forcas. Somente ela entra na 2a lei.",
        "A terceira lei nao anula a acao: as forcas atuam em corpos diferentes.",
        "A normal nao e sempre igual ao peso: em planos inclinados ou com forcas adicionais, muda.",
        "Atrito estatico pode variar ate o maximo; so iguala a forca que puxa ate atingir o limite.",
        "Em plano inclinado sem atrito, a = g.sen alfa.",
        "Use diagrama do corpo livre para nao esquecer nenhuma forca.",
    ],
    "pegadinhas": [
        "Achar que acao e reacao se anulam porque sao iguais e opostas: atuam em corpos diferentes.",
        "Confundir peso e massa: peso e forca (N); massa e quantidade de materia (kg).",
        "Usar a forca aplicada em vez da forca resultante na 2a lei.",
        "Esquecer de decompor o peso no plano inclinado.",
        "Achar que a normal e sempre igual ao peso: em elevadores acelerados, muda.",
        "Confundir microe (coeficiente estatico) com microc (cinetico): estatico e maior.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "PARAN, D. Fisica. 6. ed. Sao Paulo: Atual, 1996.",
        "BONJORNO, J. R.; BONJORNO, R. S.; RAMOS, C. M. Fisica para o Ensino Médio. Sao Paulo: FTD, 1999.",
    ],
}

IMG_DINAMICA = [{"file": "fi_dinamica.png", "caption": "Diagrama de forcas em um bloco sobre plano inclinado", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.4 Hidrostatica
# ============================================================
HIDROSTATICA = {
    "titulo": "Hidrostática",
    "disciplina": "Física",
    "topico": "Hidrostática",
    "subtopico": "Pressao, densidade, empuxo e vasos comunicantes",
    "introducao": (
        "A Hidrostatica estuda os liquidos em equilibrio, isto e, "
        "sem movimento. E fundamental para entender pressao "
        "arterial, funcionamento do sangue, balanca hidraulica e "
        "equipamentos medicos."
    ),
    "secoes": [
        {
            "titulo": "1. Pressao, densidade e massa especifica",
            "conteudo": (
                "PRESSAO: forca aplicada perpendicularmente por unidade "
                "de area. p = F/A. No SI, pascal (Pa = N/m^2). Outras "
                "unidades comuns: atm, mmHg, cmH2O.\n\n"
                "DENSIDADE: razao entre a massa e o volume. d = m/V. "
                "No SI, kg/m^3. Tambem usamos g/cm^3.\n\n"
                "MASSA ESPECIFICA: similar a densidade, mas medida no "
                "mesmo local e temperatura. Na pratica, sao "
                "consideradas iguais.\n\n"
                "PRESSAO HIDROSTATICA: pressao devida a coluna de "
                "liquido. p = p0 + d.g.h, onde p0 e a pressao na "
                "superficie, d a densidade, g a gravidade e h a "
                "profundidade."
            ),
            "exemplo": (
                "A pressao sanguinea de 120/80 mmHg significa que a "
                "sistole gera uma coluna de mercurio de 120 mm e a "
                "diastole de 80 mm. Convertendo para pascal: "
                "120 mmHg = 120 x 133,3 = 15996 Pa. A pressao "
                "sanguinea depende da profundidade: nas pernas, a "
                "pressao hidrostatica do sangue e maior que na cabeca, "
                "devido a coluna de sangue acima."
            ),
        },
        {
            "titulo": "2. Vasos comunicantes e teorema de Stevin",
            "conteudo": (
                "TEOREMA DE STEVIN: a diferenca de pressao entre dois "
                "pontos de um liquido em equilibrio e d = d.g.h, onde "
                "h e a diferenca de altura.\n\n"
                "VASOS COMUNICANTES: se contem o mesmo liquido, o "
                "nivel se iguala em todos os ramos, independentemente "
                "do formato. Se contem liquidos imisceis diferentes, "
                "os produtos d.h sao iguais.\n\n"
                "PRINCIPIO DE PASCAL: a pressao aplicada a um liquido "
                "confinado se transmite integralmente a todos os "
                "pontos do liquido.\n\n"
                "APLICACOES: freio hidraulico, macaco hidraulico, "
                "elevadores, soro hospitalar."
            ),
            "exemplo": (
                "O macaco hidraulico aplica o principio de Pascal: "
                "uma forca pequena F1 em uma pequena area A1 gera uma "
                "pressao p, que se transmite para uma area maior A2, "
                "produzindo uma forca maior F2. Em cadeiras odontologicas "
                "e macas, sistemas hidraulicos permitem levantar "
                "pacientes com pouca forca."
            ),
        },
        {
            "titulo": "3. Empuxo e principio de Arquimedes",
            "conteudo": (
                "EMPUXO: forca vertical de baixo para cima que um "
                "fluido exerce sobre um corpo mergulhado. "
                "E = d_liquido . g . V_submerso.\n\n"
                "PRINCIPIO DE ARQUIMEDES: todo corpo mergulhado em um "
                "fluido sofre um empuxo igual ao peso do fluido "
                "deslocado.\n\n"
                "CONDICOES DE FLOTUACAO:\n"
                "- d_corpo < d_liquido: corpo flutua\n"
                "- d_corpo = d_liquido: corpo fica em equilibrio\n"
                "- d_corpo > d_liquido: corpo afunda\n\n"
                "APARENTAMENTE MENOS PESADO: no fluido, o peso "
                "aparente e P - E."
            ),
            "exemplo": (
                "O corpo humano praticamente flutua na agua porque a "
                "densidade media do corpo (cerca de 1,07 g/cm^3) e "
                "proxima da agua. Apos uma expiracao, afundamos; apos "
                "uma inspiracao, flutuamos. Em fisioterapia, a "
                "hidroterapia aproveita o empuxo para reduzir o peso "
                "aparente das articulacoes durante a reabilitacao."
            ),
        },
    ],
    "resumo": (
        "- Pressao: p = F/A; SI: pascal (Pa).\n"
        "- Densidade: d = m/V.\n"
        "- Pressao hidrostatica: p = p0 + d.g.h.\n"
        "- Vasos comunicantes: niveis se igualam com o mesmo liquido.\n"
        "- Principio de Pascal: pressao se transmite integralmente.\n"
        "- Empuxo: E = d_fluido . g . V_submerso (Arquimedes).\n"
        "- Corpo flutua se densidade menor que a do liquido."
    ),
    "dicas": [
        "1 atm = 101325 Pa = 760 mmHg = 1033 cmH2O.",
        "Pressao hidrostatica so depende da altura, densidade e gravidade, nao do formato do recipiente.",
        "No macaco hidraulico, F2/F1 = A2/A1.",
        "Empuxo depende do volume submerso, nao do volume total do corpo.",
        "Densidade do sangue e cerca de 1,06 g/cm^3, ligeiramente acima da agua.",
        "1 mmHg = 133,3 Pa; 1 cmH2O = 98,1 Pa.",
    ],
    "pegadinhas": [
        "Achar que pressao depende da area total do recipiente: depende da altura e densidade.",
        "Confundir densidade do corpo com densidade do liquido no empuxo.",
        "Esquecer que V_submerso e o volume mergulhado, nao o volume total.",
        "Usar massa em vez de volume para calcular empuxo.",
        "Achar que o formato do vaso comunicante altera o nivel: o nivel e o mesmo.",
        "Esquecer de converter mmHg para Pa quando a questao pede SI.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "PARAN, D. Fisica. 6. ed. Sao Paulo: Atual, 1996.",
        "BONJORNO, J. R.; BONJORNO, R. S.; RAMOS, C. M. Fisica para o Ensino Médio. Sao Paulo: FTD, 1999.",
    ],
}

IMG_HIDROSTATICA = [{"file": "fi_hidrostatica.png", "caption": "Pressao hidrostatica aumenta com a profundidade", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (GRANDEZAS_UNIDADES, "FI_GRANDEZAS_UNIDADES.pdf", IMG_GRANDEZAS, "Fisica — Grandezas e Unidades"),
        (CINEMATICA, "FI_CINEMATICA.pdf", IMG_CINEMATICA, "Fisica — Cinematica"),
        (DINAMICA, "FI_DINAMICA.pdf", IMG_DINAMICA, "Fisica — Dinamica"),
        (HIDROSTATICA, "FI_HIDROSTATICA.pdf", IMG_HIDROSTATICA, "Fisica — Hidrostatica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
