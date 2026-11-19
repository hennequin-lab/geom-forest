@@@ slug: three-models
@@@ title: Three models, one core
@@@ tags: ga/model
@@@ aliases: models

The library is one functor over a [[signature]] and a scalar kind, instantiated
three times. The algebra never changes; only the interpretation of the blades
does. Each row of the table below is a different answer to the question "what
should a point be?".

| module | algebra | coeffs | objects | motions |
| --- | --- | --- | --- | --- |
| `E3` | `Cl(3,0,0)` | 8 | vectors, bivectors, volumes | rotors (quaternions) |
| `Pga` | `Cl(3,0,1)` | 16 | planes (1), lines (2), points (3) | dual quaternions |
| `Cga` | `Cl(4,1)` | 32 | points, spheres, planes, lines, circles, point pairs | motors, dilations, transversions |

The notation `Cl(p,q,r)` means a Clifford algebra with $p$ positive, $q$
negative and $r$ null basis directions ([[signature]]); the number of
coefficients is $2^(p+q+r)$.

`E3` is the rotation algebra: the smallest useful testbed and the orientation
layer. [[pga|PGA]] adds one degenerate direction so that planes, lines and
points become blades and incidence becomes the wedge, at the price of the
[[pga-no-dual|Hodge dual]]. [[cga|CGA]] adds two dimensions so that Euclidean
points become null vectors, which buys [[conformal-distance|distance as an
inner product]] and a complete object layer, at the price of 32 coefficients.

```ocaml
open Geom

(E3.size, Pga.size, Cga.size)                  (* (8, 16, 32) *)
Signature.to_string E3.signature               (* "(3,0,0)" *)
Signature.to_string Pga.signature              (* "(3,0,1)" *)
Signature.to_string Cga.signature              (* "(4,1,0)" *)
```

The models are not nested implementations of each other: each one has its own
object layer, because a CGA point is a null vector and a PGA point is a
trivector. What *is* shared is the [[motor-shared|packed motor type]], which is
the even subalgebra of `Cl(3,0,1)` and the rigid part of `Cl(4,1)` at once.
[[cga-tradeoffs|The trade-offs note]] says which model to reach for;
[[reading-paths]] says in which order to read them.

@@@ slug: e3
@@@ title: Cl(3,0,0) is the Euclidean rotation algebra
@@@ tags: ga/model
@@@ aliases: E3, Euclidean algebra, Cl(3,0,0)

`Cl(3,0,0)` has three orthonormal basis vectors $e_1, e_2, e_3$ with
$e_1^2 = e_2^2 = e_3^2 = 1$ and no degenerate or negative direction. Its eight
coefficients split as one scalar, three vectors, three bivectors and one
trivector:

| grade | blades | interpretation |
| --- | --- | --- |
| 0 | `1` | scalars |
| 1 | `e1`, `e2`, `e3` | Euclidean vectors |
| 2 | `e12`, `e13`, `e23` | rotation planes |
| 3 | `e123` | the pseudoscalar $I$ |

The bivectors are the rotation planes, the vectors are ordinary Euclidean
vectors, and the trivector is the [[pseudoscalar]] with $I^2 = -1$. The
[[even-subalgebra|even part]] is four-dimensional, and it is exactly the
[[quaternions]].

Because the metric is positive definite, every non-zero blade is invertible
([[blade-inverse]]), the [[hodge-dual]] is available, and there are no
lightlike directions to trip over. That makes `Cl(3,0,0)` the clean testbed: if
an identity fails here, it is your algebra that is wrong, not your convention.

```ocaml
open Geom

let x = E3.vector3 1. 2. 3. in
Nx.to_array (E3.to_vector x)                    (* [|1.; 2.; 3.|] *)
let b = E3.op E3.e1 E3.e2 in                    (* the e12 rotation plane *)
Nx.item [] (E3.norm2 b)                         (* 1.: unit magnitude *)
Nx.item [] (E3.grade 0 (E3.gp E3.pseudoscalar E3.pseudoscalar))  (* -1. *)
```

![The geometric product of two vectors is a bivector: the oriented
parallelogram they span. A rotor acts on a vector by the sandwich.](../../figures/e3-product.svg)

In the library `E3` is the algebra used for orientation-only problems and for
[[rotor|rotors]]. It is also the place to develop intuition before the
projective and conformal layers add dimensions, because every object you can
draw in `Cl(3,0,0)` is a vector, a plane or a volume; see [[grades]].

@@@ slug: quaternions
@@@ title: Quaternions are the even subalgebra of Cl(3,0,0)
@@@ tags: ga/model
@@@ aliases: quaternions, even part of Cl(3,0,0)

The [[even-subalgebra]] of `Cl(3,0,0)` is spanned by the four blades
$1, e_23, e_31, e_12$ and has dimension four. Because the [[pseudoscalar]]
squares to $-1$, the three bivectors behave exactly like the quaternion units
$i, j, k$:

```typst
e_23^2 = e_31^2 = e_12^2 = -1, quad
e_12 e_23 = e_13 = -e_23 e_12, quad dots
```

So the quaternions are not a separate invention. They are the even part of the
Euclidean Clifford algebra, and a unit quaternion is a [[rotor|rotor]]:

```typst
q = cos(theta/2) - sin(theta/2) B,
```

where $theta$ is the rotation angle and $B$ is the unit bivector of the rotation
plane. The familiar quaternion vector part is the bivector part, read through
the [[hodge-dual|dual]]; that is where the "axis times sine" description of a
rotation comes from, and why it only works in three dimensions.

```ocaml
open Geom

let q = Nx.create Nx.float32 [| 4 |] [| 1.; 0.; 0.; 0. |] in
let m = Motor.of_quaternion q in
Nx.to_array (Motor.to_quaternion m)   (* [|1.; 0.; 0.; 0.|] *)
Nx.to_array (Motor.rotation m)        (* 3x3 identity, row-major *)
```

The library bridges the two representations explicitly, because camera and
inertial code often hands you a quaternion: `Motor.of_quaternion` and
`Motor.to_quaternion`. Everything else — composition, interpolation,
application — is the [[motor|motor]] API, and the double cover
([[rotor-composition]]) is inherited unchanged.

@@@ slug: rotor
@@@ title: A rotor is exp(-θB/2)
@@@ tags: ga/model
@@@ aliases: rotor

For a unit bivector $B$ — a rotation plane — and an angle $theta$, the rotor is

```typst
R = exp(-theta/2 B) = cos(theta/2) - sin(theta/2) B,
quad tilde(R) = cos(theta/2) + sin(theta/2) B.
```

