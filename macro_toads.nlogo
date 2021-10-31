extensions [csv array]

globals
[
  yearly-spread-table

  yearly-spread-table-fence
  yearly-spread-table-fence7
  yearly-spread-table-fence30

  yearly-spread-table-fence-trap
  yearly-spread-table-fence30-trap2
  yearly-spread-table-fence30-trap1
  yearly-spread-table-fence7-trap2
  yearly-spread-table-fence7-trap1

  yearly-spread-table-trap
  yearly-spread-table-trap1
  yearly-spread-table-trap2
  distance-list
  capacity-list

  min-days
  max-days
  step-days
  days-list

  dis-step
  cap-step
  min-dis
  min-cap
  max-dis
  max-cap

  mean-capacity
]

breed [wps wp]
breed [stations station]
breed [clocs cloc]
breed [fs f]

clocs-own
[
  fence-position
]

wps-own
[
  wp-type
  capacity
  colonised?
  emitting?
  colonised-since
  exclude?
  exclusion-fail?
  exclusion-fail-since
  trapped?
  radius

  act-capacity
  boost-index
]

links-own
[
  fenced?
]

stations-own
[
  code
  name
  mean-move-days
  sd-move-days
  max-move-days
  min-move-days

  move-days
]

to load-spread-table
  set mean-capacity 60
  set dis-step 20
  set cap-step 20
  set min-dis 20
  set min-cap 20
  set max-dis 200
  set max-cap 100

  set min-days 40
  set max-days 160
  set step-days 20

  set-default-shape wps "circle"
  set-default-shape stations "cloud"
  set-default-shape clocs "circle"
  set-default-shape fs "line"

  ;ifelse light-theme? [ ask patches [set pcolor white] ]
  ;[ ask patches [ set pcolor black ] ]
  clear-patches
  clear-drawing
  import-drawing "figures/ausmap_cropped.png"

  set distance-list (range min-dis (max-dis + dis-step) dis-step)
  set capacity-list (range min-cap (max-cap + cap-step) cap-step)
  set days-list (range min-days (max-days + step-days) step-days)

  if yearly-spread-table = 0 [
    set yearly-spread-table create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
    let file csv:from-file "toads final.csv"
    foreach (sublist file 1 (length file)) [row ->
      insert-prob-to-matrix row yearly-spread-table
    ]
    show yearly-spread-table
  ]

  if fence != "none" [
    if fence = "fence30" [
      if yearly-spread-table-fence30 = 0 [
        set yearly-spread-table-fence30 (create-empty-spread-table (length capacity-list) (length distance-list) (length days-list))
        let file csv:from-file "toads final w fence 30.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence30
        ]
      ]
      set yearly-spread-table-fence yearly-spread-table-fence30
    ]
    if fence = "fence7" [
      if yearly-spread-table-fence7 = 0 [
        set yearly-spread-table-fence7 (create-empty-spread-table (length capacity-list) (length distance-list) (length days-list))
        let file csv:from-file "toads final w fence 7.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence7
        ]
      ]
      set yearly-spread-table-fence yearly-spread-table-fence7
    ]
  ]

  if fence != "none" and trap != "none" [
    if fence = "fence30" and trap = "trap1" [
      if yearly-spread-table-fence30-trap1 = 0 [
        set yearly-spread-table-fence30-trap1 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w fence 30 trap dest 1.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence30-trap1
        ]
      ]
      set yearly-spread-table-fence-trap yearly-spread-table-fence30-trap1
    ]
    if fence = "fence30" and trap = "trap2" [
      if yearly-spread-table-fence30-trap2 = 0 [
        set yearly-spread-table-fence30-trap2 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w fence 30 trap dest 2.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence30-trap2
        ]
      ]
      set yearly-spread-table-fence-trap yearly-spread-table-fence30-trap2
    ]
    if fence = "fence7" and trap = "trap1" [
      if yearly-spread-table-fence7-trap1 = 0 [
        set yearly-spread-table-fence7-trap1 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w fence 7 trap dest 1.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence7-trap1
        ]
      ]
      set yearly-spread-table-fence-trap yearly-spread-table-fence7-trap1
    ]
    if fence = "fence7" and trap = "trap2" [
      if yearly-spread-table-fence7-trap2 = 0 [
        set yearly-spread-table-fence7-trap2 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w fence 7 trap dest 2.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-fence7-trap2
        ]
      ]
      set yearly-spread-table-fence-trap yearly-spread-table-fence7-trap2
    ]
  ]

  if trap != "none" [
    if trap = "trap1" [
      if yearly-spread-table-trap1 = 0 [
        set yearly-spread-table-trap1 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w trap dest 1.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-trap1
        ]
      ]
      set yearly-spread-table-trap yearly-spread-table-trap1
    ]
    if trap = "trap2" [
      if yearly-spread-table-trap2 = 0 [
        set yearly-spread-table-trap2 create-empty-spread-table (length capacity-list) (length distance-list) (length days-list)
        let file csv:from-file "toads final w trap dest 2.csv"
        foreach (sublist file 1 (length file)) [row ->
          insert-prob-to-matrix row yearly-spread-table-trap2
        ]
      ]
      set yearly-spread-table-trap yearly-spread-table-trap2
    ]
  ]

  if not any? clocs [
    let loc-file csv:from-file "control locations.csv"
    foreach (sublist loc-file 1 (length loc-file)) [row ->
      generate-control-loc row
    ]
  ]

  if not any? stations [
    let station-file csv:from-file "station_final.csv"
    foreach (sublist station-file 1 (length station-file)) [row ->
      generate-station row
    ]
  ]

  if not any? wps [
    let file csv:from-file "Plb_water_points6_formatted.csv"
    foreach (sublist file 1 566) [row ->
      generate-wp row
    ]
  ]

  file-close-all
