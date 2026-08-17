# PAES MED AI — Documentação Técnica Completa

**Plataforma Inteligente de Estudos para PAES/UEMA Medicina**

| Campo | Valor |
|-------|-------|
| **Desenvolvedor** | Yuri Medeiros Bandeira |
| **Cliente** | Jonas Almeida Medeiros |
| **Versão documentada** | 1.0.0.26 |
| **Data** | 16 de agosto de 2026 |
| **Licença** | Uso controlado (ver LICENSE) |
| **Repositório** | github.com/ymedeiros228/PAES_MED_AI |

---

## 1. Introdução

### 1.1 Contexto

O **PAES** (Processo Seletivo Seriado) da **UEMA** (Universidade Estadual do Maranhão) é o principal caminho para ingresso no curso de **Medicina** da universidade. A prova cobre conteúdo de todo o ensino médio em 9 disciplinas, com peso maior para Biologia, Química e Física.

Estudantes maranhenses precisam de uma ferramenta que:

- Centralize **questões oficiais reais** de provas anteriores (2014–2026)
- Ofereça **resoluções detalhadas** e **macetes** para cada questão
- Permita **revisão espaçada** com flashcards
- Forneça **material de estudo** organizado por disciplina
- Funcione **offline** (sem depender de internet)
- Tenha um **tutor de IA** para tirar dúvidas

O **PAES MED AI** resolve todos esses pontos em uma única plataforma desktop.

### 1.2 Objetivo geral

Desenvolver uma plataforma desktop offline-first para preparação completa ao PAES/UEMA Medicina, com banco de questões reais, resoluções, flashcards, material de estudo e tutor de IA.

### 1.3 Objetivos específicos

- Banco com **720 questões reais** de 13 anos de prova (2014–2026)
- **738 flashcards** para revisão espaçada
- **218 aulas** em texto com teoria completa
- **92 materiais em PDF** organizados por disciplina
- **Resoluções detalhadas** para todas as questões
- Tutor de IA opcional (OpenAI, Groq, Gemini ou OpenRouter)
- Funcionamento 100% offline (sem internet)
- Instalador Windows profissional com atalho na Área de Trabalho
- PWA para acesso via navegador

---

## 2. Requisitos funcionais

### 2.1 Banco de questões

| Recurso | Descrição |
|---------|-----------|
| Questões reais | 720 questões de provas oficiais PAES/UEMA (2014–2026) |
| 9 disciplinas | Biologia, Química, Física, História, Português, Matemática, Filosofia, Geografia, Sociologia |
| Resoluções | Cada questão tem resolução detalhada em português |
| Macetes e pegadinhas | Dicas mnemônicas e avisos de armadilhas comuns |
| Filtros | Por disciplina, ano, tópico, dificuldade |
| Modo simulado | Reproduz condições de prova cronometrada |

### 2.2 Flashcards (revisão espaçada)

- 738 flashcards gerados a partir do conteúdo
- Algoritmo de repetição espaçada (SRS)
- Filtros por disciplina e tópico
- Marcação de "acertei/errei"
- Priorização de cards vencidos (due)

### 2.3 Material de estudo

- 92 PDFs com teoria completa por disciplina
- Diagramas e imagens ilustrativas
- Indexação automática por tópico
- Leitor PDF integrado
- Cobertura completa do edital PAES

### 2.4 Tutor de IA

- Suporte a múltiplos provedores: OpenAI, Groq, Gemini, OpenRouter
- Configuração via tela de Configurações
- Funciona **offline** se nenhuma chave for configurada
- Explica conceitos, resolve dúvidas e sugere planos de estudo
- Histórico de conversas salvo localmente

### 2.5 Dashboard e progresso

- Estatísticas em tempo real: questões respondidas, taxa de acerto
- Gráficos de desempenho por disciplina
- Streak de dias consecutivos de estudo
- Progresso por disciplina
- Recomendações de estudo personalizadas

### 2.6 Plano de estudo

- Data da prova configurável
- Cronograma automático até o dia da prova
- Distribuição de tópicos por dia
- Checkpoints de progresso
- Identificação de lacunas de conhecimento

### 2.7 Simulados

- Reprodução fiel das condições de prova
- Cronômetro com tempo real
- Correção automática com gabarito
- Estatísticas por simulado
- Histórico de simulados anteriores

---

## 3. Requisitos não funcionais