It is an even, unit [[versor]], and it acts by the
[[sandwich]] $x |-> R x tilde(R)$. Here $x$ is a vector (or any multivector),
$tilde(R)$ is the [[reverse]] of $R$, and the sandwich rotates $bold(x)$ by
$theta$ in the plane, with the right-hand rule about the plane normal. There is
no matrix, no axis-angle singularity, and no need for a separate inverse: for a
unit rotor $R^(-1) = tilde(R)$.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let r = E3.rotor ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi /. 2.)) in
E3.to_array r                                        (* 0.7071 - 0.7071 e12 *)
Nx.to_array (E3.to_vector (E3.apply_rotor r E3.e1))  (* [|0.; 1.; 0.|] *)
```

`E3.rotor` takes an *axis* for convenience and converts it to the plane normal
to it; the bivector is the primary object and the axis is the three-dimensional
translation of it ([[grades]]). A rotation about an axis that does not pass
through the origin is a translation-conjugated rotor, which is the motor
[[rotate-about-point|note on conjugation]].

The half angle is not a convention to memorise: it is what makes the sandwich,
not the rotor itself, rotate by $theta$. That is the same half-angle that
appears in quaternion slerp ([[quaternions]]) and in every
[[rotor-composition|composition]] rule.

@@@ slug: rotor-composition
@@@ title: Rotors compose by multiplication, twice around
@@@ tags: ga/model
@@@ aliases: rotor composition, double cover

Rotors compose by multiplication, in the same order as matrices acting on
column vectors: $R_2 R_1$ applies $R_1$ first and $R_2$ second. The product of
two unit rotors is a unit rotor, because the even part is a subalgebra and the
norm is multiplicative on unit versors.

The map from rotors to rotations is two-to-one. The rotor $R$ and its negative
$-R$ give the same sandwich, because the sign cancels between the two sides:

```typst
(-R) x (tilde(-R)) = R x tilde(R)
```

for any multivector $x$.

That double cover is a feature, not an ambiguity to fix. It is what makes
continuous interpolation possible: a path of rotors can wind once and come back
to $-R$, which no continuous path of rotation matrices can do. It is also why a
rotor interpolated over more than a half turn must be told which way to go
([[slerp]]).

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let r45 = E3.rotor ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi /. 4.)) in
let r90 = E3.rotor ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi /. 2.)) in
let r135 = E3.gp r90 r45 in       (* r45 first, then r90 *)
E3.to_array r135                  (* 0.3827 - 0.9239 e12 *)
```

Same-plane rotors add their angles, as the exponential of a single bivector
should ([[bivector-exp]]). Different planes do not commute, and the
[[commutator]] measures the failure — the reason composition order matters for
every kinematic chain ([[fk]]).

@@@ slug: pga
@@@ title: Cl(3,0,1) is plane-based projective geometry
@@@ tags: ga/model
@@@ aliases: PGA, projective geometric algebra, Cl(3,0,1)

`Cl(3,0,1)` has three Euclidean directions $e_1, e_2, e_3$ with squares $+1$,
and one degenerate direction $e_0$ with $e_0^2 = 0$. Its sixteen coefficients
are exactly enough for the objects of three-dimensional projective geometry:

| grade | object | example |
| --- | --- | --- |
| 1 | plane | `e3 - e0`, the plane $z = 1$ |
| 2 | line | `e12`, a line |
| 3 | point | `e123`, a point |

The [[pga-objects|grade table]] is the whole object model. The key point is the
reversal of intuition relative to vectors-and-points algebra: in PGA a *plane*
is a vector and a *point* is a trivector, because the model is built from the
planes that cut space.

The degenerate direction is what makes it projective. Homogeneous coordinates
identify a point with any non-zero multiple of itself, and $e_0$ carries the
"at infinity" part of that identification: a [[pga-ideal-points|point with zero
weight]] is a direction, not a location. The [[pseudoscalar]] squares to zero,
so there is no [[hodge-dual]]; the dual is the [[complement]]
([[pga-no-dual]]), and the [[regressive|regressive product]] takes its place.

```ocaml
open Geom

let pi = Pga.plane3 0. 0. 1. 1. in        (* the plane z = 1 *)
let p = Pga.point3 0. 0. 1. in
Nx.item [] (Pga.weight p)                 (* 1.: a finite point *)
Nx.item [] (Pga.is_ideal p)               (* false *)
Nx.item [] (Pga.point_on_plane p pi)      (* true *)
```

Because the basis is already orthogonal ($e_1, e_2, e_3, e_0$ with the last
squared to zero), PGA needs no [[orthonormal-storage|null-basis trick]]. It is
the natural model for graphics and for plane-based incidence, and its
[[even-subalgebra|even part]] is the eight-dimensional
[[motor|dual-quaternion]] algebra shared with CGA ([[motor-shared]]).

@@@ slug: pga-objects
@@@ title: PGA objects live at fixed grades
@@@ tags: ga/model
@@@ aliases: PGA objects

In `Cl(3,0,1)` the object type is the grade, and the grade is the codimension:

| grade | blade | object |
| --- | --- | --- |
| 1 | `e1`, `e3`, `e0` | plane |
| 2 | `e12`, `e10` | line |
| 3 | `e123`, `e120` | point |

A plane with unit normal $bold(n) = n_1 e_1 + n_2 e_2 + n_3 e_3$ and offset $d$
— the set ${bold(x) : bold(n) dot bold(x) = d}$ — is the vector

```typst
pi = bold(n) - d e_0.
```

Here $e_0$ is the degenerate basis vector with $e_0^2 = 0$. The pair
$(bold(n), -d)$ is the homogeneous coordinate vector of the plane, so the plane
equation on a point $p$ is the wedge $p and pi = 0$ ([[pga-incidence]]), not a
contraction. A point is the wedge of three planes, so it is a trivector,
and its coefficient on $e_123$, the Euclidean pseudoscalar, is its weight
([[pga-ideal-points]]). A line is the wedge of two planes, a bivector with the
six Plücker components.

```ocaml
open Geom

let p = Pga.point3 1. 2. 3. in
Nx.item [] (Pga.weight p)             (* 1. *)
Nx.to_array (Pga.point_coords p)      (* [|1.; 2.; 3.|] *)
let l = Pga.line_through p (Pga.point3 1. 2. 4.) in
Nx.to_array (Pga.line_direction l)    (* parallel to z *)
Nx.to_array (Pga.line_moment l)       (* the moment about the origin *)
```

The point of the grade table is that incidence becomes a wedge, with no metric
involved; [[pga-incidence]] shows the predicates, and
[[pga-meet-join|meet and join]] turn them into an intersection calculus.

