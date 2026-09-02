"""Gera PDF profissional ABNT do material de Química - Princípios Elementares.

Texto 100% PT-BR (Português Brasileiro) com acentuação correta.
Imagens de sites educacionais brasileiros.
Referências em formato ABNT.
"""

import os
from pathlib import Path

from PIL import Image as PILImage
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import HRFlowable, Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer

ROOT = Path(__file__).resolve().parent.parent
LOGO_PATH = ROOT / "assets" / "branding" / "paes_med_ai_icon_source.png"
IMG_DIR = ROOT / "data" / "materiais" / "imagens"
PDF_DIR = ROOT / "data" / "materiais"

PRIMARY = HexColor("#0D7C66")
PRIMARY_DARK = HexColor("#0A5D4D")
PRIMARY_LIGHT = HexColor("#E0F2F1")
TEXT_DARK = HexColor("#1A1A2E")
TEXT_LIGHT = HexColor("#666666")


def _register_fonts():
    font_paths = {
        "Normal": "C:/Windows/Fonts/arial.ttf",
        "Bold": "C:/Windows/Fonts/arialbd.ttf",
        "Italic": "C:/Windows/Fonts/ariali.ttf",
        "BoldItalic": "C:/Windows/Fonts/arialbi.ttf",
    }
    registered = {}
    for name, path in font_paths.items():
        if os.path.exists(path):
            try:
                pdfmetrics.registerFont(TTFont(name, path))
                registered[name] = True
            except Exception:
                registered[name] = False
        else:
            registered[name] = False
    if all(registered.values()):
        from reportlab.pdfbase.pdfmetrics import registerFontFamily
        registerFontFamily("Normal", normal="Normal", bold="Bold",
                           italic="Italic", boldItalic="BoldItalic")
        return True
    return False


_HAS_TTF = _register_fonts()
_FN = "Normal" if _HAS_TTF else "Helvetica"
_FB = "Bold" if _HAS_TTF else "Helvetica-Bold"
_FI = "Italic" if _HAS_TTF else "Helvetica-Oblique"
_FBI = "BoldItalic" if _HAS_TTF else "Helvetica-BoldOblique"


