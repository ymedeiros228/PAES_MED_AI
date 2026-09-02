"""Gera diagramas RICOS para Historia — topicos 8.1 a 8.6.

Cada diagrama tem 1000x700 pixels com multiplos elementos visuais:
mapas, linhas do tempo, piramides sociais, fluxogramas e cronologias.
"""

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
    except Exception:
        return ImageFont.load_default()


def save(diagram_name, draw_fn, w=1000, h=700):
    out = IMG_DIR / f"{diagram_name}.png"
    img = Image.new("RGB", (w, h), "white")
    d = ImageDraw.Draw(img)
    draw_fn(d, w, h)
    img.save(out, "PNG")
    print(f"  Diagrama: {out}")
    return out


def header(d, w, title, subtitle=""):
    d.rectangle([(0, 0), (w, 60)], fill="#0D7C66")
    d.text((20, 15), title, fill="white", font=font(26, bold=True))
    if subtitle:
        d.text((20, 80), subtitle, fill="#0D7C66", font=font(18))


def box(d, x, y, w, h, title, items, color="#E0F2F1", border="#0D7C66"):
    d.rectangle([(x, y), (x+w, y+h)], fill=color, outline=border, width=3)
    d.text((x+10, y+8), title, fill="#1A1A2E", font=font(18, bold=True))
    for i, item in enumerate(items):
        d.text((x+15, y+35+i*22), f"- {item}", fill="#1A1A2E", font=font(15))


def arrow_h(d, x1, y, x2, color="#F44336", width=3):
    d.line([(x1, y), (x2, y)], fill=color, width=width)
    d.polygon([(x2-10, y-6), (x2, y), (x2-10, y+6)], fill=color)


def arrow_v(d, x, y1, y2, color="#F44336", width=3):
    d.line([(x, y1), (x, y2)], fill=color, width=width)
    d.polygon([(x-6, y2-10), (x, y2), (x+6, y2-10)], fill=color)


# ============================================================
# 8.1 Mundo Antigo — mapa + cronologia + contribuicoes
# ============================================================
def draw_mundo_antigo(d, w, h):
    header(d, w, "Mundo Antigo: Civilizacoes e Contribuicoes",
           "Egito, Grecia, Roma e Reinos Africanos")

    # Mapa estilizado (Mediterraneo)
    d.rectangle([(30, 110), (480, 400)], fill="#BBDEFB", outline="#0D7C66", width=2)
    d.text((180, 115), "Mediterraneo", fill="#0D7C66", font=font(16, bold=True))
    # Europa
    d.polygon([(120, 130), (280, 130), (300, 200), (250, 230), (150, 220)],
              fill="#C8E6C9", outline="black", width=2)
    d.text((170, 160), "GRECIA", fill="#2196F3", font=font(14, bold=True))
    d.text((180, 180), "ROMA", fill="#FF9800", font=font(14, bold=True))
    # Africa
    d.polygon([(100, 250), (350, 250), (380, 380), (150, 390)],
              fill="#FFE0B2", outline="black", width=2)
    d.text((180, 270), "EGITO", fill="#FF5722", font=font(16, bold=True))
    d.text((160, 300), "NILO", fill="#1976D2", font=font(14, bold=True))
    d.line([(220, 290), (220, 380)], fill="#1976D2", width=3)
    d.text((250, 340), "REINOS", fill="#7B1FA2", font=font(14, bold=True))
    d.text((250, 360), "AFRICANOS", fill="#7B1FA2", font=font(14, bold=True))

    # Caixas de contribuicoes
    box(d, 510, 110, 460, 130, "EGITO E AFRICA",
        ["Papiro Edwin Smith: medicina", "Piramides e arquitetura",
         "Tombuctu: universidades", "Comercio transaariano",
         "Mansa Musa: imperio Mali"],
        color="#FFF3E0", border="#FF5722")

    box(d, 510, 260, 460, 130, "GRECIA",
        ["Democracia ateniense", "Filosofia: Socrates, Platao",
         "Medicina: Hipocrates", "Teatro: tragedia e comedia",
         "Olimpiadas"],
        color="#E3F2FD", border="#2196F3")

    # Roma
    box(d, 30, 420, 940, 130, "ROMA ANTIGA",
        ["Direito romano: base do direito ocidental",
         "Republica: Senado, consules, tribunos",
         "Arquitetura: arcos, aquedutos, Coliseu",
         "Latim: origem das linguas neolatinas",
         "Hospitais militares (valetudinaria)",
         "Cristianismo: surgiu no imperio, edito de Milao (313)"],
        color="#FFF8E1", border="#FF9800")

    # Linha do tempo
    d.line([(30, 580), (970, 580)], fill="#0D7C66", width=3)
    pontos = [(100, "3000 a.C.", "Egito"), (280, "500 a.C.", "Grecia"),
              (500, "509 a.C.", "Republica"), (700, "27 a.C.", "Imperio"),
              (900, "476", "Queda Roma")]
    for x, data, ev in pontos:
        d.ellipse([(x-7, 580-7), (x+7, 580+7)], fill="#F44336", outline="black", width=2)
        d.text((x-35, 595), data, fill="#F44336", font=font(14, bold=True))
        d.text((x-35, 615), ev, fill="#1A1A2E", font=font(13))
    d.text((300, 650), "Linha do tempo do Mundo Antigo", fill="#0D7C66", font=font(16, bold=True))


