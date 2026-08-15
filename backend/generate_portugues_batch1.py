# -*- coding: utf-8 -*-
"""Gera PDFs de Lingua Portuguesa — batch 1 (topicos 5.1 a 5.4)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 5.1 Comunicacao e Linguagem
# ============================================================
COMUNICACAO = {
    "titulo": "Comunicação e Linguagem",
    "disciplina": "Lingua Portuguesa",
    "topico": "Comunicacao e Linguagem",
    "subtopico": "Funcoes da linguagem, linguagem verbal e nao verbal",
    "introducao": (
        "A comunicacao e o processo pelo qual uma mensagem e "
        "transmitida de um emissor a um receptor. A linguagem "
        "e o sistema que permite essa transmissao e pode ser "
        "verbal ou nao verbal."
    ),
    "secoes": [
        {
            "titulo": "1. Elementos da comunicacao",
            "conteudo": (
                "Para que a comunicacao ocorra, sao necessarios "
                "diversos elementos.\n\n"
                "EMISSOR: quem produz a mensagem, o locutor.\n\n"
                "RECEPTOR: quem recebe e interpreta a mensagem.\n\n"
                "MENSAGEM: o conteudo transmitido, composto por "
                "signos.\n\n"
                "CODIGO: o sistema de signos compartilhado, como "
                "a lingua.\n\n"
                "CANAL: o meio fisico ou virtual de transmissao.\n\n"
                "CONTEXTO: a situacao em que a comunicacao ocorre.\n\n"
                "RUIDO: qualquer interferencia que dificulte a "
                "compreensao da mensagem."
            ),
            "exemplo": (
                "No consultorio, o medico e o emissor, o paciente "
                "e o receptor. A mensagem e o diagnostico, o "
                "codigo e a lingua portuguesa e o canal pode ser "
                "a fala ou um laudo escrito. Ruidos como termos "
                "técnicos demais podem dificultar a "
                "compreensao do paciente."
            ),
        },
        {
            "titulo": "2. Funcoes da linguagem",
            "conteudo": (
                "Segundo Roman Jakobson, a linguagem pode ter seis "
                "funcoes principais, cada uma destacando um "
                "elemento da comunicacao.\n\n"
                "REFERENCIAL: foco no referente, na mensagem em "
                "si. Exemplo: boletim de saude.\n\n"
                "EMOTIVA: foco no emissor. Expressa emocoes. "
                "Exemplo: estou muito feliz com o resultado!\n\n"
                "CONATIVA: foco no receptor. Convida a acao. "
                "Exemplo: tome o medicamento duas vezes ao dia.\n\n"
                "FATICA: foco no canal. Exemplo: voce me escuta?\n\n"
                "METALINGUISTICA: fala sobre a lingua. Exemplo: "
                "a palavra medico e um substantivo.\n\n"
                "POETICA: foco na forma da mensagem. Exemplo: "
                "publicidade, literatura."
            ),
            "exemplo": (
                "Um anuncio de remedio na TV usa a funcao poetica "
                "quando recorre a rimas e musicas. Ja a bula do "
                "remedio usa a funcao referencial, pois busca "
                "informar com precisao. Uma campanha de vacinacao "
                "usa a funcao conativa, pois quer convencer o "
                "publico a se vacinar."
            ),
        },
        {
            "titulo": "3. Linguagem verbal e nao verbal",
            "conteudo": (
                "LINGUAGEM VERBAL: usa palavras, seja oral ou "
                "escrita. E codificada pela lingua.\n\n"
                "LINGUAGEM NAO VERBAL: usa gestos, expressoes "
                "faciais, postura, imagens, simbolos. "
                "Complementa ou substitui a linguagem verbal.\n\n"
                "VARIEDADES LINGUISTICAS: a lingua muda de "
                "acordo com o contexto. Variantes regionais "
                "(dialeto), sociais (fala de determinado grupo) "
                "e situacionais (formal vs. informal).\n\n"
                "REGISTRO FORMAL: emprego em documentos, "
                "discursos, provas. Evita gírias e abreviacoes.\n\n"
                "REGISTRO INFORMAL: conversas cotidianas, "
                "redes sociais. Aceita regionalismos e "
                "expressões coloquiais."
            ),
            "exemplo": (
                "No pronto-socorro, um medico pode usar linguagem "
                "nao verbal ao apontar para a cadeira para o "
                "paciente sentar. No prontuario, a linguagem "
                "e formal e objetiva. Ja a conversa com o "
                "paciente pode misturar linguagem tecnica e "
                "coloquial, dependendo da escolaridade do "
                "interlocutor."
            ),
        },
    ],
    "resumo": (
        "- Comunicacao: emissor, receptor, mensagem, codigo, canal, contexto.\n"
        "- Funcoes da linguagem: referencial, emotiva, conativa, fatica, metalinguistica, poetica.\n"
        "- Linguagem verbal: palavras. Nao verbal: gestos, imagens, postura.\n"
        "- Registros formal e informal. Variedades linguisticas."
    ),
    "dicas": [
        "A funcao referencial e a mais comum em textos informativos.",
        "Se a mensagem se preocupa com a forma, e poetica.",
        "Linguagem nao verbal complementa, mas pode contrariar a verbal.",
        "Registro formal evita gírias e marcas de oralidade.",
        "A funcao conativa usa imperativos e vocativos.",
        "A funcao metalinguistica fala sobre a propria lingua.",
    ],
    "pegadinhas": [
        "Confundir funcao emotiva com referencial: a primeira foca no emissor, a segunda na mensagem.",
        "Achar que toda linguagem nao verbal e universal: gestos podem variar culturalmente.",
        "Esquecer que o canal pode ser a internet, nao so fala ou escrita.",
        "Confundir ruido com mensagem: ruido e interferencia.",
        "Considerar que gíria e erro: gíria e uma variedade linguistica, nao necessariamente errado.",
        "Trocar conativa com fatica: conativa manda no receptor; fatica testa o canal.",
    ],
    "referencias": [
        "KOCH, I. G. V. Argumentacao e linguagem. 5. ed. Sao Paulo: Cortez, 2010.",
        "JAKOBSON, R. Linguistica e comunicacao. Sao Paulo: Cultrix, 1969.",
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "MARTELOTTA, M. Manual de gramatica. Sao Paulo: Contexto, 2012.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
        "Perini, M. A. A gramatica secundaria. Sao Paulo: Parabola, 2008.",
    ],
}

IMG_COMUNICACAO = [
    {"file": "pt_comunicacao.png", "caption": "Elementos do processo de comunicacao", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 5.2 Semantica
# ============================================================
SEMANTICA = {
    "titulo": "Semântica",
    "disciplina": "Lingua Portuguesa",
    "topico": "Semantica",
    "subtopico": "Sentido, polissemia, sinonimia, antonimia, homonimia",
    "introducao": (
        "A Semantica estuda o significado das palavras e "
        "expressoes. Saber distinguir sentido denotativo, "
        "conotativo e relacoes entre palavras e essencial para "
        "interpretacao de textos."
    ),
    "secoes": [
        {
            "titulo": "1. Significado e sentido",
            "conteudo": (
                "SIGNO: toda unidade de significacao formada por "
                "um significante (imagem acustica ou grafica) e "
                "um significado (conceito).\n\n"
                "SENTIDO DENOTATIVO: o sentido literal, objetivo, "
                "de uma palavra. Aparece nos dicionarios.\n\n"
                "SENTIDO CONOTATIVO: o sentido figurado, "
                "subjetivo, que evoca sensacoes, emocoes ou "
                "associacoes. Usado na literatura e propaganda.\n\n"
                "USO: o mesmo significante pode ter diferentes "
                "sentidos em contextos distintos."
            ),
            "exemplo": (
                "A palavra luz tem sentido denotativo de "
                "radiacao que ilumina. No poema, ela pode ter "
                "sentido conotativo de esperanca, conhecimento "
                "ou vida. O contexto e quem define qual sentido "
                "esta ativo."
            ),
        },
        {
            "titulo": "2. Relacoes de significado",
            "conteudo": (
                "SINONIMIA: palavras de sentidos iguais ou "
                "semelhantes. Exemplo: medico/clinico; feliz/"
                "alegre.\n\n"
                "ANTONIMIA: palavras de sentidos opostos. "
                "Exemplo: doente/sadio; vida/morte.\n\n"
                "HOMONIMIA: palavras iguais na pronuncia ou "
                "escrita, mas com sentidos diferentes. Pode ser "
                "homofonia (som igual, escrita diferente: acender/"
                "ascender) ou homografia (escrita igual, som "
                "diferente: saude).\n\n"
                "POLISSEMIA: uma palavra com varios sentidos "
                "relacionados. Exemplo: cabeca pode ser parte do "
                "corpo, chefia, cabeceira.\n\n"
                "PARONIMIA: palavras parecidas na pronuncia e "
                "escrita, mas com significados diferentes. "
                "Exemplo: eminente/iminente."
            ),
            "exemplo": (
                "Em farmacologia, muitas palavras sao paronimas "
                "e confundi-las e perigoso: anotar (escrever) "
                "e notar (perceber) tem sentidos distintos. Ja "
                "medicamento e remedio sao sinonimos no uso "
                "comum. A palavra comum e sensivel a contextos "
                "técnicos."
            ),
        },
        {
            "titulo": "3. Conotacao, ambiguidade e neologismo",
            "conteudo": (
                "AMBIGUIDADE: ocorre quando uma expressao pode "
                "ser interpretada de mais de uma maneira. "
                "Exemplo: Vi o medico com o binoculo.\n\n"
                "NEOLOGISMO: palavra nova criada para expressar "
                "um fenomeno recente. Muito comum em areas "
                "técnicas.\n\n"
                "ESTRANGEIRISMOS: palavras de outras linguas "
                "usadas no portugues. Exemplo: check-up, "
                "stress, feedback.\n\n"
                "DENOTACAO E CONOTACAO NA PROVA: textos "
                "literarios exploram a conotacao; textos "
                "normativos e cientificos privilegiam a "
                "denotacao."
            ),
            "exemplo": (
                "A frase O paciente esta bem pode ser ambigua: "
                "pode significar que a saude melhorou ou que "
                "esta em boa posicao. No prontuario, a "
                "escritura busca a denotacao, evitando "
                "ambiguidade. Ja um poema sobre a cura pode "
                "usar conotacoes."
            ),
        },
    ],
    "resumo": (
        "- Signo: significante + significado.\n"
        "- Denotacao: sentido literal. Conotacao: sentido figurado.\n"
        "- Sinonimia: sentidos proximos. Antonimia: opostos.\n"
        "- Homonimia: palavras iguais com sentidos diferentes.\n"
        "- Polissemia: varios sentidos relacionados. Paronimia: palavras parecidas.\n"
        "- Ambiguidade: mais de uma interpretacao."
    ),
    "dicas": [
        "Leia o contexto para decidir se o sentido e denotativo ou conotativo.",
        "Sinonimo perfeito e raro; geralmente ha nuances.",
        "Homofonia e sobre o som; homografia e sobre a escrita.",
        "Neologismos e estrangeirismos sao comuns na medicina.",
        "Para eliminar ambiguidade, reescreva a frase.",
        "Conotacao aparece em literatura, publicidade e discursos emotivos.",
    ],
    "pegadinhas": [
        "Achar que sinonimos tem sentido identico: quase sempre ha pequena diferenca.",
        "Confundir homonimia com polissemia: na polissemia os sentidos sao relacionados.",
        "Esquecer que o contexto define o sentido conotativo.",
        "Achar que toda ambiguidade e erro: em poesia pode ser proposital.",
        "Confundir paronimia com sinonimia: paronimos sao parecidos, mas distintos.",
        "Considerar neologismo como erro linguistico: todo neologismo comeca como inovacao.",
    ],
    "referencias": [
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "MARTELOTTA, M. Manual de gramatica. Sao Paulo: Contexto, 2012.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
        "KOCH, I. G. V. Argumentacao e linguagem. 5. ed. Sao Paulo: Cortez, 2010.",
        "Perini, M. A. A gramatica secundaria. Sao Paulo: Parabola, 2008.",
        "Airaghi, A. E. Significado e sentido na lingua. Campinas: Pontes, 2004.",
    ],
}

IMG_SEMANTICA = [
    {"file": "pt_semantica.png", "caption": "Denotacao e conotacao da palavra sol", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 5.3 Texto e Textualidade
# ============================================================
TEXTO = {
    "titulo": "Texto e Textualidade",
    "disciplina": "Lingua Portuguesa",
    "topico": "Texto e Textualidade",
    "subtopico": "Coesao, coerencia, tipos e generos textuais",
    "introducao": (
        "Texto e toda unidade de sentido organizada de forma "
        "coesa e coerente. A textualidade e garantida por "
        "propriedades que tornam um conjunto de frases um "
        "texto."
    ),
    "secoes": [
        {
            "titulo": "1. Propriedades da textualidade",
            "conteudo": (
                "COESAO: relacao gramatical entre as partes do "
                "texto. Usa conectivos, pronomes, artigos, "
                "repeticoes.\n\n"
                "COERENCIA: relacao semantica, o sentido logico. "
                "Faz o texto fazer sentido.\n\n"
                "INTENCIONALIDADE: todo texto tem um proposito, "
                "uma intencao comunicativa.\n\n"
                "SITUACIONALIDADE: o texto e adequado ao contexto "
                "e ao interlocutor.\n\n"
                "INTERTEXTUALIDADE: relacao com outros textos, "
                "citacoes, referencias, estereotipos.\n\n"
                "INFORMACIONALIDADE: o conteudo deve ser novo ou "
                "relevante para o receptor."
            ),
            "exemplo": (
                "Um prontuario medico tem coesao porque usa "
                "conectivos temporais e pronomes, e coerencia "
                "porque os fatos sao apresentados em ordem "
                "logica. A intencionalidade e informar a equipe; "
                "a situacionalidade e o ambiente hospitalar; a "
                "intertextualidade sao os exames e prescricoes "
                "referenciados."
            ),
        },
        {
            "titulo": "2. Tipos e generos textuais",
            "conteudo": (
                "TIPOS TEXTUAIS: categorias baseadas na "
                "predominancia da funcao da linguagem.\n"
                "- Narrativo: conta uma historia.\n"
                "- Descritivo: descreve caracteristicas.\n"
                "- Dissertativo-argumentativo: expoe ideias e "
                "opinioes.\n"
                "- Informativo: transmite dados.\n"
                "- Injuntivo: instrui, ordena.\n\n"
                "GENEROS TEXTUAIS: formas concretas de texto, "
                "ligadas a situacoes de uso. Exemplos: noticia, "
                "receita, bula, carta, resenha, editorial, "
                "prontuario, relatorio.\n\n"
                "TIPO vs. GENERO: o tipo e abstrato; o genero e "
                "uma realizacao concreta."
            ),
            "exemplo": (
                "Uma bula de medicamento e o genero textual; o "
                "tipo predominante e o informativo, com partes "
                "injuntivas (como usar). Um editorial de jornal "
                "e do tipo dissertativo-argumentativo. Uma "
                "noticia e informativa."
            ),
        },
        {
            "titulo": "3. Argumentacao e persuasao",
            "conteudo": (
                "ARGUMENTACAO: estrategia de defender um ponto de "
                "vista. Requer tese, argumentos e conclusao.\n\n"
                "TIPOS DE ARGUMENTO:\n"
                "- Autoridade: citar especialistas.\n"
                "- Exemplo: apresentar casos concretos.\n"
                "- Comparacao: contrapontos.\n"
                "- Estatistica: usar numeros.\n"
                "- Causa e efeito: demonstrar consequencias.\n\n"
                "FALACIAS: raciocinios aparentemente validos, mas "
                "falsos. Exemplo: generalizacao rapida, ataque "
                "ad hominem, falso dilema.\n\n"
                "COESAO ARGUMENTATIVA: marcadores como portanto, "
                "entretanto, logo, assim, porem, alem disso."
            ),
            "exemplo": (
                "Em uma campanha anti-tabagismo, a autoridade "
                "medica e usada para convencer fumantes a "
                "pararem. A tese e que fumar causa cancer; o "
                "argumento de autoridade cita a OMS; os dados "
                "estatisticos mostram a relacao causa-efeito. "
                "A conclusao e a recomendacao de parar de fumar."
            ),
        },
    ],
    "resumo": (
        "- Textualidade: coesao, coerencia, intencionalidade, situacionalidade, intertextualidade.\n"
        "- Tipos: narrativo, descritivo, dissertativo-argumentativo, informativo, injuntivo.\n"
        "- Generos: formas concretas (noticia, bula, carta, prontuario).\n"
        "- Argumentacao: tese, argumentos, conclusao. Cuidado com falacias."
    ),
    "dicas": [
        "Coesao e gramatical; coerencia e semantica.",
        "Tipo textual e abstrato; genero e concreto.",
        "A narrativa conta fatos; a dissertacao defende ideias.",
        "Argumento de autoridade pode falhar se a fonte nao for confiavel.",
        "Marcadores de coesao: portanto, contudo, alem disso, por exemplo.",
        "Intertextualidade: citacoes, alusoes, estereotipos. Pode ser direta ou indireta.",
    ],
    "pegadinhas": [
        "Achar que coesao e coerencia sao a mesma coisa: uma e gramatical, outra e de sentido.",
        "Confundir tipo com genero textual.",
        "Esquecer que todo texto tem intencao comunicativa.",
        "Considerar todo argumento de autoridade infalivel.",
        "Nao reconhecer falacias em textos argumentativos.",
        "Achar que intertextualidade so e citacao explicita: tambem pode ser alusao implicita.",
    ],
    "referencias": [
        "KOCH, I. G. V. Argumentacao e linguagem. 5. ed. Sao Paulo: Cortez, 2010.",
        "MARCUSCHI, L. A. Produzao textual, analise de generos e compreensao. Sao Paulo: Parabola, 2008.",
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
        "Perini, M. A. A gramatica secundaria. Sao Paulo: Parabola, 2008.",
        "Cosi, D. R. et al. Generos textuais e ensino. Campinas: Mercado de Letras, 2011.",
    ],
}

IMG_TEXTO = [
    {"file": "pt_textualidade.png", "caption": "Elementos da textualidade", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 5.4 Morfossintaxe
# ============================================================
MORFOSSINTAXE = {
    "titulo": "Morfossintaxe",
    "disciplina": "Lingua Portuguesa",
    "topico": "Morfossintaxe",
    "subtopico": "Classes de palavras, flexao, colocacao pronominal e regencia",
    "introducao": (
        "A Morfossintaxe estuda como as palavras se formam "
        "(morfologia) e como se organizam nas frases (sintaxe). "
        "Dominar classes gramaticais e regencia e essencial "
        "para a prova de portugues."
    ),
    "secoes": [
        {
            "titulo": "1. Classes gramaticais",
            "conteudo": (
                "VARIAVEIS: "
                "- Substantivo: nome de seres, objetos, conceitos.\n"
                "- Adjetivo: qualifica o substantivo.\n"
                "- Artigo: determina o substantivo.\n"
                "- Numeral: indica quantidade, ordem.\n"
                "- Pronome: substitui o nome.\n"
                "- Verbo: exprime acao, estado, fenomeno.\n\n"
                "INVARIAVEIS:\n"
                "- Adverbio: modifica o verbo, o adjetivo ou outro "
                "adverbio.\n"
                "- Preposicao: liga palavras e estabelece relacoes.\n"
                "- Conjuncao: liga oracoes ou termos.\n"
                "- Interjeicao: exprime emocao.\n\n"
                "MORFEMAS: unidades minimas de significado. "
                "Radical + afixos."
            ),
            "exemplo": (
                "Na frase O medico observou atentamente o "
                "paciente, O e artigo, medico e substantivo, "
                "observou e verbo, atentamente e adverbio, o e "
                "artigo, paciente e substantivo. A preposicao "
                "nao aparece, mas poderia em outra versao."
            ),
        },
        {
            "titulo": "2. Colocacao pronominal e regencia",
            "conteudo": (
                "PRONOMES PESSOAIS: eu, tu, ele, nos, vos, eles, "
                "me, te, se, o, a, lhe, meu, teu.\n\n"
                "COLOCACAO PRONOMINAL: posicao do pronome obliquo "
                "em relacao ao verbo.\n"
                "- Proclise: pronome antes do verbo (nao gosto).\n"
                "- Mesoclise: pronome no meio do verbo (falar-lhe-ia).\n"
                "- Enclise: pronome depois do verbo (gosto-me).\n\n"
                "CASOS DE PROCLISE: palavra negativa, adverbio, "
                "pronome relativo, conjuncao subordinativa, "
                "modo imperativo negativo.\n\n"
                "REGENCIA VERBAL: verbos que exigem preposicao. "
                "Exemplo: gostar de, obedecer a, prescindir de.\n\n"
                "REGENCIA NOMINAL: nomes que exigem preposicao. "
                "Exemplo: amor a, necessidade de."
            ),
            "exemplo": (
                "A expressao assistir ao paciente pode ser "
                "ambiguidade: assistir a (ver) ou assistir "
                "(prestar assistencia). A regencia verbal define "
                "o sentido. Da mesma forma, gostar de exige a "
                "preposicao de, enquanto obedecer a exige a."
            ),
        },
        {
            "titulo": "3. Concordancia e flexao",
            "conteudo": (
                "CONCORDANCIA VERBAL: o verbo concorda com o "
                "sujeito em numero e pessoa.\n\n"
                "CONCORDANCIA NOMINAL: o adjetivo concorda com o "
                "substantivo em genero e numero.\n\n"
                "FLEXAO VERBAL: modos (indicativo, subjuntivo, "
                "imperativo), tempos, numeros e pessoas.\n\n"
                "FLEXAO NOMINAL: genero (masculino, feminino) e "
                "numero (singular, plural).\n\n"
                "CRASE: juncao de duas vogais identicas, "
                "preposicao a + artigo a. Exemplo: vou a farmacia. "
                "Havendo preposicao a e artigo feminino a, ocorre "
                "o acento grave."
            ),
            "exemplo": (
                "A equipe medica se reuniu. O sujeito e a equipe "
                "medica, portanto o verbo fica no singular. Ja "
                "em A maioria dos medicos concordou, se o sujeito "
                "e coletivo partitivo, o verbo concorda com a "
                "palavra que determina a parte: concordou (a "
                "maioria). Se for A maioria dos medicos "
                "concordaram, a concordancia e com medicos, "
                "pela silepse de numero."
            ),
        },
    ],
    "resumo": (
        "- Classes gramaticais: variaveis e invariaveis.\n"
        "- Colocacao pronominal: proclise, mesoclise, enclise.\n"
        "- Regencia verbal e nominal.\n"
        "- Concordancia verbal e nominal.\n"
        "- Crase: preposicao a + artigo a.\n"
        "- Flexao: genero, numero, modo, tempo."
    ),
    "dicas": [
        "Se houver palavra negativa, use proclise.",
        "Na ordem direta, o pronome vem depois do verbo (enclise).",
        "Mesoclise ocorre em futuro do presente e futuro do preterito.",
        "Crase: preposicao a + artigo feminino a; preposicao a + pronome demonstrativo a(s).",
        "Concordancia com coletivo partitivo: verbo concorda com o termo que especifica a parte.",
        "Regencia nominal: verifique se o nome exige preposicao.",
    ],
    "pegadinhas": [
        "Achar que toda palavra terminada em o e masculina e em a e feminina: ha excecoes.",
        "Esquecer que a preposicao e o nucleo da regencia.",
        "Usar mesoclise em tempos que nao permitem.",
        "Esquecer o artigo feminino depois da preposicao a na crase.",
        "Concordar o verbo com o complemento e nao com o sujeito.",
        "Confundir adverbio com adjetivo: o adverbio modifica verbo/adjetivo/adverbio.",
    ],
    "referencias": [
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
        "MARTELOTTA, M. Manual de gramatica. Sao Paulo: Contexto, 2012.",
        "Perini, M. A. A gramatica secundaria. Sao Paulo: Parabola, 2008.",
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
    ],
}

IMG_MORFOSSINTAXE = [
    {"file": "pt_morfossintaxe.png", "caption": "Principais classes gramaticais", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (COMUNICACAO, "PT_COMUNICACAO_LINGUAGEM.pdf", IMG_COMUNICACAO, "Lingua Portuguesa — Comunicacao e Linguagem"),
        (SEMANTICA, "PT_SEMANTICA.pdf", IMG_SEMANTICA, "Lingua Portuguesa — Semantica"),
        (TEXTO, "PT_TEXTO_TEXTUALIDADE.pdf", IMG_TEXTO, "Lingua Portuguesa — Texto e Textualidade"),
        (MORFOSSINTAXE, "PT_MORFOSSINTAXE.pdf", IMG_MORFOSSINTAXE, "Lingua Portuguesa — Morfossintaxe"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
