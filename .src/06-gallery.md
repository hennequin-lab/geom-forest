@@@ slug: gallery
@@@ title: Gallery of figures
@@@ tags: map
@@@ aliases: figures, contact sheet

Every figure in the forest, drawn with `geom-viz` from the very objects the
note is about. Each one also sits inside its own note; this page is the contact
sheet, so you can see them all without hunting.

## The geometric product and a rotor

```typst
u v = u dot v + u and v
```

The oriented parallelogram is $u and v$; the sandwich $R x tilde(R)$ rotates a
vector in that plane. See [[e3|the Euclidean algebra]].

![The geometric product of two vectors is a bivector: the oriented parallelogram they span. A rotor acts on a vector by the sandwich.](figures/e3-product.svg)

## Incidence in PGA

Two planes meet in a line, the line meets a third plane in a point; every
incidence is a wedge. See [[pga-meet-join|meet and join in PGA]].

![Three planes, the line where two of them meet, and the point where the third cuts that line. Every incidence here is a wedge.](figures/pga-incidence.svg)

## Wedge the points, then dualise

Three conformal points span a triangle; their dual is the circumcircle. See
[[objects-from-points|the construction recipe]].

![Three points on a circle; the circle is the dual of their wedge. The triangle is the direct blade, the circumcircle the constraint.](figures/wedge-dualise.svg)

## A transversion bends space

A square grid before and after a transversion: conformal, so angles survive and
only the scale varies. See [[transversion]].

![A square grid pushed through a transversion: the map is conformal, so right angles survive and only the scale varies.](figures/transversion-grid.svg)

## ScLERP along a screw

Five frames along the group exponential, and the screw axis they all share. See
[[slerp|screw interpolation]].

![Five frames along a ScLERP: each is a rigid motion, and the screw axis is the line the whole family shares.](figures/slerp-screw.svg)

## A forward-kinematics chain

A planar arm built from motor products; the tool frame is one sandwich away
from the pose motor. See [[fk|forward kinematics]].

![A planar arm built from motor products; the end-effector frame is one sandwich away from the pose motor.](figures/fk-chain.svg)

## The camera is a PGA meet

The eye, a world point, the view ray and the image plane; the projection is the
meet of the ray with the plane. See [[camera-pga|the camera note]].

![The eye, a world point, the view ray and the image plane; the projection is the meet of the ray with the plane.](figures/camera-meet.svg)

## The conformal embedding of a line

The coordinate $x$ becomes a point on a parabola; the chord is $X and Y$. See
[[conformal-embedding|the embedding note]].

![The embedding of a line: the coordinate x becomes a point on a parabola, and the chord length encodes the distance.](figures/null-parabola.svg)
