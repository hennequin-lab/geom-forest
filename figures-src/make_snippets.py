#!/usr/bin/env python3
"""Extract every ```ocaml block from the staging notes into one OCaml file.

The snippets in the notes are written toplevel-style: a chain of `let ... in`
phrases and bare expressions, exactly as you would type them in `utop`. To
typecheck them, this script turns each block into a module of structure-level
definitions:

  * a phrase is a run of lines starting at column 0, plus its indented
    continuation (an `and` continuation is merged into the preceding phrase);
  * a `let` phrase loses its closing `in`, so it becomes a definition;
  * a lone `in` phrase is dropped;
  * a bare expression phrase becomes `let _ = <expr>`.

That is a syntactic rewrite only; it does not change what the note shows.
"""
import pathlib
import re
import sys

src = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])

IN_RE = re.compile(r"\bin(\s*\(\*.*?\*\))?\s*$")


def phrases(lines: list[str]) -> list[list[str]]:
    starts = [
        i
        for i, line in enumerate(lines)
        if line.strip() and line[0] not in " \t" and not line.startswith("and ")
    ]
    if not starts:
        return [lines] if lines else []
    result = []
    for a, b in zip(starts, starts[1:] + [len(lines)]):
        result.append(lines[a:b])
    return result


def transform(lines: list[str]) -> list[str]:
    out: list[str] = []
    for ph in phrases(lines):
        head = ph[0].strip()
        if not head:
            continue
        if head.startswith("(*"):
            out.extend(ph)
            continue
        if re.fullmatch(r"in(\s*\(\*.*?\*\))?", head):
            continue
        if head.startswith(("let ", "let rec ")) or re.match(r"^let\b", head):
            # drop the closing `in` of the phrase, if it has one
            last = len(ph) - 1
            while last > 0 and not ph[last].strip():
                last -= 1
            ph = list(ph)
            ph[last] = IN_RE.sub(lambda m: (m.group(1) or ""), ph[last])
            out.extend(ph)
            continue
        if head.startswith(("open ", "module ")):
            out.extend(ph)
            continue
        out.append("let _ = " + ph[0])
        out.extend(ph[1:])
    return out


blocks = []
for p in sorted(src.glob("*.md")):
    s = p.read_text()
    for m in re.finditer(r"```ocaml\n(.*?)```", s, re.S):
        slug = None
        for h in re.finditer(r"@@@ slug: (\S+)", s[: m.start()]):
            slug = h.group(1)
        blocks.append((slug, m.group(1)))

out = ["(* every OCaml snippet in the vault, as structure-level definitions *)"]
for i, (slug, body) in enumerate(blocks):
    out.append(f"(* ---- {i:03d}: {slug} ---- *)")
    out.append(f"module S{i:03d} = struct")
    out.extend(
        "  " + line if line.strip() else "" for line in transform(body.rstrip().splitlines())
    )
    out.append("end")
out_path.write_text("\n".join(out) + "\n")
print(f"{len(blocks)} blocks -> {out_path}")
