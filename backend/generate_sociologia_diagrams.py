# -*- coding: utf-8 -*-
"""Gera diagramas para Sociologia — topicos 11.1 a 11.9."""

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
    d.rectangle([(0, 0), (w, 60)], fill="#00695C")
    d.text((20, 15), title, fill="white", font=font(26, bold=True))
    if sub:
        d.text((20, 80), sub, fill="#00695C", font=font(18))

def box(d, x, y, w, h, title, items, color="#E0F2F1", border="#00695C"):
    d.rectangle([(x, y), (x+w, y+h)], fill=color, outline=border, width=3)
    d.text((x+10, y+8), title, fill="#1A1A2E", font=font(18, bold=True))
    for i, item in enumerate(items):
        d.text((x+15, y+35+i*22), f"- {item}", fill="#1A1A2E", font=font(15))

def draw_surgimento(d, w, h):
    header(d, w, "Surgimento da Sociologia", "Contexto historico e ciencia")
    box(d, 30, 100, 460, 200, "CONTEXTO HISTORICO",
        ["Revolucao Industrial (sec XVIII)", "Urbanizacao caotica",
         "Proletariado: condicoes precarias", "Revolucao Francesa: novas ideias",
         "Crise do antigo regime", "Novos problemas sociais"],
        color="#E0F2F1", border="#00695C")
    box(d, 510, 100, 460, 200, "SOCIOLOGIA COMO CIENCIA",
        ["Auguste Comte: pai da sociologia", "Positivismo: metodo das ciencias naturais",
         "Objeto: a sociedade", "Metodo: observacao, experimentacao",
         "Fato social (Durkheim)", "Compreensao (Weber)"],
        color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 940, 180, "A REVOLUCAO INDUSTRIAL E A SOCILOGIA",
        ["A sociologia nasce para explicar a nova sociedade industrial",
         "Problemas: pobreza urbana, criminalidade, conflitos de classe",
         "Saint-Simon, Comte: ordem e progresso",
         "Durkheim: anomia, solidariedade",
         "Marx: luta de classes, alienacao",
         "Weber: racionalizacao, desencantamento do mundo"],
        color="#FFF3E0", border="#FF9800")
    d.text((250, 540), "Sociologia: ciencia da sociedade moderna", fill="#00695C", font=font(18, bold=True))

