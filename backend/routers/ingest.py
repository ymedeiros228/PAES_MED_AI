"""Rotas: ingestao."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from fastapi import (
    APIRouter,
    File,
    HTTPException,
    UploadFile,
)

from api_helpers import _save_upload
from db import DATA_DIR, db
from ingest_pdf import (
    apply_gabarito,
    classify_questions_by_syllabus,
    commit_preview,
    extract_pdf_text,
    get_preview,
    import_and_commit_year,
    import_year_pair,
    list_pdf_inventory,
    parse_gabarito,
    parse_pdf_file,
    update_preview,
)
from schemas import (
    AcervoBatchCommitRequest,
    AcervoBootstrapCommitRequest,
    AcervoBootstrapRequest,
    AcervoCommitOnDiskRequest,
    AcervoFetchAvailableRequest,
    AcervoFetchRequest,
    AcervoImportAllCompleteRequest,
    ApplyGabaritoRequest,
    CommitIngestRequest,
    ImportYearRequest,
    ImportYearSafeRequest,
    IngestFromDataRequest,
    ParseGateRequest,
    UpdatePreviewRequest,
)
from services_advanced import index_all_questions
from services_core import bank_profile
from services_extra import (
    create_backup,
    create_natureza_pack,
    fill_professor_drafts,
    ingest_pdf_placeholder,
    parse_gate_flags,
)

router = APIRouter(tags=["ingestao"])


@router.post("/api/ingest/pdf")
async def api_ingest_pdf(
    kind: str = "prova",
    year: int | None = None,
    subject: str = "Geral",
    file: UploadFile = File(...),
) -> dict[str, Any]:
    if kind not in ("prova", "gabarito", "edital"):
        raise HTTPException(400, "kind deve ser prova|gabarito|edital")
    if not (Path(file.filename or "").name.lower().endswith(".pdf")):
        raise HTTPException(400, "Envie um arquivo .pdf")
    folder = DATA_DIR / ("provas" if kind == "prova" else "gabaritos" if kind == "gabarito" else "edital")
    dest = await _save_upload(file, folder, "arquivo.pdf")
    try:
        return parse_pdf_file(dest, kind, year=year, subject=subject)
    except Exception as exc:
        ingest_pdf_placeholder(dest.name, kind)
        raise HTTPException(500, f"Falha ao parsear PDF: {type(exc).__name__}: {exc}") from exc

@router.post("/api/ingest/commit")
def api_ingest_commit(payload: CommitIngestRequest) -> dict[str, Any]:
    create_backup()
    result = commit_preview(
        payload.previewId,
        payload.questions,
        high_confidence_only=payload.highConfidenceOnly,
        min_confidence=payload.minConfidence,
        allow_without_gabarito=payload.allowWithoutGabarito,
    )
    if not result.get("ok"):
        raise HTTPException(400, result.get("message", "Commit falhou"))
    if payload.autoProfessor and int(result.get("inserted") or 0) > 0:
        result["professor"] = fill_professor_drafts(
            limit=max(40, int(result.get("inserted") or 20)),
            prefer_uema=True,
        )
    sp = result.get("sessionPath") or "/sessao?examBoard=UEMA_PAES"
    if "preferNatureza" not in sp:
        sp = f"{sp}&preferNatureza=1" if "?" in sp else f"{sp}?preferNatureza=1"
    result["sessionPath"] = sp
    try:
        result["rag"] = index_all_questions()
    except Exception as exc:
        result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
    return result

@router.post("/api/ingest/from-data")
def api_ingest_from_data(payload: IngestFromDataRequest) -> dict[str, Any]:
    folders = {"prova": "provas", "gabarito": "gabaritos", "edital": "edital"}
    filename = Path(payload.filename).name
    if filename != payload.filename or not filename.lower().endswith(".pdf"):
        raise HTTPException(400, "filename deve ser um PDF existente nas pastas de dados.")
    path = DATA_DIR / folders[payload.kind] / filename
    if not path.is_file():
        raise HTTPException(404, "PDF não encontrado na pasta de dados.")
    return parse_pdf_file(path, payload.kind, payload.year, payload.subject)

@router.post("/api/ingest/import-year")
def api_ingest_import_year(payload: ImportYearRequest) -> dict[str, Any]:
    try:
        result = import_and_commit_year(payload.year) if payload.commit else import_year_pair(payload.year)
        if payload.commit and result.get("commit", {}).get("ok"):
            try:
                result["rag"] = index_all_questions()
            except Exception as exc:
                result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        return result
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except Exception as exc:
        raise HTTPException(500, f"Falha ao importar {payload.year}: {type(exc).__name__}: {exc}") from exc

@router.post("/api/acervo/import-year-safe")
def api_acervo_import_year_safe(payload: ImportYearSafeRequest) -> dict[str, Any]:
    """Preview + commit high-conf só com gabarito; senão devolve needsGabarito (HH)."""
    from acervo_fetch import import_year_safe

    result = import_year_safe(
        payload.year,
        commit=payload.commit,
        min_confidence=payload.minConfidence,
        skip_if_committed=payload.skipIfCommitted,
    )
    if not result.get("ok") and result.get("needsProva"):
        raise HTTPException(400, result.get("message") or "Sem prova no disco")
    if result.get("committed") and result.get("ok"):
        try:
            result["rag"] = index_all_questions()
        except Exception as exc:
            result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        if payload.commit and int(result.get("inserted") or 0) > 0:
            result["professor"] = fill_professor_drafts(
                limit=max(40, int(result.get("inserted") or 20)),
                prefer_uema=True,
            )
    return result

@router.post("/api/ingest/classify-pending")
def api_ingest_classify_pending() -> dict[str, Any]:
    """Reclassifica tópicos fracos, oficiais Natureza/Humanas e cross-domain (Ciclo X/Y/K)."""
    from ingest_pdf import refine_natureza_subject
    from services_core import is_cross_domain, is_official_source, official_curation_inventory

    updated = 0
    subject_changed = 0
    cross_fixed = 0
    n_candidates = 0
    with db() as conn:
        rows = conn.execute(
            """
            SELECT id, subject, topic, subtopic, statement, options_json, source, generated, exam_board
            FROM questions
            WHERE topic='A classificar'
               OR subject IN ('Geral', 'Ciências da Natureza', 'A classificar', 'Matemática')
               OR (
                    COALESCE(generated,0)=0
                    AND (
                        LOWER(COALESCE(source,'')) LIKE '%pdf%'
                        OR LOWER(COALESCE(source,'')) LIKE '%ingest%'
                        OR LOWER(COALESCE(source,'')) LIKE '%oficial%'
                        OR UPPER(COALESCE(exam_board,'TREINO'))='UEMA_PAES'
                    )
               )
            """
        ).fetchall()
        by_id: dict[str, Any] = {}
        for row in rows:
            by_id[str(row["id"])] = row
        questions = []
        for row in by_id.values():
            questions.append(
                {
                    "id": row["id"],
                    "subject": row["subject"],
                    "topic": row["topic"],
                    "subtopic": row["subtopic"],
                    "statement": row["statement"],
                    "options": json.loads(row["options_json"] or "[]"),
                    "_force": is_cross_domain(row["subject"], row["topic"])
                    or (
                        (row["subject"] or "") in ("Biologia", "Química", "Física")
                        and is_official_source(row["source"], row["generated"])
                    ),
                }
            )
        n_candidates = len(questions)
        classified = classify_questions_by_syllabus(questions)
        humanas = {
            "História",
            "Geografia",
            "Filosofia",
            "Sociologia",
            "Língua Portuguesa e Literatura",
            "Linguagens",
        }
        natureza = {"Biologia", "Química", "Física"}
        topic_to_nat = {
            "cinemática": "Física",
            "cinematica": "Física",
            "dinâmica": "Física",
            "dinamica": "Física",
            "óptica": "Física",
            "optica": "Física",
            "eletromagnetismo": "Física",
            "termodinâmica": "Física",
            "estequiometria": "Química",
            "equilibrio quimico": "Química",
            "equilíbrio químico": "Química",
            "cinética química": "Química",
            "genetica": "Biologia",
            "genética": "Biologia",
            "ecologia": "Biologia",
            "citologia": "Biologia",
        }
        for original, question in zip(questions, classified, strict=False):
            new_subj = question.get("subject")
            new_topic = question.get("topic")
            if (new_subj or "") in humanas and is_cross_domain(new_subj, new_topic):
                tl = (new_topic or "").lower()
                forced = None
                for key, sub in topic_to_nat.items():
                    if key in tl:
                        forced = sub
                        break
                if not forced:
                    refined = refine_natureza_subject(
                        str(original.get("statement") or ""),
                        list(original.get("options") or []),
                        "Ciências da Natureza",
                    )
                    if refined in natureza:
                        forced = refined
                if forced:
                    new_subj = forced
                    question["subject"] = forced
                    cross_fixed += 1
            if (new_subj or "") in natureza and is_cross_domain(new_subj, new_topic):
                new_topic = f"Conceitos de {new_subj}"
                question["topic"] = new_topic
                cross_fixed += 1
            if new_topic == "A classificar" and new_subj == original.get("subject"):
                if not original.get("_force"):
                    continue
            if (
                new_subj != original.get("subject")
                or new_topic != original.get("topic")
                or question.get("subtopic") != original.get("subtopic")
            ):
                conn.execute(
                    "UPDATE questions SET subject=?, topic=?, subtopic=?, syllabus_id=? WHERE id=?",
                    (
                        new_subj,
                        new_topic,
                        question.get("subtopic"),
                        question.get("syllabusId"),
                        question["id"],
                    ),
                )
                updated += 1
                if new_subj != original.get("subject"):
                    subject_changed += 1
        conn.commit()

    inv = official_curation_inventory()
    residual = int(inv.get("crossDomainCount") or 0)
    residual_sample = (inv.get("crossDomainSample") or [])[:8]
    bank_export: dict[str, Any] = {"ok": False}
    try:
        profile = bank_profile()
        bank_export = {
            "ok": True,
            "officialYears": profile.get("yearsUsed") or profile.get("years"),
            "topicCount": len(profile.get("topicFrequency") or profile.get("topics") or []),
        }
    except Exception:  # noqa: BLE001
        bank_export = {"ok": False}

    return {
        "ok": True,
        "candidates": n_candidates,
        "updated": updated,
        "subjectChanged": subject_changed,
        "crossDomainFixed": cross_fixed,
        "residualCrossDomain": residual,
        "residualSample": residual_sample,
        "bySubject": inv.get("bySubject"),
        "bankProfile": bank_export,
        "message": (
            f"Reclassificados {updated} · assuntos de áreas misturadas corrigidos {cross_fixed} · restantes {residual}."
        ),
        "disclaimer": "Relatório da base local — não inventa incidência UEMA.",
    }

@router.post("/api/ingest/apply-gabarito")
def api_ingest_apply_gabarito(payload: ApplyGabaritoRequest) -> dict[str, Any]:
    candidates = [
        item for item in list_pdf_inventory()
        if item["kind"] == "gabarito" and item.get("year") == payload.year
    ]
    if not candidates:
        raise HTTPException(404, f"Gabarito de {payload.year} não encontrado.")
    gabarito = parse_gabarito(extract_pdf_text(Path(candidates[-1]["path"])))
    if not gabarito:
        raise HTTPException(422, "Não foi possível identificar respostas A–E no gabarito.")
    with db() as conn:
        rows = conn.execute(
            """
            SELECT id, source, correct_index FROM questions
            WHERE year=? AND generated=0
              AND (LOWER(COALESCE(source,'')) LIKE '%pdf%' OR LOWER(COALESCE(source,'')) LIKE '%ingest%' OR LOWER(COALESCE(source,'')) LIKE '%oficial%')
            ORDER BY id
            """,
            (payload.year,),
        ).fetchall()
        questions = [
            {"id": r["id"], "number": int((r["source"] or "0_0").rsplit("_", 1)[-1]) if (r["source"] or "").rsplit("_", 1)[-1].isdigit() else index}
            for index, r in enumerate(rows, start=1)
        ]
        merged = apply_gabarito(questions, gabarito)
        updated = 0
        for question in merged:
            if question.get("gabaritoApplied"):
                conn.execute("UPDATE questions SET correct_index=? WHERE id=?", (question["correctIndex"], question["id"]))
                updated += 1
        conn.commit()
    return {"ok": True, "year": payload.year, "answersFound": len(gabarito), "updated": updated}

@router.post("/api/ingest/preview/update")
def api_ingest_preview_update(payload: UpdatePreviewRequest) -> dict[str, Any]:
    result = update_preview(payload.previewId, payload.questions)
    if not result.get("ok"):
        raise HTTPException(400, result.get("message", "Update falhou"))
    return result

@router.get("/api/ingest/preview/{preview_id}")
def api_ingest_preview_get(preview_id: str) -> dict[str, Any]:
    data = get_preview(preview_id)
    if not data:
        raise HTTPException(404, "Preview não encontrado")
    return data

@router.get("/api/acervo/manifest")
def api_acervo_manifest() -> dict[str, Any]:
    from acervo_fetch import manifest_with_local

    return manifest_with_local()

@router.post("/api/acervo/fetch-year")
def api_acervo_fetch_year(payload: AcervoFetchRequest) -> dict[str, Any]:
    from acervo_fetch import fetch_year

    return fetch_year(payload.year, dry_run=payload.dryRun, overwrite=payload.overwrite)

@router.post("/api/acervo/fetch-available")
def api_acervo_fetch_available(payload: AcervoFetchAvailableRequest) -> dict[str, Any]:
    from acervo_fetch import fetch_available

    return fetch_available(dry_run=payload.dryRun, overwrite=payload.overwrite)

@router.post("/api/acervo/bootstrap-year")
def api_acervo_bootstrap_year(payload: AcervoBootstrapRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_year

    result = bootstrap_year(dry_run=payload.dryRun, overwrite=payload.overwrite, year=payload.year)
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "A preparação do acervo falhou")
    return result

@router.post("/api/acervo/bootstrap-and-commit")
def api_acervo_bootstrap_and_commit(payload: AcervoBootstrapCommitRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_and_commit

    result = bootstrap_and_commit(
        dry_run=payload.dryRun,
        overwrite=payload.overwrite,
        year=payload.year,
        min_confidence=payload.minConfidence,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "Bootstrap+commit falhou")
    return result

@router.post("/api/acervo/bootstrap-and-commit-available")
def api_acervo_bootstrap_and_commit_available(payload: AcervoBatchCommitRequest) -> dict[str, Any]:
    from acervo_fetch import bootstrap_and_commit_available

    result = bootstrap_and_commit_available(
        dry_run=payload.dryRun,
        overwrite=payload.overwrite,
        min_confidence=payload.minConfidence,
        skip_committed=payload.skipCommitted,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun:
        raise HTTPException(400, result.get("message") or result.get("error") or "Lote found falhou")
    return result

@router.post("/api/acervo/commit-on-disk")
def api_acervo_commit_on_disk(payload: AcervoCommitOnDiskRequest) -> dict[str, Any]:
    from acervo_fetch import commit_on_disk

    result = commit_on_disk(
        dry_run=payload.dryRun,
        min_confidence=payload.minConfidence,
        skip_committed=payload.skipCommitted,
        auto_professor=payload.autoProfessor,
    )
    if not result.get("ok") and not payload.dryRun and (result.get("years") or []):
        failed = [y for y in (result.get("years") or []) if not y.get("ok") and not y.get("skipped")]
        if failed and result.get("insertedTotal", 0) == 0:
            raise HTTPException(400, result.get("message") or "Commit no disco falhou")
    return result

@router.post("/api/acervo/import-all-complete")
def api_acervo_import_all_complete(payload: AcervoImportAllCompleteRequest) -> dict[str, Any]:
    """Importa todos os anos com prova+gab no disco (Ciclo HK)."""
    from acervo_fetch import import_all_complete

    result = import_all_complete(
        min_confidence=payload.minConfidence,
        skip_if_committed=payload.skipIfCommitted,
        classify_after=payload.classifyAfter,
    )
    if payload.classifyAfter and int(result.get("insertedTotal") or 0) > 0:
        try:
            result["classified"] = api_ingest_classify_pending()
        except Exception as exc:  # noqa: BLE001
            result["classified"] = {"ok": False, "error": str(exc)}
    if int(result.get("insertedTotal") or 0) > 0:
        try:
            result["rag"] = index_all_questions()
        except Exception as exc:  # noqa: BLE001
            result["rag"] = {"ok": False, "message": f"Reindex pendente: {type(exc).__name__}"}
        try:
            result["professor"] = fill_professor_drafts(
                limit=max(40, int(result.get("insertedTotal") or 20)),
                prefer_uema=True,
            )
        except Exception as exc:  # noqa: BLE001
            result["professor"] = {"ok": False, "error": str(exc)}
    return result

@router.post("/api/acervo/parse-gate")
def api_parse_gate(payload: ParseGateRequest) -> dict[str, Any]:
    return parse_gate_flags(year_health=payload.yearHealth, pending=payload.pending)

@router.post("/api/acervo/natureza-pack")
def api_natureza_pack(limit: int = 12, year: int | None = None) -> dict[str, Any]:
    return create_natureza_pack(limit=limit, year=year)
