# -*- coding: utf-8 -*-
"""Gera PDFs de Química — batch 2 (tópicos 5-9)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 2.5 Transformações Químicas
# ============================================================
TRANSFORMACOES = {
    "titulo": "Transformações Químicas",
    "disciplina": "Química",
    "topico": "Transformações Químicas",
    "subtopico": "Reações, Tipos, Balanceamento e Oxidação",
    "introducao": (
        "As transformações químicas são processos em que substâncias "
        "são convertidas em novas substâncias, com propriedades "
        "diferentes. A representação simbólica dessas transformações "
        "é feita por meio de equações químicas."
    ),
    "secoes": [
        {
            "titulo": "1. Equações Químicas e Tipos de Reações",
            "conteudo": (
                "EQUAÇÃO QUÍMICA: representação simbólica de uma "
                "reação. Reagentes → Produtos. Ex.: 2H₂ + O₂ → 2H₂O.\n\n"
                "TIPOS DE REAÇÕES:\n"
                "- Adição/Síntese: A + B → AB. Ex.: 2Na + Cl₂ → 2NaCl.\n"
                "- Decomposição: AB → A + B. Ex.: 2H₂O → 2H₂ + O₂.\n"
                "- Deslocamento simples: A + BC → AC + B. Ex.: "
                "Zn + 2HCl → ZnCl₂ + H₂.\n"
                "- Dupla troca: AB + CD → AD + CB. Ex.: NaCl + AgNO₃ "
                "→ AgCl + NaNO₃.\n"
                "- Combustão: substância + O₂ → CO₂ + H₂O + energia. "
                "Ex.: CH₄ + 2O₂ → CO₂ + 2H₂O.\n"
                "- Oxirredução: transferência de elétrons. Pode "
                "ocorrer junto com outros tipos.\n\n"
                "NÚMERO DE OXIDAÇÃO (Nox): carga que um átomo teria "
                "se todos os elétrons das ligações fossem atribuídos "
                "ao elemento mais eletronegativo. Regras: substância "
                "simples = 0; íon = carga; H = +1 (com não-metais) "
                "ou -1 (com metais); O = -2 (geralmente); soma dos "
                "nox = carga da espécie."
            ),
            "exemplo": (
                "A combustão da glicose é a base da respiração celular: "
                "C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + energia (ATP). O "
                "carbono da glicose é oxidado (Nox passa de 0 para "
                "+4 no CO₂), e o oxigênio é reduzido (passa de 0 "
                "para -2 na água). Sem essa reação, não haveria "
                "energia para a vida."
            ),
        },
        {
            "titulo": "2. Balanceamento de Equações",
            "conteudo": (
                "LEI DA CONSERVAÇÃO DAS MASSAS (Lavoisier): a massa "
                "total dos reagentes é igual à dos produtos. Nenhum "
                "átomo é criado ou destruído — apenas rearranjado.\n\n"
                "BALANCEAMENTO: ajustar coeficientes para que o número "
                "de átomos de cada elemento seja igual nos dois lados.\n\n"
                "MÉTODOS:\n"
                "- Tentativa: ajustar coeficientes manualmente.\n"
                "- Sistema algébrico: atribuir variáveis aos "
                "coeficientes e resolver.\n"
                "- Método das tentativas com ordem: começar pelo "
                "elemento mais complexo, depois o mais simples, "
                "deixar O e H por último.\n\n"
                "EXEMPLO: Fe + O₂ → Fe₂O₃\n"
                "Passo 1: 4Fe + 3O₂ → 2Fe₂O₃ (Fe: 4=4; O: 6=6).\n\n"
                "BALANCEAMENTO DE OXIRREDUÇÃO:\n"
                "1. Determinar os Nox de cada elemento;\n"
                "2. Identificar quem oxidou e quem reduziu;\n"
                "3. Igualar a variação de Nox multiplicando;\n"
                "4. Balancear os demais átomos;\n"
                "5. Balancear O com H₂O e H com H+ (meio ácido) "
                "ou OH- (meio básico)."
            ),
            "exemplo": (
                "O balanceamento é essencial na indústria farmacêutica. "
                "Para produzir ácido acetilsalicílico (aspirina), a "
                "equação deve ser balanceada para calcular as "
                "quantidades exatas de reagentes. Um erro de "
                "balanceamento pode levar a impurezas tóxicas no "
                "medicamento final. A estequiometria correta garante "
                "rendimento máximo e segurança."
            ),
        },
        {
            "titulo": "3. Previsão de Ocorrência de Reações",
            "conteudo": (
                " Nem toda mistura de reagentes resulta em reação. "
                "Para prever se uma reação ocorre, usamos critérios:\n\n"
                "DESLOCAMENTO SIMPLES: ocorre se o elemento livre for "
                "mais reativo que o elemento combinado. Série de "
                "reatividade: Li > K > Na > Ca > Mg > Al > Zn > Fe > "
                "Ni > Sn > Pb > H > Cu > Ag > Au. Um metal mais "
                "reativo desloca um menos reativo.\n\n"
                "DUPLA TROCA: ocorre se formar um produto precipitado "
                "(insolúvel), gasoso ou molecular fraco (água, ácido "
                "fraco). Tabela de solubilidade: nitratos, acetatos e "
                "sais de metais alcalinos são solúveis.\n\n"
                "COMBUSTÃO: ocorre se houver combustível, comburente "
                "(O₂) e energia de ativação (calor).\n\n"
                "ENERGIA DE ATIVAÇÃO: energia mínima para iniciar a "
                "reação. Catalisadores reduzem essa energia sem ser "
                "consumidos."
            ),
            "exemplo": (
                "O ferro desloca o cobre de uma solução de CuSO₄: "
                "Fe + CuSO₄ → FeSO₄ + Cu. O ferro é mais reativo "
                "que o cobre. Isso é usado em metalurgia e explica "
                "por que pregos de ferro em solução de sulfato de "
                "cobre ficam recobertos de cobre. Já o cobre NÃO "
                "desloca o ferro de FeSO₄ — a reação não ocorre."
            ),
        },
    ],
    "resumo": (
        "- Reação química: reagentes → produtos, novas substâncias.\n"
        "- Tipos: síntese, decomposição, deslocamento, dupla troca, combustão, oxirredução.\n"
        "- Nox: carga teórica do átomo. Oxidação = aumento; redução = diminuição.\n"
        "- Balanceamento: conservar átomos (Lavoisier). Métodos: tentativa, algébrico, redox.\n"
        "- Dupla troca ocorre se formar precipitado, gás ou molécula fraca.\n"
        "- Série de reatividade: Li > ... > Au. Mais reativo desloca menos reativo."
    ),
    "dicas": [
        "Lavoisier: massa dos reagentes = massa dos produtos.",
        "Oxidação = perda de elétrons (aumento do Nox). Redução = ganho (diminuição).",
        "Combustão completa: C → CO₂. Combustão incompleta: C → CO ou C.",
        "Balancear O e H por último; começar pelo elemento mais complexo.",
        "Sais de nitrato, acetato, alcalinos e amônio são sempre solúveis.",
        "Catalisador reduz energia de ativação, não altera produtos.",
    ],
    "pegadinhas": [
        "Achar que combustão incompleta sempre forma CO₂: pode formar CO (tóxico).",
        "Confundir oxidação com ganho de elétrons: oxidação é PERDA (aumento do Nox).",
        "Esquecer que catalisador não aparece na equação global.",
        "Achar que toda dupla troca ocorre: só ocorre se formar precipitado, gás ou fraco.",
        "Confundir reagente mais reativo com produto: o mais reativo DESLOCA o menos reativo.",
        "Esquecer de verificar Nox de H (-1 com metais, +1 com não-metais).",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "MORTIMER, E. F.; MACHADO, A. H. Química para o Ensino Médio. São Paulo: Scipione, 2010.",
    ],
}

IMG_TRANSFORMACOES = [
    {"file": "br_qui5_reacoes.jpg",
     "caption": "Reações químicas: transformação de reagentes em produtos",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/reacoes-quimicas/"},
    {"file": "br_qui5_balanceamento.jpg",
     "caption": "Balanceamento químico: conservação de átomos",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/balanceamento-quimico/"},
]

# ============================================================
# 2.6 Funções Inorgânicas
# ============================================================
FUNCOES_INORGANICAS = {
    "titulo": "Funções Inorgânicas",
    "disciplina": "Química",
    "topico": "Funções Inorgânicas",
    "subtopico": "Ácidos, Bases, Sais e Óxidos",
    "introducao": (
        "As funções inorgânicas agrupam substâncias com propriedades "
        "semelhantes. As quatro principais são: ácidos, bases, sais "
        "e óxidos. Compreender essas funções é essencial para "
        "entender reações, pH, neutralização e processos biológicos."
    ),
    "secoes": [
        {
            "titulo": "1. Ácidos",
            "conteudo": (
                "ÁCIDOS (Arrhenius): substâncias que ionizam em água, "
                "liberando H+ (cátion H+ ou H₃O+). Ex.: HCl, H₂SO₄, "
                "HNO₃, H₃PO₄, CH₃COOH.\n\n"
                "CLASSIFICAÇÃO:\n"
                "- Quanto à força: fortes (ionização completa: HCl, "
                "HNO₃, H₂SO₄) e fracos (ionização parcial: H₂CO₃, "
                "CH₃COOH, HF).\n"
                "- Quanto ao número de H ionizáveis: monoácidos (1H), "
                "diácidos (2H), triácidos (3H).\n"
                "- Quanto à presença de oxigênio: hidrácidos (sem O: "
                "HCl, H₂S) e oxiácidos (com O: HNO₃, H₂SO₄).\n\n"
                "NOMENCLATURA:\n"
                "- Hidrácidos: ácido [nome do ânion com ídrico]. "
                "Ex.: HCl = ácido clorídrico.\n"
                "- Oxiácidos: ácido [nome do central com ico/oso]. "
                "Ex.: HNO₃ = ácido nítrico; HNO₂ = ácido nitroso.\n\n"
                "BRØNSTED-LOWRY: ácido é doador de prótons (H+).\n"
                "LEWIS: ácido é aceitador de par de elétrons."
            ),
            "exemplo": (
                "O ácido clorídrico (HCl) é produzido pelo estômago "
                "para digestão. O pH gástrico é 1-2, muito ácido. "
                "Excesso de HCl causa gastrite e úlcera. Antiácidos "
                "(NaHCO₃, Mg(OH)₂) neutralizam o excesso: HCl + "
                "NaHCO₃ → NaCl + H₂O + CO₂. Inibidores de bomba de "
                "prótons (omeprazol) reduzem a produção de HCl."
            ),
        },
        {
            "titulo": "2. Bases",
            "conteudo": (
                "BASES (Arrhenius): substâncias que dissociam em água, "
                "liberando OH- (hidroxila). Ex.: NaOH, KOH, Ca(OH)₂, "
                "Mg(OH)₂, NH₄OH.\n\n"
                "CLASSIFICAÇÃO:\n"
                "- Quanto à força: fortes (NaOH, KOH, Ca(OH)₂) e "
                "fracas (NH₄OH, Mg(OH)₂).\n"
                "- Quanto ao número de OH: monobases (1OH), dibases "
                "(2OH), tribases (3OH).\n"
                "- Quanto à solubilidade: solúveis (NaOH, KOH) e "
                "praticamente insolúveis (Fe(OH)₃, Cu(OH)₂).\n\n"
                "NOMENCLATURA: [nome do cátion] + hidróxido. Ex.: "
                "NaOH = hidróxido de sódio; Ca(OH)₂ = hidróxido de "
                "cálcio.\n\n"
                "BRØNSTED-LOWRY: base é receptora de prótons (H+).\n"
                "LEWIS: base é doadora de par de elétrons.\n\n"
                "PROPRIEDADES: sabor cáustico, conduzem eletricidade "
                "(dissolvidas), mudam indicadores (fenolftaleína "
                "fica rosa, tornassol fica azul)."
            ),
            "exemplo": (
                "O hidróxido de magnésio (Mg(OH)₂) é o princípio ativo "
                "do leite de magnésia, usado como antiácido e "
                "laxante. Neutraliza o excesso de HCl no estômago: "
                "Mg(OH)₂ + 2HCl → MgCl₂ + 2H₂O. O hidróxido de "
                "alumínio (Al(OH)₃) também é usado em antiácidos."
            ),
        },
        {
            "titulo": "3. Sais e Óxidos",
            "conteudo": (
                "SAIS: compostos iônicos formados pela reação entre "
                "ácido e base (neutralização). Cátion (diferente de "
                "H+) + ânion (diferente de OH-). Ex.: NaCl, KNO₃, "
                "CaSO₄, FeCl₃.\n\n"
                "CLASSIFICAÇÃO:\n"
                "- Neutros: sem H+ ou OH- (NaCl, K₂SO₄).\n"
                "- Ácidos: com H+ (NaHSO₄, NaHCO₃).\n"
                "- Básicos: com OH- (Ca(OH)Cl, Mg(OH)Cl).\n"
                "- Duplos: dois cátions diferentes (KAl(SO₄)₂).\n"
                "- Hidratados: com água de cristalização (CuSO₄·5H₂O).\n\n"
                "NOMENCLATURA: [nome do ânion] de [nome do cátion]. "
                "Ex.: NaCl = cloreto de sódio; FeSO₄ = sulfato "
                "ferroso; Fe₂(SO₄)₃ = sulfato férrico.\n\n"
                "ÓXIDOS: compostos binários com oxigênio. O oxigênio "
                "é sempre o elemento mais eletronegativo. Ex.: CO₂, "
                "SO₂, Fe₂O₃, Na₂O, H₂O.\n\n"
                "CLASSIFICAÇÃO:\n"
                "- Básicos: metal + O. Reagem com água formando base "
                "(Na₂O + H₂O → 2NaOH).\n"
                "- Ácidos: não-metal + O. Reagem com água formando "
                "ácido (SO₃ + H₂O → H₂SO₄).\n"
                "- Anfóteros: reagem com ácido e base (Al₂O₃, ZnO).\n"
                "- Neutros: não reagem com água (CO, NO, N₂O).\n"
                "- Peróxidos: com O₂²⁻ (H₂O₂, Na₂O₂)."
            ),
            "exemplo": (
                "O CO₂ é um óxido ácido essencial para o equilíbrio "
                "ácido-base do sangue. Dissolve-se formando H₂CO₃ "
                "(ácido carbônico), que se dissocia em H+ e HCO₃-. "
                "O sistema tampão bicarbonato mantém o pH do sangue "
                "entre 7,35 e 7,45. Alterações causam acidose (pH<7,35) "
                "ou alcalose (pH>7,45), ambas graves."
            ),
        },
    ],
    "resumo": (
        "- Ácidos: liberam H+ em água. Hidrácidos (sem O) e oxiácidos (com O).\n"
        "- Bases: liberam OH- em água. Fortes (NaOH, KOH) e fracas (NH₄OH).\n"
        "- Sais: ácido + base → sal + água (neutralização). Neutros, ácidos, básicos, duplos.\n"
        "- Óxidos: binários com O. Básicos (metal), ácidos (não-metal), anfóteros, neutros, peróxidos.\n"
        "- Arrhenius: H+/OH-. Brønsted: doador/receptor de H+. Lewis: par de elétrons.\n"
        "- Neutralização: ácido + base → sal + água."
    ),
    "dicas": [
        "Ácidos fortes: HCl, HNO₃, H₂SO₄. Bases fortes: NaOH, KOH, Ca(OH)₂.",
        "Hidrácidos terminam em 'ídrico'. Oxiácidos em 'ico' (alto Nox) ou 'oso' (baixo).",
        "Sais: ânion + cátion. Nome: [ânion] de [cátion com oso/ico].",
        "Óxidos básicos: metal + O. Ácidos: não-metal + O.",
        "Peróxidos têm O₂²⁻ (H₂O₂, Na₂O₂). Diferente de óxidos comuns.",
        "Neutralização: ácido + base → sal + água. Ex.: HCl + NaOH → NaCl + H₂O.",
    ],
    "pegadinhas": [
        "Achar que H₂O é só óxido: é óxido neutro, mas também pode ser base ou ácido fraco.",
        "Confundir ácido forte com ácido concentrado: forte = ionização completa; concentrado = muita quantidade.",
        "Esquecer que NH₄OH é base fraca (não é hidróxido metálico).",
        "Achar que CO é óxido ácido: é neutro, não reage com água.",
        "Confundir oso/ico: oso = Nox menor, ico = Nox maior.",
        "Esquecer que peróxidos (H₂O₂) são diferentes de óxidos comuns.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "SHRIVER, D. F.; ATKINS, P. W. Química Inorgânica. 4. ed. Porto Alegre: Bookman, 2008.",
    ],
}

IMG_FUNCOES = [
    {"file": "br_qui6_acidos.jpg",
     "caption": "Ácidos: ionizam em água liberando H+",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/acidos/"},
    {"file": "br_qui6_oxidos.jpg",
     "caption": "Óxidos: compostos binários com oxigênio",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/oxidos/"},
    {"file": "br_qui11_ph.jpg",
     "caption": "Escala de pH: ácidos (pH<7), neutros (7), bases (pH>7)",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/equilibrio-quimico/"},
]

# ============================================================
# 2.7 Cálculos Químicos
# ============================================================
CALCULOS_QUIMICOS = {
    "titulo": "Cálculos Químicos",
    "disciplina": "Química",
    "topico": "Cálculos Químicos",
    "subtopico": "Mol, Avogadro, Fórmulas, Leis Ponderais e Estequiometria",
    "introducao": (
        "Os cálculos químicos permitem quantificar as reações: "
        "quantos reagentes são necessários, quanto produto se forma, "
        "qual o rendimento. O conceito central é o mol — a unidade "
        "de quantidade de matéria."
    ),
    "secoes": [
        {
            "titulo": "1. Mol e Número de Avogadro",
            "conteudo": (
                "MOL: unidade de quantidade de matéria. 1 mol contém "
                "6,02 × 10²³ entidades (átomos, moléculas, íons, etc.).\n\n"
                "NÚMERO DE AVOGADRO: 6,02 × 10²³. Corresponde ao número "
                "de átomos em exatamente 12g de carbono-12.\n\n"
                "MASSA MOLAR: massa de 1 mol de uma substância, em "
                "gramas. Numericamente igual à massa atômica/molecular "
                "em uma. Ex.: H₂O = 18 g/mol; NaCl = 58,5 g/mol; "
                "C₆H₁₂O₆ = 180 g/mol.\n\n"
                "VOLUME MOLAR: 1 mol de gás nas CNTP (0°C, 1 atm) "
                "ocupa 22,4 L. Nas CTPS (25°C, 1 atm), 24,5 L.\n\n"
                "FÓRMULAS:\n"
                "- n = m/M (n = número de mols, m = massa, M = massa molar)\n"
                "- n = N/Na (N = número de entidades, Na = 6,02×10²³)\n"
                "- n = V/Vm (V = volume do gás, Vm = volume molar)"
            ),
            "exemplo": (
                "Para produzir 180g de glicose (C₆H₁₂O₆), precisamos "
                "de 1 mol. Cada molécula tem 6 átomos de carbono, "
                "então 1 mol contém 6 × 6,02 × 10²³ átomos de C. "
                "Em medicina, a glicemia é medida em mg/dL, mas para "
                "cálculos bioquímicos usa-se mmol/L. A conversão: "
                "180 mg/dL de glicose = 10 mmol/L."
            ),
        },
        {
            "titulo": "2. Fórmulas Químicas e Leis Ponderais",
            "conteudo": (
                "FÓRMULA MÍNIMA (EMPÍRICA): menor proporção inteira "
                "entre os átomos. Ex.: CH₂O (glicose).\n\n"
                "FÓRMULA MOLECULAR: proporção real. Ex.: C₆H₁₂O₆ "
                "(glicose = 6× a fórmula mínima).\n\n"
                "LEIS PONDERAIS:\n"
                "- Lavoisier (conservação das massas): massa reagentes "
                "= massa produtos.\n"
                "- Proust (proporções definidas): um composto tem "
                "sempre a mesma proporção de elementos.\n"
                "- Dalton (proporções múltiplas): quando dois "
                "elementos formam mais de um composto, as massas de "
                "um que se combinam com massa fixa do outro estão "
                "em razão de números pequenos inteiros.\n\n"
                "CÁLCULO DE FÓRMULA:\n"
                "1. Converter % em massa;\n"
                "2. Converter massa em mol (dividir pela massa atômica);\n"
                "3. Dividir pelo menor valor para obter a proporção;\n"
                "4. Multiplicar para inteiros se necessário;\n"
                "5. Para fórmula molecular, usar massa molar conhecida."
            ),
            "exemplo": (
                "Um composto tem 40% C, 6,7% H e 53,3% O, com massa "
                "molar 180 g/mol. Convertendo: C=3,33mol, H=6,7mol, "
                "O=3,33mol. Dividindo por 3,33: CH₂O (fórmula mínima). "
                "Massa da fórmula mínima = 30. 180/30 = 6. Fórmula "
                "molecular: C₆H₁₂O₆ (glicose)."
            ),
        },
        {
            "titulo": "3. Estequiometria",
            "conteudo": (
                "ESTEQUIOMETRIA: cálculo das quantidades de reagentes "
                "e produtos em uma reação química, usando a equação "
                "balanceada.\n\n"
                "PASSOS:\n"
                "1. Escrever a equação balanceada;\n"
                "2. Converter as quantidades dadas em mol;\n"
                "3. Usar a proporção estequiométrica (coeficientes);\n"
                "4. Converter mol do produto para a unidade pedida.\n\n"
                "RENDIMENTO: nem toda reação é 100% eficiente.\n"
                "- Rendimento real = (massa obtida / massa teórica) × 100\n"
                "- Reagente limitante: aquele que se esgota primeiro, "
                "limitando a quantidade de produto.\n"
                "- Reagente em excesso: sobra após a reação.\n\n"
                "PUREZA: se o reagente não é puro, usar apenas a massa "
                "da substância ativa. massa pura = massa total × %pureza/100."
            ),
            "exemplo": (
                "Na produção de amônia (Haber-Bosch): N₂ + 3H₂ → 2NH₃. "
                "Para 28g de N₂ (1 mol) com H₂ em excesso, formam-se "
                "2 mol de NH₃ = 34g. Mas o rendimento industrial é "
                "cerca de 15%. A amônia é base da produção de "
                "fertilizantes e de explosivos. Sem estequiometria, "
                "seria impossível dimensionar fábricas químicas."
            ),
        },
    ],
    "resumo": (
        "- 1 mol = 6,02×10²³ entidades (Avogadro). Massa molar em g/mol.\n"
        "- n = m/M = N/Na = V/Vm. Volume molar: 22,4 L (CNTP).\n"
        "- Fórmula mínima: menor proporção. Molecular: proporção real.\n"
        "- Lavoisier: massas se conservam. Proust: proporções definidas.\n"
        "- Estequiometria: usar coeficientes da equação balanceada.\n"
        "- Reagente limitante: esgota primeiro. Rendimento = real/teórico × 100."
    ),
    "dicas": [
        "Sempre converter para mol antes de usar proporções estequiométricas.",
        "Reagente limitante: comparar mol disponível / coeficiente. Menor = limitante.",
        "Volume molar: 22,4 L nas CNTP (0°C, 1 atm), 24,5 L nas CTPS (25°C).",
        "Para fórmula molecular: dividir massa molar real pela massa da fórmula mínima.",
        "Rendimento nunca passa de 100%.",
        "Pureza: usar apenas a massa da substância ativa nos cálculos.",
    ],
    "pegadinhas": [
        "Esquecer de balancear a equação antes de calcular estequiometria.",
        "Confundir massa molar com massa molecular: numericamente iguais, mas unidades diferentes.",
        "Achar que rendimento > 100% é possível: não é, indica erro.",
        "Usar massa direta sem converter para mol nas proporções.",
        "Esquecer de considerar pureza do reagente.",
        "Confundir reagente limitante com o de menor massa: limitante é o que esgota primeiro.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "BRADY, J. E.; HUMISTON, G. E. Química Geral. 2. ed. Rio de Janeiro: LTC, 1986.",
    ],
}

IMG_CALCULOS = [
    {"file": "br_qui7_estequio.jpg",
     "caption": "Estequiometria: cálculos de quantidade em reações químicas",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/estequiometria/"},
    {"file": "br_qui7_molaridade.jpg",
     "caption": "Molaridade: concentração em mol/L",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/mol/"},
    {"file": "br_qui7_leis.jpg",
     "caption": "Leis ponderais: Lavoisier, Proust e Dalton",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/estequiometria/"},
]

# ============================================================
# 2.8 Gases
# ============================================================
GASES = {
    "titulo": "Gases",
    "disciplina": "Química",
    "topico": "Gases",
    "subtopico": "Propriedades, Leis Empíricas, Equação de Gás Ideal e Teoria Cinética",
    "introducao": (
        "O estudo dos gases é fundamental para a Química e para a "
        "Fisiologia. Os gases não têm forma ou volume próprios, "
        "expandem-se livremente e são compressíveis. As leis dos "
        "gases descrevem como pressão, volume e temperatura se "
        "relacionam."
    ),
    "secoes": [
        {
            "titulo": "1. Propriedades e Leis Empíricas dos Gases",
            "conteudo": (
                "PROPRIEDADES DOS GASES:\n"
                "- Forma e volume variáveis;\n"
                "- Compressíveis e expansíveis;\n"
                "- Baixa densidade;\n"
                "- Pressão decorrente de colisões das moléculas com "
                "as paredes.\n\n"
                "LEIS EMPÍRICAS:\n"
                "- Boyle (T constante): P₁V₁ = P₂V₂. Pressão e volume "
                "são inversamente proporcionais.\n"
                "- Charles (P constante): V₁/T₁ = V₂/T₂. Volume e "
                "temperatura (K) são diretamente proporcionais.\n"
                "- Gay-Lussac (V constante): P₁/T₁ = P₂/T₂. Pressão "
                "e temperatura são diretamente proporcionais.\n"
                "- Lei de Charles-Gay-Lussac: V = V₀(1 + α·ΔT), "
                "onde α = 1/273.\n\n"
                "TEMPERATURA EM KELVIN: T(K) = T(°C) + 273. Nunca "
                "usar Celsius nas leis dos gases."
            ),
            "exemplo": (
                "A respiração humana usa a lei de Boyle. Ao inspirar, "
                "o diafragma desce, aumentando o volume dos pulmões. "
                "A pressão interna diminui abaixo da atmosférica, e "
                "o ar flui para dentro. Ao expirar, o volume diminui, "
                "a pressão aumenta e o ar sai. Tudo por P·V = "
                "constante (T praticamente constante)."
            ),
        },
        {
            "titulo": "2. Equação dos Gases Ideais e Misturas",
            "conteudo": (
                "EQUAÇÃO DE CLAPEYRON: PV = nRT\n"
                "- P = pressão (atm)\n"
                "- V = volume (L)\n"
                "- n = número de mols\n"
                "- R = constante universal (0,082 atm·L/mol·K)\n"
                "- T = temperatura (K)\n\n"
                "PRINCÍPIO DE AVOGADRO: volumes iguais de gases "
                "diferentes, nas mesmas condições de P e T, contêm "
                "o mesmo número de moléculas.\n\n"
                "MISTURA DE GASES:\n"
                "- Lei de Dalton: P_total = P₁ + P₂ + ... (soma das "
                "pressões parciais).\n"
                "- Pressão parcial: P_i = x_i × P_total, onde x_i é "
                "a fração molar do gás i.\n\n"
                "GASES REAIS: desviam do ideal em altas pressões e "
                "baixas temperações. Equação de van der Waals "
                "corrige: (P + a·n²/V²)(V - nb) = nRT."
            ),
            "exemplo": (
                "O ar atmosférico é uma mistura: N₂ (78%), O₂ (21%), "
                "Ar (0,93%), CO₂ (0,04%). A pressão parcial de O₂ "
                "ao nível do mar = 0,21 × 760 = 160 mmHg. Nas grandes "
                "altitudes, a pressão total diminui, e a pressão "
                "parcial de O₂ também — por que ocorre hipóxia. "
                "Oxigênio suplementar aumenta a fração de O₂ e "
                "compensa. Em anestesia, a pressão parcial de cada "
                "gás determina a absorção nos pulmões."
            ),
        },
        {
            "titulo": "3. Teoria Cinética dos Gases",
            "conteudo": (
                "POSTULADOS:\n"
                "- As moléculas são pontos materiais (volume "
                "desprezível);\n"
                "- Não há forças intermoleculares (exceto em colisões);\n"
                "- Movem-se em linha reta, aleatoriamente;\n"
                "- Colisões são elásticas (energia conservada);\n"
                "- Energia cinética média é proporcional à temperatura "
                "(K).\n\n"
                "EQUAÇÃO: Ec = (3/2)·k·T, onde k = constante de "
                "Boltzmann.\n\n"
                "VELOCIDADE: as moléculas têm distribuição de "
                "velocidades (Maxwell-Boltzmann). A velocidade "
                "quadrática média aumenta com a temperatura e "
                "diminui com a massa molar.\n\n"
                "DIFUSÃO E EFUSÃO: gases mais leves se difundem mais "
                "rápido (lei de Graham: taxa ∝ 1/√M)."
            ),
            "exemplo": (
                "A difusão de gases nos alvéolos segue a lei de "
                "Graham. O O₂ (M=32) se difunde mais devagar que o "
                "CO₂ (M=44), mas a diferença é compensada pela "
                "espessura da membrana alveolar e pelo gradiente de "
                "pressão. O CO₂ é 20× mais solúvel em plasma que o "
                "O₂, o que compensa sua difusão mais lenta."
            ),
        },
    ],
    "resumo": (
        "- Boyle: P·V = const (T fixa). Charles: V/T = const (P fixa). Gay-Lussac: P/T = const (V fixa).\n"
        "- Equação geral: PV = nRT. R = 0,082 atm·L/mol·K. Temperatura em Kelvin.\n"
        "- Dalton: P_total = Σ P_i. Pressão parcial = fração molar × P_total.\n"
        "- Teoria cinética: moléculas pontuais, colisões elásticas, Ec ∝ T.\n"
        "- Lei de Graham: difusão ∝ 1/√M. Gases leves se difundem mais rápido.\n"
        "- Gases reais desviam em alta P e baixa T (van der Waals)."
    ),
    "dicas": [
        "Sempre converter temperatura para Kelvin: T(K) = T(°C) + 273.",
        "Boyle: P e V inversos. Charles: V e T diretos. Gay-Lussac: P e T diretos.",
        "Pressão parcial = fração molar × pressão total.",
        "Equação: PV = nRT. R = 0,082 (atm·L/mol·K) ou 8,31 (J/mol·K).",
        "Gás ideal: volume próprio desprezível, sem forças intermoleculares.",
        "Difusão mais rápida: gases de menor massa molar (lei de Graham).",
    ],
    "pegadinhas": [
        "Usar Celsius nas leis dos gases: sempre Kelvin.",
        "Confundir pressão parcial com pressão total.",
        "Esquecer que P e V são inversos (Boyle), não diretos.",
        "Achar que gases reais sempre seguem PV=nRT: desviam em alta P/baixa T.",
        "Confundir R em diferentes unidades: 0,082 (atm·L) ≠ 8,31 (J).",
        "Esquecer que temperatura é proporcional à energia cinética MÉDIA, não à velocidade.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "CASTELLAN, G. W. Fundamentos de Físico-Química. 4. ed. Rio de Janeiro: LTC, 1996.",
    ],
}

IMG_GASES = [
    {"file": "br_qui8_leis.jpg",
     "caption": "Leis dos gases: Boyle, Charles e Gay-Lussac",
     "source": "Brasil Escola", "source_url": "https://brasilescola.uol.com.br/quimica/lei-dos-gases.htm"},
]

# ============================================================
# 2.9 Soluções
# ============================================================
SOLUCOES = {
    "titulo": "Soluções",
    "disciplina": "Química",
    "topico": "Soluções",
    "subtopico": "Conceitos, Tipos, Concentração, Diluição e Misturas",
    "introducao": (
        "Soluções são misturas homogêneas de duas ou mais substâncias. "
        "O estudo de soluções é essencial para a Química, a "
        "Biologia e a Medicina — quase todas as reações ocorrem em "
        "solução, e o corpo humano é majoritariamente composto por "
        "soluções aquosas."
    ),
    "secoes": [
        {
            "titulo": "1. Conceitos e Tipos de Solução",
            "conteudo": (
                "SOLUÇÃO: mistura homogênea de soluto (dissolvido) e "
                "solvente (dissolve). O solvente geralmente está em "
                "maior quantidade.\n\n"
                "CLASSIFICAÇÃO quanto ao estado físico:\n"
                "- Sólidas: ligas metálicas (bronze, aço).\n"
                "- Líquidas: água salgada, álcool medicinal.\n"
                "- Gasosas: ar atmosférico.\n\n"
                "CLASSIFICAÇÃO quanto à saturação:\n"
                "- Insaturada: contém menos soluto que o máximo.\n"
                "- Saturada: contém o máximo de soluto. Há equilíbrio "
                "entre dissolver e cristalizar.\n"
                "- Supersaturada: contém mais soluto que o máximo "
                "(instável, cristaliza com perturbação).\n\n"
                "SOLUBILIDADE: máxima quantidade de soluto que se "
                "dissolve em uma quantidade de solvente a uma "
                "temperatura. Depende da temperatura, pressão (para "
                "gases) e natureza das substâncias (polar dissolve "
                "polar)."
            ),
            "exemplo": (
                "O soro fisiológico é uma solução saturada de NaCl "
                "0,9% (m/V) — isotônica com o plasma. Soluções "
                "hipertônicas (mais concentradas) desidratam células "
                "(crenação das hemácias). Hipotônicas causam "
                "edema celular (hemólise). Por isso a concentração "
                "exata é crítica em medicina."
            ),
        },
        {
            "titulo": "2. Unidades de Concentração",
            "conteudo": (
                "PRINCIPAIS UNIDADES:\n\n"
                "- Concentração comum (g/L): C = m₁/V, onde m₁ = "
                "massa de soluto (g), V = volume (L).\n\n"
                "- Título (% m/m): T = m₁/(m₁+m₂), onde m₂ = massa "
                "de solvente. Pode ser em %.\n\n"
                "- % m/V: massa de soluto (g) por volume de solução "
                "(mL) × 100.\n\n"
                "- Molaridade (mol/L): M = n₁/V, onde n₁ = mol de "
                "soluto, V = volume (L).\n\n"
                "- Molalidade (mol/kg): W = n₁/m₂, onde m₂ = massa "
                "de solvente (kg). Não varia com temperatura.\n\n"
                "- Fração molar: x₁ = n₁/(n₁+n₂). Adimensional.\n\n"
                "- Normalidade (eq-g/L): N = n_eq/V. Usada em "
                "volumetria.\n\n"
                "- ppm e ppb: partes por milhão/bilhão. Para "
                "concentrações muito baixas (poluentes)."
            ),
            "exemplo": (
                "A glicemia de jejum normal é 70-99 mg/dL. Para "
                "converter em molaridade: 90 mg/dL = 0,9 g/L. Massa "
                "molar da glicose = 180 g/mol. M = 0,9/180 = 0,005 "
                "mol/L = 5 mmol/L. Valores acima de 126 mg/dL "
                "(7 mmol/L) indicam diabetes. A conversão entre "
                "unidades é rotina em laboratórios clínicos."
            ),
        },
        {
            "titulo": "3. Diluição e Misturas de Soluções",
            "conteudo": (
                "DILUIÇÃO: adicionar solvente a uma solução. A massa "
                "de soluto não muda.\n"
                "Fórmula: C₁V₁ = C₂V₂ (inicial = final, em qualquer "
                "unidade de concentração).\n\n"
                "MISTURA DE SOLUÇÕES MESMO SOLUTO:\n"
                "- Somar massa de soluto: m_total = m₁ + m₂.\n"
                "- Somar volumes (aproximação): V_total = V₁ + V₂.\n"
                "- Nova concentração: C = m_total/V_total.\n\n"
                "MISTURA DE SOLUÇÕES DE SOLUTOS DIFERENTES (sem "
                "reação): cada soluto mantém sua concentração, "
                "reduzida pelo aumento de volume.\n\n"
                "MISTURA COM REAÇÃO (neutralização): ácido + base "
                "→ sal + água. Determinar o reagente limitante, "
                "calcular excesso e pH resultante."
            ),
            "exemplo": (
                "Para preparar 500 mL de NaCl 0,9% a partir de uma "
                "solução 10%: C₁V₁ = C₂V₂ → 10·V₁ = 0,9·500 → "
                "V₁ = 45 mL. Medir 45 mL da solução 10% e completar "
                "com água até 500 mL. Essa diluição é feita em "
                "farmácias e hospitais para preparar soluções "
                "isotônicas."
            ),
        },
    ],
    "resumo": (
        "- Solução = soluto + solvente, mistura homogênea.\n"
        "- Saturação: insaturada, saturada, supersaturada.\n"
        "- Concentrações: g/L, % m/m, % m/V, mol/L (molaridade), mol/kg (molalidade), fração molar.\n"
        "- Diluição: C₁V₁ = C₂V₂. Massa de soluto não muda.\n"
        "- Mistura mesmo soluto: somar massas e volumes.\n"
        "- Mistura com reação: determinar limitante, calcular excesso e pH."
    ),
    "dicas": [
        "Molaridade (mol/L) varia com temperatura; molalidade (mol/kg) não varia.",
        "Diluição: C₁V₁ = C₂V₂. A massa de soluto é constante.",
        "ppm = mg/L para soluções aquosas diluídas.",
        "Polar dissolve polar; apolar dissolve apolar (semelhante dissolve semelhante).",
        "Mistura de soluções mesmo soluto: somar massas de soluto e volumes.",
        "Neutralização: ácido + base → sal + água. Calcular excesso para pH.",
    ],
    "pegadinhas": [
        "Confundir molaridade com molalidade: molaridade usa volume (L), molalidade usa massa (kg).",
        "Esquecer que diluição não altera a massa de soluto, só a concentração.",
        "Somar volumes de solventes diferentes (ex.: água + álcool) sem considerar contração.",
        "Achar que mistura de soluções sempre reage: só reage se houver reação química.",
        "Confundir % m/m com % m/V: m/m usa massa total, m/V usa volume.",
        "Esquecer de converter unidades antes de misturar (ex.: g/L com mol/L).",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "SKOOG, D. A. et al. Fundamentos de Química Analítica. 8. ed. São Paulo: Cengage, 2006.",
    ],
}

IMG_SOLUCOES = [
    {"file": "br_qui9_diluicao.jpg",
     "caption": "Diluição e misturas de soluções",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/separacao-de-misturas/"},
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (TRANSFORMACOES, "QU_TRANSFORMACOES_QUIMICAS.pdf", IMG_TRANSFORMACOES, "Química — Transformações"),
        (FUNCOES_INORGANICAS, "QU_FUNCOES_INORGANICAS.pdf", IMG_FUNCOES, "Química — Funções Inorgânicas"),
        (CALCULOS_QUIMICOS, "QU_CALCULOS_QUIMICOS.pdf", IMG_CALCULOS, "Química — Cálculos Químicos"),
        (GASES, "QU_GASES.pdf", IMG_GASES, "Química — Gases"),
        (SOLUCOES, "QU_SOLUCOES.pdf", IMG_SOLUCOES, "Química — Soluções"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluído: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
