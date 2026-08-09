"""Ingestão de PDF: extrai texto, gera preview de questões, commit após confirmação."""

from __future__ import annotations

import json
import re
import uuid
from pathlib import Path
from typing import Any

from db import DATA_DIR, db
from timeutil import now, now_iso

try:
    from pypdf import PdfReader
except ImportError:  # pragma: no cover
    PdfReader = None  # type: ignore


def ocr_extract_pdf(path: Path) -> str | None:
    """Extrai texto de PDF escaneado quando dependências opcionais existem."""
    try:
        import pytesseract
        from pdf2image import convert_from_path

        pages = convert_from_path(str(path), dpi=220)
        text = "\n".join(pytesseract.image_to_string(page, lang="por") for page in pages).strip()
        return text or None
    except (ImportError, OSError, RuntimeError):
        return None
    except Exception:
        # OCR é melhoria opcional; falhas de binário/idioma não podem derrubar ingestão.
        return None


def extract_pdf_text(path: Path) -> str:
    if PdfReader is None:
        raise RuntimeError("pypdf não instalado. pip install pypdf")
    reader = PdfReader(str(path))
    parts: list[str] = []
    for page in reader.pages:
        parts.append(page.extract_text() or "")
    text = "\n".join(parts).strip()
    if len(text) < 80:
        ocr_text = ocr_extract_pdf(path)
        if ocr_text and len(ocr_text) >= len(text):
            return ocr_text
        return (
            text
            + "\n\n[NEEDS_OCR] Pouco texto extraído — PDF pode ser escaneado. "
            "A leitura automática do PDF não está disponível. Envie o texto revisado."
        )
    return text


AREA_SUBJECT_MAP = (
    (re.compile(r"LINGUAGENS", re.I), "Língua Portuguesa e Literatura"),
    (re.compile(r"CI[EÊ]NCIAS\s+HUMANAS", re.I), "História"),
    (re.compile(r"MATEM[AÁ]TICA", re.I), "Matemática"),
    # Natureza fica como âncora; Bio/Qui/Fis refinados por keywords no item
    (re.compile(r"CI[EÊ]NCIAS\s+DA\s+NATUREZA|NATUREZA\s+E\s+SUAS", re.I), "Ciências da Natureza"),
    (re.compile(r"BIOLOGIA", re.I), "Biologia"),
    (re.compile(r"F[IÍ]SICA", re.I), "Física"),
    (re.compile(r"QU[IÍ]MICA", re.I), "Química"),
    (re.compile(r"GEOGRAFIA", re.I), "Geografia"),
    (re.compile(r"HIST[OÓ]RIA", re.I), "História"),
    (re.compile(r"SOCIOLOGIA", re.I), "Sociologia"),
    (re.compile(r"FILOSOFIA", re.I), "Filosofia"),
)

_EXAM_HEADER_RE = re.compile(
    r"processo\s+seletivo\s+de\s+acesso\s+à\s+educação\s+superior",
    re.IGNORECASE,
)
_PDF_GID_RE = re.compile(r"(?:/gid\d+\s*)+", re.IGNORECASE)
_PDF_ARTIFACT_MARKER = "\ue000"
_HEADER_PAGE_AFTER_ARTIFACT_RE = re.compile(
    rf"{re.escape(_PDF_ARTIFACT_MARKER)}"
    rf"(?:\s+{re.escape(_PDF_ARTIFACT_MARKER)})*"
    r"\s*(?:(?:19|20)\d{2}\s+)?\d{1,3}(?=\s+[A-ZÀ-Ý\"“])"
)


def clean_question_statement(statement: str) -> str:
    """Remove artefatos de cabeçalho do PDF sem tocar nos números do conteúdo."""
    cleaned = statement.replace("\r", " ")
    had_pdf_header = bool(_EXAM_HEADER_RE.search(cleaned) or _PDF_GID_RE.search(cleaned))
    cleaned = _EXAM_HEADER_RE.sub(_PDF_ARTIFACT_MARKER, cleaned)
    cleaned = _PDF_GID_RE.sub(_PDF_ARTIFACT_MARKER, cleaned)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    # O número de página só pode ser removido imediatamente após o artefato.
    if had_pdf_header:
        cleaned = _HEADER_PAGE_AFTER_ARTIFACT_RE.sub("", cleaned)
    cleaned = cleaned.replace(_PDF_ARTIFACT_MARKER, " ")
    return re.sub(r"\s+", " ", cleaned).strip()

NATUREZA_BIO = re.compile(
    r"(?i)\b(c[eé]lula|mitose|meiose|gene|alelo|dna|rna|ecossistema|fotoss[ií]ntese|"
    r"evolu[cç][aã]o|mendel|heredit|prote[ií]na|enzima|v[ií]rus|bact[eé]ria|"
    r"sistema\s+nervoso|horm[oô]nio|ecologia|citologia|mitoc[oô]ndria|ribossomo|"
    r"osmose|membrana|cloroplasto|cadeia\s+alimentar|popula[cç][aã]o|bioma|"
    r"imunolog|vacina|anticorpo|gameta|embri[aã]o|respira[cç][aã]o\s+celular)\b"
)

NATUREZA_QUI = re.compile(
    r"(?i)\b(mol|estequiometr|rea[cç][aã]o|oxid|redu[cç]|[aá]cido|base|ph\b|org[aâ]nica|"
    r"hidrocarboneto|lig[aã]o\s+i[oô]nica|tabela\s+peri[oó]dica|solu[cç][aã]o|"
    r"concentra[cç][aã]o|equilibrio\s+qu[ií]mico|equil[ií]brio\s+qu[ií]mico|"
    r"elemento\s+qu[ií]mico|[aá]tomo|pr[oó]ton|n[eê]utron|el[eé]tron|"
    r"massa\s+molar|isomeria|termoqu[ií]mica|eletroqu[ií]mica)\b"
)
NATUREZA_FIS = re.compile(
    r"(?i)\b(velocidade|acelera[cç][aã]o|for[cç]a|newton|energia|trabalho|pot[eê]ncia|"
    r"ohm|resistor|corrente|tens[aã]o|campo\s+el[eé]trico|ondas?|frequ[eê]ncia|"
    r"cinem[aá]tica|mruv|mru\b|calor|temperatura|press[aã]o|lentes?|espelho|"
    r"gravit|atrito|impulso|campo\s+magn[eé]tico|refr[aã][cç][aã]o|reflex[aã]o|"
    r"joule|watt|f[oó]ton)\b"
)

