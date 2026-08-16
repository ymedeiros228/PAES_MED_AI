# -*- coding: utf-8 -*-
"""Gera PDFs de Sociologia — batch 1 (topicos 11.1 a 11.3)."""

from pdf_base import generate_educational_pdf
from sociologia_real_images import REAL_IMAGES

# ============================================================
# 11.1 Surgimento da Sociologia
# ============================================================
SURGIMENTO = {
    "titulo": "Surgimento da Sociologia",
    "disciplina": "Sociologia",
    "topico": "Surgimento da Sociologia",
    "subtopico": "Contexto historico e sociologia como ciencia",
    "introducao": (
        "A sociologia nasce no seculo XIX como resposta aos "
        "problemas trazidos pela Revolucao Industrial e pela "
        "Revolucao Francesa. Busca explicar a nova sociedade "
        "moderna com metodo cientifico."
    ),
    "secoes": [
        {
            "titulo": "1. Contexto historico do surgimento",
            "conteudo": (
                "REVOLUCAO INDUSTRIAL (sec XVIII-XIX):\n"
                "- Transferencia do campo para a cidade.\n"
                "- Proletariado: condicoes precarias, jornadas "
                "exaustivas, baixos salarios.\n"
                "- Urbanizacao caotica: favelas, doencas, "
                "criminalidade.\n"
                "- Conflitos de classe: burguesia x operarios.\n\n"
                "REVOLUCAO FRANCESA (1789):\n"
                "- Fim do absolutismo, novos valores: liberdade, "
                "igualdade.\n"
                "- Crise do antigo regime, nova ordem social.\n"
                "- Questionamento das tradicoes.\n\n"
                "NECESSIDADE: explicar a nova sociedade, seus "
                "problemas e encontrar solucoes. A sociologia "
                "nasce como ciencia da sociedade moderna."
            ),
            "exemplo": (
                "As condicoes dos operarios no seculo XIX eram "
                "desumanas: jornadas de 14-16 horas, criancas "
                "trabalhando em minas, insalubridade. Engels "
                "descreveu a situacao da classe operaria inglesa. "
                "Essa realidade exigia explicacao cientifica: "
                "surgiu a sociologia para entender e transformar."
            ),
        },
        {
            "titulo": "2. Sociologia como ciencia",
            "conteudo": (
                "AUGUSTE COMTE (1798-1857):\n"
                "- Pai da sociologia, cunhou o termo.\n"
                "- Positivismo: aplicar metodo das ciencias "
                "naturais a sociedade.\n"
                "- Lei dos tres estados: teologico, metafisico, "
                "positivo.\n"
                "- Ordem e progresso: lema positivista.\n\n"
                "SOCIOLOGIA COMO CIENCIA:\n"
                "- Objeto: a sociedade, os fatos sociais.\n"
                "- Metodo: observacao, experimentacao, comparacao.\n"
                "- Objetividade: afastar preconceitos.\n"
                "- Explicar para compreender e transformar.\n\n"
                "DESENVOLVIMENTO: Durkheim, Marx, Weber consolidam "
                "a sociologia como disciplina cientifica no "
                "seculo XIX-XX."
            ),
            "exemplo": (
                "Comte propôs a lei dos tres estados: a "
                "humanidade passa do teologico (explicacao por "
                "deuses), ao metafisico (ideias abstratas), ao "
                "positivo (ciencia). A sociologia seria a ciencia "
                "mais complexa, chegando por ultimo. O lema "
                "'ordem e progresso' esta na bandeira do Brasil, "
                "influencia positivista."
            ),
        },
        {
            "titulo": "3. Os classicos e a consolidacao",
            "conteudo": (
                "DURKHEIM (1858-1917):\n"
                "- Fato social: externo, coercitivo, geral.\n"
                "- Solidariedade mecanica (rural) x organica "
                "(urbana).\n"
                "- Anomia: ausencia de normas, crise.\n"
                "- 'Suicidio': estudo sociologico pioneiro.\n\n"
                "MARX (1818-1883):\n"
                "- Materialismo historico: economia determina "
                "sociedade.\n"
                "- Luta de classes: motor da historia.\n"
                "- Alienacao: trabalhador separado do produto.\n"
                "- Mais-valia: exploracao do trabalho.\n\n"
                "WEBER (1864-1920):\n"
                "- Acao social: comportamento com sentido.\n"
                "- Compreensao (Verstehen): entender o sentido.\n"
                "- Racionalizacao: modernidade racionaliza.\n"
                "- Desencantamento do mundo.\n"
                "- Etica protestante e capitalismo."
            ),
            "exemplo": (
                "Durkheim estudou o suicidio como fato social, "
                "nao individual. Descobriu que sociedades com "
                "menos integracao (anomia) tem maiores taxas. "
                "Isso mostrou que ate atos aparentemente "
                "individuais tem causas sociais. A sociologia "
                "explica o social pelo social."
            ),
        },
    ],
    "resumo": (
        "- Contexto: Revolucao Industrial + Revolucao Francesa.\n"
        "- Problemas: urbanizacao, proletariado, conflitos.\n"
        "- Comte: positivismo, lei dos tres estados, ordem e progresso.\n"
        "- Durkheim: fato social, anomia, solidariedade.\n"
        "- Marx: luta de classes, alienacao, mais-valia.\n"
        "- Weber: acao social, racionalizacao, desencantamento."
    ),
    "dicas": [
        "Sociologia nasce com a Revolucao Industrial, nao antes.",
        "Comte: pai da sociologia, positivismo, ordem e progresso.",
        "Durkheim: fato social e externo e coercitivo.",
        "Marx: luta de classes e motor da historia.",
        "Weber: acao social tem sentido (Verstehen).",
        "O lema 'ordem e progresso' da bandeira do Brasil e positivista.",
    ],
    "pegadinhas": [
        "Achar que sociologia existe desde a antiguidade: nasce no sec XIX.",
        "Confundir Comte com Durkheim: Comte e pai, Durkheim e consolidador.",
        "Esquecer que Marx nao era sociologo de profissao: e filosofo/economista.",
        "Achar que Weber era positivista: ele e compreensivo.",
        "Confundir solidariedade mecanica (rural) com organica (urbana).",
        "Esquecer que anomia e ausencia de normas, nao caos total.",
    ],
    "referencias": [
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "DURKHEIM, E. As regras do metodo sociologico. Sao Paulo: Martins Fontes, 2007.",
        "MARX, K. O capital. Sao Paulo: Boitempo, 2013.",
        "WEBER, M. Economia e sociedade. Brasilia: UnB, 2004.",
        "COMTE, A. Curso de filosofia positiva. Sao Paulo: Abril Cultural, 1978.",
    ],
}

