"""Gera PDFs de Matematica — batch 2 (topicos 4.6 a 4.10)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 4.6 Matrizes e Sistemas
# ============================================================
MATRIZES = {
    "titulo": "Matrizes e Sistemas",
    "disciplina": "Matemática",
    "topico": "Matrizes e Sistemas",
    "subtopico": "Matrizes, determinantes e resolucao de sistemas lineares",
    "introducao": (
        "Matrizes organizam numeros em linhas e colunas e "
        "aparecem em planilhas, imagens medicas e modelos "
        "estatisticos. Sistemas lineares permitem resolver "
        "problemas com varias equacoes e incognitas."
    ),
    "secoes": [
        {
            "titulo": "1. Matrizes: conceitos e tipos",
            "conteudo": (
                "MATRIZ: tabela retangular de numeros organizados "
                "em linhas e colunas. Uma matriz m x n tem m "
                "linhas e n colunas.\n\n"
                "NOTACAO: A = (a_ij), onde i e o indice da linha "
                "e j o da coluna.\n\n"
                "TIPOS ESPECIAIS:\n"
                "- Matriz linha: 1 x n\n"
                "- Matriz coluna: m x 1\n"
                "- Matriz quadrada: n x n\n"
                "- Matriz nula: todos os elementos iguais a zero\n"
                "- Matriz identidade: quadrada com 1 na diagonal "
                "principal e 0 fora\n"
                "- Matriz transposta (A^t): troca linhas por colunas\n\n"
                "ADICAO E MULTIPLICACAO POR ESCALAR: soma "
                "elemento a elemento; multiplicacao por escalar "
                "multiplica cada elemento."
            ),
            "exemplo": (
                "Uma planilha de vacinacao pode ser uma matriz: "
                "linhas sao postos de saude e colunas sao dias da "
                "semana. Cada celula mostra o numero de doses "
                "aplicadas. Somar duas matrizes significa somar as "
                "doses de cada posto em cada dia. Multiplicar por "
                "2 projeta o dobro de doses."
            ),
        },
        {
            "titulo": "2. Determinantes e matriz inversa",
            "conteudo": (
                "DETERMINANTE: numero associado a uma matriz "
                "quadrada. Indica se a matriz e inversivel e "
                "aparece em sistemas e areas.\n\n"
                "ORDEM 2: det = a.d - b.c, para matriz [[a, b], [c, d]].\n\n"
                "ORDEM 3: regra de Sarrus ou Laplace. Para matriz "
                "3x3, repete as duas primeiras colunas e soma "
                "diagonais descendentes, subtraindo as ascendentes.\n\n"
                "MATRIZ INVERSA: A^(-1) e tal que A . A^(-1) = I. "
                "Existe somente se det(A) != 0.\n\n"
                "APLICACAO: resolucao de sistemas lineares pela "
                "regra de Cramer."
            ),
            "exemplo": (
                "Uma matriz 2x2 representa uma transformacao "
                "em uma imagem medica. Se a matriz for [[2, 0], "
                "[0, 2]], o determinante e 4, o que significa que "
                "a area e multiplicada por 4. Se a matriz "
                "distorcer a imagem, o determinante negativo "
                "indica uma inversao de orientacao."
            ),
        },
        {
            "titulo": "3. Sistemas lineares",
            "conteudo": (
                "SISTEMA LINEAR: conjunto de equacoes do 1o grau "
                "com varias incognitas.\n\n"
                "CLASSIFICACAO:\n"
                "- Possivel e determinado: uma unica solucao.\n"
                "- Possivel e indeterminado: infinitas solucoes.\n"
                "- Impossivel: nenhuma solucao.\n\n"
                "METODOS DE RESOLUCAO:\n"
                "- Substituicao: isolar uma variavel em uma "
                "equacao e substituir nas outras.\n"
                "- Adicao: somar as equacoes para eliminar uma "
                "variavel.\n"
                "- Cramer: usa determinantes.\n"
                "- Escalonamento: transforma o sistema em uma "
                "forma triangular.\n\n"
                "NUMERO DE EQUACOES E VARIAVEIS: em geral, "
                "n equacoes e n incognitas para solucao unica."
            ),
            "exemplo": (
                "Em uma farmacia, x e a quantidade de um remedio "
                "de 10 mg e y de 20 mg. Se precisamos de 30 "
                "comprimidos e 500 mg no total, o sistema e:\n"
                "x + y = 30\n"
                "10x + 20y = 500\n"
                "Da primeira equacao, x = 30 - y. Substituindo na "
                "segunda: 10.(30 - y) + 20y = 500, "
                "300 + 10y = 500, y = 20. Entao x = 10."
            ),
        },
    ],
    "resumo": (
        "- Matriz e uma tabela de numeros. Tipos: linha, coluna, quadrada, identidade.\n"
        "- Transposta: linhas viram colunas.\n"
        "- Determinante ordem 2: a.d - b.c.\n"
        "- Regra de Sarrus para ordem 3.\n"
        "- Matriz inversa: existe se det(A) != 0.\n"
        "- Sistemas lineares: substituicao, adicao, Cramer, escalonamento.\n"
        "- Classificacao: determinado, indeterminado, impossivel."
    ),
    "dicas": [
        "A diagonal principal vai do canto superior esquerdo ao inferior direito.",
        "Matriz identidade e como o numero 1 da multiplicacao.",
        "Se o determinante for zero, a matriz nao tem inversa.",
        "Para sistemas 2x2, o metodo da substituicao e rapido.",
        "Cramer exige que o determinante da matriz dos coeficientes seja diferente de zero.",
        "Sistema indeterminado: as equacoes representam a mesma reta ou planos coincidentes.",
    ],
    "pegadinhas": [
        "Multiplicar matrizes com dimensoes incompativeis: colunas da primeira devem igualar linhas da segunda.",
        "Achar que toda matriz tem inversa: so as quadradas com det != 0.",
        "Esquecer de trocar linha por coluna na transposta.",
        "Confundir matriz identidade com matriz nula.",
        "Aplicar Sarrus em matrizes 4x4 ou maiores.",
        "Esquecer que sistema impossivel gera uma contradicao como 0 = 5.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_MATRIZES = [
    {"file": "mat_matrizes.png", "caption": "Matriz 3 x 3 e determinante", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.7 Trigonometria
# ============================================================
TRIGONOMETRIA = {
    "titulo": "Trigonometria",
    "disciplina": "Matemática",
    "topico": "Trigonometria",
    "subtopico": "Triangulo retangulo, ciclo trigonometrico e funcoes",
    "introducao": (
        "A Trigonometria estuda as relacoes entre angulos e lados "
        "de triangulos e e usada em medicina, engenharia e "
        "navegacao."
    ),
    "secoes": [
        {
            "titulo": "1. Triangulo retangulo",
    "conteudo": (
                "RAZOES TRIGONOMETRICAS: para um angulo agudo teta "
                "em um triangulo retangulo:\n"
                "- sen teta = cateto oposto / hipotenusa\n"
                "- cos teta = cateto adjacente / hipotenusa\n"
                "- tan teta = cateto oposto / cateto adjacente\n\n"
                "TEOREMA DE PITAGORAS: (hipotenusa)^2 = (cateto "
                "oposto)^2 + (cateto adjacente)^2.\n\n"
                "ANGULOS NOTAVEIS: 30, 45 e 60 graus. Os valores "
                "de seno, cosseno e tangente desses angulos "
                "aparecem com frequencia.\n\n"
                "RELACAO FUNDAMENTAL: sen^2 teta + cos^2 teta = 1."
            ),
            "exemplo": (
                "Para medir a altura de um predio, um medico de "
                "edificacoes olha para o topo com um angulo de "
                "60 graus, a 30 m do predio. A altura h e tal "
                "que tan 60 = h / 30. Como tan 60 = raiz(3) "
                "aproximadamente 1,73, h = 30 . 1,73 = 51,9 m. "
                "Esse metodo e usado em avaliacoes de acessibilidade."
            ),
        },
        {
            "titulo": "2. Circulo trigonometrico",
            "conteudo": (
                "CIRCULO TRIGONOMETRICO: circulo de raio 1, "
                "dividido em quatro quadrantes. Medida de arcos "
                "em graus ou radianos.\n\n"
                "CONVERSAO: pi radianos = 180 graus. "
                "1 radiano = 180 / pi graus.\n\n"
                "QUADRANTES:\n"
                "- 1o: 0 a 90 graus; sen e cos positivos.\n"
                "- 2o: 90 a 180; sen positivo, cos negativo.\n"
                "- 3o: 180 a 270; sen e cos negativos.\n"
                "- 4o: 270 a 360; sen negativo, cos positivo.\n\n"
                "REDUCAO AO PRIMEIRO QUADRANTE: angulos maiores "
                "que 90 graus podem ser reduzidos usando simetrias."
            ),
            "exemplo": (
                "Em biomecanica, o angulo de flexao do cotovelo e "
                "medido em graus. Uma flexao de 90 graus e "
                "pi/2 radianos. A amplitude de movimento de um "
                "ombro pode chegar a 180 graus, que e pi radianos. "
                "Fisioterapeutas convertem entre graus e radianos "
                "ao analisar relatorios de goniometria."
            ),
        },
        {
            "titulo": "3. Funcoes trigonométricas",
            "conteudo": (
                "SENO: funcao f(x) = sen x. Periodo 360 graus ou "
                "2.pi radianos. Varia entre -1 e 1.\n\n"
                "COSSENO: f(x) = cos x. Tambem periodo 2.pi, "
                "varia entre -1 e 1. Grafico e uma onda "
                "deslocada em relacao ao seno.\n\n"
                "TANGENTE: f(x) = tan x = sen x / cos x. Periodo "
                "pi radianos. Nao definida quando cos x = 0.\n\n"
                "APLICACOES: ondas sonoras, eletrocardiograma, "
                "fenomenos periodicos, biomecanica."
            ),
            "exemplo": (
                "A pressao arterial varia de forma ciclica ao "
                "longo do dia. Em um modelo simplificado, pode-se "
                "aproximar a variacao por uma funcao senoidal. "
                "A sistole e a diastole definem a amplitude, "
                "enquanto a frequencia cardiaca define o periodo. "
                "Funcoes trigonometricas ajudam a modelar esses "
                "ciclos biologicos."
            ),
        },
    ],
    "resumo": (
        "- sen teta = oposto/hipotenusa; cos teta = adjacente/hipotenusa; tan teta = oposto/adjacente.\n"
        "- sen^2 teta + cos^2 teta = 1.\n"
        "- Circulo trigonometrico: raio 1, 4 quadrantes.\n"
        "- pi radianos = 180 graus.\n"
        "- Funcoes seno, cosseno e tangente sao periodicas.\n"
        "- Tangente nao definida quando cosseno e zero."
    ),
    "dicas": [
        "Cateto oposto e o que nao toca o angulo teta; adjacente toca.",
        "Hipotenusa e sempre o maior lado, oposto ao angulo reto.",
        "Seno e cosseno de angulos complementares: sen x = cos(90 - x).",
        "No circulo trigonometrico, o raio vale 1.",
        "Para converter graus em radianos, multiplique por pi/180.",
        "Seno e cosseno variam entre -1 e 1.",
    ],
    "pegadinhas": [
        "Confundir cateto oposto com adjacente em relacao ao angulo dado.",
        "Usar seno em triangulos nao retangulos sem cuidado.",
        "Esquecer que tan teta = sen teta / cos teta e que cos teta = 0 gera problema.",
        "Confundir graus e radianos na mesma conta.",
        "Achar que sen x pode ser maior que 1.",
        "Esquecer o sinal das razoes nos quadrantes 2, 3 e 4.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_TRIGONOMETRIA = [
    {"file": "mat_trigonometria.png", "caption": "Razoes trigonometricas no triangulo retangulo", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.8 Analise Combinatoria
# ============================================================
COMBINATORIA = {
    "titulo": "Análise Combinatória",
    "disciplina": "Matemática",
    "topico": "Analise Combinatoria",
    "subtopico": "Fatorial, arranjos, permutacoes e combinacoes",
    "introducao": (
        "A Analise Combinatoria conta de quantas maneiras um "
        "evento pode ocorrer. E usada em probabilidade, "
        "genetica e epidemiologia."
    ),
    "secoes": [
        {
            "titulo": "1. Fatorial e principio multiplicativo",
    "conteudo": (
                "FATORIAL: n! = n . (n-1) . (n-2) ... 2 . 1. "
                "Por convencao, 0! = 1.\n\n"
                "PRINCIPIO MULTIPLICATIVO: se uma acao pode ser "
                "feita de m maneiras e outra de n maneiras, as "
                "duas juntas podem ser feitas de m . n maneiras.\n\n"
                "PRINCIPIO ADITIVO: se as acoes sao excludentes "
                "(uma ou outra), soma-se m + n.\n\n"
                "ARVORE DE POSSIBILIDADES: representacao grafica "
                "das escolhas sequenciais."
            ),
            "exemplo": (
                "Um pacote de cafe da manha oferece 3 tipos de "
                "pao, 2 recheios e 4 bebidas. Pelo principio "
                "multiplicativo, o numero de refeicoes diferentes "
                "e 3 . 2 . 4 = 24. Em dietas hospitalares, essa "
                "contagem ajuda a planevar cardapios variados."
            ),
        },
        {
            "titulo": "2. Arranjos, permutacoes e combinacoes",
            "conteudo": (
                "PERMUTACAO SIMPLES: ordenacao de n elementos "
                "distintos. P_n = n!\n\n"
                "ARRANJO: escolha e ordenacao de p elementos de "
                "um total de n. A(n,p) = n! / (n-p)!\n\n"
                "COMBINACAO: escolha de p elementos de n, sem "
                "importar a ordem. C(n,p) = n! / (p! . (n-p)!)\n\n"
                "DIFERENCA: arranjo importa a ordem; combinacao "
                "nao.\n\n"
                "PERMUTACAO COM REPETICAO: se ha elementos "
                "repetidos, divide pelo fatorial das repeticoes."
            ),
            "exemplo": (
                "Em um hospital, 5 medicos concorrem a 2 vagas em "
                "um congresso. Se a ordem de escolha importa "
                "(primeiro e segundo participante), e arranjo: "
                "A(5,2) = 5! / 3! = 5 . 4 = 20. Se as duas "
                "vagas sao iguais, e combinacao: C(5,2) = "
                "5! / (2! . 3!) = 10."
            ),
        },
        {
            "titulo": "3. Binomio de Newton",
            "conteudo": (
                "BINOMIO DE NEWTON: expansao de (a + b)^n. "
                "(a + b)^n = soma de C(n,p) . a^(n-p) . b^p, "
                "com p variando de 0 a n.\n\n"
                "TRIANGULO DE PASCAL: fornece os coeficientes "
                "binomials de forma organizada. Cada numero e a "
                "soma dos dois acima.\n\n"
                "TERMOS DO BINOMIO: os expoentes de a "
                "diminuem e os de b aumentam, de n ate 0.\n\n"
                "APLICACOES: expansoes algebricas, probabilidade, "
                "genetica."
            ),
            "exemplo": (
                "Na genetica, a probabilidade de um casal ter "
                "dois filhos com determinada caracteristica pode "
                "ser modelada por um binomio. Se a chance de "
                "um filho ter a caracteristica e 25%, as "
                "possibilidades para dois filhos seguem "
                "(p + q)^2 = p^2 + 2.p.q + q^2."
            ),
        },
    ],
    "resumo": (
        "- Fatorial: n! = n . (n-1) ... 1. 0! = 1.\n"
        "- Principio multiplicativo: m . n. Principio aditivo: m + n.\n"
        "- Permutacao: P_n = n!\n"
        "- Arranjo: A(n,p) = n!/(n-p)!\n"
        "- Combinacao: C(n,p) = n!/(p!.(n-p)!)\n"
        "- Binomio de Newton: (a+b)^n. Triangulo de Pascal fornece coeficientes."
    ),
    "dicas": [
        "Ordem importa? Arranjo. Ordem nao importa? Combinacao.",
        "Permutacao e um arranjo onde p = n.",
        "Principio multiplicativo e para 'e' (acoes em sequencia); aditivo e para 'ou' (alternativas).",
        "No binomio, os coeficientes sao os mesmos de C(n,p).",
        "Triangulo de Pascal: linha n fornece os coeficientes de (a+b)^n.",
        "C(n,p) = C(n, n-p).",
    ],
    "pegadinhas": [
        "Confundir arranjo com combinacao: se a ordem nao importa, nao use arranjo.",
        "Esquecer que 0! = 1.",
        "Somar em vez de multiplicar no principio multiplicativo.",
        "Achar que n! = n . (n-1) sem multiplicar ate 1.",
        "Esquecer de dividir pelas repeticoes em permutacoes com repeticao.",
        "No binomio, esquecer o sinal de b se for (a - b)^n.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_COMBINATORIA = [
    {"file": "mat_combinatoria.png", "caption": "Arvore de possibilidades: principio multiplicativo", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.9 Estatistica e Probabilidade
# ============================================================
ESTATISTICA = {
    "titulo": "Estatística e Probabilidade",
    "disciplina": "Matemática",
    "topico": "Estatistica e Probabilidade",
    "subtopico": "Media, mediana, moda, variancia, probabilidade",
    "introducao": (
        "A Estatistica organiza e interpreta dados. A "
        "Probabilidade mede a chance de um evento ocorrer. "
        "Ambas sao essenciais para entender pesquisas medicas "
        "e epidemiologia."
    ),
    "secoes": [
        {
            "titulo": "1. Medidas de tendencia central",
            "conteudo": (
                "MEDIA ARITMETICA: soma dos valores dividida pelo "
                "numero de valores. x_ = (soma x_i) / n.\n\n"
                "MEDIA PONDERADA: considera pesos para cada valor. "
                "x_ = (soma x_i . p_i) / (soma p_i).\n\n"
                "MEDIANA: valor central quando os dados estao "
                "ordenados. Se n for par, e a media dos dois "
                "valores centrais.\n\n"
                "MODA: valor que mais se repete. Pode haver mais "
                "de uma moda ou nenhuma."
            ),
            "exemplo": (
                "As glicemias de um paciente em 5 dias foram: "
                "90, 95, 100, 105, 110. A media e "
                "(90+95+100+105+110)/5 = 500/5 = 100. A mediana "
                "e 100. Nao ha moda. Em epidemiologia, a media "
                "de idade dos pacientes ajuda a definir o publico "
                "alvo de uma campanha."
            ),
        },
        {
            "titulo": "2. Variancia, desvio padrao e graficos",
            "conteudo": (
                "AMPLITUDE: diferenca entre o maior e o menor valor.\n\n"
                "VARIANCIA: media dos quadrados dos desvios em "
                "relacao a media. Mede a dispersao.\n\n"
                "DESVIO PADRAO: raiz quadrada da variancia. "
                "Mesma unidade dos dados. Simbolo: s.\n\n"
                "TIPOS DE GRAFICOS:\n"
                "- Barras: compara categorias.\n"
                "- Setores (pizza): mostra proporcao.\n"
                "- Linhas: mostra evolucao ao longo do tempo.\n"
                "- Histograma: barras justapostas para dados "
                "agrupados em intervalos."
            ),
            "exemplo": (
                "Um estudo mede a pressao arterial de dois grupos. "
                "O grupo A tem media 120 mmHg e desvio padrao 5. "
                "O grupo B tambem tem media 120, mas desvio "
                "padrao 20. Embora as medias sejam iguais, o "
                "grupo B tem valores muito mais dispersos, "
                "indicando menos controle. O desvio padrao "
                "revela essa diferenca."
            ),
        },
        {
            "titulo": "3. Probabilidade",
            "conteudo": (
                "PROBABILIDADE: P(A) = (numero de casos favoraveis "
                "a A) / (numero total de casos possiveis).\n\n"
                "PROPRIEDADES:\n"
                "- 0 <= P(A) <= 1\n"
                "- P(universo) = 1\n"
                "- P(complementar de A) = 1 - P(A)\n\n"
                "EVENTOS INDEPENDENTES: P(A e B) = P(A) . P(B).\n\n"
                "EVENTOS MUTUAMENTE EXCLUSIVOS: P(A ou B) = "
                "P(A) + P(B).\n\n"
                "PROBABILIDADE CONDICIONAL: P(A|B) = "
                "P(A e B) / P(B), com P(B) > 0."
            ),
            "exemplo": (
                "A probabilidade de um paciente ter complicacoes "
                "apos uma cirurgia e de 5%. Se dois pacientes "
                "independentes se operam, a chance de ambos "
                "terem complicacoes e 0,05 . 0,05 = 0,0025, ou "
                "0,25%. Ja a chance de pelo menos um ter "
                "complicacoes e 1 - (0,95 . 0,95) = 0,0975, "
                "ou 9,75%."
            ),
        },
    ],
    "resumo": (
        "- Media: soma / n. Ponderada: considera pesos.\n"
        "- Mediana: valor central. Moda: mais frequente.\n"
        "- Desvio padrao mede dispersao.\n"
        "- Graficos: barras, pizza, linhas, histograma.\n"
        "- P(A) = favoraveis / total. 0 <= P(A) <= 1.\n"
        "- Eventos independentes: P(A e B) = P(A) . P(B)."
    ),
    "dicas": [
        "Sempre ordene os dados para calcular a mediana.",
        "A moda pode ser bimodal (dois valores) ou nao existir.",
        "Desvio padrao alto significa dados muito espalhados.",
        "Na probabilidade, multiplique para 'e' e some para 'ou' quando os eventos sao exclusivos.",
        "Complementar de A e tudo o que nao e A.",
        "Probabilidade condicional: restringe o universo ao evento B.",
    ],
    "pegadinhas": [
        "Confundir media com mediana: a media e sensivel a valores extremos.",
        "Achar que a moda e sempre o maior valor: e o mais frequente.",
        "Somar probabilidades de eventos nao exclusivos sem subtrair a intersecao.",
        "Esquecer de multiplicar por 100 para expressar porcentagem.",
        "Achar que eventos independentes nunca podem ocorrer juntos: eles podem, mas a ocorrencia de um nao afeta o outro.",
        "Confundir variancia com desvio padrao: variancia e o quadrado do desvio.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_ESTATISTICA = [
    {"file": "mat_estatistica.png", "caption": "Grafico de barras: frequencia e medidas centrais", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.10 Geometria Analitica
# ============================================================
GEO_ANALITICA = {
    "titulo": "Geometria Analítica",
    "disciplina": "Matemática",
    "topico": "Geometria Analitica",
    "subtopico": "Ponto, reta, distancia e circunferencia no plano cartesiano",
    "introducao": (
        "A Geometria Analitica unifica algebra e geometria. "
        "Pontos, retas e figuras sao representados por "
        "coordenadas e equacoes."
    ),
    "secoes": [
        {
            "titulo": "1. Ponto, distancia e ponto medio",
    "conteudo": (
                "PLANO CARTESIANO: formado pelos eixos x e y, "
                "perpendiculares. Um ponto e dado por (x, y).\n\n"
                "DISTANCIA ENTRE PONTOS: dados A(x1,y1) e B(x2,y2), "
                "d(A,B) = raiz((x2 - x1)^2 + (y2 - y1)^2).\n\n"
                "PONTO MEDIO: M = ((x1 + x2)/2, (y1 + y2)/2).\n\n"
                "BARICENTRO: intersecao das medianas de um triangulo. "
                "G = ((x1 + x2 + x3)/3, (y1 + y2 + y3)/3).\n\n"
                "AREA DE TRIANGULO: A = (1/2) . |x1(y2 - y3) + "
                "x2(y3 - y1) + x3(y1 - y2)|."
            ),
            "exemplo": (
                "Um hospital tem tres entradas com coordenadas "
                "A(0,0), B(4,0) e C(2,3). O baricentro, que "
                "indica um ponto central, e "
                "G = ((0+4+2)/3, (0+0+3)/3) = (2, 1). A "
                "distancia entre A e B e 4, e a area do triangulo "
                "formado pelas entradas e "
                "A = (1/2) . |0.(0-3) + 4.(3-0) + 2.(0-0)| = 6."
            ),
        },
        {
            "titulo": "2. Reta: equacoes e coeficiente angular",
            "conteudo": (
                "COEFICIENTE ANGULAR: m = (y2 - y1) / (x2 - x1). "
                "Mede a inclinacao da reta.\n\n"
                "EQUACAO FUNDAMENTAL: y - y0 = m . (x - x0).\n\n"
                "EQUACAO REDUZIDA: y = m . x + b, onde b e a "
                "ordenada na origem.\n\n"
                "EQUACAO GERAL: a . x + b . y + c = 0.\n\n"
                "RETA HORIZONTAL: m = 0. Reta vertical: inclinacao "
                "nao definida.\n\n"
                "PARALELISMO: duas retas sao paralelas se m1 = m2.\n\n"
                "PERPENDICULARIDADE: m1 . m2 = -1 (se nenhuma "
                "for vertical)."
            ),
            "exemplo": (
                "A relacao entre dose de medicamento e tempo de "
                "absorcao pode ser linear. Se apos 1 hora a "
                "concentracao no sangue e 20 mg/L e apos 3 "
                "horas e 60 mg/L, o coeficiente angular e "
                "m = (60 - 20)/(3 - 1) = 20 mg/L por hora. "
                "A equacao e y = 20 . x."
            ),
        },
        {
            "titulo": "3. Circunferencia",
    "conteudo": (
                "EQUACAO REDUZIDA: (x - a)^2 + (y - b)^2 = r^2, "
                "onde (a,b) e o centro e r o raio.\n\n"
                "EQUACAO GERAL: x^2 + y^2 - 2.a.x - 2.b.y + "
                "(a^2 + b^2 - r^2) = 0.\n\n"
                "POSICAO RELATIVA DE RETA E CIRCUNFERENCIA: "
                "calcula a distancia do centro a reta. Se for "
                "menor que r, a reta e secante; igual, tangente; "
                "maior, externa.\n\n"
                "APLICACOES: delimitacao de zonas, modelagem de "
                "ondas, robotica."
            ),
            "exemplo": (
                "Uma zona de abrangencia de um hospital pode ser "
                "modelada por uma circunferencia de centro na "
                "unidade e raio de 5 km. A equacao e "
                "(x - 2)^2 + (y - 3)^2 = 25. Um paciente em "
                "(5,7) esta fora da zona, pois "
                "(5-2)^2 + (7-3)^2 = 9 + 16 = 25, ou seja, "
                "exatamente na fronteira."
            ),
        },
    ],
    "resumo": (
        "- Distancia entre pontos: raiz((x2-x1)^2 + (y2-y1)^2).\n"
        "- Ponto medio: media das coordenadas.\n"
        "- Coeficiente angular: m = (y2-y1)/(x2-x1).\n"
        "- Reta: y = m.x + b.\n"
        "- Paralelas: m1 = m2. Perpendiculares: m1.m2 = -1.\n"
        "- Circunferencia: (x-a)^2 + (y-b)^2 = r^2."
    ),
    "dicas": [
        "Sempre coloque as coordenadas na formula na ordem correta.",
        "O coeficiente angular e a 'inclinacao' da reta.",
        "Reta horizontal tem m = 0; reta vertical nao tem m definido.",
        "Na circunferencia, (a,b) e o centro e r e o raio.",
        "Para saber se um ponto esta dentro da circunferencia, substitua e verifique se e menor que r^2.",
        "Distancia de ponto a reta: |a.x0 + b.y0 + c| / raiz(a^2 + b^2).",
    ],
    "pegadinhas": [
        "Trocar x e y no plano cartesiano.",
        "Esquecer que m1 . m2 = -1 para retas perpendiculares, nao m1 = -m2.",
        "Confundir centro (a,b) com um ponto da circunferencia.",
        "Achar que retas verticais tem m = 0: elas nao tem m.",
        "Esquecer de elevar ao quadrado na formula da distancia.",
        "Na equacao geral da circunferencia, confundir sinais dos termos lineares.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_GEO_ANALITICA = [
    {"file": "mat_geo_analitica.png", "caption": "Plano cartesiano e equacao da reta", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (MATRIZES, "MT_MATRIZES_SISTEMAS.pdf", IMG_MATRIZES, "Matematica — Matrizes e Sistemas"),
        (TRIGONOMETRIA, "MT_TRIGONOMETRIA.pdf", IMG_TRIGONOMETRIA, "Matematica — Trigonometria"),
        (COMBINATORIA, "MT_ANALISE_COMBINATORIA.pdf", IMG_COMBINATORIA, "Matematica — Analise Combinatoria"),
        (ESTATISTICA, "MT_ESTATISTICA_PROBABILIDADE.pdf", IMG_ESTATISTICA, "Matematica — Estatistica e Probabilidade"),
        (GEO_ANALITICA, "MT_GEOMETRIA_ANALITICA.pdf", IMG_GEO_ANALITICA, "Matematica — Geometria Analitica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