# ============================================================
# 8.2 Mundo Medieval — piramide social + feudalismo + religioes
# ============================================================
def draw_medieval(d, w, h):
    header(d, w, "Mundo Medieval: Feudalismo e Religioes",
           "Sociedade estamental, cristianismo e islamismo")

    # Piramide social (esquerda)
    d.text((30, 100), "Piramide Social Feudal", fill="#0D7C66", font=font(20, bold=True))
    # Rei
    d.polygon([(200, 130), (140, 200), (260, 200)], fill="#FFD700", outline="black", width=3)
    d.text((180, 155), "REI", fill="black", font=font(16, bold=True))
    # Nobreza
    d.rectangle([(120, 200), (280, 270)], fill="#BDBDBD", outline="black", width=3)
    d.text((135, 225), "NOBREZA", fill="black", font=font(16, bold=True))
    d.text((130, 245), "(guerrear)", fill="black", font=font(13))
    # Clero
    d.rectangle([(120, 270), (280, 340)], fill="#9FA8DA", outline="black", width=3)
    d.text((150, 295), "CLERO", fill="black", font=font(16, bold=True))
    d.text((130, 315), "(orar)", fill="black", font=font(13))
    # Servos
    d.rectangle([(80, 340), (320, 430)], fill="#8D6E63", outline="black", width=3)
    d.text((130, 370), "SERVOS", fill="white", font=font(16, bold=True))
    d.text((100, 395), "(trabalhar a terra)", fill="white", font=font(13))

    # Obligacoes dos servos (centro)
    box(d, 360, 110, 280, 180, "Obrigacoes do Servo",
        ["Corveia: trabalho gratuito",
         "Talha: parte da producao",
         "Banalidades: taxas (moinho)",
         "Dizimo: 10% para a Igreja",
         "Nao era escravo: livre,",
         "mas preso a terra"],
        color="#FFF3E0", border="#8D6E63")

    # Cristianismo (direita superior)
    box(d, 670, 110, 300, 180, "CRISTIANISMO MEDIEVAL",
        ["Igreja: maior poder da epoca",
         "Papa: autoridade maxima",
         "Cruzadas (1096-1291)",
         "Inquisicao: combate heresias",
         "Mosteiros: copia de livros",
         "Companhia de Jesus"],
        color="#E8EAF6", border="#3F51B5")

    # Islamismo (direita inferior)
    box(d, 670, 310, 300, 180, "ISLAMISMO",
        ["Fundador: Maome (570-632)",
         "Livro: Alcorao",
         "5 pilares: fe, oracao,",
         "  esmola, jejum, peregrinacao",
         "Avicena: Canon de Medicina",
         "Algebra, astronomia"],
        color="#E0F2F1", border="#00695C")

    # Decadencia (baixo)
    box(d, 30, 460, 940, 110, "DECADENCIA DO FEUDALISMO",
        ["Cruzadas reabriram rotas comerciais do Mediterraneo",
         "Renascimento comercial: cidades crescem, burguesia surge",
         "Peste Negra (1347-1351): 1/3 da populacao europeia morta",
         "Transicao: do feudalismo ao capitalismo comercial",
         "Monarquias nacionais se fortalecem"],
        color="#FFEBEE", border="#C62828")

    d.text((250, 590), "Feudalismo: poucos no topo, muitos na base", fill="#0D7C66", font=font(18, bold=True))
    d.text((200, 620), "Decadencia: cruzadas, comercio, peste negra", fill="#F44336", font=font(16))


