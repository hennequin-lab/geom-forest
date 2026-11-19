@@@ slug: reading-paths
@@@ title: Four reading paths through the forest
@@@ tags: map
@@@ aliases: reading paths

The [[map|forest map]] is a graph, not a book. These four paths are the ones
that make sense; each is short and self-contained.

## 1. The five-minute version

[[why-ga]] → [[geometric-product]] → [[anticommutation]] → [[rotor]] →
[[sandwich]] → [[motor]] → [[conformal-distance]]. Seven notes, no software,
and you can read the rest of the forest afterwards.

## 2. From quaternions to rigid motions

For someone who already rotates things for a living. Start at
[[quaternions]], the even subalgebra you already know, then
[[bivector-exp]] for why the exponential closes, [[rotor-composition]] for the
double cover, [[translator]] for the trick that turns translation into a null
rotation, and [[motor]] with [[se3-exp]] for the full pose. Finish with
[[slerp]] and [[adjoint]], which are what kinematics code actually calls.

## 3. The conformal model, properly

The long path, in dependency order: [[cga]] for the ambient space,
[[conformal-embedding]] for the null-vector representation,
[[conformal-distance]] for the one identity everything follows from,
[[cga-sphere]] and [[cga-plane]] for the two kinds of vector object,
[[round-flat]] for the dichotomy between them, then [[cga-line]],
[[cga-circle]], [[point-pair]] and [[objects-from-points]] for the rest of the
object layer. [[working-representation]] is the summary table; read it twice.

## 4. The software path

For the person who has to make it run: [[batching]] for the shape
convention, [[structure-constants]] for the multiplication table,
[[traced]] for what "compatible with `jit`" costs, [[numerics]] for the traps,
then [[api-map]] for the module layout. [[alternatives]] is the honest
comparison with matrices, quaternions and dual quaternions, and
[[cga-tradeoffs]] says when not to bother.

## Where the pictures are

[[gallery|The gallery]] collects all fifteen figures in one page.
[[viz-model]] explains the renderer, [[camera-pga]] the camera, and
[[viz-adapters]] the three lines of code that turn a conformal sphere into a
drawable primitive.
