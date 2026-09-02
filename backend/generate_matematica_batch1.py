"""Gera PDFs de Matematica — batch 1 (topicos 4.1 a 4.5)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 4.1 Aritmetica
# ============================================================
ARITMETICA = {
    "titulo": "Aritmética",
    "disciplina": "Matemática",
    "topico": "Aritmetica",
    "subtopico": "Numeros, operacoes, fracoes, porcentagens e regra de tres",
    "introducao": (
        "A Aritmetica e o ramo da Matematica que estuda as "
        "operacoes com numeros e suas aplicacoes do dia a dia, como "
        "fracoes, porcentagens, juros e regra de tres."
    ),
    "secoes": [
        {
            "titulo": "1. Numeros e operacoes fundamentais",
    "conteudo": (
                "CONJUNTOS NUMERICOS:\n"
                "- Naturais: 0, 1, 2, 3, ...\n"
                "- Inteiros: ..., -2, -1, 0, 1, 2, ...\n"
                "- Racionais: fracoes p/q, com q diferente de zero.\n"
                "- Irracionais: numeros com representacao decimal "
                "infinita e nao periodica, como raiz de 2 e pi.\n"
                "- Reais: uniao dos racionais e irracionais.\n\n"
                "OPERACOES: adicao, subtracao, multiplicacao e "
                "divisao. Ordem das operacoes: parenteses, "
                "potencias, multiplicacao/divisao, "
                "adicao/subtracao.\n\n"
                "PROPRIEDADES:\n"
                "- Comutativa: a + b = b + a; a . b = b . a\n"
                "- Associativa: (a + b) + c = a + (b + c)\n"
                "- Distributiva: a . (b + c) = a . b + a . c\n"
                "- Elemento neutro: a + 0 = a; a . 1 = a"
            ),
            "exemplo": (
                "Uma pessoa toma 1/2 de um comprimido pela manha e "
                "1/4 a noite. O total por dia e 1/2 + 1/4. Reduzindo "
                "ao mesmo denominador: 2/4 + 1/4 = 3/4 de comprimido. "
                "Se a cartela tem 12 comprimidos, isso da 12 dividido "
                "por 3/4 = 16 dias de tratamento."
            ),
        },
        {
            "titulo": "2. Fracoes, porcentagens e razoes",
            "conteudo": (
                "FRACAO: representa parte de um inteiro. Numerador "
                "sobre denominador.\n\n"
                "OPERACOES COM FRACOES:\n"
                "- Soma/subtracao: mesmo denominador.\n"
                "- Multiplicacao: numerador vezes numerador e "
                "denominador vezes denominador.\n"
                "- Divisao: multiplica pela inversa.\n\n"
                "PORCENTAGEM: razao de denominador 100. 25% = 25/100 "
                "= 0,25 = 1/4.\n\n"
                "JUROS SIMPLES: J = C . i . t, onde C e o capital, "
                "i a taxa e t o tempo.\n\n"
                "JUROS COMPOSTOS: M = C . (1 + i)^t, onde M e o "
                "montante."
            ),
            "exemplo": (
                "Um remedio custa 80 reais e o plano de saude cobre "
                "70%. O paciente paga 30% do valor: 0,30 . 80 = "
                "24 reais. Se o remédio teve um reajuste de 10% no "
                "mes seguinte, o novo preco e 80 . 1,10 = 88 reais. "
                "A participacao do paciente passa a ser 0,30 . 88 = "
                "26,40 reais."
            ),
        },
        {
            "titulo": "3. Regra de tres e grandezas proporcionais",
            "conteudo": (
                "REGRA DE TRES SIMPLES: usada quando duas grandezas "
                "sao diretamente proporcionais. Monta-se a proporcao "
                "e resolve.\n\n"
                "REGRA DE TRES COMPOSTA: envolve tres ou mais "
                "grandezas. Deve-se verificar quais sao diretamente "
                "proporcionais e quais inversamente.\n\n"
                "GRANDEZAS DIRETAMENTE PROPORCIONAIS: quando uma "
                "aumenta, a outra aumenta na mesma proporcao.\n\n"
                "GRANDEZAS INVERSAMENTE PROPORCIONAIS: quando uma "
                "aumenta, a outra diminui na mesma proporcao.\n\n"
                "ESCALA: razao entre a medida do desenho e a medida "
                "real. Escala 1:10000 significa 1 cm no desenho = "
                "10000 cm na realidade."
            ),
            "exemplo": (
                "Se 4 enfermeiras atendem 60 pacientes em 3 horas, "
                "quantas atendem 90 pacientes no mesmo tempo? A "
                "regra de tres e: 4 enfermeiras --- 60 pacientes; "
                "x --- 90 pacientes. Diretamente proporcional: "
                "x = 4 . 90 / 60 = 6 enfermeiras."
            ),
        },
    ],
    "resumo": (
        "- Numeros: naturais, inteiros, racionais, irracionais, reais.\n"
        "- Fracoes: soma com mesmo denominador, divisao multiplica pela inversa.\n"
        "- Porcentagem: a% = a/100. Juros simples: J = C.i.t.\n"
        "- Juros compostos: M = C.(1 + i)^t.\n"
        "- Regra de tres: monte a proporcao e iguale os produtos.\n"
        "- Grandezas diretamente e inversamente proporcionais."
    ),
    "dicas": [
        "Para somar fracoes, primeiro iguale os denominadores.",
        "Porcentagem e so uma fracao de denominador 100.",
        "Juros simples: o juro e igual a cada periodo. Juros compostos: juros sobre juros.",
        "Em regra de tres, verifique se as grandezas sao diretas ou inversas antes de montar.",
        "1% = 0,01. 10% = 0,10. 50% = 0,5.",
        "Na escala, a ordem e desenho : real.",
    ],
    "pegadinhas": [
        "Somar fracoes com denominadores diferentes sem reduzir.",
        "Esquecer que dividir por fracao e o mesmo que multiplicar pela inversa.",
        "Confundir juros simples com compostos: compostos crescem mais rapido.",
        "Achar que a% de b e b% de a sao iguais: sao iguais.",
        "Esquecer de converter porcentagem para decimal em formulas.",
        "Em escala, trocar a ordem desenho/real.",
    ],
    "referencias": [
        "DANTE, L. R. Matematica: contexto e aplicacoes. Sao Paulo: Atica, 2018.",
        "IEZZI, G.; MURAKAMI, C. Fundamentos de Matematica Elementar. 11. ed. Sao Paulo: Atual, 2013.",
        "PAIVA, M. R. Matematica. 2. ed. Sao Paulo: Moderna, 2010.",
        "SMOLE, K. S.; DINIZ, M. I. Matematica Ensino Medio. 6. ed. Sao Paulo: Saraiva, 2009.",
        "LIMA, E. L. et al. Matematica do Ensino Medio. 3. ed. Rio de Janeiro: SBM, 2006.",
        "RIBEIRO, J. U. Matematica. 5. ed. Sao Paulo: Scipione, 2010.",
    ],
}

IMG_ARITMETICA = [
    {"file": "mat_aritmetica.png", "caption": "Porcentagem e fracao: 25% equivale a 1/4", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.2 Conjuntos
# ============================================================
CONJUNTOS = {
    "titulo": "Conjuntos",
    "disciplina": "Matemática",
    "topico": "Conjuntos",
    "subtopico": "Operacoes, representacao e problemas de contagem",
    "introducao": (
        "A Teoria dos Conjuntos e a base para organizar e "
        "classificar elementos. Conjuntos sao colecoes de objetos "
        "bem definidos, e suas operacoes aparecem em muitos "
        "problemas de logica e contagem."
    ),
    "secoes": [
        {
            "titulo": "1. Representacao e subconjuntos",
            "conteudo": (
                "CONJUNTO: colecao de elementos. Representacoes: "
                "por extenso (A = {1, 2, 3}), por propriedade "
                "(A = {x | x e numero inteiro e 1 <= x <= 3}) ou "
                "pelo diagrama de Venn.\n\n"
                "PERTINENCIA: x pertence a A (x in A) ou nao "
                "pertence (x not in A).\n\n"
                "SUBCONJUNTO: A esta contido em B (A c B) se todo "
                "elemento de A tambem e de B.\n\n"
                "CONJUNTO VAZIO: nao tem elementos, simbolo 0/.\n\n"
                "CONJUNTO UNIVERSO: contem todos os elementos "
                "considerados em um problema."
            ),
            "exemplo": (
                "Em um prontuario, A = {pacientes diabeticos} e "
                "B = {pacientes hipertensos}. Se um paciente esta "
                "em A e tambem em B, ele pertence a intersecao "
                "A inter B. Medicos frequentemente precisam contar "
                "quantos pacientes tem ambas as doencas, apenas uma "
                "ou nenhuma, usando diagramas de Venn."
            ),
        },
        {
            "titulo": "2. Uniao, intersecao e diferenca",
            "conteudo": (
                "UNIAO (A u B): elementos que estao em A ou em B.\n\n"
                "INTERSECCAO (A inter B): elementos que estao em A "
                "e em B.\n\n"
                "DIFERENCA (A - B): elementos de A que nao estao "
                "em B.\n\n"
                "COMPLEMENTAR: A^c contem os elementos do universo "
                "que nao estao em A.\n\n"
                "PRINCIPIO DA INCLUSAO-EXCLUSAO:\n"
                "n(A u B) = n(A) + n(B) - n(A inter B).\n\n"
                "Para tres conjuntos:\n"
                "n(A u B u C) = n(A) + n(B) + n(C) - n(A inter B) "
                "- n(A inter C) - n(B inter C) + n(A inter B inter C)."
            ),
            "exemplo": (
                "Em 100 pacientes, 60 tem febre (A) e 40 tem dor "
                "de cabeca (B). Se 20 tem ambos, quantos tem pelo "
                "menos um dos sintomas? n(A u B) = 60 + 40 - 20 "
                "= 80 pacientes. Os que nao tem nenhum sintoma "
                "sao 100 - 80 = 20 pacientes."
            ),
        },
        {
            "titulo": "3. Conjuntos numericos e intervalos",
            "conteudo": (
                "CONJUNTOS NUMERICOS:\n"
                "- N: naturais (0, 1, 2, ...)\n"
                "- Z: inteiros (... -2, -1, 0, 1, ...)\n"
                "- Q: racionais (p/q, q != 0)\n"
                "- R: reais (Q + irracionais)\n\n"
                "INTERVALOS:\n"
                "- Fechado [a, b]: a <= x <= b\n"
                "- Aberto (a, b): a < x < b\n"
                "- Semiaberto [a, b) ou (a, b]\n"
                "- Infinito: (-infinito, a] ou [a, +infinito)\n\n"
                "OPERACOES COM INTERVALOS: uniao e intersecao, "
                "usando a reta numerica."
            ),
            "exemplo": (
                "Uma dose segura de medicamento esta entre 10 mg e "
                "20 mg, incluindo 10 e excluindo 20. Em intervalos, "
                "e [10, 20). Se uma ampola tem 15 mg, a dose esta "
                "dentro do intervalo. Se tem 20 mg, nao esta, pois "
                "20 nao e incluido."
            ),
        },
    ],
    "resumo": (
        "- Conjunto: colecao de elementos. Representacao por extenso, propriedade ou Venn.\n"
        "- Uniao: A u B. Intersecao: A inter B. Diferenca: A - B.\n"
        "- n(A u B) = n(A) + n(B) - n(A inter B).\n"
        "- Complementar: elementos fora do conjunto, no universo.\n"
        "- Conjuntos numericos: N, Z, Q, R.\n"
        "- Intervalos: [a,b], (a,b), [a,b), semiabertos e infinitos."
    ),
    "dicas": [
        "Pertinencia e para elementos; continencia e para conjuntos.",
        "Na uniao, nao repita elementos comuns.",
        "Para calcular complementar, use o numero total de elementos do universo.",
        "Na reta numerica, intersecao e a parte comum; uniao e a parte pintada.",
        "Intervalo fechado inclui os extremos; aberto nao inclui.",
        "Problemas de contagem: faca o diagrama de Venn antes de calcular.",
    ],
    "pegadinhas": [
        "Confundir A u B com A inter B.",
        "Esquecer de subtrair a intersecao na formula da uniao.",
        "Achar que 0/ e subconjunto de qualquer conjunto: ele e subconjunto de todos, mas nao elemento.",
        "Trocar inclusao de extremos em intervalos.",
        "Usar pertinencia em vez de continencia para conjuntos.",
        "Esquecer de adicionar de volta n(A inter B inter C) na formula de 3 conjuntos.",
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

IMG_CONJUNTOS = [
    {"file": "mat_conjuntos.png", "caption": "Diagrama de Venn: uniao e intersecao de conjuntos", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.3 Funcoes
# ============================================================
FUNCOES = {
    "titulo": "Funções",
    "disciplina": "Matemática",
    "topico": "Funcoes",
    "subtopico": "Definicao, dominio, imagem, funcoes do 1o e 2o graus",
    "introducao": (
        "Funcao e uma relacao entre dois conjuntos em que cada "
        "elemento do primeiro conjunto esta associado a um unico "
        "elemento do segundo. Funcoes descrevem fenomenos da saude, "
        "como crescimento, dosagem e metabolismo."
    ),
    "secoes": [
        {
            "titulo": "1. Conceitos de funcao",
            "conteudo": (
                "DEFINICAO: uma funcao f de A em B associa cada "
                "elemento x de A a um unico elemento y de B. "
                "Escrevemos y = f(x).\n\n"
                "DOMINIO (D): conjunto dos valores que x pode assumir.\n\n"
                "CONTRADOMINIO: conjunto B, onde podem estar os "
                "valores de y.\n\n"
                "IMAGEM (Im): valores de y que realmente sao atingidos.\n\n"
                "CRITERIO DE UMA FUNCAO: cada x deve ter um unico "
                "y. Se um x tiver dois y, nao e funcao."
            ),
            "exemplo": (
                "A dose de um antibiotico pode ser modelada por "
                "uma funcao: dose (mg) em funcao do peso (kg). Se "
                "a dose e 10 mg por kg, entao f(x) = 10.x. Uma "
                "crianca de 25 kg recebe f(25) = 250 mg. Nao e "
                "permitido que o mesmo peso leve a duas doses "
                "diferentes."
            ),
        },
        {
            "titulo": "2. Funcao do 1o grau",
            "conteudo": (
                "DEFINICAO: f(x) = a.x + b, onde a e b sao numeros "
                "reais e a != 0.\n\n"
                "GRAFICO: reta. O coeficiente a e a inclinacao "
                "(coeficiente angular). Quanto maior a, mais "
                "inclinada. Se a > 0, a funcao e crescente; se "
                "a < 0, e decrescente.\n\n"
                "COEFICIENTE b: ordenada na origem, valor de f(0).\n\n"
                "RAIZ: valor de x tal que f(x) = 0. "
                "x = -b/a.\n\n"
                "Aplicacao: relacoes lineares como custo em "
                "funcao da quantidade, deslocamento em funcao do "
                "tempo, dose em funcao do peso."
            ),
            "exemplo": (
                "A quantidade de insulina em funcao da glicemia "
                "pode ser aproximada por uma funcao do 1o grau. "
                "Se f(g) = 0,5 . g - 80, para glicemia g = 180 "
                "mg/dL, f(180) = 0,5 . 180 - 80 = 90 - 80 = 10 "
                "unidades de insulina. O endocrinologista ajusta "
                "os coeficientes a e b para cada paciente."
            ),
        },
        {
            "titulo": "3. Funcao do 2o grau",
            "conteudo": (
                "DEFINICAO: f(x) = a.x^2 + b.x + c, com a != 0.\n\n"
                "GRAFICO: parabola. Se a > 0, a concavidade e "
                "para cima; se a < 0, para baixo.\n\n"
                "VERTICE: ponto de maximo ou minimo. "
                "x_v = -b/(2.a); y_v = f(x_v).\n\n"
                "RAIZES: valores onde f(x) = 0. Formula de "
                "Bhaskara: x = (-b +- raiz de (b^2 - 4.a.c)) / (2.a).\n\n"
                "DISCRIMINANTE: Delta = b^2 - 4.a.c. Se Delta > 0, "
                "duas raizes; Delta = 0, uma raiz; Delta < 0, "
                "nenhuma raiz real."
            ),
            "exemplo": (
                "A altura de um projetil lancado para cima e dada "
                "por h(t) = -5.t^2 + 20.t. O tempo de subida ate o "
                "vertice e t = -20/(2 . (-5)) = 2 s. A altura "
                "maxima e h(2) = -5 . 4 + 20 . 2 = -20 + 40 = 20 m. "
                "Essa modelagem quadratica aparece em biomecanica "
                "e estudos de movimento."
            ),
        },
    ],
    "resumo": (
        "- Funcao: cada x tem um unico y. Dominio, contradominio, imagem.\n"
        "- 1o grau: f(x) = a.x + b. Grafico e reta. Raiz: x = -b/a.\n"
        "- 2o grau: f(x) = a.x^2 + b.x + c. Grafico e parabola.\n"
        "- Vertice: x_v = -b/(2.a); y_v = f(x_v).\n"
        "- Bhaskara: x = (-b +- raiz(Delta))/(2.a), Delta = b^2 - 4.a.c.\n"
        "- Delta: > 0 duas raizes, = 0 uma, < 0 nenhuma real."
    ),
    "dicas": [
        "Na funcao do 1o grau, a inclinacao da reta e o valor de a.",
        "Se a > 0, a funcao e crescente; se a < 0, e decrescente.",
        "Na parabola, se a > 0, o vertice e ponto de minimo; se a < 0, e ponto de maximo.",
        "Sempre calcule o Delta antes de aplicar Bhaskara.",
        "O vertice e o ponto mais alto ou mais baixo da parabola.",
        "Raiz e onde o grafico corta o eixo x, ou seja, f(x) = 0.",
    ],
    "pegadinhas": [
        "Achar que toda relacao e funcao: precisa de um unico y para cada x.",
        "Confundir dominio com imagem: dominio e o x; imagem e o y realmente atingido.",
        "Esquecer que, na funcao do 1o grau, a = 0 nao e permitido.",
        "Aplicar Bhaskara sem calcular o Delta.",
        "Esquecer de verificar o sinal de a na concavidade da parabola.",
        "Confundir o vertice com a raiz: vertice e maximo/minimo; raiz e f(x)=0.",
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

IMG_FUNCOES = [
    {"file": "mat_funcoes.png", "caption": "Grafico de funcao do 1o grau: f(x) = a.x + b", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.4 Geometria Plana
# ============================================================
GEO_PLANA = {
    "titulo": "Geometria Plana",
    "disciplina": "Matemática",
    "topico": "Geometria Plana",
    "subtopico": "Triangulos, quadrilateros, circunferencias e areas",
    "introducao": (
        "Geometria Plana estuda figuras em duas dimensoes. Area, "
        "perimetro, angulos e semelhanca sao conceitos centrais "
        "para resolver problemas praticos."
    ),
    "secoes": [
        {
            "titulo": "1. Triangulos e quadrilateros",
            "conteudo": (
                "TRIANGULOS: poligonos de tres lados. Soma dos "
                "angulos internos: 180 graus. Classificam-se por "
                "lados (equilatero, isosceles, escaleno) e por "
                "angulos (acutangulo, retangulo, obtusangulo).\n\n"
                "TEOREMA DE PITAGORAS: em um triangulo retangulo, "
                "a^2 + b^2 = c^2, onde c e a hipotenusa.\n\n"
                "QUADRILATEROS: quatro lados. Paralelogramos: "
                "lados opostos paralelos (retangulo, quadrado, "
                "losango, paralelogramo).\n\n"
                "TRAPEZIOS: ao menos um par de lados paralelos. "
                "Area do trapezio: (B + b) . h / 2."
            ),
            "exemplo": (
                "Uma rampa de acesso a maca forma um triangulo "
                "retangulo. Se a rampa tem 5 m de comprimento e "
                "3 m de base, a altura e h = raiz(5^2 - 3^2) = "
                "raiz(25 - 9) = raiz(16) = 4 m. Isso ajuda a "
                "verificar se a inclinacao e segura para subir "
                "pacientes."
            ),
        },
        {
            "titulo": "2. Circunferencia e circulo",
            "conteudo": (
                "CIRCUNFERENCIA: contorno. Comprimento: C = 2.pi.r.\n\n"
                "CIRCULO: superficie limitada pela circunferencia. "
                "Area: A = pi . r^2.\n\n"
                "ANGULOS NA CIRCUNFERENCIA:\n"
                "- Angulo central: mede o arco.\n"
                "- Angulo inscrito: metade do arco.\n"
                "- Angulo do segmento: metade da diferenca dos arcos.\n\n"
                "SETOR CIRCULAR: area de uma fatia de circulo. "
                "A = (teta / 360) . pi . r^2.\n\n"
                "VALOR DE pi: aproximadamente 3,14 ou 22/7."
            ),
            "exemplo": (
                "A area de um curativo circular de raio 3 cm e "
                "A = pi . 3^2 = 3,14 . 9 = 28,26 cm^2. Isso "
                "ajuda a calcular a quantidade de gaze ou filme "
                "transparente necessario para cobrir uma ferida "
                "de formato aproximadamente circular."
            ),
        },
        {
            "titulo": "3. Semelhanca e teorema de Tales",
            "conteudo": (
                "POLIGONOS SEMELHANTES: angulos iguais e lados "
                "proporcionais. A razao entre lados e o "
                "coeficiente de proporcionalidade k.\n\n"
                "TEOREMA DE TALES: retas paralelas cortadas por "
                "transversais produzem segmentos proporcionais.\n\n"
                "APLICACOES: escala de mapas, ampliacao e "
                "reducao de imagens, triangulos semelhantes.\n\n"
                "TRIANGULOS RETANGULOS SEMELHANTES: altura relativa "
                "a hipotenusa gera tres triangulos semelhantes. "
                "Relacoes metricas: h^2 = m . n; a^2 = m . c; "
                "b^2 = n . c."
            ),
            "exemplo": (
                "Em radiologia, uma radiografia e uma ampliacao "
                "semelhante do corpo. Se uma vertebra mede 3 cm na "
                "imagem e a escala e 1,5:1, a vertebra real mede "
                "3 / 1,5 = 2 cm. A proporcionalidade e usada para "
                "medir tumores, fraturas e orgaos em exames de "
                "imagem."
            ),
        },
    ],
    "resumo": (
        "- Soma dos angulos internos de um triangulo: 180 graus.\n"
        "- Pitagoras: a^2 + b^2 = c^2.\n"
        "- Area do retangulo: b . h. Area do triangulo: (b . h)/2.\n"
        "- Circulo: area = pi . r^2; comprimento = 2 . pi . r.\n"
        "- Setor circular: A = (teta/360) . pi . r^2.\n"
        "- Semelhanca: angulos iguais e lados proporcionais. Teorema de Tales."
    ),
    "dicas": [
        "Area de triangulo e metade da area de um retangulo com mesma base e altura.",
        "Pitagoras so vale para triangulos retangulos.",
        "Circunferencia e o contorno; circulo e a area interna.",
        "Semelhanca preserva angulos e lados na mesma proporcao.",
        "Teorema de Tales: retas paralelas cortadas por transversais dao segmentos proporcionais.",
        "Area do trapezio: (base maior + base menor) . altura / 2.",
    ],
    "pegadinhas": [
        "Aplicar Pitagoras em triangulos nao retangulos.",
        "Confundir circunferencia com circulo: contorno x area.",
        "Esquecer de dividir por 2 na area do triangulo.",
        "Achar que poligonos com angulos iguais sao semelhantes: precisam de lados proporcionais tambem.",
        "Esquecer de converter unidades antes de calcular areas.",
        "Usar o raio errado no circulo: o diametro e 2.r.",
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

IMG_GEO_PLANA = [
    {"file": "mat_geo_plana.png", "caption": "Areas de figuras planas: triangulo e retangulo", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 4.5 Geometria Espacial
# ============================================================
GEO_ESPACIAL = {
    "titulo": "Geometria Espacial",
    "disciplina": "Matemática",
    "topico": "Geometria Espacial",
    "subtopico": "Poliedros, prismas, piramides, cilindro, cone, esfera",
    "introducao": (
        "Geometria Espacial estuda figuras em tres dimensoes. "
        "Comprimento, area e volume sao usados para calcular "
        "capacidade, cobertura e espaco."
    ),
    "secoes": [
        {
            "titulo": "1. Poliedros e solidos redondos",
            "conteudo": (
                "POLIEDROS: solidos limitados por poligonos. Faces, "
                "arestas e vertices. Relacao de Euler: V - A + F = 2, "
                "para poliedros convexos.\n\n"
                "PRISMAS: bases paralelas e congruentes. Volume: "
                "V = A_base . h.\n\n"
                "PIRAMIDES: base poligonal e vertice. Volume: "
                "V = (A_base . h) / 3.\n\n"
                "CILINDRO: bases circulares. Volume: "
                "V = pi . r^2 . h. Area lateral: 2 . pi . r . h.\n\n"
                "CONE: base circular e vertice. Volume: "
                "V = (pi . r^2 . h) / 3.\n\n"
                "ESFERA: Volume: (4/3) . pi . r^3. Area: 4 . pi . r^2."
            ),
            "exemplo": (
                "Um reservatorio cilindrico de agua para hospital "
                "tem raio 2 m e altura 5 m. O volume e "
                "V = pi . 2^2 . 5 = 3,14 . 4 . 5 = 62,8 m^3, "
                "ou 62.800 litros. Isso define a autonomia de "
                "abastecimento em caso de falta de agua."
            ),
        },
        {
            "titulo": "2. Areas e volumes",
    "conteudo": (
                "AREA TOTAL: soma das areas de todas as faces.\n\n"
                "AREA LATERAL: area das faces laterais, sem as "
                "bases.\n\n"
                "VOLUME: espaco ocupado pelo solido. Medido em "
                "unidades cubicas (m^3, cm^3, litro = dm^3).\n\n"
                "RELACAO VOLUME-CAPACIDADE: 1 litro = 1 dm^3 = "
                "1000 cm^3. 1 m^3 = 1000 litros.\n\n"
                "CUBO: aresta a. Volume = a^3. Area total = 6 . a^2.\n\n"
                "PARALELEPIPEDO RETANGULO: dimensoes a, b, c. "
                "Volume = a . b . c."
            ),
            "exemplo": (
                "Uma caixa de isopor para transportar vacinas mede "
                "40 cm x 30 cm x 20 cm. O volume e "
                "40 . 30 . 20 = 24.000 cm^3 = 24 litros. Se cada "
                "frasco ocupa 0,5 litro, cabem 48 frascos na caixa. "
                "Esse calculo e essencial para logistica de vacinacao."
            ),
        },
        {
            "titulo": "3. Inscricao e circunscricao",
            "conteudo": (
                "INSCRICAO: um solido esta inscrito em outro quando "
                "suas faces tangenciam internamente o outro.\n\n"
                "CIRCUNSCRICAO: um solido esta circunscrito quando "
                "contem outro tangenciando suas faces.\n\n"
                "RELACOES COMUNS:\n"
                "- Cubo inscrito em esfera: diagonal do cubo e o "
                "diametro da esfera. D = a.raiz(3).\n"
                "- Esfera inscrita em cubo: diametro da esfera e "
                "igual a aresta do cubo.\n"
                "- Cilindro inscrito em esfera: h^2 + (2r)^2 = D^2, "
                "onde D e o diametro da esfera."
            ),
            "exemplo": (
                "Uma capsula esferica inscrita em um cubo de aresta "
                "1 cm tem diametro 1 cm, entao raio 0,5 cm. O "
                "volume da capsula e (4/3) . pi . (0,5)^3 = "
                "(4/3) . 3,14 . 0,125 = 0,52 cm^3. Esse tipo de "
                "calculo aparece na fabricacao de comprimidos e "
                "capsulas farmaceuticas."
            ),
        },
    ],
    "resumo": (
        "- Prisma: V = A_base . h. Piramide: V = (A_base . h)/3.\n"
        "- Cilindro: V = pi . r^2 . h.\n"
        "- Cone: V = (pi . r^2 . h)/3.\n"
        "- Esfera: V = (4/3) . pi . r^3; area = 4 . pi . r^2.\n"
        "- Relacao de Euler: V - A + F = 2.\n"
        "- 1 litro = 1 dm^3 = 1000 cm^3; 1 m^3 = 1000 litros."
    ),
    "dicas": [
        "Volume de piramide e cone e 1/3 do volume do prisma/cilindro com mesma base e altura.",
        "Area total inclui as bases; area lateral nao inclui.",
        "Relacao de Euler so vale para poliedros convexos.",
        "Cubo: diagonal da face = a.raiz(2); diagonal do cubo = a.raiz(3).",
        "Esfera inscrita no cubo: raio = a/2.",
        "Conversao: metro cubico para litro: multiplique por 1000.",
    ],
    "pegadinhas": [
        "Confundir area com volume: area e em m^2, volume em m^3.",
        "Esquecer que volume da piramide e cone tem o divisor 3.",
        "Aplicar a relacao de Euler em poliedros nao convexos.",
        "Usar raio em vez de diametro em inscricoes.",
        "Esquecer a conversao de litro para metro cubico.",
        "Confundir cilindro com cone: cone tem vertice, cilindro nao.",
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

IMG_GEO_ESPACIAL = [
    {"file": "mat_geo_espacial.png", "caption": "Volumes de solidos: cubo e cilindro", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (ARITMETICA, "MT_ARITMETICA.pdf", IMG_ARITMETICA, "Matematica — Aritmetica"),
        (CONJUNTOS, "MT_CONJUNTOS.pdf", IMG_CONJUNTOS, "Matematica — Conjuntos"),
        (FUNCOES, "MT_FUNCOES.pdf", IMG_FUNCOES, "Matematica — Funcoes"),
        (GEO_PLANA, "MT_GEOMETRIA_PLANA.pdf", IMG_GEO_PLANA, "Matematica — Geometria Plana"),
        (GEO_ESPACIAL, "MT_GEOMETRIA_ESPACIAL.pdf", IMG_GEO_ESPACIAL, "Matematica — Geometria Espacial"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