Two normalisations are easy to confuse. `Algebra.normalize` is the metric one
and is useless for a null object such as an ideal point.
`Pga.normalize_plane` divides by the normal's length so that the offset is a
signed distance, and `Pga.normalize_point` divides by the weight so that the
point is on the affine slice. The [[numerics|numerical note]] explains why
mixing them silently changes the geometry.

@@@ slug: pga-incidence
@@@ title: In PGA, incidence is the wedge
@@@ tags: ga/model
@@@ aliases: PGA incidence

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
is *always* zero in four dimensions, since the wedge would have grade 5; so
`point_on_line` uses the [[complement|complement dual]] instead — the library
hides that behind the predicate. Second, in a degenerate metric the wedge does
**not** reduce to a scalar contraction of a dual point with a plane, the way it
does in the conformal model ([[round-flat]]). Incidence here is genuinely
exterior, and [[pga-meet-join]] builds the intersection calculus on top of it.

@@@ slug: pga-meet-join
@@@ title: Meet and join in PGA
@@@ tags: ga/model
@@@ aliases: meet and join

Two operations carry the whole projective calculus:

- **meet** is the outer product: two planes meet in a line, a line and a plane
  meet in a point. It lowers the codimension, so it raises the grade.
- **join** is the [[regressive|regressive product]]: two points span a line, a
  point and a line span a plane.

Both are exact, polynomial, and free of division. That is the practical
difference from homogeneous matrices, where intersection requires a cross
product and a case analysis.

```ocaml
open Geom

let pi1 = Pga.plane3 1. 0. 0. 0.    (* x = 0 *)
and pi2 = Pga.plane3 0. 1. 0. 0. in (* y = 0 *)
let l = Pga.meet pi1 pi2 in
Nx.to_array (Pga.line_direction l)          (* parallel to z *)
let corner = Pga.meet l (Pga.plane3 0. 0. 1. 2.) in
Nx.to_array (Pga.point_coords corner)       (* [|0.; 0.; 2.|] *)
let same = Pga.join (Pga.point3 0. 0. 0.) (Pga.point3 0. 0. 1.) in
Nx.to_array (Pga.line_direction same)       (* parallel to z *)
```

![Three planes, the line where two of them meet, and the point where the third
cuts that line. Every incidence here is a wedge.](../../figures/pga-incidence.svg)

The naming is worth fixing in your head: in PGA, points are trivectors and
planes are vectors, so the *wedge* meets and the *regressive product* joins.
[[pga-incidence]] is the predicate-level version of the same story.
Reading `Pga.meet` as "the intersection" and `Pga.join` as "the span" keeps the
geometry straight even when the grade arithmetic feels inverted. The conformal
model has the opposite convention ([[working-representation]]).

@@@ slug: pga-ideal-points
@@@ title: Ideal points carry weight zero
@@@ tags: ga/model
@@@ aliases: ideal points, points at infinity, weight

A projective point is a trivector, and the coefficient of the Euclidean
pseudoscalar $e_123$ is its **weight**. Write $w(p)$ for that coefficient. A
finite point can be rescaled so that $w(p) = 1$; that is the affine slice, and
it is what `Pga.normalize_point` and `Pga.point_coords` use.

A point of weight zero is not a location at all. It is a **direction**: the
point at infinity in that direction. Algebraically it is a trivector whose
$e_123$ coefficient vanishes,

```typst
w(p) = 0 quad <==> quad p " lives at infinity",
```

and it is obtained with `Pga.ideal_point bold(d)`, where $bold(d)$ is the
direction vector. Directions and locations live in the same algebra,
distinguished by one coefficient.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in

let i = Pga.ideal_point (v3 0. 0. 1.) in
Nx.item [] (Pga.weight i)         (* 0. *)
Nx.item [] (Pga.is_ideal i)       (* true *)
Nx.item [] (Pga.is_ideal (Pga.point3 0. 0. 1.))  (* false *)
```

This is the mechanism behind the [[pga-objects|object table]]: a line through
two finite points has a direction and a moment ([[pga-meet-join]]), and the
direction part is the ideal point it contains. It is also the projective
analogue of the conformal [[point-at-infinity]], though the two are not the
same object: in `Cl(4,1)` infinity is a single null vector, and flats are the
objects that contain it ([[round-flat]]).

@@@ slug: pga-no-dual
@@@ title: PGA has no Hodge dual, and that is the point
@@@ tags: ga/model
@@@ aliases: no Hodge dual in PGA

The [[pseudoscalar]] of `Cl(3,0,1)` is $I = e_1 e_2 e_3 e_0$, and it squares to
zero, because the degenerate direction appears in the product and $e_0^2 = 0$.
A zero square means no inverse, which means the [[hodge-dual]] $A I^(-1)$ of a
multivector $A$ does not exist. The library says so loudly: `dual` raises `Invalid_argument` for a
degenerate signature.

What survives is the [[complement]], a signed permutation of the coefficients
that needs no metric:

```ocaml
open Geom

(* dual works in the conformal model, where I^2 = -1 *)
let star = Cga.dual (Cga.point3 1. 0. 0.) in
(* in PGA the same idea is the complement *)
let c = Pga.complement (Pga.plane3 0. 0. 1. 0.) in
Nx.item [] (Pga.grade 0 (Pga.gp Pga.pseudoscalar Pga.pseudoscalar))  (* 0. *)
```

The complement is what defines the [[regressive|regressive product]], so
[[pga-meet-join|meet and join]] remain exact. What you lose is the ability to
turn a blade into "the same object in the other grade" with a *metric*
statement attached; in a degenerate algebra that statement would be a division
by zero.

The practical rule is the one in [[numerics]]: never route a generic `dual`
through both models. A dual in `Cl(4,1)` and a complement in `Cl(3,0,1)` agree
on index sets and disagree on signs, and mixing them produces geometry that is
subtly mirrored.

@@@ slug: cga
@@@ title: Cl(4,1) is the conformal model of 3D space
@@@ tags: ga/model
@@@ aliases: CGA, conformal geometric algebra, Cl(4,1)

The conformal model takes five orthonormal directions — four positive, one
negative — and defines two null combinations

```typst
e_0 = 1/2 (e_5 - e_4), quad e_oo = e_4 + e_5,
```

with $e_0^2 = e_oo^2 = 0$ and $e_0 dot e_oo = -1$. Here $e_4$ and $e_5$ are the
two extra basis vectors, with $e_4^2 = +1$ and $e_5^2 = -1$; the Euclidean
directions $e_1, e_2, e_3$ are untouched. This is `Cl(4,1)`, 32 coefficients,
and its objects are a strict superset of everything in the Euclidean and
projective models.

The extra dimensions buy four things at once: Euclidean points become
[[conformal-embedding|null vectors]], distance becomes an
[[conformal-distance|inner product]], spheres and planes become vectors
([[cga-sphere]], [[cga-plane]]), and the whole Möbius group — rotations,
translations, dilations and inversions — becomes the group of
[[versor|versors]] ([[mobius-group]]).

```ocaml
open Geom