_OVERRIDEABLE_HUMANS = frozenset({
    "História",
    "Geografia",
    "Filosofia",
    "Sociologia",
    "Geral",
    "Ciências Humanas",
    "A classificar",
})


def _subject_for_offset(text: str, offset: int, default: str) -> str:
    """Último cabeçalho de área antes do offset define a disciplina."""
    head = text[:offset]
    best_pos = -1
    best_subj = default
    for pattern, subject in AREA_SUBJECT_MAP:
        for m in pattern.finditer(head):
            if m.start() >= best_pos:
                best_pos = m.start()
                best_subj = subject
    return best_subj


def refine_natureza_subject(statement: str, options: list[Any], current: str) -> str:
    """Escolhe Bio/Qui/Fis e resgata de dump Humanas quando o texto é Natureza (Ciclo X)."""
    blob = " ".join([statement or "", *[str(o) for o in options or []]])
    scores = {
        "Biologia": len(NATUREZA_BIO.findall(blob)),
        "Química": len(NATUREZA_QUI.findall(blob)),
        "Física": len(NATUREZA_FIS.findall(blob)),
    }
    best = max(scores, key=scores.get)
    nat_hit = scores[best]
    cur = (current or "").strip()
    if cur in ("Ciências da Natureza", "Biologia", "Química", "Física", "", "Geral"):
        if nat_hit <= 0:
            if cur in ("Ciências da Natureza", "Geral", ""):
                return "Biologia"
            return cur or "Biologia"
        return best
    if cur in _OVERRIDEABLE_HUMANS and nat_hit >= 2:
        return best
    return cur or best


def ensure_professor_defaults(q: dict[str, Any]) -> dict[str, Any]:
    """Resolução/macete/pegadinha mínimos para oficiais estudáveis (Ciclo M)."""
    item = dict(q)
    year = item.get("year") or ""
    subject = item.get("subject") or "Geral"
    topic = item.get("topic") or "A classificar"
    idx = int(item.get("correctIndex") or 0)
    letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
    res = (item.get("resolution") or "").strip()
    if not res or res.lower().startswith("revisar gabarito") or res == "—":
        item["resolution"] = (
            f"1) Gabarito oficial: alternativa {letter}.\n"
            f"2) Assunto: {subject} · {topic}.\n"
            f"3) Oficial PAES-{year} — refine a explicação no Modo professor se precisar."
        )
    mac = (item.get("macete") or "").strip()
    if not mac or mac == "—":
        item["macete"] = f"Elimine extremos; foque o comando em {topic}."
    peg = (item.get("pegadinha") or "").strip()
    if not peg or peg == "—":
        item["pegadinha"] = "Distrator clássico: termo trocado ou conclusão além do enunciado."
    if not (item.get("bancaIntent") or "").strip() or item.get("bancaIntent") == "—":
        item["bancaIntent"] = f"Cobrar {topic} no padrão PAES-UEMA ({year})."
    item["examBoard"] = item.get("examBoard") or "UEMA_PAES"
    return item


def _is_suspect_question(q: dict[str, Any]) -> bool:
    conf = float(q.get("parseConfidence") or 0)
    gab_missing = q.get("gabaritoApplied") is not True
    has_placeholder = any("(revisar)" in str(o) for o in (q.get("options") or []))
    topic = (q.get("topic") or "").strip()
    topic_conf = float(q.get("topicConfidence") or 1)
    topic_weak = topic == "A classificar" or topic_conf < 0.3
    return conf < 0.5 or gab_missing or has_placeholder or topic_weak


def compute_year_health(
    questions: list[dict[str, Any]],
    *,
    preview_all: list[dict[str, Any]] | None = None,
    year: int | None = None,
) -> dict[str, Any]:
    """Relatório pós-commit: totais, gabarito %, Natureza Bio/Qui/Fis, suspeitas no preview."""
    from collections import Counter

    total = len(questions)
    gab = sum(1 for q in questions if q.get("gabaritoApplied") is True)
    subjects = Counter((q.get("subject") or "?").strip() or "?" for q in questions)
    natureza = {
        "Biologia": subjects.get("Biologia", 0),
        "Química": subjects.get("Química", 0),
        "Física": subjects.get("Física", 0),
    }
    pool = preview_all if preview_all is not None else questions
    suspects = sum(1 for q in pool if _is_suspect_question(q))
    y = year
    if y is None and questions:
        try:
            y = int(questions[0].get("year") or 0) or None
        except (TypeError, ValueError):
            y = None
    return {
        "year": y,
        "total": total,
        "gabaritoApplied": gab,
        "gabaritoPct": round(100.0 * gab / total, 1) if total else 0.0,
        "subjects": dict(subjects.most_common()),
        "natureza": natureza,
        "suspectsRemaining": suspects,
        "previewCount": len(pool),
    }


def year_health_from_db(year: int) -> dict[str, Any]:
    """Saúde a partir das oficiais já gravadas para um ano."""
    with db() as conn:
        rows = conn.execute(
            """
            SELECT subject, topic, resolution, source, generated, exam_board, correct_index
            FROM questions
            WHERE year=? AND UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES'
            """,
            (year,),
        ).fetchall()
    from collections import Counter

    subjects = Counter((r["subject"] or "?").strip() or "?" for r in rows)
    natureza = {
        "Biologia": subjects.get("Biologia", 0),
        "Química": subjects.get("Química", 0),
        "Física": subjects.get("Física", 0),
    }
    thin = 0
    for r in rows:
        res = (r["resolution"] or "").strip()
        if (
            not res
            or res.lower().startswith("revisar gabarito")
            or ("Oficial PAES-" in res and "refine" in res.lower())
        ):
            thin += 1
    return {
        "year": year,
        "total": len(rows),
        "gabaritoApplied": len(rows),
        "gabaritoPct": 100.0 if rows else 0.0,
        "subjects": dict(subjects.most_common()),
        "natureza": natureza,
        "thinProfessorDrafts": thin,
        "suspectsRemaining": 0,
    }


