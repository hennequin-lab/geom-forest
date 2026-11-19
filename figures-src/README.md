# figures-src

`forest_figures.ml` draws the fifteen SVGs in `../figures/` with
[`geom-viz`](../../murder/packages/geom/viz) and prints a table of numerical
checks. Those numbers are the ones the notes quote, so running it is also a
correctness check on the prose. The builder inlines the SVGs into the notes
(`.src/build_vault.py`, the `fig` function), so the site needs no asset copy.

`make_snippets.py` extracts every ` ```ocaml ` block from `../.src/*.md` into one
OCaml file of structure-level definitions, so the snippets can be typechecked.

## Why a scratch copy

`geom` and `geom_viz` are not installed libraries: they live in the `murder`
checkout and depend on its `dune.lock`. There is therefore no way to build this
directory in place without making it part of that workspace. The recipe is to
copy it in, build, and copy the figures out — the checkout is left unchanged
apart from an untracked directory that you delete afterwards.

```sh
# 1. copy into the murder workspace
cp -r figures-src ~/code/modern/murder/scratch-forest-figures

# 2. typecheck every OCaml snippet in the vault
python3 ~/code/modern/geom-forest/figures-src/make_snippets.py \
        ~/code/modern/geom-forest/.src \
        ~/code/modern/murder/scratch-forest-figures/snippets.ml
cd ~/code/modern/murder && dune build scratch-forest-figures/snippets.exe

# 3. draw the figures and print the checks
dune exec scratch-forest-figures/forest_figures.exe -- \
     ~/code/modern/geom-forest/figures

# 4. clean up
rm -rf ~/code/modern/murder/scratch-forest-figures
```

The `dune` file here declares both executables, so step 1 is enough:

```
(executables
 (names forest_figures snippets)
 (modules forest_figures snippets)
 (libraries geom geom_viz nx rune hugin.gg hugin.vg hugin.font))
```

## Notes on the drawings

- The camera figure draws its focal plane at a unit focal length for legibility.
  The library's image plane sits at `Camera.focal` page points (≈676 for the
  default 800×600 page and a 45° field of view), which is the same PGA
  construction at a different scale.
- The screw axis in the ScLERP figure is the fixed point of the planar rotation,
  solved from `(I − R₂) p = t₂`, because that motion is a rotation about z
  composed with a translation along z.
- Labels are glyph outlines from the same font stack as the rest of `geom-viz`,
  so the SVGs do not depend on fonts installed on the viewer's machine.
