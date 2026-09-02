"""Gera PDFs de Filosofia — batch 2 (topicos 10.5 a 10.7)."""

from filosofia_real_images import REAL_IMAGES
from pdf_base import generate_educational_pdf

# ============================================================
# 10.5 Estetica
# ============================================================
ESTETICA = {
    "titulo": "Estetica",
    "disciplina": "Filosofia",
    "topico": "Estetica",
    "subtopico": "O belo, o gosto, arte, tecnica e industria cultural",
    "introducao": (
        "A estetica e o estudo do belo e da experiencia estetica. "
        "Nascida com Baumgarten, desenvolveu-se com Kant e "
        "chegou a critica da industria cultural com Adorno."
    ),
    "secoes": [
        {
            "titulo": "1. Conceito de estetica e o belo",
            "conteudo": (
                "ESTETICA: do grego aisthesis (sensacao). "
                "Baumgarten (1750): ciencia do sensivel.\n\n"
                "KANT (Crítica do Juizo):\n"
                "- Juizo estetico: subjetivo mas universal.\n"
                "- Belo livre: sem conceito (flores).\n"
                "- Belo aderente: ligado a conceito (humano).\n"
                "- Sublime: excede a imaginacao. Maiestade, "
                "infinitude.\n\n"
                "O BELO E O FEIO:\n"
                "- Belo classico: harmonia, proporcao, simetria.\n"
                "- Feio: desarmonia. Grotesco: exagero do feio.\n"
                "- Belo romantico: expressao, originalidade.\n"
                "- Relatividade: o belo varia no tempo e cultura."
            ),
            "exemplo": (
                "Uma pintura classica renascentista (Mona Lisa) "
                "busca harmonia e proporcao. Ja um quadro "
                "expressionista (Munch, O Grito) expressa angustia, "
                "sendo 'feio' no sentido classico, mas belo na "
                "estetica romantica. O belo depende do paradigma "
                "estetico de cada epoca."
            ),
        },
        {
            "titulo": "2. A questao do gosto e arte/religiao",
            "conteudo": (
                "GOSTO:\n"
                "- Kant: gosto subjetivo mas comunicavel. Senso "
                "comum estetico.\n"
                "- Bourdieu: gosto e de classe. A distincao "
                "estetica marca hierarquia social.\n"
                "- Gosto de classe: elite consome arte erudita, "
                "povo consome cultura popular.\n\n"
                "ARTE E RELIGIAO:\n"
                "- Arte sacra: expressa o sagrado.\n"
                "- Iconoclastia: destruicao de imagens (Bizancio, "
                "Reforma).\n"
                "- Arte liturgica: arquitetura, musica, pintura "
                "religiosas.\n"
                "- Secularizacao da arte: Renascimento.\n\n"
                "ARTE E TECNICA (Benjamin):\n"
                "- Reprodutibilidade tecnica: fotografia, cinema.\n"
                "- Aura: originalidade perdida na copia.\n"
                "- Valor de culto x valor de exposicao."
            ),
            "exemplo": (
                "Benjamin observou que a fotografia permitiu "
                "reproduzir obras de arte em massa. Isso perdeu "
                "a 'aura' do original (a experiencia unica de ver "
                "a Mona Lisa no Louvre), mas democratizou o acesso. "
                "Hoje, ver uma obra no Google Arts e diferente de "
                "ve-la ao vivo, mas alcancavel por todos."
            ),
        },
        {
            "titulo": "3. Industria cultural",
            "conteudo": (
                "INDUSTRIA CULTURAL (Adorno e Horkheimer):\n"
                "- Cultura produzida como mercadoria.\n"
                "- Padronizacao: todos consomem o mesmo.\n"
                "- Falsa individualizacao: ilusao de escolha.\n"
                "- Entretenimento: alienacao, nao reflexao.\n"
                "- Cultura de massa: passividade.\n\n"
                "CRITICA:\n"
                "- A industria cultural transforma o publico em "
                "consumidor.\n"
                "- A arte critica e marginalizada.\n"
                "- O sistema se auto-reproduz.\n\n"
                "CONTRACULTURA: movimentos que resistem (punk, "
                "hippie). Negam a padronizacao."
            ),
            "exemplo": (
                "A musica pop e produzida para vender: formulas "
                "repetidas, refrões colantes, temas previsiveis. "
                "A industria cultural cria a ilusao de que ha "
                "escolha (muitas bandas), mas todas seguem o "
                "mesmo molde. A contracultura (punk, por exemplo) "
                "resiste com ruidos, letras politicas, estetica "
                "anti-comercial."
            ),
        },
    ],
    "resumo": (
        "- Estetica: estudo do sensivel e do belo (Baumgarten).\n"
        "- Kant: juizo estetico subjetivo mas universal. Belo livre x aderente.\n"
        "- Sublime: excede a imaginacao.\n"
        "- Bourdieu: gosto e de classe, nao natural.\n"
        "- Benjamin: reprodutibilidade tecnica, perda da aura.\n"
        "- Adorno: industria cultural = cultura como mercadoria.\n"
        "- Contracultura: resistencia a padronizacao."
    ),
    "dicas": [
        "Baumgarten: estetica = ciencia do sensivel.",
        "Kant: belo livre (sem conceito) x aderente (com conceito).",
        "Bourdieu: gosto e distincao social, nao natural.",
        "Benjamin: reprodutibilidade tecnica perde a aura.",
        "Adorno: industria cultural padroniza e aliena.",
        "Contracultura resiste a padronizacao (punk, hippie).",
    ],
    "pegadinhas": [
        "Achar que belo e absoluto: varia no tempo e cultura.",
        "Confundir belo livre com belo aderente (Kant).",
        "Esquecer que Bourdieu vincula gosto a classe social.",
        "Achar que reprodutibilidade so tem aspectos negativos: tambem democratiza.",
        "Confundir industria cultural com cultura popular: sao conceitos diferentes.",
        "Esquecer que a contracultura e resposta a industria cultural.",
    ],
    "referencias": [
        "COSTA, C. Filosofia: volume unico. Sao Paulo: Moderna, 2013.",
        "KANT, I. Critica do juizo. Lisboa: Imprensa Nacional, 2008.",
        "BENJAMIN, W. A obra de arte na era de sua reprodutibilidade tecnica. Porto Alegre: Zouk, 2012.",
        "ADORNO, T.; HORKHEIMER, M. Dialética do esclarecimento. Rio de Janeiro: Zahar, 1985.",
        "BOURDIEU, P. A distincao. Porto Alegre: Zouk, 2007.",
        "DUARTE, R. Estetica, arte e filosofia. Sao Paulo: Atica, 2011.",
    ],
}

