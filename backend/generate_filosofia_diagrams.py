# -*- coding: utf-8 -*-
"""Gera diagramas para Filosofia — topicos 10.1 a 10.7."""

from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

IMG_DIR = Path(__file__).resolve().parent.parent / "data" / "materiais" / "imagens"
IMG_DIR.mkdir(parents=True, exist_ok=True)
FONT = "C:/Windows/Fonts/arial.ttf"
FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"

def font(size, bold=False):
    try:
        return ImageFont.truetype(FONT_BOLD if bold else FONT, size)
    except:
        return ImageFont.load_default()

def save(name, fn, w=1000, h=700):
    out = IMG_DIR / f"{name}.png"
    img = Image.new("RGB", (w, h), "white")
    d = ImageDraw.Draw(img)
    fn(d, w, h)
    img.save(out, "PNG")
    print(f"  {out}")
    return out

def header(d, w, title, sub=""):
    d.rectangle([(0, 0), (w, 60)], fill="#5E35B1")
    d.text((20, 15), title, fill="white", font=font(26, bold=True))
    if sub:
        d.text((20, 80), sub, fill="#5E35B1", font=font(18))

def box(d, x, y, w, h, title, items, color="#EDE7F6", border="#5E35B1"):
    d.rectangle([(x, y), (x+w, y+h)], fill=color, outline=border, width=3)
    d.text((x+10, y+8), title, fill="#1A1A2E", font=font(18, bold=True))
    for i, item in enumerate(items):
        d.text((x+15, y+35+i*22), f"- {item}", fill="#1A1A2E", font=font(15))

def draw_cultura(d, w, h):
    header(d, w, "Cultura: Natureza e Simbolo", "Atividade humana, trabalho e sagrado")
    box(d, 30, 100, 300, 200, "NATUREZA E CULTURA",
        ["Natureza: o dado, o natural", "Cultura: o construido",
         "Tabu do incesto: universal", "Linguagem: marca cultural",
         "Cultura = segunda natureza"], color="#E8F5E9", border="#4CAF50")
    box(d, 350, 100, 300, 200, "SENTIDOS DE CULTURA",
        ["Antropologico: modo de vida", "Estetico: belles-artes",
         "Sociologico: valores e normas", "Filosofico: formacao",
         "Cultura popular x erudita"], color="#FFF3E0", border="#FF9800")
    box(d, 670, 100, 300, 200, "CULTURA E TRABALHO",
        ["Trabalho transforma natureza", "Marx: trabalho alienado",
         "Cultura material e imaterial", "Tecnica e cultura",
         "Lazer e cultura"], color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 460, 180, "RELIGIOSIDADE E SAGRADO",
        ["Durkheim: profano x sagrado", "Mito e rito",
         "Tabu, totem, sacrificio", "Religiao: fato social",
         "Secularizacao: modernidade"], color="#F3E5F5", border="#7B1FA2")
    box(d, 510, 320, 460, 180, "A MORTE",
        ["Morte: universal e cultural", "Rituais funerarios",
         "Morte no ocidente", "Elisabeth Kubler-Ross",
         "Fases: negacao, raiva, barganha, depressao, aceitacao"],
        color="#FFEBEE", border="#C62828")
    d.text((250, 540), "Cultura: ordem simbolica que organiza a vida humana", fill="#5E35B1", font=font(18, bold=True))
    d.text((300, 580), "Natureza -> Trabalho -> Cultura -> Simbolo", fill="#1A1A2E", font=font(20, bold=True))
    d.text((350, 630), "O ser humano e um ser cultural", fill="#5E35B1", font=font(16))

