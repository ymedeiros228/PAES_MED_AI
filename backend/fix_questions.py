"""Correção de qualidade das questões persistidas no banco.

Resolve problemas reportados:
- Enunciados cortados/truncados.
- Alternativas vazias, duplicadas ou misturadas com texto de outras questões.
- Artefatos de PDF no enunciado (―, ‖, cabeçalhos).
- Gabaritos não aplicados (correct_index sempre 0).
- Source não marcado como 'oficial'.

Executa em três fases:
1. Diagnóstico — lista questões problemáticas com quality_score.
2. Correção — limpa enunciados, corta contaminação, remove irrecuperáveis.
3. Gabarito — aplica gabaritos oficiais e marca source='oficial'.
"""

from __future__ import annotations

import json
import re
from typing import Any

from db import db
from ingest_pdf import (
    clean_question_statement,
    extract_pdf_text,
    pair_prova_gabarito,
    parse_gabarito,
)

# Caracteres de artefato de PDF (apenas caracteres estranhos, não – e — que são legítimos)
_PDF_ARTIFACT_CHARS = re.compile(r"[\u2015\u2016\u2017]{1,}")
# Aspas tipográficas não-ASCII que viraram lixo
_BROKEN_QUOTES = re.compile(r"[“”„‟「」『』]")
# Marcadores de opção colados (a) b) c) no meio de texto)
_INLINE_OPTION_LEAK = re.compile(r"(?<=\S)\s+[a-e]\s*[\)\.]\s+[A-ZÀ-Ý]")
# Padrões que indicam início de próxima questão colada em alternativa
_NEXT_Q_START = re.compile(
    r"(?i)(?:^|\s)(?:"
    r"leia\s+(?:o|a|um|uma)\s|"
    r"analise\s+(?:o|a|um|uma)\s|"
    r"observe\s+(?:o|a|um|uma)\s|"
    r"considere\s+(?:o|a|um|uma|que)\s|"
    r"de\s+acordo\s+com\s+o\s+texto\s|"
    r"quest(?:[ãa]o|ao)\s*\d|"
    r"seg[uú]n\s+el\s+texto\s|"
    r"according\s+to\s+the\s+text\s|"
    r"read\s+the\s+(?:following|text|passage)\s|"
    r"o\s+tempo\s+sempre\s+instigou\s|"
    r"sistema\s+solar\s|"
    r"[ií]ndice\s+pluviom[ée]trico\s|"
    r"ingredientes\s+quantidade\s|"
    r"a\s+fic[cç][aã]o\s+inspira\s|"
    r"os\s+termos\s+orto\s|"
    r"no\s+romance\s+as\s+meninas\s|"
    r"para\s+responder\s+[aà]\s+quest[ãa]o\s|"
    r"em\s+casa\s+de\s+pens[ãa]o\s"
    r")"
)


def _is_numeric_option(opt: str) -> bool:
    """Detecta alternativas numéricas/expressões curtas legítimas (mat/qui/fis/bio)."""
    o = opt.strip()
    if not o:
        return False
    # Genética: AA, Aa, aa, AA e Aa, aa e aa, AABB, AaBb
    if re.match(r"^[aA]{1,2}(\s+e\s+[aA]{1,2})?$", o):
        return True
    if re.match(r"^[aA][aAbB]{1,3}$", o) and len(o) <= 6:
        return True
    # Porcentagem: 0%, 25%, 50%
    if re.match(r"^\d+%?$", o) and len(o) < 10:
        return True
    # Números puros, com decimais/vírgulas: 15, 3.14, 1/2, √5
    if re.match(r"^[\d\s\.\,\+\-\*\/\(\)\=\<\>\√\^\°x-yà-ÿ]+$", o) and len(o) < 40:
        return True
    # Fórmulas curtas: Ci < p, F=ma, 2x10-5, 2 x 10-5 °C-1
    if re.match(r"^[a-zA-ZÀ-ÿ][\s\=\+\-\<\>\d\.\,\(\)\°\^\*\/]*$", o) and len(o) < 30:
        return True
    # Numerais romanos: I., II., III., IV.
    if re.match(r"^[IVXLCDM]+\.?$", o) and len(o) < 10:
        return True
    return False


