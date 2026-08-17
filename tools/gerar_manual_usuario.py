"""
Gera o Manual do Usuario do PAES MED AI em PDF.
PDF em portrait (A4), com capturas de tela e instrucoes passo-a-passo.
Destinado ao cliente (Jonas Almeida Medeiros).
"""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage,
    Frame, PageTemplate, PageBreak, Table, TableStyle, KeepTogether
)
from reportlab.pdfgen import canvas
from PIL import Image as PILImage

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "docs" / "screenshots" / "manual"
OUT = ROOT / "docs" / "PAES_MED_AI_Manual_Usuario.pdf"

# Paleta do app
C_NAVY = colors.HexColor("#0A1628")
C_NAVY_SOFT = colors.HexColor("#132337")
C_TEAL = colors.HexColor("#1FA887")
C_TEAL_DEEP = colors.HexColor("#0C7A63")
C_MINT = colors.HexColor("#E6F6F1")
C_SAND = colors.HexColor("#F6F4F1")
C_WHITE = colors.white
C_MUTED = colors.HexColor("#5A6B6E")
C_INK = colors.HexColor("#0E1726")
C_ALERT = colors.HexColor("#E8A04B")
C_DANGER = colors.HexColor("#D3544A")
C_SUCCESS = colors.HexColor("#2E9B6B")

PAGE_W, PAGE_H = A4  # 595 x 842 pt (portrait)
MARGIN = 20 * mm
CONTENT_W = PAGE_W - 2 * MARGIN
CONTENT_H = PAGE_H - 2 * MARGIN

# Estilos
styles = {
    "title": ParagraphStyle("title", fontName="Helvetica-Bold", fontSize=28, textColor=C_WHITE, alignment=TA_CENTER, spaceAfter=6, leading=32),
    "subtitle": ParagraphStyle("subtitle", fontName="Helvetica-Bold", fontSize=14, textColor=C_TEAL, alignment=TA_CENTER, spaceAfter=4, leading=18),
    "meta": ParagraphStyle("meta", fontName="Helvetica", fontSize=10, textColor=C_MINT, alignment=TA_CENTER, leading=14),
    "h1": ParagraphStyle("h1", fontName="Helvetica-Bold", fontSize=18, textColor=C_NAVY, spaceBefore=16, spaceAfter=8, leading=22),
    "h2": ParagraphStyle("h2", fontName="Helvetica-Bold", fontSize=14, textColor=C_TEAL_DEEP, spaceBefore=12, spaceAfter=6, leading=18),
    "body": ParagraphStyle("body", fontName="Helvetica", fontSize=11, textColor=C_INK, alignment=TA_JUSTIFY, spaceAfter=6, leading=16),
    "bullet": ParagraphStyle("bullet", fontName="Helvetica", fontSize=11, textColor=C_INK, leftIndent=18, bulletIndent=6, spaceAfter=4, leading=15),
    "caption": ParagraphStyle("caption", fontName="Helvetica-Oblique", fontSize=9, textColor=C_MUTED, alignment=TA_CENTER, spaceBefore=4, spaceAfter=12, leading=12),
    "tip": ParagraphStyle("tip", fontName="Helvetica", fontSize=10, textColor=C_NAVY_SOFT, leftIndent=10, rightIndent=10, spaceAfter=8, leading=14),
    "step": ParagraphStyle("step", fontName="Helvetica-Bold", fontSize=12, textColor=C_TEAL_DEEP, spaceBefore=10, spaceAfter=4, leading=16),
    "footer": ParagraphStyle("footer", fontName="Helvetica", fontSize=8, textColor=C_MUTED, alignment=TA_CENTER, leading=10),
}