end

to setup
  clear-ticks
  clear-links

  ask wps [reset-wp]

  ask wps [

    if ycor > 60 [
      set colonised? true
      set colonised-since -1
      set emitting? true
      set color green + 2
    ]
    if xcor < 8 [
      ifelse light-theme? [set color yellow - 1] [set color yellow + 1]
    ]

    ask other wps in-radius ((max-dis + dis-step * boost-index) / 50) with [not link-neighbor? myself] [
        make-edge myself
    ]
  ]

  reset-link-color

  setup-control

  reset-ticks
end

to setup-control
  let controlled-wps sublist (sort-on [distance cloc active-cloc] wps with [wp-type != "Natural"]) 0 no-controlled-wp
  ask clocs [
    ifelse light-theme?
    [
      set color [0 0 0 50]
      set label-color black
    ]
    [
      set color [255 255 255 100]
      set label-color white
    ]

    ifelse who != active-cloc or length controlled-wps = 0 [set hidden? true] [set hidden? false]
    ifelse length controlled-wps > 0 [
      set size 0.3 + 2 * [distance cloc active-cloc] of (last controlled-wps)
    ]
    [
      set size 0
    ]
  ]

  if exclusion? [
    ask turtle-set controlled-wps [
      set exclude? true
      update-color
    ]
  ]

  ask fs [die]
  if fence != "none" [
    generate-fence
    fence-links
;    ask turtle-set controlled-wps [
;      set fenced? true
;      update-color
;    ]
  ]

  if trap != "none" [
    ask turtle-set controlled-wps [
      set trapped? true
      update-color
    ]
  ]
end

to-report create-empty-spread-table [d1 d2 d3]
  let empty-table array:from-list n-values d1 [0]
  foreach (range d1) [cap-index ->
    array:set empty-table cap-index array:from-list (n-values d2 [array:from-list n-values d3 [0]])
  ]
  report empty-table
end

to generate-control-loc [row]
  create-clocs 1 [
    set xcor item 1 row
    set ycor item 2 row
    set fence-position item 3 row
    set label who
  ]
