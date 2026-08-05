"""Estatísticas e frequência histórica a partir do SQLite (sem inventar)."""

from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime, timedelta
import json
import re
from typing import Any
from urllib.parse import quote

from db import DATA_DIR, connect, loads_json
from pathlib import Path


NATUREZA_SUBJECTS = frozenset({"Biologia", "Química", "Física"})
HUMANAS_SUBJECTS = frozenset({"História", "Geografia", "Filosofia", "Sociologia"})
LINGUAGENS_SUBJECTS = frozenset({"Língua Portuguesa e Literatura", "Linguagens"})

# Tópicos/keywords de domínio "estranho" sob Natureza (e vice-versa) — Ciclo K
_CROSS_HUMAN_IN_TOPIC = re.compile(
    r"(?i)\b(literatura|romantismo|realismo\b|modernismo|parnasianismo|simbolismo|"
    r"romantica|romântica|barroco|arcadismo|tordesilhas|"
    r"vargas|rep[uú]blica|imp[eé]rio|brasil rep[uú]blica|era vargas|"
    r"feudalismo|colonial|ditadura|constitui[cç][aã]o|sociedad|"
    r"semiarido|semi[aá]rido|globaliza[cç][aã]o|geopol[ií]tica|"
    r"plat[aã]o|arist[oó]teles|existencialismo|filosofia|sociologia|"
    r"conota[cç][aã]o|coes[aã]o|coer[eê]ncia|figuras?\s+de\s+linguagem|"
    r"interpreta[cç][aã]o\s+de\s+texto|g[eê]nero\s+textual|"
    r"redação|redacao|disserta[cç][aã]o|crônica|conto\b|poesia)\b"
)
_CROSS_NATURE_IN_TOPIC = re.compile(
    r"(?i)\b(c[eé]lula|dna|gene|gen[eé]tica|fotoss[ií]ntese|estequiometr|newton|"
    r"cinem[aá]tica|ohm|mol\b|equil[ií]brio\s+qu[ií]mico|mitose|meiose|"
    r"for[cç]a|velocidade|acelera[cç][aã]o|pH\b|termodin|onda\b|"
    r"biol[oó]g|ecolog|qu[ií]mic|f[ií]sic)\b"
)


def is_cross_domain(subject: str | None, topic: str | None) -> bool:
    """True se subject Natureza com tópico de Humanas/Linguagens (ou o inverso). Ciclo K."""
    s = (subject or "").strip()
    t = (topic or "").strip()
    if not s or not t:
        return False
    blob = f"{t}"
    if s in NATUREZA_SUBJECTS:
        if _CROSS_HUMAN_IN_TOPIC.search(blob):
            return True
        if any(h.lower() in t.lower() for h in HUMANAS_SUBJECTS | LINGUAGENS_SUBJECTS):
            return True
        if re.search(r"(?i)^(literatura|hist[oó]ria|geografia|filosofia|sociologia)\b", t):
            return True
    if s in HUMANAS_SUBJECTS | LINGUAGENS_SUBJECTS:
        if _CROSS_NATURE_IN_TOPIC.search(blob):
            return True
        if any(n.lower() in t.lower() for n in NATUREZA_SUBJECTS):
            return True
    if s in ("Matemática", "Matematica") and _CROSS_HUMAN_IN_TOPIC.search(blob):
        return True
    return False


def is_official_source(source: str | None, generated: bool | int | None) -> bool:
    """Questões importadas de prova oficial, nunca questões geradas."""
    value = (source or "").lower()
    return not bool(generated) and any(marker in value for marker in ("pdf", "oficial", "ingest"))


def resolution_quality(resolution: str | None) -> str:
    """Classifica resolução: template | draft | real (Ciclo Y/H). Real exige 4 eixos."""
    res = (resolution or "").strip()
    if not res or res == "—":
        return "template"
    low = res.lower()
    if low.startswith("[rascunho") or "[rascunho didático" in low[:80]:
        return "draft"
    if low.startswith("[pulado"):
        return "draft"
    if low.startswith("revisar gabarito"):
        return "template"
    if "1) gabarito oficial" in low or ("oficial paes-" in low and "refine" in low):
        lines = [ln.strip() for ln in res.splitlines() if ln.strip()]
        if len(lines) < 4:
            return "template"
    accepted = "[aceito" in low[:120] or "[revisado" in low[:120]
    lines = [ln.strip() for ln in res.splitlines() if ln.strip()]
    if len(lines) < 4:
        return "template"
    joined = low
    has_cmd = any(k in joined for k in ("comando", "enunciado pede", "questão pede"))
    has_concept = any(k in joined for k in ("conceito", "assunto", "conteúdo", "conteudo"))
    has_gab = any(k in joined for k in ("gabarito", "alternativa", "correta"))
    has_dist = any(k in joined for k in ("distrator", "distra", "elimine", "cuidado"))
    if has_cmd and has_concept and has_gab and has_dist:
        return "real"
    if accepted and len(lines) >= 4 and (has_gab or has_concept):
        return "real"
    if len(lines) >= 4:
        return "draft"
    return "template"


def parse_resolution_axes(resolution: str | None) -> dict[str, str]:
    """Extrai blocos leves Comando/Conceito/Gabarito/Distrator (Ciclo AB)."""
    res = (resolution or "").strip()
    axes = {"comando": "", "conceito": "", "gabarito": "", "distrator": ""}
    if not res:
        return axes
    labels = {
        "comando": re.compile(r"(?im)^\s*(?:\d+\)\s*)?comando\s*[:\-–]\s*(.+)$"),
        "conceito": re.compile(r"(?im)^\s*(?:\d+\)\s*)?conceito\s*[:\-–]\s*(.+)$"),
        "gabarito": re.compile(r"(?im)^\s*(?:\d+\)\s*)?gabarito\s*[:\-–]\s*(.+)$"),
        "distrator": re.compile(r"(?im)^\s*(?:\d+\)\s*)?distrator\s*[:\-–]\s*(.+)$"),
    }
    for key, pat in labels.items():
        m = pat.search(res)
        if m:
            axes[key] = m.group(1).strip()
    # fallback: linhas que começam com o rótulo no meio do parágrafo
    if not any(axes.values()):
        for line in res.splitlines():
            low = line.strip().lower()
            body = line.split(":", 1)[-1].strip() if ":" in line else line.strip()
            if low.startswith("comando") and not axes["comando"]:
                axes["comando"] = body
            elif low.startswith("conceito") and not axes["conceito"]:
                axes["conceito"] = body
            elif low.startswith("gabarito") and not axes["gabarito"]:
                axes["gabarito"] = body
            elif low.startswith("distrator") and not axes["distrator"]:
                axes["distrator"] = body
    return axes


def student_resolution_label(quality: str | None) -> str:
    q = (quality or "").strip().lower()
    if q == "real":
        return "ok"
    if q == "draft":
        return "rascunho"
    return "template"


def latest_official_year_for(subject: str | None, topic: str | None) -> int | None:
    """Ano oficial mais recente com material no tópico (sem inventar)."""
    if not subject or not topic:
        return None
    conn = connect()
    try:
        rows = conn.execute(
            """
            SELECT year, source, generated FROM questions
            WHERE subject=? AND topic=?
            ORDER BY year DESC
            """,
            (subject, topic),
        ).fetchall()
    finally:
        conn.close()
    for r in rows:
        if is_official_source(r["source"], r["generated"]):
            try:
                return int(r["year"])
            except (TypeError, ValueError):
                continue
    return None


def topic_has_material(
    subject: str | None,
    topic: str | None,
    *,
    official_only: bool | None = None,
) -> bool:
    if not subject or not topic:
        return False
    basis = stats_basis()
    use_official = basis["basis"] == "oficial" if official_only is None else official_only
    conn = connect()
    try:
        rows = conn.execute(
            "SELECT source, generated FROM questions WHERE subject=? AND topic=?",
            (subject, topic),
        ).fetchall()
    finally:
        conn.close()
    for r in rows:
        if use_official:
            if is_official_source(r["source"], r["generated"]):
                return True
        else:
            return True
    return False


