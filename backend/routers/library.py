"""Rotas: biblioteca."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from fastapi import APIRouter, HTTPException

from db import (
    DATA_DIR,
    connect,
)
from ingest_pdf import (
    compute_year_statuses,
    list_pdf_inventory,
    pair_prova_gabarito,
)
from schemas import (
    OpenFolderRequest,
    OpenPathRequest,
    OpenUrlRequest,
)
from services_advanced import index_all_questions
from services_core import (
    library_search,
    list_library_search_history,
    stats_basis,
    year_pdf_info,
)
from services_edital import (
    edital_coverage,
    sync_syllabus_from_edital_file,
    theory_snippets_for,
)
from services_extra import (
    create_backup,
    list_pending_ingest_previews,
)

router = APIRouter(tags=["biblioteca"])


@router.post("/api/backup")
def api_backup() -> dict[str, Any]:
    return create_backup()

@router.get("/api/backup/last")
def api_backup_last() -> dict[str, Any]:
    from services_extra import last_backup_status

    return last_backup_status()

@router.post("/api/backup/restore")
def api_backup_restore(folderName: str = "", path: str = "") -> dict[str, Any]:
    """Restaura DB a partir de pasta ou zip dentro de data/backups."""
    from services_extra import restore_backup_db

    backups_dir = (DATA_DIR / "backups").resolve()
    if path:
        candidate = Path(path).expanduser().resolve()
        if not candidate.is_relative_to(backups_dir):
            raise HTTPException(400, "path deve apontar para data/backups.")
        return restore_backup_db(str(candidate))
    if not folderName:
        raise HTTPException(400, "Informe folderName ou path")
    if Path(folderName).name != folderName:
        raise HTTPException(400, "folderName deve ser um nome simples dentro de data/backups.")
    src = DATA_DIR / "backups" / folderName
    if (src / "paes_med_ai.db").exists():
        return restore_backup_db(str(src))
    zip_path = DATA_DIR / "backups" / folderName
    if zip_path.suffix == ".zip" and zip_path.exists():
        return restore_backup_db(str(zip_path))
    # folderName may be zip filename
    z2 = DATA_DIR / "backups" / f"{folderName}.zip" if not folderName.endswith(".zip") else DATA_DIR / "backups" / folderName
    if z2.exists():
        return restore_backup_db(str(z2))
    raise HTTPException(404, f"Backup não encontrado: {folderName}")

@router.get("/api/library")
def api_library() -> dict[str, Any]:
    inventory = list_pdf_inventory()
    pairs = pair_prova_gabarito(inventory)
    year_statuses = compute_year_statuses()
    from acervo_fetch import manifest_with_local

    acervo = manifest_with_local()
    conn = connect()
    try:
        rows = conn.execute("SELECT year, source, generated, COUNT(*) AS c FROM questions GROUP BY year, source, generated").fetchall()
        by_year: dict[int, dict[str, Any]] = {
            item["year"]: {
                "year": item["year"], "questions": item["officialQuestionCount"],
                "status": item["status"], "hasProva": item["hasProva"], "hasGabarito": item["hasGabarito"],
            }
            for item in year_statuses
        }
        counts = {"total": 0, "treino": 0, "oficial": 0, "generated": 0}
        for r in rows:
            y = int(r["year"])
            c = int(r["c"])
            counts["total"] += c
            if r["generated"]:
                counts["generated"] += c
            src = (r["source"] or "").lower()
            if "pdf" in src or "oficial" in src or "ingest" in src:
                counts["oficial"] += c
            else:
                counts["treino"] += c
        provas_years = sorted({item["year"] for item in inventory if item["kind"] == "prova" and item.get("year")})
        gabaritos_years = sorted({item["year"] for item in inventory if item["kind"] == "gabarito" and item.get("year")})
        edital_ok = any(item["kind"] == "edital" for item in inventory)
        checklist = {
            "editalOk": edital_ok,
            "yearsWithProva": provas_years,
            "yearsWithGabarito": gabaritos_years,
            "yearsComplete": sorted(set(provas_years) & set(gabaritos_years)),
            "coveragePct": round(100 * len(set(provas_years) & set(gabaritos_years)) / 13, 1),
            "missingYears": [
                year for year in range(2014, 2027)
                if year not in provas_years or year not in gabaritos_years
            ],
            "yearStatuses": year_statuses,
            "guide": {
                "provasPath": str(DATA_DIR / "provas"),
                "gabaritosPath": str(DATA_DIR / "gabaritos"),
                "editalPath": str(DATA_DIR / "edital"),
                "naming": "paes_YYYY.pdf | gabarito_YYYY.pdf | edital_YYYY.pdf",
            },
            "provasYears": provas_years,
            "gabaritosYears": gabaritos_years,
            "anosCompletos": sorted(set(provas_years) & set(gabaritos_years)),
            "anosParciais": sorted(set(provas_years) - set(gabaritos_years)),
            "anosParciaisCount": len(set(provas_years) - set(gabaritos_years)),
            "anosCompletosCount": len(set(provas_years) & set(gabaritos_years)),
            "officialCount": stats_basis()["officialCount"],
            "message": (
                "Acervo oficial disponível para revisão."
                if edital_ok and provas_years and gabaritos_years
                else "Ainda faltam arquivos oficiais; dados de treino permanecem claramente identificados."
            ),
        }
        from ingest_pdf import year_health_from_db

        year_health: dict[str, Any] = {}
        for y in sorted({int(r["year"]) for r in rows}):
            health = year_health_from_db(y)
            if health.get("total", 0) > 0:
                year_health[str(y)] = health
                if y in by_year:
                    by_year[y]["yearHealth"] = health
        checklist["yearHealth"] = year_health
        from acervo_fetch import acervo_year_grid

        year_grid = acervo_year_grid()
        checklist["yearGrid"] = year_grid
        pending = list_pending_ingest_previews(limit=8)
        checklist["pendingPreviews"] = pending
        return {
            "years": [by_year[y] for y in sorted(by_year)],
            "counts": counts,
            "inventory": inventory,
            "pairs": pairs,
            "checklist": checklist,
            "yearGrid": year_grid,
            "pendingPreviews": pending,
            "acervoManifest": acervo,
            "dataDir": str(DATA_DIR),
            "paths": {
                "provas": str(DATA_DIR / "provas"),
                "gabaritos": str(DATA_DIR / "gabaritos"),
                "edital": str(DATA_DIR / "edital"),
                "root": str(DATA_DIR),
            },
        }
    finally:
        conn.close()

@router.post("/api/library/open-folder")
def api_library_open_folder(payload: OpenFolderRequest) -> dict[str, Any]:
    mapping = {
        "provas": DATA_DIR / "provas",
        "gabaritos": DATA_DIR / "gabaritos",
        "edital": DATA_DIR / "edital",
        "root": DATA_DIR,
    }
    path = mapping[payload.folder]
    path.mkdir(parents=True, exist_ok=True)
    try:
        if os.name == "nt":
            os.startfile(str(path))  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", str(path)])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", str(path)])
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Não foi possível abrir a pasta: {exc}") from exc
    return {"ok": True, "path": str(path), "folder": payload.folder}

@router.post("/api/library/open-path")
def api_library_open_path(payload: OpenPathRequest) -> dict[str, Any]:
    """Abre arquivo/pasta local dentro de DATA_DIR (Ciclo AP)."""
    from pathlib import Path as _Path

    target = _Path(payload.path).resolve()
    root = DATA_DIR.resolve()
    try:
        target.relative_to(root)
    except ValueError as exc:
        raise HTTPException(403, "Só é possível abrir arquivos dentro da pasta de dados do app") from exc
    if not target.exists():
        raise HTTPException(
            404,
            "Arquivo não encontrado no disco — pode ter sido movido ou apagado.",
        )
    try:
        if os.name == "nt":
            os.startfile(str(target))  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", str(target)])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", str(target)])
    except OSError as exc:
        raise HTTPException(500, f"Não foi possível abrir: {exc}") from exc
    return {"ok": True, "path": str(target)}

@router.get("/api/library/materials")
def api_library_materials(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Lista material local filtrado por subject/topic + snippets do edital (Ciclo AR)."""
    subj = (subject or "").strip()
    top = (topic or "").strip()
    filter_active = bool(subj or top)
    tokens = [t.lower() for t in f"{subj} {top}".split() if len(t) > 2]
    matched = f"{subj} · {top}".strip(" ·") if filter_active else None

    def _matches_blob(blob: str) -> bool:
        if not filter_active:
            return True
        low = blob.lower()
        return any(tok in low for tok in tokens)

    def _matches_file(path: Path) -> bool:
        if not filter_active:
            return True
        if _matches_blob(path.name):
            return True
        if path.suffix.lower() in {".md", ".txt"}:
            try:
                head = path.read_text(encoding="utf-8", errors="ignore")[:8000]
            except OSError:
                return False
            return _matches_blob(head)
        return False

    items: list[dict[str, Any]] = []
    file_match_count = 0

    # Trechos de teoria do edital/syllabus (não inventa PDF)
    for i, snip in enumerate(theory_snippets_for(subj or None, top or None, limit=6)):
        text = (snip or "").strip()
        if not text:
            continue
        items.append(
            {
                "kind": "theory_snippet",
                "label": f"Teoria · {matched or 'edital'}" + (f" ({i + 1})" if i else ""),
                "snippet": text[:800],
                "path": None,
                "folder": "edital",
                "exists": True,
                "matchedTopic": matched,
                "sourceKind": "edital_snippet",
            }
        )

    edital_dir = DATA_DIR / "edital"
    if edital_dir.exists():
        for p in sorted(edital_dir.iterdir()):
            if not p.is_file() or p.suffix.lower() not in {".md", ".txt", ".pdf"}:
                continue
            if not _matches_file(p):
                continue
            kind = "edital_md" if p.suffix.lower() in {".md", ".txt"} else "edital_pdf"
            items.append(
                {
                    "kind": kind,
                    "label": p.name,
                    "path": str(p),
                    "folder": "edital",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1

    # PDFs de prova: com filtro de tópico só se o nome bater; sem filtro, até 8
    provas_dir = DATA_DIR / "provas"
    if provas_dir.exists():
        prova_n = 0
        for p in sorted(provas_dir.glob("*.pdf")):
            if filter_active and not _matches_blob(p.name):
                continue
            if not filter_active and prova_n >= 8:
                break
            items.append(
                {
                    "kind": "prova",
                    "label": p.name,
                    "path": str(p),
                    "folder": "provas",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1
            prova_n += 1

    if not filter_active:
        gab_dir = DATA_DIR / "gabaritos"
        if gab_dir.exists():
            for p in sorted(gab_dir.glob("*.pdf"))[:4]:
                items.append(
                    {
                        "kind": "gabarito",
                        "label": p.name,
                        "path": str(p),
                        "folder": "gabaritos",
                        "exists": True,
                        "matchedTopic": matched,
                        "sourceKind": "local",
                    }
                )
                file_match_count += 1

    aulas_dir = DATA_DIR / "aulas"
    if aulas_dir.exists():
        for p in sorted(aulas_dir.iterdir()):
            if not p.is_file():
                continue
            if not _matches_file(p):
                continue
            items.append(
                {
                    "kind": "estudo",
                    "label": p.name,
                    "path": str(p),
                    "folder": "aulas",
                    "exists": True,
                    "matchedTopic": matched,
                    "sourceKind": "local",
                }
            )
            file_match_count += 1

    note = None
    if not items:
        note = (
            f"Nenhum material local para {matched or 'este recorte'}. "
            "Coloque resumo MD em data/edital ou PDFs oficiais — o app não inventa edital UEMA."
        )
    elif filter_active and file_match_count == 0:
        note = (
            f"Sem arquivo no disco batendo em {matched}; há trecho(s) de edital/syllabus se listados. "
            "Não inventamos PDF. Abra a Biblioteca para o acervo 2024–26."
        )

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "matchedTopic": matched,
        "items": items,
        "count": len(items),
        "fileMatchCount": file_match_count,
        "note": note,
        "disclaimer": "Só lista o que existe no disco ou trechos do edital local; não inventa 2017–23 nem PDF ausente.",
    }

@router.get("/api/library/year-pdf")
def api_library_year_pdf(year: int) -> dict[str, Any]:
    """Resolve PDF de prova oficial no disco para o ano (Ciclo AV)."""
    return year_pdf_info(int(year))

@router.get("/api/library/search")
def api_library_search(
    q: str = "",
    subject: str | None = None,
    topic: str | None = None,
    sourceKind: str | None = None,
    limit: int = 30,
) -> dict[str, Any]:
    """Busca acervo local oficial/estudo (Ciclo AW)."""
    return library_search(q=q, subject=subject, topic=topic, source_kind=sourceKind, limit=limit)

@router.get("/api/library/search-history")
def api_library_search_history(limit: int = 15) -> dict[str, Any]:
    """Histórico local de buscas na Biblioteca (Ciclo BL)."""
    return list_library_search_history(limit=limit)

@router.post("/api/library/open-url")
def api_library_open_url(payload: OpenUrlRequest) -> dict[str, Any]:
    """Abre portal UEMA (ou URL http/https) no navegador padrão — playbook Acervo."""
    from urllib.parse import urlparse

    url = payload.url.strip()
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise HTTPException(400, "URL inválida (use http/https)")
    host = (parsed.hostname or "").lower()
    if not (host == "uema.br" or host.endswith(".uema.br")):
        raise HTTPException(400, "Só portais *.uema.br são abertos pelo app")
    try:
        if os.name == "nt":
            os.startfile(url)  # type: ignore[attr-defined]
        elif os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", url])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", url])
    except OSError as exc:
        raise HTTPException(status_code=500, detail=f"Não foi possível abrir o navegador: {exc}") from exc
    return {"ok": True, "url": url}

@router.post("/api/edital/sync-syllabus")
def api_edital_sync_syllabus() -> dict[str, Any]:
    return sync_syllabus_from_edital_file()

@router.get("/api/edital/coverage")
def api_edital_coverage() -> dict[str, Any]:
    return edital_coverage()

@router.post("/api/library/reprocess")
def api_library_reprocess() -> dict[str, Any]:
    """Estatísticas são derivadas do SQLite; reindex embeddings + confirmação."""
    indexed = index_all_questions()
    return {"ok": True, "message": "Base reprocessada (frequência/perfil recalculam na leitura).", "rag": indexed}

@router.get("/api/backups")
def api_list_backups() -> list[dict[str, str]]:
    backup_dir = DATA_DIR / "backups"
    if not backup_dir.exists():
        return []
    out = []
    for p in sorted(backup_dir.iterdir(), reverse=True):
        if p.is_dir() and (p / "paes_med_ai.db").exists():
            out.append({"name": p.name, "path": str(p)})
        if p.suffix == ".zip":
            out.append({"name": p.name, "path": str(p)})
    return out[:30]