def _quality_score(row: sqlite3_Row_like) -> int:
    """Calcula score 0-100. <20 = irrecuperável."""
    score = 100
    stmt = str(row["statement"] or "")
    opts = json.loads(row["options_json"]) if row["options_json"] else []

    # Enunciado curto
    if len(stmt) < 25:
        score -= 60
    elif len(stmt) < 60:
        score -= 30
    elif len(stmt) < 100:
        score -= 15

    # Alternativas vazias — só penaliza se NÃO for numérica legítima
    empty_count = sum(1 for o in opts if len(o.strip()) < 3 and not _is_numeric_option(o))
    score -= empty_count * 15

    # Alternativas duplicadas — só penaliza se não forem todas iguais e curtas
    lower_opts = [o.strip().lower() for o in opts]
    if len(set(lower_opts)) < len(lower_opts):
        # Genética (AA, Aa, aa) é legítimo
        if not all(_is_numeric_option(o) for o in opts):
            score -= 20

    # Alternativas muito longas — só penaliza se NÃO for literatura (todas longas)
    long_count = sum(1 for o in opts if len(o) > 300)
    if long_count > 0:
        # Se todas (ou quase todas) são longas, é questão de literatura legítima
        if long_count >= 4:
            score -= 0  # literatura — não penaliza
        else:
            score -= long_count * 10

    # Artefatos de PDF
    if _PDF_ARTIFACT_CHARS.search(stmt):
        score -= 10
    if _BROKEN_QUOTES.search(stmt):
        score -= 5

    # correct_index fora do range
    ci = int(row["correct_index"] or 0)
    if ci < 0 or ci >= len(opts):
        score -= 30

    return max(0, score)


def diagnose_questions() -> dict[str, Any]:
    """Lista todas as questões com problemas e seus scores."""
    with db() as conn:
        rows = conn.execute(
            "SELECT id, year, subject, topic, statement, options_json, correct_index, source, exam_board FROM questions"
        ).fetchall()

    problems: list[dict[str, Any]] = []
    stats = {
        "total": len(rows),
        "shortStatement": 0,
        "emptyOptions": 0,
        "duplicateOptions": 0,
        "longOptions": 0,
        "pdfArtifacts": 0,
        "badCorrectIndex": 0,
        "unrecoverable": 0,
        "noGabarito": 0,
    }

    for r in rows:
        score = _quality_score(r)
        opts = json.loads(r["options_json"]) if r["options_json"] else []
        stmt = str(r["statement"] or "")
        ci = int(r["correct_index"] or 0)
        issues: list[str] = []

        if len(stmt) < 60:
            issues.append("enunciado_curto")
            stats["shortStatement"] += 1
        empty = sum(1 for o in opts if len(o.strip()) < 3 and not _is_numeric_option(o))
        if empty > 0:
            issues.append(f"alternativas_vazias({empty})")
            stats["emptyOptions"] += 1
        lower = [o.strip().lower() for o in opts]
        if len(set(lower)) < len(lower):
            if not all(_is_numeric_option(o) for o in opts):
                issues.append("alternativas_duplicadas")
                stats["duplicateOptions"] += 1
        long_n = sum(1 for o in opts if len(o) > 300)
        if long_n > 0 and long_n < 4:  # só reporta se não for literatura (4+ longas)
            issues.append(f"alternativas_longas({long_n})")
            stats["longOptions"] += 1
        if _PDF_ARTIFACT_CHARS.search(stmt):
            issues.append("artefatos_pdf")
            stats["pdfArtifacts"] += 1
        if ci < 0 or ci >= len(opts):
            issues.append("correct_index_invalido")
            stats["badCorrectIndex"] += 1
        if ci == 0 and (r["exam_board"] or "") == "UEMA_PAES":
            issues.append("sem_gabarito_aplicado")
            stats["noGabarito"] += 1
        if score < 30:
            stats["unrecoverable"] += 1

        if issues:
            problems.append(
                {
                    "id": r["id"],
                    "year": r["year"],
                    "subject": r["subject"],
                    "score": score,
                    "issues": issues,
                    "statementPreview": stmt[:120],
                    "optionsCount": len(opts),
                    "correctIndex": ci,
                }
            )

    problems.sort(key=lambda x: x["score"])
    return {"stats": stats, "problems": problems}


