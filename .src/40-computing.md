@@@ slug: batching
@@@ title: The last axis is the blade axis
@@@ tags: ga/computing
@@@ aliases: shapes, batching convention

Every value in the library is an ordinary `Nx` tensor whose **last** axis is the
blade axis, of length $2^n$, where $n$ is the dimension of the algebra. The
leading axes are batch axes, broadcast exactly as everywhere else in `Nx`. So,
with $B$, $H$ and $W$ standing for an arbitrary batch count, height and width:

```typst
"one multivector" &: [|2^n|], quad
"a batch of" B &: [|B; 2^n|], quad
"an image" &: [|H; W; 2^n|].
```

A constructor such as `Cga.point` takes coordinates of shape
`batch @ [|3|]` and returns `batch @ [|32|]`. An extractor such as `Cga.coords`
goes the other way. Products broadcast over the leading axes, which is why the
same code maps over a single point, a batch of grasp candidates, or a whole
image.

```ocaml
open Geom

let centers = Nx.create Nx.float32 [| 4; 3 |]
    [| 0.; 0.; 0.; 1.; 0.; 0.; 0.; 1.; 0.; 0.; 0.; 1. |] in
let xs = Cga.point centers                               (* [|4; 32|] *)
Nx.shape (Cga.distance2 xs (Cga.point3 0. 0. 0.))        (* [|4|] *)
Nx.to_array (Cga.distance2 xs (Cga.point3 0. 0. 0.))
(* [|0.; 1.; 1.; 1.|] *)
```

The packed [[motor]] follows the same convention with last axis 8, so poses
batch alongside objects and there is no separate batching API. Two consequences
for the implementation: the algebra is a batched contraction over the last axis
([[structure-constants]]), and nothing may read a tensor value on the host — a
host read would break tracing and differentiable batching ([[traced]]).

@@@ slug: orthonormal-storage
@@@ title: Store the orthonormal basis, read the null basis
@@@ tags: ga/computing
@@@ aliases: storage basis, null basis

The null basis $(e_1, e_2, e_3, e_0, e_oo)$ is the right basis for *reading*
conformal geometry: points have simple coordinates, spheres and planes are short
vectors. But it is not orthogonal, since $e_0 dot e_oo = -1$, and the whole
[[basis-blades|bitmask product rule]] assumes orthogonality. In a
non-orthogonal basis the product of two basis vectors is not a single blade.

So the library stores coefficients in the orthonormal frame $e_1, dots, e_5$
and defines $e_0$ and $e_oo$ as derived multivectors:

```typst
e_0 = 1/2 (e_5 - e_4), quad e_oo = e_4 + e_5.
```

```ocaml
open Geom

Cga.to_array Cga.e0
(* -0.5 on e4, +0.5 on e5, and zero elsewhere *)
Nx.item [] (Cga.scalar_prod Cga.e0 Cga.einf)   (* -1. *)
Nx.item [] (Cga.scalar_prod Cga.einf Cga.einf) (* 0. *)
```

Points, spheres and planes still have a handful of nonzero coefficients, so the
product stays sparse; what you give up is the prettiness of printing
$bold(x) + 1 slash 2 norm(bold(x))^2 e_oo + e_0$. What you keep is a uniform
grade structure, a xor-indexed product, and one code path for all three models.

PGA needs no such trick: its natural basis $e_1, e_2, e_3, e_0$ is already
orthogonal, with the last vector squared to zero ([[pga]]). That is one small
reason the projective model is the cheaper of the two
([[cga-tradeoffs]]).

@@@ slug: structure-constants
@@@ title: The multiplication table is 2^n × 2^n signs
@@@ tags: ga/computing
@@@ aliases: structure constants, multiplication table

For an orthonormal basis, the product of two basis blades is determined by
three integers ([[basis-blades]]):

```typst
e_A e_B = epsilon(A, B) m(A, B) e_(A xor B),
```

