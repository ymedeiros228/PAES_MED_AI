"""Gera PDF profissional ABNT do material de Biologia - Microbiologia.

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
    "titulo": "Microbiologia",
    "disciplina": "Biologia",
    "topico": "Microbiologia",
    "subtopico": "Vírus, Bactérias, Protozoários, Algas e Fungos",
    "introducao": (
        "A microbiologia estuda os seres vivos microscópicos e os vírus. "
        "Esses organismos são invisíveis a olho nu e incluem vírus, "
        "bactérias, protozoários, algas e fungos. Embora sejam pequenos, "
        "têm enorme importância ecológica, econômica e para a saúde "
        "humana.\n\n"
        "Para a Medicina, a microbiologia é fundamental: muitas doenças "
        "são causadas por microorganismos. Compreender sua estrutura, "
        "reprodução e metabolismo é essencial para o diagnóstico, "
        "tratamento e prevenção de infecções. Além disso, os "
        "microorganismos são usados na produção de antibióticos, "
        "vacinas, insulina recombinante e alimentos."
    ),
    "secoes": [
        {
            "titulo": "1. Vírus",
            "conteudo": (
                "Os vírus NÃO são seres vivos. Não têm metabolismo próprio, "
                "não se reproduzem sozinhos e dependem de células hospedeiras "
                "para se multiplicar. São parasitas intracelulares obrigatórios.\n\n"
                "ESTRUTURA: formados por material genético (DNA ou RNA, nunca "
                "os dois juntos) envolvido por uma capsídeo (cápside) de "
                "proteínas. Alguns têm envelope lipídico derivado da membrana "
                "do hospedeiro. Fora da célula, são chamados virions e são "
                "inertes — basicamente cristais que carregam informação "
                "genética.\n\n"
                "CICLO DE VIDA:\n"
                "- Adsorção: o vírus se liga à célula hospedeira por "
                "receptores específicos;\n"
                "- Penetração: o material genético entra na célula;\n"
                "- Replicação: o genoma viral é copiado e as proteínas do "
                "capsídeo são sintetizadas usando a maquinaria celular;\n"
                "- Montagem: novos vírus são montados;\n"
                "- Lise: a célula é destruída e os vírus liberados.\n\n"
                "Os retrovírus (como HIV) têm RNA e usam a transcriptase "
                "reversa para transformar RNA em DNA, que é incorporado ao "
                "genoma do hospedeiro. Os bacteriófagos infectam bactérias.\n\n"
                "DOENÇAS VIRAIS: gripe, COVID-19, AIDS, hepatite, herpes, "
                "caxumba, sarampo, rubéola, poliomielite, raiva, dengue, "
                "zika, chikungunya, febre amarela. Vírus também podem causar "
                "câncer (papilomavírus — câncer de colo de útero; vírus da "
                "hepatite B — câncer de fígado).\n\n"
                "TRATAMENTO: os vírus usam a maquinaria celular, então é "
                "difícil combatê-los sem prejudicar a célula. Antivirais "
                "como o oseltamivir (gripe) e os antirretrovirais (HIV) "
                "inibem enzimas virais específicas. Vacinas estimulam a "
                "imunidade."
            ),
            "exemplo": (
                "A pandemia de COVID-19 mostrou a importância da virologia. "
                "O SARS-CoV-2 é um vírus de RNA envelopado que se liga ao "
                "receptor ACE2 nas células humanas (pulmão, coração, "
                "intestino). Suas mutações geraram variantes (Alfa, Delta, "
                "Ômicron) com diferentes capacidades de transmissão. As "
                "vacinas de mRNA (Pfizer, Moderna) revolucionaram a "
                "imunologia: ensinam as células a produzir a proteína do "
                "vírus, sem o vírus, estimulando a resposta imune."
            ),
        },
        {
            "titulo": "2. Bactérias",
            "conteudo": (
                "As bactérias são procariontes unicelulares. Têm DNA "
                "desnudo (nucleoide), ribossomos 70S, parede celular de "
                "peptidoglicano e frequentemente flagelos. Não têm "
                "organelas membranosas. Reproduzem-se rapidamente por "
                "divisão binária (cissiparidade).\n\n"
                "FORMAS BACTERIANAS (classificação morfológica):\n"
                "- Bacilos: em forma de bastonete. Exemplos: Escherichia "
                "coli, Bacillus anthracis, Mycobacterium tuberculosis.\n"
                "- Cocos: esféricos. Exemplos: Streptococcus (cadeias), "
                "Staphylococcus (cachos), Neisseria gonorrhoeae (diplococos).\n"
                "- Vibriões: em vírgula. Exemplo: Vibrio cholerae.\n"
                "- Espirilos: espiralados. Exemplo: Treponema pallidum "
                "(sífilis).\n"
                "- Espiroquetas: espiralados alongados. Exemplo: Borrelia.\n\n"
                "PAREDE CELULAR BACTERIANA (classificação de Gram):\n"
                "- Gram-positivas: parede grossa de peptidoglicano. "
                "Retêm o corante violeta e ficam roxas.\n"
                "- Gram-negativas: parede fina de peptidoglicano, com "
                "membrana externa de lipopolissacarídeo (LPS) e "
                "lipoproteínas. Não retêm o violeta e ficam cor-de-rosa. "
                "O LPS é endotoxina e causa choque séptico.\n\n"
                "METABOLISMO:\n"
                "- Autotróficas: fotossintetizantes (cianobactérias) ou "
                "quimiossintetizantes.\n"
                "- Heterotróficas: saprofíticas (decompositoras) ou "
                "parasitas.\n"
                "- Aeróbias: precisam de O2.\n"
                "- Anaeróbias: vivem sem O2.\n"
                "- Facultativas: podem viver com ou sem O2.\n\n"
                "DOENÇAS BACTERIANAS: tuberculose, leptospirose, cólera, "
                "tetano, difteria, gonorreia, sífilis, salmonelose, "
                "shigelose, pneumonia, meningite, peste, hanseníase, "
                "infecção por Helicobacter pylori (úlcera e câncer "
                "gástrico).\n\n"
                "ANTIBIÓTICOS: substâncias que inibem o crescimento de "
                "bactérias. Atuam em alvos específicos (síntese de parede, "
                "síntese de proteínas, replicação do DNA). Não funcionam "
                "contra vírus. O uso indevido causa resistência bacteriana."
            ),
            "exemplo": (
                "A resistência bacteriana é uma das maiores ameaças à saúde "
                "global. A tuberculose multirresistente (TB-MDR) exige "
                "tratamento por até 2 anos com antibióticos tóxicos. A "
                "Staphylococcus aureus resistente à meticilina (MRSA) "
                "causa infecções hospitalares graves. A disseminação de "
                "genes de resistência ocorre por transferência horizontal "
                "(conjugação, transformação, transdução). Por isso, o "
                "uso racional de antibióticos é crucial — o médico deve "
                "prescrever o antibiótico correto, na dose certa e pelo "
                "tempo adequado."
            ),
        },
        {
            "titulo": "3. Protozoários",
            "conteudo": (
                "Os protozoários são eucariontes unicelulares (reino "
                "Protista). São heterotróficos e vivem em ambientes úmidos "
                "— muitos são parasitas de humanos e animais. Têm mecanismos "
                "de locomoção: pseudópodes, cílios, flagelos ou são "
                "imóveis.\n\n"
                "PRINCIPAIS GRUPOS E DOENÇAS:\n"
                "- Sarcodíneos (rizópodes): amebas, com pseudópodes. "
                "Entamoeba histolytica causa amebíase (disenteria). "
                "Acanthamoeba pode causar queratite (inflamação da córnea).\n"
                "- Mastigóforos (flagelados): com flagelos. Giardia lamblia "
                "(giardíase — diarreia); Trypanosoma cruzi (doença de "
                "Chagas); Trypanosoma brucei (doença do sono na África); "
                "Leishmania (leishmaniose); Trichomonas vaginalis "
                "(tricomoníase, DST).\n"
                "- Cilióforos (ciliados): com cílios. Balantidium coli "
                "(balantidíase). Paramecium ciliatum é de água doce e "
                "não patogênico.\n"
                "- Esporozoários: sem locomoção, parasitos intracelulares. "
                "Plasmodium (malária); Toxoplasma gondii (toxoplasmose); "
                "Cryptosporidium (criptosporidiose); Eimeria.\n\n"
                "CICLO DE VIDA: muitos protozoários têm ciclos complexos, "
                "com hospedeiros alternativos e formas (tropozoíto, "
                "cisto, esporozoíto, merozoíto). A forma cística é "
                "resistente e transmissível pelo ambiente.\n\n"
                "TRANSMISSÃO: via fezes (amebíase, giardíase), vetores "
                "(malária por Anopheles; Chagas por barbeiro; "
                "leishmaniose por flebótomo), água contaminada, "
                "contato sexual, transplacental (toxoplasmose)."
            ),
            "exemplo": (
                "A malária é a doença parasitária mais letal da humanidade. "
                "É causada por protozoários do gênero Plasmodium (P. "
                "falciparum é o mais grave). O ciclo envolve o mosquito "
                "Anopheles (hospedeiro intermediário) e o humano (hospedeiro "
                "definitivo). O esporozoíto é inoculado pela picada, "
                "desenvolve-se no fígado e depois infecta hemácias, "
                "causando febre, anemia e, no caso de P. falciparum, "
                "complicações cerebrais. O controle depende de mosquiteiros "
                "impregnados, eliminação de criadouros e, em algumas "
                "regiões, vacina (RTS,S)."
            ),
        },
        {
            "titulo": "4. Algas",
            "conteudo": (
                "As algas são eucariontes, na maioria autotróficos "
                "fotossintetizantes (reino Protista, exceto algumas "
                "classificadas em Plantae). Podem ser unicelulares ou "
                "multicelulares, mas não formam tecidos verdadeiros como "
                "as plantas.\n\n"
                "PRINCIPAIS GRUPOS (por pigmentos):\n"
                "- Clorofíceas (algas verdes): clorofila a e b. "
                "Exemplos: Chlamydomonas, Spirogyra, Ulva. São as "
                "prováveis ancestrais das plantas terrestres.\n"
                "- Feófitas (algas pardas): fucoxantina. Exemplos: "
                "laminárias, sargaços. São as maiores algas (kelp).\n"
                "- Rodofíceas (algas vermelhas): ficobilinas. Exemplos: "
                "Porphyra (usada no sushi nori).\n"
                "- Chrysophyta (diatomáceas): parede de sílica, formam "
                "agrogeleiras. São indicadores de qualidade da água.\n"
                "- Dinoflagelados: causam marés vermelhas (toxinas). "
                "Exemplos: Gymnodinium, Gonyaulax. Têm dois flagelos.\n"
                "- Euglenófitos: como Euglena, têm cloroplastos e se "
                "comportam como heterotróficos na ausência de luz.\n\n"
                "IMPORTÂNCIA: produzem ~70% do oxigênio do planeta, "
                "base das cadeias alimentares aquáticas, fonte de "
                "biocombustíveis (biodiesel de microalgas), espessantes "
                "alimentares (agar-agar, carragenina, alginato) e "
                "remediação de ambientes poluídos (fitoremediação).\n\n"
                "ALGAS TÓXICAS: as florções de cianobactérias (azuis) em "
                "lagos e represas liberam toxinas (microcistina) que "
                "causam hepatotoxicidade e neurotoxicidade em humanos e "
                "animais."
            ),
            "exemplo": (
                "As cianobactérias têm enorme importância: são "
                "responsáveis pelo 'Grande Oxidação' há 2,5 bilhões de "
                "anos, quando transformaram a atmosfera da Terra em "
                "aeróbia. Elas também fixam nitrogênio atmosférico, "
                "enriquecendo solos e águas. Hoje, cianobactérias são "
                "estudadas como fonte de biofertilizantes, biocombustíveis "
                "e proteínas. Por outro lado, florções de algas em "
                "represas de abastecimento de água exigem tratamento "
                "especial, pois as toxinas são termoestáveis — não são "
                "destruídas pela ebulição."
            ),
        },
        {
            "titulo": "5. Fungos",
            "conteudo": (
                "Os fungos são eucariontes heterotróficos (reino Fungi). "
                "São saprofíticos, parasitas ou simbiontes (micorrizas, "
                "líquens). Têm parede celular de quitina (como os "
                "artrópodes), não de celulose como as plantas. "
                "Nutrem-se por absorção.\n\n"
                "ESTRUTURA: o corpo do fungo é o micélio — um emaranhado "
                "de filamentos chamados hifas. As hifas podem ser septadas "
                "(com divisões) ou cenocíticas (sem divisões, com muitos "
                "núcleos). A reprodução pode ser assexuada (brotamento, "
                "fragmentação, esporos) ou sexuada.\n\n"
                "REPRODUÇÃO:\n"
                "- Assexuada: por esporos (conídios), fragmentação do "
                "micélio ou brotamento (leveduras).\n"
                "- Sexuada: formação de zigoto, que dá origem a esporos.\n\n"
                "DOENÇAS CAUSADAS POR FUNGOS (micoses):\n"
                "- Micoses superficiais: dermatofitoses (micose de unha, "
                "tinea capitis — sapinho), candidíase (Candida albicans).\n"
                "- Micoses oportunistas: aspergilose (Aspergillus), "
                "criptococose (Cryptococcus neoformans, comum em "
                "pacientes com AIDS), pneumocistose (Pneumocystis "
                "jirovecii, pneumonia em imunodeprimidos).\n"
                "- Micoses sistêmicas (endêmicas): histoplasmose "
                "(Histoplasma capsulatum), coccidioidomicose "
                "(Coccidioides), paracoccidioidomicose (Paracoccidioides "
                "brasiliensis — doença sul-americana).\n\n"
                "IMPORTÂNCIA: produção de antibióticos (penicilina), "
                "enzimas, álcool etílico, pães e cervejas (leveduras), "
                "controle biológico de pragas, decomposição de matéria "
                "orgânica, formação de micorrizas (fungos simbiontes "
                "de raízes vegetais que aumentam a absorção de água e "
                "nutrientes)."
            ),
            "exemplo": (
                "A paracoccidioidomicose é uma micose sistêmica "
                "endêmica na América Latina, causada pelo fungo "
                "Paracoccidioides brasiliensis. A inalação dos conídios "
                "provoca lesões pulmonares que podem disseminar para "
                "pele, mucosas e órgãos. O tratamento é prolongado "
                "(meses a anos) com antifúngicos como itraconazol. "
                "Apenas cerca de 5-10% das pessoas expostas ao fungo "
                "desenvolvem doença — a imunidade do hospedeiro é o "
                "fator determinante. Isso mostra que fungos "
                "potencialmente patogênicos são comuns no ambiente, "
                "mas só causam doença em hospedeiros suscetíveis."
            ),
        },
    ],
    "resumo": (
        "- Vírus: não vivos, parasitas intracelulares, DNA ou RNA + capsídeo, envelope opcional.\n"
        "- Bactérias: procariontes, parede de peptidoglicano, Gram+ (roxo) e Gram- (rosa, endotoxina LPS).\n"
        "- Protozoários: eucariontes unicelulares heterotróficos. Amebíase, giardíase, Chagas, leishmaniose, malária.\n"
        "- Algas: autotróficos fotossintetizantes. Verde, parda, vermelha. Produzem 70% do O2 do planeta.\n"
        "- Fungos: heterotróficos por absorção, parede de quitina, micélio de hifas. Causam micoses.\n"
        "- Antibióticos são para bactérias; antifúngicos para fungos; antivirais para vírus. Não confunda!"
    ),
    "dicas": [
        "Vírus NÃO são vivos. Bactérias são procariontes. Fungos e protozoários são eucariontes.",
        "Parede bacteriana: Gram+ roxo (peptidoglicano grosso); Gram- rosa (membrana externa com LPS endotoxina).",
        "Protozoários por locomoção: amebas (pseudópodes), flagelados (flagelos), ciliados (cílios), esporozoários (imóveis).",
        "Malária = Plasmodium; Chagas = Trypanosoma cruzi; Leishmaniose = Leishmania; Amebíase = Entamoeba histolytica.",
        "Fungos têm parede de QUITINA, não celulose. Isso os diferencia de plantas e algas.",
        "Antibióticos NÃO funcionam contra vírus. Gripes e resfriados comuns são virais — não tome antibiótico sem prescrição.",
    ],
    "pegadinhas": [
        "Achar que vírus são seres vivos: não têm metabolismo nem se reproduzem sozinhos. São parasitas intracelulares obrigatórios.",
        "Confundir Gram+ com Gram-: Gram+ fica roxa (parede grossa); Gram- fica rosa (parede fina + LPS).",
        "Achar que fungos são plantas: fungos são heterotróficos e têm quitina; plantas são autotróficas com celulose.",
        "Confundir algas com plantas: algas não tecidos verdadeiros, não raízes/folhas/ caules como as plantas.",
        "Esquecer que endotoxina LPS está em bactérias Gram-negativas — causa choque séptico.",
        "Achar que protozoários são bactérias: protozoários são eucariontes (maiores, com núcleo definido); bactérias são procariontes.",
    ],
    "referencias": [
        "PELCZAR, M. J.; CHAN, E. C. S.; KRIEG, N. R. Microbiologia: Conceitos e Aplicações. 2. ed. São Paulo: Makron Books, 1996.",
        "TORTORA, G. J.; FUNKE, B. R.; CASE, C. L. Microbiologia. 10. ed. Porto Alegre: Artmed, 2012.",
        "DE ROBERTIS, E. M. F.; DE ROBERTIS JUNIOR, E. M. Bases da Biologia Celular e Molecular. 4. ed. Rio de Janeiro: Guanabara Koogan, 2014.",
        "JUNQUEIRA, L. C.; CARNEIRO, J. Biologia Celular e Molecular. 9. ed. Rio de Janeiro: Guanabara Koogan, 2012.",
        "SADAVA, D. et al. Vida: A Ciência da Biologia. 10. ed. Porto Alegre: Artmed, 2017.",
        "MURRAY, R. K. et al. Harper: Bioquímica Ilustrada. 31. ed. Porto Alegre: Artmed, 2019.",
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
    canvas_obj.drawString(3*cm, height - 1.6*cm, "Biologia — Microbiologia")
    canvas_obj.setStrokeColor(PRIMARY)
    canvas_obj.setLineWidth(0.5)
    canvas_obj.line(1.5*cm, height - 2*cm, width - 1.5*cm, height - 2*cm)
    canvas_obj.setFont(_FN, 7)
    canvas_obj.setFillColor(TEXT_LIGHT)
    canvas_obj.drawCentredString(width/2, 1*cm, f"PAES MED AI — Material de Estudo  |  Página {doc.page}")
    canvas_obj.restoreState()


def generate_pdf():
    pdf_path = PDF_DIR / "BI_MICROBIOLOGIA.pdf"

    images_data = [
        {"file": "br_mic_virus_estrutura.jpg",
         "caption": "Estrutura do vírus: material genético, capsídeo e envelope",
         "source": "Toda Matéria",
         "source_url": "https://www.todamateria.com.br/virus/"},
        {"file": "br_mic_bacterias_classif.jpg",
         "caption": "Classificação morfológica das bactérias: cocos, bacilos, vibriões e espirilos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/bacterias.htm"},
        {"file": "br_mic_tipos_bacterias.jpg",
         "caption": "Tipos de bactérias: classificação por forma e arranjo",
         "source": "Mundo Educação",
         "source_url": "https://mundoeducacao.uol.com.br/biologia/bacterias.htm"},
        {"file": "br_mic_protozoarios.jpg",
         "caption": "Representação de protozoários: ameba, paramecio, trypanosoma e plasmodium",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/protozoarios.htm"},
        {"file": "br_mic_algas2.jpg",
         "caption": "Algas: organismos fotossintetizantes de diferentes grupos",
         "source": "Brasil Escola",
         "source_url": "https://brasilescola.uol.com.br/biologia/algas.htm"},
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
