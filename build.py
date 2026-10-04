#!/usr/bin/env python3
"""Build the Pune KnOT site into _site/.

Usage: python build.py            (site served from the domain root)
       BASE_URL=/repo python build.py   (site served from a sub-path)
"""
from __future__ import annotations

import datetime as dt
import os
import shutil
from pathlib import Path

import markdown
import yaml
from jinja2 import Environment, FileSystemLoader, select_autoescape

ROOT = Path(__file__).parent
OUT = ROOT / "_site"
BASE = os.environ.get("BASE_URL", "").rstrip("/")


def read_front_matter(path: Path) -> tuple[dict, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise SystemExit(f"{path}: missing front matter")
    _, fm, body = text.split("---", 2)
    return yaml.safe_load(fm) or {}, body.strip()


def render_md(text: str) -> str:
    html = markdown.markdown(text, extensions=["extra", "sane_lists", "smarty"])
    # Root-relative links in the copy must respect BASE_URL.
    return html.replace('href="/', f'href="{BASE}/')


def load_talks(today: dt.date, categories: list[str]) -> list[dict]:
    talks = []
    for path in sorted((ROOT / "talks").glob("*.md")):
        meta, body = read_front_matter(path)
        for key in ("title", "speakers", "date"):
            if key not in meta:
                raise SystemExit(f"{path}: front matter needs '{key}'")
        date = dt.date.fromisoformat(str(meta["date"]))
        abstract, _, bio = body.partition("## About the speaker")
        bio = bio.split("\n", 1)[1] if "\n" in bio else ""
        if meta.get("category") and meta["category"] not in categories:
            raise SystemExit(f"{path}: category '{meta['category']}' is not listed in site.yaml")
        poster = meta.get("poster")
        if poster and not (ROOT / "static" / "posters" / poster).exists():
            raise SystemExit(f"{path}: poster static/posters/{poster} not found")
        thumb = None
        if poster:
            candidate = poster.rsplit(".", 1)[0] + "-thumb.jpg"
            thumb = candidate if (ROOT / "static" / "posters" / candidate).exists() else poster
        talks.append(
            {
                **meta,
                "slug": path.stem,
                "date": date,
                "upcoming": date >= today,
                "abstract_html": render_md(abstract),
                "bio_html": render_md(bio),
                "thumb": thumb,
                "speaker_line": " & ".join(meta["speakers"]),
            }
        )
    talks.sort(key=lambda t: t["date"])
    for number, talk in enumerate(talks, start=1):
        talk["number"] = number
    return talks


def last_thursday(year: int, month: int) -> dt.date:
    first_of_next = dt.date(year + month // 12, month % 12 + 1, 1)
    day = first_of_next - dt.timedelta(days=1)
    return day - dt.timedelta(days=(day.weekday() - 3) % 7)


def next_event(site: dict, upcoming: list[dict], today: dt.date) -> dict:
    """The date the home-page countdown runs to, and whether it has been announced."""
    if upcoming:
        date, confirmed = upcoming[0]["date"], True
    elif site.get("next_date") and dt.date.fromisoformat(str(site["next_date"])) >= today:
        date, confirmed = dt.date.fromisoformat(str(site["next_date"])), True
    else:
        date = last_thursday(today.year, today.month)
        if date < today:
            date = last_thursday(today.year + today.month // 12, today.month % 12 + 1)
        confirmed = False
    return {"date": date, "confirmed": confirmed, "iso": f"{date.isoformat()}T{site.get('start_time', '18:30')}:00+05:30"}


def load_pages() -> list[dict]:
    pages = []
    for path in sorted((ROOT / "pages").glob("*.md")):
        meta, body = read_front_matter(path)
        pages.append({**meta, "slug": path.stem, "html": render_md(body)})
    return sorted(pages, key=lambda p: p.get("order", 99))


def main() -> None:
    today = dt.date.today()
    site = yaml.safe_load((ROOT / "site.yaml").read_text(encoding="utf-8"))
    talks = load_talks(today, site.get("categories", []))
    pages = load_pages()
    past = [t for t in talks if not t["upcoming"]][::-1]
    upcoming = [t for t in talks if t["upcoming"]]

    env = Environment(
        loader=FileSystemLoader(ROOT / "templates"),
        autoescape=select_autoescape(["html"]),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    env.filters["longdate"] = lambda d: f"{d:%A}, {d.day} {d:%B %Y}"
    env.filters["shortdate"] = lambda d: f"{d.day} {d:%b %Y}"
    env.globals.update(site=site, base=BASE, pages=pages, year=today.year, talk_count=len(past))

    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(ROOT / "static", OUT / "static")

    def write(rel: str, template: str, **ctx) -> None:
        target = OUT / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(env.get_template(template).render(path=rel, **ctx), encoding="utf-8")

    write(
        "index.html",
        "home.html",
        next_talk=upcoming[0] if upcoming else None,
        event=next_event(site, upcoming, today),
        recent=past[:8],
        here="home",
    )
    write("talks/index.html", "talks.html", past=past, upcoming=upcoming, here="talks")
    for talk in talks:
        write(f"talks/{talk['slug']}/index.html", "talk.html", talk=talk, here="talks")
    for page in pages:
        write(f"{page['slug']}/index.html", page.get("template", "page.html"), page=page, here=page["slug"])
    write("404.html", "404.html", here="")

    urls = ["/", "/talks/"] + [f"/talks/{t['slug']}/" for t in talks] + [f"/{p['slug']}/" for p in pages]
    (OUT / "sitemap.txt").write_text("\n".join(site["url"] + u for u in urls) + "\n")
    print(f"built {len(talks)} talks ({len(upcoming)} upcoming), {len(pages)} pages -> {OUT}")


if __name__ == "__main__":
    main()
