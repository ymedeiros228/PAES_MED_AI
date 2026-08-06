# Auto-Pilot — TRAVADO / PARA O CURSOR

Itens que o Auto-Pilot **não conseguiu** concluir sozinho.
Formato: `- [ ] [TÍTULO] | por quê | onde | próxima ação`

Sessão GR–GU (host)

- [x] dist pack | Restored: Iniciar bat + branding/app_icon.ico + app/exe + VERSION.txt + Desktop .lnk | host xcopy restore
- [ ] git no PATH do agente | `git.exe` ainda ausente no PATH padrão do shell do agente (Flutter build exige Git) | host | Instalar Git for Windows e garantir `git` no PATH do sistema
- [x] flutter path documentado | usar `C:\Users\Yuri\flutter\bin` | scripts/host

Checklist host residual (se push falhar no agente):
1. Abrir terminal com Git no PATH: `git status` na raiz `PAES_MED_AI`
2. Commit como **Yuri Medeiros** + push `origin/main` (sem force; sem `.env`/`dist`/`*.db`)
3. Fechar PR #2 / branch autopilot se limpo e já em main
