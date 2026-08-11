# Deploy web — PAES MED AI

## O que este documento explica

Como subir o app pra web de forma que **você atualiza de casa** e o **cliente só abre o site** (PWA — instala no celular/PC com um botão, atualiza sozinho).

## Arquitetura

```
Você (casa)              GitHub (privado)           Render (cloud)           Cliente
   │                          │                        │                      │
   │── git push ─────────────→│                        │                      │
   │                          │── webhook ────────────→│                      │
   │                          │                        │ rebuild + deploy     │
   │                          │                        │ API + front + dados  │
   │                          │                        │←── abre site ────────│
   │                          │                        │── serve app ────────→│
   │                          │                        │   PWA: instala       │
   │                          │                        │   Próxima visita:   │
   │                          │                        │   pega update        │
```

Tudo num servidor só: **API + front + banco + PDFs**.

## Passo a passo (uma vez)

### 1. Criar repo no GitHub (privado)

```bash
# No seu PC, dentro de PAES_MED_AI/
git init  # se ainda não tiver
git add .
git commit -m "Versão web + PWA"
git remote add origin https://github.com/ymedeiros228/paes-med-ai.git
git push -u origin main
```

**Importante:** o `.gitignore` já exclui `data/backups/` (53GB), `data/paes_med_ai.db`, `.env`, `dist/`, `build/`. Só sobe código + PDFs de provas (~50MB).

### 2. Configurar no Render

1. Acesse https://render.com e crie conta (ou login com GitHub)
2. **New → Blueprint**
3. Selecione o repo `paes-med-ai`
4. Render detecta `render.yaml` automaticamente
5. Configure as env vars:
   - `GEMINI_API_KEY` → sua chave do Gemini (a que você já tem)
   - `GEMINI_MODEL` → `gemini-2.0-flash` (ou o modelo que preferir)
   - `PAES_ALLOWED_ORIGINS` → vazio (deploy unificado, mesma origin)
6. **Create**
7. Render faz build + deploy (~5-10 min na primeira vez)
8. URL final: `https://paes-med-ai.onrender.com` (Render dá o nome)

### 3. Testar

- Abra a URL no browser
- O app carrega com splash → tela de Hoje
- Vai em Ajustes > Tutor IA → a chave já está configurada (no servidor)
- Faça uma pergunta pro Tutor → deve responder online
- Abra uma prova na Biblioteca → PDF abre no browser

### 4. PWA (instalar no celular do cliente)

- Cliente abre a URL no Chrome (Android) ou Safari (iOS)
- Aparece "Adicionar à tela inicial" ou "Instalar"
- Aceita → ícone aparece no celular como app
- Próxima vez que você atualizar (git push), ele pega na próxima abertura

## Atualizar (você, de casa)

```bash
# Qualquer mudança no código ou dados:
git add .
git commit -m "descrição da mudança"
git push
```

Render rebuild automaticamente (~5-10 min). Cliente pega na próxima visita.

## Custo

- **Render free tier**: 750h/mês, dorme após 15min inativo (desperta em ~30s no primeiro acesso)
- **Gemini free tier**: generoso pra uso pessoal
- Se precisar 24/7 sem sleep: Render paid = $7/mês

## Troubleshooting

### App não carrega (tela branca)
- Abra DevTools (F12) → Console
- Se ver erro de CORS: confira `PAES_ALLOWED_ORIGINS` no Render
- Se ver erro de `main.dart.js`: o build Flutter falhou, verifique logs do Render

### Tutor IA não responde
- Verifique `GEMINI_API_KEY` no Render (Settings → Environment)
- Teste: `curl https://sua-url.onrender.com/health` → `gemini_configured: true`

### PDFs não abrem
- Verifique se os PDFs subiram no git: `git ls-files data/provas/`
- Se não: `git add data/provas/*.pdf data/gabaritos/*.pdf && git push`

### Banco vazio (0 questões)
- O bootstrap roda no primeiro startup; pode demorar 1-2 min
- Verifique logs do Render: deve ver "ingested: [{year: 2024, inserted: 35}, ...]"
- Se não: force reseed com `PAES_BOOTSTRAP_PROD=1` (já vem ligado)
