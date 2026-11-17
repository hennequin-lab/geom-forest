+++
id = "dc7fd3f4"
title = "The sandwich is an algebra automorphism"
created = 2026-11-17T18:19:22Z
updated = 2026-11-17T18:22:27Z
tags = ["ga/foundation"]
aliases = ["sandwich product", "conjugation action"]
+++

A versor $V$ acts on the algebra by

```typst
X |-> V X V^(-1),
```

the sandwich. Because it is conjugation by an invertible element, it is an
algebra automorphism: it preserves grades, products, sums and therefore every
incidence relation. It is also linear in $X$, which means it has a matrix
([[db8d2e5e|The adjoint turns a sandwich into a matrix]]).

```ocaml
open Geom

let m = Motor.translate3 0. 0. 1. in
let s = Cga.sphere ~center:(Nx.create Nx.float32 [| 3 |] [| 0.; 0.; 0. |])
                   ~radius:(Nx.scalar Nx.float32 2.) in
let s' = Cga.apply_motor m s in
Nx.to_array (Cga.coords (Cga.sphere_center s'))   (* [|0.; 0.; 1.|] *)
```

This is the single action in the library. `apply_rotor`, `apply_motor` and
`Algebra.sandwich` are the same operation with different knowledge of the
inverse: a rotor's inverse is its reverse, a motor's is its conjugate, and a
general versor's is `tilde(V) / <tilde(V) V>_0`.

Because the action is uniform, there is no per-object transform function in the
library, and no risk of transforming a sphere correctly and its centre
incorrectly. That uniformity is the practical payoff of
[[0aef76c8|the whole enterprise]], and it is what
[[7c7870c2|the renderer]] exploits when it draws any object at all.
