"""Popula a tabela syllabus com o conteúdo programático completo do PAES UEMA.

Baseado no Edital oficial PAES 2026 (Edital 57/2025-GR/UEMA).
Cobertura: 11 disciplinas, ~415 subtópicos.
"""

from __future__ import annotations

from db import db

# Pesos estimados para Medicina (Biologia/Química/Física pesam mais)
_SUBJECT_WEIGHTS = {
    "Biologia": 1.5,
    "Química": 1.4,
    "Física": 1.3,
    "Matemática": 1.2,
    "Português": 1.1,
    "Literatura": 1.0,
    "Inglês": 0.9,
    "Espanhol": 0.9,
    "História": 1.0,
    "Geografia": 1.0,
    "Filosofia": 0.9,
    "Sociologia": 0.9,
}

_SYLLABUS: list[tuple[str, str, str, float]] = [
    # === BIOLOGIA ===
    ("Biologia", "Introdução à Biologia", "Conceitos básicos e linguagem científica", 1.3),
    ("Biologia", "Introdução à Biologia", "Características dos seres vivos", 1.3),
    ("Biologia", "Introdução à Biologia", "Método científico", 1.0),
    ("Biologia", "Introdução à Biologia", "Teoria da geração espontânea e biogênese", 1.2),
    ("Biologia", "Introdução à Biologia", "Teoria da evolução química", 1.2),
    ("Biologia", "Introdução à Biologia", "Teoria da endossimbiose", 1.3),
    ("Biologia", "Introdução à Biologia", "Substâncias orgânicas e inorgânicas", 1.4),
    ("Biologia", "Introdução à Biologia", "Macro e micronutrientes", 1.2),
    ("Biologia", "Citologia", "Membrana plasmática", 1.5),
    ("Biologia", "Citologia", "Citoplasma", 1.3),
    ("Biologia", "Citologia", "Organelas celulares", 1.5),
    ("Biologia", "Citologia", "Núcleo e cariótipo", 1.4),
    ("Biologia", "Citologia", "Ciclo celular", 1.4),
    ("Biologia", "Citologia", "Mitose e meiose", 1.5),
    ("Biologia", "Citologia", "Gametogênese", 1.4),
    ("Biologia", "Citologia", "Anomalias cromossômicas", 1.3),
    ("Biologia", "Metabolismo Celular", "Anabolismo e catabolismo", 1.4),
    ("Biologia", "Metabolismo Celular", "Respiração celular", 1.5),
    ("Biologia", "Metabolismo Celular", "Fermentação", 1.3),
    ("Biologia", "Metabolismo Celular", "Fotossíntese", 1.5),
    ("Biologia", "Reprodução e Embriologia", "Reprodução assexuada e sexuada", 1.2),
    ("Biologia", "Reprodução e Embriologia", "Reprodução humana", 1.4),
    ("Biologia", "Reprodução e Embriologia", "Métodos contraceptivos", 1.3),
    ("Biologia", "Reprodução e Embriologia", "Desenvolvimento embrionário", 1.4),
    ("Biologia", "Reprodução e Embriologia", "Anexos embrionários", 1.2),
    ("Biologia", "Histologia", "Tecido epitelial", 1.3),
    ("Biologia", "Histologia", "Tecido conjuntivo", 1.3),
    ("Biologia", "Histologia", "Tecido muscular", 1.3),
    ("Biologia", "Histologia", "Tecido nervoso", 1.4),
    ("Biologia", "Ecologia", "Fluxo de energia", 1.4),
    ("Biologia", "Ecologia", "Ciclos biogeoquímicos", 1.4),
    ("Biologia", "Ecologia", "Relações ecológicas", 1.5),
    ("Biologia", "Ecologia", "Ecologia de populações", 1.3),
    ("Biologia", "Ecologia", "Biomas e biodiversidade", 1.3),
    ("Biologia", "Ecologia", "Problemas ambientais", 1.2),
    ("Biologia", "Classificação e Sistemática", "Sistema de classificação", 1.1),
    ("Biologia", "Classificação e Sistemática", "Nomenclatura científica", 1.0),
    ("Biologia", "Classificação e Sistemática", "Reinos e domínios", 1.2),
    ("Biologia", "Microbiologia", "Vírus", 1.4),
    ("Biologia", "Microbiologia", "Bactérias", 1.4),
    ("Biologia", "Microbiologia", "Protozoários", 1.3),
    ("Biologia", "Microbiologia", "Algas", 1.1),
    ("Biologia", "Microbiologia", "Fungos", 1.3),
    ("Biologia", "Botânica", "Classificação das plantas", 1.1),
    ("Biologia", "Botânica", "Histologia das angiospermas", 1.2),
    ("Biologia", "Botânica", "Morfologia das angiospermas", 1.2),
    ("Biologia", "Botânica", "Fisiologia vegetal", 1.3),
    ("Biologia", "Botânica", "Reprodução das plantas", 1.2),
    ("Biologia", "Zoologia", "Poríferos e cnidários", 1.0),
    ("Biologia", "Zoologia", "Platelmintos e nematódios", 1.3),
    ("Biologia", "Zoologia", "Anelídeos e moluscos", 1.1),
    ("Biologia", "Zoologia", "Artrópodes", 1.2),
    ("Biologia", "Zoologia", "Equinodermos", 1.0),
    ("Biologia", "Zoologia", "Peixes e anfíbios", 1.1),
    ("Biologia", "Zoologia", "Répteis e aves", 1.1),
    ("Biologia", "Zoologia", "Mamíferos", 1.2),
    ("Biologia", "Genética", "Leis de Mendel", 1.5),
    ("Biologia", "Genética", "Polialelia e sistemas sanguíneos", 1.4),
    ("Biologia", "Genética", "Interações gênicas", 1.3),
    ("Biologia", "Genética", "Ligação gênica e recombinação", 1.3),
    ("Biologia", "Genética", "Teoria cromossômica", 1.3),
    ("Biologia", "Genética", "Mutações", 1.3),
    ("Biologia", "Genética", "Engenharia genética", 1.2),
    ("Biologia", "Evolução", "Evidências da evolução", 1.2),
    ("Biologia", "Evolução", "Lamarck e Darwin", 1.3),
    ("Biologia", "Evolução", "Genética de populações", 1.2),
    ("Biologia", "Evolução", "Especiação", 1.2),
    ("Biologia", "Evolução", "Evolução humana", 1.1),
    ("Biologia", "Saúde e Doenças", "Doenças virais e bacterianas", 1.4),
    ("Biologia", "Saúde e Doenças", "Doenças parasitárias", 1.4),
    ("Biologia", "Saúde e Doenças", "Sistema imunológico", 1.5),
    ("Biologia", "Saúde e Doenças", "Vacinas e soros", 1.3),
    ("Biologia", "Saúde e Doenças", "DSTs", 1.3),

    # === QUÍMICA ===
    ("Química", "Princípios Elementares", "Matéria e energia", 1.3),
    ("Química", "Princípios Elementares", "Fenômenos físicos e químicos", 1.2),
    ("Química", "Princípios Elementares", "Estados físicos da matéria", 1.2),
    ("Química", "Princípios Elementares", "Substâncias e alotropia", 1.3),
    ("Química", "Princípios Elementares", "Misturas e separação", 1.3),
    ("Química", "Teoria Atômica", "Evolução do modelo atômico", 1.4),
    ("Química", "Teoria Atômica", "Partículas atômicas", 1.3),
    ("Química", "Teoria Atômica", "Isótopos, isóbaros, isótonos", 1.3),
    ("Química", "Teoria Atômica", "Configuração eletrônica", 1.5),
    ("Química", "Classificação Periódica", "Estrutura da tabela periódica", 1.3),
    ("Química", "Classificação Periódica", "Propriedades periódicas", 1.4),
    ("Química", "Ligações Químicas", "Ligação iônica", 1.4),
    ("Química", "Ligações Químicas", "Ligação covalente", 1.4),
    ("Química", "Ligações Químicas", "Polaridade e geometria molecular", 1.5),
    ("Química", "Ligações Químicas", "Forças intermoleculares", 1.4),
    ("Química", "Ligações Químicas", "Ligação metálica", 1.2),
    ("Química", "Transformações Químicas", "Equação química e balanceamento", 1.4),
    ("Química", "Transformações Químicas", "Tipos de reações", 1.3),
    ("Química", "Transformações Químicas", "Número de oxidação", 1.3),
    ("Química", "Funções Inorgânicas", "Ácidos", 1.4),
    ("Química", "Funções Inorgânicas", "Bases", 1.4),
    ("Química", "Funções Inorgânicas", "Sais", 1.3),
    ("Química", "Funções Inorgânicas", "Óxidos", 1.3),
    ("Química", "Funções Inorgânicas", "Teorias ácido-base", 1.2),
    ("Química", "Cálculos Químicos", "Mol e número de Avogadro", 1.4),
    ("Química", "Cálculos Químicos", "Leis ponderais", 1.2),
    ("Química", "Cálculos Químicos", "Estequiometria", 1.5),
    ("Química", "Gases", "Propriedades e leis dos gases", 1.3),
    ("Química", "Gases", "Equação do gás ideal", 1.3),
    ("Química", "Soluções", "Conceitos e tipos", 1.3),
    ("Química", "Soluções", "Concentração e diluição", 1.4),
    ("Química", "Termoquímica", "Calor e entalpia", 1.4),
    ("Química", "Termoquímica", "Lei de Hess", 1.3),
    ("Química", "Cinética e Equilíbrio", "Cinética química", 1.3),
    ("Química", "Cinética e Equilíbrio", "Equilíbrio químico", 1.4),
    ("Química", "Cinética e Equilíbrio", "Princípio de Le Chatelier", 1.3),
    ("Química", "Eletroquímica", "Pilhas", 1.4),
    ("Química", "Eletroquímica", "Eletrólise", 1.3),
    ("Química", "Química Orgânica", "Cadeias carbônicas", 1.4),
    ("Química", "Química Orgânica", "Funções orgânicas", 1.5),
    ("Química", "Química Orgânica", "Isomeria", 1.4),
    ("Química", "Química Orgânica", "Reações orgânicas", 1.3),

    # === FÍSICA ===
    ("Física", "Grandezas e Unidades", "Sistema Internacional de Unidades", 1.1),
    ("Física", "Cinemática", "Movimento Uniforme (MU)", 1.4),
    ("Física", "Cinemática", "Movimento Uniformemente Variado (MUV)", 1.4),
    ("Física", "Cinemática", "Queda livre", 1.4),
    ("Física", "Cinemática", "Lançamento horizontal e oblíquo", 1.4),
    ("Física", "Dinâmica", "Leis de Newton", 1.5),
    ("Física", "Dinâmica", "Forças (peso, normal, atrito, elástica)", 1.5),
    ("Física", "Dinâmica", "Plano inclinado", 1.3),
    ("Física", "Dinâmica", "Trabalho e energia", 1.5),
    ("Física", "Dinâmica", "Conservação de momento e colisões", 1.4),
    ("Física", "Dinâmica", "Gravitação Universal", 1.3),
    ("Física", "Hidrostática", "Densidade e pressão", 1.4),
    ("Física", "Hidrostática", "Teorema de Stevin e Pascal", 1.3),
    ("Física", "Hidrostática", "Princípio de Arquimedes (Empuxo)", 1.4),
    ("Física", "Termologia", "Calor e temperatura", 1.3),
    ("Física", "Termologia", "Escalas termométricas", 1.2),
    ("Física", "Termologia", "Dilatação térmica", 1.3),
    ("Física", "Termologia", "Calorimetria", 1.4),
    ("Física", "Termologia", "Termodinâmica", 1.4),
    ("Física", "Termologia", "Máquinas térmicas e Carnot", 1.3),
    ("Física", "Óptica Geométrica", "Espelhos planos e esféricos", 1.4),
    ("Física", "Óptica Geométrica", "Reflexão e refração", 1.4),
    ("Física", "Óptica Geométrica", "Lentes esféricas", 1.3),
    ("Física", "Ondulatória", "Movimento harmônico simples", 1.3),
    ("Física", "Ondulatória", "Ondas e fenômenos ondulatórios", 1.3),
    ("Física", "Ondulatória", "Acústica e Efeito Doppler", 1.2),
    ("Física", "Eletrostática", "Carga elétrica e Lei de Coulomb", 1.4),
    ("Física", "Eletrostática", "Campo e potencial elétrico", 1.4),
    ("Física", "Eletrodinâmica", "Corrente e resistores", 1.4),
    ("Física", "Eletrodinâmica", "Circuitos elétricos", 1.4),
    ("Física", "Eletromagnetismo", "Campo e força magnética", 1.3),
    ("Física", "Eletromagnetismo", "Indução e Lei de Faraday", 1.3),
    ("Física", "Física Moderna", "Efeito fotoelétrico", 1.2),
    ("Física", "Física Moderna", "Estrutura atômica e relatividade", 1.2),
    ("Física", "Física Moderna", "Radioatividade", 1.2),

    # === MATEMÁTICA ===
    ("Matemática", "Aritmética", "Números reais e operações", 1.2),
    ("Matemática", "Aritmética", "Divisibilidade, MDC e MMC", 1.3),
    ("Matemática", "Aritmética", "Razão, proporção e regra de três", 1.4),
    ("Matemática", "Aritmética", "Porcentagem e juros", 1.4),
    ("Matemática", "Conjuntos", "Noções de conjuntos", 1.1),
    ("Matemática", "Funções", "Conceito de função", 1.4),
    ("Matemática", "Funções", "Função do 1º grau", 1.4),
    ("Matemática", "Funções", "Função do 2º grau", 1.5),
    ("Matemática", "Funções", "Função modular e exponencial", 1.3),
    ("Matemática", "Funções", "Função logarítmica", 1.3),
    ("Matemática", "Funções", "Funções trigonométricas", 1.3),
    ("Matemática", "Geometria Plana", "Ângulos e triângulos", 1.3),
    ("Matemática", "Geometria Plana", "Polígonos e circunferência", 1.3),
    ("Matemática", "Geometria Espacial", "Poliedros e volumes", 1.4),
    ("Matemática", "Geometria Espacial", "Prismas, pirâmides e corpos redondos", 1.3),
    ("Matemática", "Matrizes e Sistemas", "Matrizes e determinantes", 1.3),
    ("Matemática", "Matrizes e Sistemas", "Sistemas lineares", 1.3),
    ("Matemática", "Trigonometria", "Relações métricas e leis dos senos/cossenos", 1.3),
    ("Matemática", "Trigonometria", "Ciclo trigonométrico e identidades", 1.3),
    ("Matemática", "Análise Combinatória", "Princípio fundamental de contagem", 1.3),
    ("Matemática", "Análise Combinatória", "Arranjo, permutação e combinação", 1.3),
    ("Matemática", "Estatística e Probabilidade", "Médias e gráficos estatísticos", 1.3),
    ("Matemática", "Estatística e Probabilidade", "Probabilidade", 1.4),
    ("Matemática", "Estatística e Probabilidade", "PA e PG", 1.3),
    ("Matemática", "Geometria Analítica", "Reta e distâncias", 1.3),
    ("Matemática", "Geometria Analítica", "Cônicas", 1.2),

    # === PORTUGUÊS ===
    ("Português", "Comunicação e Linguagem", "Linguagem, língua e fala", 1.1),
    ("Português", "Comunicação e Linguagem", "Níveis e funções da linguagem", 1.2),
    ("Português", "Semântica", "Sinonímia, antonímia, polissemia", 1.2),
    ("Português", "Semântica", "Acentuação gráfica", 1.1),
    ("Português", "Texto e Textualidade", "Tipologia textual e gêneros", 1.3),
    ("Português", "Texto e Textualidade", "Coesão e coerência", 1.3),
    ("Português", "Morfossintaxe", "Classes de palavras", 1.3),
    ("Português", "Morfossintaxe", "Concordância e regência", 1.4),
    ("Português", "Morfossintaxe", "Pontuação", 1.3),
    ("Português", "Sintaxe do Período", "Coordenação e subordinação", 1.3),
    ("Português", "Sintaxe do Período", "Tipos de discurso", 1.2),
    ("Português", "Literatura", "Figuras de linguagem", 1.2),
    ("Português", "Literatura", "Estilos de época", 1.3),
    ("Português", "Literatura", "Literatura maranhense", 1.2),
    ("Português", "Literatura", "Obras de leitura obrigatória", 1.4),

    # === INGLÊS ===
    ("Inglês", "Leitura e Interpretação", "Skimming e scanning", 1.2),
    ("Inglês", "Leitura e Interpretação", "Inferência de significado", 1.1),
    ("Inglês", "Léxico", "Palavras cognatas", 1.0),
    ("Inglês", "Gramática", "Tempos verbais", 1.3),
    ("Inglês", "Gramática", "Pronomes e adjetivos", 1.1),
    ("Inglês", "Gramática", "Verbos frasais", 1.1),
    ("Inglês", "Gramática", "Conjunções e preposições", 1.0),

    # === ESPANHOL ===
    ("Espanhol", "Comprensión de Textos", "Gêneros textuais em espanhol", 1.1),
    ("Espanhol", "Aspectos Lexicales", "Sinonimia e polisemia", 1.1),
    ("Espanhol", "Gramática", "Verbos regulares e irregulares", 1.3),
    ("Espanhol", "Gramática", "Perífrasis verbales", 1.1),
    ("Espanhol", "Gramática", "Conectivos", 1.1),

    # === HISTÓRIA ===
    ("História", "Mundo Antigo", "Egito, Grécia e Roma", 1.2),
    ("História", "Mundo Antigo", "Reinos Africanos", 1.1),
    ("História", "Mundo Medieval", "Feudalismo e religiões", 1.2),
    ("História", "Idade Moderna", "Grandes Navegações e Renascimento", 1.3),
    ("História", "Idade Moderna", "Colonização e escravidão", 1.3),
    ("História", "Idade Contemporânea", "Revoluções e Imperialismo", 1.3),
    ("História", "Idade Contemporânea", "Guerras Mundiais", 1.3),
    ("História", "Brasil Contemporâneo", "Era Vargas e Ditadura", 1.3),
    ("História", "Brasil Contemporâneo", "Redemocratização e atualidade", 1.2),
    ("História", "História do Maranhão", "Maranhão Colonial e Imperial", 1.3),
    ("História", "História do Maranhão", "Movimentos sociais no Maranhão", 1.2),

    # === GEOGRAFIA ===
    ("Geografia", "Geografia Física", "Terra, coordenadas e fusos", 1.2),
    ("Geografia", "Geografia Física", "Clima e vegetação", 1.3),
    ("Geografia", "Geografia Física", "Relevo e hidrografia", 1.2),
    ("Geografia", "Geografia Humana", "Demografia e migrações", 1.3),
    ("Geografia", "Geografia Humana", "Urbanização", 1.3),
    ("Geografia", "Geografia Econômica", "Agricultura e indústria", 1.2),
    ("Geografia", "Geografia Econômica", "Comércio e transportes", 1.1),
    ("Geografia", "Geografia Política", "Geopolítica e megablocos", 1.2),
    ("Geografia", "Geografia do Maranhão", "Economia e sociedade maranhense", 1.3),
    ("Geografia", "Temas Contemporâneos", "Questão ambiental e sustentabilidade", 1.2),

    # === FILOSOFIA ===
    ("Filosofia", "Cultura", "Natureza, cultura e sagrado", 1.0),
    ("Filosofia", "Conhecimento", "Tipos de conhecimento e ciência", 1.1),
    ("Filosofia", "A Filosofia", "Origem e períodos da filosofia", 1.0),
    ("Filosofia", "Lógica", "Argumentação e lógica", 1.1),
    ("Filosofia", "Estética", "O belo e a arte", 1.0),
    ("Filosofia", "Política", "Estado e democracia", 1.2),
    ("Filosofia", "Ética", "Valores, moral e direitos humanos", 1.2),

    # === SOCIOLOGIA ===
    ("Sociologia", "Surgimento", "Contexto histórico da Sociologia", 1.0),
    ("Sociologia", "Perspectivas Clássicas", "Durkheim, Marx e Weber", 1.2),
    ("Sociologia", "Conceitos Básicos", "Socialização e instituições", 1.1),
    ("Sociologia", "Mudança Social", "Estratificação e desigualdade", 1.2),
    ("Sociologia", "Violência", "Tipos de violência", 1.1),
    ("Sociologia", "Cultura e Ideologia", "Cultura e multiculturalismo", 1.1),
    ("Sociologia", "Trabalho", "Fordismo, Taylorismo e Toyotismo", 1.1),
    ("Sociologia", "Estado e Poder", "Democracia e cidadania", 1.1),
    ("Sociologia", "Contemporâneo", "Globalização e neoliberalismo", 1.1),
]


