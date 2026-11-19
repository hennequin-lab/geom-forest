(* Figures for the geom-forest vault, drawn with geom-viz.

   The build is done from inside the murder checkout, because geom and
   geom_viz are not installed libraries:

     cp -r figures-src <murder>/scratch-forest
     cd <murder> && dune exec scratch-forest/forest_figures.exe -- \
                       ~/code/modern/geom-forest/figures

   The program writes the SVGs and prints a table of numerical checks that the
   vault notes quote. *)

open Geom
open Geom_viz
open Nx
module P = Primitive
module C = Camera
module Gg = Hugin_gg
module Vg = Hugin_vg
module F = Hugin_font

let width = 760.
let height = 500.

(* ─── palette ─── *)

let ink = Gg.Color.v 0.13 0.15 0.18
let muted = Gg.Color.v 0.42 0.45 0.50
let red = Gg.Color.v 0.80 0.18 0.13
let green = Gg.Color.v 0.12 0.55 0.22
let blue = Gg.Color.v 0.16 0.36 0.78
let teal = Gg.Color.v 0.05 0.45 0.55
let amber = Gg.Color.v 0.90 0.55 0.06
let violet = Gg.Color.v 0.50 0.20 0.68
let grid_style = Draw.outline ~width:0.5 (Gg.Color.gray ~alpha:0.22 0.55)

(* ─── small vector helpers ─── *)

let p3 = P.p3

let v3 x y z = create float32 [| 3 |] [| x; y; z |]
let sc x = scalar float32 x
let item x = Nx.item [] x
let bool b = if item b then "true" else "false"

let p3_of t =
  let a = Nx.to_array t in
  p3 a.(0) a.(1) a.(2)
let p3_of_cga t = p3_of (Cga.coords t)

(* ─── page drawing helpers ─── *)

(* [text] lays out ASCII [s] in Inter and draws the glyph outlines. Outlines
   keep the SVG independent of the viewer's fonts. *)
let text ?(color = ink) ?(size = 12.) ?(font = F.Font.regular) ~x ~y s =
  let chars = ref [] in
  String.iter (fun c -> chars := Uchar.of_char c :: !chars) s;
  let glyphs = Array.of_list (List.rev_map (F.Font.glyph font) !chars) in
  let n = Array.length glyphs in
  let xs = Array.make n 0. in
  for i = 1 to n - 1 do
    xs.(i)
    <- xs.(i - 1)
       +. (size
           *. (F.Font.advance font glyphs.(i - 1)
               +. F.Font.kerning font glyphs.(i - 1) glyphs.(i)))
  done;
  let glyph i =
    Vg.Picture.transform
      Gg.Affine.(translate (x +. xs.(i)) y * scale size size)
      (Vg.Picture.fill color (F.Font.outline font glyphs.(i)))
  in
  Vg.Picture.group (List.init n glyph)

let label2d ?(color = ink) ?(size = 12.) ~x ~y s = text ~color ~size ~x ~y s

let project (c : C.t) p =
  match C.project c p with
  | Some (x, y, _) -> Some (x, y)
  | None -> None

let label ?(color = ink) ?(size = 12.) ?(dx = 8.) ?(dy = -8.) (c : C.t) p s =
  match project c p with
  | None -> Vg.Picture.empty
  | Some (x, y) -> text ~color ~size ~x:(x +. dx) ~y:(y +. dy) s

let line2d ?(color = ink) ?(width = 1.5) ?(dash = []) (x0, y0) (x1, y1) =
  let stroke = if dash = [] then Gg.Stroke.v width else Gg.Stroke.v ~dash width in
  Vg.Picture.stroke stroke color (Gg.Path.polyline [| x0; x1 |] [| y0; y1 |])

let dot2d ?(color = ink) ?(radius = 4.) (x, y) =
  Vg.Picture.fill color (Gg.Path.circle (Gg.P2.v x y) radius)

let ring2d ?(color = ink) ?(radius = 4.5) ?(width = 1.6) (x, y) =
  Vg.Picture.stroke (Gg.Stroke.v width) color (Gg.Path.circle (Gg.P2.v x y) radius)

let arrow2d ?(color = ink) ?(width = 2.2) ?(head = 10.) (c : C.t) a b =
  match project c a, project c b with
  | Some (x0, y0), Some (x1, y1) ->
    let dx = x1 -. x0
    and dy = y1 -. y0 in
    let len = Float.sqrt ((dx *. dx) +. (dy *. dy)) in
    if len < 1e-6
    then Vg.Picture.empty
    else (
      let ux = dx /. len
      and uy = dy /. len in
      let bx = x1 -. (head *. ux)
      and by = y1 -. (head *. uy) in
      let nx = -.uy
      and ny = ux in
      let half = head *. 0.45 in
      let tri =
        Gg.Path.polygon
          [| x1; bx +. (half *. nx); bx -. (half *. nx) |]
          [| y1; by +. (half *. ny); by -. (half *. ny) |]
      in
      Vg.Picture.group
        [ Vg.Picture.stroke
            (Gg.Stroke.v width)
            color
            (Gg.Path.polyline [| x0; bx |] [| y0; by |])
        ; Vg.Picture.fill color tri
        ])
  | _ -> Vg.Picture.empty

let polyline3 ?(color = ink) ?(width = 1.5) ?(dash = []) (c : C.t) pts =
  let pts = List.filter_map (fun p -> project c p) pts in
  match pts with
  | [] -> Vg.Picture.empty
  | _ ->
    let xs = Array.of_list (List.map fst pts)
    and ys = Array.of_list (List.map snd pts) in
    let stroke = if dash = [] then Gg.Stroke.v width else Gg.Stroke.v ~dash width in
    Vg.Picture.stroke stroke color (Gg.Path.polyline xs ys)

let disc ?(color = ink) ?(radius = 4.) (c : C.t) p =
  match project c p with
  | None -> Vg.Picture.empty
  | Some (x, y) -> Vg.Picture.fill color (Gg.Path.circle (Gg.P2.v x y) radius)

let ring ?(color = ink) ?(radius = 4.) ?(width = 1.4) (c : C.t) p =
  match project c p with
  | None -> Vg.Picture.empty
  | Some (x, y) ->
    Vg.Picture.stroke (Gg.Stroke.v width) color (Gg.Path.circle (Gg.P2.v x y) radius)

(* ─── scene helpers ─── *)

let ground ~size style =
  Draw.static
    ~layer:0
    ~style
    (P.Plane
       { normal = p3 0. 0. 1.
       ; offset = 0.
       ; patch =
           [ p3 (-.size) (-.size) 0.
           ; p3 size (-.size) 0.
           ; p3 size size 0.
           ; p3 (-.size) size 0.
           ]
       })

let grid ~layer ~size ~step =
  let n = int_of_float (2. *. size /. step) in
  List.init (n + 1) (fun i ->
    let x = -.size +. (float_of_int i *. step) in
    [ Draw.static
        ~layer
        ~style:grid_style
        (P.Segment (p3 x (-.size) 0., p3 x size 0.))
    ; Draw.static
        ~layer
        ~style:grid_style
        (P.Segment (p3 (-.size) x 0., p3 size x 0.))
    ])
  |> List.concat

let ground_style ?(alpha = 0.06) () =
  { Draw.fill = Some (Gg.Color.v ~alpha 0.30 0.45 0.55)
  ; stroke = Some (Gg.Color.v ~alpha:0.35 0.30 0.40 0.50)
  ; width = 0.8
  ; dash = []
  ; opacity = 1.
  }

let scene_picture scene = Draw.picture_at scene ~time:0.

let rec pairs = function
  | a :: (b :: _ as rest) -> (a, b) :: pairs rest
  | _ -> []

let out_dir = if Array.length Sys.argv > 1 then Sys.argv.(1) else "."

let save name picture =
  let frame = Frame.create ~density:1.6 ~width ~height picture in
  Frame.save_svg frame (Filename.concat out_dir (name ^ ".svg"));
  Printf.printf "wrote %s/%s.svg\n%!" out_dir name

(* ─── Figure 1: the geometric product and a rotor in E3 ─── *)

let figure_e3 () =
  let camera =
    C.create
      ~eye:(p3 1.62 (-2.12) 1.32)
      ~target:(p3 0.42 0.36 0.18)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 5.2)
      ~width
      ~height
      ()
  in
  let u = p3 1. 0. 0.
  and v = p3 0.45 0.85 0. in
  let sum = P.add u v in
  let origin = p3 0. 0. 0. in
  let square = P.Polygon [ origin; u; sum; v ] in
  let square_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.16 0.22 0.45 0.82)
    ; stroke = Some (Gg.Color.v ~alpha:0.50 0.18 0.30 0.60)
    ; width = 1.1
    ; dash = []
    ; opacity = 1.
    }
  in
  let angle = 2. *. Float.pi /. 3. in
  let rotor = E3.rotor ~axis:(v3 0. 0. 1.) ~angle:(sc angle) in
  let rotated = E3.apply_rotor rotor (E3.vector3 1. 0. 0.) |> E3.to_vector in
  let rotated = p3_of rotated in
  let arc =
    List.init 33 (fun i ->
      let a = angle *. float_of_int i /. 32. in
      p3 (Float.cos a) (Float.sin a) 0.002)
  in
  let entities =
    [ ground ~size:1.6 (ground_style ()) ]
    @ grid ~layer:0 ~size:1.5 ~step:0.5
    @ [ Draw.static ~layer:1 ~style:square_style square ]
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ arrow2d ~color:red ~width:2.6 camera origin u
      ; arrow2d ~color:green ~width:2.6 camera origin v
      ; arrow2d ~color:violet ~width:3.0 camera origin rotated
      ; polyline3 ~color:violet ~width:1.3 ~dash:[ 4.; 4. ] camera arc
      ; disc ~color:ink ~radius:3.5 camera origin
      ; ring ~color:red ~radius:4.5 camera u
      ; ring ~color:green ~radius:4.5 camera v
      ; ring ~color:violet ~radius:4.5 camera rotated
      ; label ~color:red ~size:14. ~dx:6. ~dy:18. camera u "u"
      ; label ~color:green ~size:14. ~dx:6. ~dy:(-6.) camera v "v"
      ; label ~color:violet ~size:14. ~dx:8. ~dy:0. camera rotated "R u R~"
      ; label ~color:ink ~size:13. ~dx:0. ~dy:0. camera (P.scale sum 0.45) "u ^ v"
      ]
  in
  save "e3-product" (Vg.Picture.group [ scene_picture scene; overlay ])

