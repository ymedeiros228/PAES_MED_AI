# -*- coding: utf-8 -*-
"""Gera PDFs de Historia — batch 2 (topicos 8.4 a 8.6)."""

from pdf_base import generate_educational_pdf
from historia_real_images import REAL_IMAGES

# ============================================================
# 8.4 Idade Contemporanea
# ============================================================
CONTEMPORANEA = {
    "titulo": "Idade Contemporanea",
    "disciplina": "Historia",
    "topico": "Idade Contemporanea",
    "subtopico": "Revolucoes, guerras mundiais, imperialismo e ideologias",
    "introducao": (
        "A Idade Contemporanea comeca com a Revolucao Francesa "
        "(1789) e chega aos dias atuais. Marcada por revolucoes, "
        "guerras mundiais, imperialismo, fascismos e Guerra Fria."
    ),
    "secoes": [
        {
            "titulo": "1. Revolucao Francesa e Revolucao Industrial",
            "conteudo": (
                "REVOLUCAO FRANCESA (1789):\n"
                "- Causas: absolutismo, crise economica, "
                "desigualdade social, influencia iluminista.\n"
                "- Fases: Assembleia Nacional, Monarquia "
                "Constitucional, Republica, Terror, Diretorio.\n"
                "- Lema: liberdade, igualdade, fraternidade.\n"
                "- Fim dos privilegios, Declaracao dos Direitos "
                "do Homem.\n"
                "- Napoleao Bonaparte: expansao militar.\n\n"
                "REVOLUCAO INDUSTRIAL (sec XIX):\n"
                "- 1a fase: maquina a vapor, texteis.\n"
                "- 2a fase: eletricidade, petroleo, quimica.\n"
                "- Urbanizacao, proletariado, sindicalismo.\n"
                "- Taylorismo: organizacao cientifica do trabalho.\n"
                "- Fordismo: linha de montagem, producao em massa."
            ),
            "exemplo": (
                "O fordismo revolucionou a producao: Henry Ford "
                "introduziu a linha de montagem em 1913, reduzindo "
                "o tempo de montagem de um carro de 12 horas para "
                "1,5 horas. Isso barateou produtos e aumentou "
                "salarios, mas tambem intensificou o trabalho e "
                "gerou alienacao operaria."
            ),
        },
        {
            "titulo": "2. Imperialismo e Independencias",
            "conteudo": (
                "IMPERIALISMO/NEOIMPERIALISMO (sec XIX-XX):\n"
                "- Partilha da Africa (Conferencia de Berlim, 1884).\n"
                "- Colonias na Asia e Oceania.\n"
                "- Motivos: materias-primas, mercados, prestigio.\n"
                "- Neoimperialismo: dominio economico sem ocupacao.\n\n"
                "INDEPENDENCIAS:\n"
                "- EUA (1776): Declaracao de Independencia.\n"
                "- America Latina (1808-1825): Bolivar, San Martin.\n"
                "- Brasil (1822): D. Pedro I, grito do Ipiranga.\n\n"
                "RACISMO E CULTURA AFRO-BRASILEIRA:\n"
                "- Racismo scientifico no sec XIX.\n"
                "- Cultura afro-brasileira: candomble, capoeira, "
                "samba, culinaria.\n"
                "- Abolicao da escravatura: Brasil 1888 (ultima)."
            ),
            "exemplo": (
                "A Conferencia de Berlim (1884-1885) dividiu a "
                "Africa entre potencias europeias sem consultar "
                "os povos africanos. As fronteiras artificiais "
                "ignoraram etnias e culturas, gerando conflitos "
                "que persistem ate hoje. O neoimperialismo "
                "continua com dominio economico."
            ),
        },
        {
            "titulo": "3. Guerras Mundiais, Fascismo e Guerra Fria",
            "conteudo": (
                "1a GUERRA MUNDIAL (1914-1918):\n"
                "- Causas: imperialismo, nacionalismo, aliancas.\n"
                "- Tratado de Versalhes: puniu a Alemanha.\n\n"
                "ENTREGUERRAS:\n"
                "- Crise de 1929: quebra da bolsa de Nova York.\n"
                "- Fascismo (Italia): Mussolini.\n"
                "- Nazismo (Alemanha): Hitler, totalitarismo, "
                "antisemitismo.\n\n"
                "2a GUERRA MUNDIAL (1939-1945):\n"
                "- Holocausto: genocidio de judeus e outros.\n"
                "- Bombas atomicas: Hiroshima e Nagasaki.\n"
                "- Criacao da ONU (1945).\n\n"
                "GUERRA FRIA (1947-1991):\n"
                "- EUA (capitalismo) x URSS (comunismo).\n"
                "- Corrida armamentista e espacial.\n"
                "- Muro de Berlim (1961-1989).\n"
                "- Descolonizacao da Africa e Asia.\n"
                "- Queda da URSS (1991)."
            ),
            "exemplo": (
                "A Crise de 1929 comecou com a quebra da bolsa de "
                "Nova York e se espalhou pelo mundo. No Brasil, "
                "derrubou o preco do cafe, enfraquecendo a "
                "Republica Velha e contribuindo para a Revolucao "
                "de 1930, que levou Getulio Vargas ao poder."
            ),
        },
    ],
    "resumo": (
        "- Revolucao Francesa (1789): liberdade, igualdade, fraternidade.\n"
        "- Revolucao Industrial: vapor, eletricidade, taylorismo, fordismo.\n"
        "- Imperialismo: partilha da Africa, neoimperialismo.\n"
        "- Independencias: EUA (1776), America Latina, Brasil (1822).\n"
        "- 1a Guerra (1914-18), Crise de 1929, Fascismo e Nazismo.\n"
        "- 2a Guerra (1939-45): Holocausto, bomba atomica, ONU.\n"
        "- Guerra Fria (1947-1991): EUA x URSS, muro de Berlim."
    ),
    "dicas": [
        "Revolucao Francesa: causa social + economica + ideologica (iluminismo).",
        "Fordismo: linha de montagem + salario maior = producao em massa.",
        "Conferencia de Berlim dividiu a Africa sem consultar africanos.",
        "Tratado de Versalhes puniu a Alemanha e preparou o terreno para o nazismo.",
        "Holocausto: genocidio sistematico de judeus e minorias.",
        "Guerra Fria: nunca houve confronto direto EUA-URSS, mas guerras indiretas.",
    ],
    "pegadinhas": [
        "Confundir taylorismo (organizacao do trabalho) com fordismo (linha de montagem).",
        "Achar que a Independencia do Brasil foi militar: foi politica.",
        "Esquecer que a Crise de 1929 teve impacto global, inclusive no Brasil.",
        "Confundir fascismo (Italia) com nazismo (Alemanha): sao diferentes.",
        "Achar que a Guerra Fria teve batalhas diretas: foi conflito indireto.",
        "Esquecer a descolonizacao da Africa e Asia como consequencia da Guerra Fria.",
    ],
    "referencias": [
        "VICENTINO, C. D. Historia para o Ensino Medio. 2. ed. Sao Paulo: Scipione, 2013.",
        "MOTA, M.; BRAICK, P. R. Historia das cavernas ao terceiro milenio. Sao Paulo: Moderna, 2010.",
        "ARRUDA, J. J. A. Historia moderna e contemporanea. 14. ed. Sao Paulo: Atica, 2010.",
        "HOBSBAWM, E. A Era das Revolucoes. Sao Paulo: Paz e Terra, 2009.",
        "HOBSBAWM, E. A Era dos Extremos. Sao Paulo: Companhia das Letras, 1995.",
        "FAUSTO, B. Historia do Brasil. 13. ed. Sao Paulo: Edusp, 2013.",
    ],
}