def populate_syllabus(force: bool = False) -> int:
    """Popula a tabela syllabus. Retorna o número de entradas inseridas."""
    inserted = 0
    with db() as conn:
        for subject, topic, subtopic, weight in _SYLLABUS:
            # ID determinístico
            slug = f"{subject}_{topic}_{subtopic}".lower().replace(" ", "_")
            for old, new in [("á","a"),("é","e"),("í","i"),("ó","o"),("ú","u"),("ã","a"),("õ","o"),("ç","c"),("/","_"),("(",""),(")","")]:
                slug = slug.replace(old, new)
            sid = f"sy_{slug}"

            if not force:
                existing = conn.execute("SELECT id FROM syllabus WHERE id=?", (sid,)).fetchone()
                if existing:
                    continue

            conn.execute(
                "INSERT OR REPLACE INTO syllabus (id, subject, topic, subtopic, weight) VALUES (?, ?, ?, ?, ?)",
                (sid, subject, topic, subtopic, weight),
            )
            inserted += 1
        conn.commit()
    return inserted


if __name__ == "__main__":
    count = populate_syllabus(force=True)
    print(f"Syllabus populado: {count} entradas inseridas.")
    with db() as conn:
        total = conn.execute("SELECT COUNT(*) FROM syllabus").fetchone()[0]
        print(f"Total no banco: {total}")
        for subject in ["Biologia", "Química", "Física", "Matemática", "Português", "Inglês", "Espanhol", "História", "Geografia", "Filosofia", "Sociologia"]:
            n = conn.execute("SELECT COUNT(*) FROM syllabus WHERE subject=?", (subject,)).fetchone()[0]
            print(f"  {subject}: {n} tópicos")
