+++
id = "db8d2e5e"
title = "The adjoint turns a sandwich into a matrix"
created = 2026-11-17T18:19:22Z
updated = 2026-11-17T18:22:27Z
tags = ["ga/motion"]
aliases = ["adjoint"]
+++

For a fixed versor $V$, the sandwich $X |-> V X V^(-1)$ is linear in $X$, so it
is a matrix in the blade basis. That matrix is the adjoint. For the dense
algebra it is $32 times 32$; for a motor it is the usual $6 times 6$ adjoint of
`SE(3)` acting on twists.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let m = Motor.rotate ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi /. 2.)) in
Nx.shape (Motor.adjoint m)          (* [|6; 6|] *)
Nx.shape (Cga.adjoint (Cga.of_motor m))  (* [|32; 32|] *)
```

Two uses. The first is composition of many motions applied to many points: a
$32 times 32$ matrix times a batch of 32-vectors is one `dot`, which is often
faster than a batched sandwich. The second is the Lie-theoretic one: the
adjoint carries twists (and, dually, wrenches) between frames, and the adjoint
of a composition is the product of the adjoints, $op("Ad")(M_1 M_2) = op("Ad")(M_1) op("Ad")(M_2)$.

The dense adjoint is also the cleanest test of the sandwich implementation:
apply the sandwich to each basis blade, stack the results, and compare with the
matrix. That is a cheap property test, and it catches sign errors that a
hand-written example would miss ([[1d3a2467|Numerical cautions in a projective algebra]]).