where $A$ and $B$ are bitmask index sets, $epsilon(A, B)$ is the sign of the
reordering, $m(A, B)$ is the product of the $sigma_i$ over the common indices
$A inter B$ (the metric factor), and the result index is the bitwise xor. So
the whole algebra is a table of $2^n times 2^n$ signed indices, computed once at
module initialisation. For `Cl(4,1)` that is $32 times 32 = 1024$ entries.

```ocaml
open Geom

Array.length (Blade.all 5)                            (* 32 blades *)
Blade.mul_sign (Blade.of_basis 1) (Blade.of_basis 2)  (* 1 *)
Blade.mul_sign (Blade.of_basis 2) (Blade.of_basis 1)  (* -1 *)
Blade.to_int (Blade.of_basis 1)                       (* 1 *)
```

The geometric product of two multivectors is then a batched contraction over
the last axis: gather the coefficients of the pairs that land on each output
blade, multiply by the table entry, and sum. The implementation can use an
explicit $2^n times 2^n times 2^n$ structure tensor in a single `einsum`, or
the equivalent gather-and-sum with the xor table; both are traceable, and the
choice is a performance question rather than a semantic one.

`Blade` owns the table-free part (indices, grades, signs, complements) and
knows nothing about the metric, which is why it can be shared by all three
models ([[three-models]]). Note that `Blade.mul_sign` is only the reordering
sign: the metric factor is applied by the algebra, so a blade whose index sets
intersect in a null direction gets a zero from `m`, not from the sign.

@@@ slug: traced
@@@ title: Traced algebra: no host branches
@@@ tags: ga/computing
@@@ aliases: jit, tracing, differentiability

The algebra is written as pure `Nx` operations with no host read of a tensor
value and no data-dependent OCaml branch. That is a strong constraint, and it is
what makes every expression in the forest compatible with `Rune.jit` and
`Rune.grad`:

```ocaml
open Geom

let s = Cga.sphere ~center:(Nx.create Nx.float32 [|3|] [|0.;0.;0.|])
                   ~radius:(Nx.scalar Nx.float32 1.) in
let on_sphere p = Cga.scalar_prod (Cga.point p) s in
let jit = Rune.jit' on_sphere in
Nx.item [] (jit (Nx.create Nx.float32 [|3|] [|1.; 0.; 0.|]))   (* 0. *)
```

The constraint bites hardest on the closed forms. Small-angle limits in the
exponential and logarithm are handled with `sinc`-style rewrites and safe
denominators, not with `if`; where a genuine choice is needed (the branch of a
[[se3-log|logarithm]], the sign of a square root) it is made with `Nx.where`.
The general bivector exponential, when it is exposed, will use a fixed number
of scaling-and-squaring steps for the same reason.

The payoff is that a residual like [[ga-residuals|a task-space objective]] can
be differentiated without writing a Jacobian by hand, and batched without a
loop ([[batching]]). The cost is a style rule: if you find yourself writing
`if Float.abs x < eps then` inside an algebra function, it will not trace, and
the small-angle case must be folded into an algebraic expression instead.

@@@ slug: numerics
@@@ title: Numerical cautions in a projective algebra
@@@ tags: ga/computing
@@@ aliases: numerical issues, normalisation

Four failure modes account for most wrong answers. They are worth checking in
this order, because each one can mask the next.

**Scale.** Every object is homogeneous: $S$ and $2 S$ are the same sphere. Fix
the scale before comparing anything, with the normalisation that belongs to the
object, not the metric one:

| object | call | what it fixes |
| --- | --- | --- |
| conformal point | `Cga.normalize_point` | `e∞ . X = -1` |
| conformal sphere | `Cga.normalize_sphere` | `e∞ . S = -1` |
| conformal plane | `Cga.normalize_plane` | `pi^2 = 1` |
| PGA point | `Pga.normalize_point` | weight 1 |
| PGA plane | `Pga.normalize_plane` | unit normal |
| blade, versor | `Algebra.normalize` | metric magnitude 1 |
| motor | `Motor.normalize` | `M ~M = 1` |