end

to insert-prob-to-matrix [row table]
  let prob (item 4 row)
  let days-index ((item 3 row) - min-days) / step-days
  let cap-index ((item 2 row) - min-cap) / cap-step
  let dis-index ((item 1 row) - min-dis) / dis-step

  array:set (array:item (array:item table cap-index) dis-index) days-index prob

;  let cap-table item cap-index yearly-spread-table
;  let dis-list item dis-index cap-table
;
;  set dis-list replace-item days-index dis-list prob
;  set cap-table replace-item dis-index cap-table dis-list
;  set yearly-spread-table replace-item cap-index yearly-spread-table cap-table
end

to generate-wp [row]
  create-wps 1 [
    set exclude? false
    set exclusion-fail? false
    set exclusion-fail-since -1
    set trapped? false

    set wp-type item 15 row
    setxy (3 + (item 9 row) / 5000) (2 + (item 10 row) / 5000)

    set colonised? false
    set emitting? false

    ifelse wp-type = "Irrigation" [
      let area (item 2 row)
      set radius sqrt (area / pi) * 10 ; one unit of radius = 100m
      set capacity area
      set boost-index 1

      set size 0.5 + 0.04 * radius
    ]
    [
      ifelse randomise-capacity?
      [set capacity (random-poisson mean-capacity) / mean-capacity]
      [set capacity 1]
      set radius 0
      set boost-index 0

      set size 0.5
    ]
    set boost-index boost-index + spread-boost

    let raw-cap (capacity * mean-capacity)
    set act-capacity capacity
    while [raw-cap > max-cap] [
      set raw-cap raw-cap / 4
      set act-capacity act-capacity / 4
      set boost-index boost-index + 1
    ]
    update-color
  ]
end

to reset-wp
  set exclude? false
  set exclusion-fail? false
  set trapped? false
  set colonised? false
  set emitting? false

  ifelse wp-type = "Irrigation" [
    set boost-index 1

    set size 0.5 + 0.04 * radius
  ]
  [
    ifelse randomise-capacity?
    [set capacity (random-poisson mean-capacity) / mean-capacity]
    [set capacity 1]
    set boost-index 0

    set size 0.5
  ]
  set boost-index boost-index + spread-boost

  let raw-cap (capacity * mean-capacity)
  set act-capacity capacity
  while [raw-cap > max-cap] [
    set raw-cap raw-cap / 4
    set act-capacity act-capacity / 4
    set boost-index boost-index + 1
  ]
  update-color
end

to generate-station [row]
  create-stations 1 [
    set code item 1 row
    set name item 2 row
    ; set label name
    setxy ((item 3 row - 119) * 19) ((20.45 + item 4 row) * 24.5)
    set max-move-days item 5 row
    set min-move-days item 6 row
    set mean-move-days item 7 row
    set sd-move-days item 8 row
    ifelse light-theme? [ set color grey ]
    [ set color white ]
  ]
end

to go
  reset-link-color


  ifelse ticks mod wet-year-interval = 0 [
    ask stations [
      set move-days max-move-days + wet-year-extra-days
      set size 2.2
    ]
  ]
  [
    ask stations [
      set move-days random-normal mean-move-days sd-move-days
      set move-days max (list min-move-days min (list move-days max-move-days))
      set size 1 + 1 * (move-days / 127)
    ]
  ]

  ask wps with [exclude? and not exclusion-fail?] [
    if random-float 1 < exclusion-failure-prob [
      set exclusion-fail? true
      set exclusion-fail-since ticks
      update-color
    ]
  ]
  ask wps with [exclusion-fail? and ticks - exclusion-fail-since >= exclusion-repair-delay] [repair-exclusion]

  ask wps with [colonised?] [start-emitting ]
  ask wps with [not colonised? and (not exclude? or exclusion-fail?)]  [
    check-if-colonised-yearly
  ]

  if region-colonised? or ticks >= sim-duration [ stop ]
  tick
end