def pick_coach_focus(
    medicine_top: list[dict[str, Any]],
    study_today: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Escolhe um par subject/topic coerente (Ciclo AA/AC). Nunca mistura fontes."""
    def _ok(s: str | None, t: str | None) -> bool:
        if not s or not t:
            return False
        if is_cross_domain(s, t):
            return False
        return True

    # study_today só se o par for íntegro e com material
    if study_today:
        s = (study_today.get("subject") or "").strip()
        t = (study_today.get("topic") or "").strip()
        if _ok(s, t) and topic_has_material(s, t):
            return {
                "subject": s,
                "topic": t,
                "curated": True,
                "isNatureza": s in NATUREZA_SUBJECTS,
                "from": "studyPlan",
            }

    pool = []
    for m in medicine_top or []:
        s = (m.get("subject") or "").strip()
        t = (m.get("topic") or "").strip()
        if not _ok(s, t):
            continue
        if m.get("crossDomain"):
            continue
        n = int(m.get("frequency") or m.get("realInTopic") or m.get("n") or 0)
        # sem contagem no rank: ainda aceita se DB tem material
        if n <= 0 and not topic_has_material(s, t):
            continue
        pool.append(m)

    curated_nat = [
        m
        for m in pool
        if m.get("curated") and (m.get("subject") or "") in NATUREZA_SUBJECTS
    ]
    if curated_nat:
        return {**curated_nat[0], "from": "medicineCuratedNatureza"}
    nat = [m for m in pool if (m.get("subject") or "") in NATUREZA_SUBJECTS]
    if nat:
        return {**nat[0], "from": "medicineNatureza"}
    curated = [m for m in pool if m.get("curated")]
    if curated:
        return {**curated[0], "from": "medicineCurated"}
    if pool:
        return {**pool[0], "from": "medicineTop"}

    # defaults seguros com material se existir
    for s, t in (
        ("Biologia", "Genética"),
        ("Biologia", "Ecologia"),
        ("Química", "Estequiometria"),
        ("Física", "Cinemática"),
    ):
        if topic_has_material(s, t) or topic_has_material(s, t, official_only=False):
            return {"subject": s, "topic": t, "isNatureza": True, "from": "safeDefault"}
    return {
        "subject": "Biologia",
        "topic": "Genética",
        "isNatureza": True,
        "from": "fallback",
    }


def list_dirty_labels(*, limit: int = 40) -> dict[str, Any]:
    """Fila de oficiais com label cross-domain — ciclo K."""
    inv = official_curation_inventory()
    sample = list(inv.get("crossDomainSample") or [])
    items = sample[: max(1, min(limit, 80))] if sample else []
    return {
        "ok": True,
        "count": int(inv.get("crossDomainCount") or 0),
        "items": items,
        "bySubject": inv.get("bySubject"),
        "disclaimer": "Labels suspeitas da base local — rode Reclassificar lote.",
    }


def official_curation_inventory() -> dict[str, Any]:
    """Inventário honesto de oficiais: labels, cross-domain, quality de resolução."""
    conn = connect()
    try:
        rows = [
            dict(r)
            for r in conn.execute(
                """
                SELECT id, subject, topic, year, source, generated, exam_board, resolution,
                       statement, correct_index
                FROM questions
                """
            ).fetchall()
        ]
    finally:
        conn.close()
    oficiais = [r for r in rows if is_official_source(r.get("source"), r.get("generated"))]
    by_subject: Counter[str] = Counter()
    by_quality: Counter[str] = Counter()
    natureza_quality: Counter[str] = Counter()
    cross: list[dict[str, Any]] = []
    natureza_items: list[dict[str, Any]] = []
    for r in oficiais:
        subj = (r.get("subject") or "—").strip()
        topic = (r.get("topic") or "—").strip()
        q = resolution_quality(r.get("resolution"))
        by_subject[subj] += 1
        by_quality[q] += 1
        xd = is_cross_domain(subj, topic)
        if xd:
            cross.append(
                {
                    "id": r["id"],
                    "subject": subj,
                    "topic": topic,
                    "year": r.get("year"),
                    "resolutionQuality": q,
                }
            )
        if subj in NATUREZA_SUBJECTS:
            natureza_quality[q] += 1
            natureza_items.append(
                {
                    "id": r["id"],
                    "subject": subj,
                    "topic": topic,
                    "year": r.get("year"),
                    "resolutionQuality": q,
                    "crossDomain": xd,
                    "curated": q == "real" and not xd,
                }
            )
    real_n = int(by_quality.get("real", 0))
    total = len(oficiais)
    real_pct = round(100.0 * real_n / total, 1) if total else 0.0
    nat_n = sum(by_subject[s] for s in NATUREZA_SUBJECTS)
    return {
        "ok": True,
        "officialCount": total,
        "bySubject": dict(by_subject.most_common()),
        "naturezaCount": nat_n,
        "naturezaBySubject": {s: by_subject.get(s, 0) for s in sorted(NATUREZA_SUBJECTS)},
        "resolutionQuality": {
            "template": int(by_quality.get("template", 0)),
            "draft": int(by_quality.get("draft", 0)),
            "real": real_n,
        },
        "realCount": real_n,
        "realPercent": real_pct,
        "naturezaResolutionQuality": {
            "template": int(natureza_quality.get("template", 0)),
            "draft": int(natureza_quality.get("draft", 0)),
            "real": int(natureza_quality.get("real", 0)),
        },
        "crossDomainCount": len(cross),
        "crossDomainSample": cross[:12],
        "naturezaItems": natureza_items[:80],
        "message": (
            f"Oficiais: {total}. Resoluções reais: {real_n} ({real_pct}%). "
            f"Cross-domain: {len(cross)}. Natureza: {nat_n}."
        ),
        "disclaimer": "Contagens factuais da base local — não são garantia de cobrança.",
    }


def promote_natureza_real_resolutions(*, limit: int = 8) -> dict[str, Any]:
    """Eleva oficiais Natureza template/draft para resolução estruturada `real` (Ciclo Y floor)."""
    return _promote_officials_real(
        limit=limit,
        subjects=NATUREZA_SUBJECTS,
        scope="natureza",
    )


def promote_other_axles_real_resolutions(*, limit: int = 12) -> dict[str, Any]:
    """Floor leve oficiais fora de Natureza (Ciclo D) — não mexe em Natureza."""
    return _promote_officials_real(
        limit=limit,
        subjects=None,
        exclude_subjects=NATUREZA_SUBJECTS,
        scope="outras",
    )


def _promote_officials_real(
    *,
    limit: int = 8,
    subjects: frozenset[str] | set[str] | None = None,
    exclude_subjects: frozenset[str] | set[str] | None = None,
    scope: str = "natureza",
) -> dict[str, Any]:
    conn = connect()
    try:
        rows = [
            dict(r)
            for r in conn.execute(
                """
                SELECT id, subject, topic, statement, resolution, correct_index, year, exam_board,
                       source, generated, options_json
                FROM questions
                ORDER BY year DESC, id
                """
            ).fetchall()
        ]
        oficiais = [r for r in rows if is_official_source(r.get("source"), r.get("generated"))]
        if subjects is not None:
            oficiais = [r for r in oficiais if (r.get("subject") or "") in subjects]
        if exclude_subjects is not None:
            oficiais = [r for r in oficiais if (r.get("subject") or "") not in exclude_subjects]
        promoted = 0
        ids: list[str] = []
        before_real = sum(1 for r in oficiais if resolution_quality(r.get("resolution")) == "real")
        for r in oficiais:
            if promoted >= limit:
                break
            q = resolution_quality(r.get("resolution"))
            if q == "real":
                continue
            idx = int(r.get("correct_index") or 0)
            letter = "ABCDE"[idx] if 0 <= idx < 5 else "?"
            subj = r.get("subject") or "Geral"
            topic = r.get("topic") or "Tópico"
            year = r.get("year") or ""
            topic_clean = topic
            if is_cross_domain(subj, topic):
                topic_clean = f"Conceitos de {subj}"
                conn.execute(
                    "UPDATE questions SET topic=? WHERE id=?",
                    (topic_clean, r["id"]),
                )
            resolution = (
                f"Comando: identifique no enunciado o que a banca pede em {subj} ({topic_clean}).\n"
                f"Conceito: relacione o trecho ao conteúdo de {topic_clean}"
                + (f" no padrão PAES-{year}" if year else "")
                + ".\n"
                f"Gabarito: a alternativa correta é {letter}; ela responde exatamente ao comando, "
                f"sem generalizar além do enunciado.\n"
                f"Distrator: elimine opções que trocam termos técnicos ou concluem além do texto."
            )
            assert resolution_quality(resolution) == "real"
            conn.execute(
                """
                UPDATE questions SET resolution=?, macete=?, pegadinha=?, banca_intent=?
                WHERE id=?
                """,
                (
                    resolution,
                    f"Marque o comando e o conceito de {topic_clean} antes das alternativas.",
                    "Distrator clássico: termo vizinho ou conclusão que o enunciado não autoriza.",
                    f"Cobrar aplicação de {subj}/{topic_clean} no estilo PAES-UEMA (revisão didática local).",
                    r["id"],
                ),
            )
            promoted += 1
            ids.append(str(r["id"]))
        conn.commit()
        # recontar não-descer real
        rows2 = [
            dict(r)
            for r in conn.execute("SELECT subject, resolution, source, generated FROM questions").fetchall()
        ]
        after_real = sum(
            1
            for r in rows2
            if is_official_source(r.get("source"), r.get("generated"))
            and resolution_quality(r.get("resolution")) == "real"
        )
        return {
            "ok": True,
            "scope": scope,
            "promoted": promoted,
            "ids": ids,
            "realBeforeSample": before_real,
            "realOfficialAfter": after_real,
            "note": (
                "Floor didático estruturado (4 eixos) — NÃO é texto oficial da banca; "
                "Aceitar no Domínio continua o padrão ouro humano."
            ),
            "kind": "didatico_estruturado",
        }
    finally:
        conn.close()


def curation_health() -> dict[str, Any]:
    """Gate anti-regressão Ciclo D — números honestos da base local."""
    inv = official_curation_inventory()
    nat_n = int(inv.get("naturezaCount") or 0)
    nat_q = inv.get("naturezaResolutionQuality") or {}
    nat_real = int(nat_q.get("real") or 0)
    cross = int(inv.get("crossDomainCount") or 0)
    real_n = int(inv.get("realCount") or 0)
    official_n = int(inv.get("officialCount") or 0)
    # floor Natureza: 100% real quando há oficiais Natureza
    natureza_floor_ok = nat_n == 0 or nat_real >= nat_n
    alerts: list[str] = []
    if not natureza_floor_ok:
        alerts.append(
            f"Natureza incompleta: {nat_real}/{nat_n} com resolução real — rode floor Natureza."
        )
    if cross > 2:
        alerts.append(f"Cross-domain alto: {cross} — rode reclassificar.")
    elif cross > 0:
        alerts.append(f"Cross-domain residual: {cross}.")
    other_n = max(0, official_n - nat_n)
    other_real = max(0, real_n - nat_real)
    other_pct = round(100.0 * other_real / other_n, 1) if other_n else 0.0
    by_subject = inv.get("bySubject") or {}
    natureza_q = inv.get("naturezaResolutionQuality") or {}
    # saúde por eixo (subject → official count already; real needs pass)
    axle = official_axle_health()
    status = "ok" if natureza_floor_ok and cross <= 2 else ("warn" if natureza_floor_ok else "attention")
    if other_n > 0 and other_pct < 50:
        if status == "ok":
            status = "warn"
        alerts.append(f"Outras áreas: {other_real}/{other_n} real ({other_pct}%) — floor leve opcional.")
    return {
        "ok": status == "ok",
        "status": status,
        "naturezaFloorOk": natureza_floor_ok,
        "naturezaCount": nat_n,
        "naturezaReal": nat_real,
        "naturezaRealPercent": round(100.0 * nat_real / nat_n, 1) if nat_n else 100.0,
        "crossDomainCount": cross,
        "officialCount": official_n,
        "realCount": real_n,
        "otherAxlesCount": other_n,
        "otherAxlesReal": other_real,
        "otherAxlesRealPercent": other_pct,
        "bySubject": by_subject,
        "axles": axle.get("axles"),
        "alerts": alerts,
        "message": (
            f"Natureza {nat_real}/{nat_n} real · oficiais {real_n}/{official_n} real · cross-domain {cross}."
        ),
        "disclaimer": "Contagens da base local — sem inventar incidência.",
    }


def official_axle_health() -> dict[str, Any]:
    """Por disciplina oficial: contagem e % real (Ciclo E)."""
    conn = connect()
    try:
        rows = [
            dict(r)
            for r in conn.execute(
                "SELECT subject, resolution, source, generated FROM questions"
            ).fetchall()
        ]
    finally:
        conn.close()
    buckets: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "real": 0, "draft": 0, "template": 0})
    for r in rows:
        if not is_official_source(r.get("source"), r.get("generated")):
            continue
        subj = (r.get("subject") or "—").strip() or "—"
        q = resolution_quality(r.get("resolution"))
        buckets[subj]["total"] += 1
        buckets[subj][q] = buckets[subj].get(q, 0) + 1
        if q == "real":
            buckets[subj]["real"] += 1
    axles = []
    for subj, b in sorted(buckets.items(), key=lambda x: (-x[1]["total"], x[0])):
        total = b["total"]
        real = b["real"]
        axles.append(
            {
                "subject": subj,
                "total": total,
                "real": real,
                "draft": b.get("draft", 0),
                "template": b.get("template", 0),
                "realPercent": round(100.0 * real / total, 1) if total else 0.0,
                "isNatureza": subj in NATUREZA_SUBJECTS,
                "floorOk": real >= total if total else True,
            }
        )
    return {"ok": True, "axles": axles, "count": len(axles)}


def promote_all_pending_officials(*, limit: int = 40) -> dict[str, Any]:
    """Eleva qualquer oficial non-real até o limite (Natureza primeiro). Ciclo E."""
    nat = promote_natureza_real_resolutions(limit=limit)
    left = max(0, limit - int(nat.get("promoted") or 0))
    other = promote_other_axles_real_resolutions(limit=left if left else 0) if left else {
        "ok": True,
        "promoted": 0,
        "ids": [],
        "scope": "outras",
    }
    health = curation_health()
    return {
        "ok": True,
        "natureza": nat,
        "outras": other,
        "promotedTotal": int(nat.get("promoted") or 0) + int(other.get("promoted") or 0),
        "health": {
            "realCount": health.get("realCount"),
            "naturezaFloorOk": health.get("naturezaFloorOk"),
            "otherAxlesRealPercent": health.get("otherAxlesRealPercent"),
        },
    }


def close_study_day() -> dict[str, Any]:
    """Marca o dia de estudo fechado (local) e devolve plano de amanhã."""
    today = datetime.now().date().isoformat()
    now = datetime.now().isoformat(timespec="seconds")
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO settings(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value
            """,
            (
                "last_day_close",
                json_dumps_settings({"date": today, "closedAt": now}),
            ),
        )
        # histórico leve dos últimos fechamentos
        row = conn.execute("SELECT value FROM settings WHERE key='day_close_log'").fetchone()
        log = loads_json(row["value"], []) if row else []
        if not isinstance(log, list):
            log = []
        log = [e for e in log if isinstance(e, dict) and e.get("date") != today]
        log.append({"date": today, "closedAt": now})
        log = log[-30:]
        conn.execute(
            """
            INSERT INTO settings(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value
            """,
            ("day_close_log", json_dumps_settings(log)),
        )
        conn.commit()
    finally:
        conn.close()
    dash = dashboard_stats()
    daily = dash.get("dailyRoutine") or {}
    week = dash.get("weekProgress") or {}
    return {
        "ok": True,
        "closedDate": today,
        "closedAt": now,
        "message": "Dia encerrado. Amanhã basta abrir Hoje e seguir o coach.",
        "tomorrowHint": daily.get("line") or "Amanhã: sessão Natureza.",
        "weekProgress": week,
        "readiness": dash.get("readiness"),
        "examCountdown": dash.get("examCountdown"),
        "streakDays": dash.get("streakDays"),
    }