def _clean_artifacts(text: str) -> str:
    """Remove artefatos de PDF de qualquer texto (enunciado ou alternativa)."""
    if not text:
        return text
    # Barras duplas ‖ → vazio
    cleaned = text.replace("\u2016", "")
    # Aspas longas ‗ → aspa simples
    cleaned = cleaned.replace("\u2017", "'")
    # Traço horizontal estranho ― (U+2015) → em-dash normal —
    cleaned = cleaned.replace("\u2015", "—")
    # Aspas tipográficas quebradas → aspas normais
    cleaned = _BROKEN_QUOTES.sub('"', cleaned)
    # Espaços múltiplos
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def _cut_option_contamination(option: str, other_opts: list[str]) -> str:
    """Corta texto de próxima questão colado em alternativa."""
    if not option or len(option) < 50:
        return option
    # Se todas as outras opções são curtas (números), esta deve ser curta também
    valid_sizes = [len(o) for o in other_opts if o and len(o) > 0]
    avg_other = (sum(valid_sizes) / len(valid_sizes)) if valid_sizes else 0
    all_short = avg_other > 0 and avg_other < 30

    # Procura padrão de início de próxima questão
    match = _NEXT_Q_START.search(option)
    if match:
        # Se outras opções são curtas, corta mesmo se contaminação começa cedo
        min_start = 2 if all_short else 10
        if match.start() >= min_start:
            cleaned = option[: match.start()].rstrip()
            cleaned = re.sub(r"[\s,;:\-–—\.\[\]\"”]+$", "", cleaned).rstrip()
            if len(cleaned) >= 2 if all_short else 5:
                return cleaned
    # Heurística por tamanho: se opção é muito maior que as outras
    if valid_sizes and len(option) > 250:
        avg = avg_other
        if len(option) > avg * 2.5:
            # Procura ponto final após tamanho médio
            search_start = max(1, int(avg * 0.8))
            for delim in [". ", ";\n", ".\n"]:
                idx = option.find(delim, search_start)
                if idx >= 0:
                    cleaned = option[: idx + 1].rstrip()
                    cleaned = re.sub(r"[\s,;:\-–—\[\]\"”]+$", "", cleaned).rstrip()
                    if 5 <= len(cleaned) <= max(int(avg * 4), 200):
                        return cleaned
    return option


def _is_legitimate_short_option(opt: str, subject: str) -> bool:
    """Detecta alternativas curtas legítimas (genética, matemática)."""
    o = opt.strip().lower()
    # Genética: AA, Aa, aa, AA e Aa, etc.
    if any(g in o for g in ["aa", "aa e aa", "aa e aa", "aa e aa"]):
        if re.match(r"^[aA]{1,2}(\s+e\s+[aA]{1,2})?$", o):
            return True
    # Matemática: números, expressões curtas
    if re.match(r"^[\d\s\.\,\+\-\*\/\(\)\=\<\>\√\^\°x-y]+$", o) and len(o) < 30:
        return True
    # Física/Química: fórmulas curtas
    if re.match(r"^[a-zA-Z][\s\=\+\-\<\>\d\.\,\(\)\°]*$", o) and len(o) < 20:
        return True
    return False


