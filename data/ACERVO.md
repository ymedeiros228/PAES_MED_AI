# Acervo oficial — nomenclatura e fluxo

## Pastas

| Pasta | Conteúdo | Nome sugerido |
|-------|----------|---------------|
| `data/provas/` | PDFs das provas | `paes_YYYY.pdf` |
| `data/gabaritos/` | Gabaritos oficiais | `gabarito_YYYY.pdf` |
| `data/edital/` | Edital + resumo MD | `edital_YYYY.pdf` |

O ano **precisa** aparecer no nome do arquivo.

## Fluxo no app

1. Copie os PDFs para as pastas (veja `LEIA-ME.txt` em cada uma).
2. Abra **Biblioteca** → checklist mostra anos faltando / pares prova↔gabarito.
3. **Revisar** → edite disciplina, assunto e gabarito questão a questão.
4. **Commitar** → backup automático + gravação como oficial + reindex RAG.
5. **Sync syllabus** a partir do edital; **Reclassificar**.
6. Estude: sessão / Medicina / Banca passam a preferir oficiais (com limiar ≥10).

Sem PDF, o app continua com **treino** rotulado — nunca inventa prova oficial.

## Manifesto (Ciclo J/K)

Arquivo: `data/ACERVO_MANIFEST.json` — inventário ano a ano com links públicos (`uema.br` / `paes.uema.br`).

Anos com download direto (found): **2024, 2025, 2026**. Em 2024 o manifesto prefere o **gabarito retificado**.

No app: **Biblioteca → Acervo UEMA → Baixar todos disponíveis** → **Revisar** → **Commitar**.

Rótulos: `UEMA_PAES` (oficial commitada) · `TREINO` · `OUTRA` (parecida).

## Histórico completo (2014+)

PDFs de prova: copiar para `data/provas/` como `paes_YYYY.pdf` (e `paes_YYYY_etapa2.pdf` se 2 cadernos).
Gabaritos: `data/gabaritos/gabarito_YYYY.pdf`. Sem gabarito o ano fica **parcial** — estude só após Revisar respostas.

Biblioteca → grade de anos → Importar / Revisar / Commitar.
