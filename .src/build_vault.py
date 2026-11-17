#!/usr/bin/env python3
"""Turn the staging notes in .src/*.md into an EG vault.

Staging format: one or more notes per file, each introduced by header lines

    @@@ slug: some-slug
    @@@ title: The note title
    @@@ tags: tag-a, tag-b
    @@@ aliases: alias one, alias two

The body follows, up to the next `@@@ slug:` line. Links are written with
slugs, `[[some-slug|display text]]` or `[[some-slug]]`; this script resolves
them to EG ids after every note has been created, and verifies that no link
points at a missing slug.

Note ids are minted by `eg new` and cached in .src/ids.json, so the script is
idempotent: re-running it rewrites note bodies in place and keeps every id.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / ".src"
IDS = SRC / "ids.json"
NOTES = ROOT / "notes"

HEADER = re.compile(r"^@@@\s+(slug|title|tags|aliases):\s*(.*)$")
LINK = re.compile(r"\[\[([a-z0-9][a-z0-9-]*)(?:\|([\s\S]+?))?\]\]")
IMG = re.compile(r"!\[([^\]]*)\]\(([^)]+)\)")
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def parse() -> list[dict]:
    notes: list[dict] = []
    for path in sorted(SRC.glob("*.md")):
        current: dict | None = None
        body: list[str] = []
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            m = HEADER.match(line)
            if m:
                key, value = m.group(1), m.group(2).strip()
                if key == "slug":
                    if current is not None:
                        current["body"] = "\n".join(body).strip() + "\n"
                        notes.append(current)
                    current = {
                        "slug": value,
                        "title": None,
                        "tags": [],
                        "aliases": [],
                        "body": "",
                        "where": f"{path.name}:{lineno}",
                    }
                elif current is None:
                    die(f"{path.name}:{lineno}: header before any @@@ slug")
                elif key == "title":
                    current["title"] = value
                elif key == "tags":
                    current["tags"] = [t.strip() for t in value.split(",") if t.strip()]
                elif key == "aliases":
                    current["aliases"] = [a.strip() for a in value.split(",") if a.strip()]
                body = []
            else:
                body.append(line)
        if current is not None:
            current["body"] = "\n".join(body).strip() + "\n"
            notes.append(current)
    return notes


def load_ids() -> dict[str, str]:
    if IDS.exists():
        return json.loads(IDS.read_text())
    return {}


def save_ids(ids: dict[str, str]) -> None:
    IDS.write_text(json.dumps(dict(sorted(ids.items())), indent=2) + "\n")


def eg_new(note: dict) -> str:
    cmd = ["eg", "new", "--vault", str(ROOT), "--title", note["title"]]
    if note["tags"]:
        cmd += ["--tags", ",".join(note["tags"])]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        die(f"eg new failed for {note['slug']}: {out.stderr.strip()}")
    first = out.stdout.strip().splitlines()[0]
    nid = first.split()[0]
    if not re.fullmatch(r"[0-9a-f]{8}", nid):
        die(f"unexpected eg new output for {note['slug']}: {first!r}")
    return nid


def existing_field(path: Path, key: str) -> str | None:
    if not path.exists():
        return None
    lines = path.read_text().splitlines()
    if not lines or lines[0] != "+++":
        return None
    for line in lines[1:]:
        if line == "+++":
            break
        if line.startswith(key + " "):
            return line.split("=", 1)[1].strip().strip('"')
    return None


def existing_body(path: Path) -> str | None:
    if not path.exists():
        return None
    text = path.read_text()
    marker = "\n+++\n"
    if marker not in text:
        return None
    return text.split(marker, 1)[1]


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def toml_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def render(note: dict, body: str, nid: str, created: str, updated: str) -> str:
    lines = ["+++", f'id = "{nid}"', f"title = {toml_str(note['title'])}"]
    lines.append(f"created = {created}")
    lines.append(f"updated = {updated}")
    if note["tags"]:
        tags = ", ".join(toml_str(t) for t in note["tags"])
        lines.append(f"tags = [{tags}]")
    if note["aliases"]:
        al = ", ".join(toml_str(a) for a in note["aliases"])
        lines.append(f"aliases = [{al}]")
    lines.append("+++")
    lines.append("")
    lines.append("")
    return "\n".join(lines) + body


def main() -> None:
    check_only = "--check" in sys.argv
    notes = parse()

    seen: dict[str, str] = {}
    for n in notes:
        if not n["title"]:
            die(f"{n['where']}: missing @@@ title")
        if not SLUG.match(n["slug"]):
            die(f"{n['where']}: bad slug {n['slug']!r}")
        if n["slug"] in seen:
            die(f"{n['where']}: duplicate slug {n['slug']!r} (also {seen[n['slug']]})")
        seen[n["slug"]] = n["where"]

    ids = load_ids()
    by_slug = {n["slug"]: n for n in notes}

    # Mint ids for new slugs.
    if not check_only:
        for n in notes:
            if n["slug"] not in ids:
                ids[n["slug"]] = eg_new(n)
                save_ids(ids)
                print(f"created {n['slug']:<26} {ids[n['slug']]}")

    # Resolve links and report every unknown target before writing anything.
    problems: list[str] = []
    resolved: dict[str, str] = {}
    for n in notes:
        def repl(m: re.Match) -> str:
            slug, label = m.group(1), m.group(2)
            if slug not in by_slug:
                problems.append(f"{n['slug']}: unknown slug {slug!r}")
                return m.group(0)
            target = by_slug[slug]
            text = re.sub(r"\s+", " ", label).strip() if label else target["title"]
            return f"[[{ids[slug]}|{text}]]"

        body = LINK.sub(repl, n["body"])
        # A markdown image would be recorded by eg as a link and reported
        # broken (the figures live in the built site). Emit raw HTML instead,
        # which Omd passes through and the link scanner ignores.
        def fig(m: re.Match) -> str:
            alt = re.sub(r"\s+", " ", m.group(1)).strip()
            name = Path(m.group(2)).name
            source = ROOT / "figures" / name
            if not source.exists():
                die(f"{n['slug']}: missing figure {name}")
            svg = source.read_text()
            svg = re.sub(r"^<\?xml[^>]*\?>\s*", "", svg)
            # The figure is inlined, not linked: the page then carries its own
            # drawing, so `eg build` alone is enough and no asset copy is needed.
            svg = re.sub(r'width="[^"]*"\s+height="[^"]*"\s*', "", svg, count=1)
            attr = alt.replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;")
            svg = svg.replace(
                "<svg ",
                "<svg role=\"img\" aria-label=\"" + attr + "\" "
                'style="width:100%;max-width:680px;height:auto;display:block;margin:0 auto;'
                'border-radius:6px" ',
                1,
            )
            cap = (
                f'<figcaption style="text-align:center;font-size:0.85em;opacity:0.7;'
                f'margin-top:0.4em">{alt}</figcaption>'
            )
            return f"<figure>\n{svg}\n{cap}\n</figure>"
        resolved[n["slug"]] = IMG.sub(fig, body)

    if problems:
        for p in problems:
            print(f"error: {p}", file=sys.stderr)
        die(f"{len(problems)} unresolved link(s); nothing written")

    # Expand the {{index}} directive: every note, grouped by cluster tag.
    order = ["map", "ga/foundation", "ga/model", "ga/motion", "ga/computing", "ga/viz"]
    labels = {
        "map": "Maps and paths",
        "ga/foundation": "Foundations: the algebra",
        "ga/model": "Models: E3, PGA, CGA",
        "ga/motion": "Motions: motors and kinematics",
        "ga/computing": "Computing: shapes, tracing, numerics",
        "ga/viz": "Pictures",
    }

    def cluster(n: dict) -> str:
        for t in n["tags"]:
            if t in order:
                return t
        return "map"

    grouped: dict[str, list[dict]] = {k: [] for k in order}
    for n in notes:
        if n["slug"] == "index":
            continue
        grouped[cluster(n)].append(n)

    lines = []
    for key in order:
        group = sorted(grouped[key], key=lambda n: n["title"].lower())
        if not group:
            continue
        lines.append(f"## {labels[key]}")
        lines.append("")
        lines.extend(f"- [[{ids[n['slug']]}|{n['title']}]]" for n in group)
        lines.append("")
    listing = "\n".join(lines).rstrip() + "\n"

    for n in notes:
        if "{{index}}" in resolved[n["slug"]]:
            resolved[n["slug"]] = resolved[n["slug"]].replace("{{index}}", listing)

    # Orphans and unused slugs.
    for slug in ids:
        if slug not in by_slug:
            print(f"warning: stale id for removed slug {slug!r}", file=sys.stderr)

    if check_only:
        print(f"ok: {len(notes)} note(s), all links resolve")
        return

    NOTES.mkdir(exist_ok=True)
    changed = 0
    for n in notes:
        nid = ids[n["slug"]]
        path = NOTES / f"{nid}.md"
        body = resolved[n["slug"]]
        created = existing_field(path, "created") or now()
        prev_updated = existing_field(path, "updated") or created
        # Compare against the file as it would look with its current `updated`
        # stamp: only a real content change bumps the stamp (and the mtime).
        old = path.read_text() if path.exists() else None
        if old == render(n, body, nid, created, prev_updated):
            continue
        new = render(n, body, nid, created, now())
        changed += 1
        path.write_text(new)
    print(f"wrote {len(notes)} note(s), {changed} changed")


if __name__ == "__main__":
    main()