**Signs of squares.** An imaginary sphere has $S^2 < 0$, while a point pair of
two real points has a positive square ([[point-pair]]). Neither sign should be
forced positive before a square root; `sphere_radius2` returns the signed value
on purpose.

**Dual versus complement.** The [[hodge-dual]] exists only for a non-degenerate
signature; the [[complement]] exists always ([[pga-no-dual]]). A generic `dual`
routed through both models silently mirrors geometry.

**Degeneracy.** Four coplanar points have a zero wedge, so
`Cga.sphere_through` returns zero rather than a sphere
([[sphere-through-four]]). Three collinear points do not vanish: they give a
flat 2-blade, the line through them, so `circle_radius2` is undefined rather
than zero. Check the [[reverse|magnitude]] of a constructed object, and its
[[round-flat|flat/round]] flag, before using it.

```ocaml
open Geom
let s = Cga.sphere ~center:(Nx.create Nx.float32 [|3|] [|0.;0.;0.|])
                   ~radius:(Nx.scalar Nx.float32 2.) in
Cga.to_array (Cga.normalize_sphere s)   (* scale fixed *)
```

Finally, float32 drift: long motor products should call `Motor.normalize`, and
`distance` guards the square root of a squared distance that rounding may leave
slightly negative for coincident points.

@@@ slug: api-map
@@@ title: The geom API map
@@@ tags: ga/computing
@@@ aliases: API, modules

One functor and three models, plus a packed motion type.

| module | what it is | where to read the maths |
| --- | --- | --- |
| `Blade` | bitmask blades, grades, signs, complements | [[basis-blades]] |
| `Signature` | the metric $(p,q,r)$ — $p$ positive, $q$ negative, $r$ null directions — and the pseudoscalar square | [[signature]] |
| `Algebra` | the dense functor: products, involutions, duals, norms, sandwich, adjoint | [[geometric-product]], [[hodge-dual]], [[versor]] |
| `Versor` | `exp`, `log`, `exp_simple`, `slerp` for a dense algebra | [[bivector-exp]] |
| `Motor` | packed 8-component rigid motions, exp/log, slerp | [[motor]] |
| `E3` | `Cl(3,0,0)`: vectors, rotors | [[e3]] |
| `Pga` | `Cl(3,0,1)`: planes, lines, points, meet/join | [[pga]] |
| `Cga` | `Cl(4,1)`: points, spheres, lines, circles, motors | [[cga]] |

```ocaml
open Geom
let v3 x y z = Nx.create Nx.float32 [| 3 |] [| x; y; z |] in
let sc x = Nx.scalar Nx.float32 x in

(* the generic surface, shared by the three models *)
E3.gp E3.e1 E3.e2                            (* products *)
Cga.reverse (Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.))
(* model-specific surface *)
Cga.incident (Cga.point3 0. 0. 1.)
  (Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.))
Motor.mul (Motor.translate3 1. 0. 0.) Motor.one
```

The interfaces are the documentation: each `.mli` fixes the sign conventions and
points at the section of `geom/doc/notes.typ` that derives them. When in doubt
about a sign, read the `.mli`; when in doubt about a normalisation, read
[[numerics]].

The library is batched throughout ([[batching]]) and traceable throughout
([[traced]]), so there is no separate "fast path" API. The one place where you
choose a representation is motion: packed [[motor]] or dense
[[motor-shared|embedded]].

@@@ slug: alternatives
@@@ title: Matrices, quaternions, dual quaternions, geometric algebra
@@@ tags: ga/computing
@@@ aliases: comparison, alternatives

Every tool here is a representation of the same groups and spaces, and the
honest comparison is about which operations are cheap.

| tool | pose | interpolation | incidence with a sphere | derivative |
| --- | --- | --- | --- | --- |
| 4×4 matrix | 16 numbers, easy | awkward (needs polar decomposition) | no objects | fine |
| quaternion | rotation only | slerp, natural | no | fine |
| dual quaternion | 8 numbers | ScLERP, natural | no objects | fine |
| homogeneous + Plücker | 16 + 6, constraint to maintain | awkward | yes, but several formulas | fine |
| [[motor|motors]] | 8 numbers | [[slerp|ScLERP]] | no objects | fine |
| [[cga|CGA]] | 8 (motor) + 32 (objects) | motor ScLERP, object versors | one contraction | [[polynomial-predicates|polynomial]] |

