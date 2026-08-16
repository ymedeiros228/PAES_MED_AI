# -*- coding: utf-8 -*-
"""Gera PDFs de Historia — batch 1 (topicos 8.1 a 8.3)."""

from pdf_base import generate_educational_pdf

# ============================================================
# 8.1 Mundo Antigo
# ============================================================
MUNDO_ANTIGO = {
    "titulo": "Mundo Antigo",
    "disciplina": "Historia",
    "topico": "Mundo Antigo",
    "subtopico": "Egito, Grecia, Roma e Reinos Africanos",
    "introducao": (
        "O Mundo Antigo abrange as primeiras grandes civilizacoes "
        "da humanidade, desde os reinos africanos ate Roma. "
        "Compreender essas sociedades e entender as raizes da "
        "cultura ocidental e africana."
    ),
    "secoes": [
        {
            "titulo": "1. Egito Antigo e Reinos Africanos",
            "conteudo": (
                "EGITO ANTIGO: civilizacao do rio Nilo. Sociedade "
                "teocratica governada pelo faraó. Economia agraria "
                "baseada na inundacao do Nilo. Escrita hieroglifica. "
                "Religiao politeista com vida apos a morte.\n\n"
                "REINOS AFRICANOS:\n"
                "- Mali: imperio rico em ouro, Mansa Musa.\n"
                "- Songai: comercio transaariano, Tombuctu.\n"
                "- Kush/Nubia: vizinhos do Egito, piramides.\n"
                "- Zimbabwe: grandes construcoes de pedra.\n\n"
                "CONTRIBUICOES: matematica, astronomia, arquitetura, "
                "medicina (egipcia), comercio e universidades "
                "(Tombuctu)."
            ),
            "exemplo": (
                "A medicina egipcia ja conhecia o coracao e o "
                "sistema circulatorio, como mostra o papiro Edwin "
                "Smith. Os reinos africanos, como Mali, tinham "
                "universidades em Tombuctu que atraiam estudiosos "
                "do mundo islamico. Essas contribuicoes sao "
                "frequentemente esquecidas na historia tradicional."
            ),
        },
        {
            "titulo": "2. Grecia Antiga",
            "conteudo": (
                "GRECIA ANTIGA: organizada em polis (cidades-estado). "
                "Principais: Atenas (democracia) e Esparta "
                "(militarismo).\n\n"
                "DEMOCRACIA ATENIENSE: governo do povo (demos), "
                "mas excluia mulheres, escravos e estrangeiros.\n\n"
                "CULTURA: filosofia (Socrates, Platao, Aristoteles), "
                "teatro (tragedia e comedia), mitologia, olimpiadas.\n\n"
                "PERIODOS:\n"
                "- Homérico: formacao das polis.\n"
                "- Arcaico: expansao, colonizacao.\n"
                "- Classico: apogeu cultural, guerras persas.\n"
                "- Helenistico: imperio de Alexandre Magno."
            ),
            "exemplo": (
                "A medicina hipocratica nasceu na Grecia. "
                "Hipocrates e considerado o pai da medicina e "
                "estabeleceu principios eticos ainda usados hoje, "
                "como o juramento hipocratico. A observacao "
                "clinica e a busca por causas naturais das doencas "
                "marcaram o inicio da medicina cientifica."
            ),
        },
        {
            "titulo": "3. Roma Antiga",
            "conteudo": (
                "ROMA: fundada em 753 a.C. (mito de Romulo e Remo).\n\n"
                "PERIODOS:\n"
                "- Monarquia: 753-509 a.C., sete reis.\n"
                "- Republica: 509-27 a.C., Senado, consules, "
                "tribunos. Conquistas territoriais.\n"
                "- Imperio: 27 a.C.-476 d.C. Augusto primeiro "
                "imperador. Pax Romana.\n\n"
                "CONTRIBUICOES:\n"
                "- Direito romano: base do direito ocidental.\n"
                "- Arquitetura: arcos, aquedutos, coliseu.\n"
                "- Lingua: latim, origem das linguas neolatinas.\n"
                "- Republica e Senado: modelos politicos.\n\n"
                "CRISTIANISMO: surgiu no imperio romano, "
                "perseguido ate 313 (edito de Milao) e oficializado "
                "em 380."
            ),
            "exemplo": (
                "O direito romano influencia o sistema juridico "
                "brasileiro. Conceitos como contrato, propriedade "
                "e cidadania tem raizes romanas. A organizacao "
                "dos hospitais militares romanos (valetudinaria) "
                "e precursora dos hospitais modernos."
            ),
        },
    ],
    "resumo": (
        "- Egito: sociedade teocratica no Nilo. Reinos Africanos: Mali, Songai, Kush.\n"
        "- Grecia: polis, democracia ateniense, filosofia, medicina hipocratica.\n"
        "- Roma: monarquia, republica, imperio. Direito, arquitetura, latim.\n"
        "- Cristianismo surgiu no imperio romano.\n"
        "- Contribuicoes africanas: Tombuctu, comercio, ciencia."
    ),
    "dicas": [
        "Egito e uma sociedade teocratica: faraó e rei e deus.",
        "Democracia ateniense excluia mulheres, escravos e metecos.",
        "Roma: republica tem Senado; imperio tem imperador.",
        "Hipocrates e o pai da medicina; juramento hipocratico.",
        "Tombuctu foi centro de saber africano, nao so de comercio.",
        "Direito romano e base do direito brasileiro.",
    ],
    "pegadinhas": [
        "Achar que a democracia ateniense era universal: excluia a maioria.",
        "Confundir periodo homérico com helenistico.",
        "Esquecer os reinos africanos na historia antiga.",
        "Achar que Roma sempre foi imperio: primeiro foi monarquia e republica.",
        "Confundir Pax Romana com ausencia de guerras: havia paz interna, mas conquistas externas.",
        "Esquecer que o cristianismo nasceu dentro do imperio romano.",
    ],
    "referencias": [
        "VICENTINO, C. D. Historia para o Ensino Medio. 2. ed. Sao Paulo: Scipione, 2013.",
        "MOTA, M.; BRAICK, P. R. Historia das cavernas ao terceiro milenio. Sao Paulo: Moderna, 2010.",
        "ARRUDA, J. J. A. Historia antiga e medieval. 15. ed. Sao Paulo: Atica, 2011.",
        "CARDOSO, C. F. S. O trabalho compulsorio na antiguidade. Rio de Janeiro: Graal, 2003.",
        "KI-ZERBO, J. Historia da Africa negra. 2. ed. Sintra: Publicacoes Europa-America, 1999.",
        "FUNARI, P. P. A. Roma: vida publica e privada. Sao Paulo: Atual, 2002.",
    ],
}

