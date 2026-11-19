@@@ slug: map
@@@ title: Map of the geometric-algebra forest
@@@ tags: map
@@@ aliases: index, start here

These notes are a working map of geometric algebra as it is actually used in
robotics: the algebra first, then three models of space, then rigid motions,
then the software that makes it batch and differentiate. Every note is atomic;
the links are the argument.

A geometric algebra is a vector space you are allowed to multiply. One product
encodes the metric *and* the exterior structure, and every other operation —
dot product, cross product, quaternion rotation, homogeneous transform — turns
out to be a grade selection of it. That claim is unpacked in
[[why-ga|one product instead of a pile]] and made precise by
[[clifford-relation|the Clifford relation]].

## The five trails

| trail | start here | what it gives you |
| --- | --- | --- |
| Foundations | [[clifford-relation]] | blades, grades, products, duality, versors |
| Models | [[three-models]] | `Cl(3,0,0)`, `Cl(3,0,1)`, `Cl(4,1)` and what lives in each |
| Motions | [[motor]] | rigid motions as eight numbers, exp/log, ScLERP |
| Computing | [[batching]] | shapes, structure constants, tracing, numerics |
| Pictures | [[viz-model]] | turning algebra objects into SVG |

If you would rather be told in which order to read, take one of the
[[reading-paths|four reading paths]]; if you want the flat list,
[[index|the index of all notes]] is generated from the vault itself. All fifteen
drawings are collected on [[gallery|the gallery page]].

## The five ideas worth carrying away

1. **A blade is a subspace with a magnitude and an orientation**
   ([[grades]]). A bivector is a plane, not a normal vector.
2. **The sandwich is the only action** ([[sandwich]]). Versors transform every
   object of the algebra the same way, and preserve every incidence relation
   for free.
3. **In the conformal model, distance is an inner product**
   ([[conformal-distance]]): for conformal points $X$ and $Y$ representing
   Euclidean points $bold(x)$ and $bold(y)$,
   $X dot Y = -1 slash 2 norm(bold(x) - bold(y))^2$. Almost everything else in
   that model is a corollary.
4. **A rigid motion needs eight coefficients, not thirty-two** ([[motor]]).
   The packed motor type is a dual quaternion wearing a different hat.
5. **Geometric predicates are polynomial** ([[polynomial-predicates]]), so they
   are good residuals for optimisation and good targets for autodiff.

## Provenance

The code samples and figures come from `murder/packages/geom`, the batched
OCaml geometric-algebra library (`Geom`, `Geom.E3`, `Geom.Pga`, `Geom.Cga`,
`Geom.Motor`) and its experimental renderer `geom-viz`. Where a note shows an
SVG, that SVG was drawn by `geom-viz` from the very objects the note is about.
The mathematics follows `geom/doc/notes.typ`; the module layout is
[[api-map|mapped here]], and convention clashes are flagged in
[[numerics|the note on numerical cautions]].