CONTENT = {
    "titulo": "Princípios Elementares da Química",
    "disciplina": "Química",
    "topico": "Princípios Elementares",
    "subtopico": "Matéria, Energia, Substâncias, Misturas e Separação",
    "introducao": (
        "A Química é a ciência que estuda a matéria, sua estrutura, "
        "composição, propriedades e transformações. Compreender os "
        "princípios elementares é essencial para avançar para tópicos "
        "como ligações químicas, reações e cálculos estequiométricos.\n\n"
        "Este material aborda os conceitos fundamentais: matéria e "
        "energia, fenômenos físicos e químicos, estados físicos, "
        "substâncias puras (simples e compostas), alotropia, misturas "
        "(homogêneas e heterogêneas), processos de separação e "
        "materiais básicos de laboratório."
    ),
    "secoes": [
        {
            "titulo": "1. Matéria, Energia e Fenômenos",
            "conteudo": (
                "MATÉRIA: tudo que tem massa e ocupa lugar no espaço. "
                "Pode ser percebida pelos sentidos ou por instrumentos. "
                "Exemplos: madeira, água, ar, ferro.\n\n"
                "ENERGIA: capacidade de realizar trabalho ou produzir "
                "calor. Não tem massa nem ocupa lugar no espaço, mas "
                "pode ser transformada em matéria e vice-versa "
                "(Einstein: E = mc²).\n\n"
                "CORPO: porção limitada de matéria com forma definida. "
                "Ex.: bloco de madeira.\n"
                "OBJETO: corpo fabricado para um fim específico. "
                "Ex.: lápis.\n\n"
                "FENÔMENOS FÍSICOS: não alteram a composição da "
                "matéria. A substância continua a mesma, apenas muda "
                "de estado, forma ou tamanho. Ex.: derretimento do "
                "gelo, ruptura de vidro, magnetização.\n\n"
                "FENÔMENOS QUÍMICOS: alteram a composição da matéria. "
                "Substâncias novas são formadas. Ex.: combustão, "
                "ferrugem, fotossíntese, digestão.\n\n"
                "PROPRIEDADES DA MATÉRIA:\n"
                "- Gerais (comuns a toda a matéria): massa, extensão, "
                "impenetrabilidade, divisibilidade, compressibilidade, "
                "inércia.\n"
                "- Específicas (distinguem substâncias): densidade, "
                "ponto de fusão, ponto de ebulição, solubilidade, "
                "calor específico, cor, odor, sabor, dureza, "
                "maleabilidade, ductilidade, condutibilidade."
            ),
            "exemplo": (
                "A densidade é uma propriedade específica que permite "
                "identificar substâncias. A densidade do ouro é "
                "19,3 g/cm³, enquanto a do ferro é 7,8 g/cm³. Por "
                "isso, uma joia 'de ouro' que flutua em água "
                "certamente não é ouro puro. Na medicina, a densidade "
                "urinária é usada para avaliar a concentração de "
                "solutos na urina e diagnosticar desidratação ou "
                "problemas renais."
            ),
        },
        {
            "titulo": "2. Estados Físicos da Matéria",
            "conteudo": (
                "A matéria pode existir em três estados principais: "
                "sólido, líquido e gasoso (e o plasma, em condições "
                "especiais).\n\n"
                "SÓLIDO: forma e volume constantes. Partículas muito "
                "próximas, com vibração mínima. Ex.: gelo, ferro.\n\n"
                "LÍQUIDO: forma variável (assume a do recipiente) e "
                "volume constante. Partículas com maior liberdade de "
                "movimento. Ex.: água, álcool.\n\n"
                "GASOSO: forma e volume variáveis. Partículas muito "
                "afastadas, com grande liberdade. Ocupam todo o "
                "recipiente. Ex.: ar, gás butano.\n\n"
                "MUDANÇAS DE ESTADO (fenômenos físicos):\n"
                "- Fusão: sólido → líquido (absorve calor).\n"
                "- Solidificação: líquido → sólido (libera calor).\n"
                "- Vaporização: líquido → gás. Pode ser evaporação "
                "(superfície), calefação (rápida) ou ebulição (em "
                "todo o líquido).\n"
                "- Liquefação/Condensação: gás → líquido.\n"
                "- Sublimação: sólido → gás (sem passar por líquido).\n"
                "- Ressublimação: gás → sólido.\n\n"
                "CURVAS DE AQUECIMENTO E RESFRIAMENTO: durante a "
                "mudança de estado, a temperatura permanece constante "
                "enquanto a substância absorve ou libera calor latente."
            ),
            "exemplo": (
                "O gelo seco (CO₂ sólido) sublima à temperatura "
                "ambiente, passando direto de sólido para gás. Por "
                "isso é usado para conservar alimentos transportados "
                "sem deixar resíduo líquido. Em medicina, a "
                "sublimação é usada em processos de liofilização "
                "para conservar vacinas e medicamentos: a água é "
                "congelada e depois sublimada em baixa pressão, "
                "preservando a estrutura do fármaco."
            ),
        },
        {
            "titulo": "3. Substâncias Puras e Alotropia",
            "conteudo": (
                "SUBSTÂNCIA PURA: formada por um único tipo de matéria, "
                "com composição fixa e propriedades constantes. Pode "
                "ser simples ou composta.\n\n"
                "SUBSTÂNCIA SIMPLES: formada por um único elemento "
                "químico. Ex.: O₂ (gás oxigênio), O₃ (gás ozônio), "
                "Fe (ferro), H₂ (gás hidrogênio).\n\n"
                "SUBSTÂNCIA COMPOSTA: formada por mais de um elemento "
                "químico, combinados em proporção definida. Ex.: H₂O "
                "(água), CO₂ (gás carbônico), NaCl (cloreto de sódio), "
                "C₆H₁₂O₆ (glicose).\n\n"
                "ALOTROPIA: fenômeno em que um mesmo elemento químico "
                "forma substâncias simples diferentes, com "
                "propriedades distintas. Os alotropos têm "
                "arranjos atômicos ou moleculares diferentes.\n\n"
                "EXEMPLOS DE ALOTROPIA:\n"
                "- Carbono: diamante (rede cristalina tetraédrica, "
                "dureza máxima), grafite (camadas hexagonais, "
                "condutor, macio), fulerenos (C60, estrutura "
                "esférica), grafeno (folha de um átomo de espessura).\n"
                "- Oxigênio: O₂ (gás oxigênio, respiração) e O₃ "
                "(gás ozônio, camada de ozônio).\n"
                "- Enxofre: S₈ (monoclínico ou rômbico).\n"
                "- Fósforo: branco (P₄, tóxico, inflamável) e "
                "vermelho (polímero, mais estável)."
            ),
            "exemplo": (
                "A diferença entre diamante e grafite ilustra a "
                "alotropia. Ambos são feitos apenas de carbono, mas "
                "no diamante cada átomo se liga a outros quatro em "
                "uma rede tridimensional (durez máxima), enquanto na "
                "grafite os átomos formam camadas hexagonais fracamente "
                "ligadas (macia, condutora). O grafeno, isolado em "
                "2004 (Prêmio Nobel de Física 2010), é uma camada "
                "única de grafite — mais resistente que o aço e "
                "excelente condutor, prometendo revolução na "
                "eletrônica e na medicina (biossensores, entrega "
                "de fármacos)."
            ),
        },
        {
            "titulo": "4. Misturas Homogêneas e Heterogêneas",
            "conteudo": (
                "MISTURA: associação de duas ou mais substâncias sem "
                "reação química entre elas. A composição pode variar.\n\n"
                "MISTURA HOMOGÊNEA: aspecto uniforme, uma única fase. "
                "Também chamada de solução. Ex.: água + sal (liquida), "
                "ar atmosférico (gasosa), bronze (sólida).\n\n"
                "MISTURA HETEROGÊNEA: aspecto não uniforme, duas ou "
                "mais fases. Ex.: água + óleo, granito, água + areia.\n\n"
                "OBSERVAÇÃO IMPORTANTE: a distinção entre homogênea e "
                "heterogênea depende da escala de observação. O leite, "
                "por exemplo, parece homogêneo a olho nu, mas ao "
                "microscópio revela glóbulos de gordura em suspensão "
                "(micela) — é uma mistura heterogênea.\n\n"
                "TIPOS DE SOLUÇÕES:\n"
                "- Sólidas: ligas metálicas (bronze, aço), amálgama.\n"
                "- Líquidas: água salgada, álcool medicinal.\n"
                "- Gasosas: ar atmosférico (N₂, O₂, Ar, CO₂).\n\n"
                "CONCENTRAÇÃO DE SOLUÇÕES: pode ser expressa em g/L, "
                "% (m/m, m/V, V/V), mol/L (molaridade), molalidade, "
                "fração molar. Será aprofundada no tópico Soluções.\n\n"
                "FRACIONAMENTO: separação dos componentes de uma "
                "mistura. Cada método aproveita uma propriedade "
                "específica (temperatura de ebulição, solubilidade, "
                "densidade, magnetismo)."
            ),
            "exemplo": (
                "O soro fisiológico (NaCl 0,9% em água) é uma mistura "
                "homogênea usada em medicina. A concentração de 0,9% "
                "(m/V) é isotônica em relação ao plasma sanguíneo, "
                "evitando hemólise (ruptura de hemácias) ou "
                "crenação. Por isso é usado para hidratação, "
                "limpeza de feridas e diluição de medicamentos. "
                "Já a água + óleo é heterogênea porque óleo e água "
                "não se misturam — formam duas fases distintas."
            ),
        },
        {
            "titulo": "5. Processos de Separação de Misturas",
            "conteudo": (
                "Os métodos de separação aproveitam diferenças nas "
                "propriedades das substâncias.\n\n"
                "MISTURAS HETEROGÊNEAS:\n"
                "- Catação: separação manual (grãos e impurezas).\n"
                "- Levigação: arraste por água (ouro em sedimento).\n"
                "- Ventilação: sopro separa componentes leves.\n"
                "- Peneiração/Tamisação: tamanho das partículas.\n"
                "- Filtração: separa sólido de líquido/gás por "
                "filtro poroso.\n"
                "- Decantação: repouso separa por densidade.\n"
                "- Centrifugação: rotação acelerada separa por "
                "densidade (sangue em plasma e hemácias).\n"
                "- Flotação: bolhas aderem a um componente e o "
                "flutuam (mineração).\n"
                "- Separação magnética: ímã separa componentes "
                "magnéticos (ferro em areia).\n"
                "- Dissolução fracionada: solvente dissolve um "
                "componente e não o outro.\n\n"
                "MISTURAS HOMOGÊNEAS:\n"
                "- Destilação simples: líquido + sólido solúvel. "
                "Aquece, evapora o líquido e condensa.\n"
                "- Destilação fracionada: líquidos com pontos de "
                "ebulição diferentes (petróleo em refinarias).\n"
                "- Fusão fracionada: sólidos com pontos de fusão "
                "diferentes.\n"
                "- Cristalização fracionada: dissolução e "
                "precipitação seletiva.\n"
                "- Liquefação fracionada: gases com pontos de "
                "ebulição diferentes (ar: N₂, O₂, Ar).\n\n"
                "MATERIAIS DE LABORATÓRIO: béquer, balão de fundo "
                "redondo, erlenmeyer, proveta, pipeta, bureta, "
                "funil, funil de Buchner, balão de destilação, "
                "condensador, termômetro, almofariz e pistilo, "
                "dessecador, vidro de relógio."
            ),
            "exemplo": (
                "A destilação fracionada do petróleo é o processo "
                "industrial mais importante do mundo. O petróleo "
                "bruto é uma mistura complexa de hidrocarbonetos. "
                "Na torre de destilação, cada fração é coletada em "
                "alturas diferentes, conforme o ponto de ebulição: "
                "gás (metano, propano), gasolina, querosene, diesel, "
                "óleos lubrificantes, asfalto. Na medicina, a "
                "destilação é usada para purificar solventes e "
                "produzir álcool etílico para desinfecção."
            ),
        },
    ],
    "resumo": (
        "- Matéria: tem massa e ocupa espaço. Energia: capacidade de realizar trabalho.\n"
        "- Fenômeno físico: não altera composição. Fenômeno químico: forma novas substâncias.\n"
        "- Estados: sólido (forma e volume fixos), líquido (volume fixo), gasoso (ambos variáveis).\n"
        "- Mudanças de estado: fusão, solidificação, vaporização, liquefação, sublimação, ressublimação.\n"
        "- Substância simples: um elemento. Composta: mais de um elemento. Alotropia: formas diferentes do mesmo elemento.\n"
        "- Mistura homogênea = solução (1 fase). Heterogênea = 2+ fases.\n"
        "- Separação: filtração, decantação, destilação, cristalização, magnetismo, liquefação fracionada."
    ),
    "dicas": [
        "Fenômeno físico não muda a substância; fenômeno químico forma novas substâncias.",
        "Alotropia: diamante e grafite são ambos carbono puro, com propriedades diferentes.",
        "Mistura homogênea = 1 fase. Heterogênea = 2+ fases. O leite é heterogênea (micelas).",
        "Destilação simples: líquido + sólido. Fracionada: líquidos com PE diferentes.",
        "Decantação separa por densidade; filtração por tamanho de poro; magnetismo por propriedade magnética.",
        "Propriedades específicas identificam substâncias: densidade, PF, PE, solubilidade.",
    ],
    "pegadinhas": [
        "Achar que o ar é substância pura: é mistura homogênea de N₂, O₂, Ar, CO₂.",
        "Confundir alotropia com isomeria: alotropia é do mesmo elemento; isomeria é de compostos diferentes com mesma fórmula.",
        "Achar que água mineral é substância pura: é mistura homogênea com sais dissolvidos.",
        "Confundir fusão com dissolução: fusão é sólido → líquido por calor; dissolução é mistura com solvente.",
        "Esquecer que a temperatura NÃO muda durante a mudança de estado (calor latente).",
        "Achar que 'água pura' de torneira é substância pura: tem Cl₂, sais, etc. — é mistura.",
    ],
    "referencias": [
        "ATKINS, P.; JONES, L. Princípios de Química: Questionando a Visão Moderna. 5. ed. Porto Alegre: Bookman, 2012.",
        "FELTRE, P. Química Geral. 7. ed. São Paulo: Moderna, 2008.",
        "KOTZ, J. C.; TREICHEL, P. M. Química e Reações Químicas. 6. ed. Rio de Janeiro: LTC, 2010.",
        "RUSSELL, J. B. Química Geral. 2. ed. São Paulo: Makron Books, 2002.",
        "USBERCO, J.; SALVADOR, E. Química Geral. 12. ed. São Paulo: Saraiva, 2006.",
        "MORTIMER, E. F.; MACHADO, A. H. Química para o Ensino Médio. São Paulo: Scipione, 2010.",
    ],
}


