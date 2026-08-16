# -*- coding: utf-8 -*-
"""Gera PDFs de Filosofia — batch 1 (topicos 10.1 a 10.4)."""

from pdf_base import generate_educational_pdf
from filosofia_real_images import REAL_IMAGES

# ============================================================
# 10.1 Cultura
# ============================================================
CULTURA = {
    "titulo": "Cultura",
    "disciplina": "Filosofia",
    "topico": "Cultura",
    "subtopico": "Natureza, trabalho, ordem simbolica, religiosidade e morte",
    "introducao": (
        "A cultura e o conjunto de praticas, valores e simbolos "
        "que organizam a vida humana. Distingue-se da natureza "
        "como o construido se distingue do dado. O ser humano "
        "e um ser cultural por excelencia."
    ),
    "secoes": [
        {
            "titulo": "1. Natureza e cultura, cultura e trabalho",
            "conteudo": (
                "NATUREZA: o dado, o natural, o instintivo. "
                "Comum a todos os seres vivos.\n\n"
                "CULTURA: o construido, o aprendido, o simbolico. "
                "Especifico de cada sociedade.\n\n"
                "FRONTEIRA: tabu do incesto e linguagem sao "
                "universais culturais (Levi-Strauss). Marcam a "
                "passagem da natureza a cultura.\n\n"
                "CULTURA E TRABALHO: o trabalho transforma a "
                "natureza em cultura. Marx: o trabalho alienado "
                "separa o homem de sua essencia. A tecnica e "
                "expressao cultural.\n\n"
                "CULTURA MATERIAL E IMATERIAL: objetos, artefatos "
                "(material) e valores, ideias, simbolos (imaterial)."
            ),
            "exemplo": (
                "O ser humano nao tem instinto suficiente para "
                "sobreviver: precisa aprender. Um bebe humano "
                "abandonado nao sobrevive sozinho, enquanto "
                "animais tem instintos programados. Isso mostra "
                "que a cultura e nossa 'segunda natureza': "
                "precisamos dela para viver."
            ),
        },
        {
            "titulo": "2. Sentidos de cultura e ordem simbolica",
            "conteudo": (
                "SENTIDOS DE CULTURA:\n"
                "- Antropologico: modo de vida de um povo.\n"
                "- Estetico: artes, belles-lettres.\n"
                "- Sociologico: valores, normas, costumes.\n"
                "- Filosofico: formacao do espirito (paideia).\n\n"
                "CULTURA POPULAR x ERUDITA: popular (do povo, "
                "massa) x erudita (elite, refinada). Distincao "
                "questionada por Bourdieu: o gosto e de classe.\n\n"
                "ORDEM SIMBOLICA: a cultura organiza o real "
                "atraves de simbolos. Linguagem, mito, rito sao "
                "sistemas simbolicos (Levi-Strauss). O simbolo "
                "remete a algo ausente."
            ),
            "exemplo": (
                "Bourdieu mostrou que o gosto cultural nao e "
                "natural: e aprendido conforme a classe social. "
                "Ouvir musica classica ou forro nao e questao de "
                "gosto pessoal, mas de origem social. Isso "
                "questiona a distincao entre cultura 'superior' "
                "e 'inferior'."
            ),
        },
        {
            "titulo": "3. Religiosidade, o sagrado e a morte",
            "conteudo": (
                "RELIGIOSIDADE E SAGRADO:\n"
                "- Durkheim: profano x sagrado. Religiao e fato "
                "social.\n"
                "- Mito: narrativa sagrada que explica a origem.\n"
                "- Rito: acao simbolica que atualiza o mito.\n"
                "- Tabu, totem, sacrificio: formas do sagrado.\n"
                "- Secularizacao: modernidade reduz o religioso.\n\n"
                "A MORTE:\n"
                "- Universal e cultural: todos morrem, mas cada "
                "cultura ritualiza a morte.\n"
                "- Rituais funerarios: presentes desde o "
                "Neandertal.\n"
                "- Kubler-Ross: 5 fases do luto: negacao, raiva, "
                "barganha, depressao, aceitacao.\n"
                "- Morte no ocidente: medicalizada, escondida."
            ),
            "exemplo": (
                "Os rituais funerarios egipcios (mumificacao) "
                "mostram que a morte nao e so um fato biologico, "
                "mas cultural. Os egipcios preparavam o corpo "
                "para a vida apos a morte, com objetos e "
                "amuletos. Isso revela como a cultura organiza "
                "ate mesmo a morte."
            ),
        },
    ],
    "resumo": (
        "- Natureza: o dado. Cultura: o construido.\n"
        "- Tabu do incesto e linguagem: universais culturais.\n"
        "- Trabalho transforma natureza em cultura.\n"
        "- Sentidos: antropologico, estetico, sociologico, filosofico.\n"
        "- Ordem simbolica: linguagem, mito, rito (Levi-Strauss).\n"
        "- Sagrado x profano (Durkheim). Morte: universal e cultural."
    ),
    "dicas": [
        "Cultura = segunda natureza: precisamos dela para viver.",
        "Tabu do incesto e a fronteira natureza/cultura (Levi-Strauss).",
        "Bourdieu: gosto cultural e de classe, nao natural.",
        "Durkheim: sagrado x profano estrutura a religiao.",
        "Kubler-Ross: 5 fases do luto (negacao, raiva, barganha, depressao, aceitacao).",
        "Secularizacao: modernidade reduz o espaco do sagrado.",
    ],
    "pegadinhas": [
        "Achar que cultura e so arte: e modo de vida (sentido antropologico).",
        "Confundir cultura popular com cultura inferior: sao diferentes, nao hierarquicas.",
        "Esquecer que o tabu do incesto e universal cultural.",
        "Achar que a morte e so biologica: e tambem cultural.",
        "Confundir sagrado com religiao: sagrado e categoria, religiao e instituicao.",
        "Esquecer que o trabalho e atividade cultural, nao so economica.",
    ],
    "referencias": [
        "COSTA, C. Filosofia: volume unico. Sao Paulo: Moderna, 2013.",
        "ARANHA, M. L. A.; MARTINS, M. H. P. Filosofando. 4. ed. Sao Paulo: Moderna, 2009.",
        "LEVI-STRAUSS, C. Antropologia estrutural. Rio de Janeiro: Tempo Brasileiro, 2008.",
        "DURKHEIM, E. As formas elementares da vida religiosa. Sao Paulo: Martins Fontes, 2008.",
        "BOURDIEU, P. A distincao: critica social do julgamento. Porto Alegre: Zouk, 2007.",
        "KUBLER-ROSS, E. Sobre a morte e o morrer. Sao Paulo: Martins Fontes, 2008.",
    ],
}