# ============================================================
# 8.3 Idade Moderna — navegacoes + renascimento + reforma + iluminismo
# ============================================================
def draw_moderna(d, w, h):
    header(d, w, "Idade Moderna (1453-1789)",
           "Navegacoes, Renascimento, Reforma e Iluminismo")

    # Mapa de navegacoes
    d.text((30, 100), "Grandes Navegacoes", fill="#0D7C66", font=font(20, bold=True))
    # Europa
    d.rectangle([(60, 140), (220, 280)], fill="#C8E6C9", outline="black", width=2)
    d.text((100, 200), "EUROPA", fill="#1A1A2E", font=font(16, bold=True))
    d.text((80, 220), "Portugal", fill="#1565C0", font=font(14, bold=True))
    d.text((130, 240), "Espanha", fill="#C62828", font=font(14, bold=True))
    # America
    d.rectangle([(500, 160), (750, 380)], fill="#A5D6A7", outline="black", width=2)
    d.text((580, 250), "AMERICA", fill="#1A1A2E", font=font(18, bold=True))
    # Africa
    d.polygon([(250, 300), (450, 300), (470, 420), (230, 420)],
              fill="#FFE0B2", outline="black", width=2)
    d.text((320, 350), "AFRICA", fill="#1A1A2E", font=font(16, bold=True))
    # Rotas
    d.arc([(60, 140), (750, 400)], 0, 360, fill="#1565C0", width=2)
    arrow_h(d, 220, 200, 500, color="#C62828")
    d.text((300, 175), "1492 - Colombo", fill="#C62828", font=font(16, bold=True))
    d.text((300, 270), "1498 - India", fill="#1565C0", font=font(16, bold=True))
    d.text((300, 295), "1500 - Brasil", fill="#1565C0", font=font(16, bold=True))
    d.text((560, 395), "Tordesilhas 1494", fill="#7B1FA2", font=font(14, bold=True))

    # Renascimento
    box(d, 510, 100, 460, 130, "RENASCIMENTO (sec XIV-XVI)",
        ["Humanismo: valorizacao do homem",
         "Leonardo da Vinci, Michelangelo",
         "Ciencia: Copernico, Galileu",
         "Vesalio: anatomia (1543)",
         "Hipocrates: medicina cientifica"],
        color="#E3F2FD", border="#1565C0")

    # Reforma e Contra-Reforma
    box(d, 30, 430, 460, 130, "REFORMA E CONTRA-REFORMA",
        ["Lutero: 95 teses (1517)",
         "Calvino: predestinacao, Genebra",
         "Anglicanismo: Henrique VIII",
         "Contra-reforma: Trento (1545-63)",
         "Jesuitas: catequese e educacao"],
        color="#FFF3E0", border="#FF5722")

    # Iluminismo
    box(d, 510, 430, 460, 130, "ILUMINISMO (sec XVIII)",
        ["Razao, liberdade, igualdade",
         "Voltaire, Rousseau, Montesquieu",
         "Locke: direitos naturais",
         "Influencia: Independencia EUA",
         "Influencia: Revolucao Francesa"],
        color="#F3E5F5", border="#7B1FA2")

    # Linha do tempo
    d.line([(30, 590), (970, 590)], fill="#0D7C66", width=3)
    pontos = [(80, "1453", "Const."), (220, "1492", "Colombo"),
              (380, "1517", "Lutero"), (550, "1543", "Vesalio"),
              (720, "1789", "Rev. Fr."), (920, "", "")]
    for x, data, ev in pontos[:5]:
        d.ellipse([(x-7, 590-7), (x+7, 590+7)], fill="#F44336", outline="black", width=2)
        d.text((x-30, 605), data, fill="#F44336", font=font(14, bold=True))
        d.text((x-30, 625), ev, fill="#1A1A2E", font=font(13))
    d.text((300, 660), "Linha do tempo da Idade Moderna", fill="#0D7C66", font=font(16, bold=True))