def heuristic_parse_questions(text: str, default_year: int = 2024, subject: str = "Geral") -> list[dict[str, Any]]:
    """Extrai blocos PAES ``QUESTÃO 01`` (ou ``01.``) e alternativas A–E."""
    normalized = re.sub(r"\r", "", text)
    # Prioridade 0: QUESTÃO NN; prioridade 1: NN. no início de linha + enunciado
    strong_re = re.compile(
        r"(?im)^\s*quest(?:ão|ao)\s*(?:n[ºo°.]?\s*)?(\d{1,3})\b\s*[\.\-:)]*\s*"
    )
    weak_re = re.compile(
        r"(?im)^\s*(\d{1,3})\s*[\.\-:)]+\s+(?=[A-Za-zÀ-ÿ0-9\"'«(\[])"
    )
    by_number: dict[int, tuple[int, re.Match[str]]] = {}
    for match in strong_re.finditer(normalized):
        number = int(match.group(1))
        if 1 <= number <= 90:
            by_number[number] = (0, match)
    for match in weak_re.finditer(normalized):
        number = int(match.group(1))
        if number < 1 or number > 90:
            continue
        # Evita capturar anos isolados / rodapés (ex. 2024.)
        if number >= 1900:
            continue
        prev = by_number.get(number)
        if prev is None or prev[0] > 1:
            by_number[number] = (1, match)
    ordered = sorted(((n, m) for n, (_, m) in by_number.items()), key=lambda x: x[0])
    results: list[dict[str, Any]] = []
    for position, (number, match) in enumerate(ordered):
        end = ordered[position + 1][1].start() if position + 1 < len(ordered) else len(normalized)
        body = normalized[match.end():end].strip()
        # Cortar lixo de rodapé / próxima área no meio
        body = re.split(
            r"(?im)^\s*(?:LINGUAGENS|CI[EÊ]NCIAS\s+HUMANAS|MATEM[AÁ]TICA|PRODU[CÇ][AÃ]O\s+TEXTUAL|"
            r"CI[EÊ]NCIAS\s+DA\s+NATUREZA)\b",
            body,
        )[0].strip()
        # Alternativas: início de linha A)/A. e inline (A)
        option_re = re.compile(
            r"(?:^|\n)\s*(?:([A-E])\s*[\)\.\-:]\s+|\(([A-E])\)\s+)|"
            r"(?<=[\s;])\(([A-E])\)\s+",
            re.IGNORECASE | re.MULTILINE,
        )
        first_by_letter: dict[str, tuple[int, int]] = {}  # letter -> (start, end_marker)
        for om in option_re.finditer(body):
            letter = (om.group(1) or om.group(2) or om.group(3) or "").upper()
            if letter not in "ABCDE" or letter in first_by_letter:
                continue
            first_by_letter[letter] = (om.start(), om.end())
        by_pos = sorted(
            ((start, letter, mend) for letter, (start, mend) in first_by_letter.items()),
            key=lambda x: x[0],
        )
        opts_by_letter: dict[str, str] = {}
        for index, (_start, letter, mend) in enumerate(by_pos):
            option_end = by_pos[index + 1][0] if index + 1 < len(by_pos) else len(body)
            value = re.sub(r"\s+", " ", body[mend:option_end]).strip()
            value = re.sub(r"^[\)\.\-:]\s*", "", value)
            if value:
                opts_by_letter[letter] = value[:800]
        # Sempre A–E em ordem de índice (gabarito A=0)
        opts = [opts_by_letter.get(chr(65 + i), "") for i in range(5)]
        statement = body[: by_pos[0][0]].strip() if by_pos else body
        statement = clean_question_statement(statement)[:1200]
        if not statement:
            continue
        real_opts = sum(1 for o in opts if o and "(revisar)" not in o)
        # Corpo muito curto só vale se há 4+ alternativas
        if len(statement) < 25 and real_opts < 4:
            continue
        confidence = 0.35
        if real_opts >= 5:
            confidence += 0.35
        elif real_opts >= 4:
            confidence += 0.25
        elif real_opts >= 3:
            confidence += 0.12
        if len(statement) >= 80:
            confidence += 0.2
        elif len(statement) >= 40:
            confidence += 0.1
        if real_opts >= 5:
            confidence += 0.1
        if 1 <= number <= 60:
            confidence = min(0.99, confidence + 0.05)
        # QUESTÃO explícita no match
        if re.search(r"(?i)quest", match.group(0) or ""):
            confidence = min(0.99, confidence + 0.05)
        confidence = round(min(0.99, confidence), 2)
        while len(opts) < 5:
            opts.append("")
        opts = [
            (o if o else f"Alternativa {chr(65 + i)} (revisar)") for i, o in enumerate(opts[:5])
        ]
        q_subject = _subject_for_offset(normalized, match.start(), subject)
        if q_subject in ("Ciências da Natureza", "Biologia", "Química", "Física"):
            q_subject = refine_natureza_subject(statement, opts[:5], q_subject)
        results.append(
            {
                "id": f"paes-{default_year}-{number:03d}",
                "number": number,
                "year": default_year,
                "subject": q_subject,
                "topic": "A classificar",
                "subtopic": None,
                "statement": statement,
                "options": opts[:5],
                "correctIndex": 0,
                "difficulty": "Média",
                "resolution": "Revisar gabarito oficial após commit.",
                "bancaIntent": "Questão oficial PAES-UEMA importada de PDF — revisar classificação.",
                "macete": "Confirme disciplina/assunto no edital.",
                "pegadinha": "Parser automático pode cortar enunciado.",
                "relatedTopics": [],
                "keywords": [],
                "source": f"pdf_ingest_{default_year}_{number:03d}",
                "examBoard": "UEMA_PAES",
                "generated": False,
                "parseConfidence": confidence,
            }
        )
        if len(results) >= 90:
            break
    if not results:
        results.append(
            {
                "id": f"ingest-{uuid.uuid4().hex[:10]}",
                "year": default_year,
                "subject": subject,
                "topic": "A classificar",
                "statement": text[:800] or "PDF sem texto útil extraído.",
                "options": ["A", "B", "C", "D", "E"],
                "correctIndex": 0,
                "difficulty": "Média",
                "resolution": "Revise manualmente.",
                "bancaIntent": "Importação incompleta.",
                "macete": "Cole o texto ou use a leitura automática.",
                "pegadinha": "PDF imagem.",
                "relatedTopics": [],
                "keywords": [],
                "source": "pdf_ingest",
                "examBoard": "UEMA_PAES",
                "generated": False,
                "parseConfidence": 0.1,
            }
        )
    return results


