"""Gera todos os 12 PDFs de Química restantes de uma vez.

Usa pdf_base.py como template reutilizável.
Padrão: PT-BR, sem imagens de pessoas, layout livro, referências ABNT.
"""

from pdf_base import generate_educational_pdf

# ============================================================
# 2.2 Teoria Atômica
# ============================================================
TEORIA_ATOMICA = {
    "titulo": "Teoria Atômica",
    "disciplina": "Química",
    "topico": "Teoria Atômica",
    "subtopico": "Modelos Atômicos, Partículas, Isótopos e Configuração Eletrônica",
    "introducao": (
        "A teoria atômica é a base da Química moderna. Desde Dalton "
        "até o modelo quântico, a compreensão do átomo evoluiu "
        "consideravelmente. O átomo é a menor parte de uma substância "
        "que mantém suas propriedades químicas.\n\n"
        "Compreender a estrutura atômica é essencial para entender "
        "ligações químicas, reações, tabela periódica e radioatividade "
        "— temas centrais no vestibular de Medicina."
    ),
    "secoes": [
        {
            "titulo": "1. Evolução dos Modelos Atômicos",
            "conteudo": (
                "DALTON (1808): o átomo é uma esfera maciça, "
                "indivisível e indestrutível. Átomos de um mesmo "
                "elemento são idênticos. Átomos diferentes formam "
                "compostos em proporções definidas (Lei das "
                "Proporções Definidas).\n\n"
                "THOMSON (1897): descobriu o elétron com experimentos "
                "com raios catódicos. Propôs o modelo 'pudim de "
                "passas': uma esfera positiva com elétrons "
                "embutidos. O átomo é divisível.\n\n"
                "RUTHERFORD (1911): experiência da folha de ouro. "
                "Partículas alfa atravessavam a folha, mas algumas "
                "se desviavam. Concluiu que o átomo tem um núcleo "
                "pequeno, denso e positivo, com elétrons girando ao "
                "redor (modelo planetário).\n\n"
                "BOHR (1913): baseado na teoria dos quanta de Planck "
                "e no espectro do hidrogênio, propôs que os elétrons "
                "giram em órbitas circulares definidas (níveis de "
                "energia). Elétrons só emitem/absorvem energia ao "
                "mudar de órbita.\n\n"
                "MODELO QUÂNTICO (Schrödinger, 1926): o elétron não "
                "tem órbita definida. É descrito por função de onda, "
                "com probabilidade de ser encontrado em orbitais "
                "(regiões do espaço). Princípio da incerteza de "
                "Heisenberg: não se pode determinar simultaneamente "
                "posição e velocidade do elétron."
            ),
            "exemplo": (
                "A ressonância magnética (RM) usa propriedades "
                "quânticas dos núcleos atômicos. Núcleos de "
                "hidrogênio (prótons) em tecidos corporais se "
                "alinham em campo magnético e absorvem radiofreqüência. "
                "O sinal emitido forma imagens detalhadas do corpo "
                "sem radiação ionizante. Isso só é possível porque "
                "os núcleos têm spin quântico — um conceito do "
                "modelo quântico."
            ),
        },
        {
            "titulo": "2. Partículas Atômicas Fundamentais",
            "conteudo": (
                "PRÓTONS (p+): carga positiva (+1), massa 1 uma, "
                "localizados no núcleo. O número de prótons define "
                "o elemento (número atômico, Z).\n\n"
                "NÊUTRONS (n0): sem carga, massa 1 uma, no núcleo. "
                "Estabilizam o núcleo (força nuclear forte). A "
                "quantidade de nêutrons pode variar (isótopos).\n\n"
                "ELÉTRONS (e-): carga negativa (-1), massa "
                "0,00055 uma (desprezível), na eletrosfera. "
                "Participam das reações químicas.\n\n"
                "NÚMERO ATÔMICO (Z): número de prótons. Define o "
                "elemento. Ex.: Z=6 é carbono, Z=8 é oxigênio.\n\n"
                "NÚMERO DE MASSA (A): prótons + nêutrons. A = Z + n.\n\n"
                "NOTAÇÃO: ᴬX (ex.: ²³⁵U — urânio com 92 prótons e "
                "143 nêutrons).\n\n"
                "ÍONS: átomos que ganham ou perdem elétrons. "
                "Cátions (perdem e-, carga +). Ânions (ganham e-, "
                "carga -). Ex.: Na+ (perdeu 1 e-), Cl- (ganhou 1 e-)."
            ),
            "exemplo": (
                "O iodo (Z=53) é essencial para a tireoide produzir "
                "os hormônios T3 e T4. A deficiência de iodo na dieta "
                "causa bócio (aumento da tireoide). O isótopo "
                "radioativo iodo-131 (¹³¹I) é usado em medicina "
                "nuclear para tratar hipertireoidismo e câncer de "
                "tireoide: o isótopo se concentra na tireoide e a "
                "radiação destrói seletivamente as células doentes."
            ),
        },
        {
            "titulo": "3. Isótopos, Isóbaros e Isótonos",
            "conteudo": (
                "ISÓTOPOS: mesmo número de prótons (mesmo elemento), "
                "números de nêutrons diferentes. Ex.: ¹²C, ¹³C, ¹⁴C "
                "(todos carbono, Z=6, mas A=12, 13, 14).\n\n"
                "ISÓBAROS: mesmo número de massa (A), elementos "
                "diferentes. Ex.: ⁴⁰Ar (Z=18) e ⁴⁰K (Z=19).\n\n"
                "ISÓTONOS: mesmo número de nêutrons, elementos "
                "diferentes. Ex.: ¹⁴C (Z=6, n=8) e ¹⁶O (Z=8, n=8).\n\n"
                "ISOELETRÔNICOS: mesmo número de elétrons. Ex.: "
                "Na+ (10 e-), Ne (10 e-), O2- (10 e-).\n\n"
                "MASSA ATÔMICA: média ponderada das massas dos "
                "isótopos naturais. Ex.: Cl tem 75,8% de ³⁵Cl e "
                "24,2% de ³⁷Cl, resultando em massa atômica 35,45."
            ),
            "exemplo": (
                "O carbono-14 (¹⁴C) é um isótopo radioativo usado "
                "para datação de fósseis e artefatos arqueológicos. "
                "Ele se forma na atmosfera e é absorvido por seres "
                "vivos. Após a morte, o ¹⁴C decai com meia-vida de "
                "5730 anos. Medindo a proporção ¹⁴C/¹²C, calcula-se "
                "a idade. Em medicina, isótopos como ⁹⁹mTc "
                "(tecnécio) são usados em cintilografias para "
                "diagnóstico de tumores e embolias."
            ),
        },
        {
            "titulo": "4. Configuração Eletrônica e Números Quânticos",
            "conteudo": (
                "DISTRIBUIÇÃO ELETRÔNICA: os elétrons se distribuem "
                "em camadas (K, L, M, N, O, P, Q) ou níveis (1-7). "
                "Cada camada tem subníveis (s, p, d, f) com "
                "capacidades: s=2, p=6, d=10, f=14.\n\n"
                "REGRA DE LINUS PAULING: ordem de preenchimento "
                "1s 2s 2p 3s 3p 4s 3d 4p 5s 4d 5p 6s 4f 5d 6p 7s "
                "5f 6d 7p. Diagrama de Linus Pauling facilita a "
                "distribuição.\n\n"
                "PRINCÍPIO DA EXCLUSÃO DE PAULI: no máximo 2 "
                "elétrons por orbital, com spins opostos.\n\n"
                "REGRA DE HUND: ao preencher orbitais de mesma "
                "energia, os elétrons se distribuem um em cada "
                "orbital antes de se parearem.\n\n"
                "NÚMEROS QUÂNTICOS:\n"
                "- Principal (n): nível de energia (1-7).\n"
                "- Secundário (l): subnível (0=s, 1=p, 2=d, 3=f).\n"
                "- Magnético (m): orientação do orbital (-l a +l).\n"
                "- Spin (s): rotação do elétron (+1/2 ou -1/2).\n\n"
                "CAMADA DE VALÊNCIA: última camada preenchida. "
                "Determina as propriedades químicas do elemento."
            ),
            "exemplo": (
                "A configuração eletrônica do sódio (Na, Z=11) é "
                "1s² 2s² 2p⁶ 3s¹. Ele tem 1 elétron na camada de "
                "valência, por isso tende a perdê-lo formando Na+ "
                "(cátion). Já o cloro (Cl, Z=17) é 1s² 2s² 2p⁶ 3s² "
                "3p⁵, com 7 elétrons na valência — tende a ganhar "
                "1 elétron formando Cl-. A atração entre Na+ e Cl- "
                "forma o NaCl (sal de cozinha). A configuração "
                "eletrônica explica toda a reatividade química."
            ),
        },
    ],
    "resumo": (
        "- Dalton: átomo maciço e indivisível. Thomson: pudim de passas.\n"
        "- Rutherford: núcleo + eletrosfera. Bohr: órbitas definidas. Quântico: orbitais.\n"
        "- Prótons (Z, +), nêutrons (n, 0), elétrons (e-, valência). A = Z + n.\n"
        "- Isótopos: mesmo Z, A diferente. Isóbaros: mesmo A. Isótonos: mesmo n.\n"
        "- Configuração: 1s 2s 2p 3s 3p 4s 3d... Pauli: 2 e-/orbital. Hund: espalhar antes.\n"
        "- Números quânticos: n (nível), l (subnível), m (orientação), s (spin)."
    ),
    "dicas": [
        "Z = prótons = elétrons (átomo neutro). A = Z + n.",
        "Isótopos: mesmo Z, A diferente (ex: 12C, 13C, 14C).",
        "Camada de valência = última camada. Define reatividade.",
        "Regra de Hund: um elétron por orbital antes de parear.",
        "Princípio de Pauli: máximo 2 elétrons por orbital, spins opostos.",
        "Cátions perdem elétrons (+), ânions ganham elétrons (-).",
    ],
    "pegadinhas": [
        "Achar que isótopos têm propriedades químicas muito diferentes: são quase idênticas (mesmo Z).",
        "Confundir isóbaros com isótopos: isóbaros têm mesmo A, elementos diferentes.",
        "Esquecer que nêutrons NÃO afetam a carga do átomo, apenas a massa.",
        "Achar que o modelo de Bohr é o atual: o modelo quântico (Schrödinger) substituiu.",
        "Confundir número atômico (Z) com número de massa (A).",
        "Esquecer que íons têm número de elétrons diferente de prótons.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "MAHAN, B. M.; MYERS, R. J. Química: Um Curso Universitário. 4. ed. Lisboa: Fundação Calouste Gulbenkian, 1995.",
    ],
}