For poses alone, a dual quaternion is exactly a motor, and the only difference
is notation: the eight components in `Motor.t` are the dual quaternion. For
rotations alone, a quaternion is the even subalgebra of `Cl(3,0,0)`
([[quaternions]]), and the choice is again notation.

The real division is between representations that carry **objects** and those
that do not. Matrices and quaternions cannot express "this point is on this
sphere" without leaving the formalism. Geometric algebra keeps points, spheres,
planes, lines and circles inside the same multiplication, which is the case
[[cga-tradeoffs]] argues is the interesting one for robotics.

What you pay is the object layer's size ([[working-representation]]) and the
need for [[numerics|projective normalisation]]. What you get is a predicate
calculus that differentiates ([[ga-residuals]]).

@@@ slug: viz-model
@@@ title: The geom-viz rendering model
@@@ tags: ga/viz
@@@ aliases: geom-viz, renderer

`geom-viz` turns algebra objects into pictures in four layers.

1. **Primitives.** `Primitive.t` is a small neutral language — points,
   segments, polylines, polygons, circles, spheres, planes with an explicit
   finite patch, and coordinate frames. It knows nothing about Clifford
   algebras.
2. **Adapters.** `Primitive.of_cga_sphere`, `of_cga_plane`, `of_cga_line`,
   `of_cga_circle`, `of_cga_point` (and the `Pga` equivalents) read an object
   and produce a primitive ([[viz-adapters]]).
3. **Camera and scene.** A `Camera.t` is a look-at camera whose projection is a
   PGA construction ([[camera-pga]]). A `Draw.scene` is a camera plus a list of
   entities; an entity is a primitive with a style, a paint layer and a motion.
4. **Page.** `Draw.picture_at scene ~time:0.` produces a Hugin picture;
   `Frame.create ~width ~height` then `Frame.save_svg`, `save_png` or `save_pdf`
   writes it.

```ocaml
open Geom_viz
module P = Primitive

let camera =
  Camera.create ~eye:(P.p3 4. (-4.) 3.) ~target:(P.p3 0. 0. 0.5)
    ~up:(P.p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.) ~width:800. ~height:600. ()

let scene =
  Draw.create camera
    [ Draw.static (P.Sphere { center = P.p3 0. 0. 1.; radius = 1. })
    ; Draw.static ~style:(Draw.outline (Hugin_gg.Color.v 0.05 0.45 0.55))
        (P.Circle { center = P.p3 0. 0. 0.
                  ; normal = P.p3 0. 0. 1.
                  ; radius = 1.5
                  })
    ]

let () =
  let picture = Draw.picture_at scene ~time:0. in
  Frame.save_svg (Frame.create ~width:800. ~height:600. picture) "scene.svg"
```

The renderer is a painter's algorithm: lower layers paint first, and inside a
layer entities are sorted by depth and painted far to near, with one depth
value per primitive. Intersecting surfaces and lines through solids can sort
incorrectly, so split an object into pieces when that matters. There is no
near-plane clipping and no shading, and the renderer draws no text: labels are
glyph outlines composed on top of the picture, which is how every label in this
forest was made (see `geom/examples/figures.ml`).

@@@ slug: camera-pga
@@@ title: The camera projects by a PGA meet
@@@ tags: ga/viz
@@@ aliases: camera, projection

The camera is not a 4×4 matrix. It is a set of projective objects:

- `Camera.view c` is the motor carrying world points into camera coordinates;
- `Camera.eye_point c` is the world-space eye, as a `Pga.t` point;
- `Camera.image_plane c` is the world-space image plane $z = -f$, as a
  `Pga.t` plane, where $f$ is the focal length;