| Requisito | Implementação |
|-----------|---------------|
| Performance | SQLite com WAL mode, Gzip em respostas > 1KB |
| Segurança | CORS restrito a origens locais, chaves em .env |
| Privacidade | 100% local — dados não saem do computador |
| Offline-first | Sem dependência de internet para funcionar |
| Portabilidade | Windows desktop + PWA web |
| UX | Material 3, Google Fonts (Inter/Poppins), modo escuro |
| Confiabilidade | Launcher robusto com fallback offline |
| Instalação | Inno Setup com atalho desktop e desinstalador |

---

## 4. Arquitetura de software

### 4.1 Stack tecnológica

| Camada | Tecnologia |
|--------|-----------|
| Frontend desktop | Flutter 3.x + Riverpod + GoRouter |
| Frontend web | Flutter Web (PWA) |
| Backend | FastAPI (Python) + Uvicorn |
| Banco de dados | SQLite com WAL mode |
| IA (opcional) | OpenAI / Groq / Gemini / OpenRouter |
| Empacotamento | Inno Setup 6 (Windows) |
| Tipografia | Google Fonts (Inter, Poppins) |
| Gráficos | fl_chart |
| PDFs | pypdf (leitura) + reportlab (geração) |

### 4.2 Estrutura de pastas

```
PAES_MED_AI/
├── lib/                          # Código Flutter (Dart)
│   ├── main.dart                 # Entry point
│   ├── app.dart                  # App + rotas
│   ├── core/                     # Núcleo (API client, tema, versão)
│   └── features/                 # Funcionalidades
│       ├── adaptive/             # Layout responsivo
│       ├── ai_tutor/             # Tutor de IA
│       ├── approval/             # Aprovação de questões
│       ├── bank_profile/         # Perfil do banco
│       ├── dashboard/            # Tela principal
│       ├── essay/                # Redações
│       ├── flashcards/           # Revisão espaçada
│       ├── focus/                # Modo foco
│       ├── gamification/         # Gamificação
│       ├── lessons/              # Aulas em texto
│       ├── library/              # Biblioteca
│       ├── materials/            # Materiais PDF
│       ├── medicine/             # Conteúdo médico
│       ├── onboarding/           # Primeiro acesso
│       ├── progress/             # Progresso do usuário
│       ├── questions/            # Banco de questões
│       ├── revisions/            # Revisões
│       ├── session/              # Sessão de estudo
│       ├── settings/             # Configurações
│       ├── simulations/          # Simulados
│       ├── study_plan/           # Plano de estudo
│       └── today/                # Estudo do dia
├── backend/                      # API FastAPI (Python)
│   ├── main.py                   # Entry point da API
│   ├── config.py                 # Configuração de ambiente
│   ├── db.py                     # Conexão SQLite
│   ├── routers/                  # Endpoints da API
│   │   ├── ai.py                 # Tutor de IA
│   │   ├── essays.py             # Redações
│   │   ├── flashcards.py         # Flashcards
│   │   ├── ingest.py             # Importação de PDFs
│   │   ├── library.py            # Biblioteca
│   │   ├── materials.py          # Materiais
│   │   ├── media.py              # Mídia (imagens)
│   │   ├── meta.py               # Metadados
│   │   ├── questions.py          # Questões
│   │   ├── simulations.py        # Simulados
│   │   ├── stats.py              # Estatísticas
│   │   └── study.py              # Estudo
│   ├── services_core.py          # Serviços principais
│   ├── services_advanced.py      # Serviços avançados
│   ├── services_media.py         # Serviços de mídia
│   ├── requirements.txt          # Dependências Python
│   └── .env.example              # Exemplo de configuração
├── data/                         # Dados locais
│   ├── paes_med_ai.db            # Banco SQLite (720 questões)
│   ├── materiais/                # 92 PDFs de estudo
│   ├── edital/                   # Edital PAES
│   ├── gabaritos/                # Gabaritos oficiais
│   └── logs/                     # Logs do sistema
├── windows/                      # Configuração Flutter Windows
├── web/                          # Configuração PWA
├── assets/                       # Ícones e branding
├── installer/                    # Inno Setup
│   ├── paes_med_ai.iss           # Script do instalador
│   └── Output/                   # Instalador compilado
├── tools/                        # Scripts utilitários
├── Iniciar_PAES_MED_AI.bat       # Launcher Windows
├── Iniciar_PAES_MED_AI.vbs       # Wrapper invisível
├── VERSION                       # Versão atual
└── pubspec.yaml                  # Dependências Flutter
```

### 4.3 Fluxo de execução (desktop)

