"""Acervo UEMA — manifesto + download só de PDFs oficiais públicos."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

from db import DATA_DIR

MANIFEST_PATH = DATA_DIR / "ACERVO_MANIFEST.json"
# Fallback: manifesto ao lado do código (repo) se data/ ainda não tiver cópia
_REPO_MANIFEST = Path(__file__).resolve().parent.parent / "data" / "ACERVO_MANIFEST.json"

ALLOWED_HOST_SUFFIXES = (".uema.br", "uema.br")


def _ensure_manifest_in_data() -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if _REPO_MANIFEST.exists():
        if (not MANIFEST_PATH.exists()) or (
            _REPO_MANIFEST.stat().st_mtime > MANIFEST_PATH.stat().st_mtime
        ):
            MANIFEST_PATH.write_bytes(_REPO_MANIFEST.read_bytes())
    return MANIFEST_PATH if MANIFEST_PATH.exists() else _REPO_MANIFEST


def load_manifest() -> dict[str, Any]:
    path = _ensure_manifest_in_data()
    if not path.exists():
        return {"version": 0, "years": [], "error": "manifest missing"}
    return json.loads(path.read_text(encoding="utf-8"))


def local_file_status(year: int) -> dict[str, Any]:
    """Prova/gabarito no disco (qualquer PDF com o ano no nome; preferência canônica)."""
    provas = DATA_DIR / "provas"
    gabaritos = DATA_DIR / "gabaritos"
    y = str(int(year))
    has_prova = False
    if provas.is_dir():
        has_prova = (provas / f"paes_{year}.pdf").is_file() or any(
            y in p.name for p in provas.glob("*.pdf")
        )
    has_gabarito = False
    if gabaritos.is_dir():
        has_gabarito = (gabaritos / f"gabarito_{year}.pdf").is_file() or any(
            y in p.name for p in gabaritos.glob("*.pdf")
        )
    return {
        "hasProva": has_prova,
        "hasGabarito": has_gabarito,
        "complete": has_prova and has_gabarito,
        "partial": has_prova and not has_gabarito,
    }


def manifest_with_local() -> dict[str, Any]:
    m = load_manifest()
    years_out = []
    for y in m.get("years") or []:
        item = dict(y)
        year = int(item["year"])
        local = local_file_status(year)
        item["local"] = local
        urls = item.get("urls") or {}
        item["canFetch"] = bool(urls.get("prova") or urls.get("gabarito"))
        if local["hasProva"] and local["hasGabarito"]:
            item["localStatus"] = "complete"
        elif local["hasProva"] or local["hasGabarito"]:
            item["localStatus"] = "partial"
        else:
            item["localStatus"] = "empty"
        years_out.append(item)
    m["years"] = years_out
    m["dataDir"] = str(DATA_DIR)
    return m


def _host_allowed(url: str) -> bool:
    from urllib.parse import urlparse

    host = (urlparse(url).hostname or "").lower()
    return any(host == s or host.endswith(s) for s in ALLOWED_HOST_SUFFIXES)


def _download(url: str, dest: Path, timeout: int = 90, *, retries: int = 1) -> dict[str, Any]:
    if not _host_allowed(url):
        return {"ok": False, "error": f"host não permitido: {url}", "path": str(dest)}
    dest.parent.mkdir(parents=True, exist_ok=True)
    last_err: dict[str, Any] | None = None
    for attempt in range(retries + 1):
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "PAES-MED-AI/1.0 (estudo pessoal; acervo oficial)"},
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = resp.read()
                ctype = (resp.headers.get("Content-Type") or "").lower()
            if len(data) < 500:
                last_err = {"ok": False, "error": "arquivo muito pequeno", "path": str(dest), "url": url}
                continue
            if "html" in ctype and not data[:5].startswith(b"%PDF"):
                last_err = {"ok": False, "error": "resposta não é PDF", "path": str(dest), "url": url}
                continue
            if not data[:5].startswith(b"%PDF"):
                last_err = {"ok": False, "error": "conteúdo sem assinatura PDF", "path": str(dest), "url": url}
                continue
            dest.write_bytes(data)
            return {
                "ok": True,
                "path": str(dest),
                "bytes": len(data),
                "url": url,
                "attempts": attempt + 1,
            }
        except urllib.error.HTTPError as e:
            last_err = {"ok": False, "error": f"HTTP {e.code}", "path": str(dest), "url": url, "attempts": attempt + 1}
        except Exception as e:  # noqa: BLE001
            last_err = {"ok": False, "error": str(e), "path": str(dest), "url": url, "attempts": attempt + 1}
    return last_err or {"ok": False, "error": "download falhou", "path": str(dest), "url": url}


def _gabarito_url(entry: dict[str, Any]) -> str | None:
    urls = entry.get("urls") or {}
    prefer = (entry.get("gabaritoPrefer") or "definitivo").lower()
    if prefer == "retificacao" and urls.get("gabaritoRetificacao"):
        return urls["gabaritoRetificacao"]
    return urls.get("gabarito") or urls.get("gabaritoRetificacao")


def fetch_year(year: int, *, dry_run: bool = False, overwrite: bool = False) -> dict[str, Any]:
    m = load_manifest()
    entry = next((y for y in (m.get("years") or []) if int(y["year"]) == int(year)), None)
    if not entry:
        return {"ok": False, "year": year, "error": "ano não está no manifesto"}
    urls = entry.get("urls") or {}
    prova_url = urls.get("prova")
    gab_url = _gabarito_url(entry)
    if not prova_url and not gab_url:
        return {
            "ok": False,
            "year": year,
            "error": "sem URL direta no manifesto",
            "status": entry.get("status"),
            "portal": entry.get("portal"),
            "notes": entry.get("notes"),
        }

    prova_dest = DATA_DIR / "provas" / f"paes_{year}.pdf"
    gab_dest = DATA_DIR / "gabaritos" / f"gabarito_{year}.pdf"
    results: dict[str, Any] = {
        "year": year,
        "dryRun": dry_run,
        "gabaritoPrefer": entry.get("gabaritoPrefer"),
        "downloads": {},
    }

    if dry_run:
        results["ok"] = True
        results["downloads"] = {
            "prova": {"url": prova_url, "dest": str(prova_dest), "wouldDownload": bool(prova_url)},
            "gabarito": {"url": gab_url, "dest": str(gab_dest), "wouldDownload": bool(gab_url)},
        }
        return results

    ok_any = False
    if prova_url:
        if prova_dest.exists() and not overwrite:
            results["downloads"]["prova"] = {"ok": True, "skipped": True, "path": str(prova_dest)}
            ok_any = True
        else:
            r = _download(prova_url, prova_dest)
            results["downloads"]["prova"] = r
            ok_any = ok_any or bool(r.get("ok"))
    if gab_url:
        if gab_dest.exists() and not overwrite:
            results["downloads"]["gabarito"] = {"ok": True, "skipped": True, "path": str(gab_dest)}
            ok_any = True
        else:
            r = _download(gab_url, gab_dest)
            results["downloads"]["gabarito"] = r
            ok_any = ok_any or bool(r.get("ok"))

    local = local_file_status(year)
    results["local"] = local
    results["ok"] = ok_any
    results["portal"] = entry.get("portal")
    results["playbook"] = {
        "openProvas": True,
        "openGabaritos": True,
        "retry": True,
        "commitOnDisk": bool(local.get("hasProva") and local.get("hasGabarito")),
        "portal": entry.get("portal"),
        "manualDrop": "Coloque paes_{year}.pdf e gabarito_{year}.pdf nas pastas e Commitar.".format(year=year),
    }
    if ok_any and local["hasProva"] and local["hasGabarito"]:
        results["message"] = "PDFs salvos. Próximo passo: Biblioteca → Revisar → Commitar."
    elif not ok_any:
        results["message"] = (
            f"Download falhou para PAES {year}. Use o portal, Abrir provas/gabaritos (drop manual) ou Tentar de novo."
        )
        results["fetchFailed"] = True
    else:
        results["message"] = "Download parcial; confira downloads e portal."
        results["fetchFailed"] = True
    return results


def fetch_available(*, dry_run: bool = False, overwrite: bool = False) -> dict[str, Any]:
    """Baixa todos os anos found ainda incompletos no disco."""
    m = manifest_with_local()
    years = []
    for item in m.get("years") or []:
        if item.get("status") != "found":
            continue
        if not item.get("canFetch"):
            continue
        local = item.get("local") or {}
        if local.get("hasProva") and local.get("hasGabarito") and not overwrite:
            years.append(
                {
                    "year": item["year"],
                    "ok": True,
                    "skipped": True,
                    "local": local,
                    "message": "já completo no disco",
                }
            )
            continue
        years.append(fetch_year(int(item["year"]), dry_run=dry_run, overwrite=overwrite))

    complete = [
        int(y["year"])
        for y in (m.get("years") or [])
        if (y.get("local") or {}).get("hasProva") and (y.get("local") or {}).get("hasGabarito")
    ]
    # Recompute after downloads
    if not dry_run:
        complete = [
            int(item["year"])
            for item in (manifest_with_local().get("years") or [])
            if (item.get("local") or {}).get("hasProva") and (item.get("local") or {}).get("hasGabarito")
        ]

    next_review = complete[0] if complete else None
    ok_count = sum(1 for y in years if y.get("ok"))
    return {
        "ok": ok_count > 0 or bool(complete),
        "dryRun": dry_run,
        "years": years,
        "completeOnDisk": complete,
        "nextReviewYear": next_review,
        "message": (
            f"Lote ok. Revisar próximo ano completo: {next_review}."
            if next_review
            else "Nenhum ano completo ainda; confira erros de download."
        ),
    }


def pick_bootstrap_year() -> int | None:
    """Preferência 2026 → 2025 → 2024 entre anos found."""
    m = manifest_with_local()
    preferred = [2026, 2025, 2024]
    found = {
        int(y["year"]): y
        for y in (m.get("years") or [])
        if y.get("status") == "found" and y.get("canFetch")
    }
    for year in preferred:
        if year in found:
            return year
    # qualquer found
    years = sorted(found.keys(), reverse=True)
    return years[0] if years else None


def bootstrap_year(*, dry_run: bool = False, overwrite: bool = False, year: int | None = None) -> dict[str, Any]:
    """Ciclo L/M: escolhe ano → fetch (se faltar) → import-year preview (sem commit)."""
    from ingest_pdf import import_year_pair

    target = year or pick_bootstrap_year()
    if target is None:
        return {"ok": False, "error": "nenhum ano found no manifesto", "dryRun": dry_run}

    m = load_manifest()
    entry = next((y for y in (m.get("years") or []) if int(y["year"]) == int(target)), {}) or {}
    portal = entry.get("portal")

    if dry_run:
        local = local_file_status(target)
        return {
            "ok": True,
            "dryRun": True,
            "year": target,
            "local": local,
            "wouldFetch": not (local["hasProva"] and local["hasGabarito"]),
            "portal": portal,
            "stages": ["check_disk", "fetch_if_needed", "extract_preview"],
            "message": f"Dry-run: bootstrap PAES {target} (fetch se faltar PDF + preview).",
        }

    local = local_file_status(target)
    skipped_fetch = local["hasProva"] and local["hasGabarito"] and not overwrite
    stages: list[str] = ["check_disk"]
    fetch_result: dict[str, Any]
    if skipped_fetch:
        stages.append("skip_fetch")
        fetch_result = {
            "ok": True,
            "year": target,
            "skipped": True,
            "local": local,
            "message": "PDFs já no disco — pulando download.",
        }
    else:
        stages.append("fetch")
        fetch_result = fetch_year(target, dry_run=False, overwrite=overwrite)
        local = local_file_status(target)

    if not local["hasProva"]:
        return {
            "ok": False,
            "year": target,
            "fetch": fetch_result,
            "portal": portal,
            "stages": stages,
            "error": "prova não disponível após fetch",
            "message": (
                (fetch_result.get("message") or "Download da prova falhou.")
                + (f" Portal: {portal}" if portal else "")
                + " Use Biblioteca → Manual / Abrir provas."
            ),
        }

    stages.append("extract_preview")
    try:
        preview = import_year_pair(target)
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "year": target,
            "fetch": fetch_result,
            "portal": portal,
            "stages": stages,
            "error": str(exc),
            "message": f"PDFs ok, mas parse falhou: {exc}",
        }

    return {
        "ok": True,
        "year": target,
        "fetch": fetch_result,
        "skippedFetch": skipped_fetch,
        "fromBootstrap": True,
        "portal": portal,
        "stages": stages + ["open_review"],
        "previewId": preview.get("previewId"),
        "questions": preview.get("questions"),
        "message": preview.get("message"),
        "needsOcr": preview.get("needsOcr"),
        "ocrFailed": preview.get("ocrFailed"),
        "pairValidation": preview.get("pairValidation"),
        "avgParseConfidence": preview.get("avgParseConfidence"),
        "gabaritoApplied": preview.get("gabaritoApplied"),
        "classified": preview.get("classified"),
        "local": local,
        "count": preview.get("count") or len(preview.get("questions") or []),
    }


def bootstrap_and_commit(
    *,
    dry_run: bool = False,
    overwrite: bool = False,
    year: int | None = None,
    min_confidence: float = 0.55,
    auto_professor: bool = True,
) -> dict[str, Any]:
    """Ciclo N/P: bootstrap + commit altas confianças (+ professor opcional)."""
    from ingest_pdf import commit_preview

    boot = bootstrap_year(dry_run=dry_run, overwrite=overwrite, year=year)
    if dry_run:
        stages = list(boot.get("stages") or []) + ["commit_high_conf"]
        if auto_professor:
            stages.append("auto_professor")
        return {
            **boot,
            "wouldCommit": True,
            "wouldAutoProfessor": auto_professor,
            "stages": stages,
            "sessionPath": f"/sessao?examBoard=UEMA_PAES&year={boot.get('year')}&preferNatureza=1",
            "message": (
                f"Dry-run: bootstrap+commit altas PAES {boot.get('year')} "
                "(fetch se faltar + preview + commit altas)."
            ),
        }
    if not boot.get("ok"):
        return boot

    preview_id = boot.get("previewId")
    questions = boot.get("questions") or []
    if not preview_id:
        return {
            **boot,
            "ok": False,
            "error": "sem previewId após bootstrap",
            "message": "Bootstrap ok, mas sem preview para commit.",
        }

    committed = commit_preview(
        str(preview_id),
        questions,
        high_confidence_only=True,
        min_confidence=min_confidence,
    )
    target = boot.get("year")
    ok = bool(committed.get("ok"))
    stages = list(boot.get("stages") or []) + ["commit_high_conf"]
    professor = None
    natureza_pack = None
    inserted_n = int(committed.get("inserted") or 0)
    if ok and auto_professor and inserted_n > 0:
        from services_extra import create_natureza_pack, fill_professor_drafts

        professor = fill_professor_drafts(limit=max(40, inserted_n), prefer_uema=True)
        stages.append("auto_professor")
        natureza_pack = create_natureza_pack(limit=min(12, max(4, inserted_n)), year=int(target) if target else None)
        stages.append("natureza_pack")
    session_path = (
        committed.get("sessionPath")
        or f"/sessao?examBoard=UEMA_PAES&year={target}"
    )
    if "preferNatureza" not in session_path:
        session_path = f"{session_path}&preferNatureza=1" if "?" in session_path else f"{session_path}?preferNatureza=1"
    return {
        "ok": ok,
        "year": target,
        "skippedFetch": boot.get("skippedFetch"),
        "portal": boot.get("portal"),
        "stages": stages,
        "previewId": preview_id,
        "fetch": boot.get("fetch"),
        "commit": committed,
        "inserted": committed.get("inserted", 0),
        "skipped": committed.get("skipped", 0),
        "officialCount": committed.get("officialCount", 0),
        "yearHealth": committed.get("yearHealth"),
        "professor": professor,
        "naturezaPack": natureza_pack,
        "sessionPath": session_path,
        "message": committed.get("message")
        if ok
        else (committed.get("message") or "Commit de altas confianças falhou."),
        "error": None if ok else committed.get("message"),
    }


def _uema_count_for_year(year: int) -> int:
    from db import connect

    conn = connect()
    try:
        row = conn.execute(
            """
            SELECT COUNT(*) AS c FROM questions
            WHERE year=? AND UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES'
            """,
            (int(year),),
        ).fetchone()
        return int(row["c"] or 0)
    finally:
        conn.close()


def found_years() -> list[int]:
    m = manifest_with_local()
    years = [
        int(y["year"])
        for y in (m.get("years") or [])
        if y.get("status") == "found" and y.get("canFetch")
    ]
    return sorted(years, reverse=True)


def years_complete_on_disk(*, min_year: int = 2014, max_year: int = 2030) -> list[int]:
    out = []
    for year in range(min_year, max_year + 1):
        local = local_file_status(year)
        if local["hasProva"] and local["hasGabarito"]:
            out.append(year)
    return out


def acervo_year_grid(*, min_year: int = 2014, max_year: int = 2026) -> list[dict[str, Any]]:
    """Grade 2014–2026: committed / preview / onDisk / partial / found / needs_manual / empty."""
    m = manifest_with_local()
    by_m = {int(y["year"]): y for y in (m.get("years") or [])}
    preview_by_year: dict[int, dict[str, Any]] = {}
    try:
        from services_extra import list_pending_ingest_previews

        pending = list_pending_ingest_previews(limit=40)
        for it in pending.get("items") or []:
            y = it.get("year")
            if y is None:
                continue
            y = int(y)
            prev = preview_by_year.get(y) or {"suspects": 0, "needsOcr": False, "count": 0}
            prev["suspects"] = int(prev["suspects"]) + int(it.get("suspects") or 0)
            prev["needsOcr"] = bool(prev["needsOcr"] or it.get("needsOcr"))
            prev["count"] = int(prev["count"]) + int(it.get("count") or 0)
            preview_by_year[y] = prev
    except Exception:  # noqa: BLE001
        preview_by_year = {}

    grid: list[dict[str, Any]] = []
    for year in range(min_year, max_year + 1):
        entry = by_m.get(year, {})
        local = local_file_status(year)
        committed = _uema_count_for_year(year)
        preview = preview_by_year.get(year)
        if committed > 0:
            ui = "committed"
        elif preview and int(preview.get("count") or 0) > 0:
            ui = "preview"
        elif local["hasProva"] and local["hasGabarito"]:
            ui = "onDisk"
        elif local["hasProva"] and not local["hasGabarito"]:
            ui = "partial"
        elif local["hasGabarito"] and not local["hasProva"]:
            ui = "partialGab"
        elif entry.get("status") == "found":
            ui = "found"
        elif entry.get("status") == "needs_manual":
            ui = "needs_manual"
        else:
            ui = "empty"
        grid.append(
            {
                "year": year,
                "uiStatus": ui,
                "manifestStatus": entry.get("status"),
                "portal": entry.get("portal"),
                "onDisk": local,
                "committedCount": committed,
                "canFetch": bool(entry.get("canFetch")),
                "localStatus": entry.get("localStatus"),
                "previewSuspects": (preview or {}).get("suspects", 0),
                "previewNeedsOcr": bool((preview or {}).get("needsOcr")),
                "previewCount": (preview or {}).get("count", 0),
                "labelHint": {
                    "committed": f"Commitado ({committed} qs)",
                    "onDisk": "Par com gab · pode gravar",
                    "partial": "Parcial · sem gabarito",
                    "partialGab": "Só gabarito · falta prova",
                    "preview": "Preview · revisar",
                    "found": "Pode baixar (portal)",
                    "needs_manual": "Baixar à mão",
                    "empty": "Vazio",
                }.get(ui, ui),
            }
        )
    return grid


def import_year_safe(
    year: int,
    *,
    commit: bool = True,
    min_confidence: float = 0.55,
    skip_if_committed: bool = False,
) -> dict[str, Any]:
    """Preview + commit high-conf só com prova+gabarito no disco (Ciclo HH)."""
    from ingest_pdf import commit_preview, import_year_pair
    from services_core import stats_basis

    local = local_file_status(year)
    if not local.get("hasProva"):
        return {
            "ok": False,
            "year": year,
            "needsProva": True,
            "message": f"Sem prova de {year} no disco. Coloque paes_{year}.pdf em data/provas.",
        }
    if skip_if_committed and _uema_count_for_year(year) > 0:
        return {
            "ok": True,
            "year": year,
            "skipped": True,
            "reason": "already_committed",
            "committedCount": _uema_count_for_year(year),
            "message": f"PAES {year} já tem oficiais na base.",
        }
    try:
        preview = import_year_pair(year)
    except Exception as exc:  # noqa: BLE001
        return {
            "ok": False,
            "year": year,
            "error": str(exc),
            "message": f"Parse falhou: {exc}",
        }
    preview_id = preview.get("previewId")
    gab_on_disk = bool(local.get("hasGabarito"))
    gab_applied = int(preview.get("gabaritoApplied") or 0)
    if not gab_on_disk or gab_applied <= 0:
        return {
            "ok": True,
            "year": year,
            "committed": False,
            "needsGabarito": True,
            "previewId": preview_id,
            "count": preview.get("count"),
            "gabaritoApplied": gab_applied,
            "avgParseConfidence": preview.get("avgParseConfidence"),
            "pairValidation": preview.get("pairValidation"),
            "questions": preview.get("questions"),
            "message": (
                f"Preview {year} com {preview.get('count') or 0} questões. "
                f"Cole gabarito_{year}.pdf em data/gabaritos e use Importar de novo / Aplicar gabarito."
            ),
            "sessionPath": f"/sessao?examBoard=UEMA_PAES&year={year}&preferNatureza=1",
        }
    if not commit:
        return {
            "ok": True,
            "year": year,
            "committed": False,
            "needsGabarito": False,
            "previewId": preview_id,
            "count": preview.get("count"),
            "gabaritoApplied": gab_applied,
            "questions": preview.get("questions"),
            "pairValidation": preview.get("pairValidation"),
            "message": preview.get("message"),
        }
    committed_res = commit_preview(
        str(preview_id),
        preview.get("questions") or [],
        high_confidence_only=True,
        min_confidence=min_confidence,
        allow_without_gabarito=False,
    )
    basis = stats_basis()
    return {
        "ok": bool(committed_res.get("ok")),
        "year": year,
        "committed": bool(committed_res.get("ok")),
        "needsGabarito": False,
        "previewId": preview_id,
        "inserted": committed_res.get("inserted", 0),
        "skipped": committed_res.get("skipped", 0),
        "yearHealth": committed_res.get("yearHealth"),
        "officialCount": basis.get("officialCount", 0),
        "sessionPath": committed_res.get("sessionPath")
        or f"/sessao?examBoard=UEMA_PAES&year={year}&preferNatureza=1",
        "error": None if committed_res.get("ok") else committed_res.get("message"),
        "message": committed_res.get("message")
        or f"Import seguro {year}: {committed_res.get('inserted', 0)} oficiais.",
    }


def bootstrap_and_commit_available(
    *,
    dry_run: bool = False,
    overwrite: bool = False,
    min_confidence: float = 0.55,
    skip_committed: bool = True,
    auto_professor: bool = True,
) -> dict[str, Any]:
    """Ciclo O/P: fetch+commit altas para todos os anos found (2024–26)."""
    years = found_years()
    if dry_run:
        items = []
        for y in years:
            local = local_file_status(y)
            committed = _uema_count_for_year(y)
            items.append(
                {
                    "year": y,
                    "wouldFetch": not (local["hasProva"] and local["hasGabarito"]),
                    "wouldCommit": not (skip_committed and committed > 0),
                    "alreadyCommitted": committed > 0,
                    "committedCount": committed,
                    "local": local,
                    "stages": ["check_disk", "fetch_if_needed", "extract_preview", "commit_high_conf"]
                    + (["auto_professor"] if auto_professor else []),
                }
            )
        return {
            "ok": True,
            "dryRun": True,
            "years": items,
            "foundCount": len(years),
            "wouldAutoProfessor": auto_professor,
            "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
            "message": f"Dry-run: bootstrap+commit altas para {len(years)} anos found.",
        }

    results: list[dict[str, Any]] = []
    inserted_total = 0
    for y in years:
        committed = _uema_count_for_year(y)
        if skip_committed and committed > 0:
            results.append(
                {
                    "year": y,
                    "ok": True,
                    "skipped": True,
                    "reason": "already_committed",
                    "inserted": 0,
                    "committedCount": committed,
                }
            )
            continue
        one = bootstrap_and_commit(
            dry_run=False,
            overwrite=overwrite,
            year=y,
            min_confidence=min_confidence,
            auto_professor=False,  # um batch no final
        )
        inserted = int(one.get("inserted") or 0)
        inserted_total += inserted
        results.append(
            {
                "year": y,
                "ok": bool(one.get("ok")),
                "skipped": False,
                "inserted": inserted,
                "skippedLowConf": one.get("skipped", 0),
                "yearHealth": one.get("yearHealth"),
                "error": one.get("error") or (None if one.get("ok") else one.get("message")),
                "message": one.get("message"),
            }
        )

    professor = None
    natureza_pack = None
    if auto_professor and inserted_total > 0:
        from services_extra import create_natureza_pack, fill_professor_drafts

        professor = fill_professor_drafts(limit=max(60, inserted_total), prefer_uema=True)
        natureza_pack = create_natureza_pack(limit=min(18, max(6, inserted_total // 2)))

    from services_core import stats_basis

    basis = stats_basis()
    ok_n = sum(1 for r in results if r.get("ok"))
    on_disk_n = len(years_complete_on_disk())
    empty_disk = inserted_total == 0 and on_disk_n == 0 and not any(
        int(r.get("committedCount") or 0) > 0 for r in results if r.get("skipped")
    )
    # Se nada inserido: montar playbook (portal + pastas)
    portals = []
    m = manifest_with_local()
    for y in (m.get("years") or []):
        if y.get("status") == "found" and y.get("portal"):
            portals.append({"year": y.get("year"), "portal": y.get("portal")})
    fetch_errors = [
        {"year": r.get("year"), "error": r.get("error") or r.get("message")}
        for r in results
        if not r.get("ok") and not r.get("skipped") and (r.get("error") or r.get("message"))
    ]
    msg = (
        f"Lote found: {inserted_total} oficiais gravadas em {ok_n}/{len(results)} anos. "
        f"Base oficial: {basis.get('officialCount', 0)}."
    )
    if empty_disk and inserted_total == 0:
        msg = (
            "Semana 1: nenhum PDF no disco e nada commitado. "
            "Use Abrir provas/gabaritos (paes_YYYY.pdf + gabarito_YYYY.pdf) "
            "ou o portal do manifesto, depois Semana 1 real de novo."
        )
    return {
        "ok": ok_n > 0 or inserted_total > 0 or any(r.get("skipped") for r in results),
        "years": results,
        "insertedTotal": inserted_total,
        "officialCount": basis.get("officialCount", 0),
        "professor": professor,
        "naturezaPack": natureza_pack,
        "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
        "emptyDisk": empty_disk and inserted_total == 0,
        "onDiskCount": on_disk_n,
        "portals": portals[:5],
        "fetchErrors": fetch_errors,
        "playbook": {
            "openProvas": True,
            "openGabaritos": True,
            "commitOnDisk": on_disk_n > 0,
            "portals": portals[:5],
            "hint": msg,
        },
        "message": msg,
    }


def commit_on_disk(
    *,
    dry_run: bool = False,
    min_confidence: float = 0.55,
    skip_committed: bool = True,
    auto_professor: bool = True,
) -> dict[str, Any]:
    """Ciclo O/P: import+commit altas para todo ano com prova+gabarito no disco (sem URL)."""
    from ingest_pdf import commit_preview, import_year_pair

    years = years_complete_on_disk()
    if dry_run:
        items = []
        for y in years:
            committed = _uema_count_for_year(y)
            items.append(
                {
                    "year": y,
                    "onDisk": True,
                    "alreadyCommitted": committed > 0,
                    "committedCount": committed,
                    "wouldCommit": not (skip_committed and committed > 0),
                    "stages": ["check_disk", "extract_preview", "commit_high_conf"]
                    + (["auto_professor"] if auto_professor else []),
                }
            )
        return {
            "ok": True,
            "dryRun": True,
            "years": items,
            "onDiskCount": len(years),
            "wouldAutoProfessor": auto_professor,
            "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
            "message": (
                f"Dry-run: {len(years)} anos completos no disco para commit."
                if years
                else "Dry-run: nenhum pares prova+gabarito no disco."
            ),
        }

    results: list[dict[str, Any]] = []
    inserted_total = 0
    for y in years:
        committed = _uema_count_for_year(y)
        if skip_committed and committed > 0:
            results.append(
                {
                    "year": y,
                    "ok": True,
                    "skipped": True,
                    "reason": "already_committed",
                    "inserted": 0,
                    "committedCount": committed,
                }
            )
            continue
        try:
            preview = import_year_pair(y)
        except Exception as exc:  # noqa: BLE001
            results.append(
                {
                    "year": y,
                    "ok": False,
                    "inserted": 0,
                    "error": str(exc),
                    "message": f"Parse falhou: {exc}",
                }
            )
            continue
        preview_id = preview.get("previewId")
        if not preview_id:
            results.append(
                {
                    "year": y,
                    "ok": False,
                    "inserted": 0,
                    "error": "sem previewId",
                    "message": "Import ok, mas sem preview.",
                }
            )
            continue
        committed_res = commit_preview(
            str(preview_id),
            preview.get("questions") or [],
            high_confidence_only=True,
            min_confidence=min_confidence,
            allow_without_gabarito=False,
        )
        inserted = int(committed_res.get("inserted") or 0)
        inserted_total += inserted
        results.append(
            {
                "year": y,
                "ok": bool(committed_res.get("ok")),
                "skipped": False,
                "inserted": inserted,
                "skippedLowConf": committed_res.get("skipped", 0),
                "yearHealth": committed_res.get("yearHealth"),
                "error": None if committed_res.get("ok") else committed_res.get("message"),
                "message": committed_res.get("message"),
            }
        )

    professor = None
    natureza_pack = None
    if auto_professor and inserted_total > 0:
        from services_extra import create_natureza_pack, fill_professor_drafts

        professor = fill_professor_drafts(limit=max(60, inserted_total), prefer_uema=True)
        natureza_pack = create_natureza_pack(limit=min(18, max(6, inserted_total // 2)))

    from services_core import stats_basis

    basis = stats_basis()
    ok_n = sum(1 for r in results if r.get("ok"))
    return {
        "ok": ok_n > 0 or inserted_total > 0 or (not years),
        "years": results,
        "insertedTotal": inserted_total,
        "officialCount": basis.get("officialCount", 0),
        "professor": professor,
        "naturezaPack": natureza_pack,
        "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1",
        "message": (
            f"Disco: {inserted_total} oficiais gravadas em {ok_n}/{len(results) or 0} anos. "
            f"Base oficial: {basis.get('officialCount', 0)}."
            if years
            else "Nenhum pares prova+gabarito no disco. Coloque paes_YYYY.pdf + gabarito_YYYY.pdf."
        ),
    }


def waiting_gabarito_years(*, min_year: int = 2014, max_year: int = 2030) -> list[dict[str, Any]]:
    """Anos com prova no disco e sem gabarito (aguardando gabarito_YYYY.pdf)."""
    out: list[dict[str, Any]] = []
    for year in range(min_year, max_year + 1):
        local = local_file_status(year)
        if local.get("hasProva") and not local.get("hasGabarito"):
            out.append(
                {
                    "year": year,
                    "needsGabarito": True,
                    "proofFile": local.get("provaPath") or local.get("prova"),
                    "message": f"Aguardando gabarito_{year}.pdf em data/gabaritos/",
                }
            )
    return out


def import_all_complete(
    *,
    min_confidence: float = 0.55,
    skip_if_committed: bool = False,
    classify_after: bool = True,
) -> dict[str, Any]:
    """Ciclo HK: loop `import_year_safe` em todos os pares prova+gab no disco."""
    years = years_complete_on_disk()
    waiting = waiting_gabarito_years()
    results: list[dict[str, Any]] = []
    inserted_total = 0
    for y in years:
        one = import_year_safe(
            y,
            commit=True,
            min_confidence=min_confidence,
            skip_if_committed=skip_if_committed,
        )
        inserted = int(one.get("inserted") or 0)
        inserted_total += inserted
        results.append(
            {
                "year": y,
                "ok": bool(one.get("ok")),
                "inserted": inserted,
                "skipped": one.get("skipped"),
                "committed": bool(one.get("committed")),
                "needsGabarito": bool(one.get("needsGabarito")),
                "yearHealth": one.get("yearHealth"),
                "error": one.get("error")
                or (None if one.get("ok") else one.get("message")),
                "message": one.get("message"),
                "gabaritoPct": (one.get("yearHealth") or {}).get("gabaritoPct"),
            }
        )

    classified = None
    if classify_after and inserted_total > 0:
        classified = {
            "ok": True,
            "deferred": True,
            "message": "Chame POST /api/ingest/classify-pending após o lote (API faz isso).",
        }

    from services_core import official_curation_inventory, stats_basis

    basis = stats_basis()
    wait_years = [w["year"] for w in waiting]
    msg = (
        f"Import todos com gab: +{inserted_total} em {len(years)} par(es) no disco. "
        f"Base oficial: {basis.get('officialCount', 0)}."
    )
    if wait_years:
        msg += f" Aguardando gabarito: {', '.join(map(str, wait_years[:12]))}."
    if not years and wait_years:
        msg = (
            "Nenhum par prova+gab no disco. "
            f"Anos só com prova (sem gab): {', '.join(map(str, wait_years))}."
        )
    elif not years:
        msg = "Nenhum par prova+gabarito no disco. Coloque paes_YYYY.pdf + gabarito_YYYY.pdf."

    invent = None
    try:
        invent = official_curation_inventory()
    except Exception:  # noqa: BLE001
        invent = None

    health_by_year = {
        str(r["year"]): {
            "inserted": r.get("inserted"),
            "gabaritoPct": r.get("gabaritoPct"),
            "yearHealth": r.get("yearHealth"),
            "error": r.get("error"),
        }
        for r in results
    }

    return {
        "ok": True if years else (inserted_total > 0 or not wait_years),
        "years": results,
        "insertedTotal": inserted_total,
        "completeYears": years,
        "waitingGabarito": waiting,
        "waitingYears": wait_years,
        "healthByYear": health_by_year,
        "classified": classified,
        "naturezaInventory": invent,
        "officialCount": basis.get("officialCount", 0),
        "sessionPath": "/sessao?examBoard=UEMA_PAES&preferNatureza=1&officialWithGab=1",
        "message": msg,
    }