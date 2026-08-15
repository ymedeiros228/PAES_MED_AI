# -*- coding: utf-8 -*-
"""Gera PDFs de Fisica — batch 2 (topicos 3.5 a 3.8)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 3.5 Termologia
# ============================================================
TERMOLOGIA = {
    "titulo": "Termologia",
    "disciplina": "Física",
    "topico": "Termologia",
    "subtopico": "Calor, temperatura, dilatacao e gases",
    "introducao": (
        "A Termologia estuda os fenomenos relacionados ao calor e "
        "a temperatura. Esses conceitos sao essenciais para entender "
        "o funcionamento do corpo humano, de equipamentos medicos e "
        "processos industriais."
    ),
    "secoes": [
        {
            "titulo": "1. Temperatura e escalas termometricas",
            "conteudo": (
                "TEMPERATURA: medida do grau de agitacao das "
                "moleculas. Quanto maior a temperatura, maior a "
                "agitacao.\n\n"
                "CALOR: energia em transito entre corpos de "
                "temperaturas diferentes. O calor flui do corpo mais "
                "quente para o mais frio ate o equilibrio termico.\n\n"
                "ESCALAS TERMOMETRICAS:\n"
                "- Celsius (oC): ponto de fusao da agua = 0 oC; "
                "ebulicao = 100 oC (a 1 atm).\n"
                "- Fahrenheit (oF): fusao = 32 oF; ebulicao = 212 oF.\n"
                "- Kelvin (K): escala absoluta; 0 K = -273 oC. "
                "Fusao = 273 K; ebulicao = 373 K.\n\n"
                "CONVERSOES:\n"
                "- oC para oF: oF = 1,8 . oC + 32\n"
                "- oC para K: K = oC + 273\n"
                "- Variacoes: 1 oC = 1 K; 1 oC = 1,8 oF"
            ),
            "exemplo": (
                "A febre e um aumento da temperatura corporal, geralmente "
                "acima de 37,5 oC. Uma temperatura de 40 oC equivale "
                "a 104 oF e 313 K. A hipotermia ocorre abaixo de "
                "35 oC. Termometros medicos usam escala Celsius, mas "
                "equipamentos de pesquisa frequentemente usam Kelvin "
                "por ser uma escala absoluta."
            ),
        },
        {
            "titulo": "2. Dilatacao termica",
            "conteudo": (
                "DILATACAO: aumento de volume de um corpo quando "
                "sua temperatura aumenta. Ocorre porque as moleculas "
                "passam a vibrar mais e ocupam mais espaco.\n\n"
                "DILATACAO LINEAR: variacao no comprimento. "
                "Delta L = L0 . alfa . Delta T, onde alfa e o "
                "coeficiente de dilatacao linear.\n\n"
                "DILATACAO SUPERFICIAL: variacao na area. "
                "Delta A = A0 . 2 alfa . Delta T.\n\n"
                "DILATACAO VOLUMETRICA: variacao no volume. "
                "Delta V = V0 . gama . Delta T, com gama = 3 alfa "
                "(para solidos isotropos). Para liquidos, gama varia.\n\n"
                "DILATACAO ANOMALA DA AGUA: entre 0 oC e 4 oC, a "
                "agua contrai ao aquecer. Por isso, a agua tem "
                "densidade maxima a 4 oC."
            ),
            "exemplo": (
                "Em ortopedia, hastes metalicas sao usadas para fixar "
                "fraturas. Se o coeficiente de dilatacao do metal for "
                "muito diferente do osso, variacoes de temperatura "
                "corporaria podem gerar tensoes. O titanio e o "
                "aco inoxidavel sao escolhidos por terem coeficientes "
                "de dilatacao proximos do osso, evitando problemas."
            ),
        },
        {
            "titulo": "3. Calorimetria e mudancas de fase",
            "conteudo": (
                "CAPACIDADE TERMICA (C): quantidade de calor necessaria "
                "para elevar a temperatura de um corpo em 1 oC. "
                "C = Q / Delta T. Unidade: J/oC ou cal/oC.\n\n"
                "CALOR ESPECIFICO (c): calor por unidade de massa para "
                "elevar 1 oC. c = Q / (m . Delta T). Unidade: "
                "J/(kg.oC) ou cal/(g.oC).\n\n"
                "CALOR SENSIVEL: altera a temperatura sem mudar de fase. "
                "Q = m . c . Delta T.\n\n"
                "CALOR LATENTE: altera a fase sem mudar a temperatura. "
                "Q = m . L, onde L e o calor latente de fusao ou "
                "vaporizacao.\n\n"
                "EQUILIBRIO TERMICO: em um sistema isolado, o calor "
                "cedido pelos corpos quentes e igual ao calor "
                "recebido pelos corpos frios: Qcedido = Qrecebido."
            ),
            "exemplo": (
                "Gelo e usado para reduzir edemas e inflamacoes. Para "
                "derreter 50 g de gelo a 0 oC, e necessario "
                "Q = m . L_fusao = 50 g . 80 cal/g = 4000 cal. "
                "O calor e retirado do tecido, diminuindo a "
                "temperatura local e a inflamacao. Compressas mornas "
                "fazem o contrario: cedem calor e relaxam musculos."
            ),
        },
    ],
    "resumo": (
        "- Temperatura: agitacao molecular. Calor: energia em transito.\n"
        "- Escalas: Celsius, Fahrenheit, Kelvin. K = oC + 273.\n"
        "- Dilatacao: Delta L = L0.alfa.Delta T; Delta V = V0.gama.Delta T.\n"
        "- Agua anomala: densidade maxima a 4 oC.\n"
        "- Calor sensivel: Q = m.c.Delta T. Calor latente: Q = m.L.\n"
        "- Equilibrio termico: Qcedido = Qrecebido."
    ),
    "dicas": [
        "1 cal = 4,186 J. 1 kcal = 1000 cal.",
        "Para variacao de temperatura, 1 oC = 1 K; para conversao, K = oC + 273.",
        "Calor latente nao muda a temperatura; calor sensivel muda.",
        "Dilatacao volumetrica de solidos: gama = 3.alfa.",
        "Agua entre 0 e 4 oC diminui de volume ao aquecer; acima de 4 oC, dilata normalmente.",
        "Troca termica sem perdas: Qcedido = Qrecebido.",
    ],
    "pegadinhas": [
        "Confundir calor com temperatura: calor e energia, temperatura e agitacao.",
        "Esquecer que, para variacao, oC e K tem o mesmo tamanho.",
        "Achar que calor latente muda temperatura: nao muda.",
        "Esquecer a anomalia da agua entre 0 e 4 oC.",
        "Confundir calor especifico com capacidade termica: capacidade depende da massa.",
        "Converter 0 oC para K e esquecer de somar 273.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "CALLEN, H. B. Termodinamica e uma Introducao a Mecanica Estatistica. Sao Paulo: E. Blucher, 2011.",
        "ZEMANSKY, M. W.; DITTMAN, R. H. Calor e Termodinamica. Sao Paulo: E. Blucher, 2010.",
    ],
}

IMG_TERMOLOGIA = [{"file": "fi_termologia.png", "caption": "Escalas termometricas: Celsius, Fahrenheit e Kelvin", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.6 Optica Geometrica
# ============================================================
OPTICA = {
    "titulo": "Óptica Geométrica",
    "disciplina": "Física",
    "topico": "Óptica Geométrica",
    "subtopico": "Luz, reflexao, refracao, espelhos e lentes",
    "introducao": (
        "A Optica Geometrica estuda a propagacao da luz usando "
        "raios. E baseada em principios simples: a luz se propaga "
        "em linha reta em meios homogeneos e sofre reflexao e "
        "refracao nas mudancas de meio."
    ),
    "secoes": [
        {
            "titulo": "1. Principios da optica e reflexao",
            "conteudo": (
                "RAIO DE LUZ: linha orientada que representa a "
                "trajetoria da luz. Feixe de raios paralelos e um "
                "feixe em que os raios nao se cruzam.\n\n"
                "FONTES DE LUZ: primarias (emitem luz, como o Sol) "
                "e secundarias (refletem luz, como a Lua).\n\n"
                "VELOCIDADE DA LUZ: no vacuo, cerca de "
                "3 x 10^8 m/s. Na agua e no vidro e menor.\n\n"
                "REFLEXAO: o raio incidente, o raio refletido e a "
                "normal estao no mesmo plano. O angulo de incidencia "
                "e igual ao angulo de reflexao.\n\n"
                "ESPELHOS PLANOS: imagem virtual, direita, de mesmo "
                "tamanho e simetrica ao objeto em relacao ao espelho."
            ),
            "exemplo": (
                "O oftalmoscopio utiliza reflexao de luz para iluminar "
                "o fundo do olho. Espelhos e prismas direcionam a luz "
                "para dentro do olho e o medico observa a retina. O "
                "conhecimento da reflexao e essencial para entender "
                "como os instrumentos opticos funcionam sem causar "
                "dano a cornea."
            ),
        },
        {
            "titulo": "2. Refracao e indice de refracao",
            "conteudo": (
                "REFRACAO: mudanca de direcao de um raio de luz ao "
                "passar de um meio para outro. Ocorre porque a "
                "velocidade da luz muda.\n\n"
                "INDICE DE REFRACAO (n): n = c/v, onde c e a "
                "velocidade no vacuo e v a velocidade no meio. Quanto "
                "maior o n, mais devagar a luz se propaga.\n\n"
                "LEI DE SNELL: n1 . sen teta1 = n2 . sen teta2.\n\n"
                "ANGULO LIMITE: quando a luz passa de meio mais "
                "refringente para menos refringente, existe um angulo "
                "maximo para o qual ainda ocorre refracao. Acima "
                "desse angulo ocorre reflexao total.\n\n"
                "DISPERSAO DA LUZ: separacao das cores ao passar por "
                "um prisma, pois cada cor tem um indice de refracao "
                "ligeiramente diferente."
            ),
            "exemplo": (
                "A refração e responsavel pela miopia e hipermetropia. "
                "No olho humano, a cornea e o cristalino refracam a "
                "luz para focar na retina. Na miopia, o foco fica "
                "antes da retina; oculos com lentes divergentes "
                "corrigem a curvatura. Na hipermetropia, o foco "
                "ficaria atras; lentes convergentes ajudam."
            ),
        },
        {
            "titulo": "3. Espelhos esfericos e lentes",
            "conteudo": (
                "ESPELHOS ESFERICOS: concavos e convexos. Regioes "
                "principais: centro de curvatura (C), vertice (V) e "
                "foco (F). Distancia focal f = R/2.\n\n"
                "EQUACAO DOS ESPelhos: 1/f = 1/p + 1/p', onde p e a "
                "distancia objeto e p' a distancia imagem.\n\n"
                "AUMENTO LINEAR (A): A = - p'/p. Se A > 0, imagem "
                "direita; se A < 0, invertida.\n\n"
                "LENTES ESFERICAS: convergentes (biconvexas) e "
                "divergentes (biconcavas). A equacao das lentes "
                "e a mesma: 1/f = 1/p + 1/p'.\n\n"
                "VERGENCIA (V): V = 1/f, medida em dioptrias (D). "
                "Usada em receitas de oculos."
            ),
            "exemplo": (
                "Um oftalmologista prescreve oculos de +2,0 D para "
                "hipermetropia. A distancia focal da lente e "
                "f = 1/V = 1/2 = 0,5 m = 50 cm. Lentes convergentes "
                "sao usadas para corrigir a dificuldade de focar "
                "objetos proximos, comum na presbiopia. A medida em "
                "dioptrias e a vergencia, diretamente relacionada a "
                "curvatura da lente."
            ),
        },
    ],
    "resumo": (
        "- Raio de luz: trajetoria da luz. Velocidade no vacuo: 3 x 10^8 m/s.\n"
        "- Reflexao: angulo de incidencia = angulo de reflexao.\n"
        "- Refracao: n1.sen teta1 = n2.sen teta2. Indice n = c/v.\n"
        "- Espelhos e lentes: 1/f = 1/p + 1/p'.\n"
        "- Aumento: A = -p'/p.\n"
        "- Vergencia: V = 1/f, em dioptrias."
    ),
    "dicas": [
        "Angulo de incidencia e medido em relacao a normal, nao a superficie.",
        "Quando a luz passa do ar (n~1) para a agua (n~1,33), aproxima-se da normal.",
        "Espelho plano forma imagem virtual, direita e de mesmo tamanho.",
        "Para focar em fotografia, usa-se 1/f = 1/p + 1/p'.",
        "Lente convergente tem f positivo; divergente, f negativo.",
        "1 dioptria = 1/f (em metros).",
    ],
    "pegadinhas": [
        "Medir angulo em relacao a superficie, nao a normal: o angulo e sempre em relacao a normal.",
        "Esquecer que, na reflexao, os angulos sao iguais apenas se medidos da normal.",
        "Confundir imagem real com virtual: real pode ser projetida; virtual nao.",
        "Achar que lente divergente tem f positivo: divergente tem f negativo.",
        "Esquecer de converter f para metros ao calcular dioptrias.",
        "Aplicar a equacao das lentes sem considerar sinais: p' negativo = imagem virtual.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "HECHT, E. Optica. 4. ed. Porto Alegre: Bookman, 2014.",
        "PEDROTTI, F. L.; PEDROTTI, L. M. Optica e Fotonica. Sao Paulo: LTC, 2007.",
    ],
}

IMG_OPTICA = [{"file": "fi_optica.png", "caption": "Refracao da luz ao passar do ar para a agua", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.7 Ondulatoria
# ============================================================
ONDULATORIA = {
    "titulo": "Ondulatória",
    "disciplina": "Física",
    "topico": "Ondulatória",
    "subtopico": "Ondas, frequencia, comprimento, interferencia e ressonancia",
    "introducao": (
        "A Ondulatoria estuda as ondas, fenomenos que transportam "
        "energia sem transportar materia. Ondas mecanicas precisam "
        "de um meio material; ondas eletromagneticas podem se "
        "propagar no vacuo."
    ),
    "secoes": [
        {
            "titulo": "1. Caracteristicas das ondas",
            "conteudo": (
                "GRANDEZAS DE UMA ONDA:\n"
                "- Comprimento de onda (lambda): distancia entre duas "
                "cristas consecutivas. Unidade: metro.\n"
                "- Frequencia (f): numero de oscilacoes por segundo. "
                "Unidade: hertz (Hz).\n"
                "- Periodo (T): tempo de uma oscilacao. T = 1/f. "
                "Unidade: segundo.\n"
                "- Amplitude (A): deslocamento maximo em relacao ao "
                "ponto de equilibrio.\n"
                "- Velocidade de propagacao: v = lambda . f.\n\n"
                "ONDAS MECANICAS: som, ondas na corda, ondas no mar. "
                "Necessitam de meio.\n"
                "ONDAS ELETROMAGNETICAS: luz, radio, raio X, micro-ondas. "
                "Nao necessitam de meio.\n\n"
                "ONDAS TRANSVERSAIS: a oscilacao e perpendicular a "
                "direcao de propagacao. Exemplo: ondas na corda.\n"
                "ONDAS LONGITUDINAIS: a oscilacao e paralela a "
                "direcao de propagacao. Exemplo: som no ar."
            ),
            "exemplo": (
                "O som e uma onda longitudinal. A frequencia determina "
                "a altura (grave ou agudo): 20 Hz a 20.000 Hz e o "
                "espectro audivel humano. Em medicina, o ultrassom "
                "usa frequencias acima de 20.000 Hz para imagem "
                "diagnostica. A ecografia mede o tempo de retorno do "
                "eco para formar imagens de orgaos e fetos."
            ),
        },
        {
            "titulo": "2. Fenomenos ondulatorios",
            "conteudo": (
                "REFLEXAO: a onda encontra um obstaculo e volta. "
                "Eco e o exemplo mais conhecido.\n\n"
                "REFRACAO: a onda muda de meio e altera velocidade e "
                "comprimento, mantendo a frequencia.\n\n"
                "DIFRACAO: a onda contorna obstaculos ou passa por "
                "aberturas. E mais evidente quando o obstaculo tem "
                "tamanho proximo ao comprimento de onda.\n\n"
                "INTERFERENCIA: quando duas ondas se encontram, a "
                "onda resultante e a soma das amplitudes. Pode ser "
                "construtiva (amplitudes no mesmo sentido) ou "
                "destrutiva (amplitudes opostas).\n\n"
                "RESSONANCIA: quando a frequencia de uma onda externa "
                "iguala uma frequencia natural do sistema, "
                "amplificando a oscilacao."
            ),
            "exemplo": (
                "A ressonancia e usada em ressonancia magnetica (RM). "
                "O aparelho emite ondas de radio que fazem os nucleos "
                "de hidrogenio do corpo vibrar em ressonancia. Quando "
                "a emissao para, os nucleos relaxam e liberam sinais "
                "que sao transformados em imagens detalhadas dos "
                "tecidos. Sem ressonancia, a tecnica nao existiria."
            ),
        },
        {
            "titulo": "3. Ondas sonoras e propriedades",
            "conteudo": (
                "ONDAS SONORAS: ondas mecanicas longitudinais que "
                "precisam de meio. Nao se propagam no vacuo.\n\n"
                "INTENSIDADE DO SOM: quantidade de energia que passa "
                "por unidade de area e tempo. Medida em W/m^2. O "
                "limite inferior de audicao e cerca de "
                "10^-12 W/m^2.\n\n"
                "NIVEL SONORO: medido em decibeis (dB). Escala "
                "logaritmica. Cada aumento de 10 dB significa "
                "multiplicar a intensidade por 10.\n\n"
                "EFEITO DOPPLER: mudanca aparente de frequencia quando "
                "a fonte e o observador se aproximam ou se afastam. "
                "Aproximacao: frequencia aparente aumenta. "
                "Afastamento: diminui.\n\n"
                "ECO: reflexao do som em obstaculos. Usado em "
                "ecografia e sonar."
            ),
            "exemplo": (
                "Prolongada exposicao a 85 dB pode causar perda "
                "auditiva. Ambientes hospitalares com ruido excessivo "
                "aumentam o estresse e prejudicam a comunicacao. "
                "Esterilizadores, bombas e ventiladores devem ser "
                "monitorados. O efeito Doppler e usado para medir "
                "velocidade do sangue em vasos sanguineos, auxiliando "
                "no diagnostico de estenoses."
            ),
        },
    ],
    "resumo": (
        "- v = lambda . f. T = 1/f.\n"
        "- Ondas mecanicas precisam de meio; eletromagneticas, nao.\n"
        "- Reflexao, refracao, difracao, interferencia e ressonancia.\n"
        "- Interferencia construtiva: amplitudes se somam. Destrutiva: se anulam parcialmente.\n"
        "- Nivel sonoro em dB: escala logaritmica.\n"
        "- Efeito Doppler: aproximacao aumenta a frequencia aparente."
    ),
    "dicas": [
        "Frequencia nao muda na refracao; velocidade e comprimento sim.",
        "v = lambda . f: para o mesmo meio, maior frequencia significa menor comprimento.",
        "10 dB a mais = 10 vezes mais intensidade. 20 dB a mais = 100 vezes.",
        "Difracao e mais evidente quando o obstaculo e do tamanho da onda.",
        "Efeito Doppler: aproximar = tom mais agudo; afastar = mais grave.",
        "Ultrassom e usado em medicina porque e refletido por fronteiras de tecidos.",
    ],
    "pegadinhas": [
        "Achar que ondas transportam materia: ondas transportam energia, nao materia.",
        "Esquecer que o som nao se propaga no vacuo.",
        "Confundir dB com intensidade: dB e logaritmico, intensidade e linear.",
        "Achar que a velocidade do som e constante: depende do meio e temperatura.",
        "Esquecer que frequencia e invariante ao mudar de meio.",
        "Confundir eco com refracao: eco e reflexao do som.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "INGARD, U. Fundamentos de Ondas e Oscilacoes. Sao Paulo: E. Blucher, 1992.",
        "BONJORNO, J. R.; BONJORNO, R. S.; RAMOS, C. M. Fisica para o Ensino Médio. Sao Paulo: FTD, 1999.",
    ],
}

IMG_ONDULATORIA = [{"file": "fi_ondulatoria.png", "caption": "Onda: comprimento de onda (lambda) e amplitude", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# 3.8 Eletrostatica
# ============================================================
ELETROSTATICA = {
    "titulo": "Eletrostática",
    "disciplina": "Física",
    "topico": "Eletrostática",
    "subtopico": "Cargas, forca eletrica, campo e potencial",
    "introducao": (
        "A Eletrostatica estuda as cargas eletricas em repouso. "
        "As cargas podem ser positivas ou negativas e interagem "
        "mediante forcas atrativas ou repulsivas."
    ),
    "secoes": [
        {
            "titulo": "1. Cargas eletricas e processos de eletrizacao",
            "conteudo": (
                "CARGAS ELETRICAS: podem ser positivas (protons) ou "
                "negativas (eletrons). A carga elementar e "
                "e = 1,6 x 10^-19 C.\n\n"
                "PRINCIPIO DA ATRACAO: cargas de sinais opostos se "
                "atraem; de mesmo sinal se repelem.\n\n"
                "PROCESSOS DE ELETRIZACAO:\n"
                "- Atrito: transferencia de eletrons por friccao.\n"
                "- Contato: distribuicao de cargas entre corpos "
                "condutores.\n"
                "- Inducao: redistribuicao de cargas devido a aproximacao "
                "de um corpo carregado, sem contato.\n\n"
                "CONDUTORES: permitem movimento de eletrons. Metais.\n"
                "ISOLANTES: dificultam o movimento de eletrons. "
                "Borracha, plastico, ar seco.\n\n"
                "ELETROSCOPIO: instrumento que detecta presenca de "
                "carga eletrica."
            ),
            "exemplo": (
                "Choques estaticos sao comuns no inverno seco. Ao "
                "andar sobre um carpete de lao, eletrons sao "
                "transferidos para o corpo por atrito. Quando "
                "toca-se em uma macaneta metalica, os eletrons "
                "escapam rapidamente, causando uma descarga. Em "
                "UTIs, equipamentos sao aterrados para evitar "
                "cargas estaticas que possam danificar aparelhos."
            ),
        },
        {
            "titulo": "2. Lei de Coulomb e campo eletrico",
            "conteudo": (
                "LEI DE COULOMB: a forca entre duas cargas e "
                "proporcional ao produto das cargas e inversamente "
                "proporcional ao quadrado da distancia.\n\n"
                "F = k . |Q1 . Q2| / d^2, onde k = 9 x 10^9 N.m^2/C^2 "
                "(no vacuo).\n\n"
                "CAMPO ELETRICO: regiao em torno de uma carga onde "
                "outra carga sofre forca. E = F / q. Para uma carga "
                "puntiforme, E = k . |Q| / d^2.\n\n"
                "UNIDADE: N/C ou V/m.\n\n"
                "LINHAS DE CAMPO: partem de cargas positivas e "
                "chegam em negativas. Quanto mais proximas, mais "
                "intenso o campo."
            ),
            "exemplo": (
                "O eletrocardiograma mede campos eletricos gerados "
                "pelo coracao. As celulas cardiacas criam diferencas "
                "de potencial que se propagam como ondas eletricas. "
                "Eletrodos colocados no corpo captam essas variacoes "
                "de potencial, permitindo diagnosticar arritmias, "
                "infartos e outras doencas."
            ),
        },
        {
            "titulo": "3. Potencial eletrico e energia",
            "conteudo": (
                "POTENCIAL ELETRICO: energia potencial por unidade de "
                "carga. V = E_p / q. Unidade: volt (V = J/C).\n\n"
                "POTENCIAL DE CARGA PUNTIFORME: V = k . Q / d.\n\n"
                "DIFERENCA DE POTENCIAL (ddp): V_A - V_B = "
                "trabalho por unidade de carga para levar de B a A.\n\n"
                "TRABALHO DO CAMPO ELETRICO: "
                "W = q . (V_A - V_B).\n\n"
                "EQUIPOTENCIAIS: superficies onde o potencial e "
                "constante. Nao se realiza trabalho ao mover uma "
                "carga ao longo de uma superficie equipotencial."
            ),
            "exemplo": (
                "Desfibriladores cardiacos aplicam uma diferenca de "
                "potencial elevada (ate milhares de volts) entre "
                "pas colocadas no torax. A descarga eletrica repoe "
                "o ritmo cardiaco em fibrilacao. A energia fornecida "
                "depende do trabalho realizado pelo campo eletrico "
                "sobre as cargas ionicas do coracao."
            ),
        },
    ],
    "resumo": (
        "- Cargas positivas e negativas; sinais opostos atraem, iguais repetem.\n"
        "- Eletrizacao por atrito, contato e inducao.\n"
        "- Lei de Coulomb: F = k.|Q1.Q2|/d^2.\n"
        "- Campo eletrico: E = F/q = k.|Q|/d^2.\n"
        "- Potencial eletrico: V = k.Q/d. ddp = V_A - V_B.\n"
        "- Trabalho do campo: W = q.ddp."
    ),
    "dicas": [
        "k = 9 x 10^9 N.m^2/C^2 para o vacuo.",
        "A forca de Coulomb e sempre ao longo da linha que une as cargas.",
        "Campo eletrico de carga positiva aponta para fora; de negativa, para dentro.",
        "Potencial e escalar; campo e vetorial.",
        "Superficie equipotencial: nenhum trabalho ao mover carga sobre ela.",
        "A carga elementar e e = 1,6 x 10^-19 C.",
    ],
    "pegadinhas": [
        "Esquecer que a forca de Coulomb depende do quadrado da distancia (inversa).",
        "Achar que o campo eletrico e sempre positivo: pode ser negativo, depende da carga de prova.",
        "Confundir potencial com campo: potencial e energia por carga; campo e forca por carga.",
        "Esquecer de converter distancia para metros na lei de Coulomb.",
        "Achar que trabalho do campo e zero quando a carga percorre uma equipotencial.",
        "Usar forca resultante sem considerar a direcao vetorial de cada forca.",
    ],
    "referencias": [
        "HEWITT, P. G. Fisica conceitual. 12. ed. Porto Alegre: Bookman, 2015.",
        "HALLIDAY, D.; RESNICK, R.; WALKER, J. Fundamentos de Fisica. 10. ed. Sao Paulo: LTC, 2016.",
        "Tipler, P. A.; MOSCA, G. Fisica para Cientistas e Engenheiros. 6. ed. Rio de Janeiro: LTC, 2009.",
        "ALVARENGA, B.; MAXIMO, A. Fisica. 6. ed. Sao Paulo: Harbra, 2010.",
        "FEYNMAN, R. P. Lectures on Physics: Eletromagnetismo. Sao Paulo: Bookman, 2008.",
        "NUSSENZVEIG, H. M. Curso de Fisica Basica. 4. ed. Sao Paulo: E. Blucher, 2002.",
    ],
}

IMG_ELETROSTATICA = [{"file": "fi_eletrostatica.png", "caption": "Cargas eletricas: opostos atraem e iguais repetem", "source": "PAES MED AI", "source_url": ""}]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (TERMOLOGIA, "FI_TERMOLOGIA.pdf", IMG_TERMOLOGIA, "Fisica — Termologia"),
        (OPTICA, "FI_OPTICA_GEOMETRICA.pdf", IMG_OPTICA, "Fisica — Optica Geometrica"),
        (ONDULATORIA, "FI_ONDULATORIA.pdf", IMG_ONDULATORIA, "Fisica — Ondulatoria"),
        (ELETROSTATICA, "FI_ELETROSTATICA.pdf", IMG_ELETROSTATICA, "Fisica — Eletrostatica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