(* ─── Figure 2: incidence and the meet in PGA ─── *)

let with_patch patch = function
  | P.Plane pl -> P.Plane { pl with patch }
  | other -> other

let figure_pga () =
  let camera =
    C.create
      ~eye:(p3 3.3 (-3.7) 2.7)
      ~target:(p3 0.25 0.25 0.55)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.6)
      ~width
      ~height
      ()
  in
  let pi1 = Pga.plane3 0. 0. 1. 0. in
  let pi2 = Pga.plane3 1. 0. 0. 0.6 in
  let pi3 = Pga.plane3 0. 1. 0. 1.2 in
  let l = Pga.meet pi1 pi2 in
  let corner = Pga.meet l pi3 in
  let patch2 =
    [ p3 0.6 (-1.7) 0.; p3 0.6 1.7 0.; p3 0.6 1.7 2.3; p3 0.6 (-1.7) 2.3 ]
  and patch3 =
    [ p3 (-1.7) 1.2 0.; p3 1.7 1.2 0.; p3 1.7 1.2 2.3; p3 (-1.7) 1.2 2.3 ]
  in
  let vertical_style alpha stroke =
    { Draw.fill = Some (Gg.Color.v ~alpha 0.25 0.50 0.58)
    ; stroke = Some stroke
    ; width = 1.
    ; dash = []
    ; opacity = 1.
    }
  in
  let entities =
    [ ground ~size:2.2 (ground_style ()) ]
    @ grid ~layer:0 ~size:2.0 ~step:0.5
    @ [ Draw.static
          ~layer:1
          ~style:(vertical_style 0.14 (Gg.Color.v ~alpha:0.45 0.24 0.36 0.45))
          (with_patch patch2 (P.of_pga_plane pi2))
      ; Draw.static
          ~layer:1
          ~style:(vertical_style 0.08 (Gg.Color.v ~alpha:0.25 0.30 0.35 0.40))
          (with_patch patch3 (P.of_pga_plane pi3))
      ; Draw.static
          ~layer:2
          ~style:(Draw.outline ~width:2.8 teal)
          (P.of_pga_line ~extent:1.25 l)
      ]
  in
  let scene = Draw.create camera entities in
  let on_line y = p3 0.6 y 0. in
  let off_line = p3 1.0 0.35 0.75 in
  let overlay =
    Vg.Picture.group
      [ disc ~color:teal ~radius:3.4 camera (on_line (-0.95))
      ; disc ~color:teal ~radius:3.4 camera (on_line 0.75)
      ; disc ~color:red ~radius:4.0 camera off_line
      ; disc ~color:ink ~radius:4.2 camera (p3_of (Pga.point_coords corner))
      ; label ~color:blue ~size:14. ~dx:10. ~dy:(-6.) camera (p3 0.6 0.9 1.9) "P1"
      ; label ~color:blue ~size:14. ~dx:10. ~dy:(-6.) camera (p3 0.6 (-1.2) 1.6) "P2"
      ; label ~color:muted ~size:13. ~dx:10. ~dy:0. camera (p3 1.2 1.2 1.0) "P3"
      ; label ~color:teal ~size:13. ~dx:10. ~dy:10. camera (on_line 0.75)
          "l = P1 ^ P2"
      ; label ~color:red ~size:12. ~dx:14. ~dy:(-14.) camera off_line "p ^ l != 0"
      ; label ~color:ink ~size:13. ~dx:10. ~dy:(-12.)
          camera (p3_of (Pga.point_coords corner)) "P1 ^ P2 ^ P3"
      ]
  in
  save "pga-incidence" (Vg.Picture.group [ scene_picture scene; overlay ]);
  (* checks quoted by the notes *)
  Printf.printf "  point_on_line (0.6,0.75,0)      %s\n"
    (bool (Pga.point_on_line (Pga.point3 0.6 0.75 0.) l));
  Printf.printf "  point_on_plane off_line         %s\n"
    (bool (Pga.point_on_plane
             (Pga.point3 off_line.P.x off_line.P.y off_line.P.z) pi2));
  Printf.printf "  corner coords                   [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Nx.to_array (Pga.point_coords corner)))))

(* ─── Figure 3: wedge the points, then dualise ─── *)

let figure_circle () =
  let camera =
    C.create
      ~eye:(p3 2.6 (-3.3) 2.4)
      ~target:(p3 0.05 0. 0.85)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.6)
      ~width
      ~height
      ()
  in
  let normal = P.normalize (p3 0.28 0.18 1.) in
  let u = P.normalize (P.cross normal (p3 0. 1. 0.)) in
  let v = P.cross normal u in
  let centre = p3 0. 0. 0.95
  and radius = 0.95 in
  let at t =
    P.add centre
      (P.add (P.scale u (radius *. Float.cos t)) (P.scale v (radius *. Float.sin t)))
  in
  let a = at (Float.pi /. 2.)
  and b = at ((Float.pi /. 2.) +. (2. *. Float.pi /. 3.))
  and c = at ((Float.pi /. 2.) +. (4. *. Float.pi /. 3.)) in
  let cp (q : P.p3) = Cga.point3 q.P.x q.P.y q.P.z in
  let circle_obj = Cga.circle (cp a) (cp b) (cp c) in
  let triangle_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.10 0.75 0.45 0.10)
    ; stroke = Some (Gg.Color.v ~alpha:0.55 0.50 0.30 0.05)
    ; width = 1.0
    ; dash = []
    ; opacity = 1.
    }
  in
  let entities =
    [ ground ~size:2.2 (ground_style ()) ]
    @ grid ~layer:0 ~size:2.0 ~step:0.5
    @ [ Draw.static ~layer:2 ~style:triangle_style (P.Polygon [ a; b; c ])
      ; Draw.static ~layer:3 ~style:(Draw.outline ~width:2.8 amber)
          (P.of_cga_circle circle_obj)
      ]
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ ring ~color:amber ~radius:4.6 camera a
      ; ring ~color:amber ~radius:4.6 camera b
      ; ring ~color:amber ~radius:4.6 camera c
      ; label ~color:ink ~size:13. ~dx:10. ~dy:(-4.) camera a "X1"
      ; label ~color:ink ~size:13. ~dx:(-6.) ~dy:16. camera b "X2"
      ; label ~color:ink ~size:13. ~dx:(-22.) ~dy:(-4.) camera c "X3"
      ; label ~color:amber ~size:13. ~dx:12. ~dy:0. camera (at (-.Float.pi /. 2.25))
          "c = (X1 ^ X2 ^ X3)*"
      ]
  in
  save "wedge-dualise" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  circle_radius2                  %.4g\n"
    (item (Cga.circle_radius2 circle_obj));
  Printf.printf "  incident X1 on circle           %s\n"
    (bool (Cga.incident (cp a) circle_obj))

(* ─── Figure 4: a transversion applied to a grid ─── *)

