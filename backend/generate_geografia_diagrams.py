"""Gera diagramas RICOS para Geografia — topicos 9.1 a 9.4."""

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
    d.rectangle([(0, 0), (w, 60)], fill="#1565C0")
    d.text((20, 15), title, fill="white", font=font(26, bold=True))
    if subtitle:
        d.text((20, 80), subtitle, fill="#1565C0", font=font(18))


def box(d, x, y, w, h, title, items, color="#E3F2FD", border="#1565C0"):
    d.rectangle([(x, y), (x+w, y+h)], fill=color, outline=border, width=3)
    d.text((x+10, y+8), title, fill="#1A1A2E", font=font(18, bold=True))
    for i, item in enumerate(items):
        d.text((x+15, y+35+i*22), f"- {item}", fill="#1A1A2E", font=font(15))


# ============================================================
# 9.1 Geografia Fisica — estrutura da Terra + coordenadas + clima
# ============================================================
def draw_fisica(d, w, h):
    header(d, w, "Geografia Fisica",
           "Estrutura da Terra, coordenadas, clima e relevo")

    # Estrutura interna da Terra (esquerda)
    d.text((30, 100), "Estrutura Interna da Terra", fill="#1565C0", font=font(20, bold=True))
    # Nucleo
    d.ellipse([(120, 150), (320, 350)], fill="#FF5722", outline="black", width=3)
    d.text((170, 235), "NUCLEO", fill="white", font=font(16, bold=True))
    # Manto
    d.ellipse([(100, 130), (340, 370)], fill="#FF9800", outline="black", width=3)
    d.text((150, 200), "MANTO", fill="white", font=font(14, bold=True))
    # Crosta
    d.ellipse([(80, 110), (360, 390)], fill="#8D6E63", outline="black", width=3)
    d.text((90, 130), "CROSTA", fill="white", font=font(14, bold=True))

    # Coordenadas geograficas (centro)
    box(d, 400, 100, 280, 180, "COORDENADAS GEOGRAFICAS",
        ["Latitude: paralelos",
         "  0 = Equador",
         "Longitude: meridianos",
         "  0 = Greenwich",
         "Hemisferios: N/S, L/O",
         "Fusos horarios: 24"],
        color="#E8F5E9", border="#4CAF50")

    # Clima (direita)
    box(d, 700, 100, 270, 180, "CLIMA",
        ["Elementos: temp, umidade,",
         "  precipitacao, ventos",
         "Fatores: latitude, altitude,",
         "  maritimidade, correntes",
         "Massas de ar: mT, mP, mE, mP",
         "Brasil: tropical, equatorial"],
        color="#FFF3E0", border="#FF9800")

    # Relevo (centro inferior)
    box(d, 30, 310, 460, 180, "RELEVO TERRESTRE",
        ["Montanhas: dobramentos modernos",
         "Planaltos: superficies elevadas",
         "Planicies: areas planas baixas",
         "Depressoes: abaixo do nivel",
         "  do entorno",
         "Tectonica de placas: pangaea"],
        color="#FFF8E1", border="#FFC107")

    # Hidrografia (direita inferior)
    box(d, 510, 310, 460, 180, "HIDROGRAFIA",
        ["Bacia hidrografica: area",
         "  drenada por um rio principal",
         "Bacias brasileiras:",
         "  Amazonica (maior)",
         "  Sao Francisco, Parana",
         "  Tocantins-Araguaia, Uruguai"],
        color="#E1F5FE", border="#0288D1")

    # Vegetacao (baixo)
    box(d, 30, 510, 940, 110, "PAISAGENS VEGETAIS",
        ["Floresta equatorial (Amazonia): umida, biodiversa",
         "Cerrado: savana brasileira, estacional",
         "Caatinga: seca, nordeste, xerofita",
         "Pampa: campos sulinos",
         "Mata Atlantica: floresta tropical, litoral",
         "Pantanal: humido, Mato Grosso"],
        color="#E8F5E9", border="#2E7D32")

    d.text((300, 640), "Geografia fisica: Terra, clima, relevo e agua", fill="#1565C0", font=font(16, bold=True))


