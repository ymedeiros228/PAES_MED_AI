"""Extrai uma prova PAES (formato atual, 60 questões) do caderno oficial em PDF.

Uso: python extrair_prova.py <ano>
Lê  data/provas/paes_<ano>.pdf e data/gabaritos/gabarito_<ano>.pdf (os PDFs oficiais do acervo)
Gera data/provas_oficiais/paes-<ano>.json e recortes em data/figuras/<ano>/ (revisão à mão: scripts/provas/revisao/)

O resultado é um rascunho: o verificador (verificar_prova.py) e a revisão humana
decidem o que vai para o banco.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

import pymupdf
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]

# Ordem fixa do caderno (conferida nas provas de 2024 a 2026)
DISCIPLINAS = [
    (15, "linguagens", "portugues"),
    (20, "linguagens", None),  # inglês ou espanhol, conforme a seção
    (25, "humanas", "historia"),
    (30, "humanas", "geografia"),
    (35, "humanas", "filosofia"),
    (40, "humanas", "sociologia"),
    (45, "natureza", "fisica"),
    (50, "natureza", "matematica"),
    (55, "natureza", "biologia"),
    (60, "natureza", "quimica"),
]

RE_QUESTAO = re.compile(r"^\s*Quest[ãa]o\s+(\d{1,2})\b", re.I)
RE_ALT = re.compile(r"(?:^|\s)([a-e])\)\s", re.M)
RE_FAIXA = re.compile(
    r"(?:quest(?:ões|oes|ão|ao)|questions?|cuestiones?)\s*(?:de\s*)?(\d{1,2})"
    r"((?:\s*(?:,|e|a|y|and|to|-|–)\s*\d{1,2})*)",
    re.I,
)


# Caderno antigo (PAES 2014 e 2015): 80 questões, matérias em ordem alfabética, 8 por matéria,
# Espanhol e Inglês nas questões 41 a 48 (conferido nos títulos de seção dos PDFs)
DISCIPLINAS_80 = [
    (8, "natureza", "biologia"),
    (16, "humanas", "filosofia"),
    (24, "natureza", "fisica"),
    (32, "humanas", "geografia"),
    (40, "humanas", "historia"),
    (48, "linguagens", None),
    (56, "linguagens", "portugues"),
    (64, "natureza", "matematica"),
    (72, "natureza", "quimica"),
    (80, "humanas", "sociologia"),
]

# PAES 2016: 60 questões por área, mas sem título de matéria dentro da área; a matéria de
# cada questão das áreas de Humanas e Natureza foi lida no conteúdo (ver revisão no fim do arquivo)
DISCIPLINAS_2016 = [
    (15, "linguagens", "portugues"),
    (20, "linguagens", None),
    (24, "humanas", "historia"),
    (30, "humanas", "geografia"),
    (35, "humanas", "filosofia"),
    (40, "humanas", "sociologia"),
    (45, "natureza", "matematica"),
    (50, "natureza", "fisica"),
    (54, "natureza", "biologia"),
    (59, "natureza", "quimica"),
    (60, "natureza", "biologia"),
]


class Layout:
    """O que muda de um caderno para outro: matérias, faixa das línguas e total de questões."""

    def __init__(self, disciplinas, linguas: tuple[int, int], total: int, gabarito_es_primeiro: bool, colunas: int = 1):
        self.disciplinas = disciplinas
        self.colunas = colunas
        self.lingua_ini, self.lingua_fim = linguas
        self.total = total
        # no gabarito, qual coluna de língua vem primeiro (2014/2015: Espanhol; demais: Inglês)
        self.gabarito_es_primeiro = gabarito_es_primeiro

    def eh_lingua(self, numero: int) -> bool:
        return self.lingua_ini <= numero <= self.lingua_fim


LAYOUT_ATUAL = Layout(DISCIPLINAS, (16, 20), 60, False)
LAYOUTS = {
    2014: Layout(DISCIPLINAS_80, (41, 48), 80, True, colunas=2),
    2015: Layout(DISCIPLINAS_80, (41, 48), 80, True, colunas=2),
    2016: Layout(DISCIPLINAS_2016, (16, 20), 60, False, colunas=2),
}
LAYOUT = LAYOUT_ATUAL  # trocado em extrair(ano)


def area_disciplina(numero: int, lingua: str | None) -> tuple[str, str]:
    for limite, area, disciplina in LAYOUT.disciplinas:
        if numero <= limite:
            if disciplina is None:
                return area, "ingles" if lingua == "en" else "espanhol"
            return area, disciplina
    raise ValueError(numero)


SOBRE = str.maketrans("0123456789+-−=()n", "⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁻⁼⁽⁾ⁿ")
ORDINAIS = {"st": "st", "nd": "nd", "rd": "rd", "th": "th", "o": "º", "a": "ª", "os": "ºs", "as": "ªs"}
SOB = str.maketrans("0123456789+-−=()", "₀₁₂₃₄₅₆₇₈₉₊₋₋₌₍₎")


def texto_da_linha(linha: dict) -> str:
    """Junta os trechos da linha convertendo expoentes e índices (cm³, m/s², CO₂)."""
    spans = linha["spans"]
    if not spans:
        return ""
    base = max(s["size"] for s in spans)
    base_y = max(s["origin"][1] for s in spans if s["size"] >= base - 0.1)
    partes = []
    for s in spans:
        t = s["text"]
        pequeno = s["size"] < base * 0.8 and t.strip()
        if pequeno and (s["flags"] & 1 or s["origin"][1] < base_y - 1.5):
            conv = t.strip().translate(SOBRE)
            if t.strip() in ORDINAIS:  # 3rd, 1º, 2ª: sufixo de ordinal, não expoente
                partes.append(ORDINAIS[t.strip()])
            else:
                partes.append(conv if conv != t.strip() or not t.strip().isalpha() else f"^{t.strip()}")
        elif pequeno and s["origin"][1] > base_y + 0.8:
            conv = t.strip().translate(SOB)
            partes.append(conv if conv != t.strip() else f"_{t.strip()}")
        else:
            partes.append(t)
    return "".join(partes)


def tabela_markdown(tab) -> str:
    linhas = [[(c or "").replace("\n", " ").strip() for c in lin] for lin in tab.extract()]
    linhas = [l for l in linhas if any(l)]
    if not linhas:
        return ""
    # texto em colunas (poemas lado a lado) às vezes é detectado como tabela: células longas sem espaço
    celulas = [c for l in linhas for c in l if c]
    if celulas and sum(1 for c in celulas if len(c) > 18 and " " not in c) >= max(1, len(celulas) // 4):
        return ""
    cab = linhas[0]
    md = ["| " + " | ".join(cab) + " |", "| " + " | ".join("---" for _ in cab) + " |"]
    md += ["| " + " | ".join(l) + " |" for l in linhas[1:]]
    return "\n".join(md)


def limpar(texto: str) -> str:
    texto = texto.replace("­", "").replace("ﬁ", "fi").replace("ﬂ", "fl")
    texto = texto.replace("", "→")  # seta de reação na fonte Symbol
    # travessão e marcadores das fontes Symbol/Wingdings (cadernos 2014-2016): o travessão de
    # verso vem sozinho na linha anterior (" \nsois madeira") e volta para o começo do verso
    texto = re.sub(r"[ \t]*\n?[ \t]*", "— ", texto)
    texto = re.sub(r"[][ \t]*", "• ", texto)
    texto = re.sub(r"-\n(?=[a-zà-ú])", "", texto)  # hifenização de fim de linha
    if LAYOUT.colunas == 2:
        # cadernos 2014-2016: "―" é travessão de diálogo no início da fala e aspas de abertura
        # no resto ("―tocado‖"); "‖" e "‗" são aspas de fechamento
        texto = re.sub(r"(^|\n)[ \t]*―[ \t]*", r"\1— ", texto)
        texto = texto.replace("―", "“").replace("‖", "”").replace("‗", "‘")
    # quebras são estrutura: "\n" = verso ou linha curta, "\n\n" = parágrafo (ver juntar_linhas)
    texto = re.sub(r"[ \t]*\n[ \t]*", "\n", texto)
    texto = re.sub(r"\n{3,}", "\n\n", texto)
    # linha longa sem pontuação seguida de minúscula é a mesma frase (citação curta, virada de página)
    texto = re.sub(r"(?m)^([^\n]{55,}[^.:;!?…”\")\n])\n{1,2}(?=[a-zà-ú])", r"\1 ", texto)
    # estado físico em química: "O₂₍g₎" -> "O₂(g)"
    texto = re.sub(r"₍([a-zA-Z]+)₎", r"(\1)", texto)
    return re.sub(r"[ \t]{2,}", " ", texto).strip()


def plano(texto: str) -> str:
    """Texto numa linha só (alternativas e comparações)."""
    return re.sub(r"\s+", " ", texto).strip()


def juntar_linhas(linhas: list[tuple[tuple, str]], margem: float) -> str:
    """Junta as linhas de um bloco preservando versos e parágrafos.

    Linha que chega perto da margem direita é prosa justificada e continua na seguinte;
    linha curta termina ali (fim de parágrafo, verso de poema, título como "Texto I").
    """
    # texto justificado em coluna estreita: o PDF às vezes entrega cada palavra como uma
    # "linha"; pedaços seguidos na mesma altura são a mesma linha
    unidas: list[tuple[tuple, str]] = []
    for bb, t in linhas:
        if unidas and abs(unidas[-1][0][1] - bb[1]) < 2 and bb[0] >= unidas[-1][0][2] - 1:
            (x0, y0, _x1, y1), tx = unidas[-1]
            unidas[-1] = ((x0, y0, bb[2], max(y1, bb[3])), tx.rstrip() + " " + t.strip())
        else:
            unidas.append((bb, t))
    linhas = unidas
    if len(linhas) >= 3:
        # citação recuada tem borda própria; prosa enche a maioria das linhas até ela, poema não
        borda = max(bb[2] for bb, _ in linhas)
        cheias = sum(bb[2] >= borda - 25 for bb, _ in linhas[:-1])
        # redondilha também tem linhas de tamanho parecido, mas curtas (~30 caracteres)
        media = sum(len(t.strip()) for _, t in linhas) / len(linhas)
        # justificado de verdade (coluna estreita ao lado de figura): bordas idênticas
        exatas = sum(bb[2] >= borda - 3 for bb, _ in linhas[:-1])
        prosa = (cheias >= 0.6 * (len(linhas) - 1) and media > 45) or (
            len(linhas) >= 5 and exatas >= 0.7 * (len(linhas) - 1)
        )
        margem = borda if prosa else float("inf")
    saida = ""
    for i, (bb, t) in enumerate(linhas):
        t = t.strip()
        if i == 0:
            saida = t
            continue
        anterior_cheia = linhas[i - 1][0][2] >= margem - 25
        if re.fullmatch(r"Quest[ãa]o\s+\d{1,2}", t):
            saida += "\n" + t  # marcador de questão nunca continua a linha anterior
        elif anterior_cheia and saida.endswith("-") and re.match(r"[a-zà-ú]", t):
            saida = saida[:-1] + t  # palavra hifenizada na quebra
        elif anterior_cheia:
            saida += " " + t
        else:
            saida += "\n" + t
    return saida


RE_CABECALHO = re.compile(
    r"^(LINGUAGENS, C[ÓO]DIGOS|CI[ÊE]NCIAS HUMANAS|MATEM[ÁA]TICA, CI[ÊE]NCIAS|Processo Seletivo de Acesso)", re.I
)
# cabeçalho de página dos cadernos 2014-2016: "Processo Seletivo ... PAES 2015 DOCV/PROG/UEMA
# 1ª ETAPA 16/11/2014 das 13h às 18h | P á g i n a 7" (às vezes vem colado ao texto da questão)
RE_CABECALHO_ANTIGO = re.compile(
    r"Processo Seletivo de Acesso [^\n]*(?:\n[^\n]*?P\s?á\s?g\s?i\s?n\s?a\s*\d+)?|"
    r"[^\n]*\d{1,2}/\d{1,2}/\d{4}\s+das\s+\d+h[^\n]*P\s?á\s?g\s?i\s?n\s?a\s*\d+[^\n]*",
    re.I,
)


def eh_moldura(bbox, altura_pag: float, texto: str | None = None) -> bool:
    """Rodapé, logotipos e cabeçalhos de área que se repetem em toda página."""
    x0, y0, x1, y1 = bbox
    if y0 > altura_pag - 50:
        return True
    if y1 < 48:
        # no topo, só o cabeçalho de área é moldura; o resto é conteúdo que começa a página
        return texto is None or bool(RE_CABECALHO.match(texto.strip()))
    return False


def tabela_caderno_antigo(tab) -> str:
    """Nos cadernos 2014-2016, decide o que fazer com uma "tabela" achada pelo PyMuPDF.

    'texto': falsa (quadro em volta de texto, poema, página em colunas) ou contém as
    alternativas (precisam sair como texto para virar A-E); 'imagem': tabela de verdade.
    """
    linhas = [[(c or "").replace("\n", " ").strip() for c in lin] for lin in tab.extract()]
    celulas = [c for l in linhas for c in l if c]
    if len(linhas) < 2 or not celulas:
        return "texto"
    tudo = " ".join(celulas)
    if re.search(r"Quest[ãa]o\s*\d|L[ÍI]NGUA|Quest[õo]es\s*de", tudo, re.I):
        return "texto"
    if any(len(c) > 70 for c in celulas):
        return "texto"
    if sum(1 for c in celulas if re.match(r"^[a-e]\)", c)) >= 3:
        return "texto"
    return "imagem"


def ordenar_duas_colunas(itens: list[dict], largura: float) -> list[dict]:
    """Ordem de leitura de página em duas colunas (cadernos 2014-2016).

    Bloco que atravessa o meio da página (figura larga, título "Diálogos para...") divide a
    página em faixas; dentro de cada faixa, lê a coluna da esquerda inteira e depois a da direita.
    """
    meio = largura / 2

    def atravessa(it: dict) -> bool:
        x0, _y0, x1, _y1 = it["bbox"]
        return x0 < meio - 20 and x1 > meio + 20

    saida: list[dict] = []
    faixa: list[dict] = []

    def fecha_faixa() -> None:
        faixa.sort(key=lambda it: (0 if (it["bbox"][0] < meio - 20 or it["bbox"][2] <= meio + 3) else 1, round(it["bbox"][1]), it["bbox"][0]))
        saida.extend(faixa)
        faixa.clear()

    for it in sorted(itens, key=lambda it: (round(it["bbox"][1]), it["bbox"][0])):
        if atravessa(it):
            fecha_faixa()
            saida.append(it)
        else:
            faixa.append(it)
    fecha_faixa()
    return saida


def dividir_blocos_por_coluna(blocos: list[dict], largura: float) -> list[dict]:
    """Cadernos em duas colunas: o PDF às vezes põe no mesmo bloco linhas das duas colunas
    ("Questão 35" à esquerda e "Questão 37" à direita). Separa cada bloco por coluna e
    corta da caixa da linha os espaços à direita, que a fazem parecer atravessar a página."""
    meio = largura / 2
    saida = []
    for blk in blocos:
        if blk["type"] != 0:
            saida.append(blk)
            continue
        grupos: dict[int, list[dict]] = {}
        for linha in blk["lines"]:
            texto = "".join(s["text"] for s in linha["spans"])
            if not texto.strip():
                continue
            x0, y0, x1, y1 = linha["bbox"]
            util = len(texto.rstrip()) / max(1, len(texto))
            nova = dict(linha, bbox=(x0, y0, x0 + (x1 - x0) * util, y1))
            grupos.setdefault(0 if (x0 < meio - 20 or x0 + (x1 - x0) * util <= meio + 3) else 1, []).append(nova)
        for linhas in grupos.values():
            # vão vertical grande dentro do bloco é onde fica uma figura/tabela: corta ali,
            # para a figura entrar na ordem certa (senão vai para depois da coluna inteira)
            pedacos, atual = [], [linhas[0]]
            for anterior, linha in zip(linhas, linhas[1:]):
                if linha["bbox"][1] - anterior["bbox"][3] > 20:
                    pedacos.append(atual)
                    atual = []
                atual.append(linha)
            pedacos.append(atual)
            for pedaco in pedacos:
                bb = (min(l["bbox"][0] for l in pedaco), min(l["bbox"][1] for l in pedaco),
                      max(l["bbox"][2] for l in pedaco), max(l["bbox"][3] for l in pedaco))
                saida.append({"type": 0, "lines": pedaco, "bbox": bb})
    return saida


def ler_blocos(doc) -> list[dict]:
    """Sequência de blocos de texto e imagens, na ordem de leitura, sem moldura."""
    itens: list[dict] = []
    for pn, pag in enumerate(doc):
        if pn == 0:
            continue  # capa com instruções
        h = pag.rect.height
        w = pag.rect.width
        bruto = []
        # tabelas viram markdown; o texto de dentro delas não entra como parágrafo
        areas_tabela = []
        try:
            achadas = pag.find_tables().tables
        except Exception:  # pragma: no cover - versão antiga do PyMuPDF
            achadas = []
        for tab in achadas:
            if LAYOUT.colunas == 2:
                tipo = tabela_caderno_antigo(tab)
                if tipo == "imagem":
                    # números de tabela saem embaralhados do PDF antigo ("5.200,00" -> "520000 . ,"):
                    # a tabela entra como recorte fiel da página
                    areas_tabela.append(pymupdf.Rect(tab.bbox))
                    bruto.append({"tipo": "imagem", "pag": pn, "bbox": tuple(tab.bbox)})
                continue  # "texto": quadro em volta do texto ou alternativas; segue como texto comum
            md = tabela_markdown(tab)
            if md and len(tab.extract()) >= 2:
                areas_tabela.append(pymupdf.Rect(tab.bbox))
                bruto.append({"tipo": "tabela", "texto": md, "pag": pn, "bbox": tuple(tab.bbox)})
        blocos_pag = pag.get_text("dict", sort=True)["blocks"]
        if LAYOUT.colunas == 2:
            blocos_pag = dividir_blocos_por_coluna(blocos_pag, w)
        # corpo da prova em 10 pt (algumas páginas em 9,5 pt); legendas e links abaixo disso
        por_tamanho: dict[float, int] = {}
        for b in blocos_pag:
            for l in b.get("lines", []):
                for sp in l["spans"]:
                    por_tamanho[round(sp["size"], 1)] = por_tamanho.get(round(sp["size"], 1), 0) + len(sp["text"])
        corpo_pt = max(por_tamanho, key=por_tamanho.get, default=10.0)
        limiar = min(9.6, corpo_pt - 0.3) if corpo_pt >= 9 else 9.6
        # margem direita do corpo nesta página: linha que chega nela é prosa que continua
        margem = max(
            (l["bbox"][2] for b in blocos_pag if b["type"] == 0 for l in b["lines"]
             if l["spans"] and max(s["size"] for s in l["spans"]) >= limiar and not eh_moldura(l["bbox"], h)),
            default=w,
        )
        for blk in blocos_pag:
            if blk["type"] != 0:
                continue
            if any(pymupdf.Rect(blk["bbox"]).intersects(a) and pymupdf.Rect(blk["bbox"]) in a + (-2, -2, 2, 2) for a in areas_tabela):
                continue
            corpo, creditos = [], []
            for linha in blk["lines"]:
                t = texto_da_linha(linha)
                if not t.strip():
                    continue
                tam = max(s["size"] for s in linha["spans"])
                (creditos if tam < limiar else corpo).append((linha["bbox"], t))
            for bb, t in creditos:
                if eh_moldura(bb, h, t):
                    continue
                coluna = 0 if bb[0] < w / 2 - 20 else 1
                bruto.append({"tipo": "credito", "texto": t.strip(), "pag": pn, "bbox": bb, "coluna": coluna})
            if not corpo:
                continue
            # "Questão 29" e "Questão 30" lado a lado num bloco só (2016): cada marcador fica na sua coluna
            if len(corpo) > 1 and all(re.fullmatch(r"\s*Quest[ãa]o\s+\d{1,2}\s*", t) for _, t in corpo):
                for bb, t in corpo:
                    bruto.append({"tipo": "texto", "texto": t.strip(), "pag": pn, "bbox": tuple(bb)})
                continue
            txt = RE_CABECALHO_ANTIGO.sub("", juntar_linhas(corpo, margem)).strip()
            # capa dos cadernos antigos: linhas pontilhadas para o nome do candidato
            if re.fullmatch(r"[.\s_]*", txt):
                continue
            x0 = min(bb[0] for bb, _ in corpo)
            y0 = min(bb[1] for bb, _ in corpo)
            x1 = max(bb[2] for bb, _ in corpo)
            y1 = max(bb[3] for bb, _ in corpo)
            b = (x0, y0, x1, y1, txt)
            if not txt:
                continue
            if re.search(r"L[ÍI]NGUA (INGLESA|ESPANHOLA)", txt, re.I) and len(txt) < 40 and not re.search(r"Quest[ãa]o\s+\d", txt):
                bruto.append({"tipo": "secao", "texto": txt.upper(), "pag": pn, "bbox": b[:4]})
                continue
            # cadernos antigos: "LÍNGUA ESPANHOLA / Questões de 41 a 48" no topo do bloco,
            # às vezes seguido do texto de apoio ou da Questão 41 no mesmo bloco
            m_sec = re.match(r"\s*(L[ÍI]NGUA (?:INGLESA|ESPANHOLA))\s*(?:Quest[õo]es\s+(?:de\s+)?\d+\s+a\s+\d+)?\s*", txt, re.I)
            if m_sec:
                bruto.append({"tipo": "secao", "texto": m_sec.group(1).upper(), "pag": pn, "bbox": (b[0], b[1] - 0.02, b[2], b[3])})
                txt = txt[m_sec.end():].strip()
                if not txt:
                    continue
                b = (x0, y0, x1, y1, txt)
            if eh_moldura(b[:4], h, txt):
                # "CIÊNCIAS HUMANAS ... Questão 21": o marcador vem colado ao cabeçalho
                m = re.search(r"Quest[ãa]o\s+\d{1,2}.*", txt, re.I | re.S)
                if m:
                    bruto.append({"tipo": "texto", "texto": m.group(0), "pag": pn, "bbox": b[:4]})
                continue
            # "e) 39 / Questão 51" ou "CIÊNCIAS HUMANAS... / Questão 21" no mesmo bloco: separa no marcador
            # nos cadernos antigos o marcador pode vir colado ao fim da linha cheia anterior
            # ("...no nível 4. Questão 03 Sabendo-se"): depois de pontuação, "Questão NN" maiúsculo também separa
            pedacos = [x for x in re.split(r"\n(?=\s*Quest[ãa]o\s+\d{1,2}\b)|(?<=[.!?:)\]”\"])[ \t]+(?=Questão\s+\d{2}\b)", txt) if x.strip()]
            if LAYOUT.colunas == 2:
                # "e) occasionally. Para responder às questões 44 e 45, ...": a instrução do próximo
                # texto de apoio vem colada à última alternativa; separa para não virar parte da E
                pedacos = [
                    y for x in pedacos for y in re.split(
                        r"(?<=[.!?”])\s+(?=(?:Considere|Leia|Para responder|Analise|Observe|Text to|Texto para)\b[^.]{0,140}?(?:quest|cuest))", x
                    ) if y.strip()
                ]
            for k, pedaco in enumerate(pedacos):
                if k == 0 and len(pedacos) > 1 and RE_CABECALHO.match(pedaco.strip()):
                    continue
                # ordem preservada pelo desempate em y (fração de ponto por pedaço)
                bruto.append({"tipo": "texto", "texto": pedaco.strip(), "pag": pn, "bbox": (b[0], b[1] + k * 0.01, b[2], b[3])})
        for im in pag.get_image_info():
            x0, y0, x1, y1 = im["bbox"]
            if eh_moldura(im["bbox"], h) or (x1 - x0) < 60 or (y1 - y0) < 40:
                continue
            # faixas cinzas atrás do "Questão NN" são imagens largas e baixas
            if (y1 - y0) < 45 and x0 < 30:
                continue
            bruto.append({"tipo": "imagem", "pag": pn, "bbox": (x0, y0, x1, y1)})
        if LAYOUT.colunas == 2:
            bruto = ordenar_duas_colunas(bruto, w)
        else:
            bruto.sort(key=lambda it: (round(it["bbox"][1]), it["bbox"][0]))
        itens.extend(bruto)
    return itens


def separar_alternativas(texto: str) -> tuple[str, list[str]] | None:
    """Divide 'comando a) ... b) ... e) ...' em (comando, [A..E])."""
    marcas = [m for m in RE_ALT.finditer(texto)]
    # pega a última sequência a,b,c,d,e em ordem
    for i in range(len(marcas) - 4, -1, -1):
        seq = marcas[i : i + 5]
        if [m.group(1) for m in seq] == list("abcde"):
            comando = texto[: seq[0].start()].strip()
            alts = []
            for j, m in enumerate(seq):
                fim = seq[j + 1].start() if j < 4 else len(texto)
                alts.append(plano(texto[m.end() : fim]))
            return comando, alts
    return None


def numeros_citados(texto: str) -> list[int]:
    nums: list[int] = []
    for m in RE_FAIXA.finditer(texto):
        partes = [int(m.group(1))] + [int(x) for x in re.findall(r"\d{1,2}", m.group(2) or "")]
        trecho = m.group(0)
        if len(partes) == 2 and re.search(r"\d\s*(?:a|to|-|–)\s*\d", trecho):
            nums.extend(range(partes[0], partes[1] + 1))
        else:
            nums.extend(partes)
    return sorted(set(n for n in nums if 1 <= n <= LAYOUT.total))


def ler_gabarito(caminho: Path) -> dict[str, str]:
    """Retorna {'01': 'D', ..., '16-en': 'C', '16-es': 'A', ...}. '*' = anulada.

    Nas línguas, a primeira coluna do gabarito é Inglês nos cadernos atuais e Espanhol nos de
    2014/2015 (onde as duas respostas vêm na mesma linha: "42 C B" = Espanhol C, Inglês B).
    """
    # gabarito transcrito e conferido à mão (PDF que a leitura automática embaralha)
    manual = RAIZ / "scripts" / "provas" / "gabaritos" / caminho.name.replace("gabarito_", "paes-").replace(".pdf", ".json")
    if manual.exists():
        return {k: v for k, v in json.loads(manual.read_text(encoding="utf-8")).items() if not k.startswith("_")}
    doc = pymupdf.open(caminho)
    texto = "\n".join(p.get_text("text", sort=True) for p in doc)
    pares = re.findall(r"\b(\d{1,2})\s+([A-E]|\*|X|ANULADA|NULA|[Nn]ula)\b(?:[ \t]+([A-E]|\*)\b)?", texto)
    primeira, segunda = ("es", "en") if LAYOUT.gabarito_es_primeiro else ("en", "es")
    gab: dict[str, str] = {}
    for num, letra, letra2 in pares:
        n = int(num)
        if not 1 <= n <= LAYOUT.total:
            continue
        if LAYOUT.eh_lingua(n):
            chave = f"{n:02d}-{primeira}" if f"{n:02d}-{primeira}" not in gab else f"{n:02d}-{segunda}"
            if letra2 and chave.endswith(primeira):
                gab[f"{n:02d}-{segunda}"] = letra2 if letra2 in ("A", "B", "C", "D", "E") else "*"
            if chave in gab:
                continue
        else:
            chave = f"{n:02d}"
            if chave in gab:
                continue
        gab[chave] = letra if letra in ("A", "B", "C", "D", "E") else "*"
    return gab


RE_TITULO_SECAO = re.compile(
    r"[A-ZÁÉÍÓÚÂÊÔÃÕÇ ,]{4,80}\s*Quest[õo]es\s+(?:de\s+)?\d{1,2}\s+a\s+\d{1,2}|Quest[õo]es\s+(?:de\s+)?\d{1,2}\s+a\s+\d{1,2}"
)

RE_LINHA_DE_CREDITO = re.compile(
    r"(Acesso\s+em:|S[ãa]o Paulo:|Rio de Janeiro:|Bras[íi]lia:|Porto Alegre:|Petr[óo]polis:|Bauru|"
    r"\b(?:Abril|Editora|[ÁA]tica|Saraiva|Moderna|Globo|Ediouro|Edusp|Zahar|Cortez|Contexto|Scipione)\b[^\n]*\d{4}|"
    r"\.html?>|\.br/?>|\.com/?>)"
)


def mover_creditos(texto: str, creditos: list[str]) -> tuple[str, list[str]]:
    """Cadernos 2014-2016: a 2ª linha da referência ("São Paulo: Abril, 2013.") vem no corpo do
    texto, no meio do enunciado. Linha curta com cara de referência volta para o último crédito."""
    if not creditos:
        return texto, creditos
    creditos = list(creditos)
    linhas_ok = []
    for linha in texto.split("\n"):
        l = linha.strip()
        curta_com_ano = len(l) < 45 and re.search(r",\s*\d{4}\.?\s*(\((?:a|A)daptado\)\.?)?$", l)
        if l and len(l) < 110 and not l.startswith("[[") and (RE_LINHA_DE_CREDITO.search(l) or curta_com_ano) and not re.search(r"[?:]$", l):
            creditos[-1] = creditos[-1].rstrip() + " " + l
            continue
        linhas_ok.append(linha)
    return re.sub(r"\n{3,}", "\n\n", "\n".join(linhas_ok)).strip(), creditos


def juntar_creditos(itens: list[dict]) -> list[str]:
    """Agrupa linhas de legenda/referência por coluna (legendas lado a lado não se misturam)."""
    if not itens:
        return []
    grupos: dict[tuple[int, int], list[dict]] = {}
    for it in itens:
        grupos.setdefault((it["pag"], it["coluna"]), []).append(it)
    saida = []
    for chave in sorted(grupos):
        linhas = sorted(grupos[chave], key=lambda it: it["bbox"][1])
        # linhas próximas formam um crédito só; salto grande separa
        atual: list[str] = []
        ultimo_y = None
        for it in linhas:
            if ultimo_y is not None and it["bbox"][1] - ultimo_y > 14:
                saida.append(limpar("\n".join(atual)))
                atual = []
            atual.append(it["texto"])
            ultimo_y = it["bbox"][3]
        if atual:
            saida.append(limpar("\n".join(atual)))
    return [s for s in saida if s]


def recortar(doc, pag: int, bbox, destino: Path) -> str:
    destino.parent.mkdir(parents=True, exist_ok=True)
    clip = pymupdf.Rect(bbox) + (-4, -4, 4, 4)
    pix = doc[pag].get_pixmap(clip=clip, dpi=160)
    # WebP: ~5x menor que PNG com a mesma nitidez (as figuras vão para a CDN do site)
    destino = destino.with_suffix(".webp")
    Image.frombytes("RGB", (pix.width, pix.height), pix.samples).save(destino, "WEBP", quality=82, method=6)
    return destino.relative_to(RAIZ / "data").as_posix()


def aplicar_revisao(ano: int, questoes: list[dict], textos: list[dict] | None = None) -> None:
    """Aplica correções feitas à mão (fórmulas, frações) de conteudo/revisao/paes-<ano>.json.

    Formato: {"paes-2025-43": {"alternativas": [...5...], "enunciado": "...",
              "substituir": [["de", "para"]], "nota": "quem conferiu e como"}}
    """
    arq = RAIZ / "scripts" / "provas" / "revisao" / f"paes-{ano}.json"
    if not arq.exists():
        return
    revisao = json.loads(arq.read_text(encoding="utf-8"))
    por_id = {q["id"]: q for q in questoes}
    por_codigo = {t["codigo"]: t for t in (textos or [])}
    for qid, corr in revisao.items():
        if qid.startswith("texto:"):
            # texto de apoio: "texto:t02": {"conteudo": "...", "creditos": [...]}
            t = por_codigo.get(qid.split(":", 1)[1])
            if t is None:
                raise KeyError(f"revisão aponta para texto inexistente: {qid}")
            for chave in ("conteudo", "creditos"):
                if chave in corr:
                    t[chave] = corr[chave]
            continue
        q = por_id.get(qid)
        if q is None:
            raise KeyError(f"revisão aponta para questão inexistente: {qid}")
        for de, para in corr.get("substituir", []):
            # espaço no trecho casa com qualquer espaço ou quebra de linha do texto extraído
            padrao = r"\s+".join(re.escape(p) for p in de.split())
            q["enunciado"], n = re.subn(padrao, lambda _: para, q["enunciado"])
            if n == 0:
                raise ValueError(f"{qid}: trecho a substituir não encontrado: {de!r}")
        if "enunciado" in corr:
            q["enunciado"] = corr["enunciado"]
        if "tabelas" in corr:
            q["tabelas"] = corr["tabelas"]
        if "alternativas" in corr:
            if len(corr["alternativas"]) != 5:
                raise ValueError(f"{qid}: revisão precisa de 5 alternativas")
            q["alternativas"] = corr["alternativas"]
        if "gabarito" in corr:
            # só para letra que o PDF do gabarito não deixa ler (ex.: 2015, Inglês 41)
            if corr["gabarito"] not in ("A", "B", "C", "D", "E"):
                raise ValueError(f"{qid}: gabarito inválido na revisão")
            q["gabarito"], q["anulada"] = corr["gabarito"], False
        if "disciplina" in corr:
            q["disciplina"] = corr["disciplina"]
        if "creditos" in corr:
            q["creditos"] = corr["creditos"]
        if "figuras" in corr:
            # figura que a leitura em colunas ligou à questão vizinha (ex.: mapa ao lado de outra questão)
            q["figuras"] = [{"caminho": c} for c in corr["figuras"]]
        if "texto_base" in corr:
            q["texto_base"] = corr["texto_base"]
        q["revisao_manual"] = corr.get("nota", "corrigida à mão")
        q["conferida_visualmente"] = bool(corr.get("conferida", False))


def extrair(ano: int) -> dict:
    global LAYOUT
    LAYOUT = LAYOUTS.get(ano, LAYOUT_ATUAL)
    pdf = RAIZ / "data" / "provas" / f"paes_{ano}.pdf"
    doc = pymupdf.open(pdf)
    itens = ler_blocos(doc)
    gabarito = ler_gabarito(RAIZ / "data" / "gabaritos" / f"gabarito_{ano}.pdf")
    pasta_fig = RAIZ / "data" / "figuras" / str(ano)

    questoes: list[dict] = []
    textos: list[dict] = []
    pendente: list[dict] = []  # blocos soltos entre uma questão e a próxima
    atual: dict | None = None
    lingua: str | None = None
    n_fig = 0

    def fechar_pendente_em_texto() -> None:
        nonlocal pendente
        if not pendente:
            return
        partes, tabelas = [], []
        # título de seção ("LÍNGUA PORTUGUESA ... Questões de 49 a 56") não é texto de apoio
        pendente = [
            b for b in pendente
            if not (b["tipo"] == "texto" and RE_TITULO_SECAO.fullmatch(b["texto"].strip()))
        ]
        for b in pendente:
            if b["tipo"] == "texto":
                # título de seção colado no começo do texto de apoio
                partes.append(re.sub(r"^\s*[A-ZÁÉÍÓÚÂÊÔÃÕÇ ,]{4,80}\n\s*Quest[õo]es\s+(?:de\s+)?\d{1,2}\s+a\s+\d{1,2}\s*\n", "", b["texto"]))
            elif b["tipo"] == "tabela":
                tabelas.append(b["texto"])
                partes.append(f"[[TABELA {len(tabelas)}]]")
            elif b["tipo"] == "imagem":
                partes.append(f"[[FIGURA {sum(x['tipo'] == 'imagem' for x in pendente[: pendente.index(b) + 1])}]]")
        figs = [b for b in pendente if b["tipo"] == "imagem"]
        creds = [b for b in pendente if b["tipo"] == "credito"]
        # fragmento solto (rótulo de figura, número de página) não é texto de apoio
        if not figs and len(plano(" ".join(p for p in partes if not p.startswith("[[")))) < 40:
            pendente = []
            return
        if partes or figs:
            textos.append(
                {"blocos": partes, "tabelas": tabelas, "figuras_bruto": figs, "creditos_bruto": creds, "pag": pendente[0]["pag"]}
            )
        pendente = []

    def finalizar(q: dict | None) -> None:
        if not q:
            return
        corpo = limpar("\n\n".join(q["partes"]))
        sep = separar_alternativas(corpo)
        q["corpo"] = corpo
        q["sep"] = sep

    for it in itens:
        if it["tipo"] == "secao":
            lingua = "en" if "INGLESA" in it["texto"] else "es"
            continue
        if it["tipo"] == "texto":
            m = RE_QUESTAO.match(it["texto"])
            if m:
                # texto colado depois do marcador (ex.: "CIÊNCIAS HUMANAS ... Questão 21")
                finalizar(atual)
                fechar_pendente_em_texto()
                numero = int(m.group(1))
                resto = it["texto"][m.end() :].strip()
                lg = lingua if LAYOUT.eh_lingua(numero) else None
                if numero > LAYOUT.lingua_fim:
                    lingua = None
                atual = {
                    "numero": numero,
                    "lingua": lg,
                    "partes": [resto] if resto else [],
                    "figuras_bruto": [],
                    "pag": it["pag"],
                    "texto_idx": len(textos) - 1 if textos else None,
                }
                questoes.append(atual)
                continue
            if re.search(r"L[ÍI]NGUA (INGLESA|ESPANHOLA)", it["texto"]) and len(it["texto"]) < 40:
                lingua = "en" if "INGLESA" in it["texto"].upper() else "es"
                finalizar(atual)
                atual = None
                continue
        # bloco comum: se a questão atual já tem as 5 alternativas, o bloco é do próximo texto de apoio
        if atual is not None:
            corpo_atual = limpar("\n\n".join(atual["partes"]))
            sep = separar_alternativas(corpo_atual)
            alternativas_completas = sep is not None and len(sep[1][4]) > 0
            if not alternativas_completas:
                if it["tipo"] == "texto":
                    atual["partes"].append(it["texto"])
                elif it["tipo"] == "tabela":
                    atual.setdefault("tabelas", []).append(it["texto"])
                    atual["partes"].append(f"[[TABELA {len(atual['tabelas'])}]]")
                elif it["tipo"] == "credito":
                    atual.setdefault("creditos_bruto", []).append(it)
                else:
                    atual["figuras_bruto"].append(it)
                    # marca onde a figura fica no texto (o app mostra a imagem nesse ponto)
                    atual["partes"].append(f"[[FIGURA {len(atual['figuras_bruto'])}]]")
                continue
            if it["tipo"] == "credito" and not pendente:
                # referência logo abaixo das alternativas ainda é da questão (ex.: fonte de tabela)
                atual.setdefault("creditos_bruto", []).append(it)
                continue
            # continuação da alternativa E na linha de baixo (texto curto, minúsculo no início)
            if it["tipo"] == "texto" and re.match(r"^[a-zà-ú0-9(“\"]", it["texto"]) and len(it["texto"]) < 160 and not pendente:
                atual["partes"].append(it["texto"])
                continue
            # cadernos 2014-2016: alternativa E cortada na virada de coluna ("Presidente Juscelino,")
            if (
                LAYOUT.colunas == 2 and it["tipo"] == "texto" and not pendente
                and re.search(r"[,a-zà-ú-]$", sep[1][4].rstrip()) and not RE_QUESTAO.match(it["texto"])
            ):
                # o pedaço pode trazer colado o título da próxima seção ("HISTÓRIA / Questões de 33 a 40")
                m_tit = re.search(r"\n[A-ZÁÉÍÓÚÂÊÔÃÕÇ ,]{4,80}\n\s*Quest[õo]es\s", it["texto"])
                atual["partes"].append(it["texto"][: m_tit.start()] if m_tit else it["texto"])
                continue
            finalizar(atual)
            atual = None
        pendente.append(it)
    finalizar(atual)

    # monta textos de apoio e liga às questões
    saida_textos: list[dict] = []
    ligacao: dict[tuple[int, str | None], str] = {}
    for i, t in enumerate(textos):
        conteudo = limpar("\n\n".join(t["blocos"]))
        codigo = f"t{i + 1:02d}"
        figs = []
        for f in t["figuras_bruto"]:
            n_fig += 1
            figs.append({"caminho": recortar(doc, f["pag"], f["bbox"], pasta_fig / f"{codigo}_fig{n_fig}.png")})
        citadas = numeros_citados(conteudo[:600])
        saida_textos.append(
            {
                "codigo": codigo,
                "conteudo": conteudo,
                "tabelas": t.get("tabelas", []),
                "creditos": juntar_creditos(t.get("creditos_bruto", [])),
                "figuras": figs,
                "citadas": citadas,
                "pagina": t["pag"] + 1,
            }
        )

    # Quem usa cada texto:
    # - se o texto cita as questões ("questões de 01 a 06"), vale para elas, a partir da primeira que vem depois dele;
    # - se não cita, vale para as questões até o próximo texto de apoio.
    # Um texto posterior (ex.: "Texto II") substitui o anterior a partir de onde aparece.
    for q in questoes:
        q["texto_codigo"] = None
    for i, t in enumerate(saida_textos):
        seguintes = [q for q in questoes if q["texto_idx"] == i]
        if not seguintes:
            continue
        primeira = seguintes[0]
        if t["citadas"]:
            ini = questoes.index(primeira)
            for q in questoes[ini:]:
                mesma_lingua = (q["lingua"] == primeira["lingua"]) if LAYOUT.eh_lingua(q["numero"]) else True
                if q["numero"] in t["citadas"] and mesma_lingua:
                    q["texto_codigo"] = t["codigo"]
                elif q["numero"] > max(t["citadas"]) or not mesma_lingua:
                    break
        else:
            # vale para a primeira; continua só enquanto a questão seguinte não traz texto próprio
            for j, q in enumerate(seguintes):
                comando = q["sep"][0] if q.get("sep") else q.get("corpo", "")
                if j > 0 and len(comando) > 400:
                    break
                if q["lingua"] != primeira["lingua"]:
                    break  # texto em espanhol não serve à seção de inglês (e vice-versa)
                q["texto_codigo"] = t["codigo"]

    saida_questoes = []
    for q in questoes:
        area, disciplina = area_disciplina(q["numero"], q["lingua"])
        chave = f"{q['numero']:02d}" + (f"-{q['lingua']}" if q["lingua"] else "")
        letra = gabarito.get(chave)
        figs = []
        for f in q["figuras_bruto"]:
            n_fig += 1
            figs.append({"caminho": recortar(doc, f["pag"], f["bbox"], pasta_fig / f"q{chave}_fig{n_fig}.png")})
        sep = q["sep"]
        saida_questoes.append(
            {
                "id": f"paes-{ano}-{chave}",
                "numero": q["numero"],
                "lingua": q["lingua"],
                "area": area,
                "disciplina": disciplina,
                "texto_base": q["texto_codigo"],
                "enunciado": sep[0] if sep else q["corpo"],
                "alternativas": sep[1] if sep else [],
                "gabarito": letra if letra in ("A", "B", "C", "D", "E") else None,
                "anulada": letra == "*",
                "figuras": figs,
                "tabelas": q.get("tabelas", []),
                "creditos": juntar_creditos(q.get("creditos_bruto", [])),
                "pagina_pdf": q["pag"] + 1,
            }
        )

    if LAYOUT.colunas == 2:
        for q in saida_questoes:
            q["enunciado"], q["creditos"] = mover_creditos(q["enunciado"], q["creditos"])
            # figura/tabela que caiu dentro de uma alternativa (figura ao lado das alternativas) volta ao enunciado
            for i, alt in enumerate(q["alternativas"]):
                marcas = re.findall(r"\[\[(?:FIGURA|TABELA) \d+\]\]", alt)
                if marcas:
                    q["alternativas"][i] = plano(re.sub(r"\[\[(?:FIGURA|TABELA) \d+\]\]", " ", alt))
                    q["enunciado"] = q["enunciado"].rstrip() + "\n\n" + "\n\n".join(marcas)
        for t in saida_textos:
            t["conteudo"], t["creditos"] = mover_creditos(t["conteudo"], t["creditos"])
    aplicar_revisao(ano, saida_questoes, saida_textos)
    usados = {q["texto_base"] for q in saida_questoes if q["texto_base"]}
    return {
        "prova": {"id": f"paes-{ano}", "ano": ano},
        "textos_base": [
            {k: v for k, v in t.items() if k != "citadas"} for t in saida_textos if t["codigo"] in usados
        ],
        "questoes": saida_questoes,
        "gabarito_bruto": gabarito,
    }


if __name__ == "__main__":
    ano = int(sys.argv[1])
    dados = extrair(ano)
    destino = RAIZ / "data" / "provas_oficiais" / f"paes-{ano}.json"
    destino.write_text(json.dumps(dados, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"{len(dados['questoes'])} questões, {len(dados['textos_base'])} textos de apoio -> {destino}")
