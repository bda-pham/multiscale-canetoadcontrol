globals
[
  epsilon
]

breed [toads toad]
breed [traps trap]
breed [waterpoints waterpoint]

patches-own
[
  is-fence?
  broken-since
]

toads-own
[
  age
  gender
  hydration

  speed
  angle-dev
  origin
]

traps-own
[
  capture
]

waterpoints-own
[
  established?
  colonised?
  colonised-since
  capacity
]

to setup
  clear-all
  reset-timer
  set-default-shape toads "frog top"
  set-default-shape waterpoints "circle"
  set-default-shape traps "square"
  resize-world 0 max-distance + 100 0 100
  set epsilon 0.05
  if show-grid? [ ask patches with [pxcor mod 50 = 0 or pycor mod 50 = 0] [set pcolor gray] ]

  ask patches [ set pcolor white ]

  if wp-distribution = "random" [
    ask one-of patches with [pxcor > max-pxcor - 50]
    [
      init-source-wp
    ]

    ask one-of patches with [pxcor < max-pxcor - 50]
    [
      init-dest-wp
    ]
  ]
  if wp-distribution = "series" [
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 2) [ init-source-wp ]

    ask patch ((max-pxcor - max-distance ) / 2) (max-pycor / 2) [ init-dest-wp ]

    ask patch (max-pxcor / 2) (max-pycor / 2) [ init-dest-wp ]
  ]
  if wp-distribution = "one-to-one" [
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 2) [ init-source-wp ]

    ask patch ((max-pxcor - max-distance ) / 2) (max-pycor / 2) [ init-dest-wp ]
  ]
  if wp-distribution = "two-to-one" [
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 2 + 5) [ init-source-wp ]
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 2 - 5) [ init-source-wp ]
    ask patch ((max-pxcor - max-distance ) / 2) (max-pycor / 2) [ init-dest-wp ]
  ]
  if wp-distribution = "three-to-one" [
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 3) [ init-source-wp ]
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor * 2 / 3) [ init-source-wp ]
    ask patch ((max-pxcor + max-distance ) / 2) (max-pycor / 2) [ init-source-wp ]
    ask patch ((max-pxcor - max-distance ) / 2) (max-pycor / 2) [ init-dest-wp ]
  ]
  if wp-distribution = "two-to-one-hor" [
    ask patch ((max-pxcor + max-distance ) / 2 + 10) (max-pycor / 2) [ init-source-wp ]
    ask patch ((max-pxcor + max-distance ) / 2 - 10) (max-pycor / 2) [ init-source-wp ]
    ask patch ((max-pxcor - max-distance ) / 2) (max-pycor / 2) [ init-dest-wp ]
  ]
  if wp-distribution = "one-source" [
    resize-world 0 100 0 100
    ask patches [ set pcolor white ]
    ask patch ((max-pxcor) / 2) ((max-pycor) / 2) [ init-source-wp ]
  ]

  let startcor (- trap-radius)
  let stopcor (trap-radius + 1 / trap-density)
  let step (1 / trap-density)
  let trapped-locations []
  if trap-mode = "source" [
    set trapped-locations [self] of waterpoints with [established?]
  ]

  if trap-mode = "destination" [
    set trapped-locations [self] of waterpoints with [not colonised?]
  ]
  if trap-mode = "both" [
    set trapped-locations [self] of waterpoints
  ]
  foreach (trapped-locations) [source ->
    foreach (range startcor stopcor step) [ x ->
      foreach (range startcor stopcor step) [ y ->
        create-traps 1 [
          set xcor x + [xcor] of source
          set ycor y + [ycor] of source
          set color red
          set capture 0
        ]
      ]
    ]
  ]

  ask patches [
    set is-fence? false
  ]
  if fence? [
    let fence-x ((max-pxcor - max-distance ) / 2) + fence-location * max-distance
    ask patches with [pxcor >= fence-x and pxcor < fence-x + fence-layers] [
      set is-fence? true
      set pcolor gray
      set broken-since -1
    ]
  ]
  reset-ticks
end

to init-source-wp
  sprout-waterpoints 1 [
    set color green
    set capacity 1
    set colonised? true
    set established? true
    set colonised-since -1
    set size 3.6
  ]

end

to init-dest-wp
  sprout-waterpoints 1 [
    set capacity 1
    set colonised? false
    set established? false
    set color [50 50 255 150]
    set size (2 * dest-radius)
  ]
end

