+++
id = "a7e0caa1"
title = "The even subalgebra holds the rotations"
created = 2026-11-17T18:19:22Z
updated = 2026-11-19T09:48:03Z
tags = ["ga/foundation"]
aliases = ["even subalgebra"]
+++

The even-grade elements of an $n$-dimensional Clifford algebra close under
multiplication, so they form a subalgebra of dimension $2^(n-1)$: half of the
$2^n$ basis blades have an even number of factors. It contains the scalars and
the bivectors, hence the [[0aa35a84|exponentials of bivectors]], hence all
[[b1f5db79|rotors]]: every rotation is an even versor.

Two instances are worth memorising:

- the even subalgebra of `Cl(3,0,0)` is `Cl(0,2,0)`, the
  [[834da58f|quaternions]];
- the even subalgebra of `Cl(3,0,1)` is the eight-dimensional
  [[146686de|rigid-motion algebra]], the dual quaternions.

```ocaml
open Geom

let g = E3.gp E3.e1 E3.e2 in
Blade.to_string (Blade.of_int 3)               (* "e12" *)
E3.to_array (E3.odd g)                         (* zero: even *)
let r = E3.rotor ~axis:(Nx.create Nx.float32 [|3|] [|0.;0.;1.|])
                 ~angle:(Nx.scalar Nx.float32 0.5) in
E3.to_array (E3.odd (E3.gp r E3.e1))           (* all of it: odd *)
```

The odd part is a module over the even part: multiplying an even element by an
odd one stays odd. That is why a rotor can rotate a vector (odd to odd) while
being even itself, and why reversing a sandwich does not change the parity of
the object.

The [[ad136f1c|grade]] split also suggests the first software optimisation: if
every value you need is even, you only need half the coefficients. The library
does that explicitly for motors, storing 8 components instead of 16 or 32
([[432aee25|One motor algebra, two models]]).