def draw_conhecimento(d, w, h):
    header(d, w, "Conhecimento e Verdade", "Ciencia, epistemologia e ideologia")
    box(d, 30, 100, 300, 200, "TIPOS DE CONHECIMENTO",
        ["Senso comum: cotidiano", "Religioso: fe, tradicao",
         "Filosofico: reflexao racional", "Cientifico: metodo",
         "Artistico: intuicao, sensibilidade"], color="#EDE7F6", border="#5E35B1")
    box(d, 350, 100, 300, 200, "CORRENTES EPISTEMOLOGICAS",
        ["Empirismo: experiencia", "Racionalismo: razao",
         "Positivismo: fato observavel", "Falsificabilidade: Popper",
         "Paradigmas: Kuhn"], color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "VERDADE E METODO",
        ["Verdade como correspondencia", "Verdade como coerencia",
         "Verdade como utilidade", "Hermeneutica: interpretacao",
         "Gadamer: pre-conceito"], color="#FFF3E0", border="#FF9800")
    box(d, 30, 320, 460, 180, "O QUE E CIENCIA",
        ["Metodo cientifico: hipotese", "Observacao e experimentacao",
         "Replicabilidade", "Objetividade",
         "Ciencia normal x revolucionaria", "Pseudociencia"],
        color="#E8F5E9", border="#4CAF50")
    box(d, 510, 320, 460, 180, "LINGUAGEM E IDEOLOGIA",
        ["Linguagem e pensamento", "Wittgenstein: jogos de linguagem",
         "Ideologia: falsa consciencia", "Marx: ideologia dominante",
         "Althusser: aparelhos ideologicos"], color="#FFEBEE", border="#C62828")
    d.text((200, 540), "Conhecimento: do senso comum a ciencia", fill="#5E35B1", font=font(18, bold=True))
    d.text((250, 580), "Verdade nao e absoluta: depende do metodo", fill="#1A1A2E", font=font(16))

def draw_filosofia(d, w, h):
    header(d, w, "A Filosofia: Origem e Periodos", "Atitude filosofica e reflexao")
    # Linha do tempo
    d.line([(30, 250), (970, 250)], fill="#5E35B1", width=4)
    periodos = [
        (80, "Sec VI a.C.", "Origem (Grecia)"),
        (220, "Sec V-XV", "Patristica/Escolastica"),
        (400, "Sec XV-XVI", "Renascimento"),
        (560, "Sec XVII-XVIII", "Modernidade"),
        (720, "Sec XIX", "Contemporanea"),
        (900, "Sec XX-XXI", "Pos-moderna"),
    ]
    for x, data, ev in periodos:
        d.ellipse([(x-8, 250-8), (x+8, 250+8)], fill="#5E35B1", outline="black", width=2)
        d.text((x-40, 265), data, fill="#5E35B1", font=font(14, bold=True))
        d.text((x-50, 285), ev, fill="#1A1A2E", font=font(13))
    box(d, 30, 100, 460, 130, "ATITUDE FILOSOFICA",
        ["Perguntar: o que e isto?", "Espanto, admiracao (Platao)",
         "Duvida metodica (Descartes)", "Critica do senso comum",
         "Pensar por si mesmo"], color="#EDE7F6", border="#5E35B1")
    box(d, 510, 100, 460, 130, "ORIGEM DA FILOSOFIA",
        ["Grecia Antiga (sec VI a.C.)", "Tales, Anaximandro",
         "Passagem do mito ao logos", "Cosmos ordenado por razao",
         "Polis: espaco de debate"], color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 460, 180, "FILOSOFIA ANTIGA",
        ["Socrates: maiêutica", "Platao: teoria das ideias",
         "Aristoteles: logica, etica", "Estoicos: virtude",
         "Epicuristas: prazer moderado"], color="#FFF3E0", border="#FF9800")
    box(d, 510, 320, 460, 180, "FILOSOFIA MODERNA E CONTEMPORANEA",
        ["Descartes: penso logo existo", "Kant: criticismo",
         "Hegel: dialetica", "Nietzsche: critica da moral",
         "Existencialismo: Sartre", "Escola de Frankfurt"],
        color="#F3E5F5", border="#7B1FA2")
    d.text((200, 540), "Filosofia: do espanto a reflexao critica", fill="#5E35B1", font=font(18, bold=True))