def parse_gabarito(text: str) -> dict[int, int]:
    """Lê pares número/letra de gabaritos PAES, retornando índice A=0 ... E=4.

    Questões anuladas (`nula` / `anulada`) são omitidas do mapa.
    """
    answers: dict[int, int] = {}
    patterns = (
        r"(?im)(?:quest(?:ão|ao)\s*)?(\d{1,3})\s*[\-–—.:)\]]+\s*\(?([A-E])\)?\b",
        r"(?im)\b(\d{1,3})\s+([A-E])\b",
        r"(?im)\b(\d{1,2})\s*[)\].:\-–—]*\s*([A-E])\b",
        r"(?im)(?:^|[\s|;,])(\d{1,2})([A-E])(?=[\s|;,]|$)",
    )
    for pattern in patterns:
        for number, letter in re.findall(pattern, text):
            n = int(number)
            if 1 <= n <= 90:
                answers[n] = ord(letter.upper()) - ord("A")
    for m in re.finditer(r"(?im)\b(\d{1,3})\s+(nula|anulad[oa])\b", text):
        answers.pop(int(m.group(1)), None)
    return answers


def apply_gabarito(questions: list[dict[str, Any]], gabarito_map: dict[int, int]) -> list[dict[str, Any]]:
    """Aplica respostas sem alterar a lista recebida."""
    merged: list[dict[str, Any]] = []
    for position, question in enumerate(questions, start=1):
        copy = dict(question)
        number = int(copy.get("number") or position)
        if number in gabarito_map:
            copy["correctIndex"] = gabarito_map[number]
            copy["gabaritoApplied"] = True
        merged.append(copy)
    return merged


def _tokens(value: str) -> set[str]:
    return set(re.findall(r"(?u)\b[\wÀ-ÿ]{3,}\b", (value or "").lower()))


SYLLABUS_SYNONYMS = {
    "genetica": "Genética",
    "genética": "Genética",
    "mendel": "Genética",
    "hereditariedade": "Genética",
    "heredograma": "Genética",
    "alelo": "Genética",
    "citologia": "Citologia",
    "celula": "Citologia",
    "célula": "Citologia",
    "membrana": "Citologia",
    "mitose": "Citologia",
    "meiose": "Citologia",
    "ecossistema": "Ecologia",
    "ecologia": "Ecologia",
    "cadeia": "Ecologia",
    "evolucao": "Evolução",
    "evolução": "Evolução",
    "darwin": "Evolução",
    "estequiometria": "Estequiometria",
    "mol": "Estequiometria",
    "organica": "Química orgânica",
    "orgânica": "Química orgânica",
    "cinematica": "Cinemática",
    "cinemática": "Cinemática",
    "velocidade": "Cinemática",
    "eletrodinamica": "Eletrodinâmica",
    "eletrodinâmica": "Eletrodinâmica",
    "resistor": "Eletrodinâmica",
    "ohm": "Eletrodinâmica",
    "probabilidade": "Probabilidade",
    "funcoes": "Funções",
    "funções": "Funções",
    "exponencial": "Funções",
    "circunferencia": "Geometria analítica",
    "circunferência": "Geometria analítica",
    "interpretacao": "Interpretação de texto",
    "interpretação": "Interpretação de texto",
    "conotacao": "Interpretação de texto",
    "conotação": "Interpretação de texto",
    "coesao": "Coesão e coerência",
    "coesão": "Coesão e coerência",
    "romantismo": "Literatura",
    "vargas": "Brasil República",
    "semiarido": "Brasil contemporâneo",
    "semiárido": "Brasil contemporâneo",
    "socializacao": "Cultura e sociedade",
    "socialização": "Cultura e sociedade",
}


