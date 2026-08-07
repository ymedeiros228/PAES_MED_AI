"""Mídia de reforço (vídeos + artigos) — catálogo local + APIs opcionais (AY–BF)."""

from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from db import DATA_DIR, connect, loads_json

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY", "").strip()
SERPER_API_KEY = os.getenv("SERPER_API_KEY", "").strip()
VIDEO_CACHE_TTL_H = 48
ARTICLE_CACHE_TTL_H = 48

DISCLAIMER_VIDEO = (
    "Vídeos de reforço (não oficiais da banca UEMA). "
    "Não contam como edital nem como prova oficial."
)
DISCLAIMER_ARTICLE = (
    "Leituras de reforço (não oficiais da banca UEMA). "
    "Não contam como edital nem como prova oficial."
)

_YT_HOSTS = frozenset(
    {
        "youtube.com",
        "www.youtube.com",
        "m.youtube.com",
        "youtu.be",
        "www.youtu.be",
    }
)

ESSAY_PERSONAS: list[dict[str, Any]] = [
    {
        "id": "cohesion_revisor",
        "label": "Revisor de coesão",
        "focusAxis": "cohesion",
        "hint": "Conectivos, referenciação e progressão.",
    },
    {
        "id": "argument_critic",
        "label": "Crítico de argumento",
        "focusAxis": "argumentation",
        "hint": "Tese, repertório e encadeamento.",
    },
    {
        "id": "timed_reader",
        "label": "Leitor de tempo de prova",
        "focusAxis": "coherence",
        "hint": "Clareza sob pressão; priorize o essencial.",
    },
    {
        "id": "grammar_coach",
        "label": "Coach de gramática",
        "focusAxis": "grammar",
        "hint": "Concordância, regência e pontuação.",
    },
    {
        "id": "intervention_mentor",
        "label": "Mentor de intervenção",
        "focusAxis": "intervention",
        "hint": "Proposta com agente, meio e efeito.",
    },
]


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
            (key, json.dumps(value, ensure_ascii=False) if not isinstance(value, str) else value),
        )
        conn.commit()
    finally:
        conn.close()


def media_prefs() -> dict[str, Any]:
    raw = _settings_get("media_prefs", {}) or {}
    if not isinstance(raw, dict):
        raw = {}
    videos = raw.get("suggestVideos")
    articles = raw.get("suggestArticles")
    if videos is None:
        videos = True
    if articles is None:
        articles = True
    preferred = str(raw.get("preferredLane") or "all").strip().lower()
    if preferred not in {"all", "bank", "video", "article", "search"}:
        preferred = "all"
    return {
        "suggestVideos": bool(videos),
        "suggestArticles": bool(articles),
        "preferredLane": preferred,
    }


def set_media_prefs(
    *,
    suggest_videos: bool | None = None,
    suggest_articles: bool | None = None,
    preferred_lane: str | None = None,
) -> dict[str, Any]:
    cur = media_prefs()
    if suggest_videos is not None:
        cur["suggestVideos"] = bool(suggest_videos)
    if suggest_articles is not None:
        cur["suggestArticles"] = bool(suggest_articles)
    if preferred_lane is not None:
        p = str(preferred_lane).strip().lower()
        if p in {"all", "bank", "video", "article", "search"}:
            cur["preferredLane"] = p
    _settings_set("media_prefs", cur)
    return {"ok": True, **cur}


def youtube_configured() -> bool:
    return bool(YOUTUBE_API_KEY and YOUTUBE_API_KEY not in {"cole_sua_chave_aqui", "changeme"})


def serper_configured() -> bool:
    return bool(SERPER_API_KEY and SERPER_API_KEY not in {"cole_sua_chave_aqui", "changeme"})


def _topic_key(subject: str | None, topic: str | None) -> str:
    return f"{(subject or '').strip()}::{(topic or '').strip()}"


def _load_json_catalog(name: str) -> dict[str, Any]:
    path = DATA_DIR / "media" / name
    if not path.exists():
        return {"topics": {}}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return data
    except Exception:  # noqa: BLE001
        pass
    return {"topics": {}}


