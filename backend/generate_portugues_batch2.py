"""Gera PDFs de Lingua Portuguesa — batch 2 (topicos 5.5 a 5.7)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 5.5 Sintaxe do Periodo
# ============================================================
SINTAXE = {
    "titulo": "Sintaxe do Período",
    "disciplina": "Lingua Portuguesa",
    "topico": "Sintaxe do Periodo",
    "subtopico": "Termos da oracao, periodo simples e composto, coordenacao e subordinacao",
    "introducao": (
        "A Sintaxe do Periodo estuda a organizacao das palavras "
        "nas oracoes e a relacao entre elas. Saber reconhecer "
        "termos e tipos de periodo e essencial para a prova."
    ),
    "secoes": [
        {
            "titulo": "1. Termos da oracao",
            "conteudo": (
                "SUJEITO: quem ou o que pratica a acao. Pode ser "
                "simples, composto, oculto, indeterminado.\n\n"
                "PREDICADO: o que se diz sobre o sujeito. Pode "
                "ser verbo-nominal, nominal ou verbal.\n\n"
                "TERMOS ESSENCIAIS: sujeito e predicado.\n\n"
                "TERMOS INTEGRANTES: objeto direto (OD), objeto "
                "indireto (OI), complemento nominal (CN), "
                "predicativo (P).\n\n"
                "TERMOS ACESSORIOS: aposto, vocativo, adjunto "
                "adverbial, adjunto adnominal.\n\n"
                "AGENTE DA PASSIVA: em voz passiva, o sujeito "
                "sofre a acao; o agente e quem realiza a acao."
            ),
            "exemplo": (
                "Na frase O medico receitou o remedio ao "
                "paciente ontem, O medico e o sujeito, "
                "receitou e o nucleo do predicado, o remedio "
                "e o objeto direto, ao paciente e o objeto "
                "indireto e ontem e o adjunto adverbial de tempo."
            ),
        },
        {
            "titulo": "2. Periodo simples e periodo composto",
            "conteudo": (
                "PERIODO SIMPLES: contem apenas uma oracao. Exemplo: "
                "O paciente dormiu.\n\n"
                "PERIODO COMPOSTO: contem duas ou mais oracoes.\n\n"
                "COORDENACAO: oracoes independentes, com mesmo "
                "valor sintatico. Conjunções coordenativas: "
                "aditivas (e, nem, mas ainda), adversativas (mas, "
                "porem, contudo), alternativas (ou, ora... ora), "
                "conclusivas (logo, portanto, por isso), "
                "explicativas (pois, porque).\n\n"
                "SUBORDINACAO: uma oracao depende da outra. "
                "Substantivas, adjetivas, adverbiais.\n\n"
                "PERIODO COMPOSTO POR COORDENACAO: oracoes "
                "coordenadas.\n\n"
                "PERIODO COMPOSTO POR SUBORDENACAO: oracoes "
                "subordinadas.\n\n"
                "PERIODO COMPOSTO MISTO: coordenacao e "
                "subordinacao juntas."
            ),
            "exemplo": (
                "O paciente tomou o remedio e dormiu, pois "
                "estava cansado e contem tres oracoes. "
                "O paciente tomou o remedio e dormiu e coordenada "
                "aditiva. dormiu, pois estava cansado e coordenada "
                "explicativa, mas a segunda oracao e subordinada "
                "causal (porque estava cansado)."
            ),
        },
        {
            "titulo": "3. Oracoes subordinadas",
            "conteudo": (
                "ORACOES SUBSTANTIVAS: funcionam como substantivo. "
                "Classificam-se em: subjetiva, predicativa, "
                "objetiva direta, objetiva indireta, apositiva, "
                "completiva nominal.\n\n"
                "ORACOES ADJETIVAS: funcionam como adjetivo. "
                "Explicativas ou restritivas.\n\n"
                "ORACOES ADVERBIAIS: funcionam como adverbio. "
                "Causais, consecutivas, condicionais, "
                "concessivas, temporais, proporcionais, "
                "comparativas, finais.\n\n"
                "ORACOES REDUZIDAS: sem conjuncao e sem verbo "
                "finito. Podem ser participiais, gerundiais ou "
                "infinitivas."
            ),
            "exemplo": (
                "E importante que o paciente descanse. A oracao "
                "que o paciente descanse e uma oracao "
                "subordinada substantiva subjetiva, pois exerce "
                "a funcao de sujeito. Em O remédio que o medico "
                "prescreveu e bom, que o medico prescreveu e uma "
                "oracao subordinada adjetiva restritiva, "
                "especificando qual remedio."
            ),
        },
    ],
    "resumo": (
        "- Termos: sujeito, predicado, objetos, complementos, acessorios.\n"
        "- Periodo simples: uma oracao. Composto: duas ou mais.\n"
        "- Coordenacao: oracoes independentes.\n"
        "- Subordinacao: oracao depende de outra.\n"
        "- Oracoes substantivas, adjetivas e adverbiais.\n"
        "- Oracoes reduzidas: participial, gerundial, infinitiva."
    ),
    "dicas": [
        "Objeto direto nao tem preposicao; objeto indireto tem.",
        "Complemento nominal completa um nome, nao o verbo.",
        "Conjuncoes coordenativas nao causam subordinacao.",
        "Subordinada adjetiva e introduzida por pronome relativo.",
        "Subordinada substantiva geralmente comeca com conjuncao integrante (que, se).",
        "Oracao reduzida nao tem verbo flexionado no modo indicativo/subjuntivo.",
    ],
    "pegadinhas": [
        "Confundir objeto direto com sujeito em voz passiva.",
        "Achar que toda oracao iniciada por que e subordinada adjetiva: pode ser substantiva.",
        "Esquecer que oracao coordenada pode ser assindeta (sem conjuncao).",
        "Confundir complemento nominal com objeto indireto.",
        "Achar que oracao subordinada sempre vem depois da principal: pode vir antes.",
        "Esquecer que adjunto adverbial responde a circunstancias (quando, como, onde, por que).",
    ],
    "referencias": [
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
        "Bechara, E. Moderna gramatica portuguesa. 37. ed. Rio de Janeiro: Nova Fronteira, 2009.",
        "MARTELOTTA, M. Manual de gramatica. Sao Paulo: Contexto, 2012.",
        "Perini, M. A. A gramatica secundaria. Sao Paulo: Parabola, 2008.",
        "Napoleao, M. Sintaxe do periodo. 8. ed. Sao Paulo: Atual, 1998.",
        "Cegalla, D. P. Novissima gramatica da lingua portuguesa. 47. ed. Sao Paulo: Nacional, 2011.",
    ],
}

IMG_SINTAXE = [
    {"file": "pt_sintaxe_periodo.png", "caption": "Periodo composto por coordenacao", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 5.6 Literatura
# ============================================================
LITERATURA = {
    "titulo": "Literatura",
    "disciplina": "Lingua Portuguesa",
    "topico": "Literatura",
    "subtopico": "Movimentos literarios, autores e contexto historico",
    "introducao": (
        "A Literatura brasileira passou por movimentos que "
        "refletem o contexto historico e social do pais. "
        "Conhecer os autores, as obras e as caracteristicas de "
        "cada epoca e fundamental."
    ),
    "secoes": [
        {
            "titulo": "1. Arcadismo e Romantismo",
            "conteudo": (
                "ARCADISMO (seculo XVIII): valorizava a razao, "
                "a natureza e a simplicidade. Poesia lirica, "
                "bucolismo, pastores, amor platônico. Autores: "
                "Bocage, Tomas Antonio Gonzaga, Claudio Manuel da "
                "Costa.\n\n"
                "ROMANTISMO (seculo XIX): emocao, subjetividade, "
                "exaltacao do eu e do nacionalismo. Na India "
                "(indianismo) e no sertao (regionalismo). Autores: "
                "Goncalves Dias, Jose de Alencar, Castro Alves, "
                "Casimiro de Abreu.\n\n"
                "Fases do Romantismo:\n"
                "- Nacionalista/social: indianismo e abolicionismo.\n"
                "- Ultra-Romantismo: amor, morte, melancolia."
            ),
            "exemplo": (
                "A obra Iracema, de Jose de Alencar, e um "
                "romance indianista que idealiza o indio e a "
                "natureza brasileira. A obra reflete o "
                "nacionalismo romantico e a busca por uma "
                "identidade literaria nacional."
            ),
        },
        {
            "titulo": "2. Realismo, Naturalismo e Parnasianismo",
            "conteudo": (
                "REALISMO (final do seculo XIX): critica social, "
                "observacao da realidade sem idealizacao. "
                "Personagens comuns, linguagem fiel a sociedade. "
                "Autores: Machado de Assis, Aluisio Azevedo, "
                "Raul Pompeia.\n\n"
                "NATURALISMO: heranca do realismo, com "
                "determinismo, personagens dominados por "
                "instintos e ambiente. O Cortico e exemplo "
                "central.\n\n"
                "PARNASIANISMO: poesia pela poesia, valorizacao "
                "da forma, rigor tecnico, frieza emocional. "
                "Autores: Olavo Bilac, Alberto de Oliveira, "
                "Raimundo Correia."
            ),
            "exemplo": (
                "Memorias Postumas de Bras Cubas, de Machado de "
                "Assis, inaugura o Realismo no Brasil. O narrador "
                "defunto-Bras Cubas-reflete sobre a sociedade "
                "carioca do seculo XIX com ironia e critica. O "
                "livro mistura humor, filosofia e analise "
                "psicologica."
            ),
        },
        {
            "titulo": "3. Simbolismo, Modernismo e pos-Modernismo",
            "conteudo": (
                "SIMBOLISMO (fim do seculo XIX): subjetividade, "
                "musicalidade, simbolos, espiritualidade. "
                "Autores: Cruz e Sousa, Alphonsus de Guimaraens, "
                "Catulo da Paixao Cearense.\n\n"
                "MODERNISMO (seculo XX): ruptura com a "
                "literatura anterior. Linguagem livre, temas "
                "urbanos e nacionalistas. Semana de Arte Moderna "
                "em 1922. Autores: Mario de Andrade, Oswald de "
                "Andrade, Manuel Bandeira, Carlos Drummond de "
                "Andrade.\n\n"
                "POS-MODERNISMO (final do seculo XX): fragmentacao, "
                "questoes identitarias, novas linguagens. "
                "Autores: Caio Fernando Abreu, Joao Gilberto "
                "Noll."
            ),
            "exemplo": (
                "Macunaima, de Mario de Andrade, e uma obra "
                "modernista que reune lendas, mitos e a cultura "
                "brasileira. A frase rapsodia heroica e a "
                "linguagem inventiva marcam a vanguarda do "
                "modernismo."
            ),
        },
    ],
    "resumo": (
        "- Arcadismo: razao, natureza, bucolismo.\n"
        "- Romantismo: emocao, nacionalismo, indianismo.\n"
        "- Realismo: critica social, observacao da realidade.\n"
        "- Naturalismo: determinismo, ambiente, instintos.\n"
        "- Parnasianismo: forma, poesia pelo poesia.\n"
        "- Simbolismo: simbolos, subjetividade, musicalidade.\n"
        "- Modernismo: ruptura, linguagem livre, nacionalismo."
    ),
    "dicas": [
        "Arcadismo e da virada para o seculo XIX; Romantismo e seculo XIX.",
        "Realismo e Naturalismo sao proximos, mas o Naturalismo enfatiza o determinismo.",
        "Parnasianismo preza a forma e a perfeicao tecnica.",
        "Simbolismo e subjetivo e musical; Modernismo e inovador e urbano.",
        "Machado de Assis e o maior nome do Realismo brasileiro.",
        "A Semana de Arte Moderna ocorreu em 1922, em Sao Paulo.",
    ],
    "pegadinhas": [
        "Confundir Romantismo com Realismo: o primeiro idealiza, o segundo critica a realidade.",
        "Esquecer que o Indianismo e uma fase do Romantismo.",
        "Achar que Parnasianismo e subjetivo: e formal e racional.",
        "Confundir Naturalismo com Realismo: o primeiro e mais extremo no determinismo.",
        "Esquecer que o Modernismo brasileiro e diferente do europeu: tem forte nacionalismo.",
        "Pensar que Simbolismo e so melancolia: tambem busca a musicalidade e o simbolo.",
    ],
    "referencias": [
        "CANDIDO, A. Literatura e sociedade. Sao Paulo: Editora da Universidade de Sao Paulo, 2006.",
        "CANDIDO, A. Formacao da literatura brasileira. 2. ed. Belo Horizonte: Itatiaia, 2010.",
        "BOSI, A. Historia concisa da literatura brasileira. 5. ed. Sao Paulo: Cultrix, 2006.",
        "MOISES, M. A literatura brasileira. 2. ed. Sao Paulo: Edusp, 1998.",
        "HOLANDA, S. B. Raizes do Brasil. 26. ed. Sao Paulo: Companhia das Letras, 2011.",
        "LINS, O. História da literatura brasileira. 8. ed. Rio de Janeiro: Nova Fronteira, 2006.",
    ],
}

IMG_LITERATURA = [
    {"file": "pt_literatura.png", "caption": "Principais movimentos da literatura brasileira", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 5.7 Obras de Leitura Obrigatoria
# ============================================================
OBRAS = {
    "titulo": "Obras de Leitura Obrigatória",
    "disciplina": "Lingua Portuguesa",
    "topico": "Obras de Leitura Obrigatoria",
    "subtopico": "Analise das obras e autores exigidos no PAES",
    "introducao": (
        "A prova de Lingua Portuguesa pode exigir conhecimento "
        "direto ou interpretativo de obras de leitura "
        "obrigatoria. Recomenda-se conhecer enredo, personagens, "
        "tema, contexto e estilo."
    ),
    "secoes": [
        {
            "titulo": "1. Como estudar as obras",
            "conteudo": (
                "EIXOS DE LEITURA:\n"
                "- Enredo: cadeia de acontecimentos.\n"
                "- Personagens: principais e secundarios.\n"
                "- Narrador: quem conta a historia.\n"
                "- Espaco e tempo: onde e quando se passa.\n"
                "- Tema: assunto central.\n"
                "- Estilo: como o autor escreve.\n\n"
                "NARRADOR:\n"
                "- 1a pessoa: o proprio personagem narra.\n"
                "- 3a pessoa: narrador externo. Pode ser onisciente "
                "ou observador.\n\n"
                "FOCO NARRATIVO: determina quem sabe e quem ve "
                "os fatos. Pode ser do narrador, de um "
                "personagem ou multiplo."
            ),
            "exemplo": (
                "Em Memorias Postumas de Bras Cubas, o narrador "
                "e o proprio Bras Cubas, falando apos a morte. "
                "A 1a pessoa ironica cria um distanciamento "
                "critico. Ja Vidas Secas, de Graciliano Ramos, "
                "alterna o foco entre personagens, mostrando a "
                "dureza do sertanejo."
            ),
        },
        {
            "titulo": "2. Obras mais cobradas",
            "conteudo": (
                "MEMORIAS POSTUMAS DE BRAS CUBAS (Machado de "
                "Assis): realismo, ironia, critica social. "
                "Narrador-Bras Cubas-conta sua vida com "
                "desencanto.\n\n"
                "O CORTICO (Aluisio Azevedo): naturalismo. "
                "Vida num cortico do Rio de Janeiro, "
                "determinismo, paixoes, ambiente degradante.\n\n"
                "VIDAS SECAS (Graciliano Ramos): regionalismo "
                "nordestino, familia de retirantes, linguagem "
                "seca e objetiva.\n\n"
                "GRANDE SERTAO: VEREDAS (Joao Guimaraes Rosa): "
                "modernismo, linguagem rica e inventiva, sertao, "
                "confito entre jagunco e padre, narrador Riobaldo.\n\n"
                "IRACEMA (Jose de Alencar): indianismo, amor "
                "tragico, exotismo, nacionalismo."
            ),
            "exemplo": (
                "Grande Sertao: Veredas comeca com a famosa "
                "pergunta: Diadorim, meu, eu estou aqui. A obra "
                "explora o sertao, a figura do jagunco, o "
                "conflito moral e a linguagem inventiva. O "
                "sertao e uma personagem, e a narrativa mistura "
                "oralidade e modernismo."
            ),
        },
        {
            "titulo": "3. Analise e interpretacao",
            "conteudo": (
                "INTERPRETAR CORRETAMENTE: atenha-se ao texto. "
                "Nao projetar ideias externas.\n\n"
                "INTERFERENCIA: preconceitos e conhecimentos "
                "previos podem distorcer a leitura.\n\n"
                "INFERENCIA: conclusoes baseadas no que o texto "
                "diz, mesmo sem ser explicito.\n\n"
                "LITERATURA E CONTEXTO: muitas questoes ligam a "
                "obra a sua epoca. Conheca o seculo e o "
                "movimento.\n\n"
                "CITACOES: atente para trechos citados na prova. "
                "Eles indicam a resposta correta."
            ),
            "exemplo": (
                "Se a prova cita um trecho de O Cortico e "
                "pergunta sobre o determinismo, lembre-se de que "
                "Aluisio Azevedo mostra os personagens sendo "
                "conduzidos pelo ambiente e pelas paixoes. O "
                "cortico nao e so cenario: e uma forca que "
                "molda as vidas."
            ),
        },
    ],
    "resumo": (
        "- Estude enredo, personagens, narrador, espaco, tempo, tema e estilo.\n"
        "- Narrador em 1a ou 3a pessoa; foco onisciente ou observador.\n"
        "- Obras: Memorias Postumas, O Cortico, Vidas Secas, Grande Sertao: Veredas, Iracema.\n"
        "- Leia o texto atentamente e evite projeccoes externas.\n"
        "- Relacione a obra ao movimento e ao contexto historico."
    ),
    "dicas": [
        "Memorias Postumas comeca com o narrador defunto: e ironia e Realismo.",
        "O Cortico e Naturalismo: ambiente determina as pessoas.",
        "Vidas Secas: linguagem curta e seca, como o sertao.",
        "Grande Sertao: Veredas: linguagem dificil, mas valiosa. Leia trechos.",
        "Iracema: indianismo e amor impossivel.",
        "Nas questoes de literatura, o contexto da obra e a epoca ajudam muito.",
    ],
    "pegadinhas": [
        "Confundir Machado de Assis com Realismo e nao notar a ironia.",
        "Esquecer que O Cortico e Naturalismo, nao simples Realismo.",
        "Achar que Vidas Secas e so regionalismo: tambem e existencial.",
        "Esquecer que Grande Sertao: Veredas tem linguagem regional e vanguardista.",
        "Projetar opinioes pessoais na interpretacao.",
        "Nao ligar a obra ao movimento literario correto.",
    ],
    "referencias": [
        "CANDIDO, A. Formacao da literatura brasileira. 2. ed. Belo Horizonte: Itatiaia, 2010.",
        "BOSI, A. Historia concisa da literatura brasileira. 5. ed. Sao Paulo: Cultrix, 2006.",
        "LINS, O. História da literatura brasileira. 8. ed. Rio de Janeiro: Nova Fronteira, 2006.",
        "MENDES, M. A. Literatura brasileira: textos e contextos. 3. ed. Sao Paulo: Moderna, 2009.",
        "ASSIS, M. Memorias Postumas de Bras Cubas. Sao Paulo: Martin Claret, 2009.",
        "AZEVEDO, A. O Cortico. Sao Paulo: Martin Claret, 2009.",
    ],
}

IMG_OBRAS = [
    {"file": "pt_obras.png", "caption": "Obras de leitura obrigatoria do PAES", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (SINTAXE, "PT_SINTAXE_PERIODO.pdf", IMG_SINTAXE, "Lingua Portuguesa — Sintaxe do Periodo"),
        (LITERATURA, "PT_LITERATURA.pdf", IMG_LITERATURA, "Lingua Portuguesa — Literatura"),
        (OBRAS, "PT_OBRAS_LEITURA.pdf", IMG_OBRAS, "Lingua Portuguesa — Obras de Leitura"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
