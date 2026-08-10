"""Mídia de reforço (vídeos + artigos) — catálogo local + APIs opcionais (AY–BF)."""

from __future__ import annotations

import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timedelta
from typing import Any
from urllib.parse import urlparse

from db import DATA_DIR, db, loads_json
from timeutil import now, now_iso

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY", "").strip()
SERPER_API_KEY = os.getenv("SERPER_API_KEY", "").strip()
VIDEO_CACHE_TTL_H = 48
ARTICLE_CACHE_TTL_H = 48

DISCLAIMER_VIDEO = (
    "Vídeos de reforço (não oficiais da banca UEMA). "
    "Não contam como edital nem como prova oficial."
)
DISCLAIMER_ARTICLE = (
    "Leituras de reforço de fontes científicas (SciELO, PubMed, Khan Academy, .gov.br, .edu.br). "
    "Não oficiais da banca UEMA — não contam como edital nem prova oficial."
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
    with db() as conn:
        row = conn.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
        if not row:
            return default
        return loads_json(row["value"], default)


def _settings_set(key: str, value: Any) -> None:
    with db() as conn:
        conn.execute(
            """
            INSERT INTO settings(key, value) VALUES(?, ?)
            ON CONFLICT(key) DO UPDATE SET value=excluded.value
            """,
            (key, json.dumps(value, ensure_ascii=False) if not isinstance(value, str) else value),
        )
        conn.commit()


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
    return {"suggestVideos": bool(videos), "suggestArticles": bool(articles)}


def set_media_prefs(
    *,
    suggest_videos: bool | None = None,
    suggest_articles: bool | None = None,
) -> dict[str, Any]:
    cur = media_prefs()
    if suggest_videos is not None:
        cur["suggestVideos"] = bool(suggest_videos)
    if suggest_articles is not None:
        cur["suggestArticles"] = bool(suggest_articles)
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
        return {
            "title": raw.get(title_key) or raw.get("title") or "Item",
            "channel": raw.get("channel") or raw.get("source") or "",
            "source": raw.get("source") or raw.get("channel") or source_tag,
            "url": url,
            "snippet": raw.get("snippet"),
            "thumb": raw.get("thumb"),
            "origin": source_tag,
        }

    if key in topics and isinstance(topics[key], list):
        for raw in topics[key]:
            if isinstance(raw, dict):
                n = _normalize(raw)
                if n:
                    items.append(n)
        if items:
            return items[:5]

    tokens = [t.lower() for t in f"{subject or ''} {topic or ''}".split() if len(t) > 2]
    if not tokens:
        return []
    scored: list[tuple[int, list[dict[str, Any]]]] = []
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
    return scored[0][1][:5] if scored else []


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
    if now() - ts > timedelta(hours=ttl_h):
        return None
    items = entry.get("items")
    return items if isinstance(items, list) else None


def _cache_set(store_key: str, entry_key: str, items: list[dict[str, Any]], max_keys: int = 40) -> None:
    cache = _settings_get(store_key, {}) or {}
    if not isinstance(cache, dict):
        cache = {}
    cache[entry_key] = {"at": now_iso(), "items": items}
    if len(cache) > max_keys:
        keys = sorted(cache.keys(), key=lambda k: str((cache.get(k) or {}).get("at") or ""))
        for k in keys[: max(0, len(cache) - max_keys)]:
            cache.pop(k, None)
    _settings_set(store_key, cache)


def _youtube_search(subject: str | None, topic: str | None, limit: int = 5) -> list[dict[str, Any]]:
    if not youtube_configured():
        return []
    # Query prioriza contexto brasileiro (ENEM/PAES + português) para evitar vídeos gringos.
    q = f"{subject or ''} {topic or ''} ENEM português Brasil".strip()
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
            "regionCode": "BR",
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
    # Prioriza fontes científicas/educacionais confiáveis em vez de Wikipedia.
    # SciELO, PubMed, Khan Academy, .gov.br, .edu.br são filtrados no host allowlist.
    q = (
        f"{subject or ''} {topic or ''} "
        f"(site:scielo.br OR site:pubmed.ncbi.nlm.nih.gov OR site:khanacademy.org "
        f"OR site:pt.khanacademy.org OR site:gov.br OR site:edu.br OR site:pt.wikipedia.org)"
    ).strip()
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


def list_topic_videos(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    prefs = media_prefs()
    if not prefs.get("suggestVideos", True):
        return {
            "ok": True,
            "subject": subject,
            "topic": topic,
            "items": [],
            "count": 0,
            "basis": "off",
            "disclaimer": DISCLAIMER_VIDEO,
            "note": "Sugestão de vídeos desligada em Ajustes · Avançado.",
            "youtubeConfigured": youtube_configured(),
        }

    yt = _youtube_search(subject, topic, limit=5)
    cat = _match_catalog_items("videos_catalog.json", subject, topic, source_tag="catalogo_local")
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    for src in yt + cat:
        u = (src.get("url") or "").strip()
        if not u or u in seen:
            continue
        seen.add(u)
        items.append(src)
        if len(items) >= 5:
            break

    if yt and cat:
        basis = "misto"
    elif yt:
        basis = "youtube"
    else:
        basis = "catalogo_local"

    note = None
    if not items:
        note = (
            f"Sem vídeos catalogados para {subject or '—'} · {topic or '—'}. "
            "Não inventamos URL. Com YOUTUBE_API_KEY no .env a busca enriquece o catálogo."
        )

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "items": items,
        "count": len(items),
        "basis": basis,
        "disclaimer": DISCLAIMER_VIDEO,
        "note": note,
        "youtubeConfigured": youtube_configured(),
    }


def list_topic_articles(subject: str | None = None, topic: str | None = None) -> dict[str, Any]:
    prefs = media_prefs()
    if not prefs.get("suggestArticles", True):
        return {
            "ok": True,
            "subject": subject,
            "topic": topic,
            "items": [],
            "count": 0,
            "basis": "off",
            "disclaimer": DISCLAIMER_ARTICLE,
            "note": "Sugestão de artigos desligada em Ajustes · Avançado.",
            "serperConfigured": serper_configured(),
        }

    web = _serper_search(subject, topic, limit=5)
    cat = _match_catalog_items("articles_catalog.json", subject, topic, source_tag="catalogo_local")
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    for src in web + cat:
        u = (src.get("url") or "").strip()
        if not u or u in seen:
            continue
        seen.add(u)
        items.append(src)
        if len(items) >= 5:
            break

    if web and cat:
        basis = "misto"
    elif web:
        basis = "serper"
    else:
        basis = "catalogo_local"

    note = None
    if not items:
        note = (
            f"Sem artigos catalogados para {subject or '—'} · {topic or '—'}. "
            "Não inventamos URL. Com SERPER_API_KEY no .env a busca enriquece o catálogo."
        )

    return {
        "ok": True,
        "subject": subject,
        "topic": topic,
        "items": items,
        "count": len(items),
        "basis": basis,
        "disclaimer": DISCLAIMER_ARTICLE,
        "note": note,
        "serperConfigured": serper_configured(),
    }


def _host_allowed_for_youtube(host: str) -> bool:
    return host.lower() in _YT_HOSTS


def _host_allowed_for_article(host: str) -> bool:
    h = (host or "").lower().strip(".")
    if not h:
        return False
    # Fontes científicas internacionais (PubMed/NIH)
    if h in {"ncbi.nlm.nih.gov", "pubmed.ncbi.nlm.nih.gov", "pmc.ncbi.nlm.nih.gov"}:
        return True
    if h.endswith(".ncbi.nlm.nih.gov") or h.endswith(".nih.gov"):
        return True
    # Fontes científicas brasileiras
    if h in {"scielo.br", "scielo.org", "bvs.br", "bvsalud.org"}:
        return True
    if h.endswith(".scielo.br") or h.endswith(".scielo.org") or h.endswith(".bvs.br") or h.endswith(".bvsalud.org"):
        return True
    # Khan Academy (pt e en)
    if h in {"khanacademy.org", "pt.khanacademy.org"}:
        return True
    if h.endswith(".khanacademy.org"):
        return True
    # Wikipedia (pt apenas — fallback, não prioridade)
    if h == "pt.wikipedia.org" or h.endswith(".pt.wikipedia.org"):
        return True
    # Portais governamentais brasileiros (Ministério da Saúde, etc.)
    if h.endswith(".gov.br") or h == "gov.br":
        return True
    # Domínios educacionais brasileiros
    if h.endswith(".edu.br") or h.endswith(".edu") or h == "edu" or h == "edu.br":
        return True
    # Portais médicos brasileiros confiáveis
    if h in {"msdmanuals.com", "pt.msdmanuals.com", "sociedadebrasileira.org"}:
        return True
    if h.endswith(".msdmanuals.com"):
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
    at = now_iso()
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
    elif k == "article":
        if not _host_allowed_for_article(host):
            return {
                "ok": False,
                "message": "Artigo: só wikipedia.org, scielo.br, gov.br, edu, khanacademy.org",
            }
        disclaimer = DISCLAIMER_ARTICLE
    else:
        return {"ok": False, "message": "kind inválido (use video, article ou auto)"}

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

    at = now_iso()
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