def _match_catalog_items(
    catalog_name: str,
    subject: str | None,
    topic: str | None,
    *,
    source_tag: str,
    title_key: str = "title",
    extra_label_key: str = "channel",
) -> list[dict[str, Any]]:
    cat = _load_json_catalog(catalog_name)
    topics = cat.get("topics") if isinstance(cat.get("topics"), dict) else {}
    key = _topic_key(subject, topic)
    items: list[dict[str, Any]] = []

    def _normalize(raw: dict[str, Any]) -> dict[str, Any] | None:
        url = str(raw.get("url") or "").strip()
        if not url:
            return None
        kind = str(raw.get("kind") or "").strip()
        out = {
            "title": raw.get(title_key) or raw.get("title") or "Item",
            "channel": raw.get("channel") or raw.get("source") or "",
            "source": raw.get("source") or raw.get("channel") or source_tag,
            "url": url,
            "snippet": raw.get("snippet"),
            "thumb": raw.get("thumb"),
            "origin": source_tag,
        }
        if kind:
            out["kind"] = kind
        return out

    if key in topics and isinstance(topics[key], list):
        for raw in topics[key]:
            if isinstance(raw, dict):
                n = _normalize(raw)
                if n:
                    items.append(n)
        if items:
            return items[:8]

    # Fuzzy token match
    tokens = [t.lower() for t in f"{subject or ''} {topic or ''}".split() if len(t) > 2]
    scored: list[tuple[int, list[dict[str, Any]]]] = []
    if tokens:
        for tkey, arr in topics.items():
            if not isinstance(arr, list):
                continue
            low = str(tkey).lower()
            sc = sum(1 for tok in tokens if tok in low)
            if not sc:
                continue
            cleaned: list[dict[str, Any]] = []
            for raw in arr:
                if isinstance(raw, dict):
                    n = _normalize(raw)
                    if n:
                        cleaned.append(n)
            if cleaned:
                scored.append((sc, cleaned))
        scored.sort(key=lambda x: -x[0])
        if scored:
            return scored[0][1][:8]

    # Fallback: qualquer tópico da mesma disciplina no catálogo
    sub = (subject or "").strip().lower()
    if sub:
        for tkey, arr in topics.items():
            if not isinstance(arr, list):
                continue
            if not str(tkey).lower().startswith(sub + "::"):
                continue
            for raw in arr:
                if isinstance(raw, dict):
                    n = _normalize(raw)
                    if n:
                        items.append(n)
            if items:
                return items[:8]

    # Fallback genérico do catálogo (chave __default__)
    default = topics.get("__default__")
    if isinstance(default, list):
        for raw in default:
            if isinstance(raw, dict):
                n = _normalize(raw)
                if n:
                    items.append(n)
        if items:
            return items[:8]
    return []


def _cache_get(store_key: str, entry_key: str, ttl_h: int) -> list[dict[str, Any]] | None:
    cache = _settings_get(store_key, {}) or {}
    if not isinstance(cache, dict):
        return None
    entry = cache.get(entry_key)
    if not isinstance(entry, dict):
        return None
    at = entry.get("at")
    try:
        ts = datetime.fromisoformat(str(at))
    except Exception:  # noqa: BLE001
        return None
    if datetime.now() - ts > timedelta(hours=ttl_h):
        return None
    items = entry.get("items")
    return items if isinstance(items, list) else None


def _cache_set(store_key: str, entry_key: str, items: list[dict[str, Any]], max_keys: int = 40) -> None:
    cache = _settings_get(store_key, {}) or {}
    if not isinstance(cache, dict):
        cache = {}
    cache[entry_key] = {"at": datetime.now().isoformat(timespec="seconds"), "items": items}
    if len(cache) > max_keys:
        keys = sorted(cache.keys(), key=lambda k: str((cache.get(k) or {}).get("at") or ""))
        for k in keys[: max(0, len(cache) - max_keys)]:
            cache.pop(k, None)
    _settings_set(store_key, cache)


