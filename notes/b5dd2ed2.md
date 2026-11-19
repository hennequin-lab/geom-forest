+++
id = "b5dd2ed2"
title = "In a degenerate algebra the dual becomes the complement"
created = 2026-11-17T18:19:22Z
updated = 2026-11-19T10:27:13Z
tags = ["ga/foundation"]
aliases = ["Poincare complement", "complement"]
+++

The Hodge star needs an invertible [[afad7126|The pseudoscalar is the whole space as one blade]], which a
[[d26e47d0|degenerate signature]] forbids. What survives is index
complement: for each basis blade $e_A$, the blade $e_(A^c)$ whose index set is
the complement of $A$ in ${1, dots, n}$, where $n$ is the dimension, signed so
that

```typst
e_A and e_(A^c) = I,
```

with $I = e_1 dots e_n$ the pseudoscalar. That signed permutation of
coefficients is the *complement*. It is defined for every signature, it is
cheap (a gather with precomputed signs), and it is the dual that projective
geometry actually uses.

```ocaml
open Geom

let b = Blade.of_int 3 in                      (* e12 *)
Blade.to_string (Blade.complement ~n:3 b)      (* "e3" *)
Blade.complement_sign ~n:3 b                   (* 1: e12 and e3 = e123 *)
Blade.to_string (Blade.complement ~n:4 (Blade.of_basis 1))  (* "e234" *)
```

Two properties to remember. First, the complement is *not* the star: sign
conventions differ and there is no metric involved beyond the index sets.
Second, because it needs no inverse, it composes safely with the
[[35bfa9f1|regressive product]], which is defined through it. In `Cl(4,1)`
the library exposes both, and [[1d3a2467|the numerical note]] warns about
mixing them. In `Cl(3,0,1)` only the complement exists
([[ccd5c487|PGA has no Hodge dual, and that is the point]]).
