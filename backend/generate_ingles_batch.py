"""Gera PDFs de Lingua Inglesa — topicos 6.1 a 6.3."""

from pdf_base import generate_educational_pdf

# ============================================================
# 6.1 Leitura e Interpretacao
# ============================================================
LEITURA = {
    "titulo": "Leitura e Interpretação",
    "disciplina": "Lingua Inglesa",
    "topico": "Reading and Interpretation",
    "subtopico": "Skimming, scanning, inferencia e generos textuais",
    "introducao": (
        "A prova de Lingua Inglesa do PAES cobra principalmente "
        "leitura e interpretacao de textos. Dominar estrategias "
        "de leitura rapida e compreensao e mais importante que "
        "decorar regras gramaticais."
    ),
    "secoes": [
        {
            "titulo": "1. Skimming and scanning",
            "conteudo": (
                "SKIMMING: leitura rapida para obter a ideia geral "
                "do texto. Ler titulos, subtitulos, primeiro e "
                "ultimo paragrafo. Nao se prender a palavras "
                "desconhecidas.\n\n"
                "SCANNING: leitura rapida procurando informacao "
                "especifica. Procurar numeros, datas, nomes, "
                "lugares. Como procurar uma palavra no dicionario.\n\n"
                "INTENSIVE READING: leitura detalhada, para "
                "compreender todo o texto. Usada em questoes de "
                "interpretacao.\n\n"
                "EXTENSIVE READING: leitura por prazer ou para "
                "ampliar vocabulario. Textos longos, sem pressa."
            ),
            "exemplo": (
                "Em uma prova, voce pode usar skimming no primeiro "
                "paragrafo para descobrir o tema do texto (ex.: "
                "public health). Depois, usar scanning para "
                "encontrar rapidamente o ano de uma descoberta "
                "mencionada na questao. Isso economiza tempo e "
                "evita releituras desnecessarias."
            ),
        },
        {
            "titulo": "2. Inferencia and context clues",
            "conteudo": (
                "INFERENCE: deduzir informacoes que nao estao "
                "explicitas no texto, mas sao sugeridas.\n\n"
                "CONTEXT CLUES: dicas no contexto que ajudam a "
                "deduzir o significado de palavras desconhecidas.\n\n"
                "TIPOS DE CONTEXT CLUES:\n"
                "- Definition: o texto define a palavra.\n"
                "- Synonym: uma palavra conhecida com sentido "
                "similar aparece proxima.\n"
                "- Antonym: uma palavra com sentido oposto.\n"
                "- Example: exemplos esclarecem o significado.\n"
                "- General context: o sentido geral do paragrafo "
                "ajuda.\n\n"
                "PREFIXES AND SUFFIXES: ajudam a deduzir significado "
                "(un- = not; -less = without; re- = again)."
            ),
            "exemplo": (
                "Se o texto diz 'The patient was asymptomatic, "
                "showing no signs of disease', a palavra "
                "'asymptomatic' pode ser deduzida: o prefixo 'a-' "
                "indica ausencia e 'symptomatic' relaciona-se a "
                "sintomas. Portanto, asymptomatic = sem sintomas. "
                "O contexto confirma: 'showing no signs of disease'."
            ),
        },
        {
            "titulo": "3. Text types and genres",
            "conteudo": (
                "TEXT TYPES (tipos):\n"
                "- Narrative: conta uma historia.\n"
                "- Descriptive: descreve cenas, pessoas, objetos.\n"
                "- Expository: explica, informa.\n"
                "- Argumentative: defende um ponto de vista.\n"
                "- Instructive: da instrucoes (recipes, manuals).\n\n"
                "GENRES (generos):\n"
                "- News article: noticia, fato real.\n"
                "- Advertisement: anuncio, publicidade.\n"
                "- Email: correspondencia eletronica.\n"
                "- Recipe: receita, instrucoes.\n"
                "- Blog post: postagem em blog.\n"
                "- Comic strip: tira comica.\n"
                "- Infographic: informacao visual.\n\n"
                "REFERENCE WORDS: pronomes e advérbios que retomam "
                "termos anteriores (it, they, this, that, such)."
            ),
            "exemplo": (
                "Uma noticia sobre vacinacao e do tipo expository "
                "e do genero news article. Um anuncio de remedio "
                "e do tipo argumentative/persuasive e do genero "
                "advertisement. Identificar o genero ajuda a "
                "esperar o tipo de linguagem e a intencao do autor."
            ),
        },
    ],
    "resumo": (
        "- Skimming: ideia geral. Scanning: informacao especifica.\n"
        "- Intensive reading: detalhada. Extensive: ampla.\n"
        "- Inferencia: deduzir o que nao esta explicito.\n"
        "- Context clues: definition, synonym, antonym, example.\n"
        "- Prefixos e sufixos ajudam a deduzir vocabulario.\n"
        "- Tipos: narrative, descriptive, expository, argumentative, instructive."
    ),
    "dicas": [
        "Skimming primeiro, scanning depois, intensive reading por ultimo.",
        "Nao pare em cada palavra desconhecida; use o contexto.",
        "Reference words (it, they, this) sempre se referem a algo anterior.",
        "Identifique o genero do texto para prever a estrutura.",
        "Pergunte-se: qual e a ideia central? Qual a intencao do autor?",
        "Cognatos ajudam, mas cuidado com false friends.",
    ],
    "pegadinhas": [
        "Achar que skimming e leitura preguicosa: e estrategia de eficiencia.",
        "Confundir inference com opiniao pessoal: inference se baseia no texto.",
        "Esquecer que reference words podem se referir a algo distante no texto.",
        "Achar que todo texto argumentativo defende uma tese explicita.",
        "Nao perceber que um titulo ou subtitulo ja da a ideia geral.",
        "Confundir tipo textual com genero textual.",
    ],
    "referencias": [
        "NUTTALL, C. Teaching Reading Skills in a Foreign Language. Macmillan, 2005.",
        "DAY, R. R.; BAMFORD, J. Extensive Reading in the Second Language Classroom. Cambridge University Press, 1998.",
        "GRABE, W.; STOLLER, F. L. Teaching and Researching Reading. Longman, 2011.",
        "MURPHY, R. English Grammar in Use. 4. ed. Cambridge University Press, 2012.",
        "SWAN, M. Practical English Usage. 3. ed. Oxford University Press, 2005.",
        "VINCE, M. Advanced Language Practice. Macmillan, 2009.",
    ],
}