```
Usuário clica no atalho "PAES MED AI Desktop"
        ↓
wscript.exe executa Iniciar_PAES_MED_AI.vbs (invisível)
        ↓
VBS chama Iniciar_PAES_MED_AI.bat (escondido)
        ↓
Launcher abre paes_med_ai.exe IMEDIATAMENTE
        ↓
Em paralelo: sobe backend Uvicorn na porta 8000
        ↓
App Flutter conecta a http://127.0.0.1:8000
        ↓
Dados aparecem (dashboard, questões, flashcards)
```

### 4.4 Modelo de dados

#### Tabelas principais

| Tabela | Registros | Descrição |
|--------|-----------|-----------|
| questions | 720 | Questões com resolução, macete e pegadinha |
| flashcards | 738 | Flashcards para revisão espaçada |
| lessons | 218 | Aulas em texto por tópico |
| materials | 92 | Materiais PDF indexados |
| answers | — | Respostas do usuário |
| revisions | — | Revisões agendadas |
| study_plan | — | Plano de estudo personalizado |
| session_checkpoint | — | Checkpoint de sessão |
| settings | — | Configurações do usuário |
| essays | — | Redações |
| embeddings | — | Embeddings para busca semântica |
| syllabus | — | Ementário PAES |
| study_gaps | — | Lacunas de conhecimento |
| ingest_jobs | — | Jobs de importação de PDF |
| ingest_previews | — | Previews de importação |

#### Colunas da tabela `questions`

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | INTEGER PK | Identificador único |
| year | INTEGER | Ano da prova (2014–2026) |
| subject | TEXT | Disciplina |
| topic | TEXT | Tópico |
| subtopic | TEXT | Subtópico |
| statement | TEXT | Enunciado da questão |
| options_json | TEXT | Alternativas (JSON) |
| correct_index | INTEGER | Índice da resposta correta |
| difficulty | TEXT | Dificuldade (fácil/médio/difícil) |
| tags_json | TEXT | Tags (JSON) |
| source | TEXT | Fonte (prova oficial/gerada) |
| resolution | TEXT | Resolução detalhada |
| banca_intent | TEXT | Intenção da banca |
| macete | TEXT | Macete mnemônico |
| pegadinha | TEXT | Aviso de pegadinha |
| related_topics_json | TEXT | Tópicos relacionados |
| keywords_json | TEXT | Palavras-chave |
| has_graph | INTEGER | Tem gráfico |
| has_table | INTEGER | Tem tabela |
| has_image | INTEGER | Tem imagem |
| generated | INTEGER | É gerada por IA |
| approved | INTEGER | Foi aprovada |
| exam_board | TEXT | Banca examinadora |

---

## 5. Conteúdo do banco de dados

### 5.1 Distribuição por disciplina

| Disciplina | Questões | Prioridade |
|------------|----------|------------|
| História | 167 | Alta |
| Física | 149 | Alta (peso Medicina) |
| Biologia | 90 | **Máxima (peso Medicina)** |
| Química | 80 | **Máxima (peso Medicina)** |
| Língua Portuguesa e Literatura | 69 | Média |
| Matemática | 50 | Média |
| Filosofia | 45 | Média |
| Geografia | 39 | Média |
| Sociologia | 31 | Baixa |
| **Total** | **720** | |

### 5.2 Distribuição por ano

| Ano | Questões | Ano | Questões |
|-----|----------|-----|----------|
| 2014 | 79 | 2021 | 48 |
| 2015 | 59 | 2022 | 47 |
| 2016 | 57 | 2023 | 41 |
| 2017 | 66 | 2024 | 81 |
| 2018 | 68 | 2025 | 50 |
| 2019 | 34 | 2026 | 46 |
| 2020 | 44 | | |

### 5.3 Material de estudo (92 PDFs)

| Disciplina | PDFs | Cobertura |
|------------|------|-----------|
| Biologia | 19 | Citologia, Genética, Ecologia, Zoologia, Botânica, Microbiologia, Histologia, Reprodução, Saúde, Evolução, Classificação, Metabolismo |
| Física | 11 | Cinemática, Dinâmica, Eletrostática, Eletrodinâmica, Eletromagnetismo, Hidrostática, Ondulatória, Óptica, Termologia, Física Moderna, Grandezas |
| Química | 13 | Princípios, Átomos, Classificação, Ligações, Funções, Reações, Soluções, Gases, Cálculos, Termoquímica, Eletroquímica, Cinética, Orgânica |
| História | 6 | Mundo Antigo, Medieval, Moderno, Contemporâneo, Brasil Contemporâneo, Maranhão |
| Português | 7 | Comunicação, Morfossintaxe, Semântica, Sintaxe, Texto, Literatura, Obras |
| Matemática | 11 | Aritmética, Conjuntos, Funções, Geometria Plana/Espacial/Analítica, Matrizes, Trigonometria, Estatística, Análise Combinatória |
| Filosofia | 7 | Filosofia, Conhecimento, Ética, Política, Cultura, Estética, Lógica |
| Geografia | 4 | Física, Humana, Maranhão, Temas Contemporâneos |
| Sociologia | 9 | Surgimento, Clássicas, Conceitos, Cultura, Estado, Trabalho, Mudança, Violência, Contemporâneos |
| Espanhol | 3 | Compreensão, Gramática, Semântica |
| Inglês | 3 | Gramática, Leitura, Léxico |