(Signature.to_string Cga.signature, Cga.size)   (* ("(4,1,0)", 32) *)
Cga.to_array Cga.einf                           (* 1 on e4 and e5 *)
Cga.to_array Cga.e0                             (* 1/2 on e5, -1/2 on e4 *)
Nx.item [] (Cga.scalar_prod Cga.e0 Cga.einf)    (* -1. *)
```

The storage is in the orthonormal basis, not the null basis, for a reason that
matters for the software ([[orthonormal-storage]]). The object layer stores the
*lower* of the two dual representatives ([[working-representation]]), which is
what makes incidence a single contraction. Rigid motions are handled by the
packed eight-component [[motor]] so that kinematics never pays for 32
coefficients.

@@@ slug: conformal-embedding
@@@ title: A conformal point is a null vector
@@@ tags: ga/model
@@@ aliases: conformal embedding, point representation

Write a Euclidean point as $bold(x) = x_1 e_1 + x_2 e_2 + x_3 e_3$, with
coordinates $x_i$, and let $norm(bold(x))^2 = sum_i x_i^2$. The conformal model
represents it by the vector

```typst
X = bold(x) + 1/2 norm(bold(x))^2 e_oo + e_0.
```

Here $e_0$ and $e_oo$ are the two null combinations of the extra basis vectors
of `Cl(4,1)`, with
$e_0^2 = e_oo^2 = 0$ and $e_0 dot e_oo = -1$. The vector is null, $X^2 = 0$,
and it lies on the affine slice $e_oo dot X = -1$. The null condition is the
whole trick: the quadratic term is exactly what cancels
the squared length against the two extra directions. Conversely, any null
vector on that slice is a point. To see it, write
$X = bold(x) + a e_oo + b e_0$ with unknown coefficients $a$ and $b$. Then
$e_oo dot X = -b = -1$ forces $b = 1$, and
$X^2 = norm(bold(x))^2 - 2 a = 0$ forces $a = norm(bold(x))^2 slash 2$. So the
conformal points are exactly the null vectors of the slice, and reading the
coordinates back is a projection: $x_i = e_i dot X$.

```ocaml
open Geom

let x = Cga.point3 1. 2. 3. in
Nx.item [] (Cga.norm2 x)                    (* 0.: null *)
Nx.item [] (Cga.scalar_prod Cga.einf x)     (* -1.: on the slice *)
Nx.to_array (Cga.coords x)                  (* [|1.; 2.; 3.|] *)
```

![The embedding of a line: the coordinate x becomes a point on a parabola, and
the chord length encodes the distance.](../../figures/null-parabola.svg)

The quadratic term is what makes the inner product of two points depend only on
their separation ([[conformal-distance]]), and it is why the representation is
nonlinear in the coordinates while every operation on it is linear in the
algebra. A dilation or a translation rescales the representative, and
`Cga.coords` renormalises by $-e_oo dot X$ before reading ([[numerics]]).

@@@ slug: conformal-distance
@@@ title: Distance is an inner product
@@@ tags: ga/model
@@@ aliases: distance identity

For two conformal points $X$ and $Y$, representing Euclidean points $bold(x)$
and $bold(y)$ by the embedding of [[conformal-embedding]],

```typst
X dot Y = -1/2 norm(bold(x) - bold(y))^2.
```

That is the one identity to remember. It follows in one line from the embedding:
the cross terms with $e_oo$ and $e_0$ cancel, leaving

```typst
X dot Y = bold(x) dot bold(y) - 1/2 norm(bold(x))^2 - 1/2 norm(bold(y))^2
        = -1/2 norm(bold(x) - bold(y))^2.
```

Everything else in the conformal model — incidence, angle, intersection, even
the round/flat distinction — is a corollary of it or of the same contraction
pattern.

```ocaml
open Geom

let x = Cga.point3 1. 1. 0. and y = Cga.point3 4. 5. 0. in
Nx.item [] (Cga.scalar_prod x y)   (* -12.5 *)
Nx.item [] (Cga.distance2 x y)     (* 25. *)
Nx.item [] (Cga.distance x y)      (* 5. *)
```

The minus sign is not cosmetic: it makes the scalar product of distinct real
points negative definite in the difference, so a zero scalar product means
coincident points and the squared distance is $-2 X dot Y$ with no absolute
value. The library's `distance2` is exactly `-2 *` the scalar product, and
`distance` guards the square root against the small negative values that
rounding produces for coincident points.

Two consequences worth carrying: incidence is the same contraction against a
different blade ([[round-flat]]), and the whole object layer is arranged so that
a point and an object are tested with one expression
([[working-representation]]). That uniformity is why
[[polynomial-predicates|predicates become polynomial]] and why the conformal
model is pleasant to differentiate through ([[ga-residuals]]).

@@@ slug: point-at-infinity
@@@ title: e∞ is the point at infinity
@@@ tags: ga/model
@@@ aliases: point at infinity, einf

The vector $e_oo = e_4 + e_5$ is null, but it is not on the point slice:
$e_oo dot e_oo = 0$, not $-1$. It is the extra point of the conformal
compactification $RR^3 union {infinity}$, and it plays a structural role far
beyond being "one more point".

A *flat* object is one that contains $e_oo$. A plane
$pi = bold(n) + d e_oo$, with unit normal $bold(n)$ and offset $d$, satisfies
$e_oo dot pi = 0$; a sphere does not; a line does; a circle does not. That is
the entire [[round-flat|round/flat dichotomy]], and it is a single contraction.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let pi = Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 1.) in
Nx.item [] (Cga.scalar_prod Cga.einf pi)              (* 0.: flat *)
Nx.item [] (Cga.scalar_prod Cga.einf (Cga.point3 0. 0. 0.))  (* -1.: round *)
```

`e_oo` is also the generator of translations: for a translation vector
$bold(t)$, the bivector $bold(t) and e_oo$ is null, so its exponential
terminates ([[translator]]). And the versors that fix $e_oo$ exactly are precisely the Euclidean group;
composing one with a [[dilator|dilation]] scales $e_oo$. In a degenerate algebra the same role is played by the
separate direction $e_0$ ([[pga-ideal-points]]), but there it is a whole plane
of ideal points rather than one point.

