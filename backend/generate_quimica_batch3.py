"""Gera PDFs de Química — batch 3 (tópicos 10-13)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 2.10 Termoquímica
# ============================================================
TERMOQUIMICA = {
    "titulo": "Termoquímica",
    "disciplina": "Química",
    "topico": "Termoquímica",
    "subtopico": "Calor, Entalpia, Reações Exotérmicas/Endotérmicas e Lei de Hess",
    "introducao": (
        "A Termoquímica estuda as trocas de calor associadas às "
        "reações químicas. O calor é uma forma de energia que flui "
        "do corpo de maior temperatura para o de menor temperatura. "
        "Compreender as trocas térmicas é essencial para entender "
        "processos industriais, biológicos e metabólicos."
    ),
    "secoes": [
        {
            "titulo": "1. Calor, Trabalho e Entalpia",
            "conteudo": (
                "CALOR (Q): energia em trânsito devido à diferença de "
                "temperatura. Medido em joules (J) ou calorias (cal). "
                "1 cal = 4,184 J.\n\n"
                "TRABALHO (W): energia transferida por forças. Em "
                "reações com gases, W = -P·ΔV.\n\n"
                "ENERGIA INTERNA (U): soma de todas as energias de "
                "um sistema. Primeira lei: ΔU = Q + W.\n\n"
                "ENTALPIA (H): H = U + PV. Para reações a pressão "
                "constante, ΔH = Qp (calor trocado a pressão "
                "constante).\n\n"
                "RELAÇÃO:\n"
                "- Reação exotérmica: libera calor, ΔH < 0. "
                "Ex.: combustões, neutralização.\n"
                "- Reação endotérmica: absorve calor, ΔH > 0. "
                "Ex.: fotossíntese, decomposição do CaCO₃.\n\n"
                "EQUAÇÃO TERMOQUÍMICA: inclui o ΔH. Ex.: "
                "2H₂(g) + O₂(g) → 2H₂O(l) ΔH = -572 kJ (exotérmica)."
            ),
            "exemplo": (
                "A combustão da glicose (respiração celular) libera "
                "2870 kJ/mol: C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O, "
                "ΔH = -2870 kJ. Esse energia é capturada em ATP "
                "(cerca de 30 mol de ATP = ~30 kJ/mol cada). O "
                "rendimento é ~34%, o resto vira calor — que mantém "
                "a temperatura corporal em 36,5°C. Sem essa combustão "
                "exotérmica, não haveria vida nem calor corporal."
            ),
        },
        {
            "titulo": "2. Entalpia de Formação e Lei de Hess",
            "conteudo": (
                "ENTALPIA DE FORMAÇÃO (ΔHf): variação de entalpia "
                "para formar 1 mol de composto a partir de elementos "
                "no estado padrão (25°C, 1 atm). Elementos puros "
                "têm ΔHf = 0 por definição.\n\n"
                "ENTALPIA DE REAÇÃO: ΔH = Σ ΔHf(produtos) - "
                "Σ ΔHf(reagentes).\n\n"
                "LEI DE HESS: o ΔH de uma reação é o mesmo, "
                "independentemente do caminho. Permite calcular "
                "ΔH de reações difíceis de medir diretamente, "
                "somando reações intermediárias conhecidas.\n\n"
                "EXEMPLO: C + O₂ → CO₂ ΔH = -394 kJ\n"
                "C + 1/2 O₂ → CO ΔH = -111 kJ\n"
                "CO + 1/2 O₂ → CO₂ ΔH = -283 kJ\n"
                "A soma das duas últimas = primeira, confirmando Hess."
            ),
            "exemplo": (
                "A lei de Hess é usada para calcular a energia de "
                "combustão de alimentos. Por exemplo, a combustão "
                "da gordura libera ~9 kcal/g, enquanto carboidratos "
                "e proteínas liberam ~4 kcal/g. Esses valores são "
                "obtidos por calorimetria e usados para calcular "
                "dietas. Em medicina, conhecer o metabolismo "
                "energético ajuda a planejar dietas para pacientes "
                "com obesidade, desnutrição ou diabetes."
            ),
        },
        {
            "titulo": "3. Entropia e Energia Livre de Gibbs",
            "conteudo": (
                "ENTROPIA (S): medida do grau de desordem de um "
                "sistema. Segunda lei: em processos espontâneos, a "
                "entropia do universo aumenta (ΔS_universo > 0).\n\n"
                "ENERGIA LIVRE DE GIBBS (G): G = H - TS. Combina "
                "entalpia e entropia. Em processo espontâneo a T e P "
                "constantes: ΔG < 0.\n\n"
                "- ΔG < 0: espontâneo (exergônico).\n"
                "- ΔG > 0: não espontâneo (endergônico).\n"
                "- ΔG = 0: equilíbrio.\n\n"
                "EQUAÇÃO: ΔG = ΔH - T·ΔS.\n\n"
                "TERMODINÂMICA NAS REAÇÕES:\n"
                "- Exotérmico + aumenta entropia: sempre espontâneo.\n"
                "- Endotérmico + diminui entropia: nunca espontâneo.\n"
                "- Exotérmico + diminui entropia: depende de T.\n"
                "- Endotérmico + aumenta entropia: depende de T."
            ),
            "exemplo": (
                "O ATP hidrolisa espontaneamente: ATP + H₂O → ADP + "
                "Pi, ΔG = -30,5 kJ/mol. Essa energia livre negativa "
                "é usada para impulsionar reações endergônicas no "
                "corpo, como contração muscular, transporte ativo e "
                "síntese de proteínas. Sem ATP, a vida para em "
                "segundos. A termodinâmica de Gibbs explica por que "
                "o ATP é a 'moeda energética' das células."
            ),
        },
    ],
    "resumo": (
        "- Exotérmica: ΔH < 0 (libera calor). Endotérmica: ΔH > 0 (absorve).\n"
        "- Entalpia: H = U + PV. A P constante, ΔH = Qp.\n"
        "- ΔH reação = Σ ΔHf(produtos) - Σ ΔHf(reagentes).\n"
        "- Lei de Hess: ΔH independe do caminho.\n"
        "- Entropia: desordem. Segunda lei: ΔS universo > 0.\n"
        "- Gibbs: ΔG = ΔH - TΔS. Espontâneo: ΔG < 0."
    ),
    "dicas": [
        "Exotérmica = libera calor (ΔH negativo). Endotérmica = absorve (ΔH positivo).",
        "Elementos no estado padrão têm ΔHf = 0.",
        "Lei de Hess: somar reações intermediárias para obter ΔH da reação desejada.",
        "ΔG < 0 = espontâneo. ΔG > 0 = não espontâneo. ΔG = 0 = equilíbrio.",
        "Combustão é sempre exotérmica. Fotossíntese é endotérmica.",
        "1 cal = 4,184 J. 1 kcal = 1 Caloria (nutricional).",
    ],
    "pegadinhas": [
        "Achar que reação exotérmica é sempre espontânea: depende de ΔG (H e S).",
        "Confundir ΔH positivo com exotérmico: positivo é endotérmico.",
        "Esquecer que ΔHf de elementos no estado padrão é zero.",
        "Achar que entropia sempre aumenta no sistema: pode diminuir no sistema, mas aumenta no universo.",
        "Confundir calor com temperatura: calor é energia em trânsito.",
        "Esquecer de multiplicar ΔHf pelo coeficiente estequiométrico.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "CASTELLAN, G. W. Fundamentos de Físico-Química. 4. ed. Rio de Janeiro: LTC, 1996.",
        "BALL, D. W. Físico-Química. São Paulo: Pioneira Thomson Learning, 2005.",
    ],
}

IMG_TERMOQUIMICA = [
    {"file": "br_qui10_endoexo.jpg",
     "caption": "Reações exotérmicas (liberam calor) e endotérmicas (absorvem calor)",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/termoquimica/"},
    {"file": "br_qui10_entalpia_form.jpg",
     "caption": "Entalpia de formação: energia para formar 1 mol de composto",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/entalpia/"},
    {"file": "br_qui10_hess.jpg",
     "caption": "Lei de Hess: o ΔH independe do caminho da reação",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/lei-de-hess/"},
]

# ============================================================
# 2.11 Cinética e Equilíbrio
# ============================================================
CINETICA_EQUILIBRIO = {
    "titulo": "Cinética e Equilíbrio Químico",
    "disciplina": "Química",
    "topico": "Cinética e Equilíbrio",
    "subtopico": "Velocidade das Reações, Equilíbrio, Constante e Le Chatelier",
    "introducao": (
        "A cinética química estuda a velocidade das reações e os "
        "fatores que a influenciam. O equilíbrio químico é o estado "
        "em que as velocidades direta e inversa se igualam. Estes "
        "conceitos são essenciais para entender processos "
        "industriais, biológicos e ambientais."
    ),
    "secoes": [
        {
            "titulo": "1. Cinética Química",
            "conteudo": (
                "VELOCIDADE DE REAÇÃO: variação da concentração por "
                "tempo. v = -Δ[reagente]/Δt = +Δ[produto]/Δt.\n\n"
                "FATORES QUE INFLUENCIAM A VELOCIDADE:\n"
                "- Natureza dos reagentes: substâncias iônicas reagem "
                "rápido; covalentes, mais devagar.\n"
                "- Concentração: maior concentração → mais colisões → "
                "maior velocidade (Lei da Ação das Massas).\n"
                "- Temperatura: cada 10°C aumenta ~2-3× a velocidade.\n"
                "- Superfície de contato: maior área → maior velocidade.\n"
                "- Catalisador: reduz energia de ativação, não é "
                "consumido, não altera ΔH.\n"
                "- Pressão (gases): maior pressão = maior concentração.\n\n"
                "TEORIA DAS COLISÕES: reação ocorre se houver colisão "
                "efetiva (energia suficiente + orientação correta).\n\n"
                "ENERGIA DE ATIVAÇÃO: energia mínima para iniciar a "
                "reação. Catalisador reduz essa energia.\n\n"
                "COMPLEXO ATIVADO: estado de transição entre "
                "reagentes e produtos, no topo da barreira."
            ),
            "exemplo": (
                "As enzimas são catalisadores biológicos. A triosina "
                "fosfatase acelera uma reação 10¹² vezes. Sem enzimas, "
                "a digestão levaria anos. A pepsina do estômago só "
                "funciona em pH ácido (1-2), por isso inibidores de "
                "bombas de prótons reduzem a digestão proteica. "
                "Catalisadores industriais (Fe na síntese de amônia, "
                "Pt em catalisadores automotivos) economizam energia "
                "e reduzem poluição."
            ),
        },
        {
            "titulo": "2. Equilíbrio Químico",
            "conteudo": (
                "EQUILÍBRIO: estado em que as velocidades direta e "
                "inversa são iguais. As concentrações não mudam, mas "
                "a reação não para — é dinâmico.\n\n"
                "REPRESENTAÇÃO: aA + bB ⇌ cC + dD\n\n"
                "CONSTANTE DE EQUILÍBRIO (Kc):\n"
                "Kc = [C]^c · [D]^d / ([A]^a · [B]^b)\n\n"
                "Kp (para gases, em pressões): Kp = Kc·(RT)^Δn, onde "
                "Δn = mol gasosos produtos - reagentes.\n\n"
                "INTERPRETAÇÃO:\n"
                "- K grande (>1): favorece produtos.\n"
                "- K pequeno (<1): favorece reagentes.\n"
                "- K = 1: equilíbrio equilibrado.\n\n"
                "PRODUTO IÔNICO DA ÁGUA: Kw = [H+][OH-] = 10⁻¹⁴ a 25°C.\n"
                "pH = -log[H+]. pH + pOH = 14. pH 7 = neutro."
            ),
            "exemplo": (
                "O equilíbrio do oxigênio com a hemoglobina é "
                "reversível: Hb + O₂ ⇌ HbO₂. Nos pulmões (alta "
                "concentração de O₂), o equilíbrio desloca para a "
                "direita, formando HbO₂. Nos tecidos (baixa O₂, "
                "alta CO₂), desloca para a esquerda, liberando O₂. "
                "O CO compete com O₂ (afetando K), causando "
                "intoxicação por monóxido de carbono."
            ),
        },
        {
            "titulo": "3. Deslocamento do Equilíbrio (Le Chatelier)",
            "conteudo": (
                "PRINCÍPIO DE LE CHATELIER: quando um sistema em "
                "equilíbrio sofre perturbação, ele se desloca para "
                "minimizar a perturbação.\n\n"
                "FATORES:\n"
                "- Concentração: adicionar reagente → desloca para "
                "produtos. Remover produto → desloca para produtos.\n"
                "- Temperatura: aumentar T desloca para o lado "
                "endotérmico (absorve calor). Diminuir T desloca para "
                "o exotérmico.\n"
                "- Pressão (gases): aumentar P desloca para o lado "
                "de menor volume (menos mol gasosos).\n"
                "- Catalisador: NÃO desloca o equilíbrio, apenas "
                "acelera a chegada.\n\n"
                "APLICAÇÕES INDUSTRIAIS: processo Haber (amônia): "
                "N₂ + 3H₂ ⇌ 2NH₃, ΔH < 0. Alta pressão e baixa "
                "temperatura favorecem NH₃, mas baixa T reduz "
                "velocidade — por isso usa catalisador de Fe e T "
                "moderada (450°C)."
            ),
            "exemplo": (
                "A altitude afeta o equilíbrio Hb-O₂. Em grandes "
                "altitudes, a pressão parcial de O₂ é menor, "
                "deslocando o equilíbrio para menos HbO₂. O corpo "
                "compensa produzindo mais hemoglobina (adaptação). "
                "Atletas treinam em altitude para aumentar a "
                "concentração de Hb e melhorar o desempenho. Isso "
                "é Le Chatelier no corpo humano!"
            ),
        },
    ],
    "resumo": (
        "- Velocidade: v = Δconcentração/Δt. Fatores: concentração, T, catalisador, área.\n"
        "- Energia de ativação: barreira. Catalisador reduz, não altera ΔH.\n"
        "- Equilíbrio: velocidades direta = inversa. Dinâmico.\n"
        "- Kc = [produtos]/[reagentes] com coeficientes como expoentes.\n"
        "- Le Chatelier: perturbação → desloca para minimizar.\n"
        "- pH = -log[H+]. pH 7 neutro. Kw = 10⁻¹⁴."
    ),
    "dicas": [
        "Catalisador NÃO desloca equilíbrio, só acelera a chegada.",
        "Aumentar T desloca para o lado ENDOTÉRMICO.",
        "Aumentar P desloca para o lado de MENOS mol gasosos.",
        "Adicionar reagente desloca para produtos; remover produto também.",
        "K > 1 favorece produtos; K < 1 favorece reagentes.",
        "pH + pOH = 14 (a 25°C). pH = -log[H+].",
    ],
    "pegadinhas": [
        "Achar que catalisador desloca o equilíbrio: não desloca.",
        "Confundir Kc com velocidade: Kc não muda com catalisador, só com T.",
        "Esquecer que aumentar T desloca para o lado endotérmico (absorve calor).",
        "Achar que pressão afeta equilíbrio sem gases: só afeta se houver gases.",
        "Confundir Kc com Kp: Kc usa concentrações, Kp usa pressões.",
        "Esquecer que equilíbrio é dinâmico: as reações não param, apenas se igualam.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "CASTELLAN, G. W. Fundamentos de Físico-Química. 4. ed. Rio de Janeiro: LTC, 1996.",
        "BALL, D. W. Físico-Química. São Paulo: Pioneira Thomson Learning, 2005.",
    ],
}

IMG_CINETICA = [
    {"file": "br_qui11_velocidade.jpg",
     "caption": "Velocidade das reações químicas e fatores influentes",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/cinetica-quimica/"},
    {"file": "br_qui11_ativacao.jpg",
     "caption": "Energia de ativação e complexo ativado",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/cinetica-quimica/"},
    {"file": "br_qui11_grafico.jpg",
     "caption": "Equilíbrio químico: concentrações se estabilizam",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/equilibrio-quimico/"},
]

# ============================================================
# 2.12 Eletroquímica
# ============================================================
ELETROQUIMICA = {
    "titulo": "Eletroquímica",
    "disciplina": "Química",
    "topico": "Eletroquímica",
    "subtopico": "Oxirredução, Pilhas, Eletrólise e Potenciais",
    "introducao": (
        "A Eletroquímica estuda a relação entre reações químicas e "
        "eletricidade. As reações de oxirredução que envolvem "
        "transferência de elétrons podem gerar energia elétrica "
        "(pilhas) ou ser provocadas por corrente elétrica (eletrólise)."
    ),
    "secoes": [
        {
            "titulo": "1. Pilhas e Potenciais Padronizados",
            "conteudo": (
                "PILHA (célula galvânica): converte energia química em "
                "elétrica. Espontânea.\n\n"
                "ESTRUTURA:\n"
                "- Ânodo: eletrodo negativo, onde ocorre oxidação.\n"
                "- Cátodo: eletrodo positivo, onde ocorre redução.\n"
                "- Ponte salina: fecha o circuito, mantém neutralidade.\n"
                "- Eletrólito: solução com íons.\n\n"
                "REPRESENTAÇÃO: ânodo | eletrólito || eletrólito | cátodo.\n"
                "Ex.: Zn | Zn²⁺ || Cu²⁺ | Cu\n\n"
                "POTENCIAL PADRÃO (E°): potencial de redução medido "
                "em condições padrão (25°C, 1M, 1 atm). Tabela de "
                "potenciais. Quanto maior E°, mais tende a reduzir.\n\n"
                "DDP DA PILHA: ΔE = E°cátodo - E°ânodo. Para ser "
                "espontânea, ΔE > 0.\n\n"
                "EQUAÇÃO DE NERNST: ΔE = ΔE° - (0,059/n)·log Q, onde "
                "n = elétrons trocados, Q = quociente da reação."
            ),
            "exemplo": (
                "A pilha de Daniell (Zn|Zn²⁺||Cu²⁺|Cu) tem ΔE° = "
                "0,34 - (-0,76) = 1,10 V. Pilhas recarregáveis (Li-ion) "
                "alimentam celulares e marcapassos. O marcapasso "
                "cardíaco usa pilha de lítium, que dura anos. "
                "Sem eletroquímica, não haveria dispositivos médicos "
                "implantáveis."
            ),
        },
        {
            "titulo": "2. Eletrólise",
            "conteudo": (
                "ELETRÓLISE: processo NÃO espontâneo, em que corrente "
                "elétrica força uma reação redox. Converte energia "
                "elétrica em química.\n\n"
                "ELETRÓLISE ÍGNIA: eletrólito fundido (sem água). "
                "Ex.: NaCl fundido → Na (cátodo) + Cl₂ (ânodo).\n\n"
                "ELETRÓLISE EM SOLUÇÃO: a água pode competir. NaCl "
                "aquoso: no cátodo, H₂O reduz (forma H₂) em vez de "
                "Na+. No ânodo, Cl- oxida (forma Cl₂). Forma-se "
                "também NaOH na solução.\n\n"
                "LEIS DE FARADAY:\n"
                "1ª: massa depositada ∝ carga elétrica (Q = I·t).\n"
                "2ª: massas de diferentes substâncias ∝ massas "
                "equivalentes (M/n).\n\n"
                "APLICAÇÕES: galvanoplastia (cromagem, niquelagem), "
                "purificação de metais, produção de Na, Cl₂, NaOH, "
                "alumínio (processo Hall-Héroult)."
            ),
            "exemplo": (
                "A eletrólise é usada para produzir alumínio. A "
                "bauxita (Al₂O₃) é dissolvida em criolita fundida e "
                "eletrólise a 1000°C produz Al metálico. Esse processo "
                "consome muita energia — por que reciclar alumínio "
                "economiza 95% da energia. Em medicina, a eletrólise "
                "é usada para produzir H₂ e O₂ puros para "
                "equipamentos hospitalares."
            ),
        },
        {
            "titulo": "3. Corrosão e Proteção",
            "conteudo": (
                "CORROSÃO ELETROQUÍMICA: oxidação de metais por "
                "ambiente úmido. Ferrugem: Fe → Fe²⁺ → Fe₂O₃·nH₂O. "
                "É uma pilha espontânea onde o ferro é oxidado.\n\n"
                "PROTEÇÃO:\n"
                "- Pintura: isola o metal do ambiente.\n"
                "- Galvanização: revestir com zinco (Zn é oxidado "
                "primeiro, protegendo o Fe — proteção catódica).\n"
                "- Eletrodeposição: depositar metal resistente.\n"
                "- Ligas: aço inoxidável (Cr, Ni) forma camada "
                "protetora.\n"
                "- Ânodo de sacrifício: metal mais reativo (Mg, Zn) "
                "se oxida protegendo a estrutura."
            ),
            "exemplo": (
                "A corrosão afeta implantes médicos. Parafusos e "
                "placas de aço inoxidável ou titânio são usados em "
                "ortopedia. O titânio forma camada de TiO₂ que "
                "protege contra corrosão no ambiente biológico. "
                "Implantes de ferro biodegradável estão em "
                "desenvolvimento: corroem lentamente, liberando Fe "
                "que o corpo absorve — útil em suturas e stents "
                "temporários."
            ),
        },
    ],
    "resumo": (
        "- Pilha: espontânea, química → elétrica. Ânodo = oxidação (-). Cátodo = redução (+).\n"
        "- ΔE = E°cátodo - E°ânodo. Espontânea se ΔE > 0.\n"
        "- Eletrólise: não espontânea, elétrica → química.\n"
        "- Faraday: Q = I·t. massa ∝ carga / equivalente.\n"
        "- Corrosão: oxidação eletroquímica. Proteção: pintura, galvanização, ânodo de sacrifício.\n"
        "- Equação de Nernst: ΔE = ΔE° - (0,059/n)·log Q."
    ),
    "dicas": [
        "Ânodo: oxidação, negativo na pilha. Cátodo: redução, positivo.",
        "ΔE > 0 = espontânea (pilha). ΔE < 0 = não espontânea (eletrólise).",
        "Eletrólise ígnea: sem água. Em solução: água pode competir.",
        "Galvanização: Zn protege Fe (Zn é mais reativo, se oxida primeiro).",
        "Q = I·t (carga = corrente × tempo). 1 Faraday = 96485 C.",
        "Nernst: ΔE depende das concentrações, não só de E°.",
    ],
    "pegadinhas": [
        "Confundir ânodo e cátodo: ânodo = oxidação, sempre. Sinal depende do tipo.",
        "Na pilha, ânodo é negativo. Na eletrólise, ânodo é positivo.",
        "Esquecer que eletrólise em solução aquosa pode formar H₂ e O₂.",
        "Achar que corrosão é só oxidação direta: é processo eletroquímico.",
        "Confundir E° de redução com E° de oxidação: tabela dá redução.",
        "Esquecer de inverter o sinal do E°ânodo ao calcular ΔE.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "BARD, A. J.; FAULKNER, L. R. Electrochemical Methods. 2. ed. New York: Wiley, 2001.",
        "CASTELLAN, G. W. Fundamentos de Físico-Química. 4. ed. Rio de Janeiro: LTC, 1996.",
    ],
}

IMG_ELETROQUIMICA = [
    {"file": "br_qui11_grafico.jpg",
     "caption": "Pilhas e equilíbrio eletroquímico",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/equilibrio-quimico/"},
]

# ============================================================
# 2.13 Química Orgânica
# ============================================================
QUIMICA_ORGANICA = {
    "titulo": "Química Orgânica",
    "disciplina": "Química",
    "topico": "Química Orgânica",
    "subtopico": "Cadeias, Funções, Isomeria e Reações Orgânicas",
    "introducao": (
        "A Química Orgânica estuda os compostos do carbono. O "
        "carbono é único: forma 4 ligações, cadeias longas, "
        "estruturas complexas e estáveis. Todos os seres vivos são "
        "baseados em compostos orgânicos: carboidratos, lipídios, "
        "proteínas, ácidos nucleicos, vitaminas, hormônios."
    ),
    "secoes": [
        {
            "titulo": "1. Cadeias Carbônicas e Hibridização",
            "conteudo": (
                "CADEIAS CARBÔNICAS: sequências de átomos de carbono.\n\n"
                "CLASSIFICAÇÃO:\n"
                "- Abertas (acíclicas): lineares ou ramificadas.\n"
                "- Fechadas (cíclicas): alicíclicas ou aromáticas.\n"
                "- Mistas: parte aberta e parte fechada.\n\n"
                "SATURAÇÃO:\n"
                "- Saturadas: só ligações simples (C-C).\n"
                "- Insaturadas: têm duplas (C=C) ou triplas (C≡C).\n\n"
                "HIBRIDIZAÇÃO:\n"
                "- sp³: 4 ligações simples, geometria tetraédrica "
                "(109,5°). Ex.: CH₄.\n"
                "- sp²: 3 ligações (1 dupla + 2 simples), trigonal "
                "plana (120°). Ex.: C₂H₄.\n"
                "- sp: 2 ligações (1 tripla + 1 simples), linear "
                "(180°). Ex.: C₂H₂.\n\n"
                "ÁTOMOS DE CARBONO:\n"
                "- Primário: ligado a 1 carbono.\n"
                "- Secundário: a 2. Terciário: a 3. Quaternário: a 4."
            ),
            "exemplo": (
                "O benzeno (C₆H₆) é aromático: anel hexagonal com "
                "hibridização sp² e elétrons deslocalizados. Essa "
                "estrutura confere estabilidade excepcional. O "
                "benzeno é carcinogênico, mas derivados como o "
                "acetaminofeno (paracetamol) e a aspirina são "
                "medicamentos seguros. A aromaticidade é crucial "
                "em bioquímica: aminoácidos aromáticos (fenilalanina, "
                "tirosina, triptofano) têm anéis benzênicos."
            ),
        },
        {
            "titulo": "2. Funções Orgânicas",
            "conteudo": (
                "FUNÇÕES ORGÂNICAS: grupos de compostos com "
                "características semelhantes, definidas por grupos "
                "funcionais.\n\n"
                "PRINCIPAIS FUNÇÕES:\n"
                "- HIDROCARBONETOS: só C e H. Alcanos (CₙH₂ₙ₊₂), "
                "Alcenos (CₙH₂ₙ), Alcinos (CₙH₂ₙ₋₂), Ciclanos, "
                "Aromáticos.\n"
                "- ÁLCOOIS: -OH ligado a C saturado. Ex.: etanol.\n"
                "- FENÓIS: -OH ligado a C aromático. Ex.: fenol.\n"
                "- ÉTERES: R-O-R'. Ex.: éter etílico.\n"
                "- ALDEÍDOS: -CHO. Ex.: formaldeído, acetaldeído.\n"
                "- CETONAS: C=O entre dois C. Ex.: propanona.\n"
                "- ÁCIDOS CARBOXÍLICOS: -COOH. Ex.: ácido acético.\n"
                "- ÉSTERES: -COO-. Ex.: ésteres de frutas.\n"
                "- AMINAS: -NH₂, -NHR, -NR₂. Ex.: metilamina.\n"
                "- AMIDAS: -CONH₂. Ex.: acetamida, ligação peptídica."
            ),
            "exemplo": (
                "O etanol (álcool) é o princípio ativo das bebidas "
                "alcoólicas. No fígado, é oxidado a acetaldeído e "
                "depois a acetato. O acetaldeído é tóxico e causa "
                "ressaca. O paracetamol (acetaminofeno) é uma amida "
                "usada como analgésico. Em overdose, forma "
                "metabolito tóxico que destrói o fígado. A função "
                "orgânica determina a atividade biológica."
            ),
        },
        {
            "titulo": "3. Isomeria e Reações Orgânicas",
            "conteudo": (
                "ISOMERIA: compostos com mesma fórmula molecular, "
                "estruturas diferentes.\n\n"
                "ISOMERIA PLANA:\n"
                "- De cadeia: cadeias diferentes (butano e "
                "isobutano).\n"
                "- De posição: posição da insaturação ou grupo "
                "funcional diferente.\n"
                "- De função: funções diferentes (etanol e éter "
                "metílico).\n"
                "- Metameria: posição do heteroátomo diferente.\n"
                "- Tautomeria: equilíbrio entre formas (ceto-enólica).\n\n"
                "ISOMERIA ESPACIAL (estereoisomeria):\n"
                "- Geométrica (cis-trans): em duplas ligações ou "
                "anéis. Ex.: cis-2-buteno e trans-2-buteno.\n"
                "- Óptica: compostos com carbono quiral (4 grupos "
                "diferentes). Enantiômeros (dextrógiro e levógiro). "
                "Mistura racêmica = 50:50.\n\n"
                "REAÇÕES ORGÂNICAS:\n"
                "- Substituição: troca de átomo/grupo.\n"
                "- Adição: em insaturações (hidrogenação, halogenação).\n"
                "- Eliminação: formação de insaturação.\n"
                "- Oxidação: álcool → aldeído → ácido.\n"
                "- Redução: ácido → aldeído → álcool.\n"
                "- Esterificação: ácido + álcool → éster + água."
            ),
            "exemplo": (
                "A talidomida é o exemplo trágico de isomeria óptica. "
                "Um enantiômero trata enjoo matinal; o outro causa "
                "malformações fetais. A mistura racêmica comercial "
                "causou milhares de casos de focomelia nos anos 1960. "
                "Hoje, fármacos querais são testados separadamente. "
                "O ibuprofeno é uma mistura racêmica, mas o corpo "
                "converte o enantiômero inativo em ativo. Já a "
                "levodopa (L-DOPA) só funciona na forma levógira."
            ),
        },
    ],
    "resumo": (
        "- Cadeias: abertas, fechadas, mistas. Saturadas (só simples) ou insaturadas.\n"
        "- Hibridização: sp³ (tetraédrica), sp² (trigonal), sp (linear).\n"
        "- Funções: hidrocarbonetos, álcoois, fenóis, éteres, aldeídos, cetonas, ácidos, ésteres, aminas, amidas.\n"
        "- Isomeria plana: cadeia, posição, função, metameria, tautomeria.\n"
        "- Isomeria espacial: geométrica (cis-trans) e óptica (quiralidade).\n"
        "- Reações: substituição, adição, eliminação, oxidação, redução, esterificação."
    ),
    "dicas": [
        "sp³ = 4 ligações simples, 109,5°. sp² = dupla, 120°. sp = tripla, 180°.",
        "Álcool: -OH em C saturado. Fenol: -OH em C aromático.",
        "Aldeído: -CHO (C da dupla com H). Cetona: C=O entre 2 C.",
        "Isomeria de função: etanol (álcool) e éter metílico (éter) têm mesma fórmula.",
        "Carbono quiral: 4 grupos diferentes. Forma enantiômeros.",
        "Esterificação: ácido + álcool → éster + água (reação reversível).",
    ],
    "pegadinhas": [
        "Confundir álcool com fenol: fenol tem -OH em C aromático.",
        "Esquecer que cis-trans requer dupla ligação ou anel.",
        "Achar que isômeros ópticos têm propriedades idênticas: diferem na atividade biológica.",
        "Confundir aldeído com cetona: aldeído tem H ligado ao C do C=O.",
        "Esquecer que mistura racêmica = 50:50 enantiômeros.",
        "Achar que amidas e aminas são iguais: amida tem C=O, amina não.",
    ],
    "referencias": [
        "SOLOMONS, T. W. G.; FRYHLE, C. B. Química Orgânica. 10. ed. Rio de Janeiro: LTC, 2012.",
        "VOLLHARDT, K. P. C.; SCHORE, N. E. Química Orgânica. 4. ed. Porto Alegre: Bookman, 2004.",
        "McMURRY, J. Química Orgânica. 7. ed. São Paulo: Cengage, 2011.",
        "USBERCO, J.; SALVADOR, E. Química Orgânica. 12. ed. São Paulo: Saraiva, 2006.",
        "FELTRE, P. Química Orgânica. 7. ed. São Paulo: Moderna, 2008.",
        "BRUICE, P. Y. Química Orgânica. 6. ed. São Paulo: Pearson, 2012.",
    ],
}

IMG_ORGANICA = [
    {"file": "br_qui13_classif_cadeias.jpg",
     "caption": "Classificação das cadeias carbônicas: abertas, fechadas, mistas",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/cadeias-carbonicas/"},
    {"file": "br_qui13_funcoes.jpg",
     "caption": "Funções orgânicas: grupos funcionais e suas características",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/funcoes-organicas/"},
    {"file": "br_qui13_isomeria.jpg",
     "caption": "Isomeria: mesma fórmula molecular, estruturas diferentes",
     "source": "Toda Matéria", "source_url": "https://www.todamateria.com.br/isomeria/"},
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (TERMOQUIMICA, "QU_TERMOQUIMICA.pdf", IMG_TERMOQUIMICA, "Química — Termoquímica"),
        (CINETICA_EQUILIBRIO, "QU_CINETICA_EQUILIBRIO.pdf", IMG_CINETICA, "Química — Cinética e Equilíbrio"),
        (ELETROQUIMICA, "QU_ELETROQUIMICA.pdf", IMG_ELETROQUIMICA, "Química — Eletroquímica"),
        (QUIMICA_ORGANICA, "QU_QUIMICA_ORGANICA.pdf", IMG_ORGANICA, "Química — Química Orgânica"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluído: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