# ============================================================
# 8.4 Idade Contemporanea — linha do tempo detalhada
# ============================================================
def draw_contemporanea(d, w, h):
    header(d, w, "Idade Contemporanea (1789-atual)",
           "Revolucoes, guerras mundiais e ideologias")

    # Linha do tempo principal
    d.line([(30, 200), (970, 200)], fill="#0D7C66", width=4)
    eventos = [
        (60, "1789", "Rev. Francesa", "#F44336"),
        (180, "Sec XIX", "Rev. Industrial", "#FF9800"),
        (300, "1776", "Indep. EUA", "#4CAF50"),
        (420, "1822", "Indep. Brasil", "#2196F3"),
        (540, "1914-18", "1a Guerra", "#C62828"),
        (660, "1929", "Crise", "#7B1FA2"),
        (780, "1939-45", "2a Guerra", "#C62828"),
        (900, "1947", "Guerra Fria", "#00838F"),
    ]
    for x, data, ev, c in eventos:
        d.ellipse([(x-8, 200-8), (x+8, 200+8)], fill=c, outline="black", width=2)
        d.text((x-35, 215), data, fill=c, font=font(14, bold=True))
        d.text((x-40, 235), ev, fill="#1A1A2E", font=font(13))

    # Caixas de detalhes
    box(d, 30, 280, 300, 160, "REVOLUCAO FRANCESA",
        ["Liberdade, igualdade, fraternidade",
         "Fim do absolutismo",
         "Declaracao dos Direitos",
         "Influencia iluminista",
         "Napoleao: expansao"],
        color="#FFEBEE", border="#F44336")

    box(d, 350, 280, 300, 160, "REVOLUCAO INDUSTRIAL",
        ["Maquina a vapor",
         "Taylorismo e Fordismo",
         "Urbanizacao acelerada",
         "Sindicalismo",
         "Exploracao operaria"],
        color="#FFF3E0", border="#FF9800")

    box(d, 670, 280, 300, 160, "IMPERIALISMO",
        ["Partilha da Africa",
         "Colonialismo na Asia",
         "Busca de materias-primas",
         "Nacionalismo",
         "Causa das guerras"],
        color="#E0F2F1", border="#00695C")

    box(d, 30, 460, 460, 130, "GUERRAS MUNDIAIS",
        ["1a Guerra (1914-18): imperialismo, nacionalismo",
         "Tratado de Versalhes: punicao a Alemanha",
         "Fascismo e Nazismo: totalitarismo",
         "2a Guerra (1939-45): Holocausto, bomba atomica",
         "ONU: criada em 1945"],
        color="#FFEBEE", border="#C62828")

    box(d, 510, 460, 460, 130, "GUERRA FRIA (1947-1991)",
        ["EUA (capitalismo) x URSS (comunismo)",
         "Corrida armamentista e espacial",
         "Muro de Berlim (1961-1989)",
         "Descolonizacao da Africa e Asia",
         "Queda da URSS (1991)"],
        color="#E3F2FD", border="#1565C0")

    d.text((250, 620), "Idade Contemporanea: revolucoes e conflitos", fill="#0D7C66", font=font(18, bold=True))


# ============================================================
# 8.5 Brasil Contemporaneo — linha do tempo detalhada
# ============================================================
def draw_brasil_contemporaneo(d, w, h):
    header(d, w, "Brasil Contemporaneo (1930-atual)",
           "Era Vargas, Ditadura e Redemocratizacao")

    # Linha do tempo
    d.line([(30, 180), (970, 180)], fill="#0D7C66", width=4)
    pontos = [
        (70, "1930", "Rev. de 30"),
        (180, "1937", "Estado Novo"),
        (300, "1945", "Fim Vargas"),
        (420, "1964", "Golpe"),
        (550, "1968", "AI-5"),
        (680, "1985", "Redemoc."),
        (800, "1988", "Const."),
        (920, "1990", "Collor"),
    ]
    for x, data, ev in pontos:
        c = "#F44336" if "Golpe" in ev or "AI-5" in ev else "#0D7C66"
        d.ellipse([(x-8, 180-8), (x+8, 180+8)], fill=c, outline="black", width=2)
        d.text((x-30, 195), data, fill=c, font=font(14, bold=True))
        d.text((x-35, 215), ev, fill="#1A1A2E", font=font(13))

    # Era Vargas
    box(d, 30, 260, 300, 180, "ERA VARGAS (1930-1945)",
        ["Revolucao de 1930",
         "Industrializacao: CSN",
         "Leis trabalhistas: CLT",
         "Estado Novo (1937): ditadura",
         "DASP: reforma administrativa",
         "Getulio: populismo"],
        color="#FFF3E0", border="#FF9800")

    # Periodo Democratico
    box(d, 350, 260, 300, 180, "DEMOCRACIA (1946-1964)",
        ["Constituicao de 1946",
         "Juscelino: 50 anos em 5",
         "Brasilia: nova capital (1960)",
         "Nacional-desenvolvimentismo",
         "Crescimento economico",
         "Tensao politica crescente"],
        color="#E8F5E9", border="#4CAF50")

    # Ditadura
    box(d, 670, 260, 300, 180, "DITADURA (1964-1985)",
        ["Golpe civil-militar 1964",
         "Atos Institucionais (AI-5)",
         "Censura e repressao",
         "Milagre economico (1968-73)",
         "Lei de Anistia (1979)",
         "Diretas ja (1984)"],
        color="#FFEBEE", border="#C62828")

    # Redemocratizacao
    box(d, 30, 460, 460, 130, "REDEMOCRATIZACAO",
        ["Nova Republica (1985)",
         "Constituicao Cidada (1988)",
         "Plano Real (1994): estabilidade",
         "SUS: saude publica universal",
         "Movimentos pelos direitos humanos"],
        color="#E3F2FD", border="#1565C0")

    # Atualidade
    box(d, 510, 460, 460, 130, "SOCIEDADE ATUAL",
        ["Globalizacao e tecnologia",
         "Relacoes de trabalho: precarizacao",
         "Conflitos internacionais atuais",
         "Movimentos sociais: BLM, feminismo",
         "Pandemia e saude publica"],
        color="#F3E5F5", border="#7B1FA2")

    d.text((200, 620), "Brasil: de Vargas a redemocratizacao", fill="#0D7C66", font=font(18, bold=True))