let figure_transversion () =
  let camera =
    C.create
      ~eye:(p3 0.0 (-0.5) 5.6)
      ~target:(p3 (-0.35) 0. 0.)
      ~up:(p3 0. 1. 0.)
      ~fov_y:(Float.pi /. 5.0)
      ~width
      ~height
      ()
  in
  let k = Cga.transversion (v3 0.3 0. 0.) in
  let warp (x, y) =
    let q = Cga.point3 x y 0. in
    p3_of_cga (Cga.sandwich k q)
  in
  let samples a b n =
    List.init (n + 1) (fun i -> a +. ((b -. a) *. float_of_int i /. float_of_int n))
  in
  let lo = -0.9 and hi = 0.9 and step = 0.3 in
  let ns = 64 in
  let vertical x = List.map (fun y -> warp (x, y)) (samples lo hi ns) in
  let horizontal y = List.map (fun x -> warp (x, y)) (samples lo hi ns) in
  let lines f =
    let n = int_of_float ((hi -. lo) /. step) in
    List.init (n + 1) (fun i -> f (lo +. (float_of_int i *. step)))
  in
  let original =
    List.concat
      [ List.map (fun x -> [ p3 x lo 0.001; p3 x hi 0.001 ]) (lines (fun x -> x))
      ; List.map (fun y -> [ p3 lo y 0.001; p3 hi y 0.001 ]) (lines (fun y -> y))
      ]
  in
  let overlay =
    Vg.Picture.group
      (List.map (fun pts -> polyline3 ~color:(Gg.Color.gray ~alpha:0.35 0.5) ~width:0.8
                             ~dash:[ 3.; 3. ] camera pts) original
       @ List.map (fun pts -> polyline3 ~color:teal ~width:1.6 camera pts)
           (List.map vertical (lines (fun x -> x)))
       @ List.map (fun pts -> polyline3 ~color:teal ~width:1.6 camera pts)
           (List.map horizontal (lines (fun y -> y)))
       @ [ disc ~color:amber ~radius:4. camera (warp (0., 0.))
         ; label ~color:amber ~size:12. ~dx:8. ~dy:14. camera (warp (0., 0.)) "origin"
         ])
  in
  let scene = Draw.create camera [] in
  save "transversion-grid" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  transversion of (1,0,0)         [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.coords (Cga.sandwich k (Cga.point3 1. 0. 0.)))))))

(* ─── Figure 5: ScLERP along a screw ─── *)

let rotation_rows m =
  let a = Nx.to_array (Motor.rotation m) in
  [| (a.(0), a.(1), a.(2)); (a.(3), a.(4), a.(5)); (a.(6), a.(7), a.(8)) |]

let frame_primitive m ~scale =
  let origin = p3_of (Motor.translation m) in
  let r = rotation_rows m in
  let axis i = p3 (let (x, _, _) = r.(i) in x) (let (_, y, _) = r.(i) in y)
                  (let (_, _, z) = r.(i) in z) in
  let tip d = P.add origin (P.scale d scale) in
  P.Frame { origin; x = tip (axis 0); y = tip (axis 1); z = tip (axis 2) }

let figure_slerp () =
  let camera =
    C.create
      ~eye:(p3 2.55 (-3.15) 2.2)
      ~target:(p3 0.65 0. 0.28)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 5.0)
      ~width
      ~height
      ()
  in
  let m0 = Motor.one in
  let m1 =
    Motor.mul
      (Motor.translate3 1.3 0. 0.55)
      (Motor.rotate ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi *. 0.85)))
  in
  let at t = Motor.slerp m0 m1 (sc t) in
  let times = [ 0.; 0.25; 0.5; 0.75; 1. ] in
  let colour t =
    let mix a b = a +. (t *. (b -. a)) in
    Gg.Color.v (mix 0.16 0.80) (mix 0.36 0.18) (mix 0.78 0.13)
  in
  let entities =
    [ ground ~size:2.2 (ground_style ()) ]
    @ grid ~layer:0 ~size:2.0 ~step:0.5
    @ List.map
        (fun t ->
           Draw.static
             ~layer:2
             ~style:{ Draw.fill = Some (colour t)
                    ; stroke = Some ink
                    ; width = 1.
                    ; dash = []
                    ; opacity = 1.
                    }
             (frame_primitive (at t) ~scale:0.4))
        times
  in
  let scene = Draw.create camera entities in
  let path =
    List.init 41 (fun i ->
      let t = float_of_int i /. 40. in
      p3_of (Motor.translation (at t)))
  in
  (* The screw axis. This motion is a rotation about z composed with a
     translation along z, so the axis is vertical through the fixed point of
     the planar rotation: solve (I - R2) p = t2. *)
  let r = Nx.to_array (Motor.rotation m1) in
  let t = Nx.to_array (Motor.translation m1) in
  let a11 = 1. -. r.(0)
  and a12 = -.r.(1)
  and a21 = -.r.(3)
  and a22 = 1. -. r.(4) in
  let det = (a11 *. a22) -. (a12 *. a21) in
  let axis_point =
    p3 (((t.(0) *. a22) -. (a12 *. t.(1))) /. det)
       (((a11 *. t.(1)) -. (t.(0) *. a21)) /. det)
       0.
  in
  let xi = Motor.log (Motor.mul (Motor.inverse m0) m1) in
  let w = Nx.to_array xi in
  let axis_dir = P.normalize (p3 w.(0) w.(1) w.(2)) in
  let axis_line =
    [ P.sub axis_point (P.scale axis_dir 0.5)
    ; P.add axis_point (P.scale axis_dir 1.6)
    ]
  in
  let overlay =
    Vg.Picture.group
      [ polyline3 ~color:(Gg.Color.gray ~alpha:0.55 0.5) ~width:1.4 ~dash:[ 5.; 4. ]
          camera axis_line
      ; polyline3 ~color:violet ~width:2.0 camera path
      ; Vg.Picture.group
          (List.map
             (fun t -> disc ~color:ink ~radius:3.0 camera (p3_of (Motor.translation (at t))))
             times)
      ; disc ~color:ink ~radius:3.2 camera (p3_of (Motor.translation m0))
      ; disc ~color:ink ~radius:3.2 camera (p3_of (Motor.translation m1))
      ; label ~color:ink ~size:12. ~dx:(-44.) ~dy:22. camera (p3_of (Motor.translation m0))
          "t = 0"
      ; label ~color:ink ~size:12. ~dx:10. ~dy:16. camera (p3_of (Motor.translation m1))
          "t = 1"
      ; label ~color:muted ~size:12. ~dx:12. ~dy:(-6.)
          camera (P.add axis_point (P.scale axis_dir 1.25)) "screw axis"
      ]
  in
  save "slerp-screw" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  slerp 0.5                       [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array
                (Cga.coords (Cga.apply_motor (at 0.5) (Cga.point3 0. 0. 0.)))))))

(* ─── Figure 6: a forward-kinematics chain ─── *)

let figure_fk () =
  let camera =
    C.create
      ~eye:(p3 1.1 (-4.3) 2.35)
      ~target:(p3 0. 0. 1.15)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.4)
      ~width
      ~height
      ()
  in
  let lengths = [| 0.85; 0.65; 0.5 |] in
  let q = [| 0.65; -1.05; 0.85 |] in
  let joint i =
    Motor.mul
      (Motor.rotate ~axis:(v3 0. 1. 0.) ~angle:(sc q.(i)))
      (Motor.translate3 0. 0. lengths.(i))
  in
  let rec chain i =
    if i = Array.length lengths then Motor.one
    else Motor.mul (joint i) (chain (i + 1))
  in
  let poses =
    let rec go i m acc =
      if i = Array.length lengths
      then List.rev (m :: acc)
      else go (i + 1) (Motor.mul m (joint i)) (m :: acc)
    in
    go 0 Motor.one []
  in
  let joints = List.map (fun m -> p3_of (Motor.translation m)) poses in
  let segments =
    List.map
      (fun (a, b) ->
         Draw.static ~layer:3 ~style:(Draw.outline ~width:6.0 teal) (P.Segment (a, b)))
      (pairs joints)
  in
  let entities =
    [ ground ~size:1.9 (ground_style ()) ]
    @ grid ~layer:0 ~size:1.8 ~step:0.45
    @ [ Draw.static ~layer:2 ~style:Draw.default
          (P.Frame
             { origin = p3 0. 0. 0.
             ; x = p3 0.32 0. 0.
             ; y = p3 0. 0.32 0.
             ; z = p3 0. 0. 0.32
             })
      ; Draw.static ~layer:4 ~style:Draw.default
          (frame_primitive (chain 0) ~scale:0.3)
      ]
    @ segments
  in
  let scene = Draw.create camera entities in
  let last = List.nth joints (List.length joints - 1) in
  let overlay =
    Vg.Picture.group
      [ Vg.Picture.group
          (List.mapi
             (fun i j ->
                if i >= Array.length lengths
                then Vg.Picture.empty
                else
                  Vg.Picture.group
                    [ disc ~color:ink ~radius:4.5 camera j
                    ; label ~color:ink ~size:12.
                        ~dx:(if i = 0 then 12. else 10.)
                        ~dy:(if i = 0 then 22. else -12.)
                        camera j (Printf.sprintf "q%d" (i + 1))
                    ])
             joints)
      ; ring ~color:amber ~radius:5.0 ~width:2.0 camera last
      ; label ~color:amber ~size:12. ~dx:14. ~dy:(-18.) camera last "tool"
      ]
  in
  save "fk-chain" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  fk end effector                 [%s]\n"
    (String.concat "; "
       (List.map
          (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array
                (Cga.coords (Cga.apply_motor (chain 0) (Cga.point3 0. 0. 0.)))))))