@@@ slug: cga-sphere
@@@ title: A sphere is a vector
@@@ tags: ga/model
@@@ aliases: sphere representation

With $C$ the conformal point of the centre $bold(c)$ and $r$ the radius, the
sphere is

```typst
S = C - 1/2 r^2 e_oo.
```

Here $e_oo$ is the point at infinity, the null vector $e_4 + e_5$ of
`Cl(4,1)`. The sphere is a grade-1 vector, not a four-blade. Its square is the
squared radius,
$S^2 = r^2$, and it satisfies $e_oo dot S = -1$, so it is a round object
([[round-flat]]). Incidence is the same contraction as always: a point $X$ is
on the sphere exactly when $X dot S = 0$, and the value of that contraction is
a signed measure of how far the point is from the surface — positive inside,
negative outside,

```typst
X dot S = -1/2 (norm(bold(x) - bold(c))^2 - r^2).
```

The derivation is two lines: $X dot C = -1 slash 2 norm(bold(x) - bold(c))^2$
by [[conformal-distance]], and $X dot e_oo = -1$ for every finite point, so
$X dot S = X dot C - 1 slash 2 r^2 (X dot e_oo)$ gives the formula.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let s = Cga.sphere ~center:(v3 0. 0. 0.) ~radius:(sc 2.) in
Nx.item [] (Cga.sphere_radius2 s)                     (* 4. *)
Nx.item [] (Cga.incident (Cga.point3 2. 0. 0.) s)     (* true *)
Nx.to_array (Cga.coords (Cga.sphere_center s))        (* [|0.; 0.; 0.|] *)
```

Three practical notes. The representation is homogeneous, so
`Cga.normalize_sphere` divides by $-e_oo dot S$ before comparing radii. The
radius may be imaginary, in which case $S^2 < 0$; do not force it positive
([[numerics]]). And the four-blade representative is the wedge of four points
on the sphere ([[sphere-through-four]]), which is the *dual* picture; the vector
is the working representation ([[working-representation]]).

@@@ slug: cga-plane
@@@ title: A plane is a vector
@@@ tags: ga/model
@@@ aliases: plane representation

A plane with unit normal $bold(n)$ and offset $d$ is the set
${bold(x) : bold(n) dot bold(x) = d}$. In the conformal model it is the vector

```typst
pi = bold(n) + d e_oo.
```

Here $e_oo$ is the point at infinity, the null vector $e_4 + e_5$ of
`Cl(4,1)`. This is also a grade-1 vector, but a different kind: $pi^2 = 1$ and
$e_oo dot pi = 0$, so it is flat ([[round-flat]]). The contraction with a point
is the signed distance,

```typst
X dot pi = bold(n) dot bold(x) - d,
```

as the cross terms with $e_oo$ and $e_0$ cancel.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let pi = Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 1.) in
Nx.item [] (Cga.norm2 pi)                                     (* 1. *)
Nx.item [] (Cga.scalar_prod (Cga.point3 4. 5. 3.) pi)         (* 2. *)
Nx.item [] (Cga.scalar_prod (Cga.point3 4. 5. 1.) pi)         (* 0. *)
Nx.item [] (Cga.is_flat pi)                                   (* true *)
```

The normal is not normalised by the constructor; `Cga.normalize_plane` divides
by the length of the Euclidean part so that the offset is a true distance and
$pi^2 = 1$. That is a *projective* normalisation, not the metric
`normalize` of the [[blade-inverse|inverse]] machinery, and the two must not be
mixed ([[numerics]]).

The plane is the flat member of the same family as the sphere: same grade,
same incidence test, different value of $e_oo dot O$, where $O$ is the
grade-1 object vector. Three points and $e_oo$ wedge
to its dual ([[objects-from-points]]), and a plane is also a sphere of infinite
radius in the limiting sense that makes [[mobius-group|the Möbius group]] act
on both.

@@@ slug: round-flat
@@@ title: Round versus flat: the e∞ contraction decides
@@@ tags: ga/model
@@@ aliases: round objects, flat objects

For a homogeneous grade-1 object $O$, the contraction with the point at
infinity $e_oo = e_4 + e_5$ separates the two families:

```typst
e_oo dot O = cases(
  -1 & "round (sphere, point), after normalisation",
  0 & "flat (plane), after normalisation",
)
```

and the radius formula

```typst
R^2 = O^2 / (e_oo dot O)^2
```

gives a finite radius for a round object and blows up for a flat one. Here
$O^2$ is the geometric square of the object vector and $R$ is the radius. For
a sphere $O = C - 1 slash 2 R^2 e_oo$, the numerator is $R^2$ and the
denominator is $1$; for a plane the denominator is zero.

For a blade $A$ in the working representation, the same contraction with the
appropriate grade does the job: $e_oo dot A = 0$ exactly when $A$ is flat.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let s = Cga.sphere ~center:(v3 0. 0. 0.) ~radius:(sc 1.) in
let pi =
  Cga.normalize_plane (Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.))
