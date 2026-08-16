# Deploy no Render — Passo a Passo

## Estado atual (pronto para deploy)

- ✅ Build Flutter web gerado (88MB em `deploy/web/`)
- ✅ Banco atualizado (27MB, 720 questões, 738 flashcards)
- ✅ 92 PDFs de materiais em `deploy/data/materiais/`
- ✅ Dockerfile configurado (Python 3.13 + FastAPI + Flutter web)
- ✅ render.yaml configurado (plano Free)
- ✅ Backend testado localmente: health, PDFs, questões, front web — tudo OK
- ✅ Código commitado e pushado para GitHub (commit `9fdb0b5`)

## Passo 1 — Criar conta no Render

1. Acesse https://render.com
2. Clique em **Sign Up** ou **Login**
3. Faça login com GitHub (botão "Sign up with GitHub")

## Passo 2 — Criar o serviço

1. No dashboard, clique em **New** → **Blueprint**
2. Selecione o repositório `ymedeiros228/PAES_MED_AI`
3. O Render detecta o `render.yaml` automaticamente
4. O serviço `paes-med-ai` aparece com plano Free

## Passo 3 — Configurar variáveis de ambiente

Na página do serviço, aba **Environment**, adicione:

| Variável | Valor |
|----------|-------|
| `GROQ_API_KEY` | *(sua chave Groq — a que já funciona localmente)* |
| `GEMINI_API_KEY` | *(sua chave Gemini)* |
| `OPENROUTER_API_KEY` | *(sua chave OpenRouter)* |
| `OPENAI_API_KEY` | *(sua chave OpenAI)* |
| `PAES_BOOTSTRAP_PROD` | `1` |

As variáveis `GEMINI_MODEL`, `GROQ_MODEL`, `OPENROUTER_MODEL`, `OPENAI_MODEL` já têm valores padrão no `render.yaml`.

## Passo 4 — Deploy

1. Clique em **Apply** ou **Create**
2. O Render faz o build do Dockerfile automaticamente
3. Aguarde 5-10 minutos (primeiro build é mais lento)
4. A URL será: `https://paes-med-ai.onrender.com`

## Passo 5 — Testar

Abra a URL no navegador:
- `https://paes-med-ai.onrender.com/` → app Flutter web
- `https://paes-med-ai.onrender.com/health` → `{"status":"ok"}`
- `https://paes-med-ai.onrender.com/api/materials/pdf-list` → lista de 92 PDFs
- `https://paes-med-ai.onrender.com/api/questions?limit=5` → 5 questões

## Atualizações futuras

A cada `git push` para `main`, o Render rebuilda automaticamente.

## Problemas comuns

- **Build demora muito**: primeiro build baixa Python 3.13 + dependências. Segundos builds usam cache.
- **Plano Free hiberna**: depois de 15min sem acesso, o serviço hiberna. Primeiro acesso após hibernação demora ~30s.
- **Sem disco persistente**: no plano Free, dados escritos em runtime são perdidos no redeploy. Por isso o banco vem commitado no Docker image.
