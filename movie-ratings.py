#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional

import requests

VIDEO_EXTENSIONS = {
    ".webm",
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".m4v",
    ".mpg",
    ".mpeg",
}

NOISE_TOKENS = {
    "a1a2",
    "ad",
    "arte",
    "br",
    "cut",
    "d",
    "die",
    "der",
    "das",
    "hd",
    "hq",
    "mit",
    "mp4",
    "mkv",
    "mpg",
    "mpeg",
    "neo",
    "part",
    "p19v17",
    "rbb",
    "spielfilm",
    "sr",
    "fernsehen",
    "srfernsehen",
    "wdr",
    "webm",
    "zdf",
    "zdfneo",
    "4328k",
    "final",
}

def normalize_title(value: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "", value.lower())
    return value


def clean_title(path: Path) -> List[str]:
    name = path.name
    stem = Path(name).name
    stem = re.sub(r"\.(webm|mp4|mkv|avi|mov|m4v|mpg|mpeg)$", "", stem, flags=re.IGNORECASE)
    stem = re.sub(r"\.part$", "", stem, flags=re.IGNORECASE)
    stem = re.sub(r"^\d{6,8}_", "", stem)
    stem = re.sub(r"^\d{4}[-_]\d{2}[-_]\d{2}[_-]?", "", stem)
    stem = re.sub(r"[_\.\-]+", " ", stem)
    stem = re.sub(r"\s+", " ", stem).strip()

    if not stem:
        return []

    tokens = [token for token in re.split(r"\s+", stem) if token]
    filtered = []
    for token in tokens:
        normalized = token.lower()
        if normalized in NOISE_TOKENS:
            continue
        filtered.append(token)

    candidates = []
    if filtered:
        candidates.append(" ".join(filtered))
    if len(filtered) > 2:
        candidates.append(" ".join(filtered[:4]))
        candidates.append(" ".join(filtered[:3]))
    if stem:
        candidates.append(stem)

    seen = []
    for candidate in candidates:
        candidate = re.sub(r"\s+", " ", candidate).strip()
        if candidate and candidate not in seen:
            seen.append(candidate)
    return seen


def lookup_imdb_rating(query: str, language: Optional[str] = None) -> Optional[Dict[str, str]]:
    try:
        url = f"https://v2.sg.media-imdb.com/suggestion/x/{requests.utils.quote(query.lower())}.json"
        response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
        response.raise_for_status()
        data = response.json()
    except Exception:
        return None

    results = data.get("d", [])
    if not results:
        return None

    best_item = None
    for item in results:
        if item.get("id") and item.get("q") in {"feature", "tvSeries", "video"}:
            best_item = item
            break

    if not best_item:
        best_item = results[0]

    if not best_item:
        return None

    title = best_item.get("l")
    year = best_item.get("y")
    if not title:
        return None

    normalized = normalize_title(title)

    try:
        page_url = f"https://r.jina.ai/http://www.imdb.com/title/{best_item['id']}/"
        page = requests.get(page_url, headers={"User-Agent": "Mozilla/5.0"}, timeout=20)
        page.raise_for_status()
        text = page.text
    except Exception:
        text = ""

    match = re.search(r"⭐\s*([0-9]\.[0-9])", text)
    rating = match.group(1) if match else None
    return {"title": title, "year": str(year) if year is not None else "N/A", "rating": rating or "N/A"}


def main() -> None:
    parser = argparse.ArgumentParser(description="Print each video file next to its IMDb rating score")
    parser.add_argument("files", nargs="+", help="Video files to inspect")
    parser.add_argument("--language", choices=["de", "en"], help="Title language to prefer; defaults to preserving the title as-is")
    args = parser.parse_args()

    files: List[Path] = []
    for raw_path in args.files:
        path = Path(raw_path).expanduser().resolve()
        if not path.exists():
            print(f"File not found: {path}", file=sys.stderr)
            continue
        if not path.is_file():
            print(f"Not a file: {path}", file=sys.stderr)
            continue
        if path.suffix.lower() not in VIDEO_EXTENSIONS or path.name.endswith(".part"):
            print(f"Skipping unsupported file: {path.name}", file=sys.stderr)
            continue
        files.append(path)

    if not files:
        print("No supported video files provided.")
        return

    cache: Dict[str, Optional[Dict[str, str]]] = {}
    for path in sorted(files, key=lambda p: p.name):
        metadata = None
        for candidate in clean_title(path):
            if candidate in cache:
                metadata = cache[candidate]
            else:
                metadata = lookup_imdb_rating(candidate, args.language)
                cache[candidate] = metadata
            if metadata:
                break
        if metadata:
            print(f"{path.name}\t{metadata['title']} ({metadata['year']})\t{metadata['rating']}")
        else:
            print(f"{path.name}\tN/A")


if __name__ == "__main__":
    main()