IMG_MUNDO_ANTIGO = [
    {"file": "hist_mundo_antigo.png", "caption": "Principais civilizacoes da Antiguidade", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 8.2 Mundo Medieval
# ============================================================
MEDIEVAL = {
    "titulo": "Mundo Medieval",
    "disciplina": "Historia",
    "topico": "Mundo Medieval",
    "subtopico": "Feudalismo, cristianismo, islamismo e sociedade feudal",
    "introducao": (
        "O Mundo Medieval vai da queda do Imperio Romano do "
        "Ocidente (476) ate a tomada de Constantinopla pelos "
        "turcos (1453). Marcado pelo feudalismo, pela expansao "
        "do cristianismo e do islamismo."
    ),
    "secoes": [
        {
            "titulo": "1. Feudalismo",
            "conteudo": (
                "FEUDALISMO: sistema economico, social e politico "
                "baseado no feudo (terra). Predominante na Europa "
                "ocidental entre os seculos V e XV.\n\n"
                "SOCIEDADE ESTAMENTAL:\n"
                "- Clero: orar (primero estado).\n"
                "- Nobreza: guerrear (segundo estado).\n"
                "- Servos: trabalhar (terceiro estado).\n\n"
                "RELACOES DE PRODUCAO:\n"
                "- Senhor feudal: dono da terra.\n"
                "- Servo: trabalhador preso a terra, nao escravo.\n"
                "- Corveia: trabalho gratuito.\n"
                "- Talha: parte da producao para o senhor.\n"
                "- Banalidades: taxas pelo uso de moinho, forno.\n\n"
                "DECADENCIA: renascimento comercial, crescimento "
                "das cidades, cruzadas, peste negra."
            ),
            "exemplo": (
                "O servo nao era escravo: tinha liberdade pessoal, "
                "mas estava preso a terra e devia obrigatorias ao "
                "senhor. A peste negra (1347-1351) matou cerca de "
                "um terco da populacao europeia, gerando escassez "
                "de mao de obra e enfraquecendo o feudalismo."
            ),
        },
        {
            "titulo": "2. Cristianismo e Islamismo",
            "conteudo": (
                "CRISTIANISMO MEDIEVAL:\n"
                "- Igreja catolica: instituicao mais poderosa.\n"
                "- Papa: autoridade maxima espiritual.\n"
                "- Feudalismo eclesiastico: mosteiros, bispos.\n"
                "- Cruzadas: expedições para recuperar Terra Santa.\n"
                "- Inquisicao: combate a heresias.\n\n"
                "ISLAMISMO:\n"
                "- Fundador: Maome (570-632).\n"
                "- Livro sagrado: Alcorao.\n"
                "- Cinco pilares: fe, oracao, esmola, jejum, "
                "peregrinacao.\n"
                "- Expansao rapida: do Arabia ate Peninsula Iberica.\n"
                "- Califados: Omíadas, Abassidas, Otomano.\n\n"
                "CONTRIBUICOES ISLAMICAS: matematica (algebra), "
                "astronomia, medicina (Avicena), preservacao de "
                "textos gregos."
            ),
            "exemplo": (
                "Avicena (Ibn Sina) escreveu o Canon de Medicina, "
                "obra usada em universidades europeias por seculos. "
                "Os arabes preservaram e ampliaram o conhecimento "
                "grego durante a Idade Media, enquanto a Europa "
                "ocidental vivia um periodo de menor producao "
                "intelectual."
            ),
        },
        {
            "titulo": "3. Sociedade feudal e transicao",
            "conteudo": (
                "VIDA NO FEUDO: economia de subsistencia, pouca "
                "moeda, comercio local. Castelos, mosteiros e "
                "vilarejos.\n\n"
                "CRUZADAS (1096-1291): expedições religiosas e "
                "militares. Reabriram rotas comerciais no "
                "Mediterraneo.\n\n"
                "RENASCIMENTO COMERCIAL: a partir do seculo XI, "
                "cidades cresceram, burguesia surgiu, feudos "
                "decadiram.\n\n"
                "PESTE NEGRA: doenca que dizimou populacao "
                "europeia em meados do seculo XIV.\n\n"
                "TRANSICAO: do feudalismo ao capitalismo comercial. "
                "Monarquias nacionais se fortalecem."
            ),
            "exemplo": (
                "As cruzadas, embora religiosas em proposito, "
                "tiveram efeito economico: reabriram rotas "
                "comerciais com o Oriente, trazendo produtos como "
                "especiarias e seda. Isso estimulou o comercio, "
                "enriqueceu a burguesia e enfraqueceu o sistema "
                "feudal."
            ),
        },
    ],
    "resumo": (
        "- Feudalismo: feudo, senhor, servo, corveia, talha.\n"
        "- Sociedade estamental: clero, nobreza, servos.\n"
        "- Igreja catolica: poder central na Idade Media.\n"
        "- Islamismo: Maome, Alcorao, cinco pilares, expansao.\n"
        "- Cruzadas reabriram rotas comerciais.\n"
        "- Peste negra e renascimento comercial decadiram o feudalismo."
    ),
    "dicas": [
        "Servo nao e escravo: tem liberdade pessoal, mas preso a terra.",
        "Clero e nobreza sao privilegiados; servos pagam impostos.",
        "Cruzadas tiveram efeito economico alem do religioso.",
        "Avicena e outros arabes preservaram e ampliaram a medicina grega.",
        "Peste negra acelerou o fim do feudalismo.",
        "Burguesia surge com o renascimento comercial.",
    ],
    "pegadinhas": [
        "Confundir servo com escravo: servo tem liberdade pessoal.",
        "Achar que o feudalismo era so economico: era tambem politico e social.",
        "Esquecer as contribuicoes islamicas para a ciencia.",
        "Achar que as cruzadas foram so religiosas: tinham interesses economicos.",
        "Confundir clero regular (mosteiros) com clero secular (bispos).",
        "Esquecer que a peste negra foi fator de decadencia do feudalismo.",
    ],
    "referencias": [
        "VICENTINO, C. D. Historia para o Ensino Medio. 2. ed. Sao Paulo: Scipione, 2013.",
        "MOTA, M.; BRAICK, P. R. Historia das cavernas ao terceiro milenio. Sao Paulo: Moderna, 2010.",
        "ARRUDA, J. J. A. Historia antiga e medieval. 15. ed. Sao Paulo: Atica, 2011.",
        "FRANCO JR, H. A Idade Media: nascimento do Ocidente. 2. ed. Sao Paulo: Brasiliense, 2001.",
        "CARDOSO, C. F. S. O trabalho compulsorio na antiguidade. Rio de Janeiro: Graal, 2003.",
        "ARMSTRONG, K. Maome: uma biografia do profeta. Sao Paulo: Companhia das Letras, 2002.",
    ],
}

IMG_MEDIEVAL = [
    {"file": "hist_medieval.png", "caption": "Piramide da sociedade feudal", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# 8.3 Idade Moderna
# ============================================================
MODERNA = {
    "titulo": "Idade Moderna",
    "disciplina": "Historia",
    "topico": "Idade Moderna",
    "subtopico": "Navegacoes, Renascimento, Reforma, colonizacao e Iluminismo",
    "introducao": (
        "A Idade Moderna vai de 1453 (tomada de Constantinopla) "
        "a 1789 (Revolucao Francesa). Marcada por grandes "
        "navegacoes, Renascimento, Reforma religiosa, "
        "colonizacao e Iluminismo."
    ),
    "secoes": [
        {
            "titulo": "1. Grandes Navegacoes e Renascimento",
            "conteudo": (
                "GRANDES NAVEGACOES (seculos XV-XVI):\n"
                "- Portugal: pioneiro. Escola de Sagres, Henrique "
                "Navegador. Boa Esperanca (1488), India (1498).\n"
                "- Espanha: Colombo chega a America (1492).\n"
                "- Tratado de Tordesilhas (1494): divisao do mundo.\n\n"
                "RENASCIMENTO (seculos XIV-XVI):\n"
                "- Movimento cultural: valorizacao da antiguidade "
                "classica, humanismo, racionalidade.\n"
                "- Arte: Leonardo da Vinci, Michelangelo, Rafael.\n"
                "- Ciencia: Copernico, Galileu, Vesalio.\n"
                "- Medicina: Vesalio (anatomia), Paracelso.\n\n"
                "CAUSAS DAS NAVEGACOES: busca de especiarias, "
                "rotas comerciais, expansao cristã, centralizacao "
                "monarquica."
            ),
            "exemplo": (
                "Vesalio publicou 'De Humani Corporis Fabrica' "
                "(1543), revolucionando a anatomia com observacoes "
                "diretas de cadaveres. Isso corrigiu erros de "
                "Galeno que duravam ha seculos. O Renascimento "
                "trouxe o espirito cientifico para a medicina."
            ),
        },
        {
            "titulo": "2. Reforma e Contra-Reforma",
            "conteudo": (
                "REFORMA PROTESTANTE (seculo XVI):\n"
                "- Lutero (1517): 95 teses, contra venda de "
                "indulgencias.\n"
                "- Calvino: predestinacao, Genebra.\n"
                "- Anglicanismo: Henrique VIII separa Igreja "
                "inglesa de Roma.\n\n"
                "CONTRA-REFORMA:\n"
                "- Concilio de Trento (1545-1563): reformas "
                "internas, doutrina catolica.\n"
                "- Companhia de Jesus: evangelizacao, educacao.\n"
                "- Inquisicao: combate a heresias.\n\n"
                "CONSEQUENCIAS: divisao religiosa da Europa, "
                "guerras religiosas, expansao do protestantismo."
            ),
            "exemplo": (
                "A Companhia de Jesus, fundada por Inacio de "
                "Loyola, foi importante na colonizacao do Brasil. "
                "Os jesuitas fundaram escolas e aldeias, "
                "catequizaram indigenas e foram os principais "
                "educadores da colonia ate a expulsao em 1759."
            ),
        },
        {
            "titulo": "3. Colonizacao, escravidao e Iluminismo",
            "conteudo": (
                "COLONIZACAO DAS AMERICAS:\n"
                "- Espanha: Mexico, Peru, destruicao de imperios "
                "asteca e inca.\n"
                "- Portugal: Brasil, cana-de-acucar, capitanias.\n"
                "- Inglaterra: colonias na America do Norte.\n\n"
                "ESCRAVIDAO:\n"
                "- Indigena: primeiro trabalho forcado no Brasil.\n"
                "- Africana: trafico negreiro, seculos XVI-XIX.\n"
                "- Impacto demografico e cultural profundo.\n\n"
                "ILUMINISMO (seculo XVIII):\n"
                "- Razao, liberdade, igualdade, progresso.\n"
                "- Pensadores: Voltaire, Rousseau, Montesquieu, "
                "Locke.\n"
                "- Influencia na Independencia dos EUA e na "
                "Revolucao Francesa."
            ),
            "exemplo": (
                "O trafico negreiro trouxe milhoes de africanos "
                "para as Americas. No Brasil, a cultura afro-"
                "brasileira influenciou religiao (candomble), "
                "musica, culinaria e lingua. O Iluminismo "
                "inspirou movimentos de independencia e ideais "
                "de liberdade."
            ),
        },
    ],
    "resumo": (
        "- Navegacoes: Portugal pioneiro, Tordesilhas, Colombo 1492.\n"
        "- Renascimento: humanismo, arte, ciencia, Vesalio.\n"
        "- Reforma: Lutero, Calvino, anglicanismo. Contra-reforma: Trento, jesuitas.\n"
        "- Colonizacao: Espanha, Portugal, Inglaterra. Escravidao africana e indigena.\n"
        "- Iluminismo: razao, liberdade, Voltaire, Rousseau, Montesquieu."
    ),
    "dicas": [
        "Portugal foi pioneiro nas navegacoes devido a centralizacao monarquica e escola de Sagres.",
        "Vesalio revolucionou a anatomia no Renascimento.",
        "Lutero comecou a Reforma em 1517 com as 95 teses.",
        "Tordesilhas dividiu o mundo entre Portugal e Espanha em 1494.",
        "Iluminismo influenciou a Independencia dos EUA e a Revolucao Francesa.",
        "Escravidao africana foi central na economia colonial brasileira.",
    ],
    "pegadinhas": [
        "Achar que Colombo descobriu o Brasil: chegou a America, mas Portugal chegou ao Brasil em 1500.",
        "Confundir Renascimento (cultural) com Reforma (religiosa).",
        "Esquecer que a Contra-Reforma tambem teve reformas internas, nao so repressao.",
        "Achar que o Iluminismo era so frances: tambem ingles (Locke) e alemao (Kant).",
        "Confundir colonizacao de exploracao com colonizacao de povoamento.",
        "Esquecer a importancia dos jesuitas na educacao colonial.",
    ],
    "referencias": [
        "VICENTINO, C. D. Historia para o Ensino Medio. 2. ed. Sao Paulo: Scipione, 2013.",
        "MOTA, M.; BRAICK, P. R. Historia das cavernas ao terceiro milenio. Sao Paulo: Moderna, 2010.",
        "ARRUDA, J. J. A. Historia moderna e contemporanea. 14. ed. Sao Paulo: Atica, 2010.",
        "BURNS, E. M. Historia da civilizacao ocidental. 43. ed. Porto Alegre: Globo, 2005.",
        "NOVAIS, F. A. Portugal e Brasil na crise do antigo sistema colonial. Sao Paulo: Hucitec, 2001.",
        "CANDIDO, A. Formacao da literatura brasileira. 2. ed. Belo Horizonte: Itatiaia, 2010.",
    ],
}

IMG_MODERNA = [
    {"file": "hist_moderna.png", "caption": "Grandes navegacoes: Europa chega a America", "source": "PAES MED AI", "source_url": ""}
]

# ============================================================
# Gerar todos
# ============================================================
def main():
    pdfs = [
        (MUNDO_ANTIGO, "HIS_MUNDO_ANTIGO.pdf", IMG_MUNDO_ANTIGO, "Historia — Mundo Antigo"),
        (MEDIEVAL, "HIS_MUNDO_MEDIEVAL.pdf", IMG_MEDIEVAL, "Historia — Mundo Medieval"),
        (MODERNA, "HIS_IDADE_MODERNA.pdf", IMG_MODERNA, "Historia — Idade Moderna"),
    ]
    for content, filename, imgs, subtitle in pdfs:
        print(f"\nGerando: {filename}")
        generate_educational_pdf(content, filename, imgs, subtitle)
    print(f"\nConcluido: {len(pdfs)} PDFs gerados!")

if __name__ == "__main__":
    main()