def classify_questions_by_syllabus(questions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Classifica por sobreposição de palavras com os tópicos cadastrados no edital.

    Preserva subject vindo do cabeçalho de área do caderno quando o score de syllabus é fraco.
    """
    with db() as conn:
        syllabus = [dict(row) for row in conn.execute(
            "SELECT id, subject, topic, subtopic, weight FROM syllabus"
        ).fetchall()]

    classified: list[dict[str, Any]] = []
    for question in questions:
        item = dict(question)
        prior_subject = (item.get("subject") or "").strip()
        if prior_subject in (
            "Ciências da Natureza",
            "Biologia",
            "Química",
            "Física",
            "",
            "Geral",
            "História",
            "Geografia",
            "Filosofia",
            "Sociologia",
            "A classificar",
        ):
            prior_subject = refine_natureza_subject(
                str(item.get("statement") or ""),
                list(item.get("options") or []),
                prior_subject or "Ciências da Natureza",
            )
            item["subject"] = prior_subject
        text = " ".join([str(item.get("statement") or ""), *map(str, item.get("options") or [])])
        question_tokens = _tokens(text)
        inferred_topics = {SYLLABUS_SYNONYMS[token] for token in question_tokens if token in SYLLABUS_SYNONYMS}
        best_score = 0
        best_match: dict[str, Any] | None = None
        for entry in syllabus:
            keywords = _tokens(" ".join(
                [entry["subject"], entry["topic"], entry.get("subtopic") or ""]
            ))
            score = len(question_tokens & keywords) + (4 if entry["topic"] in inferred_topics else 0)
            # leve bônus se subject da área bate com syllabus
            if prior_subject and prior_subject == entry["subject"]:
                score += 1
            if prior_subject in ("Biologia", "Química", "Física") and entry["subject"] == "História":
                score = max(0, score - 3)
            # Ciclo Y: bloqueio cross-domain forte
            if prior_subject in ("Biologia", "Química", "Física") and entry["subject"] in (
                "História",
                "Geografia",
                "Filosofia",
                "Sociologia",
                "Língua Portuguesa e Literatura",
                "Linguagens",
            ):
                score = max(0, score - 8)
            if prior_subject in ("Biologia", "Química", "Física") and entry["subject"] not in (
                "Biologia",
                "Química",
                "Física",
            ):
                score = max(0, score - 2)
            if score > best_score:
                best_score, best_match = score, entry
        if best_match and best_score >= 2:
            # score forte: usa syllabus completo
            if not prior_subject or prior_subject in ("Geral", "A classificar") or best_score >= 4:
                if not (
                    prior_subject in ("Biologia", "Química", "Física")
                    and best_match["subject"]
                    in (
                        "História",
                        "Geografia",
                        "Filosofia",
                        "Sociologia",
                        "Língua Portuguesa e Literatura",
                        "Linguagens",
                    )
                ):
                    item["subject"] = best_match["subject"]
            # não copiar tópico Humanas para item Natureza
            if prior_subject in ("Biologia", "Química", "Física") and best_match["subject"] not in (
                "Biologia",
                "Química",
                "Física",
            ):
                if not item.get("topic") or item.get("topic") == "A classificar":
                    item["topic"] = f"Conceitos de {prior_subject}"
                item["topicConfidence"] = 0.2
            else:
                item["topic"] = best_match["topic"]
                item["subtopic"] = best_match.get("subtopic")
                item["syllabusId"] = best_match["id"]
                item["topicConfidence"] = round(min(0.99, 0.35 + best_score * 0.12), 2)
        elif best_match:
            natureza = ("Biologia", "Química", "Física")
            humanas_ling = (
                "História",
                "Geografia",
                "Filosofia",
                "Sociologia",
                "Língua Portuguesa e Literatura",
                "Linguagens",
            )
            # Ciclo Y: nunca colar tópico Humanas/Linguagens em item Natureza (score fraco)
            if prior_subject in natureza and best_match["subject"] in humanas_ling:
                if not item.get("topic") or item.get("topic") == "A classificar":
                    item["topic"] = f"Conceitos de {prior_subject}"
                item["topicConfidence"] = 0.18
            else:
                item["topic"] = best_match["topic"]
                item["subtopic"] = best_match.get("subtopic")
                item["syllabusId"] = best_match["id"]
                item["topicConfidence"] = 0.28
                if not prior_subject or prior_subject in ("Geral",):
                    item["subject"] = best_match["subject"]
        else:
            if not item.get("topic") or item.get("topic") == "A classificar":
                item["topic"] = "A classificar"
            item["topicConfidence"] = 0.12
        # Pós: se subject Natureza ficou com tópico de outro domínio, force tópico neutro
        subj_final = (item.get("subject") or "").strip()
        topic_final = (item.get("topic") or "").strip()
        if subj_final in ("Biologia", "Química", "Física"):
            tl = topic_final.lower()
            if any(
                bad in tl
                for bad in (
                    "literatura",
                    "romantismo",
                    "história",
                    "historia",
                    "geografia",
                    "filosofia",
                    "sociologia",
                    "vargas",
                    "feudalismo",
                )
            ):
                item["topic"] = f"Conceitos de {subj_final}"
                item["topicConfidence"] = min(float(item.get("topicConfidence") or 0.2), 0.25)
        classified.append(item)
    return classified


def _year_from_filename(filename: str) -> int | None:
    # Underscore is \w in Python — \b fails on paes_2024.pdf; match year bare.
    match = re.search(r"(19\d{2}|20\d{2})", filename)
    return int(match.group(1)) if match else None


def list_pdf_inventory() -> list[dict[str, Any]]:
    """Lista PDFs colocados manualmente nas pastas oficiais de dados."""
    folders = {"provas": "prova", "gabaritos": "gabarito", "edital": "edital"}
    inventory: list[dict[str, Any]] = []
    for folder, kind in folders.items():
        root = DATA_DIR / folder
        if not root.exists():
            continue
        for path in sorted(root.glob("*.pdf")):
            inventory.append(
                {
                    "filename": path.name,
                    "year": _year_from_filename(path.name),
                    "kind": kind,
                    "path": str(path),
                    "size": path.stat().st_size,
                }
            )
    return inventory


def _prefer_canonical_prova(year: int, items: list[dict[str, Any]]) -> dict[str, Any] | None:
    """Prefere paes_YYYY.pdf; senão o primeiro nome estável (evita etapa2 sobrescrever)."""
    if not items:
        return None
    canonical = f"paes_{year}.pdf".lower()
    for item in items:
        if str(item.get("filename") or "").lower() == canonical:
            return item
    return sorted(items, key=lambda x: str(x.get("filename") or "").lower())[0]


def pair_prova_gabarito(inventory: list[dict[str, Any]] | None = None) -> list[dict[str, Any]]:
    inventory = inventory if inventory is not None else list_pdf_inventory()
    grouped: dict[int, dict[str, Any]] = {}
    for item in inventory:
        year = item.get("year")
        if year is None or item["kind"] not in {"prova", "gabarito"}:
            continue
        g = grouped.setdefault(
            year,
            {"year": year, "prova": None, "gabarito": None, "provas": []},
        )
        if item["kind"] == "prova":
            g["provas"].append(item)
        else:
            g["gabarito"] = item
    for year, g in grouped.items():
        g["provas"] = sorted(g["provas"], key=lambda x: str(x.get("filename") or "").lower())
        g["prova"] = _prefer_canonical_prova(year, g["provas"])
        g["extraProvas"] = [p for p in g["provas"] if p is not g["prova"]]
    return [grouped[year] for year in sorted(grouped)]


def compute_year_statuses() -> list[dict[str, Any]]:
    """Situação 2014–2026, derivada de arquivos e questões oficiais no SQLite."""
    inventory = list_pdf_inventory()
    years = range(2014, 2027)
    provas = {item["year"] for item in inventory if item["kind"] == "prova" and item.get("year") in years}
    gabaritos = {item["year"] for item in inventory if item["kind"] == "gabarito" and item.get("year") in years}
    prova_files: dict[int, int] = {}
    for item in inventory:
        y = item.get("year")
        if item["kind"] == "prova" and y in years:
            prova_files[y] = prova_files.get(y, 0) + 1
    with db() as conn:
        rows = conn.execute(
            """SELECT year, source, generated, COUNT(*) AS count FROM questions
               WHERE year BETWEEN 2014 AND 2026 GROUP BY year, source, generated"""
        ).fetchall()
    official_counts: dict[int, int] = {}
    for row in rows:
        source = (row["source"] or "").lower()
        if not row["generated"] and any(tag in source for tag in ("pdf", "oficial", "ingest")):
            official_counts[row["year"]] = official_counts.get(row["year"], 0) + int(row["count"])
    result = []
    for year in years:
        has_prova, has_gabarito = year in provas, year in gabaritos
        count = official_counts.get(year, 0)
        if count > 0:
            status = "commitado"
        elif has_prova and has_gabarito:
            status = "parseado"
        elif has_prova or has_gabarito:
            status = "parcial"
        else:
            status = "faltando"
        result.append(
            {
                "year": year,
                "status": status,
                "hasProva": has_prova,
                "hasGabarito": has_gabarito,
                "provaFileCount": prova_files.get(year, 0),
                "officialQuestionCount": count,
                "officialCount": count,
            }
        )
    return result


def import_year_pair(year: int, *, include_extra_provas: bool = True) -> dict[str, Any]:
    """Monta preview de uma prova anual e aplica o gabarito disponível.

    Com várias provas do mesmo ano (ex.: 2021 etapa 1 + 2), mescla cadernos:
    gabarito (se houver) aplica só nos números originais da etapa canônica;
    etapas extras vêm a seguir (números + offset) e ficam sem gabarito até revisão.
    """
    pair = next((item for item in pair_prova_gabarito() if item["year"] == year), None)
    if not pair or not pair.get("prova"):
        raise ValueError(f"Prova de {year} não encontrada nas pastas de dados.")
    prova_items: list[dict[str, Any]] = []
    if include_extra_provas and pair.get("provas"):
        # canônica primeiro, depois extras
        primary = pair["prova"]
        extras = [p for p in pair.get("provas") or [] if p.get("path") != primary.get("path")]
        prova_items = [primary, *extras]
    else:
        prova_items = [pair["prova"]]

    answers: dict[int, int] = {}
    gabarito_ocr = False
    if pair.get("gabarito"):
        gab_text = extract_pdf_text(Path(pair["gabarito"]["path"]))
        gabarito_ocr = "[NEEDS_OCR]" in gab_text
        answers = parse_gabarito(gab_text)

    questions: list[dict[str, Any]] = []
    needs_ocr = False
    ocr_failed = False
    raw_chunks: list[str] = []
    number_offset = 0
    files_used: list[str] = []
    for stage_i, prova in enumerate(prova_items):
        raw_text = extract_pdf_text(Path(prova["path"]))
        raw_chunks.append(f"--- {prova.get('filename')} ---\n{raw_text}")
        stage_needs = "[NEEDS_OCR]" in raw_text
        needs_ocr = needs_ocr or stage_needs
        ocr_failed = ocr_failed or (stage_needs and "Instale pytesseract" in raw_text)
        stage_qs = heuristic_parse_questions(raw_text, default_year=year)
        for q in stage_qs:
            q["source"] = f"pdf_ingest:{prova.get('filename')}"
            q["examBoard"] = "UEMA_PAES"
            if stage_i == 0:
                continue
            # Etapas extra: desloca número para não colidir; gabarito oficial não se aplica
            n = int(q.get("number") or 0)
            if n > 0 and number_offset > 0:
                q["number"] = n + number_offset
            q["similarityNote"] = f"Caderno extra ({prova.get('filename')}) — revisar gabarito."
        if stage_i == 0 and answers:
            stage_qs = apply_gabarito(stage_qs, answers)
        questions.extend(stage_qs)
        files_used.append(str(prova.get("filename") or ""))
        max_n = 0
        for q in stage_qs:
            try:
                max_n = max(max_n, int(q.get("number") or 0))
            except (TypeError, ValueError):
                pass
        number_offset = max(number_offset, max_n)

    questions = classify_questions_by_syllabus(questions)
    q_numbers = {int(q.get("number") or i) for i, q in enumerate(questions, start=1)}
    a_numbers = set(answers.keys())
    pair_validation = {
        "questionsParsed": len(questions),
        "gabaritoAnswers": len(answers),
        "matched": len(q_numbers & a_numbers),
        "unmatchedQuestions": sorted(q_numbers - a_numbers)[:20],
        "unmatchedAnswers": sorted(a_numbers - q_numbers)[:20],
        "files": files_used,
        "ok": (not answers) or (len(q_numbers & a_numbers) >= max(1, int(0.5 * min(len(q_numbers), max(1, len(a_numbers)))))),
        "message": (
            "Par prova↔gabarito inconsistente — revise gabaritos antes do commit."
            if answers and len(q_numbers & a_numbers) < max(1, int(0.5 * min(len(q_numbers), max(1, len(a_numbers)))))
            else (
                "Gabarito aplicado (etapa canônica)."
                if answers
                else "Sem gabarito no acervo para este ano — revise respostas antes de estudiar."
            )
        ),
    }
    avg_conf = (
        round(sum(float(q.get("parseConfidence") or 0) for q in questions) / len(questions), 2)
        if questions
        else 0
    )
    primary_name = str(pair["prova"].get("filename") or f"paes_{year}.pdf")
    preview = save_preview("prova", primary_name, questions, "\n\n".join(raw_chunks)[:50000])
    preview["year"] = year
    preview["needsOcr"] = needs_ocr or gabarito_ocr
    preview["ocrFailed"] = ocr_failed
    preview["ok"] = True
    preview["pairValidation"] = pair_validation
    preview["avgParseConfidence"] = avg_conf
    preview["gabaritoApplied"] = sum(1 for question in questions if question.get("gabaritoApplied"))
    preview["answersFound"] = len(answers)
    preview["gabaritoAnswers"] = len(answers)
    preview["files"] = files_used
    preview["classified"] = sum(1 for q in questions if (q.get("topic") or "") != "A classificar")
    preview["message"] = (
        f"Preview {year}: {len(questions)} questões · {len(files_used)} PDF(s) · confiança média {avg_conf}"
        + (" — PDF parece escaneado (leitura automática recomendada)." if needs_ocr or gabarito_ocr else "")
        + (" — leitura automática não disponível ou falhou." if ocr_failed else "")
        + (" — sem gabarito no disco." if not answers else "")
    )
    return preview


def import_and_commit_year(year: int) -> dict[str, Any]:
    """Importa e grava uma prova anual (high-conf + gabarito obrigatório)."""
    from services_extra import create_backup

    backup = create_backup()
    preview = import_year_pair(year)
    if int(preview.get("gabaritoApplied") or 0) <= 0:
        return {
            **preview,
            "backup": backup,
            "commit": {
                "ok": False,
                "message": (
                    f"Cole gabarito_{year}.pdf em data/gabaritos e reimporte. "
                    "Sem gabarito não gravamos oficiais (evita respostas inventadas)."
                ),
            },
            "rag": None,
        }
    committed = commit_preview(
        preview["previewId"],
        preview.get("questions"),
        high_confidence_only=True,
        allow_without_gabarito=False,
    )
    rag = None
    try:
        from services_advanced import index_all_questions

        rag = index_all_questions()
    except Exception as exc:  # pragma: no cover
        rag = {"ok": False, "error": str(exc)}
    return {**preview, "backup": backup, "commit": committed, "rag": rag}


def save_preview(kind: str, filename: str, questions: list[dict[str, Any]], raw_text: str) -> dict[str, Any]:
    preview_id = str(uuid.uuid4())
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS ingest_previews (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                filename TEXT NOT NULL,
                questions_json TEXT NOT NULL,
                raw_text TEXT,
                created_at TEXT NOT NULL,
                committed INTEGER DEFAULT 0
            )
            """
        )
        conn.execute(
            """
            INSERT INTO ingest_previews (id, kind, filename, questions_json, raw_text, created_at, committed)
            VALUES (?, ?, ?, ?, ?, ?, 0)
            """,
            (
                preview_id,
                kind,
                filename,
                json.dumps(questions, ensure_ascii=False),
                raw_text[:50000],
                now_iso(),
            ),
        )
        conn.execute(
            """
            INSERT INTO ingest_jobs (filename, kind, status, message, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                filename,
                kind,
                "preview_pronto",
                f"Preview {preview_id} com {len(questions)} questões candidatas. Confirme para gravar.",
                now_iso(),
            ),
        )
        conn.commit()
    return {
        "previewId": preview_id,
        "count": len(questions),
        "questions": questions,
        "message": "Revise o preview e chame /api/ingest/commit para gravar no banco.",
    }


def commit_preview(
    preview_id: str,
    questions_override: list[dict[str, Any]] | None = None,
    *,
    high_confidence_only: bool = False,
    min_confidence: float = 0.55,
    allow_without_gabarito: bool = False,
) -> dict[str, Any]:
    with db() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS ingest_previews (
                id TEXT PRIMARY KEY,
                kind TEXT NOT NULL,
                filename TEXT NOT NULL,
                questions_json TEXT NOT NULL,
                raw_text TEXT,
                created_at TEXT NOT NULL,
                committed INTEGER DEFAULT 0
            )
            """
        )
        row = conn.execute("SELECT * FROM ingest_previews WHERE id=?", (preview_id,)).fetchone()
        if not row:
            return {"ok": False, "message": "Preview não encontrado"}
        if row["committed"]:
            return {"ok": False, "message": "Preview já commitado"}
        questions = questions_override if questions_override is not None else json.loads(row["questions_json"])
        skipped = 0
        gabarito_applied = 0
        year_for_gab: int | None = None
        if row["kind"] == "prova" and questions:
            year_for_gab = int(questions[0].get("year", 0))
            gabaritos = [
                item for item in list_pdf_inventory()
                if item["kind"] == "gabarito" and item.get("year") == year_for_gab
            ]
            if gabaritos:
                answers = parse_gabarito(extract_pdf_text(Path(gabaritos[-1]["path"])))
                questions = apply_gabarito(questions, answers)
            gabarito_applied = sum(1 for question in questions if question.get("gabaritoApplied"))
            questions = classify_questions_by_syllabus(questions)
            if not allow_without_gabarito and gabarito_applied <= 0:
                return {
                    "ok": False,
                    "message": (
                        f"Cole gabarito_{year_for_gab}.pdf em data/gabaritos e reimporte. "
                        "Sem gabarito não gravamos oficiais (evita respostas inventadas)."
                    ),
                    "needsGabarito": True,
                    "year": year_for_gab,
                    "skipped": 0,
                }
        if high_confidence_only:
            kept: list[dict[str, Any]] = []
            for q in questions:
                conf = float(q.get("parseConfidence") or 0)
                gab_ok = q.get("gabaritoApplied") is True
                placeholder = any("(revisar)" in str(o) for o in (q.get("options") or []))
                if conf >= min_confidence and gab_ok and not placeholder:
                    kept.append(q)
                else:
                    skipped += 1
            questions = kept
            if not questions:
                return {
                    "ok": False,
                    "message": (
                        "Nenhuma questão em alta confiança com gabarito aplicado. "
                        "Cole gabarito_YYYY.pdf e reimporte, ou marque respostas na revisão."
                    ),
                    "skipped": skipped,
                    "needsGabarito": gabarito_applied <= 0,
                    "year": year_for_gab,
                }
        inserted = 0
        for raw in questions:
            q = ensure_professor_defaults(raw)
            conn.execute(
                """
                INSERT OR REPLACE INTO questions (
                    id, year, subject, topic, subtopic, statement, options_json, correct_index,
                    difficulty, tags_json, source, resolution, banca_intent, macete, pegadinha,
                    related_topics_json, keywords_json, avg_text_len, generated, approved,
                    exam_board, similarity_of, similarity_note
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, '[]', ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?, ?)
                """,
                (
                    q["id"],
                    q.get("year", 2024),
                    q.get("subject", "Geral"),
                    q.get("topic", "A classificar"),
                    q.get("subtopic"),
                    q["statement"],
                    json.dumps(q.get("options", []), ensure_ascii=False),
                    int(q.get("correctIndex", 0)),
                    q.get("difficulty", "Média"),
                    q.get("source", "pdf_ingest"),
                    q.get("resolution"),
                    q.get("bancaIntent"),
                    q.get("macete"),
                    q.get("pegadinha"),
                    json.dumps(q.get("relatedTopics", []), ensure_ascii=False),
                    json.dumps(q.get("keywords", []), ensure_ascii=False),
                    len(q.get("statement", "")),
                    q.get("examBoard") or "UEMA_PAES",
                    q.get("similarityOf"),
                    q.get("similarityNote"),
                ),
            )
            inserted += 1
        if questions_override is not None or high_confidence_only:
            # Mantém preview com lista completa se veio override; se high-conf, marca commit parcial
            store = questions_override if questions_override is not None else json.loads(row["questions_json"])
            conn.execute(
                "UPDATE ingest_previews SET questions_json=? WHERE id=?",
                (json.dumps(store, ensure_ascii=False), preview_id),
            )
        # Commit parcial (altas confianças) não fecha o preview para permitir 2ª passada
        if not high_confidence_only:
            conn.execute("UPDATE ingest_previews SET committed=1 WHERE id=?", (preview_id,))
        conn.execute(
            """
            INSERT INTO ingest_jobs (filename, kind, status, message, created_at)
            VALUES (?, ?, 'commitado', ?, ?)
            """,
            (
                row["filename"],
                row["kind"],
                f"{inserted} questões gravadas"
                + (f" · {skipped} deixadas de fora (baixa confiança)." if skipped else ".")
                + " Estatísticas recalculam na leitura.",
                now_iso(),
            ),
        )
        conn.commit()
        from services_core import stats_basis

        basis = stats_basis()
        # Saúde do ano (Ciclo N): usa commitadas + preview completo para suspeitas restantes
        all_preview = (
            questions_override
            if questions_override is not None
            else json.loads(row["questions_json"])
        )
        year_val = int(questions[0].get("year", 0)) if questions else None
        health = compute_year_health(questions, preview_all=all_preview, year=year_val)
        return {
            "ok": True,
            "inserted": inserted,
            "skipped": skipped,
            "previewId": preview_id,
            "gabaritoApplied": gabarito_applied,
            "highConfidenceOnly": high_confidence_only,
            "officialCount": basis.get("officialCount", 0),
            "basis": basis.get("basis"),
            "year": year_val,
            "yearHealth": health,
            "sessionPath": f"/sessao?examBoard=UEMA_PAES&year={year_val}" if year_val else "/sessao?examBoard=UEMA_PAES",
            "message": (
                f"{inserted} oficiais UEMA_PAES gravadas"
                + (f" ({skipped} fora)." if skipped else ".")
            ),
        }