- a view ray is the `Pga` line through the eye and the page point, and the
  projection of a world point is the **meet** of that ray with the image plane.

The meet performs the perspective division: the coordinates of the resulting
point are the image coordinates. In the closed form, with camera-space
coordinates $(x, y, z)$ of a point and focal length $f$, those coordinates are
$f x slash (-z)$ and $f y slash (-z)$. That is the whole projection.

```ocaml
open Geom
open Geom_viz

let c = Camera.create ~eye:(Primitive.p3 4. (-4.) 3.)
          ~target:(Primitive.p3 0. 0. 0.5) ~up:(Primitive.p3 0. 0. 1.)
          ~fov_y:(Float.pi /. 4.) ~width:800. ~height:600. ()

(* camera coordinates: eye at the origin, image plane z = -focal *)
let focal = Camera.focal c in
let p_cam = Pga.point3 0.2 (-0.1) (-2.0) in        (* in front of the eye *)
let ray = Pga.line_through (Pga.point3 0. 0. 0.) p_cam in
let hit = Pga.meet ray (Pga.plane3 0. 0. 1. (-.focal)) in
Nx.to_array (Pga.point_coords hit)
(* [|0.1 *. focal; -0.05 *. focal; -.focal|]: f x / (-z), f y / (-z) *)
```

![The eye, a world point, the view ray and the image plane; the projection is
the meet of the ray with the plane.](../../figures/camera-meet.svg)

`Camera.project` wraps exactly this: it carries the world point into camera
coordinates with `Camera.view`, builds the ray, and meets it with the image
plane. `Camera.ray` and `Camera.image_plane` expose the same two objects in
*world* coordinates, which is what you want for drawing the construction — as
in the figure above — not for reading image coordinates off.

Orthographic mode keeps the same eye, view motor and image plane but projects
by a uniform scale instead of intersecting the ray with the plane. That is the
right choice for textbook figures and for exact GA diagrams, which is why the
figures in this forest use perspective for scenes and orthographic-style flat
drawings for diagrams.

`Camera.project_pinhole` evaluates the same map in closed form, avoiding the
multivector allocations in a per-point loop; the test suite asserts that the
two agree. Using the algebra for the definition and the closed form for the hot
loop is the pattern of the whole library ([[traced]]).

@@@ slug: viz-adapters
@@@ title: Adapters from algebra objects to primitives
@@@ tags: ga/viz
@@@ aliases: adapters

The renderer never sees a multivector. Between the algebra and the picture sit
eight small functions:

```ocaml
open Geom
open Geom_viz
open Nx

let v3 x y z = create float32 [| 3 |] [| x; y; z |]
let sc x = scalar float32 x

let s = Cga.sphere ~center:(v3 0. 0. 1.) ~radius:(sc 1.) in
let p = Primitive.of_cga_sphere s in
let plane =
  Primitive.of_cga_plane (Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.))
in
let line = Primitive.of_cga_line ~extent:2.0
             (Cga.line (Cga.point3 1. 0. 1.) (Cga.point3 (-1.) 0. 1.)) in
let circle = Primitive.of_cga_circle
               (Cga.circle (Cga.point3 1. 0. 0.) (Cga.point3 0. 1. 0.)
                           (Cga.point3 (-1.) 0. 0.)) in
```

`of_cga_line` is the instructive one: a line is infinite and a picture is not,
so the adapter takes an `~extent` and draws a segment of that half-length around
the point of the line closest to the origin. `of_cga_plane` normalises the plane
projectively and attaches the default square patch. Both are decisions the
algebra cannot make for you.

Primitives also carry motion. `Primitive.transform` applies a `Motor.t` to a
primitive — a sphere keeps its radius, a circle keeps its radius and has its
normal rotated, a plane rebuilds its normal and offset from a transformed point
of the plane. That action is rigid by construction, so a
[[dilator|dilation]] or a [[transversion]] cannot be expressed this way: apply
the versor to the algebra object and extract a fresh primitive instead
([[viz-model]]).