to go
  ask toads
  [
    move
    grow
  ]
  ask patches with [is-fence?] [
    break-and-fix
  ]
  ask traps [
    if capture < trap-max-capacity [
      catch-toads
    ]
  ]
  if ticks mod trap-reset-interval = 0 [
    ask traps [
      set capture 0
    ]
  ]
  ask waterpoints [
    patch-check-colonise
    emit-colonisers
  ]
  tick
  if (ticks = max-days) or (wp-distribution != "one-source" and (count waterpoints with [not colonised?]) = 0) [stop]
end

to emit-colonisers
  let dist size
  if established? and ticks mod days-per-wave = 0 [
    let no-colonisers colonisers-perwave * capacity
    ask patch-here [
      sprout-toads no-colonisers [
        init-toad
        set origin (list xcor ycor)
      ]
    ]
  ]
end

to init-toad
  set size 2
  set pen-size 2
  if disperse-direction = "left" [ set heading 180 + random 180 ]
  if disperse-direction = "bottom-left" [ set heading 90 + random 270 ]
  if disperse-direction = "all" [ set heading random 360 ]
  if draw-path? [ pen-down ]
  ;set angle-dev max (list 0 random-normal mean-angle-dev (mean-angle-dev / 3 ))
  set angle-dev random-float (mean-angle-dev * 2)
  ;set angle-dev mean-angle-dev
;  while [angle-dev > 2 * mean-angle-dev]
;  [
;    set angle-dev max (list 0 random-normal mean-angle-dev (mean-angle-dev / 3 ))
;  ]
  ifelse random 2 = 0 [
    set gender 0
    set color green
  ]
  [
    set gender 1
    set color yellow
  ]

  set speed 0
  while [speed <= 0] [
    ifelse mode = "gender-same" [
      set speed random-normal 0.46 0.31
    ]
    [
      ifelse gender = 0 [
        set speed random-normal 0.46 0.31 ]
        ;set speed 0.46]
      [
        set speed random-normal 1.50 1.17 ]
    ]
  ]

  if cull-slow-toads? [
    let angle heading - 270
    if angle > 180 [ set angle angle - 360]
    if angle < -180 [ set angle angle + 360]

    let factor 1 + 0.5 * ( abs angle) / 180
    let min-speed (max-distance / (max-days - ticks))
    if speed < factor * min-speed [ die ]
  ]
  ;if colon-req = "two-any" and cull-slow-toads? and gender = 0 [ die ]
  if colon-req = "one-male" and gender = 1 [ die ]
end

to break-and-fix
  ifelse broken-since = -1
  [
    if random-float 1 < fence-break-chance [
      set broken-since ticks
      set pcolor gray + 3
    ]
  ]
  [
    if ticks mod fence-fix-interval = 0 [
      set broken-since -1
      set pcolor gray
    ]
  ]
end

to catch-toads ;; trap procedure
  let capture_count 0
  ask toads with [distance myself < capture-range] [
    if (gender = 0 and random-float 1 < male-capture-rate) or (gender = 1 and random-float 1 < female-capture-rate) [
      set capture_count (capture_count + 1)
      die
    ]
  ]
  set capture (capture + capture_count)
end

to patch-check-colonise ;; waterpoint procedure
  if not colonised? and capacity > 0
  [
    let males []
    let females []
    let radius size / 2
    ifelse radius <= 1 [
      set females (toads-on neighbors) with [ gender = 1 and epsilon > distance myself]
      set males (toads-on neighbors) with [ gender = 0 and epsilon > distance myself]
    ]
    [
      set females toads with [epsilon > distance myself and gender = 1]
      set males toads with [epsilon > distance myself and gender = 0]
    ]

    if (colon-req = "both-genders" and count males > 0 and count females > 0) or (colon-req = "two-any" and (count males + count females >= 2)) or (colon-req = "one-male" and (count males > 0))
    [
      set colonised? true
      set colonised-since ticks
      set color [255 50 50 150]
    ]
  ]
  if colonised? and not established? and ticks - colonised-since > 30
  [
  ]
end

to-report displacement ;; turtle procedure
  report distancexy (item 0 origin) (item 1 origin)
end

to-report meander
  ifelse age > 0 [
    report displacement / (speed * age)
  ] [ report 0 ]
end

to-report mean-meander
  report mean [ meander ] of toads with [gender = 0]
end

to-report dev-meander
  report standard-deviation [ meander ] of toads with [gender = 0]
end

to-report colonised-wp
  report count waterpoints with [colonised? and not established?]