(* ─── Figure 7: the camera is a PGA meet ─── *)

let figure_camera () =
  (* [cam] is the camera whose geometry we draw; [view] is the camera that
     draws it, so that the eye is not the viewer. *)
  let cam =
    C.create
      ~eye:(p3 0.9 (-1.3) 0.85)
      ~target:(p3 0.1 0.9 0.55)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 3.)
      ~width
      ~height
      ()
  in
  let view =
    C.create
      ~eye:(p3 3.2 (-3.5) 2.5)
      ~target:(p3 0.5 (-0.15) 0.7)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.6)
      ~width
      ~height
      ()
  in
  let eye = C.eye cam in
  let forward = C.forward cam
  and right = C.right cam
  and up = C.up cam in
  (* A focal plane at distance [d]; the library's image plane sits at
     [Camera.focal] page points, which is the same construction at another
     scale. *)
  let d = 1.15 in
  let centre = P.add eye (P.scale forward d) in
  let hw = 0.62 and hh = 0.46 in
  let corner sx sy =
    P.add centre (P.add (P.scale right (sx *. hw)) (P.scale up (sy *. hh)))
  in
  let patch =
    [ corner (-1.) (-1.); corner 1. (-1.); corner 1. 1.; corner (-1.) 1. ]
  in
  let world =
    let d0 = P.normalize (P.sub (p3 0.1 0.55 0.5) eye) in
    P.add eye (P.scale d0 3.6)
  in
  let eye_pt = C.eye_point cam in
  let world_pt = Pga.point3 world.P.x world.P.y world.P.z in
  let ray = Pga.line_through eye_pt world_pt in
  let pi =
    Pga.plane
      ~normal:(v3 forward.P.x forward.P.y forward.P.z)
      ~offset:(sc (P.dot forward eye +. d))
  in
  let hit = Pga.meet ray pi in
  let hit_p = p3_of (Pga.point_coords hit) in
  let plane_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.12 0.30 0.45 0.60)
    ; stroke = Some (Gg.Color.v ~alpha:0.55 0.20 0.35 0.50)
    ; width = 1.2
    ; dash = []
    ; opacity = 1.
    }
  in
  let entities =
    [ ground ~size:2.2 (ground_style ()) ]
    @ grid ~layer:0 ~size:2.0 ~step:0.5
    @ [ Draw.static ~layer:1 ~style:plane_style
          (P.Plane { normal = forward; offset = P.dot forward eye +. d; patch })
      ; Draw.static ~layer:3
          ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.9 0.85 0.20 0.12)
                  ; stroke = None
                  ; width = 0.
                  ; dash = []
                  ; opacity = 1.
                  }
          (P.Point world)
      ; Draw.static ~layer:2 ~style:Draw.default
          (P.Frame
             { origin = eye
             ; x = P.add eye (P.scale right 0.35)
             ; y = P.add eye (P.scale up 0.35)
             ; z = P.add eye (P.scale forward 0.35)
             })
      ]
  in
  let scene = Draw.create view entities in
  let overlay =
    Vg.Picture.group
      [ polyline3 ~color:ink ~width:1.4 ~dash:[ 6.; 4. ] view [ eye; world ]
      ; polyline3 ~color:violet ~width:2.4 view [ eye; hit_p ]
      ; disc ~color:ink ~radius:4.5 view eye
      ; ring ~color:violet ~radius:5.0 ~width:2.0 view hit_p
      ; ring ~color:amber ~radius:5.0 ~width:2.0 view world
      ; label ~color:ink ~size:13. ~dx:8. ~dy:20. view eye "eye"
      ; label ~color:amber ~size:12. ~dx:14. ~dy:(-18.) view world "world point"
      ; label ~color:violet ~size:12. ~dx:14. ~dy:20. view hit_p "image point"
      ; label ~color:muted ~size:12. ~dx:(-96.) ~dy:(-20.) view centre "image plane"
      ]
  in
  save "camera-meet" (Vg.Picture.group [ scene_picture scene; overlay ]);
  (match C.project cam world with
   | Some (x, y, depth) ->
     Printf.printf "  project world                   (%.1f, %.1f) depth %.2f\n" x y depth
   | None -> Printf.printf "  project world                   behind the camera\n");
  Printf.printf "  image point in world coords     (%.3f, %.3f, %.3f)\n"
    hit_p.P.x hit_p.P.y hit_p.P.z;
  ignore (C.project_image cam world)

(* ─── Figure 8: the conformal embedding of a line ─── *)

let figure_parabola () =
  let ox = 380. and oy = 400. and sx = 155. and sy = 140. in
  let to_page x y = (ox +. (sx *. x), oy -. (sy *. y)) in
  let curve =
    List.init 121 (fun i ->
      let x = -1.75 +. (3.5 *. float_of_int i /. 120.) in
      to_page x (0.5 *. x *. x))
  in
  let pts =
    let xs = Array.of_list (List.map fst curve)
    and ys = Array.of_list (List.map snd curve) in
    Gg.Path.polyline xs ys
  in
  let p x = to_page x (0.5 *. x *. x) in
  let a = p (-1.25)
  and b = p 1.05 in
  let overlay =
    Vg.Picture.group
      [ line2d ~color:(Gg.Color.gray ~alpha:0.55 0.5) ~width:1.0
          (to_page (-2.0) 0.) (to_page 2.1 0.)
      ; line2d ~color:(Gg.Color.gray ~alpha:0.55 0.5) ~width:1.0
          (to_page 0. (-0.25)) (to_page 0. 2.2)
      ; Vg.Picture.stroke (Gg.Stroke.v 2.4) teal pts
      ; line2d ~color:violet ~width:2.0 a b
      ; line2d ~color:(Gg.Color.gray ~alpha:0.6 0.5) ~width:1.0 ~dash:[ 3.; 3. ]
          (fst a, snd a) (fst a, oy)
      ; line2d ~color:(Gg.Color.gray ~alpha:0.6 0.5) ~width:1.0 ~dash:[ 3.; 3. ]
          (fst b, snd b) (fst b, oy)
      ; ring2d ~color:teal a
      ; ring2d ~color:teal b
      ; dot2d ~color:ink (to_page 0. 0.)
      ; label2d ~color:teal ~size:13. ~x:(fst a -. 44.) ~y:(snd a -. 12.) "X"
      ; label2d ~color:teal ~size:13. ~x:(fst b +. 10.) ~y:(snd b -. 12.) "Y"
      ; label2d ~color:violet ~size:13.
          ~x:(((fst a +. fst b) /. 2.) -. 20.)
          ~y:(((snd a +. snd b) /. 2.) +. 26.) "chord"
      ; label2d ~color:muted ~size:12. ~x:(fst a -. 26.) ~y:(oy +. 18.) "x"
      ; label2d ~color:muted ~size:12. ~x:(fst b -. 4.) ~y:(oy +. 18.) "y"
      ; label2d ~color:muted ~size:12. ~x:(ox +. (sx *. 1.45)) ~y:(oy +. 18.)
          "e1 direction"
      ; label2d ~color:muted ~size:12. ~x:(ox +. 12.) ~y:(to_page 0. 2.15 |> snd)
          "1/2 x^2 e_inf"
      ]
  in
  let frame = Frame.create ~density:1.6 ~width ~height overlay in
  Frame.save_svg frame (Filename.concat out_dir "null-parabola.svg");
  Printf.printf "wrote %s/null-parabola.svg\n%!" out_dir


(* ─── Figure 9: blades of every grade ─── *)