# ============================================================
# 9.2 Geografia Humana — demografia + economia + urbanizacao
# ============================================================
def draw_humana(d, w, h):
    header(d, w, "Geografia Humana",
           "Demografia, economia, urbanizacao e geopolitica")

    # Demografia (esquerda)
    box(d, 30, 100, 300, 200, "DEMOGRAFIA",
        ["Distribuicao desigual",
         "Crescimento: paises pobres",
         "  crescem mais",
         "Migracoes: rural-urbano",
         "  e internacionais",
         "Composicao: idade, genero,",
         "  etnia, renda",
         "Transicao demografica"],
        color="#F3E5F5", border="#7B1FA2")

    # Economia (centro)
    box(d, 350, 100, 300, 200, "ECONOMIA",
        ["Agricultura: commodities",
         "Pecuaria: bovinos, aves",
         "Industria: transformacao",
         "Energia: hidreletrica,",
         "  petroleo, renovaveis",
         "Materias-primas: mineracao",
         "Comercio externo: export/import"],
        color="#FFF3E0", border="#FF5722")

    # Urbanizacao (direita)
    box(d, 670, 100, 300, 200, "URBANIZACAO",
        ["Crescimento urbano acelerado",
         "Metropoles: Sao Paulo, RJ",
         "Favelas e periferias",
         "Problemas: transporte,",
         "  saneamento, habitacao",
         "Megacidades: 10 mi+ hab",
         "Cidades globais"],
        color="#E0F2F1", border="#00695C")

    # Geopolitica (centro inferior)
    box(d, 30, 320, 460, 180, "GEOPOLITICA: MEGABLOCOS",
        ["Uniao Europeia (UE): 27 paises",
         "USMCA/NAFTA: EUA, Canada, Mexico",
         "Mercosul: Brasil, Argentina, etc",
         "BRICS: Brasil, Russia, India, China",
         "  + Africa do Sul",
         "ASEAN: Sudeste asiatico"],
        color="#E3F2FD", border="#1565C0")

    # Questao ambiental (direita inferior)
    box(d, 510, 320, 460, 180, "QUESTAO AMBIENTAL",
        ["Aquecimento global: CO2",
         "Desmatamento: Amazonia, Cerrado",
         "Poluicao: ar, agua, solo",
         "Biodiversidade: extincao",
         "Recursos hidricos: escassez",
         "Desenvolvimento sustentavel"],
        color="#E8F5E9", border="#2E7D32")

    # Economia brasileira (baixo)
    box(d, 30, 520, 940, 110, "ECONOMIA BRASILEIRA",
        ["Agroexportacao: soja, carne, cafe, acucar",
         "Industria: automobilistica, siderurgica, quimica",
         "Servicos: 70% do PIB",
         "Energia: hidreletrica, petroleo (pre-sal), etanol",
         "Transportes: rodoviario predominante",
         "Paisagens culturais: nordeste, amazonia, pampa"],
        color="#FFF8E1", border="#FFC107")

    d.text((250, 650), "Geografia humana: populacao, economia e sociedade", fill="#1565C0", font=font(16, bold=True))


# ============================================================
# 9.3 Geografia do Maranhao — mapa + regioes + economia
# ============================================================
def draw_maranhao(d, w, h):
    header(d, w, "Geografia do Maranhao",
           "Fisica, economia e cultura maranhense")

    # Mapa do Maranhao estilizado
    d.text((30, 100), "Mapa do Maranhao", fill="#1565C0", font=font(20, bold=True))
    # Forma aproximada do Maranhao
    d.polygon([(80, 150), (300, 140), (340, 250), (320, 350),
               (200, 380), (100, 300), (70, 200)],
              fill="#C8E6C9", outline="black", width=3)
    d.text((150, 230), "MARANHAO", fill="#1A1A2E", font=font(20, bold=True))
    # Sao Luis
    d.ellipse([(90, 160), (100, 170)], fill="#F44336", outline="black", width=2)
    d.text((60, 175), "Sao Luis", fill="#F44336", font=font(14, bold=True))
    # Imperatriz
    d.ellipse([(220, 330), (230, 340)], fill="#2196F3", outline="black", width=2)
    d.text((240, 335), "Imperatriz", fill="#2196F3", font=font(14, bold=True))
    # Caxias
    d.ellipse([(280, 220), (290, 230)], fill="#FF9800", outline="black", width=2)
    d.text((300, 225), "Caxias", fill="#FF9800", font=font(14, bold=True))

    # Geografia fisica (centro)
    box(d, 380, 100, 280, 180, "GEOGRAFIA FISICA",
        ["Relevo: planicies e planaltos",
         "Clima: tropical, equatorial",
         "  no oeste, semiarido no leste",
         "Vegetacao: Amazonia (oeste),",
         "  Cerrado (centro), Caatinga",
         "  (leste), manguezais (litoral)",
         "Rios: Pindare, Mearim, Itapecuru"],
        color="#E8F5E9", border="#4CAF50")

    # Economia (direita)
    box(d, 680, 100, 290, 180, "ECONOMIA",
        ["Aluminio: Alumar (Sao Luis)",
         "Porto de Itaqui: ferro, soja",
         "Papel e celulose: Suzano",
         "Soja e pecuaria: sul do estado",
         "Gas natural: Bacia do Parnaiba",
         "BR-163: corredor de exportacao"],
        color="#FFF3E0", border="#FF5722")

    # Sociedade (centro inferior)
    box(d, 380, 300, 280, 180, "SOCIEDADE",
        ["Populacao: ~7 milhoes",
         "Densidade: ~20 hab/km2",
         "IDH: abaixo da media nacional",
         "Etnias: afro, indigena, europeia",
         "Quilombolas: comunidades",
         "  tradicionais numerosas"],
        color="#F3E5F5", border="#7B1FA2")

    # Cultura (direita inferior)
    box(d, 680, 300, 290, 180, "CULTURA",
        ["Bumba-meu-boi: patrimonio",
         "Tambor de crioula",
         "Tambor de mina (religiao)",
         "Cacuria, reggae de Sao Luis",
         "Culinaria: arroz de cuxa,",
         "  torta de caju, pescada"],
        color="#E0F2F1", border="#00695C")

    # Regioes (baixo)
    box(d, 30, 510, 940, 110, "REGIOES DO MARANHAO",
        ["Norte (Baixada): manguezais, pesca, Sao Luis, capital",
         "Oeste: floresta amazonica, extrativismo, Imperatriz",
         "Centro: Cerrado, pecuaria, agricultura",
         "Leste: Caatinga, semiarido, Caxias, Chapadinha",
         "Sul: fronteiras agricolas, soja, BR-163"],
        color="#FFF8E1", border="#FFC107")

    d.text((250, 650), "Maranhao: transicao Amazonia-Caatinga", fill="#1565C0", font=font(16, bold=True))