end

to move  ;; toad procedure
  ifelse near-new-wp? and not at-new-wp? [
    let new-wp one-of (waterpoints with [not colonised? and size / 2 > distance myself ])
    face new-wp
    ifelse speed > distance new-wp [
      move-to new-wp
    ] [
      fd speed
    ]
  ]
  [
    if (not at-new-wp? or random-float 1 > habitat-daily-retention) [
      set heading random-normal heading angle-dev
      ifelse speed < 1 [
        fd speed
        if fence-blocked? and random-float 1 > fence-breach-chance [
          fd (- speed)
        ]
      ]
      [
        let dst speed
        while [dst > 1] [
          fd 1
          ifelse fence-blocked? and random-float 1 > fence-breach-chance [
            fd -1
            set dst 0
          ]
          [
            ifelse not at-new-wp? or random-float 1 > habitat-daily-retention
            [ set dst (dst - 1) ]
            [
              set dst 0
            ]
          ]
        ]

        fd dst
        if fence-blocked? and random-float 1 > fence-breach-chance [
          fd (- dst)
        ]
      ]
      if xcor < min-pxcor or xcor > max-pxcor or ycor < min-pycor or ycor > max-pycor [
        die
      ]
    ]
  ]
end

to-report near-new-wp?
  report any? (waterpoints with [not colonised? and size / 2 > distance myself ])
end

to-report at-new-wp?
  report any? (waterpoints with [not colonised? and epsilon > distance myself ])
end

to-report fence-blocked?
  report [is-fence? and broken-since = -1] of patch-here
end

to-report uncolonised-wp?
  report capacity > 0 and not colonised?
end

to-report mature?
  report age > 20
end

to grow
  set age (age + 1)
  ;set size min (list 2 (0.5 + age / 20))
end