# ============================================================
# 8.6 Historia do Maranhao — cronologia + economia
# ============================================================
def draw_maranhao(d, w, h):
    header(d, w, "Historia do Maranhao",
           "Colonial, Imperial e Contemporaneo")

    # Mapa do Maranhao estilizado
    d.text((30, 100), "Maranhao no Brasil", fill="#0D7C66", font=font(20, bold=True))
    # Brasil simplificado
    d.polygon([(100, 150), (250, 140), (320, 200), (300, 350), (200, 380), (120, 300)],
              fill="#C8E6C9", outline="black", width=2)
    d.text((170, 250), "BRASIL", fill="#1A1A2E", font=font(16, bold=True))
    # Maranhao destacado
    d.polygon([(90, 160), (180, 150), (200, 200), (130, 210)],
              fill="#FF9800", outline="black", width=3)
    d.text((100, 175), "MA", fill="white", font=font(16, bold=True))
    d.text((60, 220), "Sao Luis", fill="#FF5722", font=font(14, bold=True))
    d.ellipse([(110, 155), (120, 165)], fill="#F44336", outline="black", width=2)

    # Colonial
    box(d, 360, 100, 600, 150, "MARANHAO COLONIAL (sec XVII-XVIII)",
        ["Franceses fundaram Sao Luis (1612)",
         "Expulsos por portugueses (1615)",
         "Companhia de Comercio do Maranhao (1682)",
         "Economia: cana-de-acucar, algodao, arroz",
         "Escravidao africana e indigena",
         "Isolamento do resto do Brasil"],
        color="#FFF3E0", border="#FF9800")

    # Imperial
    box(d, 360, 270, 600, 150, "MARANHAO IMPERIAL (sec XIX)",
        ["Balaiada (1838-1841): revolta popular",
         "Economia algodoeira em decadencia",
         "Abolicionismo: Sao Luis primeira capital",
         "  a abolir escravidao (1884)",
         "Ciclo do caju no seculo XIX",
         "Elite agraria dominante"],
        color="#E3F2FD", border="#1565C0")

    # Contemporaneo
    box(d, 360, 440, 600, 150, "MARANHAO CONTEMPORANEO (sec XX-XXI)",
        ["Modernizacao: Eletronorte, Alumar (1980s)",
         "Complexo portuario de Itaqui",
         "Movimentos sociais: MST, quilombolas",
         "Cultura: bumba-meu-boi, tambor de crioula",
         "Desigualdade regional persistente",
         "Politica: coronelismo e transicao"],
        color="#E0F2F1", border="#00695C")

    # Linha do tempo
    d.line([(30, 620), (970, 620)], fill="#0D7C66", width=3)
    pontos = [(80, "1612", "Franceses"), (250, "1682", "Cia Comercio"),
              (420, "1838", "Balaiada"), (600, "1884", "Abolic"),
              (780, "1980", "Alumar"), (920, "hoje", "")]
    for x, data, ev in pontos[:5]:
        d.ellipse([(x-7, 620-7), (x+7, 620+7)], fill="#F44336", outline="black", width=2)
        d.text((x-30, 635), data, fill="#F44336", font=font(13, bold=True))
        d.text((x-30, 655), ev, fill="#1A1A2E", font=font(12))


def main():
    draw_functions = [
        ("hist_mundo_antigo", draw_mundo_antigo),
        ("hist_medieval", draw_medieval),
        ("hist_moderna", draw_moderna),
        ("hist_contemporanea", draw_contemporanea),
        ("hist_brasil_contemporaneo", draw_brasil_contemporaneo),
        ("hist_maranhao", draw_maranhao),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