def draw_logica(d, w, h):
    header(d, w, "Logica: Argumentacao e Silogismo", "Principios e logica simbolica")
    box(d, 30, 100, 300, 200, "PRINCIPIOS DA LOGICA",
        ["Identidade: A = A", "Nao-contradicao: A != nao-A",
         "Terceiro excluido: A ou nao-A", "Razao suficiente",
         "Leis do pensamento"], color="#EDE7F6", border="#5E35B1")
    box(d, 350, 100, 300, 200, "TIPOS DE ARGUMENTACAO",
        ["Dedução: geral -> particular", "Indução: particular -> geral",
         "Abdução: hipotese explicativa", "Analogia: comparacao",
         "Silogismo: premisa + conclusao"], color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "LOGICA SIMBOLICA",
        ["Proposicoes: p, q", "Conectivos: E, OU, ->, <->",
         "Tabela verdade", "Modus ponens", "Modus tollens"],
        color="#FFF3E0", border="#FF9800")
    # Silogismo exemplo
    d.rectangle([(30, 320), (970, 480)], fill="#F3E5F5", outline="#7B1FA2", width=3)
    d.text((50, 335), "EXEMPLO DE SILOGISMO", fill="#7B1FA2", font=font(20, bold=True))
    d.text((50, 370), "Premissa maior: Todos os homens sao mortais.", fill="#1A1A2E", font=font(18))
    d.text((50, 400), "Premissa menor: Socrates e homem.", fill="#1A1A2E", font=font(18))
    d.text((50, 430), "Conclusao: Logo, Socrates e mortal.", fill="#C62828", font=font(18, bold=True))
    d.text((50, 460), "Estrutura: medio termo (homem) conecta maior e menor.", fill="#5E35B1", font=font(15))
    box(d, 30, 500, 940, 100, "TERMO E PROPOSICAO",
        ["Termo: sujeito ou predicado", "Proposicao: declarativa, V ou F",
         "Tipos: universal, particular, afirmativa, negativa",
         "Quadrado logico: A, E, I, O"], color="#E8F5E9", border="#4CAF50")
    d.text((250, 630), "Logica: ferramenta do pensamento racional", fill="#5E35B1", font=font(16, bold=True))

def draw_estetica(d, w, h):
    header(d, w, "Estetica: O Belo e a Arte", "Gosto, industria cultural e tecnica")
    box(d, 30, 100, 300, 200, "CONCEITO DE ESTETICA",
        ["Estetica: estudo do belo", "Baumgarten: ciencia do sensivel",
         "Kant: juizo estetico", "Belo livre x aderente",
         "Sublime: Kant, Burke"], color="#EDE7F6", border="#5E35B1")
    box(d, 350, 100, 300, 200, "O BELO E O FEIO",
        ["Belo: harmonia, proporcao", "Feio: desarmonia",
         "Grotesco: exagero do feio", "Belo classico x romantico",
         "Relatividade do gosto"], color="#FFF3E0", border="#FF9800")
    box(d, 670, 100, 300, 200, "A QUESTAO DO GOSTO",
        ["Gosto: subjetivo mas comunicavel", "Kant: senso comum",
         "Bourdieu: distincao social", "Gosto de classe",
         "Moda e consumo"], color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 460, 180, "ARTE, RELIGIAO E TECNICA",
        ["Arte e religiao: o sagrado", "Iconoclastia",
         "Arte e tecnica: Benjamin", "Reprodutibilidade tecnica",
         "Aura: originalidade perdida"], color="#F3E5F5", border="#7B1FA2")
    box(d, 510, 320, 460, 180, "INDUSTRIA CULTURAL",
        ["Adorno e Horkheimer", "Cultura de massa: padronizada",
         "Falsa individualizacao", "Entretenimento: alienacao",
         "Cultura como mercadoria"], color="#FFEBEE", border="#C62828")
    d.text((200, 540), "Estetica: do belo classico a industria cultural", fill="#5E35B1", font=font(18, bold=True))
    d.text((300, 580), "O belo nao e absoluto: depende do contexto", fill="#1A1A2E", font=font(16))