to check-if-colonised-yearly
  let am-i-colonised? false
  let my-radius radius
  ask link-neighbors with [emitting?] [
    if not am-i-colonised? [
      let spread-table yearly-spread-table
      let spread-fenced? false
      ifelse [fenced?] of link-with myself [
        set spread-fenced? true
        ifelse [trapped?] of myself [
          set spread-table yearly-spread-table-fence-trap
        ]
        [
          set spread-table yearly-spread-table-fence
        ]
      ]
      [
        if [trapped?] of myself [
          set spread-table yearly-spread-table-trap
        ]
      ]

      let dis 50 * distance myself
      let dispersing-days [move-days] of min-one-of stations [distance myself]
      if spread-table = 0 [ show (word "fence " fence "trap " trap )]
      let chance get-interpolated-colon-prob dis dispersing-days (act-capacity) boost-index spread-table

      set chance min list 1 (chance * (1 + (radius / 4)))
      ;    let lowchance item (ceiling dis-index) prob-list
      ;    let highchance item (floor dis-index) prob-list
      ;    let chance ((ceiling dis-index - dis-index) * highchance + (dis-index - floor dis-index) * lowchance)
      if chance > 0 [
        ask link-with myself [
          ifelse spread-fenced?
          [ ifelse light-theme? [set color (red + 3 - chance * 4)] [set color (red - 3 + chance * 4) ]]
          [ ifelse light-theme? [set color (green + 3 - chance * 4)] [set color (green - 3 + chance * 4) ]]
          set thickness 0.2 + chance * 0.5
        ]
      ]
      if random-float 1 < chance [ set am-i-colonised? true ]
    ]
  ]
  if am-i-colonised? [ colonise ]
end

to-report get-colon-prob [dis act-days cap boost matrix]
  let cap-index min (list ((length capacity-list) - 1) ceiling ((cap * mean-capacity - min-cap) / cap-step))
  if cap-index < 0 [set cap-index 0]
  ;let cap-table item cap-index spread-table

  let dis-index min (list ((length distance-list) - 1) (((dis - min-dis) / dis-step) - boost))
  if dis-index < 0 [set dis-index 0]
  ;let dis-list item dis-index cap-table
  let days-index ceiling ((act-days - min-days) / step-days)
  if days-index < 0 [set days-index 0]
  let chance array:item (array:item (array:item matrix cap-index) dis-index) days-index
  ;if boost > 0 [show (word "boost " boost ", dis " dis ", dis-index " dis-index ", chance " chance)]
  report chance
end

