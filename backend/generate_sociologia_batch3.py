# -*- coding: utf-8 -*-
"""Gera PDFs de Sociologia — batch 3 (topicos 11.7 a 11.9)."""

from pdf_base import generate_educational_pdf
from sociologia_real_images import REAL_IMAGES

# ============================================================
# 11.7 Trabalho e Sociedade
# ============================================================
TRABALHO = {
    "titulo": "Trabalho e Sociedade",
    "disciplina": "Sociologia",
    "topico": "Trabalho e Sociedade",
    "subtopico": "Fordismo, taylorismo, toyotismo, modos de producao e mercado atual",
    "introducao": (
        "O trabalho organiza a sociedade. Da organizacao "
        "cientifica de Taylor a uberizacao contemporanea, as "
        "formas de trabalhar transformam a vida social."
    ),
    "secoes": [
        {
            "titulo": "1. Taylorismo, fordismo e toyotismo",
            "conteudo": (
                "TAYLORISMO (Frederick Taylor, sec XX):\n"
                "- Organizacao cientifica do trabalho.\n"
                "- Estudo de tempos e movimentos.\n"
                "- Separacao: execucao x planejamento.\n"
                "- Maximizacao de eficiencia.\n"
                "- Trabalhador como extensao da maquina.\n\n"
                "FORDISMO (Henry Ford, 1913):\n"
                "- Linha de montagem, producao em massa.\n"
                "- Padronizacao do produto.\n"
                "- Salario maior = consumo (ciclo).\n"
                "- Intensificacao do trabalho.\n"
                "- Origem da classe media operaria.\n\n"
                "TOYOTISMO (Toyota, Japao, pos-1945):\n"
                "- Producao flexivel, nao rigida.\n"
                "- Just-in-time: estoque minimo.\n"
                "- Kaizen: melhoria continua.\n"
                "- Trabalhador polivalente (varias funcoes).\n"
                "- Qualidade total."
            ),
            "exemplo": (
                "Na linha de montagem de Ford, cada operario fazia "
                "uma tarefa repetitiva (apertar parafuso). Isso "
                "barateou o carro, mas alienou o trabalhador. "
                "No toyotismo, o operario e polivalente: faz "
                "varias tarefas e sugere melhorias (kaizen). "
                "Menos alienacao, mas mais intensidade."
            ),
        },
        {
            "titulo": "2. Modos de producao (Marx)",
            "conteudo": (
                "COMUNISMO PRIMITIVO: sem classes, sem Estado. "
                "Cacadores-coletores. Propriedade coletiva.\n\n"
                "MODO ASIATICO: Estado despota controla terras e "
                "aguas. Oriento (Egito, Mesopotamia).\n\n"
                "MODO ESCRAVISTA: dono x escravo. Antiguidade "
                "(Grecia, Roma). Trabalho forcado.\n\n"
                "MODO FEUDAL: senhor x servo. Idade Media europeia. "
                "Servo preso a terra, nao escravo.\n\n"
                "MODO CAPITALISTA: burguesia x proletariado. "
                "Seculos XVIII-atual. Salario, mais-valia.\n\n"
                "MODO SOCIALISTA: transicao. Propriedade coletiva "
                "dos meios de producao. Planejamento.\n\n"
                "COMUNISMO: sem classes, sem Estado, abundancia. "
                "Meta final (Marx)."
            ),
            "exemplo": (
                "No capitalismo, o operario produz mais valor do "
                "que recebe em salario. Essa diferenca e a "
                "mais-valia, fonte do lucro. Se um operario "
                "produz R$ 100/h mas recebe R$ 20/h, R$ 80/h sao "
                "apropriados pelo capitalista. Isso e exploracao, "
                "segundo Marx."
            ),
        },
        {
            "titulo": "3. Mercado de trabalho atual",
            "conteudo": (
                "PRECARIZACAO: perda de direitos trabalhistas. "
                "Trabalho sem carteira, sem beneficios.\n\n"
                "UBERIZACAO: plataformas digitais como 'empregadoras'. "
                "Motoristas, entregadores sem vinculo formal. "
                "Flexibilidade para a empresa, precariedade para "
                "o trabalhador.\n\n"
                "TRABALHO INFORMAL: mais de 50% no Brasil. "
                "Vendedores ambulantes, diaristas, autonomos.\n\n"
                "DESEMPREGO ESTRUTURAL: automacao e IA substituem "
                "trabalhos. Nao e conjuntural, e permanente.\n\n"
                "TRABALHO ESCRAVO CONTEMPORANEO: ainda existe em "
                "fazendas, confecoes, construcao. Combate pelo "
                "Ministerio do Trabalho.\n\n"
                "NOVAS FORMAS: home office, trabalho remoto, "
                "freelancer, gig economy."
            ),
            "exemplo": (
                "Os entregadores de aplicativo (iFood, Uber Eats) "
                "trabalham sem carteira assinada, sem ferias, sem "
                "13o. Recebem por entrega, mas arcam com combustivel "
                "e manutencao. Esse modelo e a uberizacao: "
                "flexibilidade para a empresa, precariedade para "
                "o trabalhador. E a nova face do trabalho."
            ),
        },
    ],
    "resumo": (
        "- Taylorismo: organizacao cientifica, tempos e movimentos.\n"
        "- Fordismo: linha de montagem, producao em massa, salario maior.\n"
        "- Toyotismo: flexivel, just-in-time, kaizen, polivalencia.\n"
        "- Modos de producao (Marx): primitivo, asiatico, escravista, feudal, capitalista, socialista.\n"
        "- Mais-valia: diferenca entre valor produzido e salario.\n"
        "- Atual: precarizacao, uberizacao, informalidade, desemprego estrutural."
    ),
    "dicas": [
        "Taylor: estudo de tempos. Ford: linha de montagem. Toyota: flexibilidade.",
        "Mais-valia (Marx): valor produzido menos salario.",
        "Uberizacao: app como patrao, sem direitos.",
        "Desemprego estrutural: automacao substitui permanentemente.",
        "Trabalho escravo contemporaneo ainda existe no Brasil.",
        "Toyotismo: trabalhador polivalente, kaizen (melhoria continua).",
    ],
    "pegadinhas": [
        "Confundir taylorismo com fordismo: Taylor organiza, Ford monta em linha.",
        "Achar que toyotismo e so japones: e modelo global atual.",
        "Confundir desemprego estrutural com conjuntural: estrutural e permanente.",
        "Esquecer que mais-valia e exploracao (Marx), nao lucro neutro.",
        "Achar que uberizacao e liberdade: e precarizacao disfarcada.",
        "Confundir modo feudal (senhor x servo) com escravista (dono x escravo).",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "MARX, K. O capital. Sao Paulo: Boitempo, 2013.",
        "BRAVERMAN, H. Trabalho e capital monopolista. Rio de Janeiro: Zahar, 1977.",
        "ANTUNES, R. Adeus ao trabalho? 15. ed. Sao Paulo: Cortez, 2011.",
        "GORZ, A. Metamorfoses do trabalho. Sao Paulo: Annablume, 2003.",
    ],
}