def _youtube_search(subject: str | None, topic: str | None, limit: int = 5) -> list[dict[str, Any]]:
    if not youtube_configured():
        return []
    q = f"{subject or ''} {topic or ''} ENEM Natureza".strip()
    cache_key = f"yt::{_topic_key(subject, topic)}"
    cached = _cache_get("video_cache", cache_key, VIDEO_CACHE_TTL_H)
    if cached is not None:
        return cached[:limit]
    params = urllib.parse.urlencode(
        {
            "part": "snippet",
            "type": "video",
            "maxResults": str(max(1, min(limit, 8))),
            "q": q,
            "key": YOUTUBE_API_KEY,
            "safeSearch": "strict",
            "relevanceLanguage": "pt",
        }
    )
    url = f"https://www.googleapis.com/youtube/v3/search?{params}"
    try:
        with urllib.request.urlopen(url, timeout=8) as resp:  # noqa: S310
            payload = json.loads(resp.read().decode("utf-8", errors="ignore"))
    except Exception:  # noqa: BLE001
        return []
    out: list[dict[str, Any]] = []
    for it in payload.get("items") or []:
        if not isinstance(it, dict):
            continue
        vid = ((it.get("id") or {}) if isinstance(it.get("id"), dict) else {}).get("videoId")
        snip = it.get("snippet") if isinstance(it.get("snippet"), dict) else {}
        if not vid:
            continue
        thumbs = snip.get("thumbnails") if isinstance(snip.get("thumbnails"), dict) else {}
        def_th = thumbs.get("default") if isinstance(thumbs.get("default"), dict) else {}
        out.append(
            {
                "title": snip.get("title") or "Vídeo",
                "channel": snip.get("channelTitle") or "",
                "source": snip.get("channelTitle") or "youtube",
                "url": f"https://www.youtube.com/watch?v={vid}",
                "thumb": def_th.get("url"),
                "origin": "youtube",
            }
        )
    _cache_set("video_cache", cache_key, out)
    return out[:limit]