def draw_politica(d, w, h):
    header(d, w, "Politica: Estado, Poder e Cidadania", "Totalitarismos e ideologias")
    box(d, 30, 100, 300, 200, "INVENCAO DA POLITICA",
        ["Grecia: polis, espaco publico", "Aristoteles: animal politico",
         "Publico x privado", "Democracia ateniense",
         "Republica romana"], color="#EDE7F6", border="#5E35B1")
    box(d, 350, 100, 300, 200, "FORCA E PODER",
        ["Poder: capacidade de agir", "Weber: dominacao legitima",
         "Tradicional, carismatica, legal", "Foucault: poder disperso",
         "Biopoder"], color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "ESTADO E TIPOS",
        ["Estado: monopolio da forca", "Liberal: minimo",
         "Social: intervencionista", "Welfare state",
         "Totalitario: partido unico"], color="#FFEBEE", border="#C62828")
    box(d, 30, 320, 460, 180, "IDEOLOGIAS POLITICAS",
        ["Republicanismo: bem comum", "Liberalismo: liberdade individual",
         "Socialismo: igualdade, coletivizacao", "Neoliberalismo: mercado",
         "Anarquismo: sem Estado"], color="#FFF3E0", border="#FF9800")
    box(d, 510, 320, 460, 180, "CIDADANIA E DEMOCRACIA",
        ["Cidadania: direitos civis, politicos, sociais",
         "Marshall: 3 dimensoes", "Democracia: direta, representativa",
         "Participativa, deliberativa", "Filosofia da tecnica"],
        color="#E8F5E9", border="#4CAF50")
    d.text((200, 540), "Politica: organizacao do poder na sociedade", fill="#5E35B1", font=font(18, bold=True))
    d.text((250, 580), "Estado: monopolio legitimo da forca fisica (Weber)", fill="#1A1A2E", font=font(16))

def draw_etica(d, w, h):
    header(d, w, "Etica: Valores, Dever e Liberdade", "Moral, direitos humanos e niilismo")
    box(d, 30, 100, 300, 200, "VALORES E NORMAS",
        ["Valores: o que e importante", "Normas: regras de conduta",
         "Etica: reflexao sobre a moral", "Moral: costumes",
         "Etica x moral: teoria x pratica"], color="#EDE7F6", border="#5E35B1")
    box(d, 350, 100, 300, 200, "O BEM E O MAL",
        ["Bem: o que e bom", "Mal: o que e mau",
         "Bem e mal relativos?", "Etica utilitarista: maior bem",
         "Etica deontologica: dever"], color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "DEVER E LIBERDADE",
        ["Kant: imperativo categorico", "Agir por dever",
         "Liberdade: autonomia", "Determinismo: causa e efeito",
         "Livre-arbitrio"], color="#FFF3E0", border="#FF9800")
    box(d, 30, 320, 460, 180, "DIREITOS HUMANOS E ECA",
        ["Direitos humanos: universais", "Declaracao 1948: ONU",
         "ECA: Estatuto da Crianca (1990)", "Direitos civis, politicos",
         "Sociais, economicos, culturais"], color="#E8F5E9", border="#4CAF50")
    box(d, 510, 320, 460, 180, "NIILISMO E POS-MODERNIDADE",
        ["Niilismo: Nietzsche, valores vazios", "Pos-verdade: fatos irrelevantes",
         "Pos-modernidade: fim das metanarrativas", "Relativismo etico",
         "Filosofia africana e oriental"], color="#F3E5F5", border="#7B1FA2")
    d.text((200, 540), "Etica: reflexao sobre como agir bem", fill="#5E35B1", font=font(18, bold=True))
    d.text((250, 580), "Imperativo categorico: age como se fosse lei universal", fill="#1A1A2E", font=font(16))

def main():
    funcs = [
        ("filo_cultura", draw_cultura),
        ("filo_conhecimento", draw_conhecimento),
        ("filo_filosofia", draw_filosofia),
        ("filo_logica", draw_logica),
        ("filo_estetica", draw_estetica),
        ("filo_politica", draw_politica),
        ("filo_etica", draw_etica),
    ]
    for name, fn in funcs:
        save(name, fn)
    print(f"\n{len(funcs)} diagramas gerados")

if __name__ == "__main__":
    main()