IMG_CONTEMPORANEA = [
    {"file": "hist_contemporanea.png", "caption": "Linha do tempo da Idade Contemporanea: revolucoes e guerras", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("hist_contemporanea", [])

# ============================================================
# 8.5 Brasil Contemporaneo
# ============================================================
BRASIL_CONTEMPORANEO = {
    "titulo": "Brasil Contemporaneo",
    "disciplina": "Historia",
    "topico": "Brasil Contemporaneo",
    "subtopico": "Era Vargas, ditadura civil-militar, redemocratizacao e atualidade",
    "introducao": (
        "O Brasil Contemporaneo comeca em 1930 com a Revolucao "
        "que levou Getulio Vargas ao poder. Atravessa a Era "
        "Vargas, o periodo democratico, a ditadura civil-militar "
        "e a redemocratizacao ate os dias atuais."
    ),
    "secoes": [
        {
            "titulo": "1. Era Vargas e periodo democratico",
            "conteudo": (
                "REVOLUCAO DE 1930: fim da Republica Velha, "
                "Getulio Vargas assume.\n\n"
                "ERA VARGAS (1930-1945):\n"
                "- Industrializacao: CSN (Companhia Siderurgica "
                "Nacional), Vale do Rio Doce.\n"
                "- Leis trabalhistas: CLT (1943), salario minimo, "
                "ferias, jornada de 8 horas.\n"
                "- Estado Novo (1937-1945): ditadura, censura, "
                "DASP.\n"
                "- Populismo: relacao direta com as massas.\n\n"
                "PERIODO DEMOCRATICO (1946-1964):\n"
                "- Constituicao de 1946.\n"
                "- Juscelino Kubitschek: '50 anos em 5', "
                "Brasilia (1960).\n"
                "- Nacional-desenvolvimentismo.\n"
                "- Crescimento economico com inflacao."
            ),
            "exemplo": (
                "A CLT (Consolidacao das Leis do Trabalho), "
                "promulgada em 1943, garante direitos como "
                "salario minimo, ferias remuneradas, jornada de "
                "8 horas e decimo terceiro. Esses direitos sao "
                "fruto da Era Vargas e ainda protegem os "
                "trabalhadores brasileiros hoje."
            ),
        },
        {
            "titulo": "2. Ditadura Civil-Militar (1964-1985)",
            "conteudo": (
                "GOLPE DE 1964: derrubou Joao Goulart, com apoio "
                "de setores civis e dos EUA.\n\n"
                "CARACTERISTICAS:\n"
                "- Atos Institucionais: AI-5 (1968) deu poderes "
                "autoritarios.\n"
                "- Censura, repressao, tortura, desaparecidos.\n"
                "- Milagre economico (1968-1973): crescimento "
                "com endividamento.\n"
                "- Lei de Anistia (1979).\n"
                "- Diretas Ja (1984): movimento por eleicoes "
                "diretas.\n\n"
                "MOVIMENTOS PELA JUSTICA:\n"
                "- Comissao da Verdade (2011-2014).\n"
                "- Busca por memoria, verdade e justica.\n"
                "- Direitos humanos como pauta central."
            ),
            "exemplo": (
                "O AI-5 (1968) foi o mais autoritario dos Atos "
                "Institucionais: permitiu fechar o Congresso, "
                "cassar mandatos, suspender direitos politicos e "
                "decretar estado de sitio. Marcou o endurecimento "
                "do regime. A Comissao da Verdade, criada em 2011, "
                "investigou crimes da ditadura."
            ),
        },
        {
            "titulo": "3. Redemocratizacao e sociedade atual",
            "conteudo": (
                "REDEMOCRATIZACAO:\n"
                "- Nova Republica (1985): Tancredo Neves.\n"
                "- Constituicao Cidada (1988): ampla garantia de "
                "direitos.\n"
                "- SUS: Sistema Unico de Saude, universal.\n"
                "- Plano Real (1994): estabilidade economica.\n\n"
                "SOCIEDADE ATUAL:\n"
                "- Globalizacao e tecnologia.\n"
                "- Relacoes de trabalho: precarizacao, uberizacao.\n"
                "- Movimentos sociais: MST, quilombolas, feminismo, "
                "BLM.\n"
                "- Conflitos internacionais: terrorismo, migracoes.\n"
                "- Pandemia COVID-19: desafio de saude publica.\n\n"
                "DESCOLONIZACAO DA AFRICA E ASIA:\n"
                "- Apos 2a Guerra, independencias africanas e "
                "asiaticas.\n"
                "- Movimentos de liberacao nacional.\n"
                "- Neocolonialismo: dominio economico."
            ),
            "exemplo": (
                "A Constituicao de 1988 e chamada 'Cidada' por "
                "ampliar direitos: criou o SUS (saude universal), "
                "garantiu educacao publica, direitos sociais e "
                "individuais. Apos a pandemia de COVID-19, o SUS "
                "mostrou tanto sua importancia quanto suas "
                "fragilidades estruturais."
            ),
        },
    ],
    "resumo": (
        "- Era Vargas (1930-45): industrializacao, CLT, Estado Novo, populismo.\n"
        "- Periodo democratico (1946-64): JK, Brasilia, desenvolvimentismo.\n"
        "- Ditadura (1964-85): AI-5, censura, milagre economico, Diretas Ja.\n"
        "- Redemocratizacao: Constituicao Cidada (1988), SUS, Plano Real.\n"
        "- Atualidade: globalizacao, precarizacao, movimentos sociais.\n"
        "- Descolonizacao da Africa e Asia apos 2a Guerra Mundial."
    ),
    "dicas": [
        "CLT (1943) e fruto da Era Vargas: salario minimo, ferias, 13o.",
        "AI-5 (1968) foi o endurecimento da ditadura.",
        "Constituicao de 1988 criou o SUS e ampliou direitos.",
        "Milagre economico (1968-73) cresceu com endividamento.",
        "Diretas Ja (1984) nao conseguiu emenda, mas abriu caminho.",
        "Descolonizacao da Africa e Asia e consequencia da 2a Guerra.",
    ],
    "pegadinhas": [
        "Achar que a ditadura foi so militar: tambem teve apoio civil.",
        "Confundir Estado Novo (Vargas) com ditadura de 1964.",
        "Esquecer que o SUS foi criado pela Constituicao de 1988.",
        "Achar que o milagre economico foi sem custos: houve endividamento.",
        "Confundir Diretas Ja com a redemocratizacao: a emenda nao passou.",
        "Esquecer que a descolonizacao e tema contemporaneo, nao so africano.",
    ],
    "referencias": [
        "FAUSTO, B. Historia do Brasil. 13. ed. Sao Paulo: Edusp, 2013.",
        "VICENTINO, C. D. Historia para o Ensino Medio. 2. ed. Sao Paulo: Scipione, 2013.",
        "MOTA, M.; BRAICK, P. R. Historia das cavernas ao terceiro milenio. Sao Paulo: Moderna, 2010.",
        "FERREIRA, J.; DELGADO, L. A. N. (org.) O Brasil Republicano. Rio de Janeiro: Civilizacao Brasileira, 2003.",
        "GASPARI, E. A Ditadura Envergonhada. Sao Paulo: Companhia das Letras, 2002.",
        "SADER, E. Quando novos personagens entraram em cena. Rio de Janeiro: Paz e Terra, 1988.",
    ],
}

IMG_BRASIL_CONTEMPORANEO = [
    {"file": "hist_brasil_contemporaneo.png", "caption": "Linha do tempo do Brasil Contemporaneo: de Vargas a redemocratizacao", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("hist_brasil_contemporaneo", [])

# ============================================================
# 8.6 Historia do Maranhao
# ============================================================
MARANHAO = {
    "titulo": "Historia do Maranhao",
    "disciplina": "Historia",
    "topico": "Historia do Maranhao",
    "subtopico": "Maranhao Colonial, Imperial e Contemporaneo",
    "introducao": (
        "A historia do Maranhao tem particularidades em relacao "
        "ao resto do Brasil: colonizacao francesa, isolamento, "
        "economia algodoeira, Balaiada e abolicao precoce. "
        "Conhecer essa historia e fundamental para o PAES."
    ),
    "secoes": [
        {
            "titulo": "1. Maranhao Colonial (seculos XVII-XVIII)",
            "conteudo": (
                "FUNDACAO:\n"
                "- Franceses fundaram Sao Luis em 1612 (Daniel de "
                "La Touche).\n"
                "- Portugueses expulsaram os franceses em 1615.\n"
                "- Sao Luis: unica capital brasileira fundada por "
                "nao-portugueses.\n\n"
                "ECONOMIA:\n"
                "- Cana-de-acucar (sec XVII).\n"
                "- Algodao e arroz (sec XVIII).\n"
                "- Companhia de Comercio do Maranhao (1682).\n"
                "- Companhia Geral do Grao-Para e Maranhao (1755).\n\n"
                "SOCIEDADE:\n"
                "- Escravidao africana e indigena.\n"
                "- Isolamento do resto do Brasil.\n"
                "- Ligacao comercial com Lisboa, nao com Bahia.\n"
                "- Jesuitas: catequese e educacao (ate 1759)."
            ),
            "exemplo": (
                "Sao Luis foi fundada por franceses em 1612 e "
                "expulsos pelos portugueses em 1615. Por isso, o "
                "centro historico tem arquitetura colonial "
                "portuguesa, mas o nome da cidade homenageia o "
                "rei frances Luis XIII. Esse detalhe e cobrado em "
                "provas sobre o Maranhao."
            ),
        },
        {
            "titulo": "2. Maranhao Imperial (seculo XIX)",
            "conteudo": (
                "BALAIADA (1838-1841):\n"
                "- Revolta popular no interior do Maranhao.\n"
                "- Vaqueiros, sitiantes e escravos contra elites.\n"
                "- Causas: pobreza, monopolio de terras, "
                "arbitrariedades.\n"
                "- Lideres: Manuel Bator, Cosme Bento das Chagas.\n"
                "- Reprimida por Luis Alves de Lima e Silva.\n\n"
                "ECONOMIA:\n"
                "- Decadencia do algodao maranhense.\n"
                "- Concorrencia do algodao americano.\n"
                "- Ciclo do caju no final do seculo XIX.\n\n"
                "ABOLICAO:\n"
                "- Sao Luis foi a primeira capital brasileira a "
                "abolir a escravidao (1884), antes da Lei Aurea.\n"
                "- Movimento abolicionista forte no Maranhao."
            ),
            "exemplo": (
                "A Balaiada (1838-1841) foi uma das maiores revoltas "
                "populares do Brasil Imperial. Vaqueiros e sitiantes "
                "se revoltaram contra a concentracao de terras e a "
                "violencia das elites. O escravo Cosme Bento das "
                "Chagas liderou quilombos e foi um dos herois da "
                "revolta. A repressao foi comandada por Luis Alves "
                "de Lima e Silva, futuro Duque de Caxias."
            ),
        },
        {
            "titulo": "3. Maranhao Contemporaneo (seculos XX-XXI)",
            "conteudo": (
                "MODERNIZACAO:\n"
                "- Eletronorte e Alumar (decada de 1980).\n"
                "- Complexo portuario de Itaqui: ferro, soja, "
                "combustiveis.\n"
                "- Exploracao de gas natural.\n"
                "- Corredor de exportacao BR-163.\n\n"
                "MOVIMENTOS SOCIAIS:\n"
                "- MST: ocupacoes de terra.\n"
                "- Quilombolas: comunidades tradicionais.\n"
                "- Quebradeiras de coco babacu.\n"
                "- Movimento negro e cultura afro-maranhense.\n\n"
                "CULTURA:\n"
                "- Bumba-meu-boi: principal manifestacao.\n"
                "- Tambor de crioula, cacuriá, tambor de mina.\n"
                "- Literatura: Coelho Neto, Ferreira Gullar, "
                "Naum Alves de Souza.\n\n"
                "DESAFIOS:\n"
                "- Desigualdade regional persistente.\n"
                "- Coronelismo e politica tradicional.\n"
                "- Transicao economica e social."
            ),
            "exemplo": (
                "O bumba-meu-boi e a principal manifestacao "
                "cultural do Maranhao, reconhecida como patrimonio "
                "cultural imaterial do Brasil. Combina musica, "
                "danc,a e teatro, com raizes africanas, indigenas "
                "e portuguesas. Os sotaques (matracado, zabumba, "
                "orquestra) variam por regiao do estado."
            ),
        },
    ],
    "resumo": (
        "- Colonial: franceses fundaram Sao Luis (1612), expulsos em 1615.\n"
        "- Economia colonial: cana, algodao, arroz. Companhia de Comercio (1682).\n"
        "- Imperial: Balaiada (1838-41), decadencia do algodao, abolicao precoce (1884).\n"
        "- Contemporaneo: Alumar, Itaqui, BR-163, MST, quilombolas.\n"
        "- Cultura: bumba-meu-boi, tambor de crioula, tambor de mina.\n"
        "- Desafios: desigualdade, coronelismo, transicao economica."
    ),
    "dicas": [
        "Sao Luis foi fundada por franceses em 1612: unica capital nao-portuguesa.",
        "Balaiada: revolta popular de vaqueiros e escravos (1838-1841).",
        "Cosme Bento das Chagas: lider escravo da Balaiada.",
        "Sao Luis aboliu escravidao em 1884, antes da Lei Aurea (1888).",
        "Alumar e Eletronorte modernizaram o Maranhao nos anos 1980.",
        "Bumba-meu-boi: principal manifestacao cultural, patrimonio imaterial.",
    ],
    "pegadinhas": [
        "Achar que Sao Luis foi fundada por portugueses: foram franceses.",
        "Confundir Balaiada com Cabanagem: Balaiada e no Maranhao.",
        "Esquecer que o Maranhao aboliu escravidao antes da Lei Aurea.",
        "Achar que o algodao maranhense sempre foi decadente: foi forte no sec XVIII.",
        "Confundir Companhia de Comercio (1682) com Companhia Geral (1755).",
        "Esquecer a diversidade cultural: bumba-meu-boi tem varios sotaques.",
    ],
    "referencias": [
        "MEIRELES, M. M. Historia do Maranhao. 4. ed. Sao Luis: Sicomp, 2010.",
        "GALVAO, E. C. A Balaiada. Sao Luis: Editora UEMA, 2012.",
        "ABREU, A. A. Maranhao: historia e cultura. Sao Luis: EDUFMA, 2008.",
        "VIVEIROS, J. Historia do comercio do Maranhao. Sao Luis: Associação Comercial, 1992.",
        "ALMEIDA, A. L. O Maranhao no contexto da historia. Sao Luis: GEPE, 2005.",
        "FIGUEIREDO, A. M. Historia do Maranhao: da colonia a atualidade. Sao Luis: Lithos, 2015.",
    ],
}

IMG_MARANHAO = [
    {"file": "hist_maranhao.png", "caption": "Historia do Maranhao: colonial, imperial e contemporaneo", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("hist_maranhao", [])

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (CONTEMPORANEA, "HIS_IDADE_CONTEMPORANEA.pdf", IMG_CONTEMPORANEA, "Historia — Idade Contemporanea"),
        (BRASIL_CONTEMPORANEO, "HIS_BRASIL_CONTEMPORANEO.pdf", IMG_BRASIL_CONTEMPORANEO, "Historia — Brasil Contemporaneo"),
        (MARANHAO, "HIS_MARANHAO.pdf", IMG_MARANHAO, "Historia — Historia do Maranhao"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