in
Nx.item [] (Cga.scalar_prod Cga.einf s)    (* -1.: round *)
Nx.item [] (Cga.scalar_prod Cga.einf pi)   (* 0.: flat *)
Nx.item [] (Cga.is_round s)                (* true *)
Nx.item [] (Cga.is_flat pi)                (* true *)
```

![Round versus flat: a sphere has e-infinity dot S = -1, a plane has
e-infinity dot pi = 0. The single contraction with the point at infinity
decides the family.](../../figures/round-flat.svg)

The library exposes the test as boolean tensors (`is_flat`, `is_round`) rather
than a host-side variant, so batching, tracing and autodiff survive
([[batching]], [[traced]]). Circles and point pairs are round, lines are flat;
that is why the circle's carrier plane can be extracted with the same
contraction ([[circle-carrier]]), and why a point pair is the zero-dimensional
round object ([[point-pair]]).

@@@ slug: working-representation
@@@ title: The working representation stores the lower grade
@@@ tags: ga/model
@@@ aliases: dual picture, working representation

Every conformal object has two representatives: the *direct* blade, built by
wedging conformal points $X_1, X_2, X_3, X_4$ (plus $e_oo$ for flats), and its
*dual*. Here $e_oo$ is the point at infinity, the null vector $e_4 + e_5$. The
library stores whichever has the lower grade, because that is the one with the
simplest incidence test.

| object | direct blade | dual blade | incidence |
| --- | --- | --- | --- |
| point | `X` (1) | `X*` (4) | `Y . X = 0` |
| point pair | `X1 ^ X2` (2) | `(X1 ^ X2)*` (3) | `X . P = 0` |
| circle | `X1 ^ X2 ^ X3` (3) | `z` (2) | `X . z = 0` |
| sphere | `X1 ^ X2 ^ X3 ^ X4` (4) | `S` (1) | `X . S = 0` |
| line | `X1 ^ X2 ^ e∞` (3) | `l` (2) | `X . l = 0` |
| plane | `X1 ^ X2 ^ X3 ^ e∞` (4) | `pi` (1) | `X . pi = 0` |

The number in parentheses is the grade. The uniformity is the point: for any
object blade $O$ in the working representation and any point $Y$ being tested,
incidence is $Y dot O = 0$. One expression, one code path, one contraction.

```ocaml
open Geom
let p = Cga.point3 in
let z = Cga.circle (p 1. 0. 0.) (p 0. 1. 0.) (p (-1.) 0. 0.) in
Nx.item [] (Cga.incident (p 0. (-1.) 0.) z)   (* true *)
Nx.item [] (Cga.incident (p 0. 0. 1.) z)      (* false *)
```

Three remarks. The dual of a point is a four-blade, the pencil of spheres
through it, not another point. The star is an involution only up to sign,
$(A^*)^* = -A$ in `Cl(4,1)` for a multivector $A$, so `undual` is its own
function
([[hodge-dual]]). And `Cga.meet` is only uniform for grade-one constraints;
mixing a point with a constraint is not the wedge, so use the named
constructors ([[objects-from-points]], [[cga-tradeoffs]]).

@@@ slug: objects-from-points
@@@ title: Wedge the points, then dualise
@@@ tags: ga/model
@@@ aliases: objects from points, construction recipe

The outer product of conformal points spans the projective subspace through
them: for $k$ points it is a grade-$k$ blade. Dualising turns that span into a
constraint that contains all the points — a sphere, a circle, a line or a
plane. Here $e_oo$ is the point at infinity, the null vector $e_4 + e_5$ of
`Cl(4,1)`. Writing $X_i$ for conformal points:

- four points $->$ a sphere: $S = (X_1 and X_2 and X_3 and X_4)^*$;
- three points and $e_oo$ $->$ a plane:
  $pi = (X_1 and X_2 and X_3 and e_oo)^*$;
- three points $->$ a circle: $z = (X_1 and X_2 and X_3)^*$;
- two points and $e_oo$ $->$ a line: $l = (X_1 and X_2 and e_oo)^*$;
- two points $->$ a point pair: $P = X_1 and X_2$, already direct.

The $e_oo$ is exactly the indicator of "flat" ([[round-flat]]): add it for a
plane or a line, omit it for a sphere or a circle.

![The four constructions side by side: two points give a point pair, three a
circle, four a sphere, and three points plus e-infinity a plane. In each panel
the points are the input and the object is the dual of their wedge.](../../figures/object-construction.svg)

```ocaml
open Geom
let p = Cga.point3 in
let circle = Cga.circle (p 1. 0. 0.) (p 0. 1. 0.) (p (-1.) 0. 0.) in
let line   = Cga.line (p 1. 0. 1.) (p (-1.) 0. 1.) in
let plane  = Cga.plane_through (p 1. 0. 0.) (p 0. 1. 0.) (p 0. 0. 1.) in
let sphere = Cga.sphere_through (p 1. 0. 0.) (p (-1.) 0. 0.)
                                (p 0. 1. 0.) (p 0. 0. 1.) in
Nx.item [] (Cga.circle_radius2 circle)   (* 1. *)
```

![Three points on a circle; the circle is the dual of their wedge. The triangle
is the direct blade, the circumcircle the constraint.](../../figures/wedge-dualise.svg)

This is the cleanest way to build objects, and the reason the library's
constructors are mostly "wedge the points, then dualise". It also means you
never have to solve for a sphere; the algebra does the linear algebra, and the
[[numerics|projective scale]] is the only thing left to normalise.

@@@ slug: cga-line
@@@ title: A line is a 2-blade
@@@ tags: ga/model
@@@ aliases: lines in CGA

A line is the intersection of two planes, so in the working representation it
is the bivector $l = pi_1 and pi_2$, where $pi_1$ and $pi_2$ are the two plane
vectors. Here $e_oo$ is the point at infinity, the null vector $e_4 + e_5$.
From two conformal points $X_1, X_2$, and with the flat flag,

```typst
l = (X_1 and X_2 and e_oo)^*.
```

It is a grade-2 blade, and a point $X$ lies on it exactly when $X dot l = 0$.
Its six independent coefficients are the Plücker coordinates: a Euclidean
bivector part encoding the direction and an $e_i e_oo$ part encoding the
moment, where $e_i$ is a Euclidean basis vector.

```ocaml
open Geom

let a = Cga.point3 1. 0. 1. and b = Cga.point3 (-1.) 0. 1. in
let l = Cga.line a b in
Nx.to_array (Cga.line_direction l)                     (* parallel to x *)
Nx.to_array (Cga.line_moment l)                 (* perpendicular to it *)
Nx.item [] (Cga.incident (Cga.point3 0. 0. 1.) l)      (* true *)
Nx.item [] (Cga.incident (Cga.point3 0. 1. 1.) l)      (* false *)
```

Because the Plücker relation is automatic in the wedge form, you cannot build an
inconsistent line this way; that is a real advantage over writing six numbers
by hand. Lines are flat ([[round-flat]]), so $e_oo dot l = 0$, and they sit in
the same family as planes rather than circles. Two planes meeting in a line is
the `Cga.line_of_planes` constructor; the projective version of the same story
is [[pga-objects|the PGA line]], which is also a bivector but with a different
meaning for the degenerate coefficient.

@@@ slug: cga-circle
@@@ title: A circle is a 2-blade
@@@ tags: ga/model
@@@ aliases: circles in CGA

A circle is the intersection of two spheres, so it is the bivector
$z = S_1 and S_2$, where $S_1$ and $S_2$ are the two sphere vectors. Here
$e_oo$ is the point at infinity, the null vector $e_4 + e_5$. From three
points,

```typst
z = (X_1 and X_2 and X_3)^*.
```

A point $X$ lies on it exactly when $X dot z = 0$, which is the simultaneous
satisfaction of the two sphere equations. The circle is *round*
($e_oo dot z != 0$), and its carrier plane is recovered by contracting with
$e_oo$ ([[circle-carrier]]). Centre, radius and normal are all extractors on
the same blade.

```ocaml
open Geom