IMG_TRABALHO = [
    {"file": "socio_trabalho.png", "caption": "Trabalho: do taylorismo a uberizacao", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_trabalho", [])

# ============================================================
# 11.8 Estado e Poder
# ============================================================
ESTADO_PODER = {
    "titulo": "Estado e Poder",
    "disciplina": "Sociologia",
    "topico": "Estado e Poder",
    "subtopico": "Formas de poder, regimes, democracia, partidos e movimentos sociais",
    "introducao": (
        "O Estado e a instituicao central do poder politico "
        "moderno. Entender suas formas, regimes e a dinamica "
        "entre democracia e movimentos sociais e fundamental."
    ),
    "secoes": [
        {
            "titulo": "1. Formas de poder e Estado",
            "conteudo": (
                "FORMAS DE PODER:\n"
                "- Politico: Estado, governo.\n"
                "- Economico: capital, empresas.\n"
                "- Ideologico: midia, religiao, escola.\n"
                "- Coercitivo: forca, violencia.\n"
                "- Simbolico: Bourdieu, legitimidade.\n\n"
                "ESTADO (Weber):\n"
                "- Instituicao que tem monopolio legitimo da forca "
                "fisica.\n"
                "- Soberania sobre um territorio.\n"
                "- Burocracia, leis, impostos.\n\n"
                "ESTADO x GOVERNO x REGIME:\n"
                "- Estado: instituicao permanente.\n"
                "- Governo: grupo que administra temporariamente.\n"
                "- Regime: forma de governo (democracia, autocracia).\n\n"
                "TIPOS DE ESTADO:\n"
                "- Liberal: minimo, mercado livre.\n"
                "- Social: intervencionista, welfare.\n"
                "- Totalitario: partido unico, terror.\n"
                "- Autoritario: sem liberdade, mas sem partido unico."
            ),
            "exemplo": (
                "O Estado brasileiro e permanente (existe ha mais "
                "de 200 anos), mas o governo muda a cada eleicao. "
                "O regime e democratico desde 1985. O Estado tem "
                "monopolio da forca: so ele pode prender, cobrar "
                "impostos, fazer leis. Grupos armados (faccoes) "
                "disputam esse monopolio em algumas areas."
            ),
        },
        {
            "titulo": "2. Democracia, cidadania e partidos",
            "conteudo": (
                "DEMOCRACIA:\n"
                "- Direta: cidadaos decidem (Atenas).\n"
                "- Representativa: representantes eleitos.\n"
                "- Participativa: conselhos, orcamento participativo.\n"
                "- Deliberativa: debate racional (Habermas).\n\n"
                "CIDADANIA (Marshall):\n"
                "- Civil: liberdade, igualdade perante a lei.\n"
                "- Politica: voto, elegibilidade.\n"
                "- Social: educacao, saude, previdencia.\n\n"
                "PARTIDOS POLITICOS:\n"
                "- Organizacoes que disputam o poder.\n"
                "- Espectro: esquerda, centro, direita.\n"
                "- Funcoes: recrutar lideres, formular programas, "
                "agregar interesses.\n\n"
                "SISTEMAS ELEITORAIS:\n"
                "- Majoritario: vencedor leva tudo (EUA, senado BR).\n"
                "- Proporcional: representatividade (camara BR).\n"
                "- Misto: combina ambos."
            ),
            "exemplo": (
                "No Brasil, a camara dos deputados usa sistema "
                "proporcional: cada estado elege deputados conforme "
                "sua populacao. Ja o senado usa majoritario: os "
                "mais votados ganham. A cidadania brasileira "
                "inclui direitos sociais (SUS, educacao publica) "
                "garantidos pela Constituicao de 1988."
            ),
        },
        {
            "titulo": "3. Movimentos sociais e direitos humanos",
            "conteudo": (
                "MOVIMENTOS SOCIAIS: organizacoes coletivas que "
                "reivindicam direitos e mudancas.\n\n"
                "EXEMPLOS BRASILEIROS:\n"
                "- MST: Movimento dos Trabalhadores Rurais Sem Terra.\n"
                "- MTST: Movimento dos Trabalhadores Sem Teto.\n"
                "- Movimento feminista: direitos das mulheres.\n"
                "- Movimento negro: combate ao racismo.\n"
                "- Movimento LGBTQIA+: direitos sexuais.\n"
                "- Quilombolas: territorios tradicionais.\n"
                "- Indigenas: demarcacao de terras.\n\n"
                "FUNCOES:\n"
                "- Pressionar o Estado por direitos.\n"
                "- Mobilizar a sociedade.\n"
                "- Construir identidade coletiva.\n"
                "- Democratizar a democracia.\n\n"
                "DIREITOS HUMANOS:\n"
                "- Universais: para todos, sem distincao.\n"
                "- Declaracao Universal (ONU, 1948).\n"
                "- Direitos civis, politicos, sociais, economicos, "
                "culturais.\n"
                "- Conquista historica, nao dada."
            ),
            "exemplo": (
                "O MST organiza ocupacoes de terra para pressionar "
                "pela reforma agraria. O movimento negro conquistou "
                "leis anti-racismo e cotas. O movimento feminista "
                "conquistou a Lei Maria da Penha e a legalizacao "
                "do aborto em casos especificos. Esses movimentos "
                "democratizam a democracia: ampliam direitos para "
                "quem era excluido."
            ),
        },
    ],
    "resumo": (
        "- Poder: politico, economico, ideologico, coercitivo, simbolico.\n"
        "- Estado (Weber): monopolio legitimo da forca fisica.\n"
        "- Estado: permanente. Governo: temporario. Regime: forma.\n"
        "- Democracia: direta, representativa, participativa, deliberativa.\n"
        "- Cidadania: civil, politica, social (Marshall).\n"
        "- Partidos: esquerda, centro, direita. Majoritario x proporcional.\n"
        "- Movimentos sociais: MST, feminista, negro, LGBTQIA+, indigena.\n"
        "- Direitos humanos: universais (ONU, 1948)."
    ),
    "dicas": [
        "Weber: Estado = monopolio legitimo da forca fisica.",
        "Estado e permanente, governo muda, regime e a forma.",
        "Cidadania (Marshall): civil, politica, social.",
        "Brasil: camara proporcional, senado majoritario.",
        "Movimentos sociais democratizam a democracia.",
        "Direitos humanos: universais, conquista historica.",
    ],
    "pegadinhas": [
        "Confundir Estado com governo: Estado e permanente, governo e temporario.",
        "Achar que democracia direta e viavel hoje: e ideal, nao pratica em grandes sociedades.",
        "Esquecer que cidadania tem 3 dimensoes (Marshall), nao so voto.",
        "Confundir sistema majoritario com proporcional: majoritario e vencedor leva tudo.",
        "Achar que movimentos sociais sao so protesto: tambem constroem identidade.",
        "Esquecer que direitos humanos sao conquista historica, nao dada.",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "WEBER, M. Economia e sociedade. Brasilia: UnB, 2004.",
        "BOBBIO, N. Estado, governo, sociedade. 7. ed. Sao Paulo: Paz e Terra, 2007.",
        "MARSHALL, T. H. Cidadania, classe social e status. Rio de Janeiro: Zahar, 1967.",
        "GOHN, M. G. Movimentos sociais no inicio do seculo XXI. 5. ed. Petropolis: Vozes, 2014.",
    ],
}

IMG_ESTADO_PODER = [
    {"file": "socio_estado.png", "caption": "Estado e poder: formas, regimes e movimentos sociais", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_estado", [])

# ============================================================
# 11.9 Temas Contemporaneos
# ============================================================
CONTEMPORANEOS_SOC = {
    "titulo": "Temas Contemporaneos",
    "disciplina": "Sociologia",
    "topico": "Temas Contemporaneos",
    "subtopico": "Globalizacao, neoliberalismo, meio ambiente e sustentabilidade",
    "introducao": (
        "Os temas contemporaneos da sociologia abordam os desafios "
        "do seculo XXI: globalizacao, neoliberalismo, crise "
        "ambiental e sustentabilidade."
    ),
    "secoes": [
        {
            "titulo": "1. Globalizacao e neoliberalismo",
            "conteudo": (
                "GLOBALIZACAO:\n"
                "- Mundo interligado: economia, cultura, informacao.\n"
                "- Tecnologia: internet, smartphones, redes sociais.\n"
                "- Economia global: cadeias de producao internacionais.\n"
                "- Migracoes: refugiados, trabalho.\n"
                "- Cultura global x local: glocalizacao.\n"
                "- Consequencias: homogeneizacao x diversidade.\n\n"
                "NEOLIBERALISMO:\n"
                "- Estado minimo: menos intervencionismo.\n"
                "- Privatizacoes: empresas publicas vendidas.\n"
                "- Mercado como regulador principal.\n"
                "- Desregulamentacao: menos leis trabalhistas e "
                "ambientais.\n"
                "- Pensadores: Friedman, Hayek.\n"
                "- Consequencias: desigualdade, precarizacao."
            ),
            "exemplo": (
                "A globalizacao permite que um iPhone seja projetado "
                "na California, montado na China, com pecas da "
                "Coreia e do Japao, e vendido no Brasil. Isso "
                "mostra a integracao economica global. O "
                "neoliberalismo, ao privatizar e desregulamentar, "
                "flexibiliza o trabalho, gerando precarizacao."
            ),
        },
        {
            "titulo": "2. Sociedade e meio ambiente",
            "conteudo": (
                "CRISE ECOLOGICA:\n"
                "- Aquecimento global: CO2, efeito estufa.\n"
                "- Desmatamento: Amazonia, Cerrado.\n"
                "- Poluicao: ar, agua, solo.\n"
                "- Biodiversidade: extincao de especies.\n"
                "- Antropoceno: era geologica dominada por humanos.\n\n"
                "CAUSAS SOCIAIS:\n"
                "- Capitalismo: crescimento infinito em planeta "
                "finito.\n"
                "- Consumismo: descarte, obsolescencia programada.\n"
                "- Agropecuaria: desmatamento para soja, carne.\n"
                "- Mineracao: degradacao, contaminacao.\n\n"
                "CONSEQUENCIAS:\n"
                "- Migracoes climaticas.\n"
                "- Conflitos por recursos (agua, terra).\n"
                "- Desigualdade: pobres sofrem mais.\n"
                "- Justica climatica: quem polui paga?"
            ),
            "exemplo": (
                "O desmatamento da Amazonia para pecuaria e soja "
                "e causa da crise ecologica. Queimadas liberam CO2, "
                "agravando o aquecimento. Povos tradicionais "
                "(indigenas, ribeirinhos) perdem seus territorios. "
                "A justica climatica pergunta: quem lucra com a "
                "soja? Quem sofre com as queimadas? Sao grupos "
                "diferentes."
            ),
        },
        {
            "titulo": "3. Sustentabilidade e producao de alimentos",
            "conteudo": (
                "SUSTENTABILIDADE: 3 pilares.\n"
                "- Social: equidade, justica.\n"
                "- Economico: viabilidade.\n"
                "- Ambiental: preservacao.\n\n"
                "ODS (Objetivos de Desenvolvimento Sustentavel):\n"
                "- 17 objetivos da ONU, Agenda 2030.\n"
                "- Erradicar pobreza, fome, garantir educacao, "
                "agua, energia, clima.\n\n"
                "PRODUCAO DE ALIMENTOS:\n"
                "- Agricultura convencional: agrotoxicos, "
                "monocultura.\n"
                "- Agricultura sustentavel: agroecologia, organicos.\n"
                "- Soberania alimentar: cada povo decide seu "
                "sistema alimentar.\n"
                "- Comida x commodity: alimento e direito, nao so "
                "mercadoria.\n"
                "- Desperdicio: 1/3 da comida produzida e jogada "
                "fora.\n\n"
                "DESAFIOS DO SECULO XXI:\n"
                "- Tecnologia: IA, automacao, desemprego.\n"
                "- Desigualdade crescente.\n"
                "- Migracoes e refugiados.\n"
                "- Pos-verdade e desinformacao.\n"
                "- Pandemias.\n"
                "- Crise democratica."
            ),
            "exemplo": (
                "A agroecologia propõe produzir comida sem "
                "agrotoxicos, preservando o solo e a biodiversidade. "
                "A soberania alimentar diz que cada povo deve "
                "decidir como se alimenta, nao depender de "
                "corporacoes globais. O Brasil desperdica 1/3 da "
                "comida produzida, enquanto milhoes passam fome: "
                "e problema de distribuicao, nao de producao."
            ),
        },
    ],
    "resumo": (
        "- Globalizacao: mundo interligado, economia global, glocalizacao.\n"
        "- Neoliberalismo: Estado minimo, privatizacoes, desregulamentacao.\n"
        "- Crise ecologica: aquecimento, desmatamento, poluicao, Antropoceno.\n"
        "- Sustentabilidade: 3 pilares (social, economico, ambiental).\n"
        "- ODS: 17 objetivos da ONU, Agenda 2030.\n"
        "- Alimentos: agroecologia, soberania alimentar, comida x commodity.\n"
        "- Desafios: IA, desigualdade, migracoes, pos-verdade, pandemias."
    ),
    "dicas": [
        "Globalizacao: mundo interligado. Glocalizacao: global + local.",
        "Neoliberalismo: Estado minimo, privatizacoes, Friedman/Hayek.",
        "Sustentabilidade: 3 pilares (social, economico, ambiental).",
        "ODS: 17 objetivos da ONU para 2030.",
        "Soberania alimentar: cada povo decide seu sistema alimentar.",
        "Antropoceno: era geologica dominada por humanos.",
    ],
    "pegadinhas": [
        "Achar que globalizacao e so economica: tambem cultural.",
        "Confundir neoliberalismo com liberalismo classico: neoliberalismo e versao contemporanea.",
        "Esquecer que a crise ecologica tem causas sociais (capitalismo, consumismo).",
        "Achar que sustentabilidade e so ambiental: sao 3 pilares.",
        "Confundir soberania alimentar com seguranca alimentar: soberania e decisao, seguranca e acesso.",
        "Esquecer que o desperdicio de comida e problema de distribuicao, nao producao.",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "SANTOS, M. Por uma outra globalizacao. 25. ed. Rio de Janeiro: Record, 2015.",
        "HARVEY, D. O neoliberalismo. 2. ed. Sao Paulo: Loyola, 2008.",
        "ONU. Objetivos de Desenvolvimento Sustentavel. Nova York: ONU, 2015.",
        "BAUMAN, Z. Modernidade liquida. Rio de Janeiro: Zahar, 2001.",
    ],
}

IMG_CONTEMPORANEOS_SOC = [
    {"file": "socio_contemporaneos.png", "caption": "Temas contemporaneos: globalizacao, meio ambiente e sustentabilidade", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_contemporaneos", [])

# ============================================================
def main():
    pdfs = [
        (TRABALHO, "SOC_TRABALHO_SOCIEDADE.pdf", IMG_TRABALHO, "Sociologia — Trabalho e Sociedade"),
        (ESTADO_PODER, "SOC_ESTADO_PODER.pdf", IMG_ESTADO_PODER, "Sociologia — Estado e Poder"),
        (CONTEMPORANEOS_SOC, "SOC_TEMAS_CONTEMPORANEOS.pdf", IMG_CONTEMPORANEOS_SOC, "Sociologia — Temas Contemporaneos"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
