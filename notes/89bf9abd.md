+++
id = "89bf9abd"
title = "In PGA, incidence is the wedge"
created = 2026-11-17T18:19:22Z
updated = 2026-11-17T18:22:27Z
tags = ["ga/model"]
aliases = ["PGA incidence"]
+++

A point $p$ lies on a plane $pi$ exactly when their wedge vanishes:

```typst
p and pi = 0.
```

That is the plane equation read as a statement about blades: the point is
inside the subspace the plane represents. Nothing is contracted, nothing is
normalised, and no metric is used. It works because the point *is* the
intersection of three planes: if one of them is $pi$, the wedge is dependent.

```ocaml
open Geom

let pi = Pga.plane3 0. 0. 1. 0. in
Nx.item [] (Pga.point_on_plane (Pga.point3 1. 1. 0.) pi)  (* true *)
Nx.item [] (Pga.point_on_plane (Pga.point3 1. 1. 2.) pi)  (* false *)
let l = Pga.line_through (Pga.point3 0. 0. 0.) (Pga.point3 0. 0. 1.) in
Nx.item [] (Pga.point_on_line (Pga.point3 0. 0. 0.5) l)   (* true *)
```

Two subtleties. First, the plain wedge of a point (grade 3) and a line (grade 2)
is *always* zero in four dimensions, so `point_on_line` uses the
[[b5dd2ed2|complement dual]] instead — the library hides that behind the
predicate. Second, in a degenerate metric the wedge does **not** reduce to a
scalar contraction of a dual point with a plane, the way it does in the
conformal model ([[86c369c2|Round versus flat: the e∞ contraction decides]]). Incidence here is genuinely exterior, and
[[1d71e490|Meet and join in PGA]] builds the intersection calculus on top of it.