def draw_cover(c, doc):
    """Capa do manual."""
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)

    # Faixas superior e inferior
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 8 * mm, PAGE_W, 8 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 8 * mm, fill=1, stroke=0)

    # Logo / titulo
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 32)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 80 * mm, "PAES MED AI")
    c.setFillColor(C_TEAL)
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 95 * mm, "MANUAL DO USUARIO")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 11)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 110 * mm, "Guia pratico para usar a plataforma de estudos")

    # Caixa de informacoes
    c.setFillColor(C_NAVY_SOFT)
    c.roundRect(40 * mm, PAGE_H - 175 * mm, PAGE_W - 80 * mm, 50 * mm, 4 * mm, fill=1, stroke=0)
    c.setFillColor(C_MINT)
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 140 * mm, "INFORMACOES")
    c.setFont("Helvetica", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 150 * mm, "Cliente: Jonas Almeida Medeiros")
    c.drawCentredString(PAGE_W / 2, PAGE_H - 160 * mm, "Versao: 1.0.0.26")
    c.drawCentredString(PAGE_W / 2, PAGE_H - 170 * mm, "Data: 17 de agosto de 2026")

    # Rodape
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 9)
    c.drawCentredString(PAGE_W / 2, 20 * mm, "Desenvolvido por Yuri Medeiros Bandeira")
    c.restoreState()


def draw_page(c, doc):
    """Paginas internas com cabecalho e rodape."""
    c.saveState()
    # Cabecalho
    c.setFillColor(C_NAVY)
    c.rect(0, PAGE_H - 15 * mm, PAGE_W, 15 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 16 * mm, PAGE_W, 1 * mm, fill=1, stroke=0)
    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(MARGIN, PAGE_H - 10 * mm, "PAES MED AI")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 8)
    c.drawRightString(PAGE_W - MARGIN, PAGE_H - 10 * mm, "Manual do Usuario")

    # Rodape
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 1 * mm, fill=1, stroke=0)
    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawCentredString(PAGE_W / 2, 6 * mm, f"Pagina {doc.page}  |  PAES MED AI v1.0.0.26")
    c.restoreState()


def draw_backcover(c, doc):
    """Contra-capa."""
    c.saveState()
    c.setFillColor(C_NAVY)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(C_TEAL)
    c.rect(0, PAGE_H - 8 * mm, PAGE_W, 8 * mm, fill=1, stroke=0)
    c.setFillColor(C_TEAL_DEEP)
    c.rect(0, 0, PAGE_W, 8 * mm, fill=1, stroke=0)

    c.setFillColor(C_WHITE)
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 60 * mm, "Obrigado!")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 12)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 80 * mm, "PAES MED AI - Estudos para Medicina")
    c.setFillColor(C_TEAL)
    c.setFont("Helvetica-Bold", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 100 * mm, "Suporte e contato:")
    c.setFillColor(C_MINT)
    c.setFont("Helvetica", 10)
    c.drawCentredString(PAGE_W / 2, PAGE_H - 112 * mm, "Yuri Medeiros Bandeira")
    c.drawCentredString(PAGE_W / 2, PAGE_H - 124 * mm, "github.com/ymedeiros228/PAES_MED_AI")

    c.setFillColor(C_MUTED)
    c.setFont("Helvetica", 8)
    c.drawCentredString(PAGE_W / 2, 20 * mm, "Versao 1.0.0.26  |  17 de agosto de 2026")
    c.restoreState()


def img_flowable(path, max_w=None, max_h=None):
    """Cria uma Image preservando aspect ratio."""
    if max_w is None:
        max_w = CONTENT_W
    if max_h is None:
        max_h = 110 * mm
    with PILImage.open(path) as im:
        iw, ih = im.size
    ratio = min(max_w / iw, max_h / ih)
    w = iw * ratio
    h = ih * ratio
    return RLImage(str(path), width=w, height=h)


def tip_box(text):
    """Caixa de dica com fundo mint."""
    p = Paragraph(f"<b>Dica:</b> {text}", styles["tip"])
    t = Table([[p]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), C_MINT),
        ("BOX", (0, 0), (-1, -1), 0.5, C_TEAL),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    return t