to-report get-interpolated-colon-prob [dis act-days cap boost matrix]
  let cap-index max (list 0 min (list ((length capacity-list) - 1) ((cap * mean-capacity - min-cap) / cap-step)))
  let cap-index-c max (list 1 min (list ((length capacity-list) - 1) ceiling ((cap * mean-capacity - min-cap) / cap-step)))
  let cap-index-f max (list 0 min (list ((length capacity-list) - 2) floor ((cap * mean-capacity - min-cap) / cap-step)))
  let ci cap-index - cap-index-f

  ;let cap-table item cap-index spread-table

  let dis-index max (list 0 min (list ((length distance-list) - 1) (((dis - min-dis) / dis-step) - boost)))
  let dis-index-c max (list 1 min (list ((length distance-list) - 1) ceiling (((dis - min-dis) / dis-step) - boost)))
  let dis-index-f max (list 0 min (list ((length distance-list) - 2) floor (((dis - min-dis) / dis-step) - boost)))
  let di dis-index - dis-index-f

  let days-index max (list 0 min (list ((length days-list) - 1) ((act-days - min-days) / step-days)))
  let days-index-c max (list 1 min (list ((length days-list) - 1) ceiling ((act-days - min-days) / step-days)))
  let days-index-f max (list 0 min (list ((length days-list) - 2) floor ((act-days - min-days) / step-days)))
  let ai days-index - days-index-f

  let chance-ccc array:item (array:item (array:item matrix cap-index-c) dis-index-c) days-index-c
  let chance-ccf array:item (array:item (array:item matrix cap-index-c) dis-index-c) days-index-f
  let chance-cfc array:item (array:item (array:item matrix cap-index-c) dis-index-f) days-index-c
  let chance-cff array:item (array:item (array:item matrix cap-index-c) dis-index-f) days-index-f

  let chance-fcc array:item (array:item (array:item matrix cap-index-f) dis-index-c) days-index-c
  let chance-fcf array:item (array:item (array:item matrix cap-index-f) dis-index-c) days-index-f
  let chance-ffc array:item (array:item (array:item matrix cap-index-f) dis-index-f) days-index-c
  let chance-fff array:item (array:item (array:item matrix cap-index-f) dis-index-f) days-index-f

  let c-fff chance-fff * (1 - ci) * (1 - di) * (1 - ai)
  let c-ffc chance-ffc * (1 - ci) * (1 - di) * ai
  let c-fcf chance-fcf * (1 - ci) * di * (1 - ai)
  let c-fcc chance-fcc * (1 - ci) * di * ai

  let c-cff chance-cff * ci * (1 - di) * (1 - ai)
  let c-cfc chance-cfc * ci * (1 - di) * ai
  let c-ccf chance-ccf * ci * di * (1 - ai)
  let c-ccc chance-ccc * ci * di * ai

  let chance  c-fff + c-ffc + c-fcf + c-fcc + c-cff + c-cfc + c-ccf + c-ccc

  ;if boost > 0 [show (word "boost " boost ", dis " dis ", dis-index " dis-index ", chance " chance)]
  report chance
end

to repair-exclusion
  set exclusion-fail? false
  set emitting? false
  set colonised? false
  set exclusion-fail-since -1
  update-color
end

to start-emitting
  set emitting? true
  set color green + 2
end

to update-color
  ifelse exclude? and not exclusion-fail? [
    ifelse light-theme? [ set color gray + 2 ]
    [ set color gray - 2 ]
  ]
  [
    set color grey + 1
    if wp-type = "Irrigation" [
      set color green
    ]
    if wp-type = "Natural" [
      set color blue + 1
    ]
    if wp-type = "Dwelling" [
      set color pink + 1
    ]
  ]
end

to exclude
  if mouse-down? [
    let p patch mouse-xcor mouse-ycor
    let mindis min [distancexy mouse-xcor mouse-ycor] of wps
    let target wps with [(distancexy mouse-xcor mouse-ycor) < size]
    ask target [
      if capacity > 0 [
        set exclude? true
        set color gray - 2
      ]
    ]
    stop
  ]
end

to generate-fence

;  if active-cloc = 16 and fence-position >[
;
;  ]
  let c cloc active-cloc

  let prev 0
  let next 0
  if active-cloc > 0 [
    set prev cloc (active-cloc - 1)
  ]
  if active-cloc < 16 [
    set next cloc (active-cloc + 1)
  ]
  create-fs 1 [
    set xcor [xcor] of c
    set ycor [ycor] of c
    set size 12
    let fpos [fence-position] of c
    ifelse fpos > 3 [
      ifelse next != 0 [
        face next
        fd ([distance next] of c) * (fpos - 3) / 5
      ] [
        face prev
        fd (- [distance prev] of c) * (fpos - 3) / 5
      ]
    ] [
      ifelse prev != 0 [
        face prev
        fd [distance prev] of c * (3 - fpos) / 5
      ]
      [
        face next
        fd (- [distance next] of c) * (3 - fpos) / 5
      ]
    ]
    right 90
    set color red
  ]
end

to fence-links
  let fe one-of fs
  let max-f-dis (max-dis / 50) + 1 + spread-boost / 2

  foreach [self] of links with [link-distance fe < max-f-dis] [ li ->
;    ask li [
;      set color red
;    ]
    create-turtles 1 [
      set size [link-length] of li
      set heading [link-heading] of li
      set xcor [link-xcor] of li
      set ycor [link-ycor] of li
      if (intersection self fe) != [] [
        ask li [
          ifelse light-theme? [set color red + 2] [set color red - 2]
          set fenced? true
        ]
      ]
      die
    ]
  ]