def _header_footer(canvas_obj, doc):
    canvas_obj.saveState()
    width, height = A4
    if LOGO_PATH.exists():
        canvas_obj.drawImage(str(LOGO_PATH), 1.5*cm, height - 1.8*cm,
            width=1.2*cm, height=1.2*cm, preserveAspectRatio=True, mask='auto')
    canvas_obj.setFillColor(PRIMARY)
    canvas_obj.setFont(_FB, 9)
    canvas_obj.drawString(3*cm, height - 1.2*cm, "PAES MED AI")
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Química — Princípios Elementares")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "QU_PRINCIPIOS_ELEMENTARES.pdf"

    images_data = [
        {"file": "br_qui1_estados.jpg",
         "caption": "Estados físicos da matéria: sólido, líquido e gasoso",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/quimica/estados-fisicos-materia.htm"},
        {"file": "br_qui1_mudancas.jpg",
         "caption": "Mudanças de estado físico: fusão, vaporização, sublimação",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/estados-fisicos-da-materia/"},
        {"file": "br_qui1_substancias.jpg",
         "caption": "Substâncias simples e compostas: exemplos e fórmulas",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/substancias-puras-e-misturas/"},
        {"file": "br_qui1_separacao.jpg",
         "caption": "Separação de misturas homogêneas: métodos e processos",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/separacao-de-misturas/"},
        {"file": "br_qui1_destilacao.jpg",
         "caption": "Destilação simples e fracionada: separação por ponto de ebulição",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/separacao-de-misturas/"},
    ]

    downloaded_images = []
    for img_data in images_data:
        path = IMG_DIR / img_data["file"]
        if path.exists() and path.stat().st_size > 1000:
            downloaded_images.append({
                "path": str(path),
                "caption": img_data["caption"],
                "source": img_data["source"],
                "source_url": img_data["source_url"],
            })
            print(f"  OK: {img_data['file']}")
        else:
            print(f"  FALTANDO: {img_data['file']}")

    styles = getSampleStyleSheet()
    style_title = ParagraphStyle('T', parent=styles['Title'], fontName=_FB,
        fontSize=24, textColor=PRIMARY, spaceAfter=6, alignment=TA_CENTER)
    style_sub = ParagraphStyle('S', parent=styles['Normal'], fontName=_FI,
        fontSize=12, textColor=TEXT_LIGHT, spaceAfter=20, alignment=TA_CENTER)
    style_h2 = ParagraphStyle('H', parent=styles['Heading2'], fontName=_FB,
        fontSize=15, textColor=PRIMARY_DARK, spaceBefore=18, spaceAfter=8)
    style_body = ParagraphStyle('B', parent=styles['Normal'], fontName=_FN,
        fontSize=11, textColor=TEXT_DARK, leading=16, alignment=TA_JUSTIFY, spaceAfter=8)
    style_ex = ParagraphStyle('E', parent=style_body, fontName=_FI, fontSize=10,
        textColor=PRIMARY_DARK, leftIndent=15, rightIndent=15,
        borderColor=PRIMARY, borderWidth=0.5, borderPadding=8,
        backColor=PRIMARY_LIGHT, spaceBefore=8, spaceAfter=12)
    style_cap = ParagraphStyle('C', parent=styles['Normal'], fontName=_FI,
        fontSize=9, textColor=TEXT_LIGHT, alignment=TA_CENTER, spaceAfter=4)
    style_ref = ParagraphStyle('R', parent=styles['Normal'], fontName=_FN,
        fontSize=10, textColor=TEXT_DARK, leading=14, spaceAfter=6,
        leftIndent=15, firstLineIndent=-15)

    story = []
    story.append(Spacer(1, 3*cm))
    if LOGO_PATH.exists():
        img = Image(str(LOGO_PATH), width=3*cm, height=3*cm)
        img.hAlign = 'CENTER'
        story.append(img)
    story.append(Spacer(1, 1*cm))
    story.append(Paragraph(CONTENT["titulo"], style_title))
    story.append(Paragraph(f'{CONTENT["disciplina"]} — {CONTENT["topico"]}', style_sub))
    story.append(HRFlowable(width="60%", thickness=2, color=PRIMARY, hAlign='CENTER'))
    story.append(Spacer(1, 0.8*cm))
    story.append(Paragraph(CONTENT["introducao"].replace('\n\n', '<br/><br/>'), style_body))
    story.append(PageBreak())

    for img_pos, sec in enumerate(CONTENT["secoes"]):
        story.append(Paragraph(sec["titulo"], style_h2))
        story.append(Paragraph(sec["conteudo"].replace('\n\n', '<br/><br/>').replace('\n', '<br/>'), style_body))
        if sec.get("exemplo"):
            story.append(Paragraph(f'<b>Exemplo clínico/prático:</b><br/>{sec["exemplo"]}', style_ex))
        if img_pos < len(downloaded_images):
            img_data = downloaded_images[img_pos]
            try:
                pil_img = PILImage.open(img_data["path"])
                w, h = pil_img.size
                ratio = min(14*cm / w, 10*cm / h)
                img = Image(img_data["path"], width=w*ratio, height=h*ratio)
                img.hAlign = 'CENTER'
                story.append(Spacer(1, 0.3*cm))
                story.append(img)
                story.append(Paragraph(
                    f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                    style_cap))
                story.append(Spacer(1, 0.3*cm))
            except Exception as e:
                print(f"  Erro imagem: {e}")

    used = len(CONTENT["secoes"])
    for img_data in downloaded_images[used:]:
        try:
            pil_img = PILImage.open(img_data["path"])
            w, h = pil_img.size
            ratio = min(14*cm / w, 10*cm / h)
            img = Image(img_data["path"], width=w*ratio, height=h*ratio)
            img.hAlign = 'CENTER'
            story.append(Spacer(1, 0.3*cm))
            story.append(img)
            story.append(Paragraph(
                f'<i>{img_data["caption"]}</i><br/><font size="7" color="#999">Imagem: {img_data["source"]}</font>',
                style_cap))
            story.append(Spacer(1, 0.3*cm))
        except Exception as e:
            print(f"  Erro imagem: {e}")

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Resumo", style_h2))
    story.append(Paragraph(CONTENT["resumo"].replace('\n', '<br/>'), style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Dicas para a Prova", style_h2))
    for dica in CONTENT["dicas"]:
        story.append(Paragraph(f'• {dica}', style_body))

    story.append(Spacer(1, 0.3*cm))
    story.append(Paragraph("Pegadinhas Comuns", style_h2))
    for peg in CONTENT["pegadinhas"]:
        story.append(Paragraph(f'⚠ {peg}', style_body))

    story.append(Spacer(1, 0.5*cm))
    story.append(Paragraph("Referências", style_h2))
    for ref in CONTENT["referencias"]:
        story.append(Paragraph(ref, style_ref))

    doc = SimpleDocTemplate(str(pdf_path), pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm, topMargin=2.5*cm, bottomMargin=2*cm,
        title=f'PAES MED AI — {CONTENT["titulo"]}', author='PAES MED AI')
    doc.build(story, onFirstPage=_header_footer, onLaterPages=_header_footer)

    size_kb = pdf_path.stat().st_size / 1024
    print(f"\nPDF gerado: {pdf_path}")
    print(f"Tamanho: {size_kb:.1f} KB")
    return pdf_path


if __name__ == "__main__":
    generate_pdf()