def warning_box(text):
    """Caixa de aviso."""
    p = Paragraph(f"<b>Atencao:</b> {text}", styles["tip"])
    t = Table([[p]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#FFF3E0")),
        ("BOX", (0, 0), (-1, -1), 0.5, C_ALERT),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    return t


def section(num, title):
    """Titulo de secao numerada."""
    return Paragraph(f"{num}. {title}", styles["h1"])


def subsection(title):
    return Paragraph(title, styles["h2"])


def step(num, text):
    return Paragraph(f"Passo {num}: {text}", styles["step"])


def body(text):
    return Paragraph(text, styles["body"])


def bullet(text):
    return Paragraph(f"• {text}", styles["bullet"])


def caption(text):
    return Paragraph(text, styles["caption"])


def build_manual():
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=22 * mm,
        bottomMargin=15 * mm,
    )

    # Templates
    frame_cover = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="cover")
    frame_content = Frame(MARGIN, 12 * mm, CONTENT_W, PAGE_H - 35 * mm, id="content")
    frame_back = Frame(0, 0, PAGE_W, PAGE_H, leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="back")

    doc.addPageTemplates([
        PageTemplate(id="cover", frames=[frame_cover], onPage=draw_cover),
        PageTemplate(id="content", frames=[frame_content], onPage=draw_page),
        PageTemplate(id="backcover", frames=[frame_back], onPage=draw_backcover),
    ])

    story = []

    # === CAPA ===
    story.append(PageBreak())

    # === CONTEUDO ===
    story.append(NextPageTemplate("content"))
    story.append(PageBreak())

    # Indice / Boas-vindas
    story.append(section("1", "Bem-vindo ao PAES MED AI"))
    story.append(body(
        "O PAES MED AI e uma plataforma de estudos completa para o exame "
        "vestibular de Medicina da UEMA. Ele reune questoes historicas, "
        "flashcards, aulas, materiais em PDF, simulados e um tutor com "
        "inteligencia artificial — tudo em um so aplicativo."
    ))
    story.append(body(
        "Este manual vai te ensinar, passo a passo, como usar cada parte "
        "da plataforma. Nao precisa de experiencia anterior — basta seguir "
        "as instrucoes e as capturas de tela."
    ))
    story.append(Spacer(1, 6 * mm))

    story.append(subsection("O que voce encontra no app"))
    story.append(bullet("720 questoes de 2014 a 2026"))
    story.append(bullet("738 flashcards para revisao rapida"))
    story.append(bullet("218 aulas resumidas por materia"))
    story.append(bullet("92 materiais em PDF para estudo profundo"))
    story.append(bullet("Tutor IA para tirar duvidas a qualquer momento"))
    story.append(bullet("Acompanhamento de progresso e estatisticas"))
    story.append(bullet("Funciona offline (sem internet)"))
    story.append(Spacer(1, 4 * mm))

    story.append(subsection("Menu de navegacao"))
    story.append(body(
        "Na lateral esquerda do aplicativo voce encontra o menu principal "
        "com as seguintes opcoes:"
    ))
    story.append(bullet("<b>Inicio</b> — Dashboard com resumo do seu progresso"))
    story.append(bullet("<b>Estudar</b> — Sessoes de questoes e flashcards"))
    story.append(bullet("<b>Progresso</b> — Graficos e estatisticas"))
    story.append(bullet("<b>Biblioteca</b> — Aulas e materiais em PDF"))
    story.append(bullet("<b>Materiais</b> — Lista de PDFs para download/leitura"))
    story.append(bullet("<b>Ajustes</b> — Configuracoes e preferencias"))

    # === SECAO 2: Primeiros passos ===
    story.append(PageBreak())
    story.append(section("2", "Primeiros Passos"))

    story.append(subsection("Abrindo o aplicativo"))
    story.append(body(
        "Para abrir o PAES MED AI, de um duplo clique no atalho "
        "<b>PAES MED AI Desktop</b> na sua Area de Trabalho."
    ))
    story.append(step(1, "Duplo clique no icone da Area de Trabalho"))
    story.append(body(
        "O aplicativo abre em poucos segundos. Na primeira vez, "
        "aguarde cerca de 5 a 10 segundos para o sistema carregar "
        "completamente."
    ))
    if (SHOTS / "01-dashboard.png").exists():
        story.append(img_flowable(SHOTS / "01-dashboard.png", max_h=90 * mm))
        story.append(caption("Tela inicial do PAES MED AI — Dashboard"))
    story.append(Spacer(1, 4 * mm))

    story.append(tip_box(
        "Se o aplicativo nao abrir, verifique se o icone existe na Area "
        "de Trabalho. Se nao existir, procure no Menu Iniciar por "
        "\"PAES MED AI\"."
    ))

    # === SECAO 3: Dashboard ===
    story.append(PageBreak())
    story.append(section("3", "Tela Inicial (Dashboard)"))
    story.append(body(
        "O Dashboard e a primeira tela que voce ve ao abrir o app. "
        "Ele mostra um resumo do seu progresso e atalhos rapidos."
    ))

    story.append(subsection("O que voce ve no Dashboard"))
    story.append(bullet("<b>Questoes respondidas</b> — total e porcentagem de acerto"))
    story.append(bullet("<b>Flashcards revisados</b> — quantidade de cards estudados"))
    story.append(bullet("<b>Dias para a prova</b> — contagem regressiva"))
    story.append(bullet("<b>Sequencia de estudos (streak)</b> — dias consecutivos"))
    story.append(bullet("<b>Materia do dia</b> — sugestao do que estudar hoje"))

    if (SHOTS / "02-dashboard-2.png").exists():
        story.append(img_flowable(SHOTS / "02-dashboard-2.png", max_h=90 * mm))
        story.append(caption("Dashboard com estatisticas e materia do dia"))

    story.append(tip_box(
        "Clique em \"Continuar estudo\" para retomar de onde parou, "
        "ou em \"Nova sessao\" para comecar um estudo novo."
    ))

    # === SECAO 4: Estudar ===
    story.append(PageBreak())
    story.append(section("4", "Estudando (Sessoes)"))
    story.append(body(
        "A aba <b>Estudar</b> e onde voce passa a maior parte do tempo. "
        "Aqui voce responde questoes e revisa flashcards."
    ))

    story.append(subsection("Iniciando uma sessao"))
    story.append(step(1, "Clique em \"Estudar\" no menu lateral"))
    story.append(step(2, "Escolha a materia ou deixe o sistema sugerir"))
    story.append(step(3, "Clique em \"Iniciar sessao\""))
    story.append(body(
        "O sistema vai montar uma sessao com questoes do nivel e materia "
        "escolhidos. Cada sessao tem cerca de 10 a 20 questoes."
    ))

    if (SHOTS / "03-sessao.png").exists():
        story.append(img_flowable(SHOTS / "03-sessao.png", max_h=90 * mm))
        story.append(caption("Tela de sessao de estudo — escolha de materia"))

    # === SECAO 5: Questoes ===
    story.append(PageBreak())
    story.append(section("5", "Respondendo Questoes"))
    story.append(body(
        "Cada questao aparece com o enunciado e 5 alternativas (A, B, C, D, E). "
        "Leia com atencao e clique na alternativa que acha correta."
    ))

    story.append(subsection("Como responder"))
    story.append(step(1, "Leia o enunciado com atencao"))
    story.append(step(2, "Clique na alternativa desejada"))
    story.append(step(3, "Clique em \"Confirmar\" para registrar sua resposta"))
    story.append(step(4, "Veja se acertou ou errou, com a explicacao"))

    if (SHOTS / "04-questao.png").exists():
        story.append(img_flowable(SHOTS / "04-questao.png", max_h=85 * mm))
        story.append(caption("Tela de questao — enunciado e alternativas"))

    story.append(subsection("Apos responder"))
    story.append(body(
        "Depois de confirmar sua resposta, o sistema mostra:"
    ))
    story.append(bullet("Se voce <b>acertou</b> ou <b>errou</b>"))
    story.append(bullet("A <b>resolucao completa</b> da questao"))
    story.append(bullet("O <b>macete</b> (dica rapida para lembrar)"))
    story.append(bullet("Possiveis <b>pegadinhas</b> da questao"))
    story.append(bullet("Botao para pedir explicacao ao <b>Tutor IA</b>"))

    if (SHOTS / "05-questao-resolvida.png").exists():
        story.append(img_flowable(SHOTS / "05-questao-resolvida.png", max_h=85 * mm))
        story.append(caption("Questao respondida com resolucao e explicacao"))

    story.append(tip_box(
        "Use o botao \"Tutor IA\" sempre que nao entender a explicacao. "
        "A inteligencia artificial vai te dar uma explicacao detalhada "
        "e personalizada."
    ))

    # === SECAO 6: Progresso ===
    story.append(PageBreak())
    story.append(section("6", "Acompanhando seu Progresso"))
    story.append(body(
        "A aba <b>Progresso</b> mostra graficos e estatisticas do seu "
        "desempenho. E fundamental para saber onde voce esta indo bem "
        "e onde precisa melhorar."
    ))

    story.append(subsection("Grafico de Evolucao"))
    story.append(body(
        "Mostra seu desempenho ao longo do tempo. Cada ponto no grafico "
        "representa uma sessao de estudo. A linha verde mostra a sua "
        "taxa de acerto."
    ))
    if (SHOTS / "06-progresso-evolucao.png").exists():
        story.append(img_flowable(SHOTS / "06-progresso-evolucao.png", max_h=85 * mm))
        story.append(caption("Grafico de evolucao do desempenho"))

    story.append(subsection("Radar por Materia"))
    story.append(body(
        "O grafico de radar (teia) mostra seu desempenho em cada materia. "
        "Quanto mais cheia a teia, melhor seu desempenho naquela area."
    ))
    if (SHOTS / "07-progresso-radar.png").exists():
        story.append(img_flowable(SHOTS / "07-progresso-radar.png", max_h=85 * mm))
        story.append(caption("Radar de desempenho por materia"))

    story.append(subsection("Analise Detalhada"))
    story.append(body(
        "A analise detalhada mostra estatisticas por materia, topico e "
        "dificuldade. Use para identificar onde focar seus estudos."
    ))
    if (SHOTS / "08-progresso-analise.png").exists():
        story.append(img_flowable(SHOTS / "08-progresso-analise.png", max_h=85 * mm))
        story.append(caption("Analise detalhada por materia e topico"))

    story.append(tip_box(
        "Estude mais as materias onde sua taxa de acerto esta abaixo de 60%. "
        "O proprio app sugere revisao desses topicos."
    ))

    # === SECAO 7: Biblioteca ===
    story.append(PageBreak())
    story.append(section("7", "Biblioteca de Aulas"))
    story.append(body(
        "A aba <b>Biblioteca</b> contem aulas resumidas organizadas por "
        "materia. Cada aula cobre um topico especifico do edital."
    ))

    story.append(subsection("Como acessar as aulas"))
    story.append(step(1, "Clique em \"Biblioteca\" no menu lateral"))
    story.append(step(2, "Escolha a materia (Biologia, Quimica, Fisica, etc.)"))
    story.append(step(3, "Clique na aula que deseja ler"))
    story.append(step(4, "A aula abre dentro do aplicativo"))

    if (SHOTS / "09-biblioteca-aulas.png").exists():
        story.append(img_flowable(SHOTS / "09-biblioteca-aulas.png", max_h=85 * mm))
        story.append(caption("Biblioteca — lista de aulas por materia"))

    # === SECAO 8: Materiais ===
    story.append(PageBreak())
    story.append(section("8", "Materiais de Estudo (PDF)"))
    story.append(body(
        "A aba <b>Materiais</b> tem 92 PDFs completos para estudo profundo. "
        "Cada PDF cobre um topico com detalhes, diagramas e exercicios."
    ))

    story.append(subsection("Como abrir um material"))
    story.append(step(1, "Clique em \"Materiais\" no menu lateral"))
    story.append(step(2, "Navegue pela lista ou use a busca"))
    story.append(step(3, "Clique no material desejado"))
    story.append(step(4, "O PDF abre dentro do aplicativo"))

    if (SHOTS / "10-biblioteca-materiais.png").exists():
        story.append(img_flowable(SHOTS / "10-biblioteca-materiais.png", max_h=85 * mm))
        story.append(caption("Lista de materiais em PDF"))

    if (SHOTS / "11-material-aberto.png").exists():
        story.append(img_flowable(SHOTS / "11-material-aberto.png", max_h=90 * mm))
        story.append(caption("Material de estudo aberto — Botanica"))

    story.append(tip_box(
        "Voce pode ler os materiais sem internet. Todos os 92 PDFs ja "
        "vem instalados no aplicativo."
    ))

    # === SECAO 9: Ajustes ===
    story.append(PageBreak())
    story.append(section("9", "Configuracoes (Ajustes)"))
    story.append(body(
        "A aba <b>Ajustes</b> permite personalizar o aplicativo conforme "
        "sua preferencia."
    ))

    story.append(subsection("Tema Claro e Escuro"))
    story.append(body(
        "Voce pode alternar entre tema claro e escuro. O tema escuro "
        "e melhor para estudar a noite e cansa menos os olhos."
    ))
    if (SHOTS / "12-ajustes-escuro.png").exists():
        story.append(img_flowable(SHOTS / "12-ajustes-escuro.png", max_h=85 * mm))
        story.append(caption("Ajustes — Tema escuro"))

    if (SHOTS / "13-ajustes-claro.png").exists():
        story.append(img_flowable(SHOTS / "13-ajustes-claro.png", max_h=85 * mm))
        story.append(caption("Ajustes — Tema claro"))

    story.append(subsection("Data da prova"))
    story.append(body(
        "Configure a data da sua prova para o app calcular a contagem "
        "regressiva e sugerir um plano de estudo adequado."
    ))

    story.append(subsection("Inteligencia Artificial"))
    story.append(body(
        "O app ja vem com 4 provedores de IA configurados:"
    ))
    story.append(bullet("OpenAI (GPT-4.1 Mini)"))
    story.append(bullet("Gemini (Google)"))
    story.append(bullet("Groq (Llama 3.1)"))
    story.append(bullet("OpenRouter (Nemotron)"))
    story.append(body(
        "Voce pode escolher qual usar em Ajustes. Todos ja estao "
        "prontos para uso — nao precisa configurar nada."
    ))

    # === SECAO 10: Tutor IA ===
    story.append(PageBreak())
    story.append(section("10", "Tutor IA — Sua Duvida Explicada"))
    story.append(body(
        "O Tutor IA e uma das funcionalidades mais poderosas do PAES MED AI. "
        "Ele usa inteligencia artificial para explicar questoes, tirar duvidas "
        "e dar exemplos extras."
    ))

    story.append(subsection("Como usar o Tutor IA"))
    story.append(step(1, "Responda uma questao (certa ou errada)"))
    story.append(step(2, "Clique no botao \"Tutor IA\" ou \"Explicar\""))
    story.append(step(3, "A IA vai gerar uma explicacao detalhada"))
    story.append(step(4, "Voce pode fazer perguntas adicionais"))

    if (SHOTS / "14-tutor-ia.png").exists():
        story.append(img_flowable(SHOTS / "14-tutor-ia.png", max_h=90 * mm))
        story.append(caption("Tutor IA explicando uma questao"))

    story.append(tip_box(
        "O Tutor IA funciona melhor quando voce faz perguntas especificas. "
        "Em vez de \"nao entendi\", tente \"por que a alternativa C esta errada?\""
    ))

    # === SECAO 11: Flashcards ===
    story.append(PageBreak())
    story.append(section("11", "Flashcards — Revisao Rapida"))
    story.append(body(
        "Flashcards sao cartoes de revisao rapida. Cada cartao tem uma "
        "pergunta na frente e a resposta no verso. Sao excelentes para "
        "memorizar conteudos."
    ))

    story.append(subsection("Como usar flashcards"))
    story.append(step(1, "Va em \"Estudar\" no menu lateral"))
    story.append(step(2, "Escolha \"Flashcards\" em vez de \"Questoes\""))
    story.append(step(3, "Leia a pergunta na tela"))
    story.append(step(4, "Pense na resposta e clique em \"Mostrar resposta\""))
    story.append(step(5, "Marque se voce \"Acertou\" ou \"Errou\""))
    story.append(body(
        "O sistema usa repeticao espacada: cartoes que voce erra aparecem "
        "com mais frequancia, e os que voce acerta aparecem menos."
    ))

    story.append(tip_box(
        "Estude flashcards 10-15 minutos por dia. E mais eficiente "
        "do que estudar 1 hora uma vez por semana."
    ))

    # === SECAO 12: Dicas de estudo ===
    story.append(PageBreak())
    story.append(section("12", "Dicas para Aproveitar ao Maximo"))
    story.append(body(
        "Aqui estao algumas dicas para tirar o maximo de proveito do "
        "PAES MED AI:"
    ))

    story.append(subsection("Rotina de estudos"))
    story.append(bullet("Estude <b>todos os dias</b>, mesmo que seja pouco"))
    story.append(bullet("Faca pelo menos <b>1 sessao de questoes</b> por dia"))
    story.append(bullet("Revise <b>flashcards</b> 10-15 minutos por dia"))
    story.append(bullet("Leia <b>1 material em PDF</b> por semana"))
    story.append(bullet("Use o <b>Tutor IA</b> sempre que tiver duvida"))

    story.append(subsection("Estrategia de revisao"))
    story.append(bullet("Foque nas materias com <b>menor taxa de acerto</b>"))
    story.append(bullet("Refaca questoes que voce <b>errou</b> anteriormente"))
    story.append(bullet("Use o <b>radar</b> para ver quais materias estao fracas"))
    story.append(bullet("Faca <b>simulados</b> proximos a data da prova"))

    story.append(subsection("Atencao aos pegadinhas"))
    story.append(body(
        "Muitas questoes da UEMA tem pegadinhas. O PAES MED AI marca "
        "essas questoes e mostra o tipo de pegadinha na resolucao. "
        "Preste atencao especial a essas questoes."
    ))

    # === SECAO 13: Problemas comuns ===
    story.append(PageBreak())
    story.append(section("13", "Problemas Comuns e Solucoes"))

    story.append(subsection("O aplicativo nao abre"))
    story.append(body(
        "Verifique se o atalho existe na Area de Trabalho. Se nao, "
        "procure no Menu Iniciar por \"PAES MED AI\". Se ainda assim "
        "nao abrir, reinicie o computador e tente novamente."
    ))

    story.append(subsection("Aparece \"Sem conexao\" ou \"Offline\""))
    story.append(body(
        "Isso significa que o backend (servidor local) nao subiu. "
        "Aguarde 10 segundos e feche/reabra o app. Se persistir, "
        "verifique se o Python esta instalado no computador."
    ))

    story.append(subsection("O Tutor IA nao responde"))
    story.append(body(
        "O Tutor IA precisa de internet para funcionar (ele consulta "
        "servicos externos de IA). Verifique sua conexao com a internet. "
        "Se estiver offline, o restante do app funciona normalmente."
    ))

    story.append(warning_box(
        "Se nada funcionar, entre em contato com o suporte: "
        "Yuri Medeiros Bandeira — github.com/ymedeiros228/PAES_MED_AI"
    ))

    # === SECAO 14: Acesso Web ===
    story.append(PageBreak())
    story.append(section("14", "Acesso Web (PWA)"))
    story.append(body(
        "Alem do aplicativo desktop, o PAES MED AI tambem funciona "
        "no navegador. Voce pode acessar de qualquer computador "
        "ou celular com internet."
    ))

    story.append(subsection("Como acessar via web"))
    story.append(step(1, "Abra o navegador (Chrome, Edge, Firefox)"))
    story.append(step(2, "Acesse: https://paes-med-ai.onrender.com"))
    story.append(step(3, "Use normalmente — mesma conta e dados"))

    story.append(tip_box(
        "A versao web sincroniza com a versao desktop. Seu progresso "
        "e mantido em ambas as plataformas."
    ))

    # === CONTRA CAPA ===
    story.append(NextPageTemplate("backcover"))
    story.append(PageBreak())

    doc.build(story)
    print(f"Manual gerado: {OUT}")
    print(f"Tamanho: {OUT.stat().st_size / 1024:.0f} KB")


# Import necessario no final
from reportlab.platypus import NextPageTemplate

if __name__ == "__main__":
    build_manual()