IMG_SURGIMENTO = [
    {"file": "socio_surgimento.png", "caption": "Surgimento da sociologia: contexto e ciencia", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_surgimento", [])

# ============================================================
# 11.2 Perspectivas Classicas
# ============================================================
CLASSICAS = {
    "titulo": "Perspectivas Classicas",
    "disciplina": "Sociologia",
    "topico": "Perspectivas Classicas",
    "subtopico": "Durkheim, Marx, Weber e interpretes da sociedade brasileira",
    "introducao": (
        "Os classicos da sociologia oferecem diferentes lentes "
        "para entender a sociedade. Durkheim ve a coesao, Marx "
        "ve o conflito, Weber ve o sentido. No Brasil, autores "
        "interpretam nossa formacao."
    ),
    "secoes": [
        {
            "titulo": "1. Durkheim, Marx e Weber",
            "conteudo": (
                "DURKHEIM: sociedade como organismo.\n"
                "- Fato social: externo, coercitivo, geral.\n"
                "- Solidariedade mecanica (rural, semelhancas) x "
                "organica (urbana, divisao do trabalho).\n"
                "- Anomia: crise de normas na transicao.\n"
                "- Religiao, educacao, suicidio como fatos sociais.\n\n"
                "MARX: conflito e mudanca.\n"
                "- Materialismo historico: economia determina.\n"
                "- Luta de classes: burguesia x proletariado.\n"
                "- Modos de producao: escravista, feudal, capitalista.\n"
                "- Alienacao: separacao do trabalhador e produto.\n"
                "- Mais-valia: exploracao do trabalho.\n\n"
                "WEBER: sentido e racionalidade.\n"
                "- Acao social: comportamento com sentido.\n"
                "- 4 tipos: tradicional, afetiva, valor-racional, "
                "fim-racional.\n"
                "- Racionalizacao: modernidade racionaliza tudo.\n"
                "- Desencantamento do mundo.\n"
                "- Etica protestante e espirito do capitalismo."
            ),
            "exemplo": (
                "Para Durkheim, a educacao e fato social: padroniza "
                "comportamentos. Para Marx, a escola reproduz a "
                "ideologia dominante. Para Weber, a educacao "
                "racionaliza (certificados, metodos). Cada classico "
                "revela um aspecto: coesao, conflito, racionalidade."
            ),
        },
        {
            "titulo": "2. Interpretes da sociedade brasileira",
            "conteudo": (
                "FLORESTAN FERNANDES:\n"
                "- Sociologia critica brasileira.\n"
                "- Racismo, classes sociais, integracao do negro.\n"
                "- 'A integracao do negro na sociedade de classes'.\n\n"
                "GILBERTO FREYRE:\n"
                "- 'Casa-grande e senzala' (1933).\n"
                "- Mesticagem: formacao da sociedade brasileira.\n"
                "- Patriarcalismo, relacoes raciais.\n"
                "- Critica: romantiza a escravidao.\n\n"
                "SERGIO BUARQUE DE HOLANDA:\n"
                "- 'Raizes do Brasil' (1936).\n"
                "- Homem cordial: relacao pessoal na politica.\n"
                "- Heranca ibérica, ruralismo.\n\n"
                "ROBERTO DAMATTA:\n"
                "- 'Carnavais, malandros e herois'.\n"
                "- Jeitinho: contornar regras.\n"
                "- Hierarquia x igualdade: dilema brasileiro.\n"
                "- Casa x rua: espacos sociais."
            ),
            "exemplo": (
                "O 'jeitinho brasileiro' (DaMatta) e uma forma de "
                "contornar regras impessoais usando relacoes "
                "pessoais. Quando alguem pede favor a um conhecido "
                "para agilizar um processo, esta usando o jeitinho. "
                "Isso revela o dilema brasileiro: a lei diz "
                "igualdade, mas a pratica e hierarquica."
            ),
        },
        {
            "titulo": "3. Comparacao das perspectivas",
            "conteudo": (
                "DURKHEIM x MARX x WEBER:\n"
                "- Durkheim: coesao, ordem, integracao.\n"
                "- Marx: conflito, mudanca, classes.\n"
                "- Weber: sentido, racionalidade, compreensao.\n\n"
                "METODO:\n"
                "- Durkheim: positivista (explicar).\n"
                "- Marx: critico (transformar).\n"
                "- Weber: compreensivo (entender).\n\n"
                "CONTRIBUICOES:\n"
                "- Durkheim: fato social, anomia, solidariedade.\n"
                "- Marx: luta de classes, alienacao, mais-valia.\n"
                "- Weber: acao social, racionalizacao, tipos ideais.\n\n"
                "BRASIL:\n"
                "- Florestan: racismo e classes.\n"
                "- Freyre: mesticagem.\n"
                "- Holanda: homem cordial.\n"
                "- DaMatta: jeitinho e hierarquia."
            ),
            "exemplo": (
                "Para entender o racismo no Brasil: Florestan "
                "Fernandes mostra que a abolicao nao integrou o "
                "negro, criando desigualdade de classe. Gilberto "
                "Freyre enfatiza a mesticagem como formadora. "
                "Ambos revelam aspectos, mas Florestan e mais "
                "critico, Freyre mais descritivo."
            ),
        },
    ],
    "resumo": (
        "- Durkheim: fato social, solidariedade, anomia. Ordem.\n"
        "- Marx: luta de classes, alienacao, mais-valia. Conflito.\n"
        "- Weber: acao social, racionalizacao, desencantamento. Sentido.\n"
        "- Florestan: racismo e classes no Brasil.\n"
        "- Freyre: mesticagem, casa-grande e senzala.\n"
        "- Holanda: homem cordial, raizes ibéricas.\n"
        "- DaMatta: jeitinho, hierarquia x igualdade, casa x rua."
    ),
    "dicas": [
        "Durkheim: ordem. Marx: conflito. Weber: sentido.",
        "Florestan: critico do racismo. Freyre: mesticagem.",
        "Homem cordial (Holanda): relacao pessoal na politica.",
        "Jeitinho (DaMatta): contornar regras com relacoes.",
        "Mais-valia (Marx): diferenca entre valor produzido e salario.",
        "Racionalizacao (Weber): modernidade torna tudo racional.",
    ],
    "pegadinhas": [
        "Confundir Durkheim (ordem) com Marx (conflito).",
        "Achar que Freyre e critico da escravidao: ele romantiza.",
        "Confundir homem cordial com jeitinho: sao conceitos diferentes.",
        "Esquecer que Weber estuda o sentido da acao, nao so a estrutura.",
        "Achar que Florestan e conservador: ele e critico.",
        "Confundir casa-grande (Freyre) com casa x rua (DaMatta).",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "FREYRE, G. Casa-grande e senzala. 50. ed. Sao Paulo: Global, 2003.",
        "HOLANDA, S. B. Raizes do Brasil. 26. ed. Sao Paulo: Companhia das Letras, 2009.",
        "DAMATTA, R. Carnavais, malandros e herois. 7. ed. Rio de Janeiro: Rocco, 1997.",
        "FERNANDES, F. A integracao do negro na sociedade de classes. Sao Paulo: Globo, 2008.",
    ],
}

IMG_CLASSICAS = [
    {"file": "socio_classicas.png", "caption": "Perspectivas classicas: Durkheim, Marx, Weber e Brasil", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_classicas", [])

# ============================================================
# 11.3 Conceitos Basicos
# ============================================================
CONCEITOS = {
    "titulo": "Conceitos Basicos",
    "disciplina": "Sociologia",
    "topico": "Conceitos Basicos",
    "subtopico": "Socializacao, controle social, instituicoes, grupos e status",
    "introducao": (
        "Os conceitos basicos da sociologia sao ferramentas para "
        "analisar a vida social: socializacao, controle social, "
        "instituicoes, grupos, status e papeis sociais."
    ),
    "secoes": [
        {
            "titulo": "1. Socializacao e controle social",
            "conteudo": (
                "SOCIALIZACAO: processo pelo qual o individuo "
                "aprende a cultura de sua sociedade.\n"
                "- Primaria: infancia, familia. Forma a personalidade.\n"
                "- Secundaria: escola, trabalho. Especifica.\n"
                "- Resocializacao: presidiarios, conventos.\n"
                "- Agentes: familia, escola, midia, religiao, amigos.\n\n"
                "CONTROLE SOCIAL: mecanismos que garantem "
                "conformidade as normas.\n"
                "- Normas: regras de conduta.\n"
                "- Sancões: positivas (premio) e negativas (punicao).\n"
                "- Formal: leis, policia, justica.\n"
                "- Informal: costumes, opiniao publica, vergonha.\n"
                "- Desvio: quebra de normas. Crime: desvio formal."
            ),
            "exemplo": (
                "Uma crianca aprende a nao bater nos outros pela "
                "familia (socializacao primaria) e pela escola "
                "(secundaria). Se bate, recebe sancao informal "
                "(bronca) ou formal (suspensao). O controle social "
                "mantem a ordem: sem ele, as normas perderiam forca."
            ),
        },
        {
            "titulo": "2. Instituicoes e grupos sociais",
            "conteudo": (
                "INSTITUICOES SOCIAIS: estruturas que organizam a "
                "vida coletiva.\n"
                "- Familia: reproducao, socializacao, cuidado.\n"
                "- Escola: educacao formal, socializacao secundaria.\n"
                "- Religiao: sagrado, valores, comunidade.\n"
                "- Estado: poder, leis, ordem.\n"
                "- Midia: informacao, valores, ideologia.\n\n"
                "GRUPOS SOCIAIS:\n"
                "- Primario: intimidade, face a face (familia).\n"
                "- Secundario: formal, impessoal (empresa).\n"
                "- De pertencimento: do qual faz parte.\n"
                "- De referencia: com o qual se identifica.\n"
                "- Endogrupo: 'nos'. Exogrupo: 'eles'."
            ),
            "exemplo": (
                "A familia e grupo primario (intimidade) e "
                "instituicao social (reproducao, socializacao). "
                "A escola e grupo secundario (formal) e instituicao "
                "(educacao). Quando um aluno se identifica com uma "
                "turma diferente da sua, essa turma e grupo de "
                "referencia."
            ),
        },
        {
            "titulo": "3. Status, papeis e interacao social",
            "conteudo": (
                "STATUS: posicao social que alguem ocupa.\n"
                "- Atribuido: nao escolhido (filho, mulher).\n"
                "- Adquirido: conquistado (medico, professor).\n\n"
                "PAPEL SOCIAL: comportamento esperado de quem ocupa "
                "um status.\n"
                "- Medico: cuidar, diagnosticar.\n"
                "- Aluno: estudar, respeitar regras.\n"
                "- Mae: cuidar, educar.\n\n"
                "INTERACAO E PROCESSOS SOCIAIS:\n"
                "- Cooperacao: objetivo comum.\n"
                "- Competicao: disputa sem violencia.\n"
                "- Conflito: oposicao, violencia.\n"
                "- Acomodacao: ajuste, equilibrio.\n"
                "- Assimilacao: integracao cultural.\n"
                "- Contato social: base da interacao."
            ),
            "exemplo": (
                "Um medico tem status adquirido (estudou para ser) "
                "e papel social (cuidar, diagnosticar). Se um medico "
                "nao cumpre seu papel (negligencia), ha desvio de "
                "papel. Status e a posicao; papel e o comportamento "
                "esperado. Uma pessoa pode ter varios status "
                "(medico, mae, filha) e papeis correspondentes."
            ),
        },
    ],
    "resumo": (
        "- Socializacao: aprender a cultura. Primaria (familia) x secundaria (escola).\n"
        "- Controle social: formal (leis) x informal (costumes).\n"
        "- Instituicoes: familia, escola, religiao, Estado, midia.\n"
        "- Grupos: primario (intimidade) x secundario (formal).\n"
        "- Status: posicao. Atribuido x adquirido.\n"
        "- Papel: comportamento esperado do status.\n"
        "- Processos: cooperacao, competicao, conflito, acomodacao, assimilacao."
    ),
    "dicas": [
        "Socializacao primaria: familia. Secundaria: escola.",
        "Controle formal: leis. Informal: costumes.",
        "Status = posicao. Papel = comportamento esperado.",
        "Grupo primario: intimidade. Secundario: formalidade.",
        "Desvio: quebra de normas. Crime: desvio formal.",
        "Instituicoes organizam a vida coletiva.",
    ],
    "pegadinhas": [
        "Confundir status com papel: status e posicao, papel e comportamento.",
        "Achar que socializacao so ocorre na infancia: e continua.",
        "Confundir grupo de pertencimento com de referencia.",
        "Esquecer que controle social pode ser positivo (premios).",
        "Confundir cooperacao com acomodacao: cooperacao e objetivo comum.",
        "Achar que instituicoes sao so prédios: sao estruturas sociais.",
    ],
    "referencias": [
        "GIDDENS, A. Sociologia. 6. ed. Porto Alegre: Penso, 2012.",
        "MARTINS, C. B. Sociologia: volume unico. Sao Paulo: Moderna, 2013.",
        "BERGER, P.; BERGER, B. Socializacao: como ser membro da sociedade. Sao Paulo: Atica, 2009.",
        "MEAD, G. H. Mind, self and society. Chicago: University of Chicago Press, 1967.",
        "GOFFMAN, E. A representacao do eu na vida cotidiana. Petropolis: Vozes, 2011.",
        "MERTON, R. K. Sociologia: teoria e estrutura. Sao Paulo: Martins Fontes, 2009.",
    ],
}

IMG_CONCEITOS = [
    {"file": "socio_conceitos.png", "caption": "Conceitos basicos: socializacao, controle, instituicoes", "source": "PAES MED AI", "source_url": ""}
] + REAL_IMAGES.get("socio_conceitos", [])

# ============================================================
def main():
    pdfs = [
        (SURGIMENTO, "SOC_SURGIMENTO.pdf", IMG_SURGIMENTO, "Sociologia — Surgimento"),
        (CLASSICAS, "SOC_PERSPECTIVAS_CLASSICAS.pdf", IMG_CLASSICAS, "Sociologia — Perspectivas Classicas"),
        (CONCEITOS, "SOC_CONCEITOS_BASICOS.pdf", IMG_CONCEITOS, "Sociologia — Conceitos Basicos"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