IMG_TEORIA_ATOMICA = [
    {"file": "br_qui2_evolucao.jpg",
     "caption": "Evolução dos modelos atômicos: de Dalton ao modelo quântico",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/modelos-atomicos/"},
    {"file": "br_qui2_rutherford.jpg",
     "caption": "Modelo de Rutherford: núcleo e elétrons em órbita",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/modelos-atomicos/"},
    {"file": "br_qui2_isotopos.jpg",
     "caption": "Isótopos do carbono: 12C, 13C e 14C",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/isotopos-isobaros-e-isotonos/"},
    {"file": "br_qui2_atomo.jpg",
     "caption": "Estrutura atômica: prótons, nêutrons e elétrons",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/modelos-atomicos/"},
]

# ============================================================
# 2.3 Classificação Periódica
# ============================================================
CLASSIFICACAO_PERIODICA = {
    "titulo": "Classificação Periódica",
    "disciplina": "Química",
    "topico": "Classificação Periódica",
    "subtopico": "Tabela Periódica, Períodos, Grupos e Propriedades",
    "introducao": (
        "A Tabela Periódica organiza os elementos químicos por "
        "número atômico e propriedades. É a ferramenta mais "
        "importante da Química — permite prever comportamentos, "
        "ligações e reações. Foi desenvolvida por Mendeleev (1869) "
        "e refinada por Moseley (1913) com base no número atômico."
    ),
    "secoes": [
        {
            "titulo": "1. Estrutura da Tabela Periódica",
            "conteudo": (
                "PERÍODOS: linhas horizontais (1 a 7). Indicam o "
                "número de camadas eletrônicas. Ex.: H e He estão "
                "no 1º período (1 camada).\n\n"
                "GRUPOS (famílias): colunas verticais (1 a 18). "
                "Elementos do mesmo grupo têm mesma configuração "
                "eletrônica de valência e propriedades semelhantes.\n\n"
                "CLASSIFICAÇÃO DOS ELEMENTOS:\n"
                "- Metais: lado esquerdo e centro. Brilho, "
                "condutividade, maleabilidade. Sólidos (exceto Hg).\n"
                "- Não-metais: lado direito. Sólidos, líquidos ou "
                "gasosos. Maus condutores.\n"
                "- Semimetais (metaloides): fronteira entre metais "
                "e não-metais (B, Si, Ge, As, Sb, Te).\n"
                "- Hidrogênio: à parte, comportamento único.\n\n"
                "FAMÍLIAS IMPORTANTES:\n"
                "- Grupo 1: metais alcalinos (Li, Na, K, Rb, Cs, Fr) "
                "— muito reativos.\n"
                "- Grupo 2: alcalinoterrosos (Be, Mg, Ca, Sr, Ba, Ra).\n"
                "- Grupo 17: halogênios (F, Cl, Br, I, At) — muito "
                "reativos, formam sais.\n"
                "- Grupo 18: gases nobres (He, Ne, Ar, Kr, Xe, Rn) "
                "— inertes, camada completa.\n"
                "- Grupos 3-12: metais de transição.\n"
                "- Linhas inferiores: lantanídeos e actinídeos."
            ),
            "exemplo": (
                "O potássio (K, grupo 1) é essencial para o "
                "funcionamento do coração e dos nervos. A "
                "concentração de K+ no sangue é controlada pelos "
                "rins. Tanto excesso (hipercalemia) quanto deficiência "
                "(hipocalemia) causam arritmias cardíacas graves. "
                "Por isso, pacientes cardíacos monitoram o potássio "
                "e alguns tomam suplementos. O sódio (Na, mesmo "
                "grupo) também é eletrólito importante, mas em "
                "excesso causa hipertensão."
            ),
        },
        {
            "titulo": "2. Propriedades Periódicas",
            "conteudo": (
                "RAIO ATÔMICO: metade da distância entre núcleos de "
                "átomos vizinhos. Aumenta para baixo (mais camadas) "
                "e diminui para a direita (mais prótons puxam "
                "elétrons).\n\n"
                "ENERGIA DE IONIZAÇÃO: energia para remover um "
                "elétron. Aumenta para a direita (átomo menor, "
                "elétron mais preso) e diminui para baixo.\n\n"
                "AFINIDADE ELETRÔNICA: energia liberada ao ganhar "
                "elétron. Aumenta para a direita e diminui para "
                "baixo. Halogênios têm maior afinidade.\n\n"
                "ELETRONEGATIVIDADE: tendência de atrair elétrons "
                "em ligação. Escala de Pauling (0 a 4). F = 4,0 "
                "(mais eletronegativo). Aumenta para a direita e "
                "diminui para baixo.\n\n"
                "ELETROPOSITIVIDADE: tendência de perder elétrons. "
                "Oposta à eletronegatividade. Metais alcalinos são "
                "muito eletropositivos.\n\n"
                "CARÁTER METÁLICO: aumenta para baixo e para a "
                "esquerda. Caráter não-metálico: aumenta para cima "
                "e para a direita."
            ),
            "exemplo": (
                "A eletronegatividade explica a polaridade das "
                "moléculas de água. O oxigênio (3,44) é mais "
                "eletronegativo que o hidrogênio (2,20). Por isso, "
                "os elétrons da ligação O-H ficam mais próximos do "
                "oxigênio, criando um polo negativo (O) e um positivo "
                "(H). Essa polaridade permite ligações de hidrogênio "
                "entre moléculas de água, responsáveis por: alta "
                "temperatura de ebulição, solvente universal, "
                "estrutura do gelo, coesão e capilaridade."
            ),
        },
        {
            "titulo": "3. História e Evolução da Tabela",
            "conteudo": (
                "MENDELEEV (1869): organizou os elementos por massa "
                "atômica, notando periodicidade nas propriedades. "
                "Deixou espaços vazios para elementos ainda não "
                "descobertos (eka-silício = germânio, eka-alumínio "
                "= gálio). Sua genialidade foi prever propriedades "
                "de elementos que seriam descobertos depois.\n\n"
                "MOSELEY (1913): reorganizou a tabela por número "
                "atômico (Z), resolvendo inconsistências (ex.: Ar e "
                "K, Co e Ni, Te e I).\n\n"
                "ESTRUTURA ATUAL: 7 períodos, 18 grupos. Elementos "
                "organizados por configuração eletrônica. Blocos "
                "s, p, d, f correspondem aos subníveis de valência."
            ),
            "exemplo": (
                "Mendeleev previu o germânio (Ge) antes de ser "
                "descoberto. Ele chamou de 'eka-silício' e previu "
                "sua massa atômica (~72), densidade (5,5 g/cm³) e "
                "propriedades químicas. Quando Clemens Winkler "
                "descobriu o germânio em 1886, as propriedades "
                "correspondiam. Isso validou a tabela periódica "
                "como ferramenta preditiva — um dos maiores "
                "triunfos da ciência."
            ),
        },
    ],
    "resumo": (
        "- Períodos = linhas (camadas). Grupos = colunas (valência).\n"
        "- Metais: esquerda/centro. Não-metais: direita. Semimetais: fronteira.\n"
        "- Grupo 1: alcalinos. Grupo 2: alcalinoterrosos. 17: halogênios. 18: gases nobres.\n"
        "- Raio atômico: ↓ aumenta, → diminui. Eletronegatividade: ↓ diminui, → aumenta.\n"
        "- Energia de ionização: ↓ diminui, → aumenta. Afinidade eletrônica: → aumenta.\n"
        "- Mendeleev (1869) por massa; Moseley (1913) por número atômico."
    ),
    "dicas": [
        "Metais alcalinos (grupo 1) são os mais reativos (exceto H).",
        "Gases nobres (grupo 18) são inertes — camada completa.",
        "Eletronegatividade: F > O > Cl > N > Br > I > C > H.",
        "Raio atômico aumenta para baixo (mais camadas) e diminui para a direita.",
        "Energia de ionização é inversa do raio: aumenta para a direita e diminui para baixo.",
        "Semimetais: B, Si, Ge, As, Sb, Te — fronteira entre metais e não-metais.",
    ],
    "pegadinhas": [
        "Achar que o hidrogênio é metal alcalino: está no grupo 1 mas é não-metal.",
        "Confundir período com grupo: período = linha, grupo = coluna.",
        "Esquecer que eletronegatividade e energia de ionização variam na MESMA direção.",
        "Achar que gases nobres não formam compostos: Xe e Kr formam (ex.: XeF2).",
        "Confundir afinidade eletrônica com eletronegatividade: afinidade é do átomo isolado.",
        "Esquecer que Mendeleev organizou por massa atômica, não número atômico.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "GREENWOOD, N. N.; EARNSHAW, A. Chemistry of the Elements. 2. ed. Oxford: Butterworth-Heinemann, 1997.",
    ],
}

IMG_CLASSIFICACAO = [
    {"file": "br_qui3_tabela_grande.jpg",
     "caption": "Tabela Periódica atual: elementos organizados por número atômico",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/tabela-periodica/"},
    {"file": "br_qui3_familias.jpg",
     "caption": "Famílias da Tabela Periódica: grupos e suas características",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/tabela-periodica/"},
    {"file": "br_qui3_propriedades.jpg",
     "caption": "Propriedades periódicas: raio, ionização, eletronegatividade",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/propriedades-periodicas/"},
]

# ============================================================
# 2.4 Ligações Químicas
# ============================================================
LIGACOES_QUIMICAS = {
    "titulo": "Ligações Químicas",
    "disciplina": "Química",
    "topico": "Ligações Químicas",
    "subtopico": "Iônica, Covalente, Metálica, Polaridade e Forças Intermoleculares",
    "introducao": (
        "As ligações químicas unem átomos para formar moléculas e "
        "compostos. A tendência dos átomos é alcançar a estabilidade "
        "da camada de valência (regra do octeto, exceto H e He que "
        "seguem a regra do dueto). Os três tipos principais são: "
        "iônica, covalente e metálica."
    ),
    "secoes": [
        {
            "titulo": "1. Ligação Iônica",
            "conteudo": (
                "LIGAÇÃO IÔNICA: transferência de elétrons entre "
                "metal e não-metal. O metal perde elétrons (forma "
                "cátion), o não-metal ganha (forma ânion). A "
                "atração eletrostática forma o composto iônico.\n\n"
                "EXEMPLO: Na (1s²2s²2p⁶3s¹) perde 1 e- → Na+ "
                "(1s²2s²2p⁶). Cl (1s²2s²2p⁶3s²3p⁵) ganha 1 e- → "
                "Cl- (1s²2s²2p⁶3s²3p⁶). Ambos atingem configuração "
                "de gás nobre. Forma-se NaCl.\n\n"
                "PROPRIEDADES DOS COMPOSTOS IÔNICOS:\n"
                "- Sólidos cristalinos à temperatura ambiente;\n"
                "- Altos pontos de fusão e ebulição;\n"
                "- Solúveis em água (geralmente);\n"
                "- Conduzem eletricidade quando dissolvidos ou "
                "fundidos (íons livres).\n\n"
                "RETÍCULO CRISTALINO: arranjo organizado de cátions "
                "e ânions. Cada íon é cercado por vários íons de "
                "carga oposta. Energia reticular = energia para "
                "separar totalmente os íons."
            ),
            "exemplo": (
                "O NaCl (sal de cozinha) é o exemplo clássico. "
                "Soluções salinas (soro fisiológico 0,9%) são "
                "essenciais em medicina para reposição de "
                "eletrólitos. A condutividade elétrica do NaCl "
                "dissolvido é usada para medir concentração de "
                "solutos na urina (densidade urinária)."
            ),
        },
        {
            "titulo": "2. Ligação Covalente",
            "conteudo": (
                "LIGAÇÃO COVALENTE: compartilhamento de elétrons "
                "entre não-metais. Cada átomo contribui com elétrons "
                "para formar pares eletrônicos compartilhados.\n\n"
                "TIPOS:\n"
                "- Covalente simples: 1 par compartilhado (H-H, Cl-Cl).\n"
                "- Covalente dupla: 2 pares (O=O, CO₂).\n"
                "- Covalente tripla: 3 pares (N≡N, HC≡CH).\n\n"
                "POLARIDADE DAS LIGAÇÕES:\n"
                "- Apolar: átomos iguais ou mesma eletronegatividade "
                "(H₂, O₂, Cl₂).\n"
                "- Polar: átomos diferentes, diferença de "
                "eletronegatividade < 1,7 (HCl, H₂O).\n"
                "- Iônica: diferença > 1,7 (NaCl, KCl).\n\n"
                "POLARIDADE DAS MOLÉCULAS: depende da polaridade das "
                "ligações E da geometria molecular. Moléculas "
                "simétricas com ligações polares podem ser apolares "
                "(CO₂, CH₄). Moléculas assimétricas são polares "
                "(H₂O, NH₃).\n\n"
                "PROPRIEDADES DOS COMPOSTOS COVALENTES:\n"
                "- Podem ser sólidos, líquidos ou gasosos;\n"
                "- Baixos PF e PE (moléculas pequenas);\n"
                "- Geralmente insolúveis em água (exceto polares);\n"
                "- Não conduzem eletricidade (sem íons livres)."
            ),
            "exemplo": (
                "A água (H₂O) é covalente polar. A geometria angular "
                "(104,5°) faz com que os polos não se cancelem. "
                "Essa polaridade é a base da vida: dissolve sais, "
                "gases e biomoléculas. O CO₂, por outro lado, é "
                "linear e apolar — por isso não dissolve bem em "
                "água, mas reage com ela formando ácido carbônico "
                "(H₂CO₃), importante no equilíbrio ácido-base do "
                "sangue."
            ),
        },
        {
            "titulo": "3. Geometria Molecular",
            "conteudo": (
                "A geometria molecular é prevista pela teoria VSEPR "
                "(Repulsão de Pares de Elétrons da Camada de "
                "Valência). Os pares eletrônicos se repelem e se "
                "organizam o mais distante possível.\n\n"
                "GEOMETRIAS PRINCIPAIS:\n"
                "- Linear: 2 pares, 180° (BeCl₂, CO₂).\n"
                "- Trigonal plana: 3 pares, 120° (BF₃).\n"
                "- Tetraédrica: 4 pares, 109,5° (CH₄, CCl₄).\n"
                "- Piramidal trigonal: 3 ligantes + 1 par isolado, "
                "107° (NH₃).\n"
                "- Angular: 2 ligantes + 2 pares isolados, 104,5° "
                "(H₂O).\n"
                "- Bipirâmide trigonal: 5 pares (PCl₅).\n"
                "- Octaédrica: 6 pares (SF₆).\n\n"
                "PARES ISOLADOS: ocupam mais espaço que pares "
                "ligantes, comprimindo os ângulos. Por isso H₂O "
                "(104,5°) < NH₃ (107°) < CH₄ (109,5°)."
            ),
            "exemplo": (
                "A geometria da água (angular, 104,5°) é crucial "
                "para a vida. Se fosse linear, a molécula seria "
                "apolar e não formaria pontes de hidrogênio. A água "
                "não seria solvente universal, o gelo não flutuaria "
                "e a vida como conhecemos não existiria. Tudo por "
                "causa dos dois pares isolados do oxigênio!"
            ),
        },
        {
            "titulo": "4. Forças Intermoleculares e Ligação Metálica",
            "conteudo": (
                "FORÇAS INTERMOLECULARES (entre moléculas):\n"
                "- Pontes de hidrogênio: H ligado a F, O ou N atrai "
                "átomos eletronegativos. Mais forte. Ex.: H₂O, NH₃, "
                "HF. Explica PE anormalmente alto.\n"
                "- Dipolo-dipolo: moléculas polares se atraem. "
                "Força média. Ex.: HCl, SO₂.\n"
                "- Dipolo induzido (London): moléculas apolares. "
                "Flutuações momentâneas de carga. Mais fraca. Ex.: "
                "CH₄, Cl₂.\n\n"
                "ORDEM DE FORÇA: ponte de H > dipolo-dipolo > London.\n\n"
                "LIGAÇÃO METÁLICA: metais formam retículo de "
                "cátions mergulhados em 'mar' de elétrons "
                "deslocalizados (teoria do mar de elétrons). Explica:\n"
                "- Condutividade elétrica (elétrons livres);\n"
                "- Condutividade térmica;\n"
                "- Maleabilidade e ductilidade;\n"
                "- Brilho metálico;\n"
                "- Sólidos à temperatura ambiente (exceto Hg)."
            ),
            "exemplo": (
                "As pontes de hidrogênio na água explicam por que "
                "o gelo flutua. No estado sólido, as moléculas se "
                "organizam em uma estrutura hexagonal com espaços "
                "vazios, tornando o gelo menos denso que a água "
                "líquida. Por isso os lagos congelam de cima para "
                "baixo, permitindo a vida aquática sob o gelo. "
                "Sem pontes de H, a vida não existiria."
            ),
        },
    ],
    "resumo": (
        "- Iônica: metal + não-metal, transferência de e-. Sólidos, altos PF, conduzem dissolvidos.\n"
        "- Covalente: não-metais, compartilhamento. Apolar (simétrica) ou polar (assimétrica).\n"
        "- Metálica: cátions + mar de elétrons. Condutividade, maleabilidade.\n"
        "- Geometria: linear, trigonal, tetraédrica, piramidal, angular. VSEPR.\n"
        "- Forças intermoleculares: ponte de H > dipolo-dipolo > London.\n"
        "- Polaridade da molécula = polaridade das ligações + geometria."
    ),
    "dicas": [
        "Iônica: metal + não-metal. Covalente: não-metal + não-metal. Metálica: metal + metal.",
        "Diferença de eletronegatividade > 1,7 = iônica; < 1,7 = covalente polar.",
        "Ponte de hidrogênio só com H ligado a F, O ou N.",
        "H₂O angular (104,5°), NH₃ piramidal (107°), CH₄ tetraédrica (109,5°).",
        "Molécula apolar: ligações apolares OU geometria simétrica com ligações polares.",
        "Compostos iônicos conduzem dissolvidos ou fundidos; covalentes não conduzem.",
    ],
    "pegadinhas": [
        "Achar que CO₂ é polar: é apolar (linear, ligações polares se cancelam).",
        "Confundir polaridade da ligação com polaridade da molécula.",
        "Esquecer que ponte de hidrogênio é força intermolecular, não ligação covalente.",
        "Achar que todos os compostos covalentes têm baixo PE: redes covalentes (diamante) têm PF altíssimo.",
        "Confundir dipolo-dipolo com ponte de hidrogênio: ponte de H só com F, O, N.",
        "Esquecer que pares isolados reduzem ângulos: H₂O < NH₃ < CH₄.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "PAULING, L. The Nature of the Chemical Bond. 3. ed. Ithaca: Cornell University Press, 1960.",
    ],
}

IMG_LIGACOES = [
    {"file": "br_qui4_ionica2.jpg",
     "caption": "Ligação iônica: transferência de elétrons entre metal e não-metal",
     "source": "Brasil Escola", "source_url": "https://brasilescola.uol.com.br/quimica/ligacao-ionica.htm"},
    {"file": "br_qui4_covalente2.jpg",
     "caption": "Ligação covalente: compartilhamento de pares eletrônicos",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/ligacao-covalente/"},
    {"file": "br_qui4_geometria.jpg",
     "caption": "Geometria molecular: linear, trigonal, tetraédrica, angular",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/geometria-molecular/"},
    {"file": "br_qui4_metalica.jpg",
     "caption": "Ligação metálica: mar de elétrons e retículo de cátions",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/ligacao-covalente/"},
]

# ============================================================
# Gerar todos os PDFs
# ============================================================
def main():
    pdfs = [
        (TEORIA_ATOMICA, "QU_TEORIA_ATOMICA.pdf", IMG_TEORIA_ATOMICA, "Química — Teoria Atômica"),
        (CLASSIFICACAO_PERIODICA, "QU_CLASSIFICACAO_PERIODICA.pdf", IMG_CLASSIFICACAO, "Química — Classificação Periódica"),
        (LIGACOES_QUIMICAS, "QU_LIGACOES_QUIMICAS.pdf", IMG_LIGACOES, "Química — Ligações Químicas"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluído: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
