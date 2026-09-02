"""Gera PDF profissional ABNT do material de Biologia - Zoologia.

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
    "titulo": "Zoologia",
    "disciplina": "Biologia",
    "topico": "Zoologia",
    "subtopico": "Invertebrados e Vertebrados",
    "introducao": (
        "A Zoologia estuda os animais. Os animais são seres "
        "eucariontes, multicelulares, heterotróficos, sem parede "
        "celular e, na maioria, com capacidade de locomoção. "
        "Representam a maior parte da biodiversidade do planeta.\n\n"
        "O conhecimento de Zoologia é essencial para a Medicina, pois "
        "muitos animais transmitem doenças (vetores), abrigam "
        "parasitas e produzem venenos, medicamentos e modelos para "
        "pesquisa biomédica. Além disso, estudos comparados em "
        "anatomia e fisiologia animal ajudam a compreender a "
        "biologia humana."
    ),
    "secoes": [
        {
            "titulo": "1. Invertebrados I: Poríferos, Cnidários, Platelmintos e Nematódeos",
            "conteudo": (
                "PORÍFEROS (esponjas): os animais mais simples. Sem "
                "tecidos nem órgãos. Corpo poroso com osculos e poros. "
                "Células especializadas: coanócitos (com flagelos que "
                "geram corrente de água), porócitos (poros) e amebócitos "
                "(nutrição e regeneração). Vivem fixas na fase adulta, "
                "em ambientes aquáticos. Filtração: a água entra por "
                "poros, passa pela cavidade interna (esponjocel) e sai "
                "pelo osculo. Exemplos: esponja-do-mar, esponja-de-banho.\n\n"
                "CNIDÁRIOS: simetria radial, células urticantes "
                "(cnidócitos) que lançam nematocistos. Têm duas formas "
                "de vida: pólipo (sésil, reprodutivo assexuado) e medusa "
                "(livre, com gametas). Exemplos: hidras, águas-vivas, "
                "anêmonas, corais. Importância médica: queimaduras de "
                "água-viva, venenos potenciais, colônias de corais "
                "formam recifes.\n\n"
                "PLATELMINTOS: vermes achatados dorsoventralmente, "
                "acelomados, simetria bilateral. Sem sistema "
                "circulatório (difusão). Classe Turbellaria (planárias, "
                "livres), Trematoda (vermes achatados — Schistosoma, "
                "Fasciola), Cestoda (tenías — Taenia saginata, T. "
                "solium). Os cestodos são parasitas intestinais, sem "
                "sistema digestório, absorvem nutrientes pela parede.\n\n"
                "NEMATÓDEOS: vermes cilíndricos, pseudocelomados, "
                "completes (todos os sistemas). Cúticula resistente. "
                "Muitos são parasitas humanos: Ascaris lumbricoides "
                "(ascaridíase), Enterobius vermicularis (oxiuríase), "
                "Ancylostoma (ancilostomose), Necator (necatorose), "
                "Wuchereria (filariose), Strongyloides."
            ),
            "exemplo": (
                "A hidra (Cnidaria) é um organismo-modelo em biologia "
                "regenerativa. Pode regenerar corpo inteiro a partir de "
                "pequenos fragmentos. Seu sistema nervoso é uma rede "
                "difusa (sem cérebro), mas consegue coordenar "
                "movimentos e respostas ao ambiente. Cientistas estudam "
                "cnidários para entender regeneração, envelhecimento e "
                "desenvolvimento de células-tronco."
            ),
        },
        {
            "titulo": "2. Invertebrados II: Anelídeos, Moluscos, Artrópodes e Equinodermos",
            "conteudo": (
                "ANELÍDEOS: vermes segmentados (metameria), celomados, "
                "sistema circulatório fechado. Classe Oligochaeta "
                "(minhocas — terrícolas), Polychaeta (poliquetas — "
                "marinhos), Hirudinea (sanguessugas — parasitas). As "
                "minhocas são importantes para a agricultura (aeram o "
                "solo, decompõem matéria orgânica).\n\n"
                "MOLUSCOS: corpo mole, cavidade pé (muscular) e manto "
                "(protege e secreta concha). Classe Bivalvia (ostras, "
                "mexilhões, vieiras), Gastropoda (caracóis, lesmas), "
                "Cephalopoda (polvos, lulas, chocos — sistema nervoso "
                "avançado). Alguns moluscos são vetores de parasitas: "
                "Biomphalaria transmite esquistossomose (Schistosoma "
                "mansoni); caramujos de água doce e crustáceos podem "
                "transmitir angiostrongilíase (verme da meningite).\n\n"
                "ARTRÓPODES: maior filo do reino animal. Exoesqueleto de "
                "quitina, apêndices articulados, corpo segmentado. "
                "Classes: Insecta (insetos — abelhas, moscas, "
                "besouros), Arachnida (aranhas, escorpiões, carrapatos), "
                "Crustacea (caranguejos, lagostas, camarões), Diplopoda "
                "(piolhos-de-cobra), Chilopoda (lacraias), Merostomata "
                "(limulas). Insetos têm 6 patas, aracnídeos 8, "
                "crustáceos 10 ou mais (decápodes). Muitos são vetores "
                "de doenças.\n\n"
                "EQUINODERMOS: simetria radial adulta, sistema ambulacral "
                "com pés ambulacrais, esqueleto interno de placas "
                "calcáreas. Exemplos: estrelas-do-mar, ouriços-do-mar, "
                "holotúrias (pepinos-do-mar), ofiúros. Importância "
                "econômica e ecológica nos oceanos."
            ),
            "exemplo": (
                "Os artrópodes são os principais vetores de doenças "
                "humanas. O mosquito Aedes aegypti transmite dengue, "
                "zika, chikungunya e febre amarela urbana. O Anopheles "
                "transmite malária. O Culex transmite filariose e "
                "encefalite. Carrapatos (Ixodes) transmitem doença de "
                "Lyme (Borrelia burgdorferi). Pulgas (Xenopsylla) "
                "transmitem peste (Yersinia pestis). Por isso, o "
                "controle de artrópodes é central na saúde pública."
            ),
        },
        {
            "titulo": "3. Cordados I: Características e Peixes",
            "conteudo": (
                "Os cordados compartilham, em alguma fase da vida, "
                "notocorda, cordo neural dorsal, fendas faríngeas e "
                "tubo digestório ventral. O subfilo Vertebrata inclui os "
                "animais com coluna vertebral.\n\n"
                "CARACTERÍSTICAS DOS CORDADOS:\n"
                "- Notocorda (espécie de bastão flexível);\n"
                "- Tubo nervoso dorsal oco;\n"
                "- Fendas faríngeas (respiração/filtração);\n"
                "- Tubo digestório abaixo do tubo nervoso;\n"
                "- Corpo segmentado (metameria em vertebrados).\n\n"
                "PEIXES: primeira classe de vertebrados. Respiração por "
                "brânquias, pele com escamas, corpo hidrodinâmico, "
                "locomoção por nadadeiras. Dividem-se em: Chondrichthyes "
                "(cartilaginosos — tubarões, raias, chimæras) e "
                "Osteichthyes (ósseos — atum, salmão, tilápia, sardinha). "
                "A brânquia é um órgão respiratório muito eficiente na "
                "extração de O2 da água.\n\n"
                "ANFÍBIOS: pele úmida e rica em vasos (respiração "
                "cutânea), metamorfose (girino → adulto), reprodução em "
                "água (ovos sem casca). Ordem Anura (sapos, rãs), "
                "Urodela (salamandras), Apoda (cobra-cega). Exemplos: "
                "sapo-cururu, rã-manteiga, perereca. Os anfíbios são "
                "bioindicadores de qualidade da água."
            ),
            "exemplo": (
                "Os girinos de anfíbios são bioindicadores sensíveis. "
                "Eles respiram por brânquias externas e vivem em água. "
                "Agrotóxicos e metais pesados afetam seu desenvolvimento, "
                "causando malformações. Estudos de populações de anfíbios "
                "ajudam a detectar contaminação ambiental. Além disso, "
                "a pele de algumas rãs e sapos secreta peptídeos com "
                "atividade antimicrobiana e analgésica, inspirando "
                "pesquisa para novos fármacos."
            ),
        },
        {
            "titulo": "4. Cordados II: Répteis, Aves e Mamíferos",
            "conteudo": (
                "RÉPTEIS: pele grossa e seca com escamas ou placas "
                "córneas, respiração pulmonar, ovos amnióticos com casca "
                "(não dependem de água), sangue frio (ectotérmicos). "
                "Ordes: Squamata (lagartos e cobras), Chelonia "
                "(tartarugas), Crocodilia (jacarés, crocodilos), "
                "Rhynchocephalia (tuatara). Algumas serpentes são "
                "peçonhentas (Bothrops, Crotalus — cascavéis; Lachesis "
                "— surucucu).\n\n"
                "AVES: penas, bico, ossos pneumáticos (ocos), elevado "
                "metabolismo endotérmico, quatro câmaras cardíacas. "
                "Adaptadas ao voo (exceções: avestruz, ema, pinguim). "
                "Respiração eficiente com sacos aéreos (fluxo unidirecional). "
                "Importância ecológica: dispersão de sementes, polinização, "
                "controle de pragas. Algumas aves transmitem doenças: "
                "psitacose (Chlamydia psittaci), influenza aviária H5N1.\n\n"
                "MAMÍFEROS: glândulas mamárias, pelos, endotermia, "
                "dente heterodonte (na maioria), quatro câmaras cardíacas, "
                "diafragma. Subclasses: Prototheria (ovíparos — "
                "ornitorrinco, equidna), Metatheria (marsupiais — "
                "canguru, gambá, catita), Eutheria (placentários — "
                "humanos, baleias, morcegos, gado).\n\n"
                "HUMANOS: mamíferos placentários, primatas, bípedes, "
                "com cérebro altamente desenvolvido. A anatomia humana é "
                "comparada com a de outros vertebrados para entender "
                "homologias (membros anteriores modificados: asa, nadadeira, "
                "pata, braço humano)."
            ),
            "exemplo": (
                "Morcegos (ordem Chiroptera) são os únicos mamíferos "
                "capazes de voo verdadeiro. Muitos se alimentam de insetos "
                "e são importantes polinizadores e dispersores de sementes. "
                "Algumas espécies são reservatórios de vírus: coronavírus, "
                "raiva, vírus Nipah e Hendra. A COVID-19 provavelmente "
                "teve origem em morcegos, com possível hospedeiro "
                "intermediário. O estudo de morcegos é essencial para "
                "a vigilância de zoonoses (doenças transmitidas de "
                "animais ao humano)."
            ),
        },
    ],
    "resumo": (
        "- Poríferos: sem tecidos, poros, filtração de água.\n"
        "- Cnidários: simetria radial, cnidócitos, pólipo e medusa.\n"
        "- Platelmintos: achatados, acelomados, parasitas (tenía, esquistossoma).\n"
        "- Nematódeos: vermes cilíndricos, pseudocelomados (ascaridíase, oxiuríase).\n"
        "- Anelídeos: metameria (minhoca, sanguessuga).\n"
        "- Moluscos: corpo mole, manto, concha (caracóis, polvos, ostras).\n"
        "- Artrópodes: exoesqueleto de quitina, maiores vetores de doenças.\n"
        "- Equinodermos: simetria radial, pés ambulacrais.\n"
        "- Cordados: notocorda, tubo nervoso dorsal. Vertebrados: peixes, anfíbios, répteis, aves, mamíferos.\n"
        "- Peixes = brânquias; anfíbios = pele úmida; répteis = pele seca; aves = penas; mamíferos = pelos e glândulas mamárias."
    ),
    "dicas": [
        "Decore os filos de invertebrados: Porífera, Cnidária, Platyhelminthes, Nematoda, Annelida, Mollusca, Arthropoda, Echinodermata, Chordata.",
        "Artrópodes: 6 patas = insetos; 8 patas = aracnídeos; 10+ patas = crustáceos (decápodes).",
        "Cnidócitos são exclusivos dos cnidários. Cniderios = urticantes.",
        "Moluscos Bivalvia (2 conchas), Gastropoda (1 concha), Cephalopoda (sem concha externa).",
        "Vertebrados: peixes (brânquias), anfíbios (pele úmida), répteis (pele seca/escamas), aves (penas), mamíferos (pelos/mamas).",
        "Anfíbios e peixes dependem de água para reprodução. Répteis, aves e mamíferos têm amniotos (não dependem).",
    ],
    "pegadinhas": [
        "Achar que esponjas são plantas: são animais (Porífera) — alimentam-se por filtração de partículas.",
        "Confundir platelmintos com nematódeos: platelmintos são achatados e acelomados; nematódeos são cilíndricos e pseudocelomados.",
        "Achar que aranhas são insetos: aracnídeos têm 8 patas e 2 segmentos corporais; insetos têm 6 patas e 3 segmentos.",
        "Confundir anfíbios com répteis: anfíbios têm pele úmida e ovos sem casca; répteis têm pele seca e ovos amnióticos.",
        "Esquecer que aves e mamíferos são endotérmicos (sangue quente); répteis são ectotérmicos (sangue frio).",
        "Achar que ornitorrinco e equidna são mamíferos: são sim, mas ovíparos (Prototheria).",
    ],
    "referencias": [
        "RICKLEFS, R. E. A Economia da Natureza. 6. ed. Rio de Janeiro: Guanabara Koogan, 2010.",
        "HICKMAN, C. P. et al. Princípios Integrados de Zoologia. 15. ed. Rio de Janeiro: Guanabara Koogan, 2016.",
        "STRIER, K. B. et al. Introdução à Zoologia. São Paulo: Artmed, 2006.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "KIM, K. C. Parasitologia: Doenças de Animais Invertebrados ao Homem. São Paulo: Roca, 2011.",
        "PARKER, S. P. (Ed.). Synopsis and Classification of Living Organisms. New York: McGraw-Hill, 1982.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Zoologia")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_ZOOLOGIA.pdf"

    images_data = [
        {"file": "br_zoo_hidra.jpg",
         "caption": "Hidra (Cnidário): simetria radial e cnidócitos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/reino-animalia.htm"},
        {"file": "br_zoo_libelula.jpg",
         "caption": "Libélula (Artrópode): exoesqueleto e apêndices articulados",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/reino-animalia.htm"},
        {"file": "br_zoo_jiboia.jpg",
         "caption": "Jibóia (Réptil): escamas, respiração pulmonar e ovos amnióticos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/reino-animalia.htm"},
        {"file": "br_zoo_aves.jpg",
         "caption": "Aves: penas, bico e adaptações ao voo",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/cordados/"},
        {"file": "br_zoo_tenia.jpg",
         "caption": "Tenia (Platelminto): verme achatado parasita intestinal",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/reino-animalia.htm"},
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