def update_preview(preview_id: str, questions: list[dict[str, Any]]) -> dict[str, Any]:
    with db() as conn:
        row = conn.execute("SELECT * FROM ingest_previews WHERE id=?", (preview_id,)).fetchone()
        if not row:
            return {"ok": False, "message": "Preview não encontrado"}
        if row["committed"]:
            return {"ok": False, "message": "Preview já commitado"}
        conn.execute(
            "UPDATE ingest_previews SET questions_json=? WHERE id=?",
            (json.dumps(questions, ensure_ascii=False), preview_id),
        )
        conn.commit()
        return {"ok": True, "count": len(questions), "previewId": preview_id}


def get_preview(preview_id: str) -> dict[str, Any] | None:
    with db() as conn:
        row = conn.execute("SELECT * FROM ingest_previews WHERE id=?", (preview_id,)).fetchone()
        if not row:
            return None
        return {
            "previewId": row["id"],
            "kind": row["kind"],
            "filename": row["filename"],
            "count": len(json.loads(row["questions_json"])),
            "questions": json.loads(row["questions_json"]),
            "committed": bool(row["committed"]),
        }


def parse_pdf_file(path: Path, kind: str, year: int | None = None, subject: str = "Geral") -> dict[str, Any]:
    text = extract_pdf_text(path)
    needs_ocr = "[NEEDS_OCR]" in text
    if kind == "gabarito":
        preview = save_preview(kind, path.name, [], text)
        preview.update({"gabarito": parse_gabarito(text), "message": "Gabarito lido. Use /api/ingest/apply-gabarito para aplicar às questões oficiais."})
        preview["needsOcr"] = needs_ocr
        return preview
    questions = heuristic_parse_questions(text, default_year=year or now().year, subject=subject)
    if kind == "prova":
        questions = classify_questions_by_syllabus(questions)
    preview = save_preview(kind, path.name, questions, text)
    preview["needsOcr"] = needs_ocr
    return preview


def sanitize_question_statements() -> int:
    """Limpa enunciados persistidos e retorna quantos registros mudaram."""
    changed = 0
    with db() as conn:
        rows = conn.execute("SELECT id, statement FROM questions").fetchall()
        for row in rows:
            original = str(row["statement"] or "")
            cleaned = clean_question_statement(original)
            if cleaned != original:
                conn.execute(
                    "UPDATE questions SET statement=? WHERE id=?",
                    (cleaned, row["id"]),
                )
                changed += 1
        conn.commit()
    return changed