# ============================================================
# 9.4 Temas Contemporaneos
# ============================================================
def draw_contemporaneos(d, w, h):
    header(d, w, "Temas Contemporaneos",
           "Trabalho, violencia, sustentabilidade e geotecnologias")

    # Trabalho (esquerda)
    box(d, 30, 100, 300, 200, "TRABALHO E CONDICAO HUMANA",
        ["Precarizacao: sem direitos",
         "Uberizacao: app como patrao",
         "Trabalho informal: 50%+ no Brasil",
         "Desemprego estrutural",
         "Automacao e IA: substitui",
         "  trabalhos",
         "Trabalho escravo contemporaneo"],
        color="#FFEBEE", border="#C62828")

    # Violencias (centro)
    box(d, 350, 100, 300, 200, "IMPASSES E VIOLENCIAS",
        ["Violencia urbana",
         "Violencia de genero: feminicidio",
         "Violencia racial",
         "Narcotrafico e faccoes",
         "Genocidio da juventude negra",
         "Armas e seguranca publica"],
        color="#FCE4EC", border="#AD1457")

    # Sustentabilidade (direita)
    box(d, 670, 100, 300, 200, "EDUCACAO AMBIENTAL",
        ["Sustentabilidade: 3 pilares",
         "  (social, economico, ambiental)",
         "ODS: 17 objetivos da ONU",
         "Agenda 2030",
         "Economia circular",
         "Energias renovaveis",
         "Consumo consciente"],
        color="#E8F5E9", border="#2E7D32")

    # Geopolitica (centro inferior)
    box(d, 30, 320, 460, 180, "GEOPOLITICA E CONFLITOS",
        ["Guerra Russia-Ucrania",
         "Conflito Israel-Palestina",
         "Tensoes no Oriente Medio",
         "Migracoes e refugiados",
         "Nacionalismos crescentes",
         "Disputa EUA-China"],
        color="#E3F2FD", border="#1565C0")

    # Geotecnologias (direita inferior)
    box(d, 510, 320, 460, 180, "GEOTECNOLOGIAS",
        ["GPS: posicionamento global",
         "SIG (GIS): sistemas de info",
         "  geografica",
         "Satelites: monitoramento",
         "Drones: mapeamento",
         "Google Earth/Maps",
         "Sensoriamento remoto"],
        color="#E0F7FA", border="#006064")

    # Conclusao (baixo)
    box(d, 30, 520, 940, 110, "SINTESE",
        ["O mundo contemporaneo enfrenta desafios interligados",
         "Trabalho precario, violencia e desigualdade exigem solucoes integradas",
         "Sustentabilidade nao e opcional: e necessidade urgente",
         "Geotecnologias sao ferramentas para entender e resolver problemas",
         "Educacao e cidadania sao caminhos para transformacao"],
        color="#FFF8E1", border="#FFC107")

    d.text((200, 650), "Temas contemporaneos: desafios do seculo XXI", fill="#1565C0", font=font(16, bold=True))


def main():
    draw_functions = [
        ("geo_fisica", draw_fisica),
        ("geo_humana", draw_humana),
        ("geo_maranhao", draw_maranhao),
        ("geo_contemporaneos", draw_contemporaneos),
    ]
    for name, fn in draw_functions:
        save(name, fn)
    print(f"\n{len(draw_functions)} diagramas gerados em {IMG_DIR}")


if __name__ == "__main__":
    main()
