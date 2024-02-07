globals[
  shark-energy-gain    ; amount of energy a shark gains after eating
  fish-energy-gain     ; amount of energy a fish gains after eating
  initial-fish-energy  ; initial amount of energy fish start with upon spawning
  initial-shark-energy ; initial amount of energy sharks start with upon spawning

  movement-constant;

  max-fish             ; max number of fish we can have on the board
  shark-reproduction-chance ; chance for sharks to reproduce upon collision
]

fishes-own [energy move-distance max-energy
  health-status ;; for monitoring reproduction eligibility
  schoolmates
  nearest-neighbor birth-tick]
sharks-own [energy move-distance max-energy birth-tick]
patches-own [patch-growth-countdown algae-patch alive]

breed [fishes fish]
breed [sharks blahaj]
breed [foods food]
breed [algaes algae]
breed [jellyfishes jellyfish]
to setup
  clear-all
  reset-ticks

  set-default-shape fishes "fish"
  create-fishes initial-number-fishes [
    set size 0.8
    set max-energy fish-max-energy
    set health-status 50
    set energy (1 + random max-energy)
    set-energy-color 128
    setxy random-xcor random-ycor
    set schoolmates no-turtles
  ]

  set-default-shape sharks "shark"
  create-sharks initial-number-sharks [
    set size 1.5
    set max-energy shark-max-energy
    set energy (1 + random max-energy)
    set-energy-color 98
    setxy random-xcor random-ycor
    set shark-reproduction-chance predator-tick-reproduction-chance
    set birth-tick ticks
  ]

  set-default-shape algaes "plant"

  repeat initial-number-algae-patches
  [
    set-algae-patches (patch random-xcor random-ycor)
  ]

  set-default-shape jellyfishes "default"
  create-jellyfishes initial-number-jellyfish
  [
    set size 0.4
    setxy random-xcor random-ycor
    set color green
  ]

  ask patches [
    set pcolor 101
  ]

  ;reset-ticks
end

to go
  ; govern shark movement
  update-energy
  set movement-constant swim-stride
  ask sharks [
    set-direction
    if energy <  30 [
      ; Homing behavior for sharks when energy is below  50
      let closest-fish min-one-of fishes [distance myself]
      if closest-fish != nobody [
        face closest-fish
        fd movement-constant
      ]
    ]

    if birth-tick >= predator-age [
      if random-float 1.0 < 0.015 [
        die
      ]
    ]
  ]

  ask sharks [
    set birth-tick (birth-tick + 1)
    if (birth-tick > predator-reproduction-cycle and birth-tick mod predator-reproduction-cycle >= 0 and birth-tick mod predator-reproduction-cycle < predator-reproduction-period) and (energy >=  80) [
      let nearby-sharks sharks in-radius 12  ; Assuming a small enough radius to detect nearby sharks
      let has-reproduced? false  ; Flag to track if the shark has reproduced
      ask nearby-sharks [
        if self != myself [
          if random-float 1.0 < shark-reproduction-chance [
            hatch 1 [
              setxy ([xcor] of myself + random-float   2 -   1)
                    ([ycor] of myself + random-float   2 -   1)
              set energy (energy / 2)  ; Sharing energy equally between parent and offspring
              set max-energy max-energy
              set birth-tick 0  ; Set the birth-tick of the new shark to 0
            ]
            set energy (energy - 50)  ; Reduce energy of the parent shark
            set has-reproduced? true
          ]
        ]
      ]
      if has-reproduced? [stop]  ; Stop checking for reproduction if already reproduced
    ]
  ]

  hungry-predator?

  ask fishes [
    set birth-tick (birth-tick + 1)
    ifelse (not hungry-prey?) [
      school
    ] [
      hungry-prey-action
    ]
    if birth-tick >= prey-age [
      if random-float 1.0 < 0.02 [
        die
      ]
    ]
  ]

  repeat abs(1 / movement-constant) [
    move
  ]

  ask turtles [
    if breed = fishes or breed = sharks
    [
      set energy (energy - 1) ;; all entities lose 1 energy per tick
      die?
    ]

    if breed = fishes [
      set-health-status
      reproduce-prey?
    ]
  ]

  respawn-food?

  ;; copies how Flocking does it to make the animation look clean
  tick
end

;; Check if energy is at a certain threshold, this is supposed to make it so that schools don't starve each other


;; RESPAWNING FOOD
to set-algae-patches [target-patch]
  let algae-patches patches with [distance target-patch < algae-spawn-radius]
  ask algae-patches [
    set algae-patch true
    set alive true
    sprout-algaes 1
    [
      set color green
      set size 0.4
    ]
  ]
end


