# -*- coding: utf-8 -*-
"""Gera PDF profissional ABNT do material de Biologia - Introdução à Biologia.

Texto 100% PT-BR (Português Brasileiro) com acentuação correta.
Imagens de sites educacionais brasileiros.
Referências em formato ABNT.
"""

import os
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, HRFlowable, PageBreak
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from PIL import Image as PILImage

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
    "titulo": "Introdução à Biologia",
    "disciplina": "Biologia",
    "topico": "Introdução à Biologia",
    "subtopico": "Método Científico, Origem da Vida, Células e Bioelementos",
    "introducao": (
        "A Biologia é a ciência que estuda a vida e os seres vivos. "
        "É uma das áreas mais amplas da ciência, abrangendo desde a "
        "investigação de moléculas até ecossistemas inteiros. Para "
        "compreendê-la, é necessário dominar o método científico, "
        "as características comuns a todos os seres vivos, as "
        "teorias sobre a origem da vida, a estrutura celular e a "
        "composição química dos organismos.\n\n"
        "Este material revisa os conceitos introdutórios essenciais "
        "para o vestibular de Medicina: seres vivos e não vivos, "
        "método científico, geração espontânea, biogênese, "
        "evolução química, endossimbiose, procariontes e "
        "eucariontes, e a importância dos nutrientes para a saúde."
    ),
    "secoes": [
        {
            "titulo": "1. Biologia e o Método Científico",
            "conteudo": (
                "Biologia (do grego bios = vida; logos = estudo) é a "
                "ciência que estuda os seres vivos: sua origem, "
                "estrutura, funcionamento, evolução, reprodução, "
                "relações com o meio e classificação. É dividida em "
                "várias ramificações: Citologia, Genética, "
                "Microbiologia, Zoologia, Botânica, Ecologia, "
                "Fisiologia, Anatomia, Histologia, Bioquímica, "
                "Biologia Molecular.\n\n"
                "O MÉTODO CIENTÍFICO é o conjunto de etapas usado para "
                "investigar fenômenos naturais de forma organizada e "
                "reprodutível. Etapas:\n"
                "1. Observação do fenômeno;\n"
                "2. Levantamento de questionamentos;\n"
                "3. Formulação de hipóteses (explicações provisórias);\n"
                "4. Experimentação controlada;\n"
                "5. Coleta e análise de dados;\n"
                "6. Conclusões e aceitação/rejeição da hipótese;\n"
                "7. Elaboração de teorias e leis (quando amplamente "
                "comprovadas).\n\n"
                "CONCEITOS IMPORTANTES:\n"
                "- Fato: observação comprovada;\n"
                "- Lei: relação entre fatos observáveis;\n"
                "- Teoria: conjunto de leis e hipóteses amplamente "
                "comprovadas;\n"
                "- Hipótese: explicação provisória, passível de teste;\n"
                "- Modelo: representação simplificada de um fenômeno.\n\n"
                "Características do método científico: objetividade "
                "(sem influência de crenças pessoais), reprodutibilidade "
                "(outros podem repetir o experimento), falibilidade "
                "(as teorias podem ser refutadas por novas evidências), "
                "sistematicidade (procedimento organizado)."
            ),
            "exemplo": (
                "A descoberta do vírus causador da AIDS (HIV) em 1983 "
                "ilustra o método científico. Cientistas observaram "
                "casos de pacientes com imunodeficiência sem causa "
                "conhecida (observação), propuseram que fosse um agente "
                "infeccioso novo (hipótese), isolaram o vírus em "
                "culturas celulares (experimento), sequenciaram seu "
                "genoma (dados) e confirmaram a causa da doença "
                "(conclusão). Depois, desenvolveram testes e "
                "tratamentos. Hoje, a terapia antirretroviral (TARV) "
                "transformou a AIDS em uma doença crônica controlável."
            ),
        },
        {
            "titulo": "2. Características dos Seres Vivos",
            "conteudo": (
                "Todos os seres vivos compartilham características "
                "comuns. A presença de células e a capacidade de "
                "realizar atividades vitais definem a vida.\n\n"
                "PRINCIPAIS CARACTERÍSTICAS:\n"
                "- Compostos por células: toda a vida é celular. Células "
                "são a menor unidade viva.\n"
                "- Nutrição: obtenção e uso de energia e matéria. "
                "Autotróficos (produzem o próprio alimento) e "
                "heterotróficos (dependem de outros seres).\n"
                "- Reprodução: formação de descendentes. Assexuada "
                "(sem gametas, geração idêntica) e sexuada (com "
                "gametas, variabilidade).\n"
                "- Crescimento e desenvolvimento: aumento de tamanho e "
                "complexidade.\n"
                "- Respiração/Metabolismo: reações químicas que "
                "fornecem energia.\n"
                "- Excreção: eliminação de substâncias tóxicas.\n"
                "- Irritabilidade: resposta a estímulos.\n"
                "- Locomoção: movimento do corpo ou de partes.\n"
                "- Homeostase: manutenção do equilíbrio interno.\n"
                "- Evolução: mudanças hereditárias ao longo das "
                "gerações.\n\n"
                "TEORIA CELULAR: toda a vida é composta por células; a "
                "célula é a unidade básica; toda a célula vem de outra "
                "célula (Virchow)."
            ),
            "exemplo": (
                "A resposta à insulina ilustra a homeostase e o "
                "metabolismo. Após uma refeição, a glicose no sangue "
                "aumenta. O pâncreas libera insulina, que estimula as "
                "células a absorverem glicose e abaixarem a glicemia. "
                "Em diabetes tipo 1, o pâncreas não produz insulina; "
                "em tipo 2, as células resistem à insulina. Sem "
                "tratamento, a hiperglicemia causa danos nos nervos, "
                "rins, olhos e vasos sanguíneos."
            ),
        },
        {
            "titulo": "3. Teorias da Origem da Vida",
            "conteudo": (
                "A origem da vida é um dos maiores enigmas da ciência. "
                "Diversas teorias foram propostas ao longo da história.\n\n"
                "Geração espontânea (abiogênese): antiga crença de que "
                "seres vivos surgiam de matéria inanimada (vermes de "
                "lodo, moscas de carniça). Foi refutada por "
                "experimentos científicos.\n\n"
                "FRANCESCO REDI (1668): mostrou que moscas não surgem "
                "espontaneamente de carne. Colocou carne em frascos "
                "fechados, abertos e cobertos por gaze. Moscas só "
                "apareceram nos frascos abertos, provando que vinham "
                "de ovos depositados por moscas adultas.\n\n"
                "LOUIS PASTEUR (1859): refutou definitivamente a "
                "geração espontânea. Usou frascos de vidro com gargalo "
                "de cisne (pescoço de cisne) com caldo nutritivo. O "
                "ar entrava, mas microrganismos ficavam presos no "
                "gargalo. O caldo permaneceu estéril. Quando o "
                "gargalo era quebrado, microorganismos entravam e o "
                "caldo apodrecia.\n\n"
                "TEORIA DA BIOGÊNESE: toda a vida vem de vida "
                "preexistente (omnis cellula e cellula — Virchow).\n\n"
                "EVOLUÇÃO QUÍMICA (Oparin-Haldane): a vida surgiu por "
                "processos químicos na Terra primitiva. A atmosfera "
                "redutora (CH4, NH3, H2, H2O vapor) recebia energia "
                "(raios UV, descargas elétricas, vulcanismo), formando "
                "moléculas orgânicas simples, depois aminoácidos, "
                "nucleotídeos, proteínas, ácidos nucleicos e, por fim, "
                "sistemas autocatalíticos (coacervados). O experimento "
                "de Miller-Urey (1953) produziu aminoácidos em "
                "condições simuladas da Terra primitiva.\n\n"
                "TEORIA HETEROTRÓFICA (Oparin): os primeiros seres eram "
                "heterotróficos, se alimentando de moléculas orgânicas "
                "já presentes no caldo primordial.\n\n"
                "TEORIA AUTOTRÓFICA: os primeiros seres já seriam "
                "capazes de produzir seu próprio alimento, como "
                "quimiossintetizantes."
            ),
            "exemplo": (
                "O experimento de Miller-Urey é um marco. Simulou a "
                "atmosfera primitiva com metano, amônia, hidrogênio e "
                "vapor d'água, e aplicou descargas elétricas (raios). "
                "Após uma semana, encontraram aminoácidos e outras "
                "moléculas orgânicas. Embora hoje se saiba que a "
                "atmosfera primitiva provavelmente era diferente, o "
                "experimento provou que a síntese de moléculas da vida "
                "é possível por processos químicos naturais, sem "
                "necessidade de forças sobrenaturais."
            ),
        },
        {
            "titulo": "4. Endossimbiose e Células",
            "conteudo": (
                "A teoria da endossimbiose, proposta por Lynn Margulis "
                "em 1967, explica a origem das organelas de células "
                "eucarióticas a partir de relações simbióticas entre "
                "procariontes.\n\n"
                "PROPOSTA: células eucarióticas ancestrais (provavelmente "
                "semelhantes a Archaea) englobaram bactérias "
                "aeróbias e cianobactérias por fagocitose. Em vez de "
                "serem digeridas, essas bactérias passaram a viver de "
                "forma simbiótica dentro da célula hospedeira.\n\n"
                "EVIDÊNCIAS DA ENDOSSIMBIOSE:\n"
                "- Mitocôndrias e cloroplastos têm DNA próprio, "
                "circular, semelhante ao de bactérias;\n"
                "- Têm ribossomos do tipo 70S (procariontes), não 80S "
                "(eucariontes);\n"
                "- Reproduzem-se por divisão binária, como bactérias;\n"
                "- Possuem duas membranas — a externa veio da célula "
                "hospedeira, a interna do procarionte;\n"
                "- Os genes das mitocôndrias são semelhantes aos de "
                "bactérias do grupo Rickettsia; os dos cloroplastos, "
                "aos das cianobactérias.\n\n"
                "PROCARIONTES E EUCARIONTES:\n"
                "- Procariontes: sem núcleo definido (nucleoide), sem "
                "organelas membranosas, DNA circular, ribossomos 70S. "
                "Bactérias e Archaea.\n"
                "- Eucariontes: com núcleo definido, organelas "
                "membranosas (retículo endoplasmático, complexo de "
                "Golgi, mitocôndrias, lisossomos, peroxissomos), DNA "
                "linear, ribossomos 80S. Protistas, fungos, plantas e "
                "animais.\n\n"
                "IMPORTÂNCIA: a endossimbiose explica a origem da "
                "fotossíntese (cloroplastos) e da respiração aeróbia "
                "(mitocôndrias) nas células eucarióticas, permitindo "
                "a evolução de organismos complexos."
            ),
            "exemplo": (
                "A doença de mitochondrial é um exemplo prático. Como "
                "as mitocôndrias têm DNA próprio herdado apenas da mãe, "
                "mutações no DNA mitocondrial causam doenças que "
                "afetam tecidos com alto consumo de energia: músculos, "
                "cérebro, nervos, coração. A síndrome de MELAS "
                "causa derrames em jovens, enxaquecas e fraqueza "
                "muscular. Isso confirma que as mitocôndrias são "
                "descendentes de antigas bactérias, com genoma próprio."
            ),
        },
        {
            "titulo": "5. Substâncias, Bioelementos e Nutrientes",
            "conteudo": (
                "Os seres vivos são compostos por moléculas orgânicas e "
                "inorgânicas. A quantidade de cada elemento varia, mas "
                "alguns são essenciais.\n\n"
                "BIOELEMENTOS (ELEMENTOS QUÍMICOS):\n"
                "- Macroelementos (macronutrientes inorgânicos): C, H, "
                "O, N (95% da matéria viva); P, S, K, Ca, Mg, Na, Cl. "
                "Necessários em grandes quantidades.\n"
                "- Microelementos (micronutrientes inorgânicos): Fe, "
                "Zn, Cu, Mn, I, F, Se, Mo, Co, Cr. Necessários em "
                "pequenas quantidades, mas essenciais. Deficiências "
                "causam doenças.\n\n"
                "MOLECULAS ORGÂNICAS: carboidratos, lipídios, proteínas, "
                "ácidos nucleicos. Baseadas no carbono (C).\n\n"
                "NUTRIENTES NA ALIMENTAÇÃO:\n"
                "- Macronutrientes: carboidratos, proteínas, lipídios, "
                "água. Fornecem energia e matéria para crescimento.\n"
                "- Micronutrientes: vitaminas e minerais. Atuam como "
                "coenzimas, reguladores e componentes de estruturas.\n\n"
                "FUNÇÕES NA SAÚDE HUMANA:\n"
                "- Carboidratos: principal fonte de energia;\n"
                "- Proteínas: crescimento, reparo, enzimas, anticorpos, "
                "hormônios;\n"
                "- Lipídios: reserva energética, membranas, hormônios "
                "esteroide;\n"
                "- Vitaminas: A (visão), D (ossos), C (imunidade), "
                "B (metabolismo);\n"
                "- Minerais: Ca e D (ossos), Fe (hemoglobina), I "
                "(hormônios tireoidianos), Zn (imunidade e cicatrização), "
                "F (dentes).\n\n"
                "DESNUTRIÇÃO E EXCESSO: deficiências de vitaminas ou "
                "minerais causam doenças (anemia por ferro, bócio por "
                "iodo, escorbuto por vitamina C, raquitismo por "
                "vitamina D/cálcio). Excesso de sódio, açúcar e gorduras "
                "predispõe a hipertensão, diabetes e doenças "
                "cardiovasculares."
            ),
            "exemplo": (
                "A anemia ferropriva é a deficiência nutricional mais "
                "comum no mundo. O ferro é essencial para a produção de "
                "hemoglobina, a proteína que transporta oxigênio no "
                "sangue. Sem ferro suficiente, ocorre anemia, com "
                "cansaço, fraqueza, palidez e dificuldade de concentração. "
                "Fontes de ferro: carnes vermelhas, fígado, feijão, "
                "lentilhas, espinafre. A vitamina C melhora a absorção "
                "do ferro de origem vegetal, enquanto o chá e o café "
                "prejudicam."
            ),
        },
    ],
    "resumo": (
        "- Biologia estuda a vida; método científico: observação, hipótese, experimento, conclusão.\n"
        "- Seres vivos: células, nutrição, reprodução, crescimento, metabolismo, homeostase, evolução.\n"
        "- Geração espontânea refutada por Redi e Pasteur; biogênese: toda a vida vem de vida.\n"
        "- Evolução química: moléculas simples → complexas; Miller-Urey produziu aminoácidos.\n"
        "- Endossimbiose: mitocôndrias e cloroplastos derivam de bactérias.\n"
        "- Procariontes: sem núcleo; Eucariontes: com núcleo e organelas.\n"
        "- Macro e micronutrientes essenciais; deficiências e excessos causam doenças."
    ),
    "dicas": [
        "Decore: Redi (carniça e moscas) e Pasteur (gargalo de cisne) refutaram geração espontânea.",
        "Pasteur provou biogênese: toda a vida vem de vida preexistente.",
        "Endossimbiose: mitocôndrias de bactérias aeróbias, cloroplastos de cianobactérias.",
        "Mitocôndrias têm DNA circular, ribossomos 70S, duas membranas — evidências de origem bacteriana.",
        "Bioelementos principais: CHON (carbono, hidrogênio, oxigênio, nitrogênio) = 95% da matéria viva.",
        "Anemia por ferro, bócio por iodo, raquitismo por vitamina D/cálcio, escorbuto por vitamina C.",
    ],
    "pegadinhas": [
        "Achar que Redi provou a biogênese: Redi refutou geração espontânea em macroorganismos. Pasteur completou para microrganismos.",
        "Confundir evolução química com evolução biológica: evolução química é origem das moléculas; evolução biológica é mudança de populações.",
        "Achar que mitocôndrias são procariontes: mitocôndrias são organelas EUCARIÓTICAS, mas derivam de antigas bactérias.",
        "Esquecer que procariontes NÃO têm núcleo definido — têm nucleoide.",
        "Confundir macroelementos com micronutrientes: macro = grandes quantidades (C, H, O, N); micro = pequenas (Fe, Zn, I).",
        "Achar que vírus são seres vivos: vírus NÃO têm metabolismo próprio e dependem de célula hospedeira.",
    ],
    "referencias": [
        "CAMPBELL, N. A.; REECE, J. B. Biologia. 8. ed. Porto Alegre: Artmed, 2009.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "MARGULIS, L. Origin of Eukaryotic Cells. New Haven: Yale University Press, 1970.",
        "MILLER, S. L.; UREY, H. C. Organic Compound Synthesis on the Primitive Earth. Science, v. 130, n. 3370, p. 245-251, 1959.",
        "OPARIN, A. I. The Origin of Life. 2. ed. New York: Dover, 1965.",
        "MAHAN, L. K.; RAYMOND, J. L. Krause: Alimentos, Nutrição e Dietoterapia. 14. ed. Rio de Janeiro: Elsevier, 2017.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Introdução")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_INTRODUCAO_BIOLOGIA.pdf"

    images_data = [
        {"file": "br_intro_seres.jpg",
         "caption": "Seres vivos e seres não vivos: características da vida",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/caracteristicas-dos-seres-vivos/"},
        {"file": "br_intro_metodo.jpg",
         "caption": "Método científico: observação, hipótese, experimento e conclusão",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/caracteristicas-dos-seres-vivos/"},
        {"file": "br_intro_celulas.jpg",
         "caption": "Tipos de células: procariontes e eucariontes",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/caracteristicas-dos-seres-vivos.htm"},
        {"file": "br_intro_endossimbiose.jpg",
         "caption": "Endossimbiose: origem das mitocôndrias e cloroplastos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/"},
        {"file": "br_intro_nutrientes.jpg",
         "caption": "Nutrientes: macro e micronutrientes essenciais",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/endossimbiose/"},
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