let a = Cga.point3 1. 0. 0.
and b = Cga.point3 0. 1. 0.
and c = Cga.point3 (-1.) 0. 0. in
let z = Cga.circle a b c in
Nx.item [] (Cga.circle_radius2 z)                    (* 1. *)
Nx.to_array (Cga.coords (Cga.circle_center z))       (* [|0.; 0.; 0.|] *)
Nx.to_array (Cga.circle_normal z)                    (* unit normal: (0,0,1) *)
Nx.item [] (Cga.incident (Cga.point3 0. (-1.) 0.) z) (* true *)
```

The three defining points must be distinct. If they are collinear, the result
is not a zero blade but a *flat* 2-blade: the line through them, with an
undefined radius ([[numerics]]). A circle is the exact analogue of a line one
dimension up: a flat 2-blade is a line, a round one is a circle, and the
[[round-flat|contraction with e∞]] tells them apart. Point pairs are the
dimension-zero version ([[point-pair]]), spheres the dimension-two version
([[sphere-through-four]]).

@@@ slug: point-pair
@@@ title: A point pair is a hyperbolic 2-blade
@@@ tags: ga/model
@@@ aliases: point pairs

For two conformal points $X$ and $Y$, the point pair is the direct 2-blade

```typst
P = X and Y.
```

Because both factors are null, its square is a scalar:

```typst
P^2 = (X dot Y)^2 = d^4 / 4, quad d = norm(bold(x) - bold(y)),
```

where $bold(x)$ and $bold(y)$ are the Euclidean coordinates and $d$ is their
distance. The first equality is the identity $(X and Y)^2 = (X dot Y)^2$ for
null $X, Y$; the second substitutes [[conformal-distance]].

So a point pair of distinct real points is a *hyperbolic* blade with a positive
square, and it is null exactly when the points coincide. It is a
zero-dimensional object: not a constraint blade, and best stored in its direct
form rather than dualised.

```ocaml
open Geom

let x = Cga.point3 0. 0. 0. and y = Cga.point3 2. 0. 0. in
let p = Cga.point_pair x y in
Nx.item [] (Cga.coeff (Cga.gp p p) (Blade.of_int 0))   (* 4. = d^4/4 *)
Nx.item [] (Cga.incident x p)                          (* true *)
Nx.item [] (Cga.incident (Cga.point3 1. 0. 0.) p)      (* false *)
```

The scalar $d^4 slash 4$ is the invariant that survives an arbitrary rescaling
of either point, which is why it is the right thing to test rather than the raw
coefficients. Point pairs appear as tangential intersections: when a line
touches a sphere, the meet is a double point pair, and its vanishing square is
the tangency condition. The library also obtains them as the dual of
$l and S$ when a line $l$ and a sphere $S$ intersect ([[cga-line]]).

@@@ slug: sphere-through-four
@@@ title: Four points determine a sphere
@@@ tags: ga/model
@@@ aliases: sphere through four points

The outer product of four conformal points $X_1, X_2, X_3, X_4$ is a grade-4
blade, and its dual is the sphere vector through them:

```typst
S = (X_1 and X_2 and X_3 and X_4)^*.
```

This is the conformal version of a linear solve: the wedge is the determinant,
and the dual reads the answer off the coefficients. No normalisation is needed
until you want the radius.

```ocaml
open Geom
let p = Cga.point3 in
let s = Cga.sphere_through (p 1. 0. 0.) (p (-1.) 0. 0.)
                           (p 0. 1. 0.) (p 0. 0. 1.) in
Nx.item [] (Cga.sphere_radius2 s)   (* 1. *)
Nx.item [] (Cga.incident (p 0. 1. 0.) s)  (* true *)
```

The four points must be affinely independent: four coplanar points make the
wedge vanish, and the library returns the zero blade rather than a diagnostic
([[numerics]]). If you have more than four input points $X_i$ on an approximate sphere, the
right move is a least-squares fit whose residuals are the contractions
$X_i dot S$ — which is exactly the [[ga-residuals|residual]] pattern, and the
same one used for fitting planes and circles.

The sphere is the round counterpart of the plane through three points
([[objects-from-points]]); both are "wedge, add $e_oo$ for flat, dualise".

@@@ slug: circle-carrier
@@@ title: The carrier plane of a circle
@@@ tags: ga/model
@@@ aliases: carrier plane

A circle is a round 2-blade, so it does not contain the point at infinity
$e_oo = e_4 + e_5$. But contracting it with $e_oo$ still produces a plane:

```typst
pi_z = e_oo dot z = S_1 - S_2,
```

which is the radical plane of the two spheres $S_1$ and $S_2$ and contains the
whole circle $z = S_1 and S_2$. That contraction is how you recover the plane
the circle lies in, without any coordinate arithmetic.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

let s1 = Cga.sphere ~center:(v3 0. 0. 0.) ~radius:(sc 1.) in
let s2 = Cga.sphere ~center:(v3 0. 0. 1.) ~radius:(sc 1.) in
let z = Cga.circle_of_spheres s1 s2 in
Nx.to_array (Cga.coords (Cga.circle_center z))   (* [|0.; 0.; 0.5|] *)
Nx.to_array (Cga.circle_normal z)                (* unit normal: (0,0,1) *)
Nx.item [] (Cga.circle_radius2 z)                (* 0.75 *)
```

Centre and radius follow from the plane and either sphere: the centre is the
orthogonal projection of the sphere centre onto the plane, and the radius
satisfies $r^2 = r_1^2 - delta^2$, where $r_1$ is the radius of $S_1$ and
$delta$ is the distance from the centre of $S_1$ to the plane. In the example
the centres are one unit apart with equal radii, so $delta = 1 slash 2$, the
radical plane is the bisector at $z = 1 slash 2$, and the radius is
$sqrt(3) slash 2$.

This is the model's characteristic mixture: geometrically transparent,
algebraically uniform, and requiring one small computation to get a number out
([[working-representation]]).

@@@ slug: dilator
@@@ title: A dilation is a boost in the e4e5 plane
@@@ tags: ga/model
@@@ aliases: dilation

A dilation by the factor $e^lambda$ is generated by the bivector $e_4 e_5$,
where $e_4$ and $e_5$ are the two extra orthonormal basis vectors of `Cl(4,1)`,
with $e_4^2 = 1$ and $e_5^2 = -1$. They mix into the null directions
$e_0 = 1 slash 2 (e_5 - e_4)$ and $e_oo = e_4 + e_5$. The bivector $e_4 e_5$
squares to $+1$, so the exponential is the hyperbolic case of
[[bivector-exp|the bivector exponential]]:

```typst
D = exp(-lambda/2 e_4 e_5) = cosh(lambda/2) - sinh(lambda/2) e_4 e_5.
```

It fixes the origin and rescales the two null directions:
$e_oo |-> e^lambda e_oo$ and $e_0 |-> e^(-lambda) e_0$. Its sandwich action on
a point is projective: the raw image has $e_0$ coefficient $e^(-lambda)$, so
`Cga.coords` divides by that and the Euclidean coordinates are multiplied by
$e^lambda$.

```ocaml
open Geom

let d = Cga.dilator (Nx.scalar Nx.float32 0.5) in
let x = Cga.point3 1. 0. 0. in
Nx.to_array (Cga.coords (Cga.sandwich d x))   (* e^0.5 * [|1.; 0.; 0.|] *)
```

Two uses in robotics. A scale-normalised objective can be made scale-invariant
by composing with a dilation, and a workspace defined up to similarity can be
canonicalised with one. More importantly, the dilation is the simplest example
of the projective character of the whole conformal model: the versor action is
linear on the null cone, but the induced action on coordinates is only defined
up to scale, and something has to fix the scale ([[numerics]]).

@@@ slug: transversion
@@@ title: A transversion bends space without moving infinity
@@@ tags: ga/model
@@@ aliases: transversion, special conformal transformation

A transversion with parameter vector $bold(a) = a_1 e_1 + a_2 e_2 + a_3 e_3$
is generated by the null bivector $-a_i e_i and e_0$, summed over $i = 1, 2, 3$.
Here $e_1, e_2, e_3$ are the Euclidean basis vectors and $e_0$ is the null
direction $1 slash 2 (e_5 - e_4)$. The bivector is nilpotent, so the exponential
terminates:

```typst
K = exp(-a_i e_i and e_0) = 1 - a_i e_i e_0.
```

The normalised action is the special conformal transformation

```typst
bold(x) |-> (bold(x) + bold(a) norm(bold(x))^2)
           / (1 + 2 bold(a) dot bold(x) + norm(bold(a))^2 norm(bold(x))^2),
```

which is nonlinear in the coordinates but linear on the null cone. That is the
whole point of the embedding: the conformal group acts by linear maps on the
underlying five-dimensional vector space $RR^(4,1)$.

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in

let k = Cga.transversion (v3 0.5 0. 0.) in
let x = Cga.point3 1. 0. 0. in
Nx.to_array (Cga.coords (Cga.sandwich k x))   (* [|0.6667; 0.; 0.|] *)
```

![A square grid pushed through a transversion: the map is conformal, so
right angles survive and only the scale varies.](../../figures/transversion-grid.svg)

A transversion is *not* a rigid motion, so it has no
[[motor|`Motor.t`]] representation; it lives only in the dense algebra
([[motor-shared]]). That is why the renderer's `Primitive.transform` can only
apply motors, and why conformal transformations of a scene must be applied to
the algebra objects and re-extracted ([[viz-adapters]]).

@@@ slug: mobius-group
@@@ title: The conformal group has ten generators
@@@ tags: ga/model
@@@ aliases: conformal group, Mobius group, generators

In `Cl(4,1)` the versor group is $"Spin"(4,1)$, a double cover of $"SO"(4,1)$,
which is the Möbius group of $RR^3$. Here $e_1, e_2, e_3$ are the Euclidean
basis vectors, $e_4, e_5$ the two extra ones (with $e_4^2 = 1$, $e_5^2 = -1$),
$e_0 = 1 slash 2 (e_5 - e_4)$ and $e_oo = e_4 + e_5$ the two null directions,
and $e_(i j)$ means $e_i e_j$. Its Lie algebra is spanned by ten bivectors:

- three rotations: $e_23, e_31, e_12$;
- three translations: $e_1 and e_oo, e_2 and e_oo, e_3 and e_oo$;
- one dilation: $e_4 e_5$;
- three transversions: $e_1 and e_0, e_2 and e_0, e_3 and e_0$.

Six of them — rotations and translations — preserve $e_oo$ and form the Lie
algebra of `SE(3)`. That is why a [[motor|motor]] is exactly the subalgebra
generated by $e_(i j)$ and $e_i and e_oo$, and why it needs only eight
coefficients ([[motor-shared]]). The dilation scales $e_oo$ and $e_0$; the
transversions do not preserve $e_oo$ at all ([[transversion]]).

```ocaml
open Geom

(* the six SE(3) generators, as dense bivectors *)
let rot = [ Cga.op Cga.e2 Cga.e3; Cga.op Cga.e3 Cga.e1;
            Cga.op Cga.e1 Cga.e2 ] in
let tr  = [ Cga.op Cga.e1 Cga.einf; Cga.op Cga.e2 Cga.einf;
            Cga.op Cga.e3 Cga.einf ] in
List.length (rot @ tr)     (* 6 *)
```

The [[commutator]] closes on these ten, and the exponential of any of them is
available in closed form ([[bivector-exp]]). For robotics, the useful habit is
to stay in the six: dilations and transversions are occasionally valuable for
scale-invariant objectives and for inversion-based constraints, but they are
not poses, and they do not belong in a kinematic chain ([[cga-tradeoffs]]).

@@@ slug: cga-tradeoffs
@@@ title: When the conformal model is worth it
@@@ tags: ga/model
@@@ aliases: conformal trade-offs, why conformal

The conformal model is not free. A multivector is 32 coefficients instead of 8
for a motor, an incidence test costs a contraction instead of a dot product,
and every object carries a projective scale that has to be normalised before
comparison ([[numerics]]).

It earns its keep when a task mixes **object geometry** with **kinematics**:
keeping a point on a sphere, intersecting a line with a plane, grasping a
cylinder, fitting a circle, asking whether two spheres meet. Those questions
have one-line algebraic answers ([[objects-from-points]],
[[working-representation]]) and polynomial [[ga-residuals|residuals]].

It does not earn its keep when the task only needs poses and twists. There the
packed [[motor]] — which is exactly a dual quaternion — is the right layer, and
the library is designed so that you can use it without dragging the object
layer along: kinematics pays 8 numbers, not 32.

The intermediate case is [[pga|PGA]]: 16 coefficients, exact incidence, no
Hodge dual, no distance. It is the right model for graphics and for
plane-based constraints where a metric is not needed.

What is *not* on the table is a cheaper conformal model of three dimensions:
the two extra dimensions are exactly what turns distance into an inner product
([[conformal-distance]]), and there is no way to buy that with fewer
coefficients. [[alternatives]] is the honest comparison with the tools you
would otherwise use.
