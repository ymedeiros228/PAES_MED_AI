"""Rotas: midia."""

from __future__ import annotations

import json
from typing import Any

from fastapi import (
    APIRouter,
    File,
    HTTPException,
    UploadFile,
)

from api_helpers import (
    _ask_openai,
    _openai_client,
    _save_upload,
)
from db import DATA_DIR
from schemas import (
    LessonTextRequest,
    MediaMarkReadPayload,
    MediaOpenPayload,
    MediaPrefsPayload,
)
from services_extra import (
    list_lessons,
    structure_lesson_from_text,
)
from services_media import (
    list_media_opens,
    list_media_reads,
    list_topic_articles,
    list_topic_videos,
    mark_media_read,
    media_prefs,
    open_media_url,
    serper_configured,
    set_media_prefs,
    youtube_configured,
)

router = APIRouter(tags=["midia"])


@router.post("/api/lessons/from-text")
def api_lessons_from_text(payload: LessonTextRequest) -> dict[str, Any]:
    llm_payload = None
    client = _openai_client()
    if client is not None:
        prompt = (
            "Estruture a aula em JSON com chaves: subject, topic, difficulty, summary, "
            "macetes (lista), keywords (lista), flashcards (lista de {front,back}), "
            "questions (lista de enunciados curtos). Foque no PAES/UEMA. Texto:\n"
            + payload.transcript[:12000]
        )
        raw = _ask_openai(
            "Você organiza aulas para o PAES/UEMA. Responda SÓ JSON válido.",
            prompt,
        )
        try:
            start = raw.find("{")
            end = raw.rfind("}") + 1
            llm_payload = json.loads(raw[start:end])
        except Exception:
            llm_payload = None
    return structure_lesson_from_text(
        payload.title,
        payload.transcript,
        payload.sourceType,
        payload.sourceRef,
        llm_payload,
    )

@router.post("/api/lessons/from-audio")
async def api_lessons_from_audio(
    title: str = "Aula importada",
    file: UploadFile = File(...),
) -> dict[str, Any]:
    """Transcreve com Whisper (OpenAI) se houver chave; senão orienta colar legenda."""
    dest = await _save_upload(file, DATA_DIR / "aulas", f"audio_{title}.bin")

    client = _openai_client()
    if client is None:
        return {
            "ok": False,
            "savedPath": str(dest),
            "message": (
                "Áudio salvo. Sem OPENAI_API_KEY não há Whisper. "
                "Cole a legenda/transcrição em /api/lessons/from-text."
            ),
        }
    try:
        with dest.open("rb") as audio_f:
            tr = client.audio.transcriptions.create(model="whisper-1", file=audio_f)
        transcript = getattr(tr, "text", None) or str(tr)
    except Exception as exc:
        raise HTTPException(502, f"Falha Whisper: {type(exc).__name__}") from exc

    return structure_lesson_from_text(title, transcript, "audio", str(dest), None)

@router.get("/api/lessons")
def api_lessons() -> list[dict[str, Any]]:
    return list_lessons()

@router.get("/api/media/videos")
def api_media_videos(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Vídeos de reforço do tópico (catálogo local + YouTube opcional)."""
    return list_topic_videos(subject, topic)

@router.get("/api/media/articles")
def api_media_articles(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Artigos/leituras de reforço do tópico (catálogo local + Serper opcional)."""
    return list_topic_articles(subject, topic)

@router.post("/api/media/open")
def api_media_open(payload: MediaOpenPayload) -> dict[str, Any]:
    out = open_media_url(
        payload.url,
        kind=payload.kind,
        subject=payload.subject,
        topic=payload.topic,
        title=payload.title,
    )
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "Não foi possível abrir")
    return out

@router.get("/api/media/opens")
def api_media_opens(limit: int = 20) -> dict[str, Any]:
    """Histórico local de aberturas de mídia (não é progresso de banca)."""
    return list_media_opens(limit=limit)

@router.post("/api/media/mark-read")
def api_media_mark_read(payload: MediaMarkReadPayload) -> dict[str, Any]:
    out = mark_media_read(
        payload.url,
        subject=payload.subject,
        topic=payload.topic,
        title=payload.title,
    )
    if not out.get("ok"):
        raise HTTPException(400, out.get("message") or "Não foi possível marcar")
    return out

@router.get("/api/media/reads")
def api_media_reads(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    """Leituras de reforço marcadas localmente (não é edital/oficial)."""
    return list_media_reads(subject, topic)

@router.get("/api/media/prefs")
def api_media_prefs_get() -> dict[str, Any]:
    return {
        "ok": True,
        **media_prefs(),
        "youtubeConfigured": youtube_configured(),
        "serperConfigured": serper_configured(),
    }

@router.post("/api/media/prefs")
def api_media_prefs_set(payload: MediaPrefsPayload) -> dict[str, Any]:
    return set_media_prefs(
        suggest_videos=payload.suggestVideos,
        suggest_articles=payload.suggestArticles,
    )
