"""
Limpeza cirúrgica das alternativas de questões.

Problema identificado:
- A última alternativa de muitas questões tem lixo do PDF colado:
  - Cabeçalho/rodapé: "Processo Seletivo de Acesso... – PAES/2016 - DOCV/UEMA..."
  - Texto da próxima questão: "Questão 54 Leia o texto..."
  - Matéria da próxima página: "LÍNGUA INGLESA", "GEOGRAFIA", etc.
  - Numeração de página: "2 | P á g i n a"

Estratégia:
- Para cada alternativa, procurar o PRIMEIRO padrão de lixo
- Cortar tudo a partir desse ponto
- Limpar espaços e pontuação no final
- Reportar o que foi limpo para auditoria
- Backup automático antes de modificar

Uso:
    python backend/clean_options.py --dry-run   # só audita
    python backend/clean_options.py             # limpa de verdade
"""

from __future__ import annotations

import json
import re
import shutil
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = REPO_ROOT / "data" / "paes_med_ai.db"
DEPLOY_DB_PATH = REPO_ROOT / "deploy" / "data" / "paes_med_ai.db"

# Padrões de lixo — cortar tudo a partir do primeiro match
# Ordem importa: padrões mais específicos primeiro
JUNK_PATTERNS: list[tuple[str, str]] = [
    # Cabeçalho/rodapé do PDF (mais específico primeiro)
    (r"Processo\s+Seletivo\s+de\s+Acesso", "cabecalho_pdf"),
    (r"Processo\s+Seletivo\b", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s+DOCV", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s*-\s*DOCV", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s+DOC", "cabecalho_pdf"),
    (r"DOCV/UEMA", "cabecalho_pdf"),
    (r"DOCV/PROG/UEMA", "cabecalho_pdf"),
    (r"\d+\s*\|\s*P\s*[áa]\s*g\s*i\s*n\s*a", "rodape_pdf"),
    (r"\|\s*P\s*[áa]\s*g\s*i\s*n\s*a\s*\d*", "rodape_pdf"),
    (r"P\s*[áa]\s*g\s*i\s*n\s*a\b", "rodape_pdf"),
    (r"\b1[ªa]\s+ETAPA\b", "cabecalho_pdf"),
    (r"\bSOCIOLOGIA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bFILOSOFIA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bHIST[ÓO]RIA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bGEOGRAFIA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bF[ÍI]SICA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bQU[ÍI]MICA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    (r"\bBIOLOGIA\s+Quest[\s]*[õo]es\s+de\b", "proxima_secao"),
    # Texto da próxima questão
    (r"Quest[\s]*[ãa]o\s*\d+\s+Leia", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Analise", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Considere", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Sobre", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Em\s+rela", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Leia\s+o\s+texto", "proxima_questao"),
    (r"Quest[\s]*[ãa]o\s*\d+\s+Leia\s+a\s+seguinte", "proxima_questao"),
    (r"Leia\s+o\s+Texto\s+[IVX]+\s+para\s+responder", "proxima_questao"),
    (r"Leia\s+o\s+texto\s+a\s+seguir\s+para\s+responder", "proxima_questao"),
    (r"Leia\s+a\s+seguinte\s+curiosidade\s+sobre\s+\w+\s+para\s+responder", "proxima_questao"),
    (r"Leia\s+o\s+seguinte\s+texto\s+sobre\s+\w+\s+para\s+responder", "proxima_questao"),
    (r"Leia\s+o\s+texto\s+a\s+seguir\s+e\s+utilize\s+as\s+informa", "proxima_questao"),
    (r"Leia\s+o\s+texto\s+a\s+seguir\s+e\s+utilize\s+os\s+dados", "proxima_questao"),
    (r"Leia\s+o\s+texto\s+a\s+seguir\s+para\s+analisar", "proxima_questao"),
    # Matéria da próxima página (só se vier depois de ponto final ou quebra)
    (r"\.\s+L[ÍI]NGUA\s+INGLESA\b", "materia_proxima_pagina"),
    (r"\.\s+L[ÍI]NGUA\s+PORTUGUESA\b", "materia_proxima_pagina"),
    (r"\.\s+GEOGRAFIA\b", "materia_proxima_pagina"),
    (r"\.\s+FILOSOFIA\b", "materia_proxima_pagina"),
    (r"\.\s+QU[ÍI]MICA\b", "materia_proxima_pagina"),
    (r"\.\s+SOCIOLOGIA\b", "materia_proxima_pagina"),
    (r"\.\s+HIST[ÓO]RIA\b", "materia_proxima_pagina"),
    (r"\.\s+BIOLOGIA\b", "materia_proxima_pagina"),
    (r"\.\s+F[ÍI]SICA\b", "materia_proxima_pagina"),
    (r"\.\s+MATEM[ÁA]TICA\b", "materia_proxima_pagina"),
    (r"\.\s+LITERATURA\b", "materia_proxima_pagina"),
    (r"\.\s+REDA[ÇC][ÃA]O\b", "materia_proxima_pagina"),
    (r"\.\s+ESPANHOL\b", "materia_proxima_pagina"),
    # Links em alternativas (geralmente lixo de questão de inglês com tirinha)
    (r"http[s]?://\S+\s+Muitos\s+verbos", "link_tirinha"),
    (r"http[s]?://garfield", "link_tirinha"),
    # "Maranhão | Mapa Sound System Brasil" — lixo de rodapé
    (r"Maranhão\s*\|\s*Mapa\s+Sound\s+System", "rodape_lixo"),
    # Faixa de questões da próxima seção (sem "Processo Seletivo" antes)
    (r"\bQuest[\s]*[õo]es\s+de\s+\d{1,2}\s+a\s+\d{1,2}\b", "proxima_secao"),
    (r"\bText\s+to\s+questions\s+\d+", "proxima_secao"),
    (r"\bConsidere\s+el\s+texto\s+a\s+seguir\s+para\s+las\s+cuestiones", "proxima_secao"),
]

# Sufixos de pontuação para limpar após corte
TRAILING_PUNCT = re.compile(r"[\s\u2013\u2014\-\.\,\;\:\!\?\u2026]+$")


def clean_option(
    opt: str,
    *,
    sibling_opts: list[str] | None = None,
) -> tuple[str, str | None, str | None]:
    """
    Limpa uma alternativa.
    Retorna (texto_limpo, tipo_de_lixo_removido, texto_removido).
    Se não há lixo, retorna (opt_original, None, None).
    """
    if not opt or len(opt.strip()) < 3:
        return opt, None, None

    for pattern, kind in JUNK_PATTERNS:
        m = re.search(pattern, opt, re.IGNORECASE)
        if m:
            # Cortar tudo a partir do match
            clean = opt[: m.start()].rstrip()
            # Limpar pontuação/símbolos finais órfãos
            clean = TRAILING_PUNCT.sub("", clean).rstrip()
            removed = opt[m.start() :]
            # Se o texto limpo ficou muito curto (< 2 chars), manter original
            # (pode ser falso positivo)
            if len(clean) < 2:
                # Tentar sem o ponto final antes do corte
                clean2 = opt[: m.start()].rstrip(".\u2026")
                clean2 = TRAILING_PUNCT.sub("", clean2).rstrip()
                if len(clean2) >= 2:
                    return clean2, kind, removed
                # Se ainda muito curto, não limpar (provável falso positivo)
                return opt, None, None
            return clean, kind, removed

    # Irmãs curtas + esta enorme: tipicamente tabela/rodapé colado na última alt.
    if sibling_opts and len(sibling_opts) >= 3:
        sizes = [len(s) for s in sibling_opts if s and len(s.strip()) >= 1]
        if sizes:
            avg = sum(sizes) / len(sizes)
            if avg < 80 and len(opt) > max(avg * 3.5, 120):
                search_start = max(1, int(avg * 0.8))
                upper_re = re.compile(r"\s+(?=[A-ZÀ-Ý]{2,})")
                m = upper_re.search(opt, search_start)
                if m and m.start() > 2:
                    clean = TRAILING_PUNCT.sub("", opt[: m.start()].rstrip()).rstrip()
                    if 2 <= len(clean) <= max(int(avg * 4), 100):
                        return clean, "tamanho_relativo", opt[m.start() :]

    return opt, None, None


def clean_database(db_path: Path, *, dry_run: bool = True) -> tuple[int, int, list[str]]:
    """Limpa opções poluídas em um SQLite. Retorna (limpas, sem_lixo, linhas_relatorio)."""
    if not db_path.exists():
        raise FileNotFoundError(f"banco não encontrado em {db_path}")

    if not dry_run:
        backup = db_path.with_suffix(
            f".db.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        )
        shutil.copy2(db_path, backup)
        print(f"Backup criado: {backup}")

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row

    rows = conn.execute(
        "SELECT id, statement, options_json, correct_index, source FROM questions ORDER BY id"
    ).fetchall()

    cleaned_count = 0
    skipped_count = 0
    report_lines: list[str] = []

    for r in rows:
        opts = json.loads(r["options_json"]) if r["options_json"] else []
        if not opts:
            continue

        changed = False
        new_opts = list(opts)
        # Até 2 passes: junk explícito, depois tamanho relativo com irmãs já limpas
        for _ in range(2):
            pass_changed = False
            for i, opt in enumerate(new_opts):
                siblings = [new_opts[j] for j in range(len(new_opts)) if j != i]
                clean, kind, removed = clean_option(opt, sibling_opts=siblings)
                if kind is not None and clean != opt:
                    pass_changed = True
                    changed = True
                    report_lines.append(
                        f"ID: {r['id']} | alt[{i}] | kind: {kind} | db: {db_path.name} | source: {r['source']}\n"
                        f"  ANTES: {opt[:300]}\n"
                        f"  DEPOIS: {clean[:300]}\n"
                        f"  REMOVIDO: {(removed or '')[:200]}\n"
                    )
                    new_opts[i] = clean
            if not pass_changed:
                break

        if changed:
            cleaned_count += 1
            if not dry_run:
                conn.execute(
                    "UPDATE questions SET options_json = ? WHERE id = ?",
                    (json.dumps(new_opts, ensure_ascii=False), r["id"]),
                )
        else:
            skipped_count += 1

    if not dry_run:
        conn.commit()
    conn.close()
    return cleaned_count, skipped_count, report_lines


def main(dry_run: bool = True, *, also_deploy: bool = True) -> int:
    targets = [DB_PATH]
    if also_deploy and DEPLOY_DB_PATH.exists():
        targets.append(DEPLOY_DB_PATH)

    all_report: list[str] = []
    total_rows = 0
    total_cleaned = 0
    total_skipped = 0

    for path in targets:
        try:
            cleaned, skipped, lines = clean_database(path, dry_run=dry_run)
        except FileNotFoundError as exc:
            print(f"ERRO: {exc}")
            return 1
        # Conta aproximada via relatório + skipped
        total_cleaned += cleaned
        total_skipped += skipped
        total_rows += cleaned + skipped
        all_report.append(f"### {path}\nLimpas={cleaned} Sem lixo={skipped}\n")
        all_report.extend(lines)
        print(f"[{path.name}] Limpas: {cleaned}, Sem lixo: {skipped}")

    report_path = REPO_ROOT / "clean_report.txt"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(f"Modo: {'DRY RUN' if dry_run else 'APLICADO'}\n")
        f.write(f"Total questoes (todas as bases): {total_rows}\n")
        f.write(f"Questoes limpas: {total_cleaned}\n")
        f.write(f"Questoes sem lixo: {total_skipped}\n")
        f.write("=" * 80 + "\n\n")
        f.write("\n".join(all_report))
    print(f"Modo: {'DRY RUN' if dry_run else 'APLICADO'}")
    print(f"Total: {total_rows}, Limpas: {total_cleaned}, Sem lixo: {total_skipped}")
    print(f"Relatorio: {report_path}")
    return 0


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv or "--dry" in sys.argv
    only_main = "--only-main" in sys.argv
    sys.exit(main(dry_run=dry, also_deploy=not only_main))