let figure_grades () =
  let camera =
    C.create
      ~eye:(p3 2.35 (-2.55) 1.95)
      ~target:(p3 0.35 0.35 0.38)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.7)
      ~width
      ~height
      ()
  in
  let o = p3 0. 0. 0. in
  let u = p3 1.15 0. 0.
  and v = p3 0. 1.15 0.
  and w = p3 0. 0. 1.15 in
  let uv = P.add u v in
  let add3 a b c = P.add a (P.add b c) in
  let cube_edges =
    [ (* bottom square *) (o, u); (u, uv); (uv, v); (v, o)
    ; (* top square *) (w, P.add w u); (P.add w u, add3 w u v)
    ; (add3 w u v, P.add w v); (P.add w v, w)
    ; (* verticals *) (o, w); (u, P.add u w); (uv, add3 u v w); (v, P.add v w)
    ]
  in
  let floor_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.18 0.22 0.45 0.82)
    ; stroke = Some (Gg.Color.v ~alpha:0.62 0.18 0.30 0.60)
    ; width = 1.4
    ; dash = []
    ; opacity = 1.
    }
  in
  let cube_style = Draw.outline ~width:1.2 (Gg.Color.v ~alpha:0.55 0.20 0.40 0.62) in
  let entities =
    [ ground ~size:1.9 (ground_style ~alpha:0.03 ()) ]
    @ grid ~layer:0 ~size:1.7 ~step:0.4
    @ [ Draw.static ~layer:1 ~style:floor_style (P.Polygon [ o; u; uv; v ]) ]
    @ List.map
        (fun (a, b) -> Draw.static ~layer:2 ~style:cube_style (P.Segment (a, b)))
        cube_edges
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ arrow2d ~color:red ~width:2.8 camera o u
      ; arrow2d ~color:green ~width:2.8 camera o v
      ; arrow2d ~color:blue ~width:2.8 camera o w
      ; label ~color:red ~size:14. ~dx:8. ~dy:16. camera u "u"
      ; label ~color:green ~size:14. ~dx:8. ~dy:(-8.) camera v "v"
      ; label ~color:blue ~size:14. ~dx:8. ~dy:(-4.) camera w "w"
      ; label ~color:(Gg.Color.v 0.18 0.24 0.55) ~size:12. ~dx:(-30.) ~dy:(-2.)
          camera (P.scale uv 0.5) "u ^ v  (grade 2)"
      ; label ~color:(Gg.Color.v 0.35 0.15 0.40) ~size:12. ~dx:(-48.) ~dy:(-8.)
          camera (add3 (P.scale u 0.5) (P.scale v 0.5) (P.scale w 1.02))
          "u ^ v ^ w  (grade 3)"
      ; label ~color:red ~size:11. ~dx:(-16.) ~dy:(-16.) camera (P.scale u 0.5)
          "grade 1"
      ]
  in
  save "blade-grades" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  grade of e12 / e123            %d / %d\n"
    (Blade.grade (Blade.of_int 3)) (Blade.grade (Blade.of_int 7))

(* ─── Figure 10: contraction is a quarter turn ─── *)

let figure_contraction () =
  let camera =
    C.create
      ~eye:(p3 0.42 (-0.08) 3.05)
      ~target:(p3 0.42 0.42 0.)
      ~up:(p3 0. 1. 0.)
      ~fov_y:(Float.pi /. 5.2)
      ~width
      ~height
      ()
  in
  let o = p3 0. 0. 0.
  and e1 = p3 1.25 0. 0.
  and e2 = p3 0. 1.25 0. in
  let square = P.Polygon [ o; e1; P.add e1 e2; e2 ] in
  let square_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.14 0.20 0.48 0.80)
    ; stroke = Some (Gg.Color.v ~alpha:0.55 0.18 0.30 0.58)
    ; width = 1.2
    ; dash = []
    ; opacity = 1.
    }
  in
  let arc =
    List.init 33 (fun i ->
      let a = (Float.pi /. 2.) *. float_of_int i /. 32. in
      p3 (1.25 *. Float.cos a) (1.25 *. Float.sin a) 0.002)
  in
  let entities =
    [ Draw.static ~layer:1 ~style:square_style square ]
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ polyline3 ~color:violet ~width:1.6 ~dash:[ 5.; 4. ] camera arc
      ; arrow2d ~color:red ~width:2.8 camera o e1
      ; arrow2d ~color:green ~width:2.8 camera o e2
      ; disc ~color:ink ~radius:3.5 camera o
      ; ring ~color:red ~radius:4.5 camera e1
      ; ring ~color:green ~radius:4.5 camera e2
      ; label ~color:red ~size:15. ~dx:8. ~dy:18. camera e1 "e1"
      ; label ~color:green ~size:15. ~dx:8. ~dy:(-8.) camera e2 "e2"
      ; label ~color:violet ~size:13. ~dx:(-34.) ~dy:14. camera (p3 0.92 0.18 0.)
          "e1 . e12 = e2"
      ; label ~color:(Gg.Color.v 0.18 0.24 0.55) ~size:12. ~dx:(-28.) ~dy:6.
          camera (p3 0.62 0.62 0.) "the plane e12"
      ]
  in
  save "contraction-quarter-turn" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  e1 . e12 / e2 . e12           [%s] / [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (E3.inner E3.e1 (E3.op E3.e1 E3.e2))))))
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (E3.inner E3.e2 (E3.op E3.e1 E3.e2))))))

(* ─── Figure 11: the Hodge dual is the orthogonal complement ─── *)

let figure_dual () =
  let camera =
    C.create
      ~eye:(p3 1.75 (-2.05) 1.85)
      ~target:(p3 0.42 0.42 0.48)
      ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.8)
      ~width
      ~height
      ()
  in
  let o = p3 0. 0. 0.
  and e1 = p3 1.1 0. 0.
  and e2 = p3 0. 1.1 0.
  and e3 = p3 0. 0. 1.25 in
  let square_style =
    { Draw.fill = Some (Gg.Color.v ~alpha:0.17 0.20 0.48 0.80)
    ; stroke = Some (Gg.Color.v ~alpha:0.60 0.18 0.30 0.58)
    ; width = 1.3
    ; dash = []
    ; opacity = 1.
    }
  in
  let entities =
    [ ground ~size:1.8 (ground_style ~alpha:0.03 ()) ]
    @ grid ~layer:0 ~size:1.6 ~step:0.4
    @ [ Draw.static ~layer:1 ~style:square_style
          (P.Polygon [ o; e1; P.add e1 e2; e2 ]) ]
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ arrow2d ~color:red ~width:2.8 camera o e3
      ; label ~color:red ~size:15. ~dx:8. ~dy:6. camera e3 "e3"
      ; label ~color:(Gg.Color.v 0.18 0.24 0.55) ~size:13. ~dx:(-24.) ~dy:(-6.)
          camera (P.scale (P.add e1 e2) 0.5) "B = e12  (grade 2)"
      ; label ~color:red ~size:12. ~dx:8. ~dy:(-20.) camera (p3 0. 0. 0.62)
          "B* = e3  (grade 1)"
      ; label ~color:muted ~size:12. ~dx:16. ~dy:6. camera (p3 1.12 1.12 0.02)
          "B* = B I^(-1)"
      ]
  in
  save "dual-complement" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  dual e12                       [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (E3.dual (E3.op E3.e1 E3.e2))))))

(* ─── Figure 12: four conformal constructions ─── *)

let save_page name ~width ~height picture =
  let frame = Frame.create ~density:1.4 ~width ~height picture in
  Frame.save_svg frame (Filename.concat out_dir (name ^ ".svg"));
  Printf.printf "wrote %s/%s.svg\n%!" out_dir name

let clip_tile ~w ~h picture =
  Vg.Picture.clip (Gg.Path.rect (Gg.Box2.v 0. 0. w h)) picture

let tile ~w ~h col row picture =
  let picture = clip_tile ~w ~h picture in
  Vg.Picture.transform
    (Gg.Affine.translate (float col *. w) (float row *. h))
    picture

