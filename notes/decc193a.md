+++
id = "decc193a"
title = "The working representation stores the lower grade"
created = 2026-11-17T18:19:22Z
updated = 2026-11-17T18:22:27Z
tags = ["ga/model"]
aliases = ["dual picture", "working representation"]
+++

Every conformal object has two representatives: the *direct* blade, built by
wedging points (plus $e_oo$ for flats), and its *dual*. The library stores
whichever has the lower grade, because that is the one with the simplest
incidence test.

| object | direct blade | dual blade | incidence |
| --- | --- | --- | --- |
| point | `X` (1) | `X*` (4) | `X' . X = 0` |
| point pair | `X1 ^ X2` (2) | `(X1 ^ X2)*` (3) | `X . P = 0` |
| circle | `X1 ^ X2 ^ X3` (3) | `z` (2) | `X . z = 0` |
| sphere | `X1 ^ X2 ^ X3 ^ X4` (4) | `S` (1) | `X . S = 0` |
| line | `X1 ^ X2 ^ e∞` (3) | `l` (2) | `X . l = 0` |
| plane | `X1 ^ X2 ^ X3 ^ e∞` (4) | `pi` (1) | `X . pi = 0` |

The uniformity is the point: for any object blade $O$ in the working
representation and any point $X$, incidence is $X dot O = 0$. One expression,
one code path, one contraction.

```ocaml
open Geom
let p = Cga.point3 in
let z = Cga.circle (p 1. 0. 0.) (p 0. 1. 0.) (p (-1.) 0. 0.) in
Nx.item [] (Cga.incident (p 0. (-1.) 0.) z)   (* true *)
Nx.item [] (Cga.incident (p 0. 0. 1.) z)      (* false *)
```

Three remarks. The dual of a point is a four-blade, the pencil of planes
through it, not another point. The star is an involution only up to sign,
$(A^*)^* = -A$ in `Cl(4,1)`, so `undual` is its own function
([[d32870e7|The Hodge dual trades a blade for its complement]]). And `Cga.meet` is only uniform for grade-one constraints;
mixing a point with a constraint is not the wedge, so use the named
constructors ([[5d4f04c6|Wedge the points, then dualise]], [[39201d29|When the conformal model is worth it]]).