IMG_ESTETICA = [
    {"file": "filo_estetica.png", "caption": "Estetica: do belo a industria cultural", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_estetica", [])

# ============================================================
# 10.6 Politica
# ============================================================
POLITICA = {
    "titulo": "Politica",
    "disciplina": "Filosofia",
    "topico": "Politica",
    "subtopico": "Estado, poder, totalitarismos, ideologias e cidadania",
    "introducao": (
        "A filosofia politica estuda a organizacao do poder na "
        "sociedade. Da invencao grega da polis as ideologias "
        "modernas, busca entender Estado, poder e cidadania."
    ),
    "secoes": [
        {
            "titulo": "1. Invencao da politica, forca e poder",
            "conteudo": (
                "INVENCAO DA POLITICA:\n"
                "- Grecia: polis, espaco publico de debate.\n"
                "- Aristoteles: o homem e animal politico.\n"
                "- Publico x privado: oikos (casa) x polis.\n"
                "- Democracia ateniense: assembleia.\n\n"
                "FORCA E PODER:\n"
                "- Poder: capacidade de fazer agir.\n"
                "- Weber: dominacao legitima. 3 tipos:\n"
                "  * Tradicional: costume (rei).\n"
                "  * Carismatica: lider excepcional.\n"
                "  * Legal-racional: lei (presidente eleito).\n"
                "- Foucault: poder disperso, capilar. Nao so no "
                "Estado, mas em instituicoes (escola, hospital, "
                "prisao). Biopoder: controle dos corpos."
            ),
            "exemplo": (
                "Foucault mostrou que o poder nao esta so no "
                "Estado. A escola disciplina corpos (horarios, "
                "filas, provas). O hospital controla pacientes. "
                "A prisao vigia detentos. O 'biopoder' e o "
                "controle da vida: natalidade, saude, sexualidade. "
                "O poder e capilar, esta em toda parte."
            ),
        },
        {
            "titulo": "2. Estado, totalitarismos e ideologias",
            "conteudo": (
                "ESTADO:\n"
                "- Weber: monopolio legitimo da forca fisica.\n"
                "- Tipos: liberal (minimo), social (interventor), "
                "welfare state, totalitario.\n\n"
                "TOTALITARISMOS (sec XX):\n"
                "- Fascismo (Italia): Mussolini. Partido unico, "
                "culto ao lider.\n"
                "- Nazismo (Alemanha): Hitler. Racismo, "
                "antisemitismo.\n"
                "- Estalinismo (URSS): partido unico, terror.\n\n"
                "IDEOLOGIAS POLITICAS:\n"
                "- Republicanismo: bem comum, virtude civica.\n"
                "- Liberalismo: liberdade individual, mercado, "
                "Estado minimo (Locke, Smith).\n"
                "- Socialismo: igualdade, coletivizacao dos meios "
                "de producao (Marx).\n"
                "- Neoliberalismo: mercado como regulador, Estado "
                "minimo (Friedman, Hayek).\n"
                "- Anarquismo: abolicao do Estado."
            ),
            "exemplo": (
                "O liberalismo defende liberdade individual e "
                "mercado livre. O socialismo critica a desigualdade "
                "do liberalismo e propoe coletivizacao. O "
                "neoliberalismo, versao contemporanea do liberalismo, "
                "defende privatizacoes e Estado minimo. Essas "
                "ideologias disputam o sentido de liberdade e "
                "igualdade na politica."
            ),
        },
        {
            "titulo": "3. Cidadania, democracia e filosofia da tecnica",
            "conteudo": (
                "CIDADANIA (Marshall):\n"
                "- Direitos civis: liberdade, igualdade perante a "
                "lei.\n"
                "- Direitos politicos: voto, elegibilidade.\n"
                "- Direitos sociais: educacao, saude, previdencia.\n\n"
                "DEMOCRACIA:\n"
                "- Direta: cidadaos decidem (Atenas).\n"
                "- Representativa: representantes eleitos.\n"
                "- Participativa: conselhos, orcamento participativo.\n"
                "- Deliberativa: debate racional (Habermas).\n\n"
                "FILOSOFIA DA TECNICA:\n"
                "- Tecnica como destino (Heidegger).\n"
                "- Tecnica e emancipacao ou alienacao?\n"
                "- Habermas: tecnica x interacao comunicativa.\n"
                "- Critica da tecnociencia."
            ),
            "exemplo": (
                "A cidadania plena exige os 3 direitos: civis "
                "(liberdade), politicos (voto) e sociais (saude, "
                "educacao). No Brasil, direitos sociais foram "
                "ampliados na Constituicao de 1988 (SUS, educacao "
                "publica). A democracia participativa inclui "
                "conselhos de saude, orcamento participativo, "
                "ampliando alem do voto."
            ),
        },
    ],
    "resumo": (
        "- Politica nasce na Grecia: polis, espaco publico.\n"
        "- Weber: dominacao tradicional, carismatica, legal-racional.\n"
        "- Foucault: poder disperso, capilar, biopoder.\n"
        "- Estado: monopolio legitimo da forca.\n"
        "- Totalitarismos: fascismo, nazismo, estalinismo.\n"
        "- Ideologias: republicanismo, liberalismo, socialismo, neoliberalismo.\n"
        "- Cidadania: civil, politica, social (Marshall).\n"
        "- Democracia: direta, representativa, participativa, deliberativa."
    ),
    "dicas": [
        "Weber: Estado = monopolio legitimo da forca fisica.",
        "Foucault: poder nao so no Estado, mas em instituicoes.",
        "Liberalismo: liberdade individual. Socialismo: igualdade.",
        "Marshall: 3 dimensoes da cidadania (civil, politica, social).",
        "Democracia deliberativa: Habermas, debate racional.",
        "Heidegger: tecnica como destino, nao so ferramenta.",
    ],
    "pegadinhas": [
        "Confundir poder com forca: poder e capacidade, forca e coercao.",
        "Achar que Weber so ve 3 tipos de dominacao: sao os legitimos.",
        "Esquecer que Foucault analisa poder fora do Estado.",
        "Confundir liberalismo com neoliberalismo: neoliberalismo e versao contemporanea.",
        "Achar que cidadania e so voto: sao 3 dimensoes (Marshall).",
        "Confundir democracia direta com participativa: direta e sem representantes.",
    ],
    "referencias": [
        "CHAUÍ, M. Convite a filosofia. 13. ed. Sao Paulo: Atica, 2010.",
        "WEBER, M. Economia e sociedade. Brasilia: UnB, 2004.",
        "FOUCAULT, M. Vigiar e punir. 36. ed. Petropolis: Vozes, 2013.",
        "BOBBIO, N. Estado, governo, sociedade. 7. ed. Sao Paulo: Paz e Terra, 2007.",
        "MARSHALL, T. H. Cidadania, classe social e status. Rio de Janeiro: Zahar, 1967.",
        "HABERMAS, J. Direito e democracia. Rio de Janeiro: Tempo Brasileiro, 1997.",
    ],
}

IMG_POLITICA = [
    {"file": "filo_politica.png", "caption": "Politica: Estado, poder e ideologias", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_politica", [])

# ============================================================
# 10.7 Etica
# ============================================================
ETICA = {
    "titulo": "Etica",
    "disciplina": "Filosofia",
    "topico": "Etica",
    "subtopico": "Valores, bem e mal, dever, liberdade, direitos humanos e niilismo",
    "introducao": (
        "A etica e a reflexao sobre o agir humano. Distingue-se "
        "da moral: a moral e o conjunto de costumes, a etica e "
        "a reflexao filosofica sobre eles."
    ),
    "secoes": [
        {
            "titulo": "1. Valores, bem e mal, etica e moral",
            "conteudo": (
                "VALORES: o que e considerado importante. Normas: "
                "regras de conduta. Regras: prescricoes.\n\n"
                "ETICA x MORAL:\n"
                "- Moral: costumes, regras de uma sociedade.\n"
                "- Etica: reflexao filosofica sobre a moral.\n"
                "- Etica teorica; moral pratica.\n\n"
                "O BEM E O MAL:\n"
                "- Bem: o que e bom, desejavel.\n"
                "- Mal: o que e mau, indesejavel.\n"
                "- Etica utilitarista (Bentham, Mill): maior bem "
                "para o maior numero.\n"
                "- Etica deontologica (Kant): agir por dever, nao "
                "por consequencia.\n"
                "- Etica das virtudes (Aristoteles): buscar a "
                "virtude, o equilibrio."
            ),
            "exemplo": (
                "Um medico pode enfrentar um dilema etico: "
                "utilitarista diria 'salvar 5 pacientes com "
                "orgaos de 1' (maior bem). Deontologico diria "
                "'nao matar, mesmo para salvar 5' (dever). "
                "Aristotelico buscaria a virtude da prudencia. "
                "Cada etica oferece um criterio diferente."
            ),
        },
        {
            "titulo": "2. Dever, liberdade e determinismo",
            "conteudo": (
                "KANT: imperativo categorico.\n"
                "- 'Age apenas segundo aquela maxima pela qual "
                "possas querer que ela se torne lei universal.'\n"
                "- Agir por dever, nao por inclinacao.\n"
                "- O ser humano e fim, nunca meio.\n\n"
                "LIBERDADE:\n"
                "- Liberdade: autonomia, autodeterminacao.\n"
                "- Livre-arbitrio: capacidade de escolher.\n"
                "- Sartre: 'condenados a liberdade'.\n\n"
                "DETERMINISMO:\n"
                "- Tudo tem causa. Acoes humanas sao determinadas.\n"
                "- Determinismo biologico, social, psicologico.\n"
                "- Debate: compatibilismo (liberdade e determinismo "
                "coexistem).\n"
                "- Spinoza: liberdade e ilusao de quem ignora as "
                "causas."
            ),
            "exemplo": (
                "O imperativo categorico de Kant diz: se voce "
                "nao quer que todo mundo minta, entao nao minta. "
                "A acao deve poder ser universalizada. Ja Sartre "
                "diz que somos 'condenados a liberdade': nao "
                "podemos deixar de escolher, ate nao escolher e "
                "uma escolha. A liberdade e constitutiva do ser "
                "humano."
            ),
        },
        {
            "titulo": "3. Direitos humanos, ECA, niilismo e pos-modernidade",
            "conteudo": (
                "DIREITOS HUMANOS:\n"
                "- Universais: para todos, sem distincao.\n"
                "- Declaracao Universal (ONU, 1948): 30 artigos.\n"
                "- Direitos civis, politicos, sociais, economicos, "
                "culturais.\n\n"
                "ECA (Estatuto da Crianca e do Adolescente, 1990):\n"
                "- Crianca e adolescente como sujeitos de direitos.\n"
                "- Protecao integral. Prioridade absoluta.\n\n"
                "NIILISMO (Nietzsche):\n"
                "- Valores tradicionais perderam sentido.\n"
                "- 'Deus esta morto': nao ha fundamento absoluto.\n"
                "- Transvaloracao: criar novos valores.\n\n"
                "POS-VERDADE:\n"
                "- Fatos sao menos importantes que emocoes.\n"
                "- Fake news, desinformacao.\n\n"
                "POS-MODERNIDADE:\n"
                "- Fim das metanarrativas (Lyotard).\n"
                "- Relativismo etico.\n"
                "- Filosofia africana e oriental: outras perspectivas."
            ),
            "exemplo": (
                "A pos-verdade se manifesta quando pessoas "
                "acreditam em fake news mesmo diante de evidencias. "
                "Na pandemia, muitos negaram a ciencia apesar de "
                "dados. Nietzsche ja previa o niilismo: quando "
                "valores tradicionais perdem sentido, resta criar "
                "novos valores. A filosofia africana (ubuntu: 'eu "
                "sou porque nos somos') oferece etica comunitaria "
                "diferente do individualismo ocidental."
            ),
        },
    ],
    "resumo": (
        "- Etica: reflexao sobre a moral. Moral: costumes.\n"
        "- Utilitarismo: maior bem. Deontologia: dever. Virtudes: equilibrio.\n"
        "- Kant: imperativo categorico, agir por dever.\n"
        "- Liberdade: autonomia. Determinismo: tudo tem causa.\n"
        "- Direitos humanos: universais (ONU, 1948). ECA (1990).\n"
        "- Niilismo: valores vazios (Nietzsche). Pos-verdade: fatos irrelevantes.\n"
        "- Pos-modernidade: fim das metanarrativas. Filosofia africana e oriental."
    ),
    "dicas": [
        "Etica = teoria. Moral = pratica.",
        "Kant: imperativo categorico, agir como se fosse lei universal.",
        "Utilitarismo: maior bem para o maior numero.",
        "ECA: 1990, crianca como sujeito de direitos.",
        "Nietzsche: 'Deus esta morto', transvaloracao dos valores.",
        "Ubuntu (filosofia africana): 'eu sou porque nos somos'.",
    ],
    "pegadinhas": [
        "Confundir etica com moral: etica e reflexao, moral e pratica.",
        "Achar que Kant e utilitarista: Kant e deontologico (dever).",
        "Esquecer que ECA e de 1990, nao 1988.",
        "Achar que Nietzsche era niilista: ele diagnostico o niilismo.",
        "Confundir pos-verdade com mentira: pos-verdade e emocao > fato.",
        "Esquecer que ha filosofia africana e oriental, nao so ocidental.",
    ],
    "referencias": [
        "CHAUÍ, M. Convite a filosofia. 13. ed. Sao Paulo: Atica, 2010.",
        "KANT, I. Fundamentacao da metafisica dos costumes. Sao Paulo: Martins Fontes, 2007.",
        "ARISTOTELES. Etica a Nicomaco. Brasilia: UnB, 2005.",
        "NIETZSCHE, F. A genealogia da moral. Sao Paulo: Companhia das Letras, 2009.",
        "SARTRE, J. P. O existencialismo e um humanismo. Sao Paulo: Abril Cultural, 1978.",
        "ONU. Declaracao Universal dos Direitos Humanos. 1948.",
    ],
}

IMG_ETICA = [
    {"file": "filo_etica.png", "caption": "Etica: valores, dever, direitos e niilismo", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("filo_etica", [])

# ============================================================
def main():
    pdfs = [
        (ESTETICA, "FIL_ESTETICA.pdf", IMG_ESTETICA, "Filosofia — Estetica"),
        (POLITICA, "FIL_POLITICA.pdf", IMG_POLITICA, "Filosofia — Politica"),
        (ETICA, "FIL_ETICA.pdf", IMG_ETICA, "Filosofia — Etica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