let figure_construction () =
  let tw = 600. and th = 450. in
  let caption s =
    label2d ~color:ink ~size:20. ~x:22. ~y:34. s
  in
  (* (a) two points -> point pair *)
  let tile_pair () =
    let camera =
      C.create ~eye:(p3 0.85 (-1.55) 0.95) ~target:(p3 0. 0. 0.38)
        ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.6) ~width:tw ~height:th ()
    in
    let a = p3 (-0.7) 0. 0.38 and b = p3 0.7 0. 0.38 in
    let style =
      { Draw.fill = None
      ; stroke = Some violet
      ; width = 3.2
      ; dash = []
      ; opacity = 1.
      }
    in
    let entities =
      [ ground ~size:1.5 (ground_style ~alpha:0.03 ()) ]
      @ grid ~layer:0 ~size:1.3 ~step:0.35
      @ [ Draw.static ~layer:2 ~style (P.Segment (a, b)) ]
    in
    let scene = Draw.create camera entities in
    let overlay =
      Vg.Picture.group
        [ disc ~color:ink ~radius:4.5 camera a
        ; disc ~color:ink ~radius:4.5 camera b
        ; label ~color:ink ~size:17. ~dx:(-8.) ~dy:26. camera a "X1"
        ; label ~color:ink ~size:17. ~dx:8. ~dy:26. camera b "X2"
        ; label2d ~color:violet ~size:16. ~x:80. ~y:330.
            "P = X1 ^ X2  (grade 2, direct)"
        ]
    in
    Vg.Picture.group
      [ scene_picture scene; overlay
      ; caption "2 points -> a point pair"
      ]
  in
  (* (b) three points -> circle *)
  let tile_circle () =
    let camera =
      C.create ~eye:(p3 2.35 (-2.5) 2.1) ~target:(p3 0. 0. 0.75)
        ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.7) ~width:tw ~height:th ()
    in
    let normal = P.normalize (p3 0.3 0.2 1.) in
    let u = P.normalize (P.cross normal (p3 0. 1. 0.)) in
    let v = P.cross normal u in
    let c = p3 0. 0. 0.8 and r = 0.85 in
    let at t =
      P.add c (P.add (P.scale u (r *. Float.cos t)) (P.scale v (r *. Float.sin t)))
    in
    let pts = [ at (Float.pi /. 2.); at ((Float.pi /. 2.) +. (2. *. Float.pi /. 3.))
              ; at ((Float.pi /. 2.) +. (4. *. Float.pi /. 3.)) ] in
    let cp (q : P.p3) = Cga.point3 q.P.x q.P.y q.P.z in
    let z = Cga.circle (cp (List.nth pts 0)) (cp (List.nth pts 1)) (cp (List.nth pts 2)) in
    let entities =
      [ ground ~size:1.5 (ground_style ~alpha:0.03 ()) ]
      @ grid ~layer:0 ~size:1.3 ~step:0.35
      @ [ Draw.static ~layer:1
            ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.10 0.75 0.45 0.10)
                   ; stroke = Some (Gg.Color.v ~alpha:0.55 0.50 0.30 0.05)
                   ; width = 1.0; dash = []; opacity = 1. }
            (P.Polygon pts)
        ; Draw.static ~layer:3 ~style:(Draw.outline ~width:2.8 amber)
            (P.of_cga_circle z)
        ]
    in
    let scene = Draw.create camera entities in
    let overlay =
      Vg.Picture.group
        (List.mapi
           (fun i pt ->
              Vg.Picture.group
                [ ring ~color:amber ~radius:4.6 camera pt
                ; label ~color:ink ~size:17. ~dx:10. ~dy:(-4.) camera pt
                    (Printf.sprintf "X%d" (i + 1))
                ])
           pts
         @ [ label2d ~color:amber ~size:16. ~x:220. ~y:410.
               "z = (X1 ^ X2 ^ X3)*  (grade 2)"
           ])
    in
    Vg.Picture.group [ scene_picture scene; overlay; caption "3 points -> a circle" ]
  in
  (* (c) four points -> sphere *)
  let tile_sphere () =
    let camera =
      C.create ~eye:(p3 2.5 (-2.9) 1.8) ~target:(p3 0. 0. 0.55)
        ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.8) ~width:tw ~height:th ()
    in
    let centre = p3 0. 0. 0.6 and r = 0.55 in
    let dirs =
      [ p3 1. 0. 0.4; p3 (-1.) 0.1 0.3; p3 0.1 1. 0.2; p3 0.2 (-0.9) 0.5 ]
    in
    let pts =
      List.map
        (fun d ->
           let d = P.normalize d in
           P.add centre (P.scale d r))
        dirs
    in
    let cp (q : P.p3) = Cga.point3 q.P.x q.P.y q.P.z in
    let s =
      Cga.sphere_through (cp (List.nth pts 0)) (cp (List.nth pts 1))
        (cp (List.nth pts 2)) (cp (List.nth pts 3))
    in
    let entities =
      [ ground ~size:1.5 (ground_style ~alpha:0.03 ()) ]
      @ grid ~layer:0 ~size:1.3 ~step:0.35
      @ [ Draw.static ~layer:1
            ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.16 0.05 0.45 0.55)
                   ; stroke = Some (Gg.Color.v ~alpha:0.55 0.05 0.45 0.55)
                   ; width = 1.2; dash = []; opacity = 1. }
            (P.of_cga_sphere s)
        ]
    in
    let scene = Draw.create camera entities in
    let overlay =
      Vg.Picture.group
        (List.mapi
           (fun i pt ->
              Vg.Picture.group
                [ ring ~color:teal ~radius:4.6 camera pt
                ; label ~color:ink ~size:17. ~dx:8. ~dy:(-6.) camera pt
                    (Printf.sprintf "X%d" (i + 1))
                ])
           pts
         @ [ label2d ~color:teal ~size:16. ~x:26. ~y:414.
               "S = (X1^X2^X3^X4)*  (grade 1)"
           ])
    in
    Vg.Picture.group [ scene_picture scene; overlay; caption "4 points -> a sphere" ]
  in
  (* (d) three points + einf -> plane *)
  let tile_plane () =
    let camera =
      C.create ~eye:(p3 1.85 (-2.3) 2.0) ~target:(p3 0.3 0.3 0.55)
        ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.7) ~width:tw ~height:th ()
    in
    let pts = [ p3 0. 0. 0.6; p3 1.25 0. 0.6; p3 0. 1.25 0.6 ] in
    let cp (q : P.p3) = Cga.point3 q.P.x q.P.y q.P.z in
    let pi =
      Cga.plane_through (cp (List.nth pts 0)) (cp (List.nth pts 1))
        (cp (List.nth pts 2))
    in
    let patch =
      [ p3 (-0.5) (-0.5) 0.6; p3 1.7 (-0.5) 0.6
      ; p3 1.7 1.7 0.6; p3 (-0.5) 1.7 0.6
      ]
    in
    let entities =
      [ ground ~size:1.5 (ground_style ~alpha:0.03 ()) ]
      @ grid ~layer:0 ~size:1.3 ~step:0.35
      @ [ Draw.static ~layer:1
            ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.13 0.55 0.30 0.25)
                   ; stroke = Some (Gg.Color.v ~alpha:0.55 0.10 0.35 0.55)
                   ; width = 1.2; dash = []; opacity = 1. }
            (with_patch patch (P.of_cga_plane pi))
        ]
    in
    let scene = Draw.create camera entities in
    let overlay =
      Vg.Picture.group
        (List.mapi
           (fun i pt ->
              Vg.Picture.group
                [ disc ~color:ink ~radius:4.2 camera pt
                ; label ~color:ink ~size:17. ~dx:8. ~dy:(-6.) camera pt
                    (Printf.sprintf "X%d" (i + 1))
                ])
           pts
         @ [ label2d ~color:(Gg.Color.v 0.10 0.35 0.22) ~size:16. ~x:220. ~y:414.
               "pi = (X1^X2^X3^e_inf)*  (grade 1)"
           ])
    in
    Vg.Picture.group
      [ scene_picture scene; overlay; caption "3 points + e_inf -> a plane" ]
  in
  let tiles = [ tile_pair (); tile_circle (); tile_sphere (); tile_plane () ] in
  let placed =
    List.concat
      (List.mapi
         (fun i t ->
            let col = i mod 2 and row = i / 2 in
            [ tile ~w:tw ~h:th col row t ])
         tiles)
  in
  let rules =
    Vg.Picture.group
      [ line2d ~color:(Gg.Color.gray ~alpha:0.25 0.5) ~width:0.8
          (tw, 10.) (tw, (2. *. th) -. 10.)
      ; line2d ~color:(Gg.Color.gray ~alpha:0.25 0.5) ~width:0.8
          (10., th) ((2. *. tw) -. 10., th)
      ]
  in
  save_page "object-construction" ~width:(2. *. tw) ~height:(2. *. th)
    (Vg.Picture.group (rules :: placed))

(* ─── Figure 13: round versus flat ─── *)

let figure_round_flat () =
  let camera =
    C.create ~eye:(p3 2.8 (-3.3) 2.35) ~target:(p3 0. 0. 0.62)
      ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.9) ~width ~height ()
  in
  let s = Cga.sphere ~center:(v3 0. 0. 0.62) ~radius:(sc 0.58) in
  let pi = Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.) in
  let patch =
    [ p3 (-1.6) (-1.6) 0.; p3 1.6 (-1.6) 0.
    ; p3 1.6 1.6 0.; p3 (-1.6) 1.6 0.
    ]
  in
  let entities =
    [ Draw.static ~layer:0
        ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.08 0.55 0.45 0.18)
               ; stroke = Some (Gg.Color.v ~alpha:0.35 0.20 0.45 0.45)
               ; width = 1.0; dash = []; opacity = 1. }
        (with_patch patch (P.of_cga_plane pi))
    ; Draw.static ~layer:1
        ~style:{ Draw.fill = Some (Gg.Color.v ~alpha:0.22 0.05 0.40 0.60)
               ; stroke = Some teal
               ; width = 1.4; dash = []; opacity = 1. }
        (P.of_cga_sphere s)
    ]
  in
  let scene = Draw.create camera entities in
  let overlay =
    Vg.Picture.group
      [ label ~color:teal ~size:13. ~dx:10. ~dy:(-16.) camera (p3 0. 0. 1.32)
          "S : e_inf . S = -1  (round)"
      ; label ~color:(Gg.Color.v 0.18 0.35 0.28) ~size:13. ~dx:(-34.) ~dy:24.
          camera (p3 (-1.15) (-1.15) 0.01) "pi : e_inf . pi = 0  (flat)"
      ; disc ~color:ink ~radius:3.2 camera (p3 0. 0. 0.62)
      ]
  in
  save "round-flat" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  einf . sphere / einf . plane    %.4g / %.4g\n"
    (item (Cga.scalar_prod Cga.einf s))
    (item (Cga.scalar_prod Cga.einf (Cga.normalize_plane pi)))

(* ─── Figure 14: the three cases of exp(B) ─── *)