IMG_CULTURA = [
    {"file": "filo_cultura.png", "caption": "Cultura: natureza, trabalho e ordem simbolica", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_cultura", [])

# ============================================================
# 10.2 Conhecimento
# ============================================================
CONHECIMENTO = {
    "titulo": "Conhecimento",
    "disciplina": "Filosofia",
    "topico": "Conhecimento",
    "subtopico": "Tipos de conhecimento, epistemologia, ciencia e ideologia",
    "introducao": (
        "O conhecimento e a relacao do sujeito com o objeto. "
        "Existem diferentes tipos de conhecimento e diferentes "
        "teorias sobre o que e verdade e o que e ciencia."
    ),
    "secoes": [
        {
            "titulo": "1. Tipos de conhecimento",
            "conteudo": (
                "SENSO COMUM: conhecimento cotidiano, espontaneo, "
                "baseado na experiencia. Nem sempre sistematico.\n\n"
                "CONHECIMENTO RELIGIOSO: baseado na fe, na "
                "tradicao, em textos sagrados. Nao questiona, "
                "acredita.\n\n"
                "CONHECIMENTO FILOSOFICO: reflexao racional sobre "
                "questoes fundamentais. Sistematico, mas nao "
                "empirico.\n\n"
                "CONHECIMENTO CIENTIFICO: metodo, observacao, "
                "experimentacao, replicabilidade. Objetivo e "
                "sistematico.\n\n"
                "CONHECIMENTO ARTISTICO: intuicao, sensibilidade, "
                "expressao. Subjetivo, mas significativo."
            ),
            "exemplo": (
                "Para entender uma doenca: o senso comum diz 'e "
                "mau-olhado'; o religioso diz 'e castigo divino'; "
                "o filosofico pergunta 'o que e doenca?'; o "
                "cientifico identifica o patogeno e testa "
                "tratamentos; o artistico expressa o sofrimento. "
                "Cada tipo tem seu valor, mas a ciencia e a base "
                "da medicina moderna."
            ),
        },
        {
            "titulo": "2. Correntes epistemologicas e ciencia",
            "conteudo": (
                "EMPIRISMO: conhecimento vem da experiencia "
                "(Locke, Hume). Sentidos sao a base.\n\n"
                "RACIONALISMO: conhecimento vem da razao "
                "(Descartes, Spinoza). Ideias inatas.\n\n"
                "POSITIVISMO: so o fato observavel e cientifico "
                "(Comte). Metodo das ciencias naturais.\n\n"
                "FALSIFICABILIDADE (Popper): uma teoria e "
                "cientifica se pode ser refutada. Pseudociencia "
                "nao pode ser refutada.\n\n"
                "PARADIGMAS (Kuhn): ciencia normal x revoluciones "
                "cientificas. Mudanca de paradigma."
            ),
            "exemplo": (
                "Popper criticou o marxismo e a psicanalise como "
                "pseudociencias: suas teorias nao podem ser "
                "refutadas, pois sempre se ajustam aos fatos. Ja "
                "a teoria da relatividade de Einstein podia ser "
                "refutada por observacoes astronomicas, e por "
                "isso era cientifica."
            ),
        },
        {
            "titulo": "3. Verdade, linguagem e ideologia",
            "conteudo": (
                "VERDADE:\n"
                "- Correspondencia: verdade = fato (Aristoteles).\n"
                "- Coerencia: verdade = sistema logico.\n"
                "- Utilidade: verdade = o que funciona (Pragmatismo).\n"
                "- Hermeneutica: verdade = interpretacao (Gadamer).\n\n"
                "LINGUAGEM E PENSAMENTO:\n"
                "- Linguagem estrutura o pensamento.\n"
                "- Wittgenstein: jogos de linguagem. Significado "
                "depende do uso.\n\n"
                "IDEOLOGIA:\n"
                "- Marx: ideologia = falsa consciencia. Ideias "
                "da classe dominante.\n"
                "- Althusser: aparelhos ideologicos de Estado "
                "(escola, igreja, midia).\n"
                "- Ideologia naturaliza o que e historico."
            ),
            "exemplo": (
                "A ideologia do 'esforco individual leva ao "
                "sucesso' naturaliza a desigualdade: se alguem e "
                "pobre, e porque nao se esforcou. Isso oculta "
                "fatores estruturais (heranca, educacao, racismo). "
                "A ideologia faz ver como natural o que e "
                "construido socialmente."
            ),
        },
    ],
    "resumo": (
        "- Tipos: senso comum, religioso, filosofico, cientifico, artistico.\n"
        "- Empirismo (experiencia) x racionalismo (razao).\n"
        "- Positivismo: fato observavel. Popper: falsificabilidade.\n"
        "- Kuhn: paradigmas e revoluciones cientificas.\n"
        "- Verdade: correspondencia, coerencia, utilidade, interpretacao.\n"
        "- Ideologia: falsa consciencia (Marx), aparelhos ideologicos (Althusser)."
    ),
    "dicas": [
        "Senso comum: espontaneo. Cientifico: metodico.",
        "Popper: cientifico e o que pode ser refutado.",
        "Kuhn: paradigma muda em revolucões cientificas.",
        "Marx: ideologia = ideias da classe dominante.",
        "Wittgenstein: significado depende do uso (jogos de linguagem).",
        "Hermeneutica: verdade como interpretacao, nao correspondencia.",
    ],
    "pegadinhas": [
        "Achar que senso comum e sempre errado: e limitado, mas nao falso.",
        "Confundir empirismo com positivismo: empirismo e teoria, positivismo e metodo.",
        "Achar que Popper nega a ciencia: ele define o que e cientifico.",
        "Confundir verdade de correspondencia com coerencia.",
        "Esquecer que ideologia nao e so politica: e tambem cotidiana.",
        "Achar que pseudociencia e falsa: e irrefutavel, nao testavel.",
    ],
    "referencias": [
        "CHAUÍ, M. Convite a filosofia. 13. ed. Sao Paulo: Atica, 2010.",
        "ARANHA, M. L. A.; MARTINS, M. H. P. Filosofando. 4. ed. Sao Paulo: Moderna, 2009.",
        "POPPER, K. A logica da pesquisa cientifica. Sao Paulo: Cultrix, 2007.",
        "KUHN, T. A estrutura das revolucões cientificas. 12. ed. Sao Paulo: Perspectiva, 2011.",
        "GADAMER, H. G. Verdade e metodo. Petropolis: Vozes, 2008.",
        "ALTHUSSER, L. Ideologia e aparelhos ideologicos de Estado. Lisboa: Presencas, 1980.",
    ],
}

IMG_CONHECIMENTO = [
    {"file": "filo_conhecimento.png", "caption": "Tipos de conhecimento e correntes epistemologicas", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_conhecimento", [])

# ============================================================
# 10.3 A Filosofia
# ============================================================
A_FILOSOFIA = {
    "titulo": "A Filosofia",
    "disciplina": "Filosofia",
    "topico": "A Filosofia",
    "subtopico": "Atitude filosofica, origem e principais periodos",
    "introducao": (
        "A filosofia nasce na Grecia Antiga como passagem do "
        "mito ao logos. E uma atitude de espanto e questionamento "
        "diante do mundo. Mais que um conjunto de doutrinas, e "
        "uma forma de pensar."
    ),
    "secoes": [
        {
            "titulo": "1. Atitude filosofica e reflexao",
            "conteudo": (
                "ATITUDE FILOSOFICA:\n"
                "- Espanto, admiracao diante do mundo (Platao, "
                "Aristoteles).\n"
                "- Perguntar: o que e isto? Por que?\n"
                "- Duvida metodica (Descartes): duvidar para "
                "encontrar certezas.\n"
                "- Critica do senso comum: nao aceitar o obvio.\n"
                "- Pensar por si mesmo: autonomia.\n\n"
                "REFLEXAO FILOSOFICA:\n"
                "- Voltar-se sobre o proprio pensamento.\n"
                "- Questionar pressupostos.\n"
                "- Buscar fundamentos, nao respostas prontas.\n"
                "- Filosofar e aprender a morrer (Platao)."
            ),
            "exemplo": (
                "Quando alguem pergunta 'o que e justica?' em "
                "vez de aceitar a definicao do dicionario, esta "
                "filosofando. A atitude filosofica comeca com a "
                "pergunta, nao com a resposta. Socrates fazia "
                "isso nas ruas de Atenas: perguntava ate que o "
                "interlocutor percebesse que nao sabia o que "
                "pensava saber."
            ),
        },
        {
            "titulo": "2. Origem da filosofia",
            "conteudo": (
                "ORIGEM: Grecia Antiga, seculo VI a.C., nas "
                "colonias da Asia Menor (Mileto).\n\n"
                "PASSAGEM DO MITO AO LOGOS:\n"
                "- Mito: narrativa sagrada, explicacao por deuses.\n"
                "- Logos: razao, explicacao natural.\n"
                "- Os pre-socraticos (Tales, Anaximandro, "
                "Heráclito) buscaram o principio (arche) natural.\n\n"
                "CONDICOES HISTORICAS:\n"
                "- Polis: espaco de debate publico.\n"
                "- Moeda: abstracao do valor.\n"
                "- Alfabeto: escrita fonetica.\n"
                "- Comercio: contato com outras culturas.\n\n"
                "MILESIOS: Tales (agua), Anaximandro (apeiron), "
                "Anaximenes (ar)."
            ),
            "exemplo": (
                "Tales de Mileto disse que a agua era o principio "
                "de tudo. Embora errado, foi revolucionario: "
                "explicou o mundo por um elemento natural, nao por "
                "deuses. Essa e a passagem do mito ao logos: "
                "buscar explicacao racional em vez de mitologica."
            ),
        },
        {
            "titulo": "3. Principais periodos da filosofia",
            "conteudo": (
                "FILOSOFIA ANTIGA (sec VI a.C. - V d.C.):\n"
                "- Pre-socraticos: principio natural.\n"
                "- Socrates: maiêutica, etica.\n"
                "- Platao: teoria das ideias, A Republica.\n"
                "- Aristoteles: logica, etica, metafisica.\n"
                "- Estoicos e epicuristas: etica.\n\n"
                "FILOSOFIA MEDIEVAL (sec V-XV):\n"
                "- Patristica: Agostinho.\n"
                "- Escolastica: Tomas de Aquino. Fe e razao.\n\n"
                "FILOSOFIA MODERNA (sec XV-XVIII):\n"
                "- Renascimento: humanismo.\n"
                "- Descartes: metodo, duvida.\n"
                "- Locke, Hume: empirismo.\n"
                "- Kant: criticismo, sintese.\n\n"
                "FILOSOFIA CONTEMPORANEA (sec XIX-XXI):\n"
                "- Hegel: dialetica.\n"
                "- Marx: materialismo historico.\n"
                "- Nietzsche: critica da moral.\n"
                "- Existencialismo: Sartre.\n"
                "- Escola de Frankfurt: Adorno, Habermas."
            ),
            "exemplo": (
                "Descartes duvidou de tudo: dos sentidos, da "
                "memoria, ate da existencia do mundo. Mas nao "
                "pode duvidar de que duvidava. 'Penso, logo "
                "existo' (Cogito, ergo sum) foi a primeira "
                "certeza. Esse metodo inaugurou a filosofia "
                "moderna: a razao como fundamento."
            ),
        },
    ],
    "resumo": (
        "- Atitude filosofica: espanto, pergunta, duvida, autonomia.\n"
        "- Origem: Grecia, sec VI a.C., passagem mito -> logos.\n"
        "- Condicoes: polis, moeda, alfabeto, comercio.\n"
        "- Antiga: Socrates, Platao, Aristoteles, estoicos.\n"
        "- Medieaval: Agostinho, Tomas de Aquino (fe e razao).\n"
        "- Moderna: Descartes, empirismo, Kant.\n"
        "- Contemporanea: Hegel, Marx, Nietzsche, existencialismo, Frankfurt."
    ),
    "dicas": [
        "Filosofia comeca com pergunta, nao com resposta.",
        "Mito -> logos: explicacao natural substitui sagrada.",
        "Socrates: maiêutica (parteira de ideias), nao deixou escrito.",
        "Descartes: penso logo existo, duvida metodica.",
        "Kant: sintese de empirismo e racionalismo.",
        "Nietzsche: critica da moral cristã, alem do bem e do mal.",
    ],
    "pegadinhas": [
        "Achar que filosofia e so teoria: e tambem atitude pratica.",
        "Confundir pre-socraticos com Socrates: pre-socraticos vem antes.",
        "Esquecer que a filosofia medieval tentou conciliar fe e razao.",
        "Achar que Descartes negava os sentidos: ele duvidava, nao negava.",
        "Confundir Marx com marxismo: Marx e autor, marxismo e doutrina.",
        "Esquecer que Nietzsche nao era niilista: ele diagnostico o niilismo.",
    ],
    "referencias": [
        "CHAUÍ, M. Convite a filosofia. 13. ed. Sao Paulo: Atica, 2010.",
        "ARANHA, M. L. A.; MARTINS, M. H. P. Filosofando. 4. ed. Sao Paulo: Moderna, 2009.",
        "REALE, G.; ANTISERI, D. Historia da filosofia. 3 vols. Sao Paulo: Paulus, 2003.",
        "DESCARTES, R. Discurso do metodo. Sao Paulo: Martins Fontes, 2007.",
        "PLATAO. A Republica. Lisboa: Fundacao Calouste Gulbenkian, 2005.",
        "NIETZSCHE, F. Alem do bem e do mal. Sao Paulo: Companhia das Letras, 2009.",
    ],
}

IMG_A_FILOSOFIA = [
    {"file": "filo_filosofia.png", "caption": "Linha do tempo da filosofia: origem e periodos", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_filosofia", [])

# ============================================================
# 10.4 Logica
# ============================================================
LOGICA = {
    "titulo": "Logica",
    "disciplina": "Filosofia",
    "topico": "Logica",
    "subtopico": "Principios, argumentacao, silogismo e logica simbolica",
    "introducao": (
        "A logica e o estudo do raciocinio valido. Fundada por "
        "Aristoteles, e a ferramenta do pensamento racional. "
        "Permite distinguir argumentos validos de invalidos."
    ),
    "secoes": [
        {
            "titulo": "1. Nascimento e principios da logica",
            "conteudo": (
                "NASCIMENTO: Aristoteles (sec IV a.C.) fundou a "
                "logica formal. Organon e a obra logica.\n\n"
                "PRINCIPIOS FUNDAMENTAIS:\n"
                "- Identidade: A = A. Cada coisa e o que e.\n"
                "- Nao-contradicao: A nao pode ser e nao ser ao "
                "mesmo tempo.\n"
                "- Terceiro excluido: A ou nao-A. Nao ha terceira "
                "possibilidade.\n"
                "- Razao suficiente (Leibniz): tudo tem uma razao "
                "de ser.\n\n"
                "TERMO E PROPOSICAO:\n"
                "- Termo: sujeito ou predicado.\n"
                "- Proposicao: declarativa, pode ser V ou F.\n"
                "- Tipos: universal (todo A), particular (algum A), "
                "afirmativa, negativa."
            ),
            "exemplo": (
                "O principio da identidade diz que 'um medico e "
                "um medico'. O da nao-contradicao diz que 'um "
                "medico nao pode ser e nao ser medico ao mesmo "
                "tempo'. O do terceiro excluido diz que 'alguem e "
                "medico ou nao e medico', sem meio-termo. Esses "
                "principios sao a base do pensamento logico."
            ),
        },
        {
            "titulo": "2. Argumentacao e silogismo",
            "conteudo": (
                "TIPOS DE ARGUMENTACAO:\n"
                "- Deducao: do geral ao particular. Conclusao "
                "necessaria.\n"
                "- Inducao: do particular ao geral. Conclusao "
                "provavel.\n"
                "- Abducao: hipotese explicativa (Peirce).\n"
                "- Analogia: comparacao entre casos.\n\n"
                "SILOGISMO (Aristoteles):\n"
                "- Premissa maior: todo A e B.\n"
                "- Premissa menor: C e A.\n"
                "- Conclusao: logo, C e B.\n\n"
                "EXEMPLO CLASSICO:\n"
                "Todo homem e mortal. Socrates e homem. Logo, "
                "Socrates e mortal.\n\n"
                "FALACIAS: argumentos invalidos que parecem validos. "
                "Ex: ad hominem, ad populum, espantalho."
            ),
            "exemplo": (
                "Argumento dedutivo: 'Todos os virus precisam de "
                "celula hospedeira. O HIV e um virus. Logo, o HIV "
                "precisa de celula hospedeira.' A conclusao e "
                "necessaria se as premisas forem verdadeiras. Ja "
                "a inducao: 'Observei 100 virus e todos precisam "
                "de hospedeira. Logo, todos os virus precisam.' "
                "A conclusao e provavel, mas nao certa."
            ),
        },
        {
            "titulo": "3. Logica simbolica",
            "conteudo": (
                "LOGICA SIMBOLICA: formalizacao matematica da "
                "logica (sec XIX-XX). Boole, Frege, Russell.\n\n"
                "PROPOSICOES: p, q, r...\n\n"
                "CONECTIVOS LOGICOS:\n"
                "- E (conjuncao): p E q. Verdadeiro se ambos.\n"
                "- OU (disjuncao): p OU q. Verdadeiro se ao menos "
                "um.\n"
                "- -> (implicacao): p -> q. Se p entao q.\n"
                "- <-> (bicondicional): p <-> q. Se e somente se.\n"
                "- NAO (negacao): ~p. Inverte.\n\n"
                "REGRAS DE INFERENCIA:\n"
                "- Modus ponens: p -> q, p, logo q.\n"
                "- Modus tollens: p -> q, ~q, logo ~p.\n\n"
                "TABELA VERDADE: combina V/F para cada conectivo."
            ),
            "exemplo": (
                "Modus ponens: 'Se chove, a rua fica molhada. "
                "Chove. Logo, a rua fica molhada.' (p -> q, p, "
                "logo q). Modus tollens: 'Se chove, a rua fica "
                "molhada. A rua nao esta molhada. Logo, nao "
                "choveu.' (p -> q, ~q, logo ~p). Essas regras sao "
                "a base do raciocinio logico formal."
            ),
        },
    ],
    "resumo": (
        "- Principios: identidade, nao-contradicao, terceiro excluido.\n"
        "- Termo: sujeito/predicado. Proposicao: V ou F.\n"
        "- Deducao: necessario. Inducao: provavel. Abducao: hipotese.\n"
        "- Silogismo: maior + menor -> conclusao.\n"
        "- Falacias: ad hominem, ad populum, espantalho.\n"
        "- Logica simbolica: p, q, E, OU, ->, <->, ~.\n"
        "- Modus ponens e modus tollens: regras basicas."
    ),
    "dicas": [
        "Deducao: conclusao necessaria. Inducao: conclusao provavel.",
        "Silogismo: medio termo conecta maior e menor.",
        "Modus ponens: p -> q, p, logo q.",
        "Modus tollens: p -> q, ~q, logo ~p.",
        "Falacia ad hominem: ataca a pessoa, nao o argumento.",
        "Tabela verdade: combina V/F para testar argumentos.",
    ],
    "pegadinhas": [
        "Confundir deducao com inducao: deducao e necessaria, inducao e provavel.",
        "Achar que silogismo valido tem conclusao verdadeira: depende das premisas.",
        "Confundir modus ponens com modus tollens.",
        "Achar que analogia e argumento dedutivo: e tipo diferente.",
        "Esquecer que falacia parece valida mas nao e.",
        "Confundir negacao (~) com contrapositiva.",
    ],
    "referencias": [
        "COPI, I. M. Introducao a logica. 14. ed. Sao Paulo: Martins Fontes, 2011.",
        "SALMON, W. C. Logica. 7. ed. Rio de Janeiro: LTC, 2006.",
        "MORTARI, C. A. Introducao a logica. Sao Paulo: Unesp, 2001.",
        "ARISTOTELES. Organon. Lisboa: Guimaraes, 2005.",
        "FREGE, G. Conceptografia. Sao Paulo: Abril Cultural, 1978.",
        "QUINE, W. V. O. Filosofia da logica. Lisboa: Edicoes 70, 2008.",
    ],
}

IMG_LOGICA = [
    {"file": "filo_logica.png", "caption": "Principios da logica e exemplo de silogismo", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_logica", [])

# ============================================================
def main():
    pdfs = [
        (CULTURA, "FIL_CULTURA.pdf", IMG_CULTURA, "Filosofia — Cultura"),
        (CONHECIMENTO, "FIL_CONHECIMENTO.pdf", IMG_CONHECIMENTO, "Filosofia — Conhecimento"),
        (A_FILOSOFIA, "FIL_A_FILOSOFIA.pdf", IMG_A_FILOSOFIA, "Filosofia — A Filosofia"),
        (LOGICA, "FIL_LOGICA.pdf", IMG_LOGICA, "Filosofia — Logica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