to maybe-die
  if hydration <= 0 or random 200 < age or random 30 < (count toads-on patch-here - 1)
  [
    die
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1123
524
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
180
0
100
1
1
1
ticks
30.0

BUTTON
12
167
67
200
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
73
168
128
201
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

SLIDER
8
343
145
376
colonisers-perwave
colonisers-perwave
5
200
60.0
5
1
NIL
HORIZONTAL

CHOOSER
10
10
148
55
mode
mode
"gender-diff" "gender-same"
0

CHOOSER
10
63
148
108
wp-distribution
wp-distribution
"series" "one-to-one" "two-to-one" "three-to-one" "two-to-one-hor" "one-source"
1

SLIDER
10
297
140
330
max-distance
max-distance
0
300
80.0
10
1
NIL
HORIZONTAL

SLIDER
10
386
146
419
days-per-wave
days-per-wave
1
181
1.0
5
1
NIL
HORIZONTAL

MONITOR
9
731
104
776
mean meander
mean [ meander ] of toads with [gender = 0]
2
1
11

MONITOR
9
683
94
728
displacement
mean [ displacement ] of toads with [gender = 0]
17
1
11

SLIDER
12
212
134
245
mean-angle-dev
mean-angle-dev
0
30
20.0
1
1
NIL
HORIZONTAL

MONITOR
98
826
148
871
max meander
max [meander] of toads with [gender = 0]
2
1
11

MONITOR
8
635
58
680
min meander
min [meander] of toads with [gender = 0 and meander > 0]
2
1
11

SLIDER
12
255
169
288
habitat-daily-retention
habitat-daily-retention
0
1
1.0
0.05
1
NIL
HORIZONTAL

CHOOSER
11
114
130
159
disperse-direction
disperse-direction
"left" "bottom-left" "all"
2

SWITCH
9
429
125
462
show-grid?
show-grid?
1
1
-1000

SLIDER
9
470
164
503
max-days
max-days
50
200
160.0
1
1
NIL
HORIZONTAL

SWITCH
12
512
131
545
draw-path?
draw-path?
1
1
-1000

MONITOR
10
779
98
824
max meander
max [ meander ] of toads with [gender = 0]
2
1
11

MONITOR
10
826
93
871
min meander
min [ meander ] of toads with [gender = 0]
2
1
11

SWITCH
10
552
153
585
cull-slow-toads?
cull-slow-toads?
0
1
-1000

BUTTON
133
168
191
201
go-once
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

CHOOSER
9
589
147
634
colon-req
colon-req
"both-genders" "two-any" "one-male"
0

SLIDER
66
643
158
676
dest-radius
dest-radius
1
10
1.8
0.1
1
NIL
HORIZONTAL

CHOOSER
193
557
285
602
trap-mode
trap-mode
"source" "destination" "both" "none"
3

SLIDER
292
559
476
592
male-capture-rate
male-capture-rate
0
0.2
0.03
0.01
1
daily
HORIZONTAL

SLIDER
297
607
474
640
female-capture-rate
female-capture-rate
0
0.2
0.03
0.01
1
daily
HORIZONTAL

SLIDER
476
560
648
593
capture-range
capture-range
0.5
2
1.2
0.1
1
tile
HORIZONTAL

SLIDER
479
612
651
645
trap-density
trap-density
1
5
2.0
1
1
per tile
HORIZONTAL

SLIDER
479
653
651
686
trap-radius
trap-radius
1
3
1.0
1
1
NIL
HORIZONTAL

SWITCH
696
571
799
604
fence?
fence?
0
1
-1000

SLIDER
809
573
1045
606
fence-location
fence-location
0.05
0.95
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
810
617
982
650
fence-breach-chance
fence-breach-chance
0
0.2
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
811
665
983
698
fence-break-chance
fence-break-chance
0
0.05
0.01
0.001
1
NIL
HORIZONTAL

SLIDER
813
708
985
741
fence-fix-interval
fence-fix-interval
0
160
90.0
10
1
NIL
HORIZONTAL

SLIDER
481
698
653
731
trap-max-capacity
trap-max-capacity
0
30
30.0
1
1
NIL
HORIZONTAL

SLIDER
480
743
652
776
trap-reset-interval
trap-reset-interval
0
160
3.0
1
1
NIL
HORIZONTAL

SLIDER
699
621
802
654
fence-layers
fence-layers
1
2
1.0
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
  <experiment name="cap 5" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 10" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 20" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="72"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 40" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="82"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 80" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 160" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="103"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="traps source-dest male 80" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="traps source-dest female" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="traps source-dest male 100" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence location" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.1"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence fix interval" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="15"/>
      <value value="30"/>
      <value value="60"/>
      <value value="90"/>
      <value value="120"/>
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="emit pattern trap 60" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="emit pattern trap 600" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final 5" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final 2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all at once" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="800"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 30" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w trap both" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence trap dest" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 90" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 90 trap dest" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="dest radius" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1"/>
      <value value="5"/>
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
      <value value="20"/>
      <value value="24"/>
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 5 lh" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="53"/>
      <value value="54"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 10 lh" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="60"/>
      <value value="61"/>
      <value value="62"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 20 lh" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="84"/>
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 40 lh" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="74"/>
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 80 lh" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="81"/>
      <value value="82"/>
      <value value="83"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cap 160 lh" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="93"/>
      <value value="94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trap dest source" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 7" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence fix interval" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="fence fix interval break chance" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="7"/>
      <value value="30"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.001"/>
      <value value="0.002"/>
      <value value="0.003"/>
      <value value="0.005"/>
      <value value="0.007"/>
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.0075"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="gender req" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
      <value value="&quot;two-any&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.0075"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="angle dev" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="53"/>
    <metric>mean-meander</metric>
    <metric>dev-meander</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-source&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
      <value value="22"/>
      <value value="24"/>
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;one-male&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trap male" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trap female" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="trap dest source 6060" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
      <value value="&quot;source&quot;"/>
      <value value="&quot;destination&quot;"/>
      <value value="&quot;both&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="baseline 6060" repetitions="2000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w trap dest 1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.0075"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 30 trap dest 1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 30" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 7" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w trap dest 2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.0075"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 7 trap dest 1" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 7 trap dest 2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="final w fence 30 trap dest 2" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>colonised-wp</metric>
    <enumeratedValueSet variable="fence-location">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-max-capacity">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-days">
      <value value="160"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-breach-chance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-mode">
      <value value="&quot;destination&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
      <value value="120"/>
      <value value="140"/>
      <value value="160"/>
      <value value="180"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-density">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-grid?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="female-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-path?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-layers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;gender-diff&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wp-distribution">
      <value value="&quot;one-to-one&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-fix-interval">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="capture-range">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-angle-dev">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dest-radius">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-reset-interval">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-daily-retention">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colon-req">
      <value value="&quot;both-genders&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="disperse-direction">
      <value value="&quot;all&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisers-perwave">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cull-slow-toads?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="male-capture-rate">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fence-break-chance">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="days-per-wave">
      <value value="1"/>
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
