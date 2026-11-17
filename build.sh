#!/usr/bin/env bash
# Rebuild the geom-forest vault: notes, then the site, then the figures.
#
#   ./build.sh            notes + site + figures
#
# The site is built for GitHub Pages: `.eg/config.toml` sets
# base_url = "/geom-forest/", so every internal link already carries the
# project-site prefix.
#
# The SVGs in figures/ are inlined into the note pages by .src/build_vault.py,
# so `eg build` alone is enough for the site to show them. The copy into
# site/figures/ is only a convenience for browsing the SVGs directly.
set -euo pipefail
cd "$(dirname "$0")"

python3 .src/build_vault.py
eg build --vault .
mkdir -p site/figures
cp -f figures/*.svg site/figures/
eg check --vault .