end

to-report intersection [t1 t2]
  let m1 [tan (90 - heading)] of t1
  let m2 [tan (90 - heading)] of t2
  ;; treat parallel/collinear lines as non-intersecting
  if m1 = m2 [ report [] ]
  ;; is t1 vertical? if so, swap the two turtles
  if abs m1 = tan 90
  [
    ifelse abs m2 = tan 90
      [ report [] ]
      [ report intersection t2 t1 ]
  ]
  ;; is t2 vertical? if so, handle specially
  if abs m2 = tan 90 [
     ;; represent t1 line in slope-intercept form (y=mx+c)
      let c1 [ycor - xcor * m1] of t1
      ;; t2 is vertical so we know x already
      let x [xcor] of t2
      ;; solve for y
      let y m1 * x + c1
      ;; check if intersection point lies on both segments
      if not [x-within? x] of t1 [ report [] ]
      if not [y-within? y] of t2 [ report [] ]
      report list x y
  ]
  ;; now handle the normal case where neither turtle is vertical;
  ;; start by representing lines in slope-intercept form (y=mx+c)
  let c1 [ycor - xcor * m1] of t1
  let c2 [ycor - xcor * m2] of t2
  ;; now solve for x
  let x (c2 - c1) / (m1 - m2)
  ;; check if intersection point lies on both segments
  if not [x-within? x] of t1 [ report [] ]
  if not [x-within? x] of t2 [ report [] ]
  report list x (m1 * x + c1)
end

to-report x-within? [x]  ;; turtle procedure
  report abs (xcor - x) <= abs (size / 2 * dx)
end

to-report y-within? [y]  ;; turtle procedure
  report abs (ycor - y) <= abs (size / 2 * dy)
end

to-report link-xcor
  report ([xcor] of end1 + [xcor] of end2) / 2
end

to-report link-ycor
  report ([ycor] of end1 + [ycor] of end2) / 2
end

to-report link-distance [t]
  let x link-xcor
  let y link-ycor
  report [distancexy x y] of t
end


to print-coordinate
  if mouse-down? [
    let p patch mouse-xcor mouse-ycor
    print (word mouse-xcor ", " mouse-ycor)
  ]
end

to colonise-on-click
  if mouse-down? [
    let p patch round mouse-xcor round mouse-ycor
    let min-d min [distancexy mouse-xcor mouse-ycor] of wps-on p
    let target one-of wps with [distancexy mouse-xcor mouse-ycor = min-d]
    ask target [
      if capacity > 0 [
        set colonised? true
        set colonised-since ticks - 1
        set emitting? true
        set color green + 2
      ]
    ]
    stop
  ]
end

to-report current-year
  report floor (ticks / 7)
end

to-report year [tiks]
  report floor ( tiks / 7 )
end

to colonise ;; wp procedure
  set colonised? true
  set colonised-since ticks
  set color red
end

;; connects the two wps
to make-edge [node] ;; wp procedure
  ask self [ create-link-with node  [
    set fenced? false
  ] ]
end
to reset-link-color
  ask links [
    ifelse light-theme? [ set color white - 0.5 ]
    [ set color black + 1 ]
    set thickness 0.1
  ]
end
to toggle-control-loc
  ask cloc active-cloc [
    set hidden? (not hidden?)
  ]
end

to toggle-all-control-loc
  ask clocs [
    set hidden? (not hidden?)
  ]
end

to-report region-colonised?
  report any? wps with [xcor < 8 and colonised?]
end