---

## 6. Instalação e execução

### 6.1 Instalação para o usuário final (Windows)

1. Baixar o instalador `PAESMedAI_Setup_1.0.0.26.exe`
2. Executar o instalador (duplo clique)
3. Seguir o assistente (Next → Next → Install)
4. Ao final, será criado:
   - Atalho na Área de Trabalho: **PAES MED AI Desktop**
   - Atalhos no Menu Iniciar: Iniciar, Atualizar, Desinstalar
5. Clicar no atalho **PAES MED AI Desktop** para abrir

**Local de instalação:** `C:\Users\<usuario>\AppData\Local\Programs\PAES_MED_AI\`

### 6.2 Estrutura instalada

```
PAES_MED_AI/
├── Iniciar_PAES_MED_AI.bat       # Launcher
├── Iniciar_PAES_MED_AI.vbs       # Wrapper invisível
├── VERSION.txt                   # Versão instalada
├── app/
│   ├── paes_med_ai.exe           # App Flutter
│   ├── flutter_windows.dll       # Runtime Flutter
│   └── data/                     # Assets do app
├── backend/                      # API FastAPI
│   ├── main.py
│   ├── routers/
│   └── requirements.txt
├── data/                         # Dados locais
│   ├── paes_med_ai.db            # Banco SQLite
│   ├── materiais/                # 92 PDFs
│   ├── edital/
│   └── gabaritos/
└── tools/                        # Scripts utilitários
```

### 6.3 Desenvolvimento local

**Pré-requisitos:**
- Python 3.10+
- Flutter 3.x
- Inno Setup 6 (para compilar instalador)

**Passo a passo:**

```bash
# 1. Clonar repositório
git clone https://github.com/ymedeiros228/PAES_MED_AI.git
cd PAES_MED_AI

# 2. Backend
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload

# 3. Frontend (outra janela)
flutter pub get
flutter run -d windows
```

**URLs de desenvolvimento:**
- App: janela do Flutter
- API: http://127.0.0.1:8000
- Swagger: http://127.0.0.1:8000/docs

### 6.4 Compilar instalador

```bash
# 1. Build Flutter Windows
flutter build windows --release

# 2. Preparar staging
python tools/prepare_installer.py