IMG_LEITURA = [
    {"file": "ing_leitura.png", "caption": "Reading strategies: skimming and scanning", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 6.2 Lexico
# ============================================================
LEXICO = {
    "titulo": "Léxico",
    "disciplina": "Lingua Inglesa",
    "topico": "Vocabulary and Lexicon",
    "subtopico": "Cognatos, false friends, formacao de palavras e phrasal verbs",
    "introducao": (
        "O lexico de uma lingua e o conjunto de palavras e "
        "expressoes que ela oferece. Conhecer cognatos, evitar "
        "falsos amigos e entender formacao de palavras amplia "
        "muito a compreensao de textos."
    ),
    "secoes": [
        {
            "titulo": "1. Cognates and false friends",
            "conteudo": (
                "COGNATES (cognatos): palavras parecidas em duas "
                "linguas, com o mesmo origem e significado similar. "
                "Exemplos: doctor/doctor, medicine/medicina, "
                "hospital/hospital, family/familia.\n\n"
                "FALSE FRIENDS (falsos amigos): palavras parecidas, "
                "mas com significados diferentes. Cuidado!\n\n"
                "EXEMPLOS DE FALSE FRIENDS:\n"
                "- actually = na verdade (nao 'atualmente')\n"
                "- parents = pais (nao 'parentes')\n"
                "- recipe = receita culinaria (nao 'receita medica')\n"
                "- pretend = fingir (nao 'pretender')\n"
                "- lecture = palestra (nao 'leitura')\n"
                "- library = biblioteca (nao 'livraria')\n"
                "- exit = saida (nao 'exito')\n"
                "- intend = pretender (nao 'entender')"
            ),
            "exemplo": (
                "Em uma prova, o texto pode dizer 'The doctor "
                "actually prescribed rest'. Se o aluno traduzir "
                "'actually' como 'atualmente', entendera que o "
                "medico 'atualmente prescreveu descanso', o que "
                "esta errado. O correto e 'na verdade, prescreveu "
                "descanso'. Esse tipo de erro e muito comum."
            ),
        },
        {
            "titulo": "2. Word formation: prefixes and suffixes",
            "conteudo": (
                "PREFIXES: alteram o significado da palavra.\n"
                "- un- = not (unhappy)\n"
                "- in-/im-/il-/ir- = not (invisible, impossible)\n"
                "- dis- = not (disagree)\n"
                "- re- = again (rewrite)\n"
                "- pre- = before (preview)\n"
                "- over- = too much (overwork)\n"
                "- under- = too little (underweight)\n\n"
                "SUFFIXES: alteram a classe gramatical.\n"
                "- -ness = substantivo (happiness)\n"
                "- -ful = adjetivo (careful)\n"
                "- -less = adjetivo sem (careless)\n"
                "- -ly = adverbio (quickly)\n"
                "- -tion/-sion = substantivo (action, decision)\n"
                "- -able/-ible = adjetivo (comfortable, visible)\n"
                "- -ment = substantivo (development)\n"
                "- -er/-or = pessoa que faz (teacher, doctor)"
            ),
            "exemplo": (
                "A palavra 'treatment' vem de treat + -ment. O "
                "sufixo -ment transforma o verbo em substantivo: "
                "treatment = tratamento. Ja 'untreatable' combina "
                "un- (not) + treat + -able (capable of): que nao "
                "pode ser tratado. Entender formacao de palavras "
                "multiplica o vocabulario."
            ),
        },
        {
            "titulo": "3. Phrasal verbs and collocations",
            "conteudo": (
                "PHRASAL VERBS: combinacoes de verbo + preposicao "
                "ou adverbio, com significado proprio, diferente "
                "do verbo sozinho.\n\n"
                "EXEMPLOS COMUNS:\n"
                "- give up = desistir\n"
                "- look after = cuidar\n"
                "- look for = procurar\n"
                "- put off = adiar\n"
                "- take off = decolar / tirar\n"
                "- turn on / turn off = ligar / desligar\n"
                "- get over = superar\n"
                "- bring up = criar (filhos)\n\n"
                "COLLOCATIONS: combinacoes naturais de palavras. "
                "Exemplos: take medicine (nao 'drink medicine'), "
                "make a decision, have a headache, catch a cold."
            ),
            "exemplo": (
                "Em um texto medico, 'The nurse looks after the "
                "patients' significa que a enfermeira cuida dos "
                "pacientes. Se o aluno traduzir literalmente 'olha "
                "apos', perde o sentido. Phrasal verbs sao muito "
                "comuns em ingles e aparecem em todas as provas."
            ),
        },
    ],
    "resumo": (
        "- Cognatos: palavras parecidas com mesmo significado.\n"
        "- False friends: parecidas, mas significados diferentes.\n"
        "- Prefixes: un-, in-, dis-, re-, pre-, over-, under-.\n"
        "- Suffixes: -ness, -ful, -less, -ly, -tion, -able, -ment.\n"
        "- Phrasal verbs: verbo + preposicao/adverbio, significado proprio.\n"
        "- Collocations: combinacoes naturais (take medicine, make a decision)."
    ),
    "dicas": [
        "Cognatos facilitam, mas confirme o significado no contexto.",
        "Decore os principais false friends: actually, parents, pretend, recipe.",
        "Aprenda phrasal verbs em contextos, nao em listas isoladas.",
        "Suffixes -tion e -ment sempre formam substantivos.",
        "Prefix un- e o mais comum para negacao.",
        "Collocations: em ingles, toma-se medicine, nao se bebe.",
    ],
    "pegadinhas": [
        "Traduzir 'actually' como 'atualmente': e 'na verdade'.",
        "Achar que 'parents' e 'parentes': e 'pais'.",
        "Confundir 'library' com 'livraria': e 'biblioteca'.",
        "Traduzir phrasal verb literalmente: o significado e diferente.",
        "Esquecer que -ly forma adverbios, nao adjetivos.",
        "Usar 'drink medicine' em vez de 'take medicine'.",
    ],
    "referencias": [
        "SWAN, M. Practical English Usage. 3. ed. Oxford University Press, 2005.",
        "MCCARTHY, M.; O'DELL, F. English Vocabulary in Use. Cambridge University Press, 2017.",
        "REDMAN, S. English Vocabulary in Use: Pre-intermediate. Cambridge University Press, 2017.",
        "VINCE, M. Advanced Language Practice. Macmillan, 2009.",
        "MURPHY, R. English Grammar in Use. 4. ed. Cambridge University Press, 2012.",
        "HEWINGS, M. Advanced Grammar in Use. 3. ed. Cambridge University Press, 2013.",
    ],
}

IMG_LEXICO = [
    {"file": "ing_lexico.png", "caption": "Cognates and false friends in English", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 6.3 Gramatica
# ============================================================
GRAMATICA = {
    "titulo": "Gramática",
    "disciplina": "Lingua Inglesa",
    "topico": "Grammar",
    "subtopico": "Verb tenses, articles, pronouns, adjectives and connectors",
    "introducao": (
        "A gramatica da lingua inglesa e extensa, mas a prova do "
        "PAES foca em pontos principais: tempos verbais, "
        "artigos, pronomes, adjetivos e conectivos. Dominar "
        "esses topicos melhora muito a interpretacao."
    ),
    "secoes": [
        {
            "titulo": "1. Verb tenses",
            "conteudo": (
                "SIMPLE TENSES:\n"
                "- Simple Present: I work. (rotina, fatos)\n"
                "- Simple Past: I worked. (acao concluida)\n"
                "- Simple Future: I will work. (acao futura)\n\n"
                "CONTINUOUS TENSES:\n"
                "- Present Continuous: I am working. (agora)\n"
                "- Past Continuous: I was working. (em andamento no passado)\n"
                "- Future Continuous: I will be working.\n\n"
                "PERFECT TENSES:\n"
                "- Present Perfect: I have worked. (acao com "
                "relevancia no presente)\n"
                "- Past Perfect: I had worked. (antes de outra "
                "acao passada)\n"
                "- Future Perfect: I will have worked.\n\n"
                "PERFECT CONTINUOUS: have been working, had been "
                "working.\n\n"
                "IRREGULAR VERBS: go-went-gone, see-saw-seen, "
                "take-took-taken, give-gave-given."
            ),
            "exemplo": (
                "The patient has taken the medicine. Present "
                "Perfect: a acao ocorreu no passado, mas tem "
                "relevancia no presente (o remedio ainda faz "
                "efeito). Ja 'The patient took the medicine "
                "yesterday' usa Simple Past: acao concluida em "
                "tempo definido."
            ),
        },
        {
            "titulo": "2. Articles, nouns and pronouns",
            "conteudo": (
                "ARTICLES:\n"
                "- A/an: indefinido, singular. A before consonant "
                "sound, an before vowel sound.\n"
                "- The: definido. Usado para algo especifico.\n"
                "- No article: antes de substantivos genericos "
                "ou abstratos.\n\n"
                "NOUNS:\n"
                "- Plural: regular (book-books), irregular "
                "(man-men, child-children, foot-feet).\n"
                "- Genitive case: 's (the doctor's office).\n"
                "- Countable (a book) vs. uncountable (water).\n\n"
                "PRONOUNS:\n"
                "- Personal: I, you, he, she, it, we, they.\n"
                "- Possessive: my, your, his, her, its, our, their.\n"
                "- Reflexive: myself, yourself, himself, etc.\n"
                "- Relative: who, which, that, whose.\n"
                "- Interrogative: who, what, where, when, why, how."
            ),
            "exemplo": (
                "A doctor works in a hospital. The doctor I saw "
                "yesterday was kind. No primeiro, 'a doctor' e "
                "indefinido (qualquer medico). No segundo, 'the "
                "doctor' e definido (aquele especifico). O pronome "
                "relativo 'who' seria usado para pessoas: 'The "
                "doctor who treated me was kind'."
            ),
        },
        {
            "titulo": "3. Adjectives, adverbs and connectors",
            "conteudo": (
                "ADJECTIVES: comparacao.\n"
                "- Comparative: taller than, more beautiful than.\n"
                "- Superlative: the tallest, the most beautiful.\n"
                "- Irregular: good-better-the best; "
                "bad-worse-the worst.\n\n"
                "ADVERBS:\n"
                "- Manner: quickly, carefully (geralmente -ly).\n"
                "- Time: now, yesterday, soon.\n"
                "- Frequency: always, usually, often, sometimes, "
                "never.\n"
                "- Place: here, there, everywhere.\n\n"
                "CONNECTORS:\n"
                "- Addition: and, also, moreover, furthermore.\n"
                "- Contrast: but, however, although, nevertheless.\n"
                "- Cause: because, since, as.\n"
                "- Result: so, therefore, thus.\n"
                "- Sequence: first, then, next, finally."
            ),
            "exemplo": (
                "Although the treatment was painful, the patient "
                "recovered quickly. 'Although' indica contraste; "
                "'quickly' e adverbio de modo. Em uma prova, "
                "identificar o conector ajuda a entender a relacao "
                "entre as ideias: aqui, ha uma oposicao entre dor "
                "e recuperacao."
            ),
        },
    ],
    "resumo": (
        "- Simple, continuous, perfect e perfect continuous em present, past e future.\n"
        "- Irregular verbs: go-went-gone, see-saw-seen, take-took-taken.\n"
        "- Articles: a/an (indefinido), the (definido), no article (generico).\n"
        "- Plural: regular (-s) e irregular (man-men, child-children).\n"
        "- Pronouns: personal, possessive, reflexive, relative, interrogative.\n"
        "- Comparatives: -er than / more... than. Superlatives: the -est / the most.\n"
        "- Connectors: addition, contrast, cause, result, sequence."
    ),
    "dicas": [
        "Present Perfect liga passado ao presente; Simple Past e passado concluido.",
        "A/an antes de som consonantal/vocalico, nao letra.",
        "Uncountable nouns nao levam a/an: water, information, advice.",
        "Adverbios de frequencia: always > usually > often > sometimes > never.",
        "Although/though/even though introduzem contraste.",
        "Comparativos irregulares: good-better-best, bad-worse-worst.",
    ],
    "pegadinhas": [
        "Usar 'an' antes de 'university': o som e consonantal (yu), use 'a'.",
        "Confundir Present Perfect com Simple Past quando ha tempo definido.",
        "Esquecer que 'its' (possessivo) nao tem apostrofo; 'it's' = it is.",
        "Achar que todo adverbio termina em -ly: fast, hard, well sao adverbios.",
        "Trocar who (pessoas) por which (coisas) em oracoes relativas.",
        "Usar 'more' com adjetivos curtos: diz-se 'taller', nao 'more tall'.",
    ],
    "referencias": [
        "MURPHY, R. English Grammar in Use. 4. ed. Cambridge University Press, 2012.",
        "SWAN, M. Practical English Usage. 3. ed. Oxford University Press, 2005.",
        "HEWINGS, M. Advanced Grammar in Use. 3. ed. Cambridge University Press, 2013.",
        "VINCE, M. Advanced Language Practice. Macmillan, 2009.",
        "EASTWOOD, J. Oxford Guide to English Grammar. Oxford University Press, 2002.",
        "YULE, G. Oxford Practice Grammar. Oxford University Press, 2019.",
    ],
}

IMG_GRAMATICA = [
    {"file": "ing_gramatica.png", "caption": "Verb tenses: past, present and future timeline", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (LEITURA, "ING_LEITURA_INTERPRETACAO.pdf", IMG_LEITURA, "Lingua Inglesa — Leitura e Interpretacao"),
        (LEXICO, "ING_LEXICO.pdf", IMG_LEXICO, "Lingua Inglesa — Lexico"),
        (GRAMATICA, "ING_GRAMATICA.pdf", IMG_GRAMATICA, "Lingua Inglesa — Gramatica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
