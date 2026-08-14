"""Integração com Wikipedia API (PT) para buscar imagens reais e científicas.

Usa a API REST do Wikipedia em português para:
1. Buscar o artigo mais relevante para um tópico
2. Extrair imagens com legendas
3. Filtrar imagens úteis (diagramas, figuras científicas)

Tudo gratuito, sem API key, em português.
"""

from __future__ import annotations

import urllib.parse
from typing import Any

import httpx

WIKI_PT_SEARCH = "https://pt.wikipedia.org/w/api.php"
WIKI_PT_REST = "https://pt.wikipedia.org/api/rest_v1/page/summary/"
WIKI_PT_MEDIA = "https://pt.wikipedia.org/api/rest_v1/page/media-list/"
WIKI_PT_THUMB = "https://pt.wikipedia.org/w/api.php"

# Tipos de arquivo de imagem aceitos
_IMAGE_EXTS = (".jpg", ".jpeg", ".png", ".svg", ".gif", ".webp")
# Padrões a evitar (imagens genéricas de template, ícones, etc.)
_BAD_PATTERNS = (
    "commons-logo",
    "wiki-letter",
    "semi-protect",
    "edit-clear",
    "crystal_clear",
    "question_book",
    "disambig",
    "ambox",
    "red_pog",
    "wiktionary",
    "wikiquote",
    "wikisource",
    "wikibooks",
    "portal",
    "stub",
    "editor",
    "nuvola",
    "gnome",
    "fairytale",
    "book-2",
    "write",
    "pencil",
    "merge",
    "delete",
    "featured",
    "good_article",
    "sound-icon",
    "video",
    "speaker",
    "circle",
    "star",
    "tick",
    "cross",
    "check",
    "yes",
    "no",
    "stop",
    "hand",
    "arrow",
    "portal-puzzle",
    "fleur-de-lis",
    "coa",
    "coat_of_arms",
    "flag_of",
    "seal_of",
)


def _is_useful_image(filename: str, title: str | None = None) -> bool:
    """Filtra imagens genéricas/ícones e mantém só conteúdo educativo."""
    fn_lower = filename.lower()
    if not any(fn_lower.endswith(ext) for ext in _IMAGE_EXTS):
        return False
    if any(bad in fn_lower for bad in _BAD_PATTERNS):
        return False
    # Muito pequeno provavelmente é ícone
    return True


def _normalize_query(topic: str, subject: str | None = None) -> str:
    """Constrói termo de busca otimizado para Wikipedia PT."""
    # Remove números de tópicos (ex: "Citologia 1" → "Citologia")
    parts = topic.strip().split()
    cleaned = [p for p in parts if not p.isdigit()]
    query = " ".join(cleaned) if cleaned else topic.strip()
    # Adiciona contexto da disciplina se ajudar
    if subject and len(query.split()) == 1:
        # Para tópicos de palavra única, adiciona disciplina
        context_map = {
            "Biologia": "biologia",
            "Química": "química",
            "Física": "física",
            "Matemática": "matemática",
        }
        ctx = context_map.get(subject, "")
        if ctx:
            query = f"{query} {ctx}"
    return query


async def search_wikipedia_article(query: str) -> str | None:
    """Busca o título do artigo mais relevante na Wikipedia PT."""
    params = {
        "action": "query",
        "list": "search",
        "srsearch": query,
        "srlimit": "1",
        "srprop": "",
        "format": "json",
    }
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(WIKI_PT_SEARCH, params=params)
            resp.raise_for_status()
            data = resp.json()
            results = data.get("query", {}).get("search", [])
            if not results:
                return None
            return results[0]["title"]
    except Exception:
        return None


async def get_article_summary(title: str) -> dict[str, Any] | None:
    """Pega resumo do artigo (com thumbnail e descrição)."""
    encoded = urllib.parse.quote(title, safe="")
    url = WIKI_PT_REST + encoded
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url)
            if resp.status_code != 200:
                return None
            data = resp.json()
            return {
                "title": data.get("title", title),
                "description": data.get("description", ""),
                "extract": data.get("extract", ""),
                "thumbnail": data.get("thumbnail", {}).get("source")
                if data.get("thumbnail")
                else None,
                "url": data.get("content_urls", {}).get("desktop", {}).get("page", ""),
            }
    except Exception:
        return None


async def get_article_images(title: str, max_images: int = 5) -> list[dict[str, str]]:
    """Extrai imagens relevantes do artigo da Wikipedia PT.

    Retorna lista de dicts com:
    - url: URL da imagem (original)
    - thumb: URL de thumbnail (menor)
    - caption: legenda/descrição
    - source: 'wikipedia-pt'
    """
    encoded = urllib.parse.quote(title, safe="")
    url = WIKI_PT_MEDIA + encoded
    images: list[dict[str, str]] = []
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(url)
            if resp.status_code != 200:
                return images
            data = resp.json()
            items = data.get("items", [])
            for item in items:
                # Pula vídeos e áudios
                if item.get("type") not in ("image", "stillframe"):
                    continue
                source_sets = item.get("source", {})
                # URL original
                original = source_sets.get("original", {})
                orig_url = original.get("source") if isinstance(original, dict) else None
                # Thumbnail
                thumb = None
                candidates = source_sets.get("candidates", [])
                if isinstance(candidates, list) and candidates:
                    # Pega o primeiro (geralmente o menor)
                    thumb = candidates[0].get("src") if isinstance(candidates[0], dict) else None
                if not thumb:
                    thumb = orig_url

                filename = item.get("title", "")
                if not _is_useful_image(filename):
                    continue

                caption_parts = item.get("caption", {})
                caption = ""
                if isinstance(caption_parts, dict):
                    caption = caption_parts.get("plainText", "") or caption_parts.get("text", "")
                elif isinstance(caption_parts, str):
                    caption = caption_parts

                if orig_url or thumb:
                    images.append({
                        "url": orig_url or thumb,
                        "thumb": thumb or orig_url,
                        "caption": caption,
                        "source": "wikipedia-pt",
                        "filename": filename,
                    })
                if len(images) >= max_images:
                    break
    except Exception:
        pass
    return images


async def fetch_images_for_topic(
    topic: str,
    subject: str | None = None,
    max_images: int = 5,
) -> dict[str, Any]:
    """Busca imagens reais da Wikipedia PT para um tópico de estudo.

    Retorna:
    - article_title: título do artigo encontrado
    - article_url: URL do artigo
    - summary: resumo do artigo
    - images: lista de imagens com URL, thumbnail e legenda
    """
    query = _normalize_query(topic, subject)
    article_title = await search_wikipedia_article(query)
    if not article_title:
        return {
            "article_title": None,
            "article_url": None,
            "summary": None,
            "images": [],
            "query": query,
        }

    summary = await get_article_summary(article_title)
    images = await get_article_images(article_title, max_images=max_images)

    # Se não há imagens na media-list, tenta usar o thumbnail do summary
    if not images and summary and summary.get("thumbnail"):
        images = [{
            "url": summary["thumbnail"],
            "thumb": summary["thumbnail"],
            "caption": summary.get("description", topic),
            "source": "wikipedia-pt",
            "filename": article_title,
        }]

    return {
        "article_title": article_title,
        "article_url": summary.get("url") if summary else None,
        "summary": summary.get("extract") if summary else None,
        "images": images,
        "query": query,
    }