# 3. Compilar instalador
cd installer
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" paes_med_ai.iss
```

**Resultado:** `installer/Output/PAESMedAI_Setup_1.0.0.26.exe`

### 6.5 Deploy web (PWA)

```bash
flutter build web --release
# Deploy do build/web para Render, Vercel ou similar
```

---

## 7. API REST

### 7.1 Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Health check |
| GET | `/api/dashboard` | Dashboard com estatísticas |
| GET | `/api/questions` | Lista questões (com filtros) |
| GET | `/api/questions/{id}` | Questão específica com resolução |
| POST | `/api/questions/{id}/answer` | Registra resposta |
| GET | `/api/flashcards` | Lista flashcards (dueOnly opcional) |
| POST | `/api/flashcards/{id}/review` | Registra revisão |
| GET | `/api/materials` | Lista materiais PDF |
| GET | `/api/materials/{id}/file` | Download de PDF |
| GET | `/api/lessons` | Lista aulas |
| GET | `/api/lessons/{id}` | Aula específica |
| GET | `/api/simulations` | Lista simulados |
| POST | `/api/simulations` | Cria simulado |
| GET | `/api/stats` | Estatísticas do usuário |
| GET | `/api/study/plan` | Plano de estudo |
| POST | `/api/study/exam-date` | Define data da prova |
| GET | `/api/coach/recommendations` | Recomendações de IA |
| POST | `/api/ai/chat` | Chat com tutor de IA |
| GET | `/api/ai/config` | Configuração de IA |
| POST | `/api/ai/config` | Atualiza configuração |
| GET | `/api/session/checkpoint` | Checkpoint de sessão |
| GET | `/api/session/plan` | Plano da sessão |

### 7.2 Configuração de IA

O tutor de IA suporta 4 provedores configuráveis via arquivo `.env`:

| Provedor | Variáveis | Modelo padrão |
|----------|-----------|---------------|
| OpenAI | `OPENAI_API_KEY`, `OPENAI_MODEL` | gpt-4.1-mini |
| Groq | `GROQ_API_KEY`, `GROQ_MODEL` | llama-3.3-70b-versatile |
| Gemini | `GEMINI_API_KEY`, `GEMINI_MODEL` | gemini-3-flash-preview |
| OpenRouter | `OPENROUTER_API_KEY`, `OPENROUTER_MODEL` | — |

**Sem chave configurada:** o app funciona 100% offline, apenas sem o tutor de IA.

---

## 8. Launcher e inicialização

### 8.1 Fluxo do launcher

O launcher (`Iniciar_PAES_MED_AI.bat`) foi projetado para:

1. **Abrir o app imediatamente** (~2 segundos) — sem esperar o backend
2. **Subir o backend em paralelo** — Uvicorn na porta 8000
3. **Usar caminho completo do Python** — evita o Windows Store stub
4. **Funcionar mesmo sem Python** — app abre em modo offline
5. **Não mostrar tela preta** — VBS wrapper executa tudo invisível

### 8.2 Resolução de problemas

| Problema | Solução |
|----------|---------|
| App não abre | Verificar se `app/paes_med_ai.exe` existe |
| "Sem conexão" | Aguardar 5–10s (backend subindo) ou verificar Python |
| Backend não sobe | Verificar `data/logs/launcher.log` |
| Python não encontrado | Instalar Python 3.10+ de python.org |
| Porta 8000 ocupada | Launcher mata processo automaticamente |

---

## 9. Segurança e privacidade

### 9.1 Dados do usuário

- **100% locais** — nenhum dado sai do computador
- Banco SQLite em `data/paes_med_ai.db`
- Respostas, progresso e configurações ficam no computador
- Backup automático em `data/backups/`

### 9.2 Chaves de API

- Chaves de IA ficam em `backend/.env` (não incluído no instalador)
- Nunca expostas no código ou logs
- Configuráveis via tela de Configurações

### 9.3 CORS

- Apenas origens locais permitidas (localhost, 127.0.0.1)
- Em deploy web, configurar `PAES_ALLOWED_ORIGINS`

---

## 10. Roadmap

| Fase | Período | Entregas |
|------|---------|----------|
| 1 MVP | Jan–Ago/2026 | App desktop, 720 questões, flashcards, materiais, instalador |
| 2 IA | Set/2026 | Tutor de IA com múltiplos provedores |
| 3 Web | Out/2026 | PWA deployada em Render/Vercel |
| 4 Mobile | 2027 | App Android/iOS |
| 5 Social | 2027 | Ranking, grupos de estudo, compartilhamento |

---

## 11. Versões e releases

| Versão | Data | Principais mudanças |
|--------|------|---------------------|
| 1.0.0.19 | Ago/2026 | Primeira versão com instalador |
| 1.0.0.20 | Ago/2026 | Correção de contraste no modo escuro |
| 1.0.0.22 | Ago/2026 | Ícones PWA e desktop separados |
| 1.0.0.23 | Ago/2026 | Restauro do ícone desktop original |
| 1.0.0.24 | Ago/2026 | Correção do atalho (userdesktop) + VBS wrapper |
| 1.0.0.25 | Ago/2026 | App abre imediatamente (sem esperar backend) |
| 1.0.0.26 | Ago/2026 | Backend conecta (caminho completo do Python) |

---

## 12. Contato e créditos

**Projeto:** PAES MED AI
**Desenvolvedor:** Yuri Medeiros Bandeira
**Cliente:** Jonas Almeida Medeiros
**Repositório:** github.com/ymedeiros228/PAES_MED_AI
**Versão:** 1.0.0.26
**Data:** 16 de agosto de 2026

---

## 13. Assinaturas

```
_________________________________________
Yuri Medeiros Bandeira
Desenvolvedor
16 de agosto de 2026

_________________________________________
Jonas Almeida Medeiros
Cliente
16 de agosto de 2026
```

---

© 2026 PAES MED AI — Todos os direitos reservados.
Desenvolvido por Yuri Medeiros Bandeira para Jonas Almeida Medeiros.