def draw_classicas(d, w, h):
    header(d, w, "Perspectivas Classicas da Sociologia", "Durkheim, Marx, Weber e interpretes do Brasil")
    box(d, 30, 100, 300, 200, "DURKHEIM",
        ["Fato social: externo e coercitivo", "Solidariedade mecanica x organica",
         "Anomia: ausencia de normas", "Suicidio: estudo sociologico",
         "Religiao: fato social", "Metodo: positivista"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "MARX",
        ["Materialismo historico", "Luta de classes",
         "Modos de producao", "Alienacao",
         "Mais-valia: exploracao", "Comunismo: sem classes"],
        color="#FFEBEE", border="#C62828")
    box(d, 670, 100, 300, 200, "WEBER",
        ["Acao social: compreensao (Verstehen)", "Tipos ideais",
         "Racionalizacao", "Desencantamento do mundo",
         "Etica protestante e capitalismo", "Dominacao legitima"],
        color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 460, 180, "INTERPRETES DO BRASIL",
        ["Florestan Fernandes: racismo, classes", "Gilberto Freyre: formacao, mesticagem",
         "Sergio Buarque: homem cordial", "Roberto DaMatta: jeitinho, hierarquia",
         "Caio Prado: formacao colonial", "Raymundo Fausto: escravidao"],
        color="#FFF3E0", border="#FF9800")
    box(d, 510, 320, 460, 180, "COMPARACAO",
        ["Durkheim: sociedade como organismo", "Marx: conflito e mudanca",
         "Weber: sentido e racionalidade", "Brasil: raca, mesticagem, hierarquia",
         "Cada perspectiva revela um aspecto", "Nao sao excludentes"],
        color="#F3E5F5", border="#7B1FA2")
    d.text((200, 540), "Os classicos fundaram a sociologia moderna", fill="#00695C", font=font(18, bold=True))

def draw_conceitos(d, w, h):
    header(d, w, "Conceitos Basicos de Sociologia", "Socializacao, controle, instituicoes e grupos")
    box(d, 30, 100, 300, 180, "SOCIALIZACAO",
        ["Processo de aprender a cultura", "Primaria: familia, infancia",
         "Secundaria: escola, trabalho", "Resocializacao: presidiarios",
         "Agentes: familia, escola, midia"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 180, "CONTROLE SOCIAL",
        ["Normas: regras de conduta", "Sancoes: positivas e negativas",
         "Formal: leis, policia", "Informal: costumes, opiniao",
         "Desvio: quebra de normas"],
        color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 180, "INSTITUICOES SOCIAIS",
        ["Familia: reproducao, socializacao", "Escola: educacao formal",
         "Religiao: sagrado, valores", "Estado: poder, leis",
         "Midia: informacao, valores"],
        color="#FFF3E0", border="#FF9800")
    box(d, 30, 300, 460, 180, "GRUPOS SOCIAIS",
        ["Primario: intimidade (familia)", "Secundario: formal (empresa)",
         "De pertencimento x de referencia", "Endogrupo x exogrupo",
         "Status: posicao social", "Papel: comportamento esperado"],
        color="#F3E5F5", border="#7B1FA2")
    box(d, 510, 300, 460, 180, "INTERACAO E PROCESSOS SOCIAIS",
        ["Cooperacao: objetivo comum", "Competicao: disputa",
         "Conflito: oposicao", "Acomodacao: ajuste",
         "Assimilacao: integracao", "Contato social"],
        color="#FFEBEE", border="#C62828")
    d.text((200, 520), "Conceitos basicos: ferramentas para entender a sociedade", fill="#00695C", font=font(18, bold=True))
    d.text((300, 560), "Status = posicao. Papel = comportamento esperado.", fill="#1A1A2E", font=font(16))

def draw_mudanca(d, w, h):
    header(d, w, "Mudanca Social", "Estratificacao, mobilidade e desigualdade")
    box(d, 30, 100, 300, 200, "ESTRATIFICACAO SOCIAL",
        ["Sociedade em camadas (classes)", "Caste: hereditaria (India)",
         "Estado: baseada em riqueza", "Classe: economica (Marx)",
         "Estratificacao: desigual"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "MOBILIDADE SOCIAL",
        ["Movimento entre estratos", "Vertical: sobe ou desce",
         "Horizontal: mesma posicao", "Intageracional: pai->filho",
         "Intragageracional: na carreira"],
        color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "DESIGUALDADE",
        ["Economica: renda, riqueza", "Genero: machismo, feminicidio",
         "Raca: racismo estrutural", "Etnia: indigenas, quilombolas",
         "Interseccionalidade"],
        color="#FFEBEE", border="#C62828")
    box(d, 30, 320, 940, 180, "DESIGUALDADE NO BRASIL",
        ["Brasil: um dos paises mais desiguais do mundo",
         "1% mais rico concentra ~30% da renda",
         "Negros: 2x mais probabilidade de pobreza",
         "Mulheres: recebem ~80% do salario masculino",
         "Indigenas e quilombolas: exclusao historica",
         "Interseccionalidade: raca + genero + classe"],
        color="#FFF3E0", border="#FF9800")
    d.text((200, 540), "Mudanca social: estratificacao, mobilidade e desigualdade", fill="#00695C", font=font(18, bold=True))

def draw_violencia(d, w, h):
    header(d, w, "Sociologia da Violencia", "Conceito, criminalizacao e tipos")
    box(d, 30, 100, 300, 200, "CONCEITO DE VIOLENCIA",
        ["Uso de forca para dominar", "Violencia estrutural: sistema",
         "Violencia simbolica: Bourdieu", "Violencia cultural: Galtung",
         "Nao so fisica"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "CRIMINALIZACAO",
        ["Crime: conduta tipificada", "Criminalizacao primaria: lei",
         "Criminalizacao secundaria: policia", "Seletividade: pobres e negros",
         "Encarceramento em massa"],
        color="#FFEBEE", border="#C62828")
    box(d, 670, 100, 300, 200, "TIPOS DE VIOLENCIA",
        ["Fisica: agressao, homicidio", "Sexual: estupro, assedio",
         "Psicologica: ameaca, humilhacao", "Simbolica: naturalizada",
         "Patrimonial: roubo, destruicao"],
        color="#E3F2FD", border="#1565C0")
    box(d, 30, 320, 940, 180, "VIOLENCIA NO BRASIL",
        ["Brasil: ~60 mil homicidios/ano (uma das maiores taxas)",
         "Juventude negra: principal vitima (75%)",
         "Feminicidio: Lei 13.104/2015",
         "Lei Maria da Penha (2006): violencia domestica",
         "Violencia policial: racismo estrutural",
         "Narcotrafico: faccoes e disputa territorial"],
        color="#FFF3E0", border="#FF9800")
    d.text((200, 540), "Violencia: nao so fisica, tambem estrutural e simbolica", fill="#00695C", font=font(18, bold=True))

def draw_cultura_ideologia(d, w, h):
    header(d, w, "Cultura e Ideologia", "Popular, massa, identidade e preconceito")
    box(d, 30, 100, 300, 200, "CULTURA POPULAR, ERUDITA, MASSA",
        ["Popular: do povo, tradicional", "Erudita: elite, refinada",
         "Massa: produzida para consumo", "Industria cultural: Adorno",
         "Cultura de massa: padronizada"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "IDENTIDADE E MULTICULTURALISMO",
        ["Identidade: como nos definimos", "Multiculturalismo: diversidade",
         "Identidades: genero, raca, etnia", "Politicas de identidade",
         "Hibridismo cultural"],
        color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "RACISMO E PRECONCEITO",
        ["Racismo: discriminacao por raca", "Preconceito: atitude",
         "Discriminacao: acao", "Racismo estrutural: sistema",
         "Racismo institucional: nas instituicoes"],
        color="#FFEBEE", border="#C62828")
    box(d, 30, 320, 460, 180, "CONTRACULTURA E ETNOCENTRISMO",
        ["Contracultura: recusa o hegemonico", "Punk, hippie, hip hop",
         "Etnocentrismo: minha cultura e superior", "Relativismo: cada cultura tem valor",
         "Levi-Strauss: respeito a diferenca"],
        color="#F3E5F5", border="#7B1FA2")
    box(d, 510, 320, 460, 180, "IDEOLOGIA",
        ["Marx: falsa consciencia", "Althusser: aparelhos ideologicos",
         "Ideologia naturaliza o social", "Midia: difusao ideologica",
         "Hegemonia: Gramsci, consenso"],
        color="#FFF3E0", border="#FF9800")
    d.text((200, 540), "Cultura e ideologia: organizam sentidos e poder", fill="#00695C", font=font(18, bold=True))

def draw_trabalho(d, w, h):
    header(d, w, "Trabalho e Sociedade", "Fordismo, taylorismo, toyotismo e modos de producao")
    box(d, 30, 100, 300, 200, "TAYLORISMO",
        ["Frederick Taylor (sec XX)", "Organizacao cientifica do trabalho",
         "Estudo de tempos e movimentos", "Separacao: execucao x planejamento",
         "Maximizacao de eficiencia"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "FORDISMO",
        ["Henry Ford (1913)", "Linha de montagem", "Producao em massa",
         "Padronizacao", "Salario maior = consumo",
         "Intensificacao do trabalho"],
        color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "TOYOTISMO",
        ["Toyota (Japao, pos-1945)", "Producao flexivel",
         "Just-in-time: estoque minimo", "Kaizen: melhoria continua",
         "Trabalhador polivalente", "Qualidade total"],
        color="#FFF3E0", border="#FF9800")
    box(d, 30, 320, 460, 180, "MODOS DE PRODUCAO (Marx)",
        ["Comunismo primitivo: sem classes", "Asiatico: Estado despota",
         "Escravista: dono x escravo", "Feudal: senhor x servo",
         "Capitalista: burgues x proletariado", "Socialista: transicao"],
        color="#FFEBEE", border="#C62828")
    box(d, 510, 320, 460, 180, "MERCADO DE TRABALHO ATUAL",
        ["Precarizacao: sem direitos", "Uberizacao: app como patrao",
         "Informalidade: ~50% no Brasil", "Desemprego estrutural",
         "Automacao e IA", "Trabalho escravo contemporaneo"],
        color="#F3E5F5", border="#7B1FA2")
    d.text((200, 540), "Trabalho: do taylorismo a uberizacao", fill="#00695C", font=font(18, bold=True))

def draw_estado_poder(d, w, h):
    header(d, w, "Estado e Poder", "Formas de poder, regimes, democracia e movimentos")
    box(d, 30, 100, 300, 200, "FORMAS DE PODER",
        ["Poder politico: Estado", "Poder economico: capital",
         "Poder ideologico: midia, religiao", "Poder coercitivo: forca",
         "Poder simbolico: Bourdieu"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "ESTADO, GOVERNO, REGIMES",
        ["Estado: instituicao permanente", "Governo: grupo no poder",
         "Regime: forma de governo", "Democracia, autocracia",
         "Monarquia, republica", "Presidencialismo, parlamentarismo"],
        color="#E3F2FD", border="#1565C0")
    box(d, 670, 100, 300, 200, "DEMOCRACIA E CIDADANIA",
        ["Direta, representativa, participativa", "Cidadania: civil, politica, social",
         "Sufragio universal", "Estado de direito",
         "Controle social"],
        color="#FFF3E0", border="#FF9800")
    box(d, 30, 320, 460, 180, "PARTIDOS E SISTEMAS ELEITORAIS",
        ["Partidos: organizacoes politicas", "Esquerda, centro, direita",
         "Sistema majoritario: vencedor leva tudo", "Sistema proporcional: representatividade",
         "Brasil: proporcional (camara) + majoritario (senado)"],
        color="#F3E5F5", border="#7B1FA2")
    box(d, 510, 320, 460, 180, "MOVIMENTOS SOCIAIS E DIREITOS",
        ["Movimentos: MST, MTST, feminista, BLM", "Reivindicacao de direitos",
         "Pressao sobre o Estado", "Mobilizacao coletiva",
         "Direitos humanos: universais", "Conquista historica"],
        color="#FFEBEE", border="#C62828")
    d.text((200, 540), "Estado e poder: organizacao politica da sociedade", fill="#00695C", font=font(18, bold=True))

def draw_contemporaneos(d, w, h):
    header(d, w, "Temas Contemporaneos", "Globalizacao, neoliberalismo, meio ambiente")
    box(d, 30, 100, 300, 200, "GLOBALIZACAO",
        ["Mundo interligado", "Economia global", "Cultura global x local",
         "Tecnologia: internet", "Migracoes", "Glocalizacao"],
        color="#E0F2F1", border="#00695C")
    box(d, 350, 100, 300, 200, "NEOLIBERALISMO",
        ["Estado minimo", "Privatizacoes", "Mercado como regulador",
         "Desregulamentacao", "Friedman, Hayek", "Consequencias: desigualdade"],
        color="#FFEBEE", border="#C62828")
    box(d, 670, 100, 300, 200, "MEIO AMBIENTE",
        ["Crise ecologica", "Aquecimento global", "Desmatamento",
         "Biodiversidade", "Antropoceno", "Justica climatica"],
        color="#E8F5E9", border="#4CAF50")
    box(d, 30, 320, 460, 180, "SUSTENTABILIDADE E ALIMENTOS",
        ["ODS: 17 objetivos (ONU)", "Agenda 2030", "Agricultura sustentavel",
         "Agrotoxicos: riscos", "Soberania alimentar", "Comida x commodity"],
        color="#FFF3E0", border="#FF9800")
    box(d, 510, 320, 460, 180, "DESAFIOS DO SECULO XXI",
        ["Tecnologia: IA, automacao", "Desigualdade crescente",
         "Migracoes e refugiados", "Pos-verdade e desinformacao",
         "Pandemias", "Crise democratica"],
        color="#F3E5F5", border="#7B1FA2")
    d.text((200, 540), "Temas contemporaneos: desafios globais interligados", fill="#00695C", font=font(18, bold=True))

def main():
    funcs = [
        ("socio_surgimento", draw_surgimento),
        ("socio_classicas", draw_classicas),
        ("socio_conceitos", draw_conceitos),
        ("socio_mudanca", draw_mudanca),
        ("socio_violencia", draw_violencia),
        ("socio_cultura", draw_cultura_ideologia),
        ("socio_trabalho", draw_trabalho),
        ("socio_estado", draw_estado_poder),
        ("socio_contemporaneos", draw_contemporaneos),
    ]
    for name, fn in funcs:
        save(name, fn)
    print(f"\n{len(funcs)} diagramas gerados")

if __name__ == "__main__":
    main()
