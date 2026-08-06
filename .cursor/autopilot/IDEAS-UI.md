# IDEAS-UI — polish visual (app bonita)

Formato: `- [ ] [tela/área] | ideia curta | por que melhora | esforço S/M`

## Backlog

- [ ] [Fila / checkpoint] | banner “Continuar sessão” com barra de fases (teoria/questões/revisão) | retoma estudo com contexto visual, menos texto cru | S
- [ ] [Sessão / fim de bloco] | resumo em chips (acertos, cards criados, tópicos fracos) em vez de linha única | escaneabilidade no mobile | S
- [x] [Fila / empty] | ilustração leve ou ícone maior quando fila vazia + CTA já visível acima | empty state menos “técnico”, mais acolhedor | S
- [ ] [Sessão / teoria] | trechos do edital em cards com borda suave e contador “3 de 10” | leitura mais confortável em blocos longos | M
- [ ] [Ficha / debrief sessão] | CTA **Ler teoria** no debrief inline (igual ficha) antes de Treinar | mesmo fluxo pós-erro em todos os pontos | S
- [ ] [Theory sheet] | barra de progresso “Passo 1 de 2” no topo do sheet | reforça sequência li → treino sem ler parágrafo | S
- [ ] [Fila / lacunas] | badge “teoria lida” no tile quando mark-read true | evita reabrir sheet à toa | S
- [ ] [Theory sheet] | animação suave ao marcar “li” (check + troca de CTA primário) | feedback imediato do próximo passo | S
- [ ] [Biblioteca / Semana 1] | scroll automático ao painel 2024–26 quando `?semana1=1` na rota | onboarding cai direto no CTA certo | S
- [ ] [Onboarding / passo 3] | preview mini do painel Biblioteca (mock) antes de ir | reduz surpresa na primeira tela real | M
- [ ] [Hoje / coach] | dismiss automático só após Semana 1 OK, não só officialN>0 | coach some no momento certo | S
- [x] [Biblioteca / first-run] | banner Bem-vindo + painel Semana 1 destacado | guia quem veio do onboarding direto à Biblioteca | S
- [ ] [Fila / lacunas] | filtro “só sem material” no topo da seção Lacunas | foco quando várias lacunas misturadas | S
- [ ] [Fila / lacunas] | link direto Biblioteca com subject/topic na query (scroll futuro) | 1 clique do gap certo ao acervo | M
- [ ] [Theory sheet] | empty mostra qual pasta abrir (edital vs provas) conforme note da API | menos adivinhação pós-lacuna | S
- [ ] [Fila / lacunas] | chip contador “N sem teoria” ao lado do SectionLabel | escaneabilidade rápida | S
- [x] [Biblioteca / msg erro PDF] | QuietEmpty com CTA Abrir provas quando open-path falha | 1 ação clara pós-erro de caminho | S
- [x] [Theory sheet / lido] | row check “Marcado como lido” no topo do sheet | feedback visual imediato pós mark-read | S
- [ ] [Fila / lacunas] | subtitle “· li” no tile quando read=true (além do ícone) | reforço textual no mobile | S
- [ ] [Ficha / Ler teoria] | ícone livro preenchido se tópico já lido (fetch reads no load) | estado consistente ficha+fila | S
- [ ] [Theory sheet] | haptic leve ao marcar “li” (mobile/desktop) | confirmação tátil do progresso | S
- [ ] [Biblioteca / ano] | botão PDF desabilitado + tooltip quando hasProva stale mas arquivo sumiu | evita clique falso positivo | S
- [ ] [Ficha / PDF] | link “Onde colocar o PDF” abre pasta provas se sourcePdf null | fecha loop sem jargão | S
- [ ] [Global / open-path] | toast único padronizado (ícone + 2 linhas) em todas as telas | consistência visual | M