def fix_question_data(*, delete_unrecoverable: bool = True) -> dict[str, int]:
    """Executa correção completa no banco. Retorna contagens."""
    changed_statements = 0
    changed_options = 0
    deleted = 0
    fixed_artifacts = 0

    with db() as conn:
        rows = conn.execute(
            "SELECT id, year, subject, statement, options_json, correct_index, source, exam_board FROM questions"
        ).fetchall()

        for r in rows:
            score = _quality_score(r)
            opts = json.loads(r["options_json"]) if r["options_json"] else []
            original_stmt = str(r["statement"] or "")
            list(opts)

            # Deletar irrecuperáveis
            if delete_unrecoverable and score < 20:
                conn.execute("DELETE FROM questions WHERE id=?", (r["id"],))
                deleted += 1
                continue

            # 1. Limpar artefatos do enunciado
            stmt = _clean_artifacts(original_stmt)
            stmt = clean_question_statement(stmt)
            if stmt != original_stmt:
                fixed_artifacts += 1
                changed_statements += 1

            # 2. Limpar alternativas
            new_opts: list[str] = []
            opts_changed = False
            for i, opt in enumerate(opts):
                cleaned = _clean_artifacts(str(opt) if opt else "")
                other = [str(o) for j, o in enumerate(opts) if j != i]
                cleaned = _cut_option_contamination(cleaned, other)
                if cleaned != str(opt):
                    opts_changed = True
                new_opts.append(cleaned)

            # 3. Detectar alternativas todas iguais (irrecuperável)
            lower_new = [o.strip().lower() for o in new_opts]
            if len(set(lower_new)) == 1 and len(lower_new[0]) < 5:
                if delete_unrecoverable:
                    conn.execute("DELETE FROM questions WHERE id=?", (r["id"],))
                    deleted += 1
                    continue

            # 3a. Detectar 4+ alternativas iguais e curtas (irrecuperável)
            from collections import Counter as _Counter
            opt_counts = _Counter(lower_new)
            most_common, most_count = opt_counts.most_common(1)[0]
            if most_count >= 4 and len(most_common) < 5:
                if delete_unrecoverable:
                    conn.execute("DELETE FROM questions WHERE id=?", (r["id"],))
                    deleted += 1
                    continue

            # 3b. Detectar alternativas garbled/quebradas (ex: "FTS", "9FTS", "c ( ) 1 2")
            garbled_count = sum(
                1 for o in new_opts
                if re.search(r"[a-zA-Z]\d|\d[a-zA-Z]\s|\(\s*\)|\d\s*\(\s*\)", o)
                and not _is_numeric_option(o)
                and len(o) < 30
            )
            if garbled_count >= 3 and delete_unrecoverable:
                conn.execute("DELETE FROM questions WHERE id=?", (r["id"],))
                deleted += 1
                continue

            if stmt != original_stmt or opts_changed:
                conn.execute(
                    "UPDATE questions SET statement=?, options_json=?, avg_text_len=? WHERE id=?",
                    (
                        stmt,
                        json.dumps(new_opts, ensure_ascii=False),
                        len(stmt),
                        r["id"],
                    ),
                )
                if opts_changed:
                    changed_options += 1

        conn.commit()

    return {
        "deleted": deleted,
        "changedStatements": changed_statements,
        "changedOptions": changed_options,
        "fixedArtifacts": fixed_artifacts,
    }


def apply_all_gabaritos() -> dict[str, int]:
    """Aplica gabaritos de todos os anos disponíveis e marca source='oficial'."""
    applied = 0
    updated_source = 0
    years_processed: list[int] = []

    pairs = pair_prova_gabarito()
    with db() as conn:
        for pair in pairs:
            year = pair.get("year")
            if not year:
                continue
            gabarito = pair.get("gabarito")
            if not gabarito:
                continue
            try:
                gab_text = extract_pdf_text(__import__("pathlib").Path(gabarito["path"]))
            except Exception:
                continue
            answers = parse_gabarito(gab_text)
            if not answers:
                continue

            # Buscar questões deste ano
            rows = conn.execute(
                "SELECT id, subject, topic, statement, options_json, correct_index, source, exam_board FROM questions WHERE year=? ORDER BY id",
                (year,),
            ).fetchall()

            year_applied = 0
            for r in rows:
                # Extrair número da questão do ID (paes-YYYY-NNN)
                m = re.search(r"(\d+)$", r["id"] or "")
                if not m:
                    continue
                qnum = int(m.group(1))
                if qnum in answers:
                    new_ci = answers[qnum]
                    if new_ci != int(r["correct_index"] or 0):
                        conn.execute(
                            "UPDATE questions SET correct_index=? WHERE id=?",
                            (new_ci, r["id"]),
                        )
                        applied += 1
                        year_applied += 1
                    # Marcar source='oficial' se for UEMA_PAES
                    if (r["exam_board"] or "") == "UEMA_PAES" and r["source"] != "oficial":
                        conn.execute(
                            "UPDATE questions SET source='oficial' WHERE id=?",
                            (r["id"],),
                        )
                        updated_source += 1

            years_processed.append(year)

        conn.commit()

    return {
        "gabaritoApplied": applied,
        "sourceUpdated": updated_source,
        "yearsProcessed": len(years_processed),
    }


def fix_all() -> dict[str, Any]:
    """Executa diagnóstico + correção + gabarito em sequência."""
    diag_before = diagnose_questions()
    fixes = fix_question_data(delete_unrecoverable=True)
    gabarito = apply_all_gabaritos()
    diag_after = diagnose_questions()

    return {
        "before": diag_before["stats"],
        "fixes": fixes,
        "gabarito": gabarito,
        "after": diag_after["stats"],
        "remainingProblems": len(diag_after["problems"]),
    }


# Type alias para sqlite3.Row (não importável diretamente)
sqlite3_Row_like = Any


if __name__ == "__main__":
    result = fix_all()
    print(json.dumps(result, indent=2, ensure_ascii=False))