def _serper_search(subject: str | None, topic: str | None, limit: int = 5) -> list[dict[str, Any]]:
    if not serper_configured():
        return []
    q = f"{subject or ''} {topic or ''} site:pt.wikipedia.org OR educação".strip()
    cache_key = f"serper::{_topic_key(subject, topic)}"
    cached = _cache_get("article_cache", cache_key, ARTICLE_CACHE_TTL_H)
    if cached is not None:
        return cached[:limit]
    body = json.dumps({"q": q, "gl": "br", "hl": "pt-br", "num": max(1, min(limit, 8))}).encode("utf-8")
    req = urllib.request.Request(
        "https://google.serper.dev/search",
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-API-KEY": SERPER_API_KEY,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:  # noqa: S310
            payload = json.loads(resp.read().decode("utf-8", errors="ignore"))
    except Exception:  # noqa: BLE001
        return []
    out: list[dict[str, Any]] = []
    for it in payload.get("organic") or []:
        if not isinstance(it, dict):
            continue
        link = str(it.get("link") or "").strip()
        if not link or not _host_allowed_for_article(urlparse(link).hostname or ""):
            continue
        out.append(
            {
                "title": it.get("title") or "Leitura",
                "channel": it.get("source") or urlparse(link).hostname or "",
                "source": it.get("source") or urlparse(link).hostname or "web",
                "url": link,
                "snippet": it.get("snippet"),
                "origin": "serper",
            }
        )
        if len(out) >= limit:
            break
    _cache_set("article_cache", cache_key, out)
    return out[:limit]


def youtube_search_url(subject: str | None, topic: str | None, *, accent: str = "ENEM PAES") -> str:
    q = f"{(subject or '').strip()} {(topic or '').strip()} {accent}".strip()
    return "https://www.youtube.com/results?" + urllib.parse.urlencode({"search_query": q})


def wikipedia_search_url(subject: str | None, topic: str | None) -> str:
    q = f"{(subject or '').strip()} {(topic or '').strip()}".strip()
    return "https://pt.wikipedia.org/w/index.php?" + urllib.parse.urlencode({"search": q})


def list_material_search_actions(subject: str | None, topic: str | None) -> list[dict[str, Any]]:
    """Ações de busca aberta — usuário escolhe o material (não inventa conteúdo)."""
    sub = (subject or "").strip() or "assunto"
    top = (topic or "").strip() or "tópico"
    return [
        {
            "id": "yt_search",
            "kind": "youtube_search",
            "label": f"Buscar vídeos no YouTube · {top}",
            "title": f"YouTube: {sub} · {top}",
            "channel": "YouTube · busca",
            "source": "youtube_search",
            "url": youtube_search_url(subject, topic, accent="ENEM Natureza vestibulares"),
            "origin": "youtube_search",
            "snippet": "Abre a busca; você escolhe o vídeo. Não é banca UEMA.",
        },
        {
            "id": "yt_search_paes",
            "kind": "youtube_search",
            "label": f"Buscar no YouTube · PAES / UEMA · {top}",
            "title": f"YouTube PAES: {sub} · {top}",
            "channel": "YouTube · busca",
            "source": "youtube_search",
            "url": youtube_search_url(subject, topic, accent="PAES UEMA vestibular Maranhão"),
            "origin": "youtube_search",
            "snippet": "Busca estreita a prova regional. Reforço — não inventa edital.",
        },
        {
            "id": "wiki_search",
            "kind": "article_search",
            "label": f"Buscar leitura · Wikipédia · {top}",
            "title": f"Wikipédia: {sub} · {top}",
            "channel": "Wikipédia · busca",
            "source": "wikipedia_search",
            "url": wikipedia_search_url(subject, topic),
            "origin": "wikipedia_search",
            "snippet": "Abre a busca na Wikipédia PT; você escolhe o artigo.",
        },
    ]


def list_topic_videos(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    prefs = media_prefs()
    search_actions = list_material_search_actions(subject, topic)
    yt_actions = [a for a in search_actions if a.get("kind") == "youtube_search"]
    if not prefs.get("suggestVideos", True):
        return {
            "ok": True,
            "subject": subject,
            "topic": topic,
            "items": [],
            "count": 0,
            "searchActions": yt_actions,
            "basis": "off",
            "disclaimer": DISCLAIMER_VIDEO,
            "note": "Sugestão de vídeos desligada em Ajustes · Avançado. Ainda pode buscar no YouTube.",
            "youtubeConfigured": youtube_configured(),
        }

    yt = _youtube_search(subject, topic, limit=6)
    cat = _match_catalog_items("videos_catalog.json", subject, topic, source_tag="catalogo_local")
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    # Catálogo local primeiro (estável), depois API YouTube se houver chave
    for src in cat + yt:
        u = (src.get("url") or "").strip()
        if not u or u in seen:
            continue
        seen.add(u)
        items.append(src)
        if len(items) >= 8:
            break

    if yt and cat:
        basis = "misto"
    elif yt:
        basis = "youtube"
    elif cat:
        basis = "catalogo_local"
    else:
        basis = "busca_aberta"

    # Sempre inclui ações de busca YouTube como itens clicáveis se a lista
    # ainda está fraca — o aluno escolhe o vídeo (não inventamos conteúdo).
    if len(items) < 2:
        for a in yt_actions:
            u = (a.get("url") or "").strip()
            if not u or u in seen:
                continue
            seen.add(u)
            items.append(
                {
                    "title": a.get("title") or a.get("label") or "Buscar no YouTube",
                    "channel": a.get("channel") or "YouTube · busca",
                    "source": a.get("source") or "youtube_search",
                    "url": u,
                    "snippet": a.get("snippet"),
                    "origin": "youtube_search",
                    "kind": "youtube_search",
                }
            )
            if len(items) >= 6:
                break

    note = None
    if not items:
        note = (
            f"Sem vídeo catalogado fixo para {subject or '—'} · {topic or '—'}. "
            "Use Buscar no YouTube (você escolhe o link). "
            "Com YOUTUBE_API_KEY no .env a busca automática enriquece a lista."
        )
    elif basis == "busca_aberta":
        note = (
            "Sem catálogo fixo deste tópico — use os botões de busca YouTube abaixo. "
            "Opcional: YOUTUBE_API_KEY no .env para trazer links da API."
        )

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "items": items,
        "count": len(items),
        "searchActions": yt_actions,
        "basis": basis,
        "disclaimer": DISCLAIMER_VIDEO,
        "note": note,
        "youtubeConfigured": youtube_configured(),
    }


def list_topic_articles(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    prefs = media_prefs()
    search_actions = [a for a in list_material_search_actions(subject, topic) if a.get("kind") == "article_search"]
    if not prefs.get("suggestArticles", True):
        return {
            "ok": True,
            "subject": subject,
            "topic": topic,
            "items": [],
            "count": 0,
            "searchActions": search_actions,
            "basis": "off",
            "disclaimer": DISCLAIMER_ARTICLE,
            "note": "Sugestão de artigos desligada em Ajustes · Avançado. Ainda pode buscar na Wikipédia.",
            "serperConfigured": serper_configured(),
        }

    web = _serper_search(subject, topic, limit=6)
    cat = _match_catalog_items("articles_catalog.json", subject, topic, source_tag="catalogo_local")
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    for src in cat + web:
        u = (src.get("url") or "").strip()
        if not u or u in seen:
            continue
        seen.add(u)
        items.append(src)
        if len(items) >= 8:
            break

    if web and cat:
        basis = "misto"
    elif web:
        basis = "serper"
    elif cat:
        basis = "catalogo_local"
    else:
        basis = "busca_aberta"

    if len(items) < 2:
        for a in search_actions:
            u = (a.get("url") or "").strip()
            if not u or u in seen:
                continue
            seen.add(u)
            items.append(
                {
                    "title": a.get("title") or a.get("label") or "Buscar na Wikipédia",
                    "channel": a.get("channel") or "Wikipédia · busca",
                    "source": a.get("source") or "wikipedia_search",
                    "url": u,
                    "snippet": a.get("snippet"),
                    "origin": "wikipedia_search",
                    "kind": "article_search",
                }
            )
            if len(items) >= 5:
                break

    note = None
    if not items:
        note = (
            f"Sem artigo catalogado fixo para {subject or '—'} · {topic or '—'}. "
            "Use Buscar na Wikipédia (você escolhe). "
            "Com SERPER_API_KEY no .env a busca web enriquece a lista."
        )
    elif basis == "busca_aberta":
        note = "Sem artigo fixo deste tópico — use a busca Wikipédia (você escolhe o texto)."

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "items": items,
        "count": len(items),
        "searchActions": search_actions,
        "basis": basis,
        "disclaimer": DISCLAIMER_ARTICLE,
        "note": note,
        "serperConfigured": serper_configured(),
    }


def study_materials_pack(
    *,
    subject: str | None,
    topic: str | None,
    bank_items: list[dict[str, Any]] | None = None,
    bank_note: str | None = None,
    bank_disclaimer: str | None = None,
) -> dict[str, Any]:
    """Pacote unificado: banca/local + vídeos + leituras + buscas (escolha do aluno)."""
    # TTL curto: evita double-fetch quando lista e ficha pedem o mesmo pack.
    cache_key = None
    if bank_items is None:
        try:
            import time as _time
            from services_extra import _PACK_TTL_S, _pack_cache

            cache_key = f"{(subject or '').strip().lower()}::{(topic or '').strip().lower()}"
            hit = _pack_cache.get(cache_key)
            if hit:
                t0, val = hit
                if (_time.monotonic() - float(t0)) < float(_PACK_TTL_S):
                    return val
        except Exception:
            cache_key = None
    videos = list_topic_videos(subject, topic)
    articles = list_topic_articles(subject, topic)
    searches = list_material_search_actions(subject, topic)
    bank = list(bank_items or [])
    preferred = media_prefs().get("preferredLane") or "all"
    if preferred not in {"all", "bank", "video", "article", "search"}:
        preferred = "all"
    lanes = [
        {
            "id": "bank",
            "label": "Banca / material local",
            "hint": "Edital, trechos e PDFs no PC — sem inventar oficial ausente",
            "count": len(bank),
            "items": bank,
            "disclaimer": bank_disclaimer
            or "Só o que existe no disco ou trechos locais; não é inventar gabarito.",
            "note": bank_note,
        },
        {
            "id": "video",
            "label": "Vídeos de reforço",
            "hint": "Catálogo local + YouTube (API opcional)",
            "count": int(videos.get("count") or 0),
            "items": videos.get("items") or [],
            "searchActions": videos.get("searchActions") or [],
            "disclaimer": videos.get("disclaimer"),
            "note": videos.get("note"),
            "basis": videos.get("basis"),
            "youtubeConfigured": videos.get("youtubeConfigured"),
        },
        {
            "id": "article",
            "label": "Leituras de reforço",
            "hint": "Catálogo + Wikipédia / Serper opcional",
            "count": int(articles.get("count") or 0),
            "items": articles.get("items") or [],
            "searchActions": articles.get("searchActions") or [],
            "disclaimer": articles.get("disclaimer"),
            "note": articles.get("note"),
            "basis": articles.get("basis"),
            "serperConfigured": articles.get("serperConfigured"),
        },
        {
            "id": "search",
            "label": "Buscar na web",
            "hint": "Abrir busca e escolher o material",
            "count": len(searches),
            "items": searches,
            "disclaimer": "Você escolhe o que estudiar. Reforço — não banca UEMA.",
            "note": None,
        },
    ]
    total = sum(int(l.get("count") or 0) for l in lanes if l["id"] != "search")
    # Sugere vídeo se não há banca local e há reforço em vídeo
    suggested = "all"
    if not bank and int(videos.get("count") or 0) > 0:
        suggested = "video"
    elif bank and int(videos.get("count") or 0) == 0 and int(articles.get("count") or 0) > 0:
        suggested = "article"
    out = {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "preferredLane": preferred,
        "suggestedLane": suggested,
        "lanes": lanes,
        "totalItems": total,
        "searchActions": searches,
        "youtubeConfigured": youtube_configured(),
        "serperConfigured": serper_configured(),
        "disclaimer": (
            "Escolha o material: local (banca no PC), vídeo, leitura ou busca. "
            "Nada aqui é gabarito oficial inventado pela IA."
        ),
    }
    if cache_key is not None:
        try:
            import time as _time
            from services_extra import _pack_cache

            _pack_cache[cache_key] = (_time.monotonic(), out)
        except Exception:
            pass
    return out


def _host_allowed_for_youtube(host: str) -> bool:
    return host.lower() in _YT_HOSTS


def _host_allowed_for_article(host: str) -> bool:
    h = (host or "").lower().strip(".")
    if not h:
        return False
    if h in {"wikipedia.org", "scielo.br", "khanacademy.org"}:
        return True
    if h.endswith(".wikipedia.org") or h.endswith(".scielo.br") or h.endswith(".khanacademy.org"):
        return True
    if h.endswith(".gov.br") or h == "gov.br":
        return True
    if h.endswith(".edu.br") or h.endswith(".edu") or h == "edu" or h == "edu.br":
        return True
    return False


def _append_media_open(entry: dict[str, Any], limit: int = 30) -> None:
    raw = _settings_get("media_opens", []) or []
    if not isinstance(raw, list):
        raw = []
    cleaned = [e for e in raw if isinstance(e, dict)]
    cleaned.insert(0, entry)
    # drop older dupes for same URL
    seen: set[str] = set()
    uniq: list[dict[str, Any]] = []
    for e in cleaned:
        u = (e.get("url") or "").strip()
        if not u or u in seen:
            continue
        seen.add(u)
        uniq.append(e)
        if len(uniq) >= limit:
            break
    _settings_set("media_opens", uniq)


def list_media_opens(limit: int = 20) -> dict[str, Any]:
    raw = _settings_get("media_opens", []) or []
    if not isinstance(raw, list):
        raw = []
    items = [e for e in raw if isinstance(e, dict)][: max(1, min(int(limit or 20), 50))]
    return {
        "ok": True,
        "items": items,
        "count": len(items),
        "disclaimer": "Histórico local de aberturas — não é progresso oficial UEMA.",
    }


def mark_media_read(
    url: str,
    *,
    subject: str | None = None,
    topic: str | None = None,
    title: str | None = None,
) -> dict[str, Any]:
    raw_url = (url or "").strip()
    if not raw_url.startswith("http"):
        return {"ok": False, "message": "URL inválida"}
    reads = _settings_get("media_reads", {}) or {}
    if not isinstance(reads, dict):
        reads = {}
    at = datetime.now().isoformat(timespec="seconds")
    entry = {
        "url": raw_url,
        "subject": (subject or "").strip() or None,
        "topic": (topic or "").strip() or None,
        "title": (title or "").strip() or None,
        "at": at,
        "read": True,
    }
    reads[raw_url] = entry
    # cap ~80 keys
    if len(reads) > 80:
        ordered = sorted(
            reads.values(),
            key=lambda e: str((e or {}).get("at") or ""),
            reverse=True,
        )[:80]
        reads = {str(e.get("url")): e for e in ordered if isinstance(e, dict) and e.get("url")}
    _settings_set("media_reads", reads)
    return {"ok": True, **entry, "disclaimer": "Lido local — não conta como edital/oficial."}


def list_media_reads(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    reads = _settings_get("media_reads", {}) or {}
    if not isinstance(reads, dict):
        reads = {}
    items: list[dict[str, Any]] = []
    sub = (subject or "").strip()
    top = (topic or "").strip()
    for u, e in reads.items():
        if not isinstance(e, dict):
            continue
        entry = dict(e)
        entry.setdefault("url", u)
        if sub and top:
            es = (entry.get("subject") or "").strip()
            et = (entry.get("topic") or "").strip()
            # include global marks on same URL even without subject match
            if es and et and (es != sub or et != top):
                continue
        items.append(entry)
    items.sort(key=lambda e: str(e.get("at") or ""), reverse=True)
    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "items": items[:40],
        "count": len(items),
        "urls": [str(e.get("url")) for e in items if e.get("url")],
        "disclaimer": "Leituras marcadas localmente — não é banca UEMA.",
    }


def open_media_url(
    url: str,
    kind: str | None = None,
    *,
    subject: str | None = None,
    topic: str | None = None,
    title: str | None = None,
) -> dict[str, Any]:
    raw = (url or "").strip()
    parsed = urlparse(raw)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return {"ok": False, "message": "URL inválida (use http/https)"}
    host = (parsed.hostname or "").lower()
    k = (kind or "auto").strip().lower()
    if k in {"", "auto"}:
        if _host_allowed_for_youtube(host):
            k = "video"
        elif _host_allowed_for_article(host):
            k = "article"
        else:
            return {
                "ok": False,
                "message": "Host não permitido. Use YouTube (vídeo) ou Wikipedia/SciELO/gov.br/edu (artigo).",
            }
    if k == "video":
        if not _host_allowed_for_youtube(host):
            return {"ok": False, "message": "Só links YouTube (youtube.com / youtu.be) para kind=video"}
        disclaimer = DISCLAIMER_VIDEO
    elif k in {"article", "article_search"}:
        if not _host_allowed_for_article(host):
            return {
                "ok": False,
                "message": "Artigo: só wikipedia.org, scielo.br, gov.br, edu, khanacademy.org",
            }
        disclaimer = DISCLAIMER_ARTICLE
        k = "article"
    elif k == "youtube_search":
        if not _host_allowed_for_youtube(host):
            return {"ok": False, "message": "Busca YouTube: só domain youtube.com / youtu.be"}
        disclaimer = DISCLAIMER_VIDEO
        k = "video"
    else:
        return {"ok": False, "message": "kind inválido (use video, article, youtube_search ou auto)"}

    try:
        import os as _os

        if _os.name == "nt":
            _os.startfile(raw)  # type: ignore[attr-defined]
        elif _os.name == "darwin":
            import subprocess

            subprocess.Popen(["open", raw])
        else:
            import subprocess

            subprocess.Popen(["xdg-open", raw])
    except OSError as exc:
        return {"ok": False, "message": f"Não foi possível abrir: {exc}"}

    at = datetime.now().isoformat(timespec="seconds")
    entry = {
        "url": raw,
        "kind": k,
        "subject": (subject or "").strip() or None,
        "topic": (topic or "").strip() or None,
        "title": (title or "").strip() or None,
        "at": at,
    }
    try:
        _append_media_open(entry)
    except Exception:  # noqa: BLE001
        pass
    return {"ok": True, "url": raw, "kind": k, "disclaimer": disclaimer, "at": at}


def essay_personas() -> list[dict[str, Any]]:
    return list(ESSAY_PERSONAS)


def persona_by_id(pid: str | None) -> dict[str, Any] | None:
    if not pid:
        return None
    for p in ESSAY_PERSONAS:
        if p["id"] == pid:
            return p
    return None
