+++
id = "eb4daacf"
title = "e∞ is the point at infinity"
created = 2026-11-17T18:19:22Z
updated = 2026-11-17T18:22:27Z
tags = ["ga/model"]
aliases = ["point at infinity", "einf"]
+++

The vector $e_oo = e_4 + e_5$ is null, but it is not on the point slice:
$e_oo dot e_oo = 0$, not $-1$. It is the extra point of the conformal
compactification $RR^3 union {infinity}$, and it plays a structural role far
beyond being "one more point".

A *flat* object is one that contains $e_oo$. A plane $pi = bold(n) + d e_oo$
satisfies $e_oo dot pi = 0$; a sphere does not; a line does; a circle does not.
That is the entire [[86c369c2|round/flat dichotomy]], and it is a single
contraction.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let pi = Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 1.) in
Nx.item [] (Cga.scalar_prod Cga.einf pi)              (* 0.: flat *)
Nx.item [] (Cga.scalar_prod Cga.einf (Cga.point3 0. 0. 0.))  (* -1.: round *)
```

`e_oo` is also the generator of translations: the bivector
$bold(t) and e_oo$ is null, so its exponential terminates
([[ad74741e|A translator is a null rotation]]). And the versors that fix $e_oo$, up to a scale, are precisely
the Euclidean group; the ones that scale it are [[20a44783|dilations]]. In a
degenerate algebra the same role is played by the separate direction $e_0$
([[52e66d90|Ideal points carry weight zero]]), but there it is a whole plane of ideal points rather
than one point.