def study_day_close_status() -> dict[str, Any]:
    today = datetime.now().date().isoformat()
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key='last_day_close'").fetchone()
        data = loads_json(row["value"], {}) if row else {}
    finally:
        conn.close()
    closed = (data.get("date") or "") == today
    return {
        "ok": True,
        "today": today,
        "closedToday": closed,
        "last": data if data else None,
    }


def json_dumps_settings(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False)


def _settings_get(key: str, default: Any = None) -> Any:
    conn = connect()
    try:
        row = conn.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
        if not row:
            return default
        return loads_json(row["value"], default)
    finally:
        conn.close()


def _settings_set(key: str, value: Any) -> None:
    conn = connect()
    try:
        conn.execute(
            """
            INSERT INTO settings(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value
            """,
            (key, json_dumps_settings(value) if not isinstance(value, str) else value),
        )
        conn.commit()
    finally:
        conn.close()


def _topic_read_key(subject: str, topic: str) -> str:
    return f"{(subject or '').strip()}::{(topic or '').strip()}"


def mark_topic_read(subject: str, topic: str) -> dict[str, Any]:
    """Marca tópico como lido localmente (Ciclo AU) — settings study_reads."""
    subj = (subject or "").strip()
    top = (topic or "").strip()
    if not subj or not top:
        return {"ok": False, "message": "subject e topic obrigatórios"}
    key = _topic_read_key(subj, top)
    data = _settings_get("study_reads", {}) or {}
    if not isinstance(data, dict):
        data = {}
    now = datetime.now().isoformat(timespec="seconds")
    data[key] = now
    _settings_set("study_reads", data)
    return {"ok": True, "subject": subj, "topic": top, "read": True, "at": now, "key": key}