let figure_exp_cases () =
  let tw = 400. and th = 450. in
  let axes ox oy sx sy =
    Vg.Picture.group
      [ line2d ~color:(Gg.Color.gray ~alpha:0.55 0.5) ~width:1.0
          (ox -. sx, oy) (ox +. sx, oy)
      ; line2d ~color:(Gg.Color.gray ~alpha:0.55 0.5) ~width:1.0
          (ox, oy -. sy) (ox, oy +. sy)
      ]
  in
  let caption x y s = label2d ~color:ink ~size:19. ~x ~y s in
  let note x y s = label2d ~color:muted ~size:15. ~x ~y s in
  (* elliptic: a circle *)
  let elliptic () =
    let ox = 200. and oy = 285. and r = 105. in
    let at a = (ox +. (r *. Float.cos a), oy -. (r *. Float.sin a)) in
    let curve =
      List.init 97 (fun i ->
        let a = 2. *. Float.pi *. float_of_int i /. 96. in
        at a)
    in
    let xs = Array.of_list (List.map fst curve)
    and ys = Array.of_list (List.map snd curve) in
    let points = List.map at [ 0.; Float.pi /. 4.; Float.pi /. 2.; 3. *. Float.pi /. 4. ] in
    Vg.Picture.group
      ([ axes ox oy 150. 150.
       ; Vg.Picture.stroke (Gg.Stroke.v 2.2) blue (Gg.Path.polyline xs ys)
       ; caption 118. 42. "B^2 = -theta^2"
       ; note 150. 64. "rotation"
       ]
       @ List.map (fun p -> dot2d ~color:blue p) points
       @ [ ring2d ~color:blue ~radius:7. (at (Float.pi /. 2.))
         ; label2d ~color:ink ~size:15. ~x:(ox +. 10.) ~y:(oy +. 22.) "x"
         ; label2d ~color:ink ~size:15. ~x:(ox -. 30.) ~y:(oy -. r -. 12.) "R x"
         ])
  in
  (* hyperbolic: a boost branch *)
  let hyperbolic () =
    let ox = 160. and oy = 285. and sx = 70. and sy = 70. in
    let to_page x y = (ox +. (sx *. x), oy -. (sy *. y)) in
    let curve =
      List.init 97 (fun i ->
        let t = -1.3 +. (2.6 *. float_of_int i /. 96.) in
        to_page (Float.cosh t) (Float.sinh t))
    in
    let xs = Array.of_list (List.map fst curve)
    and ys = Array.of_list (List.map snd curve) in
    let points = List.map (fun t -> to_page (Float.cosh t) (Float.sinh t)) [ 0.; 0.6; 1.1 ] in
    Vg.Picture.group
      ([ axes ox oy 130. 150.
       ; Vg.Picture.stroke (Gg.Stroke.v 2.2) green (Gg.Path.polyline xs ys)
       ; caption 118. 42. "B^2 = +theta^2"
       ; note 150. 64. "boost (dilation)"
       ]
       @ List.map (fun p -> dot2d ~color:green p) points
       @ [ label2d ~color:ink ~size:15. ~x:(ox -. 14.) ~y:(oy +. 22.) "1"
         ; label2d ~color:ink ~size:15. ~x:(ox -. 26.) ~y:(oy -. 128.) "B"
         ])
  in
  (* parabolic: equal steps along a line *)
  let parabolic () =
    let ox = 80. and oy = 285. and sx = 90. in
    let pts = [ 0.; 1.; 2. ] in
    let at t = (ox +. (sx *. t), oy) in
    Vg.Picture.group
      ([ axes ox oy 150. 150.
       ; line2d ~color:amber ~width:2.6 (at 0.) (at 2.)
       ; caption 118. 42. "B^2 = 0"
       ; note 150. 64. "translation (1 + B)"
       ]
       @ List.map (fun t -> dot2d ~color:amber (at t)) pts
       @ [ label2d ~color:ink ~size:15. ~x:(fst (at 0.) -. 8.) ~y:(oy +. 24.) "x"
         ; label2d ~color:ink ~size:15. ~x:(fst (at 1.) -. 24.) ~y:(oy +. 24.) "x + t"
         ; label2d ~color:ink ~size:15. ~x:(fst (at 2.) -. 34.) ~y:(oy +. 24.) "x + 2t"
         ])
  in
  let ts = [ elliptic (); hyperbolic (); parabolic () ] in
  let placed =
    List.concat
      (List.mapi (fun i t -> [ tile ~w:tw ~h:th i 0 t ]) ts)
  in
  let rules =
    Vg.Picture.group
      [ line2d ~color:(Gg.Color.gray ~alpha:0.25 0.5) ~width:0.8
          (tw, 10.) (tw, th -. 10.)
      ; line2d ~color:(Gg.Color.gray ~alpha:0.25 0.5) ~width:0.8
          (2. *. tw, 10.) (2. *. tw, th -. 10.)
      ]
  in
  let page =
    Vg.Picture.fill (Gg.Color.v 0.98 0.98 0.98)
      (Gg.Path.rect (Gg.Box2.v 0. 0. (3. *. tw) th))
  in
  save_page "exp-three-cases" ~width:(3. *. tw) ~height:th
    (Vg.Picture.group (page :: rules :: placed))

(* ─── Figure 15: one sandwich transforms every object ─── *)