to respawn-food?
  ask patches with [algae-patch = true and alive = false]
  [
    ifelse patch-growth-countdown = 0
    [sprout-algaes 1
      [
        set color green
        set size 0.4
      ]
      set alive true
    ]
    [
      set patch-growth-countdown patch-growth-countdown - 1
    ]
  ]
end



;; EATING FOR PREY
to hungry-prey-action
  ;; 20 cone radius for the moment
  let food-in-view turtles with [breed = algaes or breed = jellyfishes] in-cone 20 fish-vision

  ;; face turtle to food in front of vision cone
  ifelse any? food-in-view [
    let closest-target min-one-of food-in-view [distance myself]
    face closest-target

    if any? (turtles-on patch-here) with [breed = algaes or breed = jellyfishes] [
      eat-prey
    ]
  ] [
    school
  ]
end

to-report hungry-prey?
  report energy <= (max-energy / 2)
end

to eat-prey
  ask min-one-of (turtles-on patch-here) with [breed = algaes or breed = jellyfishes] [distance myself]  [
    ask patch-here [
      set alive false
      set patch-growth-countdown food-respawn-time
    ]
    die
  ]
  set energy energy + energy-gain-prey
end

;; EATING FOR PREDATOR
to hungry-predator?
  ask sharks [
     if any? (turtles-on patch-here) with [breed = fishes] [
      if energy <= (max-energy / 2) [eat-predator]
    ]
  ]
end

to eat-predator
  ask min-one-of (turtles-on patch-here) with [breed = fishes] [distance myself] [die]
  set energy energy + energy-gain-predator
end

;; ENERGY MANAGEMENT
to die?
  if energy <= 0 [die]
end

to set-energy-color [ turtle-color ]
  let energy-ratio (energy / max-energy)
  let change-factor (-5) * (energy-ratio) + 5
  set color (turtle-color - abs(change-factor))
end

to update-energy
  ask sharks [ set-energy-color 98 ]
  ask fishes [ set-energy-color 128 ]
end


;; REPRODUCTION FOR PREY
to reproduce-prey?
  if ((birth-tick > prey-reproduction-cycle) and (birth-tick mod prey-reproduction-cycle > 0) and (birth-tick mod prey-reproduction-cycle <= prey-reproduction-period))[
    if(energy >= (max-energy / 2) and (health-status >= max-energy / 2) and random-chance-prey-reproduction?)[
      hatch 1 [
        setxy ([xcor] of myself + random-float 2 - 1)
              ([ycor] of myself + random-float 2 - 1)
        set birth-tick 0  ; Set the birth-tick of the new fish to 0
      ]
    ]
  ]
end

to set-health-status
  if (energy >= ( max-energy / 2 ) and (health-status < 100))[
    set health-status (health-status + 1)
  ]
  if (energy < ( max-energy / 2 ) and (health-status > 0))[
    set health-status (health-status - 3)
  ]
end

to-report random-chance-prey-reproduction?
  report random prey-mean-ticks-reproduction = 0
end

;; MOVEMENT

to set-direction
    let factor (- max-turning ) + (random max-turning * 2 + 1)
    set heading (heading + factor)
end

to move
  ask fishes [
    fd movement-constant
  ]

  ask sharks [
    fd movement-constant
  ]

    ask jellyfishes [
    set-direction
    fd movement-constant / 10
  ] display
end


;; SCHOOLS P MUCH A COPY OF FLOCKING

to school
  find-schoolmates
  if any? schoolmates
  [ find-nearest-neighbor
    ifelse distance nearest-neighbor < minimum-spread
    [ separate ]
    [ align
      cohere ] ]
end

to find-schoolmates
  set schoolmates other fishes in-radius fish-vision
end

to find-nearest-neighbor
  set nearest-neighbor min-one-of schoolmates [distance myself]
end

to separate
  turn-away ([heading] of nearest-neighbor) max-separate-turn
end

to align
  turn-towards average-schoolmate-heading max-align-turn
end

to-report average-schoolmate-heading  ;; turtle procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of schoolmates
  let y-component sum [dy] of schoolmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end


to cohere
  turn-towards average-heading-towards-schoolmates max-cohere-turn
end

to-report average-heading-towards-schoolmates  ;; turtle procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of schoolmates
  let y-component mean [cos (towards myself + 180)] of schoolmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end



;; HELPERS FROM FLOCKING

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end
@#$#@#$#@
GRAPHICS-WINDOW
401
10
942
552
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
30.0

SLIDER
18
291
190
324
initial-number-fishes
initial-number-fishes
1
150
99.0
1
1
NIL
HORIZONTAL

BUTTON
24
58
126
91
Setup
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

