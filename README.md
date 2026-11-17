# Geometric algebra for robotics — a forest

An [EG](https://github.com/hennequi-lab/eg) vault of 78 densely inter-linked
atomic notes on geometric algebra, written around the `geom` library in
`murder/packages/geom` and its renderer `geom-viz`. Every code sample is a
snippet of that library, and every figure was drawn by `geom-viz` from the very
objects the note is about.

## Read it

```sh
./build.sh            # stage notes, build the site, copy figures, validate
eg serve --vault .    # live preview at the printed URL
```

Start from the note **Map of the geometric-algebra forest** in the built site
(`https://hennequin-lab.github.io/geom-forest/` once published):

```sh
eg ls --vault . | grep "Map of the geometric-algebra forest"
```

## Publishing

<https://hennequin-lab.github.io/geom-forest/> is a GitHub Pages *project*
site, so it is served under `/geom-forest/` rather than from a domain root.
`.eg/config.toml` sets `base_url = "/geom-forest/"`, which `eg build` uses for
every internal URL, and on every push to `main`
`.github/workflows/pages.yml` deploys the committed `site/` directory.

## Shape of the forest

Two hub notes (the map and four reading paths) and five clusters:

| cluster | tag | trailhead |
| --- | --- | --- |
| the algebra itself | `ga/foundation` | `Clifford relation` |
| three models of space | `ga/model` | `Three models, one core` |
| rigid motions | `ga/motion` | `A motor is a dual quaternion` |
| software and numerics | `ga/computing` | `The last axis is the blade axis` |
| pictures | `ga/viz` | `The geom-viz rendering model` |

78 notes, ~480 wikilinks, every note has at least one inbound link and most
have five or more. `eg check` reports 0 broken links and 0 orphans.

## Editing

The canonical source is `.src/*.md`, one file per cluster, with notes separated
by headers:

```
@@@ slug: some-slug
@@@ title: The note title
@@@ tags: tag-a, tag-b
@@@ aliases: alias one, alias two
body...
```

Links are written with slugs, `[[some-slug|display text]]`; the builder resolves
them to stable EG ids (kept in `.src/ids.json`) and refuses unknown slugs. An
image `![caption](../../figures/x.svg)` is expanded into a raw-HTML
`<figure>`, because a Markdown image would be recorded by `eg` as a broken
link.

```sh
python3 .src/build_vault.py      # stage the notes into notes/ (idempotent)
eg build --vault .               # compile site/
eg check --vault .               # links and orphans
./build.sh                       # all of the above, plus the figures
```

`notes/` is generated from `.src`; edit the staging files, not the notes, if you
want the builder to stay the source of truth.

## Figures

`figures/*.svg` are drawn by `figures-src/forest_figures.ml`, which also prints
the numerical values quoted in the notes (sphere radii, the transversion image
of a point, the ScLERP midpoint, the forward-kinematics end effector, …). See
`figures-src/README.md` for how to regenerate them;
`figures-src/make_snippets.py` typechecks every OCaml snippet in the vault.

The builder **inlines** each SVG into the note body, so the page carries its own
drawing and `eg build` alone shows it — there is no asset copy to forget. All
eight are collected on the note **Gallery of figures**.
