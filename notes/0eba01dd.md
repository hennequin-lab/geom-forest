+++
id = "0eba01dd"
title = "Four reading paths through the forest"
created = 2026-11-17T18:19:22Z
updated = 2026-11-19T10:08:48Z
tags = ["map"]
aliases = ["reading paths"]
+++

The [[771f54e6|forest map]] is a graph, not a book. These four paths are the ones
that make sense; each is short and self-contained.

## 1. The five-minute version

[[0aef76c8|Why geometric algebra: one product instead of a pile]] → [[b65e7fa9|The geometric product]] → [[831bf42e|Perpendicular directions anticommute]] → [[b1f5db79|A rotor is exp(-θB/2)]] →
[[dc7fd3f4|The sandwich is an algebra automorphism]] → [[146686de|A motor is a dual quaternion]] → [[b24b87b3|Distance is an inner product]]. Seven notes, no software,
and you can read the rest of the forest afterwards.

## 2. From quaternions to rigid motions

For someone who already rotates things for a living. Start at
[[834da58f|Quaternions are the even subalgebra of Cl(3,0,0)]], the even subalgebra you already know, then
[[0aa35a84|Exponentiating a simple bivector closes in three cases]] for why the exponential closes, [[458a227d|Rotors compose by multiplication, twice around]] for the
double cover, [[ad74741e|A translator is a null rotation]] for the trick that turns translation into a null
rotation, and [[146686de|A motor is a dual quaternion]] with [[6132d759|The SE(3) exponential turns a twist into a screw]] for the full pose. Finish with
[[0248bd6b|ScLERP interpolates along the group exponential]] and [[db8d2e5e|The adjoint turns a sandwich into a matrix]], which are what kinematics code actually calls.

## 3. The conformal model, properly

The long path, in dependency order: [[93d1da38|Cl(4,1) is the conformal model of 3D space]] for the ambient space,
[[50ea1633|A conformal point is a null vector]] for the null-vector representation,
[[b24b87b3|Distance is an inner product]] for the one identity everything follows from,
[[1656ed74|A sphere is a vector]] and [[7d7f29a7|A plane is a vector]] for the two kinds of vector object,
[[86c369c2|Round versus flat: the e∞ contraction decides]] for the dichotomy between them, then [[92485a1e|A line is a 2-blade]],
[[35a861f2|A circle is a 2-blade]], [[f862a6f6|A point pair is a hyperbolic 2-blade]] and [[5d4f04c6|Wedge the points, then dualise]] for the rest of the
object layer. [[decc193a|The working representation stores the lower grade]] is the summary table; read it twice.

## 4. The software path

For the person who has to make it run: [[095f0641|The last axis is the blade axis]] for the shape
convention, [[6c390d07|The multiplication table is 2^n × 2^n signs]] for the multiplication table,
[[863e305f|Traced algebra: no host branches]] for what "compatible with `jit`" costs, [[1d3a2467|Numerical cautions in a projective algebra]] for the traps,
then [[21d2f2bd|The geom API map]] for the module layout. [[8de937ed|Matrices, quaternions, dual quaternions, geometric algebra]] is the honest
comparison with matrices, quaternions and dual quaternions, and
[[39201d29|When the conformal model is worth it]] says when not to bother.

## Where the pictures are

[[68469ff7|The gallery]] collects all fifteen figures in one page.
[[b8a939ad|The geom-viz rendering model]] explains the renderer, [[ade8fd66|The camera projects by a PGA meet]] the camera, and
[[7c7870c2|Adapters from algebra objects to primitives]] the three lines of code that turn a conformal sphere into a
drawable primitive.
