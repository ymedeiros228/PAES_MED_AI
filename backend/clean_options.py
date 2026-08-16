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

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "paes_med_ai.db"

# Padrões de lixo — cortar tudo a partir do primeiro match
# Ordem importa: padrões mais específicos primeiro
JUNK_PATTERNS: list[tuple[str, str]] = [
    # Cabeçalho/rodapé do PDF (mais específico primeiro)
    (r"Processo\s+Seletivo\s+de\s+Acesso", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s+DOCV", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s*-\s*DOCV", "cabecalho_pdf"),
    (r"\s*[\u2013\u2014\-]\s*PAES\s*/?\s*\d{4}\s+DOC", "cabecalho_pdf"),
    (r"DOCV/UEMA", "cabecalho_pdf"),
    (r"DOCV/PROG/UEMA", "cabecalho_pdf"),
    (r"\d+\s*\|\s*P\s*[áa]\s*g\s*i\s*n\s*a", "rodape_pdf"),
    (r"\|\s*P\s*[áa]\s*g\s*i\s*n\s*a\s*\d*", "rodape_pdf"),
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
]

# Sufixos de pontuação para limpar após corte
TRAILING_PUNCT = re.compile(r"[\s\u2013\u2014\-\.\,\;\:\!\?\u2026]+$")


def clean_option(opt: str) -> tuple[str, str | None, str | None]:
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

    return opt, None, None


def main(dry_run: bool = True) -> int:
    if not DB_PATH.exists():
        print(f"ERRO: banco não encontrado em {DB_PATH}")
        return 1

    # Backup antes de modificar
    if not dry_run:
        backup = DB_PATH.with_suffix(
            f".db.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        )
        shutil.copy2(DB_PATH, backup)
        print(f"Backup criado: {backup}")

    conn = sqlite3.connect(str(DB_PATH))
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
        new_opts = []
        for i, opt in enumerate(opts):
            clean, kind, removed = clean_option(opt)
            if kind is not None:
                changed = True
                report_lines.append(
                    f"ID: {r['id']} | alt[{i}] | kind: {kind} | source: {r['source']}\n"
                    f"  ANTES: {opt[:300]}\n"
                    f"  DEPOIS: {clean[:300]}\n"
                    f"  REMOVIDO: {removed[:200]}\n"
                )
                new_opts.append(clean)
            else:
                new_opts.append(opt)

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

    # Relatório
    report_path = Path(__file__).resolve().parent.parent / "clean_report.txt"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(f"Modo: {'DRY RUN' if dry_run else 'APLICADO'}\n")
        f.write(f"Total questoes: {len(rows)}\n")
        f.write(f"Questoes limpas: {cleaned_count}\n")
        f.write(f"Questoes sem lixo: {skipped_count}\n")
        f.write("=" * 80 + "\n\n")
        f.write("\n".join(report_lines))
    print(f"Modo: {'DRY RUN' if dry_run else 'APLICADO'}")
    print(f"Total: {len(rows)}, Limpas: {cleaned_count}, Sem lixo: {skipped_count}")
    print(f"Relatorio: {report_path}")
    return 0


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv or "--dry" in sys.argv
    sys.exit(main(dry_run=dry))