to-report mouse-info
  let p patch mouse-xcor mouse-ycor
  let mindis min [distancexy mouse-xcor mouse-ycor] of wps
  let target one-of wps with [(distancexy mouse-xcor mouse-ycor) = mindis]
  ;report (word "excluded? = " [pxcor] of p)
  report (word "excluded? = " [exclude?] of target
    "; water-capacity: " precision ([capacity] of target) 2
    "; colonised: " [colonised?] of target)
end
@#$#@#$#@
GRAPHICS-WINDOW
172
10
970
749
-1
-1
10.0
1
18
1
1
1
0
0
0
1
0
78
0
72
1
1
1
ticks
30.0

BUTTON
14
189
81
222
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
14
141
81
174
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
187
166
220
NIL
exclude
T
1
T
OBSERVER
NIL
E
NIL
NIL
1

BUTTON
92
141
167
174
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
240
135
273
NIL
colonise-on-click
T
1
T
OBSERVER
NIL
C
NIL
NIL
1

MONITOR
664
776
740
821
min distance
min [link-length] of links with [link-length > 0]
3
1
11

MONITOR
172
774
472
819
NIL
mouse-info
2
1
11

SWITCH
11
15
164
48
randomise-capacity?
randomise-capacity?
0
1
-1000

SLIDER
11
102
166
135
wet-year-interval
wet-year-interval
1
30
10.0
1
1
years
HORIZONTAL

SLIDER
11
281
161
314
exclusion-failure-prob
exclusion-failure-prob
0
0.2
0.05
0.01
1
NIL
HORIZONTAL

BUTTON
848
777
968
810
NIL
print-coordinate
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
20
374
158
419
active-cloc
active-cloc
0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
15

SLIDER
21
430
153
463
no-controlled-wp
no-controlled-wp
0
20
14.0
1
1
NIL
HORIZONTAL

BUTTON
23
602
151
635
NIL
toggle-control-loc
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
327
163
360
exclusion-repair-delay
exclusion-repair-delay
1
5
2.0
1
1
NIL
HORIZONTAL

CHOOSER
19
692
157
737
fence
fence
"none" "fence7" "fence30"
1

SLIDER
21
749
155
782
spread-boost
spread-boost
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
17
792
158
825
sim-duration
sim-duration
0
300
200.0
10
1
NIL
HORIZONTAL

MONITOR
485
776
564
821
max capacity
max [capacity] of wps with [wp-type != \"Irrigation\"]
2
1
11

MONITOR
574
776
655
821
min capacity
min [capacity] of wps with [wp-type != \"Irrigation\"]
2
1
11

BUTTON
1007
22
1136
55
NIL
load-spread-table
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
19
641
157
686
trap
trap
"none" "trap1" "trap2"
2

SWITCH
26
476
138
509
exclusion?
exclusion?
1
1
-1000

BUTTON
21
563
165
596
NIL
toggle-all-control-loc
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
1007
69
1131
102
light-theme?
light-theme?
0
1
-1000

SLIDER
12
57
165
90
wet-year-extra-days
wet-year-extra-days
0
28
14.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="excl" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;fence30&quot;"/>
      <value value="&quot;fence7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trap" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="14"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;trap1&quot;"/>
      <value value="&quot;trap2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence trap" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="14"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;fence30&quot;"/>
      <value value="&quot;fence7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;trap1&quot;"/>
      <value value="&quot;trap2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl fence" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;fence30&quot;"/>
      <value value="&quot;fence7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl trap" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;trap1&quot;"/>
      <value value="&quot;trap2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl rain" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="28"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="spread rain" repetitions="2000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="28"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl fence rain" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;fence7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="28"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="spread highcap" repetitions="2000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl highcap" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="excl trap highcap" repetitions="1000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>region-colonised?</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="3"/>
      <value value="4"/>
      <value value="10"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;trap2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="spread" repetitions="2000" runMetricsEveryStep="false">
    <setup>load-spread-table
setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="sim-duration">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomise-capacity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="active-cloc">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-controlled-wp">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-boost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-repair-delay">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exclusion-failure-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-interval">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wet-year-extra-days">
      <value value="14"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