SLIDER
18
331
190
364
initial-number-sharks
initial-number-sharks
1
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
196
291
368
324
fish-max-energy
fish-max-energy
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
196
332
368
365
shark-max-energy
shark-max-energy
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
198
374
370
407
max-turning
max-turning
1
40
22.0
1
1
NIL
HORIZONTAL

BUTTON
254
58
357
91
Go
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
10
164
182
197
fish-vision
fish-vision
1
5
5.0
1
1
NIL
HORIZONTAL

SLIDER
19
375
191
408
swim-stride
swim-stride
0.1
2
0.2
0.1
1
NIL
HORIZONTAL

SLIDER
24
523
194
556
initial-number-jellyfish
initial-number-jellyfish
0
100
52.0
1
1
NIL
HORIZONTAL

SLIDER
201
522
374
555
initial-number-algae-patches
initial-number-algae-patches
1
20
16.0
1
1
NIL
HORIZONTAL

SLIDER
10
124
182
157
minimum-spread
minimum-spread
1
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
191
124
379
157
max-separate-turn
max-separate-turn
1
90
9.8
0.1
1
degrees
HORIZONTAL

SLIDER
188
201
380
234
max-align-turn
max-align-turn
1
90
29.0
0.10
1
degrees
HORIZONTAL

SLIDER
190
163
380
196
max-cohere-turn
max-cohere-turn
1
90
29.5
0.10
1
degrees
HORIZONTAL

TEXTBOX
144
97
297
115
Schooling Parameters
11
0.0
1

TEXTBOX
156
254
306
272
Setup Parameters\n
11
0.0
1

SLIDER
201
442
373
475
energy-gain-prey
energy-gain-prey
1
100
55.0
1
1
NIL
HORIZONTAL

SLIDER
201
482
373
515
energy-gain-predator
energy-gain-predator
1
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
24
482
193
515
algae-spawn-radius
algae-spawn-radius
1
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
24
442
193
475
food-respawn-time
food-respawn-time
10
100
40.0
1
1
ticks
HORIZONTAL

TEXTBOX
161
418
311
436
Food Parameters\n
11
0.0
1

PLOT
24
582
224
732
plot 1
time
population
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"fishes" 1.0 0 -4699768 true "" "plot count fishes"
"sharks" 1.0 0 -14985354 true "" "plot count sharks"

TEXTBOX
1003
101
1153
119
Reproduction Parameters
10
0.0
1

SLIDER
971
130
1150
163
prey-reproduction-cycle
prey-reproduction-cycle
150
1000
200.0
50
1
NIL
HORIZONTAL

SLIDER
971
171
1151
204
prey-reproduction-period
prey-reproduction-period
1
150
120.0
1
1
NIL
HORIZONTAL

SLIDER
971
212
1175
245
prey-mean-ticks-reproduction
prey-mean-ticks-reproduction
30
500
80.0
10
1
NIL
HORIZONTAL

SLIDER
1202
131
1403
164
predator-reproduction-cycle
predator-reproduction-cycle
200
1400
800.0
50
1
NIL
HORIZONTAL

SLIDER
1202
172
1405
205
predator-reproduction-period
predator-reproduction-period
100
450
300.0
10
1
NIL
HORIZONTAL

SLIDER
973
324
1145
357
prey-age
prey-age
100
800
400.0
50
1
NIL
HORIZONTAL

SLIDER
1206
324
1378
357
predator-age
predator-age
500
3000
1800.0
100
1
NIL
HORIZONTAL

SLIDER
1202
213
1446
246
predator-tick-reproduction-chance
predator-tick-reproduction-chance
0.0001
0.05
0.0032
0.0001
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
true
0
Polygon -1 true false 131 256 87 279 86 285 120 300 150 285 180 300 214 287 212 280 166 255
Polygon -1 true false 195 165 235 181 218 205 210 224 204 254 165 240
Polygon -1 true false 45 225 77 217 103 229 114 214 78 134 60 165
Polygon -7500403 true true 136 270 77 149 81 74 119 20 146 8 160 8 170 13 195 30 210 105 212 149 166 270
Circle -16777216 true false 106 55 30

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

shark
true
0
Polygon -7500403 true true 153 17 149 12 146 29 145 -1 138 0 119 53 107 110 117 196 133 246 134 261 99 290 112 291 142 281 175 291 185 290 158 260 154 231 164 236 161 220 156 214 160 168 164 91
Polygon -7500403 true true 161 101 166 148 164 163 154 131
Polygon -7500403 true true 108 112 83 128 74 140 76 144 97 141 112 147
Circle -16777216 true false 129 32 12
Line -16777216 false 134 78 150 78
Line -16777216 false 134 83 150 83
Line -16777216 false 134 88 150 88
Polygon -7500403 true true 125 222 118 238 130 237
Polygon -7500403 true true 157 179 161 195 156 199 152 194

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