let figure_sandwich () =
  let camera =
    C.create ~eye:(p3 4.1 (-5.4) 3.5) ~target:(p3 1.35 0. 0.55)
      ~up:(p3 0. 0. 1.) ~fov_y:(Float.pi /. 4.9) ~width ~height ()
  in
  let motor =
    Motor.mul (Motor.translate3 2.6 0. 0.)
      (Motor.rotate ~axis:(v3 0. 0. 1.) ~angle:(sc (Float.pi /. 6.)))
  in
  let point = Cga.point3 0.6 0. 0.4 in
  let sphere = Cga.sphere ~center:(v3 0. 0. 0.95) ~radius:(sc 0.42) in
  let circle =
    Cga.circle (Cga.point3 0.7 0. 0.) (Cga.point3 0. 0.7 0.) (Cga.point3 (-0.7) 0. 0.)
  in
  let line_a = Cga.point3 1.05 0. 0.12
  and line_b = Cga.point3 (-1.05) 0. 0.12 in
  let plane = Cga.plane ~normal:(v3 0. 0. 1.) ~offset:(sc 0.) in
  let patch =
    [ p3 (-1.15) (-1.15) 0.; p3 1.15 (-1.15) 0.
    ; p3 1.15 1.15 0.; p3 (-1.15) 1.15 0.
    ]
  in
  let ghost =
    { Draw.fill = None
    ; stroke = Some (Gg.Color.gray ~alpha:0.32 0.55)
    ; width = 1.1
    ; dash = [ 4.; 4. ]
    ; opacity = 1.
    }
  in
  let ghost_fill alpha =
    { Draw.fill = Some (Gg.Color.v ~alpha 0.45 0.50 0.58)
    ; stroke = Some (Gg.Color.v ~alpha:0.30 0.45 0.50 0.58)
    ; width = 1.0
    ; dash = [ 4.; 4. ]
    ; opacity = 1.
    }
  in
  let draw_obj ~layer ~ghost_obj obj =
    match obj with
    | `Point p -> [ Draw.static ~layer ~style:ghost (P.of_cga_point p) ]
    | `Sphere s ->
      [ Draw.static ~layer
          ~style:(if ghost_obj then ghost_fill 0.08
                  else { Draw.fill = Some (Gg.Color.v ~alpha:0.24 0.05 0.40 0.60)
                       ; stroke = Some teal; width = 1.4
                       ; dash = []; opacity = 1. })
          (P.of_cga_sphere s) ]
    | `Circle z ->
      [ Draw.static ~layer
          ~style:(if ghost_obj then ghost
                  else Draw.outline ~width:2.4 amber)
          (P.of_cga_circle z) ]
    | `Segment (a, b) ->
      [ Draw.static ~layer
          ~style:(if ghost_obj then ghost
                  else Draw.outline ~width:2.4 red)
          (P.Segment (p3_of_cga a, p3_of_cga b)) ]
    | `Plane pi ->
      [ Draw.static ~layer
          ~style:(if ghost_obj then ghost_fill 0.04
                  else { Draw.fill = Some (Gg.Color.v ~alpha:0.06 0.30 0.55 0.18)
                       ; stroke = Some (Gg.Color.v ~alpha:0.40 0.15 0.35 0.45)
                       ; width = 1.0; dash = []; opacity = 1. })
          (with_patch patch (P.of_cga_plane pi)) ]
  in
  let objs =
    [ `Point point; `Sphere sphere; `Circle circle
    ; `Segment (line_a, line_b); `Plane plane ]
  in
  let original =
    List.concat
      (List.map
         (fun o ->
            draw_obj ~layer:(match o with `Plane _ -> 0 | _ -> 1) ~ghost_obj:true o)
         objs)
  in
  let moved =
    List.concat
      (List.map
         (fun o ->
            let o' =
              match o with
              | `Point p -> `Point (Cga.apply_motor motor p)
              | `Sphere s -> `Sphere (Cga.apply_motor motor s)
              | `Circle z -> `Circle (Cga.apply_motor motor z)
              | `Segment (a, b) ->
                `Segment (Cga.apply_motor motor a, Cga.apply_motor motor b)
              | `Plane pi -> `Plane (Cga.apply_motor motor pi)
            in
            draw_obj ~layer:(match o' with `Plane _ -> 2 | _ -> 3) ~ghost_obj:false o')
         objs)
  in
  let frame_at m =
    let origin = p3_of (Motor.translation m) in
    let r = rotation_rows m in
    let axis i =
      let (x, _, _) = r.(i) in
      let (_, y, _) = r.(i) in
      let (_, _, z) = r.(i) in
      p3 x y z
    in
    P.Frame
      { origin
      ; x = P.add origin (P.scale (axis 0) 0.3)
      ; y = P.add origin (P.scale (axis 1) 0.3)
      ; z = P.add origin (P.scale (axis 2) 0.3)
      }
  in
  let entities =
    original @ moved
    @ [ Draw.static ~layer:4 ~style:Draw.default (frame_at Motor.one)
      ; Draw.static ~layer:4 ~style:Draw.default (frame_at motor)
      ]
  in
  let scene = Draw.create camera entities in
  let src = p3_of_cga point
  and dst = p3_of_cga (Cga.apply_motor motor point) in
  let overlay =
    Vg.Picture.group
      [ polyline3 ~color:violet ~width:1.5 ~dash:[ 5.; 4. ] camera [ src; dst ]
      ; ring ~color:violet ~radius:5.0 ~width:1.8 camera src
      ; ring ~color:violet ~radius:5.0 ~width:1.8 camera dst
      ; label ~color:violet ~size:13. ~dx:12. ~dy:6. camera dst
          "X  ->  M X M~"
      ; label ~color:muted ~size:12. ~dx:(-30.) ~dy:28. camera (p3 (-1.15) (-1.15) 0.02)
          "dashed: before"
      ; label ~color:muted ~size:12. ~dx:10. ~dy:28. camera (p3 1.5 (-1.15) 0.02)
          "solid: after one sandwich"
      ; label ~color:ink ~size:12. ~dx:8. ~dy:22. camera (p3_of (Motor.translation motor))
          "M"
      ]
  in
  save "sandwich-uniform" (Vg.Picture.group [ scene_picture scene; overlay ]);
  Printf.printf "  sandwich point                 [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.coords (Cga.apply_motor motor point))))))

(* ─── numerical checks quoted by the notes ─── *)

let checks () =
  Printf.printf "=== checks ===\n";
  let v3' = v3 in
  let s = Cga.sphere ~center:(v3' 0. 0. 1.) ~radius:(sc 1.) in
  Printf.printf "  sphere_radius2                  %.4g\n" (item (Cga.sphere_radius2 s));
  Printf.printf "  incident (1,0,1) on sphere      %s\n"
    (bool (Cga.incident (Cga.point3 1. 0. 1.) s));
  let s = Cga.sphere ~center:(v3' 0. 0. 0.) ~radius:(sc 2.) in
  Printf.printf "  scalar_prod (3,0,0) sphere      %.4g\n"
    (item (Cga.scalar_prod (Cga.point3 3. 0. 0.) s));
  let pi =
    Cga.plane ~normal:(v3' 0. 0. 1.) ~offset:(sc 1.)
  in
  Printf.printf "  point (4,5,3) . plane           %.4g\n"
    (item (Cga.scalar_prod (Cga.point3 4. 5. 3.) pi));
  Printf.printf "  is_flat plane / is_round sphere %s / %s\n"
    (bool (Cga.is_flat pi)) (bool (Cga.is_round s));
  let z =
    Cga.circle (Cga.point3 1. 0. 0.) (Cga.point3 0. 1. 0.) (Cga.point3 (-1.) 0. 0.)
  in
  Printf.printf "  circle_radius2                  %.4g\n" (item (Cga.circle_radius2 z));
  Printf.printf "  circle_center                   [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Nx.to_array (Cga.coords (Cga.circle_center z))))));
  let s1 = Cga.sphere ~center:(v3' 0. 0. 0.) ~radius:(sc 1.) in
  let s2 = Cga.sphere ~center:(v3' 0. 0. 1.) ~radius:(sc 1.) in
  let z2 = Cga.circle_of_spheres s1 s2 in
  Printf.printf "  carrier circle center / radius2 [%s] %.4g\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Nx.to_array (Cga.coords (Cga.circle_center z2))))))
    (item (Cga.circle_radius2 z2));
  let sph =
    Cga.sphere_through (Cga.point3 1. 0. 0.) (Cga.point3 (-1.) 0. 0.)
      (Cga.point3 0. 1. 0.) (Cga.point3 0. 0. 1.)
  in
  Printf.printf "  sphere_through 4 radius2        %.4g\n"
    (item (Cga.sphere_radius2 sph));
  let d = Cga.dilator (sc 0.5) in
  Printf.printf "  dilator 0.5 of (1,0,0)          [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.coords (Cga.sandwich d (Cga.point3 1. 0. 0.)))))));
  let k = Cga.transversion (v3' 0.5 0. 0.) in
  Printf.printf "  transversion 0.5 of (1,0,0)     [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.coords (Cga.sandwich k (Cga.point3 1. 0. 0.)))))));
  let x = Cga.point3 1. 1. 0.
  and y = Cga.point3 4. 5. 0. in
  Printf.printf "  X . Y / distance2 / distance    %.4g / %.4g / %.4g\n"
    (item (Cga.scalar_prod x y)) (item (Cga.distance2 x y)) (item (Cga.distance x y));
  let m =
    Motor.mul (Motor.translate3 0. 0. 1.)
      (Motor.rotate ~axis:(v3' 0. 0. 1.) ~angle:(sc (Float.pi /. 2.)))
  in
  Printf.printf "  motor (translate * rotate)      [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.coords (Cga.apply_motor m (Cga.point3 1. 0. 0.)))))));
  Printf.printf "  translation of m                [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Nx.to_array (Motor.translation m)))));
  Printf.printf "  to_array (translate 0 0 1)      [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Motor.to_array (Motor.translate3 0. 0. 1.)))));
  Printf.printf "  adjoint shapes                  [%s] / [%s]\n"
    (String.concat "; "
       (List.map string_of_int (Array.to_list (Nx.shape (Motor.adjoint m)))))
    (String.concat "; "
       (List.map string_of_int (Array.to_list (Nx.shape (Cga.adjoint (Cga.of_motor m))))));
  let centers =
    Nx.create Nx.float32 [| 4; 3 |]
      [| 0.; 0.; 0.; 1.; 0.; 0.; 0.; 1.; 0.; 0.; 0.; 1. |]
  in
  let xs = Cga.point centers in
  Printf.printf "  batched point shape             [%s]\n"
    (String.concat "; " (List.map string_of_int (Array.to_list (Nx.shape xs))));
  Printf.printf "  batched distance2               [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list
             (Nx.to_array (Cga.distance2 xs (Cga.point3 0. 0. 0.))))));
  let cam =
    C.create ~eye:(p3 4. (-4.) 3.) ~target:(p3 0. 0. 0.5) ~up:(p3 0. 0. 1.)
      ~fov_y:(Float.pi /. 4.) ~width ~height ()
  in
  let focal = C.focal cam in
  let ray = Pga.line_through (Pga.point3 0. 0. 0.) (Pga.point3 0.2 (-0.1) (-2.0)) in
  let hit = Pga.meet ray (Pga.plane3 0. 0. 1. (-.focal)) in
  Printf.printf "  projection meet                 [%s]  (focal %.1f)\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.2f")
          (Array.to_list (Nx.to_array (Pga.point_coords hit)))))
    focal;
  let q = Motor.of_quaternion (Nx.create Nx.float32 [| 4 |] [| 1.; 0.; 0.; 0. |]) in
  Printf.printf "  of_quaternion / to_quaternion   [%s]\n"
    (String.concat "; "
       (List.map (Printf.sprintf "%.4g")
          (Array.to_list (Nx.to_array (Motor.to_quaternion q)))));
  let r =
    Motor.rotate ~axis:(v3' 0. 0. 1.) ~angle:(sc (Float.pi /. 2.))
  in
  Printf.printf "  adjoint of rotation shape       [%s]\n"
    (String.concat "; "
       (List.map string_of_int (Array.to_list (Nx.shape (Motor.adjoint r)))))

let () =
  checks ();
  figure_e3 ();
  figure_pga ();
  figure_circle ();
  figure_transversion ();
  figure_slerp ();
  figure_fk ();
  figure_camera ();
  figure_parabola ();
  figure_grades ();
  figure_contraction ();
  figure_dual ();
  figure_construction ();
  figure_round_flat ();
  figure_exp_cases ();
  figure_sandwich ()