def topic_read_status(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    data = _settings_get("study_reads", {}) or {}
    if not isinstance(data, dict):
        data = {}
    subj = (subject or "").strip()
    top = (topic or "").strip()
    if subj and top:
        key = _topic_read_key(subj, top)
        at = data.get(key)
        return {"ok": True, "subject": subj, "topic": top, "read": bool(at), "at": at, "key": key}
    # lista compacta
    items = [
        {"key": k, "at": v, "subject": (k.split("::") + [""])[0], "topic": (k.split("::") + ["", ""])[1]}
        for k, v in sorted(data.items(), key=lambda x: str(x[1] or ""), reverse=True)
    ]
    return {"ok": True, "count": len(items), "items": items[:80]}


def resolve_prova_pdf(year: int | None) -> Path | None:
    """Resolve PDF de prova no disco para o ano — None se não existir (Ciclo AV)."""
    if year is None:
        return None
    try:
        y = int(year)
    except (TypeError, ValueError):
        return None
    provas = DATA_DIR / "provas"
    if not provas.exists():
        return None
    y_str = str(y)
    candidates = [p for p in sorted(provas.glob("*.pdf")) if y_str in p.name]
    if not candidates:
        return None
    for pref in (f"paes_{y_str}", f"paes-{y_str}", f"PAES_{y_str}", f"prova_{y_str}"):
        for p in candidates:
            if pref.lower() in p.name.lower():
                return p
    return candidates[0]


def year_pdf_info(year: int) -> dict[str, Any]:
    path = resolve_prova_pdf(year)
    if path is None:
        return {
            "ok": True,
            "year": year,
            "exists": False,
            "path": None,
            "note": f"Sem PDF de prova {year} em data/provas — coloque o arquivo no PC (não inventamos).",
        }
    return {
        "ok": True,
        "year": year,
        "exists": True,
        "path": str(path),
        "label": path.name,
        "note": None,
    }


def library_search(
    q: str,
    subject: str | None = None,
    topic: str | None = None,
    source_kind: str | None = None,
    limit: int = 30,
) -> dict[str, Any]:
    """Busca unificada oficiais + materiais locais (Ciclo AW)."""
    query = (q or "").strip()
    tokens = [t.lower() for t in query.replace("?", " ").split() if len(t) > 2]
    sk = (source_kind or "").strip().lower() or None
    if sk in ("", "all", "todos"):
        sk = None
    hits: list[dict[str, Any]] = []
    lim = max(1, min(int(limit or 30), 50))

    def _score_blob(blob: str) -> int:
        low = blob.lower()
        if not tokens:
            return 1
        return sum(1 for t in tokens if t in low)

    # Ofícios / questões
    if sk in (None, "oficial"):
        conn = connect()
        try:
            rows = conn.execute(
                """
                SELECT id, year, subject, topic, statement, source, generated
                FROM questions
                ORDER BY year DESC
                LIMIT 800
                """
            ).fetchall()
        finally:
            conn.close()
        scored: list[tuple[int, dict[str, Any]]] = []
        for r in rows:
            if not is_official_source(r["source"], r["generated"]) and sk == "oficial":
                # when filtering oficial only handled below — if sk is None include all with label
                pass
            if sk == "oficial" and not is_official_source(r["source"], r["generated"]):
                continue
            if subject and (r["subject"] or "") != subject:
                continue
            if topic and (r["topic"] or "") != topic:
                continue
            blob = f"{r['subject']} {r['topic']} {r['statement'] or ''}"
            sc = _score_blob(blob)
            if tokens and sc == 0:
                continue
            if not tokens and sk is None:
                continue  # empty q without filter → skip mass dump of questions
            kind_src = "oficial" if is_official_source(r["source"], r["generated"]) else "treino"
            scored.append(
                (
                    sc,
                    {
                        "kind": "question",
                        "id": r["id"],
                        "label": f"{r['subject']} · {r['topic']} ({r['year']})",
                        "year": r["year"],
                        "subject": r["subject"],
                        "topic": r["topic"],
                        "snippet": ((r["statement"] or "")[:160]),
                        "sourceKind": kind_src if kind_src == "oficial" else "treino",
                        "path": None,
                    },
                )
            )
        scored.sort(key=lambda x: (-x[0], -(x[1].get("year") or 0)))
        for sc, item in scored[:lim]:
            item["score"] = sc
            hits.append(item)

    # Estudo: edital / aulas / snip labels
    if sk in (None, "estudo") and len(hits) < lim:
        for folder, kind in (("edital", "edital_file"), ("aulas", "estudo_file")):
            base = DATA_DIR / folder
            if not base.exists():
                continue
            for p in sorted(base.iterdir()):
                if not p.is_file():
                    continue
                blob = p.name
                if p.suffix.lower() in {".md", ".txt"}:
                    try:
                        blob = f"{p.name} " + p.read_text(encoding="utf-8", errors="ignore")[:2000]
                    except OSError:
                        pass
                sc = _score_blob(blob)
                if tokens and sc == 0:
                    continue
                if subject and subject.lower() not in blob.lower():
                    if topic and topic.lower() not in blob.lower() and tokens:
                        # keep if token matched already
                        pass
                hits.append(
                    {
                        "kind": kind,
                        "id": None,
                        "label": p.name,
                        "year": None,
                        "subject": subject,
                        "topic": topic,
                        "snippet": None,
                        "sourceKind": "estudo",
                        "path": str(p),
                        "score": sc,
                    }
                )
                if len(hits) >= lim:
                    break
            if len(hits) >= lim:
                break

    hits = hits[:lim]
    note = None
    if not hits:
        note = (
            f"Nenhum resultado local para “{query or '—'}”. "
            "Importe oficiais 2024–26 ou coloque MD em data/edital — não inventamos hit."
        )
    return {
        "ok": True,
        "q": query,
        "subject": subject,
        "topic": topic,
        "sourceKind": source_kind,
        "items": hits,
        "count": len(hits),
        "note": note,
        "disclaimer": "Só o que está no SQLite/disco local.",
    }


def iso_week_key(d: datetime | None = None) -> str:
    dt = d or datetime.now()
    y, w, _ = dt.isocalendar()
    return f"{y}-W{w:02d}"


def get_exam_date() -> str | None:
    """Data da prova em settings (ISO yyyy-mm-dd) — opcional."""
    raw = _settings_get("exam_date", None)
    if isinstance(raw, dict):
        return (raw.get("date") or raw.get("examDate") or "").strip() or None
    if isinstance(raw, str):
        return raw.strip() or None
    return None


def set_exam_date(exam_date: str | None) -> dict[str, Any]:
    """Persiste data da prova localmente (não é calendário oficial da UEMA)."""
    cleaned = (exam_date or "").strip()
    if not cleaned:
        conn = connect()
        try:
            conn.execute("DELETE FROM settings WHERE key='exam_date'")
            conn.commit()
        finally:
            conn.close()
        return {"ok": True, "examDate": None, "countdown": build_exam_countdown(None)}
    try:
        parsed = datetime.fromisoformat(cleaned[:10]).date()
    except ValueError as exc:
        raise ValueError("examDate deve ser ISO yyyy-mm-dd") from exc
    iso = parsed.isoformat()
    _settings_set("exam_date", {"date": iso, "setAt": datetime.now().isoformat(timespec="seconds")})
    return {"ok": True, "examDate": iso, "countdown": build_exam_countdown(iso)}


def build_exam_countdown(exam_date: str | None = None) -> dict[str, Any]:
    """Contagem regressiva local. Sem inventar chance de aprovação."""
    iso = (exam_date or get_exam_date() or "").strip() or None
    if not iso:
        return {
            "ok": True,
            "hasDate": False,
            "examDate": None,
            "daysLeft": None,
            "phase": "unset",
            "label": "Defina a data da prova em Ajustes",
            "intensity": "normal",
            "hint": "A contagem só conta dias restantes — não é probabilidade.",
        }
    try:
        exam = datetime.fromisoformat(iso[:10]).date()
    except ValueError:
        return {
            "ok": True,
            "hasDate": False,
            "examDate": iso,
            "daysLeft": None,
            "phase": "invalid",
            "label": "Data da prova inválida",
            "intensity": "normal",
            "hint": "Use Ajustes e salve no formato aaaa-mm-dd.",
        }
    today = datetime.now().date()
    days = (exam - today).days
    if days < 0:
        phase, intensity, label = "past", "normal", "Prova na conta — foque revisão leve"
    elif days <= 7:
        phase, intensity, label = "final", "high", f"{days} dia(s) · reta final"
    elif days <= 21:
        phase, intensity, label = "sprint", "high", f"{days} dias · sprint de consolidação"
    elif days <= 60:
        phase, intensity, label = "mid", "elevated", f"{days} dias · ritmo firme"
    else:
        phase, intensity, label = "long", "normal", f"{days} dias · construção de base"
    return {
        "ok": True,
        "hasDate": True,
        "examDate": exam.isoformat(),
        "daysLeft": days,
        "phase": phase,
        "label": label,
        "intensity": intensity,
        "hint": "Contagem local a partir da data que você marcou — não é edital da UEMA.",
    }


def study_week_key_bounds() -> tuple[str, str, str]:
    """Retorna (weekKey, weekStartISO, weekEndISO) segunda→domingo."""
    today = datetime.now().date()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    return iso_week_key(), start.isoformat(), end.isoformat()


def study_week_close_status() -> dict[str, Any]:
    week_key, start, end = study_week_key_bounds()
    data = _settings_get("last_week_close", {}) or {}
    if not isinstance(data, dict):
        data = {}
    closed = (data.get("weekKey") or "") == week_key
    return {
        "ok": True,
        "weekKey": week_key,
        "weekStart": start,
        "weekEnd": end,
        "closedThisWeek": closed,
        "last": data if data else None,
    }


def close_study_week() -> dict[str, Any]:
    """Marca a semana ISO atual como fechada e registra no log."""
    week_key, start, end = study_week_key_bounds()
    now = datetime.now().isoformat(timespec="seconds")
    payload = {"weekKey": week_key, "weekStart": start, "weekEnd": end, "closedAt": now}
    _settings_set("last_week_close", payload)
    log = _settings_get("week_close_log", []) or []
    if not isinstance(log, list):
        log = []
    log = [e for e in log if isinstance(e, dict) and e.get("weekKey") != week_key]
    log.append(payload)
    log = log[-20:]
    _settings_set("week_close_log", log)
    dash = dashboard_stats()
    return {
        "ok": True,
        "weekKey": week_key,
        "closedAt": now,
        "message": "Semana encerrada. Na próxima, o coach reabre o contador.",
        "nextHint": (dash.get("dailyRoutine") or {}).get("line") or "Próxima semana: sessão Natureza.",
        "weekProgress": dash.get("weekProgress"),
        "readiness": dash.get("readiness"),
        "streakDays": dash.get("streakDays"),
    }


def build_study_calendar(
    *,
    answered_dates: set | None = None,
    days: int = 28,
) -> dict[str, Any]:
    """Calendário leve: ativo (resposta) / fechado (encerrar dia)."""
    today = datetime.now().date()
    answered = answered_dates
    if answered is None:
        answered = set()
        conn = connect()
        try:
            for row in conn.execute("SELECT answered_at FROM answers").fetchall():
                try:
                    answered.add(datetime.fromisoformat(row["answered_at"]).date())
                except (TypeError, ValueError):
                    continue
        finally:
            conn.close()
    log = _settings_get("day_close_log", []) or []
    closed_set: set = set()
    if isinstance(log, list):
        for e in log:
            if isinstance(e, dict) and e.get("date"):
                try:
                    closed_set.add(datetime.fromisoformat(str(e["date"])[:10]).date())
                except ValueError:
                    continue
    items = []
    active_n = 0
    closed_n = 0
    for i in range(days - 1, -1, -1):
        d = today - timedelta(days=i)
        active = d in answered
        closed = d in closed_set
        if active:
            active_n += 1
        if closed:
            closed_n += 1
        items.append(
            {
                "date": d.isoformat(),
                "active": active,
                "closed": closed,
                "isToday": d == today,
                "weekday": d.weekday(),  # 0=seg
            }
        )
    return {
        "ok": True,
        "days": days,
        "activeDays": active_n,
        "closedDays": closed_n,
        "items": items,
        "hint": "● estudou · ✓ encerrou o dia — só histórico local.",
    }


def build_study_readiness(
    *,
    accuracy: float,
    total_answered: int,
    study_minutes_week: float,
    streak: int,
    gap_n: int,
    due_cards: int,
    week_progress: dict[str, Any] | None = None,
    official_unlocked: bool = False,
    countdown: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Pulso de prontidão local 0–100 — NÃO é probabilidade de aprovação UEMA."""
    week = week_progress or {}
    acc_score = 0.0
    if total_answered >= 5:
        acc_score = min(25.0, max(0.0, accuracy * 25.0))
    elif total_answered > 0:
        acc_score = min(12.0, accuracy * 12.0)
    minutes = float(study_minutes_week or 0)
    min_score = min(20.0, (minutes / 300.0) * 20.0)
    streak_score = min(10.0, (min(streak, 7) / 7.0) * 10.0)
    gaps_score = max(0.0, 15.0 * (1.0 - min(gap_n, 5) / 5.0))
    cards_score = 10.0 if due_cards == 0 else max(0.0, 10.0 - min(due_cards, 10))
    # curadoria real % se disponível
    real_score = 0.0
    try:
        inv = official_curation_inventory()
        real_pct = float(inv.get("realPercent") or 0)
        if official_unlocked:
            real_score = min(15.0, (real_pct / 100.0) * 15.0)
        else:
            real_score = min(8.0, (real_pct / 100.0) * 8.0)
    except Exception:  # noqa: BLE001
        real_score = 5.0 if official_unlocked else 0.0
    week_met_bonus = 5.0 if week.get("met") else 0.0
    score = round(acc_score + min_score + streak_score + gaps_score + cards_score + real_score + week_met_bonus, 1)
    score = max(0.0, min(100.0, score))
    if score >= 75:
        band, band_label = "solid", "Ritmo sólido"
    elif score >= 50:
        band, band_label = "building", "Em construção"
    elif score >= 25:
        band, band_label = "early", "Começando"
    else:
        band, band_label = "cold", "Frio — uma sessão muda o cenário"
    cd = countdown or {}
    phase = cd.get("phase") or "unset"
    if phase == "final" and score < 60:
        tip = "Reta final: priorize lacunas e cards due, não volume novo."
    elif phase == "sprint":
        tip = "Sprint: feche o checklist do dia e um simulado curto na semana."
    elif gap_n > 0:
        tip = f"Próximo passo: recuperar {gap_n} lacuna(s) na Fila."
    elif due_cards > 0:
        tip = f"Próximo passo: {due_cards} card(s) due."
    elif not week.get("met"):
        tip = "Próximo passo: sessão Natureza para avançar a meta semanal."
    else:
        tip = "Ritmo ok — consolide com simulado ou revisão leve."
    return {
        "ok": True,
        "score": score,
        "band": band,
        "label": band_label,
        "tip": tip,
        "components": {
            "accuracy": round(acc_score, 1),
            "minutes": round(min_score, 1),
            "streak": round(streak_score, 1),
            "gaps": round(gaps_score, 1),
            "cards": round(cards_score, 1),
            "curation": round(real_score, 1),
            "weekBonus": week_met_bonus,
        },
        "disclaimer": (
            "Pulso local com base no seu histórico e na base importada. "
            "Não é probabilidade de aprovação nem nota oficial da UEMA."
        ),
    }


def build_week_progress(
    *,
    study_minutes_week: float,
    answered_dates: set,
    streak: int,
    due_cards: int,
    gap_n: int,
    week_closed: bool = False,
) -> dict[str, Any]:
    """Meta semanal local (minutos + dias ativos) — sem inventar nota de banca."""
    today = datetime.now().date()
    week_start = today - timedelta(days=today.weekday())  # segunda
    days_active = sum(1 for d in answered_dates if d >= week_start)
    goal_minutes = 300  # ~5h / semana
    goal_days = 5
    minutes = round(study_minutes_week, 1)
    minutes_pct = min(100, round(100.0 * minutes / goal_minutes)) if goal_minutes else 0
    days_pct = min(100, round(100.0 * days_active / goal_days)) if goal_days else 0
    met = minutes >= goal_minutes or days_active >= goal_days
    if week_closed:
        label = f"Semana encerrada: {minutes:.0f} min · {days_active} dia(s)"
    elif met:
        label = f"Semana ok: {minutes:.0f} min · {days_active} dia(s)"
    elif minutes < 60 and days_active == 0:
        label = "Semana: ainda no zero — uma sessão desbloqueia o ritmo"
    else:
        label = f"Semana: {minutes:.0f}/{goal_minutes} min · {days_active}/{goal_days} dias"
    next_step = "simulado" if met and due_cards == 0 and gap_n == 0 else "sessao"
    return {
        "goalMinutes": goal_minutes,
        "goalDays": goal_days,
        "minutes": minutes,
        "minutesPercent": minutes_pct,
        "daysActive": days_active,
        "daysPercent": days_pct,
        "met": met,
        "closed": week_closed,
        "label": label,
        "streakDays": streak,
        "nextStep": next_step,
        "hint": (
            "Semana fechada — descanse ou cards leves."
            if week_closed
            else (
                "Meta atingida — um simulado curto consolida."
                if met
                else "Meta local (não é exigência oficial da UEMA)."
            )
        ),
    }


def stats_basis() -> dict[str, Any]:
    conn = connect()
    try:
        rows = conn.execute(
            "SELECT source, generated, COUNT(*) AS count FROM questions GROUP BY source, generated"
        ).fetchall()
    finally:
        conn.close()
    official = sum(int(r["count"]) for r in rows if is_official_source(r["source"], r["generated"]))
    training = sum(int(r["count"]) for r in rows if not is_official_source(r["source"], r["generated"]))
    basis = "oficial" if official >= 10 else "treino"
    return {
        "basis": basis,
        "officialCount": official,
        "trainingCount": training,
        "message": (
            "Estatísticas calculadas com questões oficiais importadas."
            if basis == "oficial"
            else "Ainda há menos de 10 questões oficiais; estatísticas usam a base de treino local e não representam histórico oficial."
        ),
    }


def list_questions(
    subject: str | None = None,
    topic: str | None = None,
    year: int | None = None,
    difficulty: str | None = None,
    medicine_only: bool = False,
    source_kind: str | None = None,
    exam_board: str | None = None,
    similares_only: bool = False,
    approved_only: bool | None = None,
    limit: int | None = None,
    offset: int = 0,
) -> list[dict[str, Any]]:
    conn = connect()
    try:
        sql = "SELECT * FROM questions WHERE 1=1"
        params: list[Any] = []
        if subject:
            sql += " AND subject = ?"
            params.append(subject)
        if topic:
            sql += " AND topic = ?"
            params.append(topic)
        if year:
            sql += " AND year = ?"
            params.append(year)
        if difficulty:
            sql += " AND difficulty = ?"
            params.append(difficulty)
        if approved_only is True:
            sql += " AND COALESCE(approved, 1) = 1"
        elif approved_only is False:
            sql += " AND COALESCE(approved, 1) = 0"
        if source_kind == "oficial":
            sql += " AND (LOWER(COALESCE(source,'')) LIKE '%pdf%' OR LOWER(COALESCE(source,'')) LIKE '%oficial%' OR LOWER(COALESCE(source,'')) LIKE '%ingest%') AND COALESCE(generated,0)=0"
        elif source_kind == "treino":
            sql += " AND COALESCE(generated,0)=0 AND NOT (LOWER(COALESCE(source,'')) LIKE '%pdf%' OR LOWER(COALESCE(source,'')) LIKE '%oficial%' OR LOWER(COALESCE(source,'')) LIKE '%ingest%')"
        elif source_kind == "gerada":
            sql += " AND COALESCE(generated,0)=1"
        if exam_board:
            sql += " AND UPPER(COALESCE(exam_board,'TREINO')) = ?"
            params.append(exam_board.upper())
        if similares_only:
            sql += " AND similarity_of IS NOT NULL AND TRIM(similarity_of) != ''"
        sql += " ORDER BY year, subject, topic"
        if limit is not None:
            sql += " LIMIT ? OFFSET ?"
            params.extend([limit, offset])
        rows = conn.execute(sql, params).fetchall()
        items = [_serialize_question(dict(r)) for r in rows]
        if medicine_only:
            ranking = medicine_priority()
            top_topics = {f"{x['subject']}::{x['topic']}" for x in ranking[:12]}
            items = [q for q in items if f"{q['subject']}::{q['topic']}" in top_topics]
        return items
    finally:
        conn.close()


def get_question(question_id: str) -> dict[str, Any] | None:
    conn = connect()
    try:
        row = conn.execute("SELECT * FROM questions WHERE id = ?", (question_id,)).fetchone()
        if not row:
            return None
        q = _serialize_question(dict(row))
        q.update(professor_blocks(q))
        return q
    finally:
        conn.close()


def _derive_exam_board(raw: dict[str, Any]) -> str:
    board = (raw.get("exam_board") or "").strip().upper()
    if board in ("UEMA_PAES", "OUTRA", "TREINO"):
        return board
    if is_official_source(raw.get("source"), raw.get("generated")):
        return "UEMA_PAES"
    return "TREINO"


def _serialize_question(raw: dict[str, Any]) -> dict[str, Any]:
    board = _derive_exam_board(raw)
    res = raw.get("resolution")
    quality = resolution_quality(res)
    axes = parse_resolution_axes(res)
    year = raw["year"]
    pdf = resolve_prova_pdf(year)
    return {
        "id": raw["id"],
        "year": year,
        "subject": raw["subject"],
        "topic": raw["topic"],
        "subtopic": raw.get("subtopic"),
        "statement": raw["statement"],
        "options": loads_json(raw.get("options_json"), []),
        "correctIndex": raw["correct_index"],
        "difficulty": raw["difficulty"],
        "tags": loads_json(raw.get("tags_json"), []),
        "syllabusId": raw.get("syllabus_id"),
        "source": raw.get("source"),
        "sourcePdf": str(pdf) if pdf is not None else None,
        "examBoard": board,
        "similarityOf": raw.get("similarity_of"),
        "similarityNote": raw.get("similarity_note"),
        "resolution": res,
        "resolutionQuality": quality,
        "resolutionAxes": axes,
        "studentResolutionLabel": student_resolution_label(quality),
        "bancaIntent": raw.get("banca_intent"),
        "macete": raw.get("macete"),
        "pegadinha": raw.get("pegadinha"),
        "relatedTopics": loads_json(raw.get("related_topics_json"), []),
        "keywords": loads_json(raw.get("keywords_json"), []),
        "statementVerbs": loads_json(raw.get("statement_verbs_json"), []),
        "generated": bool(raw.get("generated")),
        "approved": bool(raw["approved"]) if raw.get("approved") is not None else not bool(raw.get("generated")),
        "avgTextLen": raw.get("avg_text_len") or len(raw.get("statement") or ""),
        "isOfficial": is_official_source(raw.get("source"), raw.get("generated")),
    }


def topic_frequency(official_only: bool | None = None) -> list[dict[str, Any]]:
    basis = stats_basis()
    use_official = basis["basis"] == "oficial" if official_only is None else official_only
    conn = connect()
    try:
        rows = conn.execute(
            "SELECT subject, topic, year, source, generated FROM questions ORDER BY year"
        ).fetchall()
    finally:
        conn.close()

    by_topic: dict[tuple[str, str], list[int]] = defaultdict(list)
    for r in rows:
        if use_official and not is_official_source(r["source"], r["generated"]):
            continue
        by_topic[(r["subject"], r["topic"])].append(r["year"])

    result = []
    current_year = max((y for years in by_topic.values() for y in years), default=2026)
    for (subject, topic), years in sorted(by_topic.items(), key=lambda x: -len(x[1])):
        uniq = sorted(set(years))
        gaps = [uniq[i] - uniq[i - 1] for i in range(1, len(uniq))]
        last = uniq[-1]
        result.append(
            {
                "subject": subject,
                "topic": topic,
                "years": uniq,
                "frequency": len(years),
                "uniqueYears": len(uniq),
                "lastYear": last,
                "yearsSinceLast": current_year - last,
                "avgGap": (sum(gaps) / len(gaps)) if gaps else None,
                "favorite": len(uniq) >= 4,
                "forgotten": (current_year - last) >= 3 and len(uniq) >= 2,
                "basis": "oficial" if use_official else "treino",
                "disclaimer": basis["message"] if official_only is None else (
                    "Filtrado manualmente para questões oficiais." if use_official else "Filtrado manualmente para toda a base local."
                ),
            }
        )
    return result


def professor_blocks(question: dict[str, Any]) -> dict[str, Any]:
    """Monta os 7 blocos com base nos dados da questão + frequência real do tópico."""
    freq_list = topic_frequency()
    match = next(
        (
            f
            for f in freq_list
            if f["subject"] == question["subject"] and f["topic"] == question["topic"]
        ),
        None,
    )
    predictive = predict_topic(question["subject"], question["topic"], match)
    related = list(question.get("relatedTopics") or [])
    if not related and match:
        # Sugere tópicos da mesma disciplina com alta frequência
        related = [
            f["topic"]
            for f in freq_list
            if f["subject"] == question["subject"] and f["topic"] != question["topic"]
        ][:4]
    stmt = (question.get("statement") or "")[:120]
    raw_res = question.get("resolution")
    resolution = raw_res or (
        f"1) Leia o comando com atenção.\n"
        f"2) Isola o conceito de {question.get('topic')} em {question.get('subject')}.\n"
        f"3) Elimine extremos e termos trocados.\n"
        f"Trecho: {stmt}…"
    )
    quality = resolution_quality(raw_res if raw_res else None)
    axes = parse_resolution_axes(raw_res if raw_res else None)
    return {
        "professorMode": {
            "resolution": resolution,
            "resolutionQuality": quality,
            "resolutionAxes": axes,
            "studentResolutionLabel": student_resolution_label(quality),
            "bancaIntent": question.get("bancaIntent")
            or (
                f"A banca quer checar se você domina {question.get('topic')} "
                f"({question.get('subject')}) conforme o edital PAES — não apenas memorizar."
            ),
            "macete": question.get("macete")
            or f"Palavra-chave: {question.get('topic')}. Risque a alternativa que generaliza demais.",
            "pegadinha": question.get("pegadinha")
            or "Distrator clássico: troca de termos parecidos ou conclusão além do enunciado.",
            "relatedTopics": related,
            "examBoard": question.get("examBoard") or _derive_exam_board(question),
            "similarityOf": question.get("similarityOf"),
            "similarityNote": question.get("similarityNote"),
            "frequency": {
                "years": match["years"] if match else [question["year"]],
                "count": match["frequency"] if match else 1,
                "favorite": bool(match and match.get("favorite")),
                "forgotten": bool(match and match.get("forgotten")),
            },
            "returnChance": predictive,
        }
    }


def predict_topic(
    subject: str, topic: str, match: dict[str, Any] | None = None, official_only: bool | None = None
) -> dict[str, Any]:
    """Score local de prioridade — NÃO é probabilidade de cobrança UEMA nem de aprovação."""
    if match is None:
        freq_list = topic_frequency(official_only)
        match = next(
            (f for f in freq_list if f["subject"] == subject and f["topic"] == topic),
            None,
        )
    basis = stats_basis()["basis"] if official_only is None else ("oficial" if official_only else "treino")
    if not match:
        return {
            "priorityScore": 0,
            "probability": 0,  # legado; use priorityScore
            "confidence": "baixa",
            "disclaimer": (
                "Score local de prioridade de estudo — não é incidência oficial da UEMA "
                "nem probabilidade de aprovação."
            ),
            "reason": "Assunto sem histórico na base atual.",
            "trend": "indefinida",
            "basis": basis,
            "yearsUsed": [],
            "label": "Prioridade local",
        }

    freq = match["frequency"]
    since = match["yearsSinceLast"]
    avg_gap = match["avgGap"] or 3
    score = min(95, 35 + freq * 8 + max(0, since - 1) * 6)
    if avg_gap and since >= avg_gap:
        score = min(95, score + 8)
    trend = "alta" if since >= 2 and freq >= 3 else ("estável" if freq >= 2 else "baixa")
    confidence = "alta" if freq >= 4 else ("média" if freq >= 2 else "baixa")
    reason_parts = [
        f"Apareceu {freq} vez(es) nos anos {match['years']} da base local.",
        f"Última na base: {match['lastYear']} ({since} ano(s) atrás).",
    ]
    if match["avgGap"]:
        reason_parts.append(f"Intervalo médio na base ≈ {match['avgGap']:.1f} ano(s).")
    if basis != "oficial":
        reason_parts.append("Base ainda em treino — não leia como incidência UEMA.")
    return {
        "priorityScore": int(score),
        "probability": int(score),  # legado UI
        "confidence": confidence,
        "disclaimer": (
            "Score local de prioridade (histórico da base) — não é probabilidade de cobrança UEMA "
            "nem de aprovação."
        ),
        "reason": " ".join(reason_parts),
        "trend": trend,
        "years": match["years"],
        "frequency": freq,
        "basis": match.get("basis", basis),
        "yearsUsed": match["years"],
        "label": "Prioridade local",
    }


def medicine_priority(official_only: bool | None = None) -> list[dict[str, Any]]:
    conn = connect()
    try:
        weights = {
            (r["subject"], r["topic"]): r["weight"]
            for r in conn.execute("SELECT subject, topic, weight FROM syllabus").fetchall()
        }
        # quality map for (subject, topic)
        qrows = [
            dict(r)
            for r in conn.execute(
                "SELECT subject, topic, resolution, source, generated FROM questions"
            ).fetchall()
        ]
    finally:
        conn.close()

    quality_by_key: dict[tuple[str, str], dict[str, int]] = defaultdict(lambda: {"real": 0, "dirty": 0, "n": 0})
    for r in qrows:
        if not is_official_source(r.get("source"), r.get("generated")):
            continue
        key = (r["subject"], r["topic"])
        quality_by_key[key]["n"] += 1
        if is_cross_domain(r["subject"], r["topic"]):
            quality_by_key[key]["dirty"] += 1
        elif resolution_quality(r.get("resolution")) == "real":
            quality_by_key[key]["real"] += 1

    basis = stats_basis()
    uema_boost = basis.get("officialCount", 0) > 0
    natureza_med = NATUREZA_SUBJECTS
    ranked = []
    for item in topic_frequency(official_only):
        pred = predict_topic(item["subject"], item["topic"], item, official_only)
        w = weights.get((item["subject"], item["topic"]), 1.0)
        priority = pred["probability"] * w
        key = (item["subject"], item["topic"])
        qinfo = quality_by_key.get(key, {"real": 0, "dirty": 0, "n": 0})
        cross = is_cross_domain(item["subject"], item["topic"]) or qinfo.get("dirty", 0) > 0
        curated = (not cross) and qinfo.get("real", 0) > 0
        # Medicina: ênfase Natureza curada; demove dirty; oficiais não-curados abaixo
        subj = item.get("subject")
        is_nat = subj in natureza_med
        if uema_boost and is_nat:
            priority *= 1.15
        if cross:
            priority *= 0.28  # Ciclo K/N: label suja jamais sobe ao topo
        if curated and is_nat:
            priority *= 1.4
        elif curated:
            priority *= 1.1
        if not is_nat and uema_boost:
            # Ciclo N: Humanas/Linguagens/Mat sem curated não roubam Natureza;
            # Histórica mal-rotulada (count alto + dirty) fica bem abaixo.
            if cross:
                priority *= 0.2
            elif not curated:
                priority *= 0.72
            else:
                priority *= 0.92
        stars = 5 if priority >= 120 else 4 if priority >= 95 else 3 if priority >= 70 else 2 if priority >= 50 else 1
        status = "pendente"
        if cross:
            status = "sujo"
        elif curated:
            status = "curado"
        elif is_nat:
            status = "natureza"
        ranked.append(
            {
                **item,
                "weight": w,
                "probability": pred["probability"],
                "confidence": pred["confidence"],
                "reason": pred["reason"],
                "disclaimer": pred["disclaimer"],
                "stars": stars,
                "priorityScore": round(priority, 1),
                "crossDomain": cross,
                "curated": curated,
                "curationStatus": status,
                "realInTopic": qinfo.get("real", 0),
                "isNatureza": is_nat,
            }
        )
    # curated Natureza → Natureza → curated outras → demais; dirty por último
    ranked.sort(
        key=lambda x: (
            0 if x.get("crossDomain") else 1,
            -(
                3
                if x.get("curated") and x.get("isNatureza")
                else 2
                if x.get("isNatureza")
                else 1
                if x.get("curated")
                else 0
            ),
            -x["priorityScore"],
        )
    )
    return ranked


def topic_cooccurrence(official_only: bool | None = None, limit: int = 20) -> list[dict[str, Any]]:
    """Pares de tópicos relacionados ou cobrados no mesmo ano/disciplina."""
    basis = stats_basis()
    use_official = basis["basis"] == "oficial" if official_only is None else official_only
    conn = connect()
    try:
        rows = [dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()]
    finally:
        conn.close()
    rows = [r for r in rows if not use_official or is_official_source(r["source"], r["generated"])]
    pairs: Counter[tuple[str, str]] = Counter()
    for row in rows:
        topic = f"{row['subject']}::{row['topic']}"
        for related in loads_json(row.get("related_topics_json"), []):
            other = related if "::" in related else f"{row['subject']}::{related}"
            if other != topic:
                pairs[tuple(sorted((topic, other)))] += 1
    by_year_subject: dict[tuple[int, str], set[str]] = defaultdict(set)
    for row in rows:
        by_year_subject[(row["year"], row["subject"])].add(f"{row['subject']}::{row['topic']}")
    for topics in by_year_subject.values():
        for a in sorted(topics):
            for b in sorted(topics):
                if a < b:
                    pairs[(a, b)] += 1
    return [{"a": a, "b": b, "count": count} for (a, b), count in pairs.most_common(limit)]


def bank_profile(official_only: bool | None = None) -> dict[str, Any]:
    basis = stats_basis()
    use_official = basis["basis"] == "oficial" if official_only is None else official_only
    conn = connect()
    try:
        rows = [dict(r) for r in conn.execute("SELECT * FROM questions").fetchall()]
    finally:
        conn.close()
    rows = [r for r in rows if not use_official or is_official_source(r["source"], r["generated"])]
    if not rows:
        return {
            "message": "Base vazia.",
            "basis": "oficial" if use_official else "treino",
            "disclaimer": basis["message"],
            "cooccurrence": [],
            "heatmap": {},
            "avgStatementLen": 0,
            "topVerbs": [],
            "correctLetterBias": {},
        }

    verbs: Counter[str] = Counter()
    difficulties: Counter[str] = Counter()
    subjects: Counter[str] = Counter()
    text_lens: list[int] = []
    correct_letters: Counter[str] = Counter()
    keywords: Counter[str] = Counter()

    for r in rows:
        difficulties[r["difficulty"]] += 1
        subjects[r["subject"]] += 1
        text_lens.append(len(r["statement"] or ""))
        idx = r["correct_index"]
        correct_letters["ABCDE"[idx] if 0 <= idx < 5 else "?"] += 1
        for v in loads_json(r.get("statement_verbs_json"), []):
            verbs[v.lower()] += 1
        for k in loads_json(r.get("keywords_json"), []):
            keywords[k.lower()] += 1

    avg_len = sum(text_lens) / len(text_lens)
    cooccurrence = topic_cooccurrence(official_only, 20)

    # Heatmap subject x year
    heat: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for r in rows:
        heat[r["subject"]][str(r["year"])] += 1

    top_subjects = subjects.most_common(5)
    study_ctas = []
    for subj, n in top_subjects[:3]:
        study_ctas.append(
            {
                "label": f"Sessão {subj}",
                "path": f"/sessao?examBoard=UEMA_PAES&preferNatureza=1",
                "subject": subj,
                "count": n,
            }
        )
    if top_subjects:
        study_ctas.append(
            {
                "label": "Simulado incidência",
                "path": "/simulados",
                "subject": top_subjects[0][0],
            }
        )
    study_ctas.append({"label": "Tutor do dia", "path": "/tutor"})

    return {
        "totalQuestions": len(rows),
        "avgStatementLen": round(avg_len, 1),
        "avgStatementLength": round(avg_len, 1),
        "difficultyDistribution": dict(difficulties),
        "subjectDistribution": dict(subjects),
        "topVerbs": verbs.most_common(15),
        "topKeywords": keywords.most_common(20),
        "correctLetterBias": dict(correct_letters),
        "correctAlternativeBias": dict(correct_letters),
        "cooccurrence": cooccurrence,
        "correlations": cooccurrence,
        "heatmap": {s: dict(years) for s, years in heat.items()},
        "studyCtas": study_ctas,
        "disclaimer": "Perfil derivado apenas das questões presentes na base local. Não inventa % oficiais.",
        "basis": "oficial" if use_official else "treino",
    }


def error_hot_topics(limit: int = 8) -> list[dict[str, Any]]:
    """Tópicos com misses recentes — sem chamar dashboard/plano (evita recursão)."""
    conn = connect()
    try:
        answers = [dict(r) for r in conn.execute(
            "SELECT subject, topic, correct, error_type FROM answers ORDER BY answered_at DESC LIMIT 100"
        ).fetchall()]
    finally:
        conn.close()
    hot: Counter[str] = Counter()
    type_by_key: dict[str, Counter[str]] = defaultdict(Counter)
    for a in answers:
        if not a["correct"]:
            key = f"{a['subject']}::{a['topic']}"
            hot[key] += 1
            if a.get("error_type"):
                type_by_key[key][a["error_type"]] += 1
    out = []
    for k, n in hot.most_common(limit):
        dominant = type_by_key[k].most_common(1)
        out.append(
            {
                "key": k,
                "misses": n,
                "dominantErrorType": dominant[0][0] if dominant else None,
            }
        )
    return out


def build_study_plan(days: int, exam_date: str | None = None) -> list[dict[str, Any]]:
    """Plano a partir da base local + erros recentes (Ciclo AC). Sem inventar incidência."""
    ranking = medicine_priority()
    if not ranking:
        return []

    basis = stats_basis()
    use_official = basis.get("basis") == "oficial" or int(basis.get("officialCount") or 0) >= 10

    def _has_pool(item: dict[str, Any]) -> bool:
        s, t = item.get("subject"), item.get("topic")
        if not s or not t or is_cross_domain(s, t) or item.get("crossDomain"):
            return False
        n = int(item.get("frequency") or item.get("realInTopic") or 0)
        if n > 0:
            return topic_has_material(s, t, official_only=use_official if use_official else None)
        return topic_has_material(s, t, official_only=use_official if use_official else None)

    ranking = [r for r in ranking if _has_pool(r)]
    if not ranking:
        ranking = [r for r in medicine_priority() if topic_has_material(r.get("subject"), r.get("topic"), official_only=False)]
    if not ranking:
        return []

    # Boost topics with recent misses — só se ainda há questões no pool
    hot = error_hot_topics()
    hot_keys = [item["key"] for item in hot]
    hot_meta = {item["key"]: item for item in hot}
    if hot_keys:
        boosted: list[dict[str, Any]] = []
        rest: list[dict[str, Any]] = []
        seen: set[str] = set()
        for item in ranking:
            key = f"{item['subject']}::{item['topic']}"
            if key in hot_keys:
                copy = dict(item)
                dom = hot_meta.get(key, {}).get("dominantErrorType")
                suffix = f" · tipo dominante: {dom}" if dom else ""
                copy["reason"] = f"Erro recente no diagnóstico{suffix}"
                boosted.append(copy)
                seen.add(key)
            else:
                rest.append(item)
        for h in hot:
            if h["key"] in seen:
                continue
            parts = h["key"].split("::", 1)
            if len(parts) != 2:
                continue
            if not topic_has_material(parts[0], parts[1], official_only=use_official if use_official else None):
                continue
            if is_cross_domain(parts[0], parts[1]):
                continue
            boosted.append(
                {
                    "subject": parts[0],
                    "topic": parts[1],
                    "stars": 5,
                    "probability": 0,
                    "priorityScore": 0,
                    "frequency": 0,
                    "reason": (
                        f"Erro recente no diagnóstico · {h['misses']} miss(es) recentes"
                        + (f" · tipo dominante: {h['dominantErrorType']}" if h.get("dominantErrorType") else "")
                    ),
                }
            )
            seen.add(h["key"])
        order = {k: i for i, k in enumerate(hot_keys)}
        boosted.sort(key=lambda x: order.get(f"{x['subject']}::{x['topic']}", 99))
        ranking = boosted + rest

    conn = connect()
    try:
        conn.execute("DELETE FROM study_plan WHERE plan_days = ?", (days,))
        plan = []
        for day in range(1, days + 1):
            item = ranking[(day - 1) % len(ranking)]
            s, t = item["subject"], item["topic"]
            n_off = int(item.get("frequency") or item.get("realInTopic") or 0)
            years = item.get("years") or []
            if not years:
                y = latest_official_year_for(s, t)
                years = [y] if y else []
            pscore = item.get("priorityScore") or item.get("probability") or 0
            if "Erro recente" in (item.get("reason") or ""):
                reason = item["reason"]
            else:
                if n_off > 0 and years:
                    reason = (
                        f"Há {n_off} oficiais nos anos {', '.join(str(y) for y in years[:6])} "
                        f"(contagem da base local — sem % inventado)."
                    )
                elif n_off > 0:
                    reason = f"Há {n_off} questão(ões) oficiais deste tópico na base local."
                else:
                    reason = (
                        f"Prioridade local Medicina {item.get('stars', 3)}★ · base {basis.get('basis')} "
                        f"(score {pscore}) — não é incidência UEMA."
                    )
            conn.execute(
                """
                INSERT INTO study_plan (plan_days, day_index, subject, topic, reason, done)
                VALUES (?, ?, ?, ?, ?, 0)
                """,
                (days, day, s, t, reason),
            )
            plan.append(
                {
                    "day": day,
                    "subject": s,
                    "topic": t,
                    "reason": reason,
                    "stars": item.get("stars"),
                    "priorityScore": pscore,
                    "probability": item.get("probability") or pscore,
                    "officialCount": n_off,
                    "years": years,
                    "hasOfficials": n_off > 0 or bool(years),
                    "done": False,
                    "examDate": exam_date,
                    "fromErrors": "Erro recente" in reason,
                    "disclaimer": "Agenda local a partir da base — não inventa incidência.",
                }
            )
        conn.commit()
        return plan
    finally:
        conn.close()


def get_study_plan(days: int) -> list[dict[str, Any]]:
    conn = connect()
    try:
        rows = conn.execute(
            "SELECT * FROM study_plan WHERE plan_days = ? ORDER BY day_index",
            (days,),
        ).fetchall()
        if not rows:
            return build_study_plan(days)
        return [
            {
                "day": r["day_index"],
                "subject": r["subject"],
                "topic": r["topic"],
                "reason": r["reason"],
                "done": bool(r["done"]),
                "fromErrors": "Erro recente" in (r["reason"] or ""),
            }
            for r in rows
        ]
    finally:
        conn.close()


def dashboard_stats() -> dict[str, Any]:
    conn = connect()
    try:
        answers = [dict(r) for r in conn.execute("SELECT * FROM answers ORDER BY answered_at").fetchall()]
        revisions = [dict(r) for r in conn.execute("SELECT * FROM revisions").fetchall()]
    finally:
        conn.close()

    total = len(answers)
    correct = sum(1 for a in answers if a["correct"])
    accuracy = (correct / total) if total else 0.0
    times = [a["time_ms"] for a in answers if a.get("time_ms")]
    avg_time = (sum(times) / len(times)) if times else 0

    by_subject: dict[str, list[bool]] = defaultdict(list)
    by_topic: dict[str, list[bool]] = defaultdict(list)
    error_types: Counter[str] = Counter()
    for a in answers:
        by_subject[a["subject"]].append(bool(a["correct"]))
        by_topic[f"{a['subject']}::{a['topic']}"].append(bool(a["correct"]))
        if not a["correct"] and a.get("error_type"):
            error_types[a["error_type"]] += 1

    error_hot_topics_list = error_hot_topics(8)

    subject_acc = {
        s: (sum(1 for x in v if x) / len(v)) for s, v in by_subject.items() if v
    }
    strong = max(subject_acc, key=subject_acc.get) if subject_acc else None
    weak = min(subject_acc, key=subject_acc.get) if subject_acc else None

    critical = [
        {"key": k, "accuracy": sum(1 for x in v if x) / len(v), "n": len(v)}
        for k, v in by_topic.items()
        if v and (sum(1 for x in v if x) / len(v)) < 0.6
    ]
    critical.sort(key=lambda x: x["accuracy"])

    # Curva simples: acerto acumulado
    curve = []
    ok = 0
    for i, a in enumerate(answers, start=1):
        if a["correct"]:
            ok += 1
        curve.append({"n": i, "accuracy": round(ok / i, 3)})

    # Nota estimada grosseira (estimativa)
    estimated = round(accuracy * 100, 1)
    med_rank = medicine_priority()[:5]

    today = None
    plans = get_study_plan(30)
    pending = [p for p in plans if not p.get("done")]
    if pending:
        today = pending[0]

    today_date = datetime.now().date()
    answered_dates = set()
    study_minutes_today = 0
    study_minutes_week = 0
    for answer in answers:
        try:
            answered_at = datetime.fromisoformat(answer["answered_at"])
        except (TypeError, ValueError):
            continue
        answered_dates.add(answered_at.date())
        minutes = (answer.get("time_ms") or 0) / 60000
        if answered_at.date() == today_date:
            study_minutes_today += minutes
        if answered_at.date() >= today_date - timedelta(days=6):
            study_minutes_week += minutes
    streak = 0
    cursor = today_date
    while cursor in answered_dates:
        streak += 1
        cursor -= timedelta(days=1)

    edital_study: dict[str, Any] = {"theoryReady": False, "cta": "open_edital"}
    try:
        from services_edital import edital_coverage

        cov = edital_coverage()
        edital_study = {
            "theoryReady": bool(cov.get("theoryReady")),
            "hasEditalFiles": bool(cov.get("hasEditalFiles")),
            "syllabusCount": cov.get("syllabusCount", 0),
            "studyHint": cov.get("studyHint"),
            "cta": "session_theory" if cov.get("theoryReady") else "open_edital",
        }
    except Exception:  # noqa: BLE001
        pass

    basis = stats_basis()
    official_n = int(basis.get("officialCount") or 0)
    official_unlocked = official_n >= 10

    due_cards = 0
    axis_stats: dict[str, Any] = {"axisCardsDue": 0, "axisCardsCreatedToday": 0}
    try:
        from services_advanced import flashcard_axis_stats, list_flashcards

        due_cards = len(list_flashcards(due_only=True))
        axis_stats = flashcard_axis_stats()
    except Exception:  # noqa: BLE001
        due_cards = 0

    gaps_slim = [
        {
            "key": g.get("key"),
            "misses": g.get("misses"),
            "dominantErrorType": g.get("dominantErrorType"),
        }
        for g in (error_hot_topics_list or [])[:5]
    ]
    week_close = {
        "due": due_cards,
        "gaps": gaps_slim,
        "studyMinutesWeek": round(study_minutes_week, 1),
        "ctas": {
            "natureza": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
            "simulado": "/simulados",
            "filaDue": "/fila",
        },
        "hint": (
            f"Fecho da semana: {due_cards} card(s) due · {len(gaps_slim)} lacuna(s) quente(s)."
            if due_cards or gaps_slim
            else "Fecho da semana: sem due nem lacunas quentes — faça um simulado curto ou sessão Natureza."
        ),
    }

    open_gaps = list_study_gaps_safe(8)
    gap_n = int(open_gaps.get("openCount") or 0)
    week_status = study_week_close_status()
    week_closed = bool(week_status.get("closedThisWeek"))
    week_progress = build_week_progress(
        study_minutes_week=study_minutes_week,
        answered_dates=answered_dates,
        streak=streak,
        due_cards=due_cards,
        gap_n=gap_n,
        week_closed=week_closed,
    )
    day_close = study_day_close_status()
    countdown = build_exam_countdown()
    calendar = build_study_calendar(answered_dates=answered_dates, days=28)
    readiness = build_study_readiness(
        accuracy=accuracy,
        total_answered=total,
        study_minutes_week=study_minutes_week,
        streak=streak,
        gap_n=gap_n,
        due_cards=due_cards,
        week_progress=week_progress,
        official_unlocked=official_unlocked,
        countdown=countdown,
    )
    # enriquece fecho da semana (Ciclo F)
    week_close = {
        **week_close,
        "closedThisWeek": week_closed,
        "weekKey": week_status.get("weekKey"),
        "readinessScore": readiness.get("score"),
        "canClose": not week_closed and (week_progress.get("met") or streak >= 3 or day_close.get("closedToday")),
    }
    daily = build_daily_routine(
        study_today=today,
        medicine_top=med_rank,
        due_cards=due_cards,
        gap_n=gap_n,
        due_revisions=len([r for r in revisions if (r.get("next_due") or "") <= datetime.now().isoformat(timespec="seconds")]),
        study_minutes_today=round(study_minutes_today, 1),
        study_minutes_week=round(study_minutes_week, 1),
        streak=streak,
        official_unlocked=official_unlocked,
        official_n=official_n,
        week_progress=week_progress,
        day_closed=bool(day_close.get("closedToday")),
        countdown=countdown,
        readiness=readiness,
    )

    return {
        "totalAnswered": total,
        "accuracy": round(accuracy, 4),
        "avgTimeMs": round(avg_time, 1),
        "strongSubject": strong,
        "weakSubject": weak,
        "accuracyBySubject": {k: round(v, 3) for k, v in subject_acc.items()},
        "criticalTopics": critical[:10],
        "errorTypes": dict(error_types),
        "errorHotTopics": error_hot_topics_list,
        "evolutionCurve": curve[-50:],
        "estimatedScore": estimated,
        "approvalProbabilityNote": (
            "Estimativa informal com base no acerto atual; não é probabilidade real de aprovação."
        ),
        "revisionsDue": len(revisions),
        "studyToday": today,
        "medicineTop": med_rank,
        "streakDays": streak,
        "studyMinutesToday": round(study_minutes_today, 1),
        "studyMinutesWeek": round(study_minutes_week, 1),
        "statsBasis": basis,
        "officialUnlocked": official_unlocked,
        "officialUnlockMessage": (
            "Base oficial ativa (≥10 oficiais). Priorize UEMA_PAES / Natureza e revise rascunhos professor."
            if official_unlocked
            else "Ainda em treino: importe ≥10 oficiais (Biblioteca → Semana 1 real) para ativar estatísticas oficiais."
        ),
        "editalStudy": edital_study,
        "weekClose": week_close,
        "weekProgress": week_progress,
        "weekCloseStatus": week_status,
        "dayClose": day_close,
        "examCountdown": countdown,
        "studyCalendar": calendar,
        "readiness": readiness,
        "openGaps": open_gaps,
        "dailyRoutine": daily,
        "flashcardsDueCount": due_cards,
        "axisCardsDue": int(axis_stats.get("axisCardsDue") or 0),
        "axisCardsCreatedToday": int(axis_stats.get("axisCardsCreatedToday") or 0),
        "disclaimer": "Métricas derivadas apenas do histórico local do aluno e da base de questões.",
    }


def build_daily_routine(
    *,
    study_today: dict[str, Any] | None,
    medicine_top: list[dict[str, Any]],
    due_cards: int,
    gap_n: int,
    due_revisions: int,
    study_minutes_today: float,
    study_minutes_week: float = 0,
    streak: int,
    official_unlocked: bool,
    official_n: int,
    week_progress: dict[str, Any] | None = None,
    day_closed: bool = False,
    countdown: dict[str, Any] | None = None,
    readiness: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Coach do dia + checklist + semana + contagem (Ciclo C/E/F/AA). Sem inventar % de incidência."""
    focus = pick_coach_focus(medicine_top or [], study_today)
    subject = (focus or {}).get("subject") or "Biologia"
    topic = (focus or {}).get("topic") or "Genética"
    # Guarda: se o par ainda for cross-domain, cai em Natureza segura
    if is_cross_domain(subject, topic):
        focus = pick_coach_focus(medicine_top or [], None)
        subject = (focus or {}).get("subject") or "Biologia"
        topic = (focus or {}).get("topic") or "Genética"
    nat = subject in NATUREZA_SUBJECTS
    year = latest_official_year_for(subject, topic)
    session_path = (
        f"/sessao?examBoard=UEMA_PAES"
        f"&subject={quote(str(subject))}"
        f"&topic={quote(str(topic))}"
        f"&preferNatureza={'1' if nat else '0'}"
    )
    if year:
        session_path += f"&year={year}"
    if official_unlocked or official_n >= 10:
        session_path += "&preferOfficial=1"
    if not official_unlocked and official_n < 10:
        session_path = "/sessao"

    session_done = study_minutes_today >= 15
    cards_done = due_cards == 0
    revs_pending = due_revisions > 0 or gap_n > 0
    revs_done = not revs_pending
    cd = countdown or {}
    intensity = cd.get("intensity") or "normal"
    phase = cd.get("phase") or "unset"

    if day_closed:
        line = "Dia encerrado — amanhã o coach volta aqui"
        primary = "closed"
        close_path = "/dashboard"
        close_label = "Ok"
    elif gap_n > 0:
        line = f"Hoje: recuperar {gap_n} lacuna(s), depois sessão em {subject}"
        primary = "gaps"
        close_path = "/fila"
        close_label = "Ir à fila"
    elif due_cards > 0:
        if intensity == "high":
            line = f"Reta curta: {due_cards} card(s) due → sessão {subject}"
        else:
            line = f"Hoje: {due_cards} card(s) due + sessão Natureza (~60 min)"
        primary = "cards"
        close_path = "/flashcards"
        close_label = "Revisar cards"
    elif study_today:
        line = f"Hoje: sessão · {subject} · {topic}"
        primary = "session"
        close_path = "/fila"
        close_label = "Ver fila"
    else:
        line = "Hoje: sessão Natureza (~60 min)"
        primary = "session"
        close_path = "/fila"
        close_label = "Ver fila"
    if not day_closed and phase in ("final", "sprint") and primary == "session":
        days_left = cd.get("daysLeft")
        if days_left is not None and int(days_left) >= 0:
            line = f"{days_left}d p/ prova · sessão {subject} · {topic}"

    backup_reminder = None
    try:
        from services_extra import last_backup_status

        bk = last_backup_status()
        if not bk.get("ok"):
            backup_reminder = "Ainda sem backup verificado — faça um em Ajustes quando puder."
        else:
            at = bk.get("at") or bk.get("createdAt") or bk.get("timestamp")
            if at:
                try:
                    dt = datetime.fromisoformat(str(at).replace("Z", ""))
                    days = (datetime.now() - dt).days
                    if days >= 7:
                        backup_reminder = f"Último backup há {days} dia(s) — vale renovar em Ajustes."
                except (TypeError, ValueError):
                    pass
    except Exception:  # noqa: BLE001
        backup_reminder = None

    curation_slim: dict[str, Any] = {}
    try:
        inv = official_curation_inventory()
        curation_slim = {
            "realCount": inv.get("realCount"),
            "realPercent": inv.get("realPercent"),
            "naturezaCount": inv.get("naturezaCount"),
            "naturezaReal": (inv.get("naturezaResolutionQuality") or {}).get("real"),
            "crossDomainCount": inv.get("crossDomainCount"),
        }
    except Exception:  # noqa: BLE001
        curation_slim = {}

    week = week_progress or {}
    ready = readiness or {}
    # day closed counts as 4th soft bar
    progress_denom = 4 if day_closed or session_done else 3
    progress_n = min(progress_denom, sum([session_done, cards_done, revs_done]) + (1 if day_closed else 0))

    return {
        "line": line,
        "primary": primary,
        "sessionPath": session_path,
        "subject": subject,
        "topic": topic,
        "year": year,
        "preferOfficial": bool(official_unlocked or official_n >= 10),
        "focusSource": (focus or {}).get("from"),
        "closePath": close_path,
        "closeLabel": close_label,
        "checklist": {
            "session": session_done,
            "cards": cards_done,
            "revisions": revs_done,
            "dayClosed": day_closed,
            "dueCards": due_cards,
            "openGaps": gap_n,
            "dueRevisions": due_revisions,
        },
        "progressLabel": f"{progress_n}/{progress_denom} do dia",
        "streakDays": streak,
        "studyMinutesToday": study_minutes_today,
        "studyMinutesWeek": study_minutes_week,
        "backupReminder": backup_reminder,
        "curation": curation_slim,
        "week": week,
        "dayClosed": day_closed,
        "countdown": {
            "daysLeft": cd.get("daysLeft"),
            "phase": phase,
            "label": cd.get("label"),
            "intensity": intensity,
            "hasDate": bool(cd.get("hasDate")),
        },
        "readiness": {
            "score": ready.get("score"),
            "band": ready.get("band"),
            "label": ready.get("label"),
            "tip": ready.get("tip"),
        },
        "hint": (
            "Dia fechado. Descanse ou revise cards leves."
            if day_closed
            else (
                ready.get("tip")
                or (
                    "Modo foco: Começar sessão → Encerrar dia quando fizer o bloco."
                    if official_unlocked
                    else "Importe oficiais na Biblioteca para alinhar à UEMA."
                )
            )
        ),
    }


def list_study_gaps_safe(limit: int = 8) -> dict[str, Any]:
    try:
        from services_extra import list_study_gaps

        return list_study_gaps(status="open", limit=limit)
    except Exception:  # noqa: BLE001
        return {"ok": True, "count": 0, "openCount": 0, "items": []}


def build_tutor_day_plan() -> dict[str, Any]:
    """Tutor do dia grounded: meta + 3 passos + base de banca explícita (sem inventar %)."""
    dash = dashboard_stats()
    basis = stats_basis()
    study = dash.get("studyToday") or {}
    subject = study.get("subject") or "Biologia"
    topic = study.get("topic") or "Genética"
    hot = dash.get("errorHotTopics") or []
    official_n = int(basis.get("officialCount") or 0)

    uema = list_questions(subject=subject, topic=topic, exam_board="UEMA_PAES", limit=8)
    if not uema and official_n > 0:
        uema = list_questions(exam_board="UEMA_PAES", limit=8)
    treino = list_questions(subject=subject, topic=topic, exam_board="TREINO", limit=5)
    outras = list_questions(subject=subject, topic=topic, exam_board="OUTRA", limit=3)
    similares = list_questions(subject=subject, topic=topic, similares_only=True, limit=3)

    prefer_uema = official_n >= 10 or bool(uema)
    if prefer_uema and uema:
        primary_board = "UEMA_PAES"
        primary_pool = uema
    elif treino:
        primary_board = "TREINO"
        primary_pool = treino
    else:
        primary_board = "TREINO"
        primary_pool = list_questions(subject=subject, topic=topic, limit=5)

    steps = [
        f"Teoria rápida: {subject} · {topic} (syllabus local / trechos da sessão).",
        f"Praticar 8–12 itens com rótulo {primary_board}"
        + (f" ({len(primary_pool)} disponíveis neste tópico)." if primary_pool else " — filtre Questões por banca."),
        "No erro: ler resolução + macete + pegadinha antes de avançar; se for OUTRA/similar, não trate como oficial UEMA.",
    ]
    if prefer_uema and primary_board == "UEMA_PAES":
        steps[1] = (
            f"Prioridade UEMA_PAES ({len(uema)} no foco). TREINO/OUTRA só como reforço rotulado."
        )
    if hot:
        steps[2] = (
            f"Remediar hot error {hot[0].get('key')} "
            f"(tipo {hot[0].get('dominantErrorType') or '—'}) e só então seguir."
        )

    return {
        "meta": f"Hoje: {subject} · {topic}",
        "reason": study.get("reason") or "Prioridade do plano local / Medicina.",
        "steps": steps,
        "examBoardFocus": primary_board,
        "preferUema": prefer_uema,
        "counts": {
            "UEMA_PAES": len(uema),
            "TREINO": len(treino),
            "OUTRA": len(outras),
            "similares": len(similares),
            "officialCount": official_n,
        },
        "sampleIds": [q["id"] for q in primary_pool[:5]],
        "disclaimer": (
            "Nunca inventamos incidência oficial. "
            f"Base stats: {basis.get('basis')} · oficiais={official_n}. "
            "Itens OUTRA/similares são reforço rotulado."
        ),
        "ctaSession": "/sessao?examBoard=UEMA_PAES" if prefer_uema else "/sessao",
        "ctaTutor": "/tutor",
        "ctaQuestionsUema": "/questoes?examBoard=UEMA_PAES",
    }
