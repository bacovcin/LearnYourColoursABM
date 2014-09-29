globals [
 alphabet colnums initcolnames initcolvals learnernames learnervals deathmean nestcounts
]

turtles-own [
 colnames 
 colvals 
 numofcols 
 coldist 
 colevid 
 nest 
 age ; Age-Stage 0-40 Infant, 41-80 Child, 81-100 Young Adult, 101-140 Adult, 141- Elder
]

patches-own [colourvalue]

to setup
  clear-all
  set alphabet ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"] 
  set colnums n-values 100 [? + 20]
   ;[0 1 2 3 4 5 6 7 8 9 10 
   ; 11 12 13 14 15 16 17 18 19 20 
   ; 21 22 23 24 25 26 27 28 29 30 
   ; 31 32 33 34 35 36 37 38 39 40 
   ; 41 42 43 44 45 46 47 48 49 50 
   ; 51 52 53 54 55 56 57 58 59 60
   ; 61 62 63 64 65 66 67 68 69 70
   ; 71 72 73 74 75 76 77 78 79 80
   ; 81 82 83 84 85 86 87 88 89 90
   ; 91 92 93 94 95 96 97 98 99 100
   ; 101 102 103 104 105 106 107 108 109 110
   ; 111 112 113 114 115 116 117 118 119 120
   ; 121 122 123 124 125 126 127 128 129 130
   ; 131 132 133 134 135 136 137 138 139] 
  ask patches [colourpatch]
  ask n-of (count patches / 16) patches [splash] 
  initnamecols
  show initcolnames
  show initcolvals
  ask n-of numberofnests patches 
  [
    sprout 50 / numberofnests
    [
      setupturtles
      move-to one-of patches in-radius maxnestdistance
      set color 9.9 
    ]
  ]
  set deathmean 140
  set-plot-y-range 0 100
  runplot
  reset-ticks
end

to runplot
  set-current-plot "Number of Colours"
  set-plot-x-range 0 initnumofcols + 2
  histogram [length colnames] of turtles  
  set-current-plot "Colour"
  set-plot-y-range 0 100
  set-histogram-num-bars 140
  histogram [getcolour plotcolnum] of turtles  
  ask turtles 
  [
    set shape "triangle"
    set color white
    let colval getcolour plotcolnum
    ifelse colval >= 0
    [
      set color scale-color red colval 0 139
    ]
    [
      set shape "circle"
    ]
  ]
  ifelse seebackgroundcolour
  [ask patches [set pcolor colourvalue]]
  [ask patches [set pcolor blue]]
  let full-nests [nest] of turtles
  let nest-types []
  foreach full-nests
  [
    if member? ? nest-types = false
    [
      set nest-types lput ? nest-types
    ]
  ]
  set nestcounts length nest-types
end

to colourpatch
  ifelse randomcolour
  [ set colourvalue random 139]
  [ set colourvalue ((((int ((abs pxcor) / 3) * 10) +  int ((abs pycor))) + 10) - random 20)]
end

to splash
  let newcolor random 120 + 20
  ask n-of 4 neighbors [set colourvalue newcolor - random 20]
end

to initnamecols
  set initcolnames n-of initnumofcols alphabet
  set initcolvals n-of initnumofcols colnums
end

to setupturtles
  set age random 140
  ifelse age <= 40
  [
    set age 0
    setuplistenercols
  ]
  [
    setupspeakercols
  ]
end

to setupspeakercols
  set colnames initcolnames
  set colvals initcolvals
  set colevid n-of initnumofcols n-values 26 [1000]
  set nest patch-here
end

to setuplistenercols
  set colnames []
  set colvals []
  set colevid []
  set nest patch-here
end

to go
  ask turtles [move givebirth? signal set age age + 1 die?]
  tick-advance 1
  runplot
  cull
end

to cull
  if count turtles > 600 and deathmean > 100
  [
    set deathmean (deathmean - 10)
  ]
  if count turtles < 50 and deathmean < 250
  [
    set deathmean (deathmean + 10)
  ]
end

to move
  fd 1
  ifelse UseNests? 
  [
    if age > 80 and age <= 100
    [
      if count turtles-on neighbors < populationdensity * 1.5 and random-float 1 <= wanderrate
      [
        face nest
        right 180
        let newpatch patch-ahead ((2 * maxnestdistance) + random maxnestdistance)
        if count turtles-on newpatch = 0 [set nest newpatch]
      ]
    ]
    ifelse distance nest > maxnestdistance 
    [face nest fd 5]
    [right random-float 360]
  ]
  [
    right random-float 360
  ]
end

to givebirth?
  if age > 80 and age <= 140
  [
    if count turtles-on neighbors < populationdensity
    [
      let mynest nest
      hatch random populationdensity [set age 0 setuplistenercols set nest mynest]
    ]
  ]
end

to signal
  if age > 40 and length colvals > 0
  [
    set coldist []
    foreach colvals [set coldist lput (abs (? - colourvalue)) coldist]
    let colname item position min coldist coldist colnames
    let colval colourvalue
    ask turtles in-radius signalradius [learn colval colname]
  ]
end
  
to learn [colval colname]
  ifelse member? colname colnames
  [
    let itempos (position colname colnames)
    set colevid replace-item itempos colevid ((item itempos colevid) + 0.01)
    let curevid item itempos colevid
    let evidnum mean (list curevid age) / 10
    if evidnum <= 1 [set evidnum 1.01]
    if evidnum >= 100 [set evidnum 100]
    set coldist []
    foreach colvals [set coldist lput (abs (? - colval)) coldist]
    if position min coldist coldist != itempos [
      let changeamount ((item itempos coldist) / evidnum)
      ifelse colval < item itempos colvals [ 
        let newdist []
        foreach colvals [
          ifelse ? - item itempos colvals < 0 [
            set newdist lput abs (? - item itempos colvals) newdist
          ]
          [
            set newdist lput 1000 newdist
          ]
        ]
        let newpos position min newdist newdist
        ifelse item newpos colvals = min colvals
        [
          ifelse (item newpos colvals - changeamount) >= 0
          [
            set colvals replace-item newpos colvals (item newpos colvals - changeamount)   
          ]
          [
            set colvals replace-item newpos colvals (item newpos colvals / 2)   
          ]
          set colvals replace-item itempos colvals (item itempos colvals - changeamount)
        ]
        [
          set colvals replace-item itempos colvals (item itempos colvals - changeamount)
          ifelse (item newpos colvals - changeamount / 2) >= 0
          [
            set colvals replace-item newpos colvals (item newpos colvals - changeamount / 2)   
          ]
          [
            set colvals replace-item newpos colvals 0
          ]
        ]

      ]
      [
        let newdist []
        foreach colvals [
          ifelse ? - item itempos colvals > 0 [
            set newdist lput abs (? - item itempos colvals) newdist
          ]
          [
            set newdist lput 1000 newdist
          ]
        ]
        let newpos position min newdist newdist
        ifelse item newpos colvals = max colvals
        [
          ifelse (item newpos colvals + changeamount) <= 139
          [
            set colvals replace-item newpos colvals (item newpos colvals + changeamount)   
          ]
          [
            set colvals replace-item newpos colvals (item newpos colvals + ((139 - item newpos colvals) / 2))
          ]
          set colvals replace-item itempos colvals (item itempos colvals + changeamount)
        ]
        [
          set colvals replace-item itempos colvals (item itempos colvals + changeamount)
          ifelse (item newpos colvals + changeamount / 2) <= 139
          [
            set colvals replace-item newpos colvals (item newpos colvals + changeamount / 2)   
          ]
          [
            set colvals replace-item newpos colvals 139
          ]
        ]
      ]
    ]
  ]
  [
    set colnames lput colname colnames
    set colvals lput colval colvals
    set colevid lput 1 colevid 
  ]
end

to die?
  let deathnum random-normal deathmean 20
  if deathnum <= age
  [
    die
  ]
  if age > 250
  [
    let mynest nest
    hatch 1 [set age 0 setuplistenercols set nest mynest]
    die
  ]
end

to-report getcolour [colnum]
  let colname item colnum initcolnames
  ifelse member? colname colnames
  [
    report item position colname colnames colvals
  ]
  [
    report -10
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
525
10
1205
451
33
20
10.0
1
10
1
1
1
0
1
1
1
-33
33
-20
20
1
1
1
ticks
30.0

BUTTON
11
20
75
53
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

BUTTON
7
71
84
104
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

BUTTON
10
126
73
159
go
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
117
20
289
53
initnumofcols
initnumofcols
2
10
10
1
1
NIL
HORIZONTAL

SLIDER
118
66
290
99
maxticks
maxticks
10
1000
1000
1
1
NIL
HORIZONTAL

SLIDER
118
121
290
154
maxnestdistance
maxnestdistance
2
20
3
1
1
NIL
HORIZONTAL

SWITCH
176
169
289
202
UseNests?
UseNests?
0
1
-1000

SLIDER
325
23
497
56
populationdensity
populationdensity
2
48
4
1
1
NIL
HORIZONTAL

SLIDER
325
74
497
107
wanderrate
wanderrate
0.001
0.01
0.0010
0.001
1
NIL
HORIZONTAL

SLIDER
327
120
499
153
signalradius
signalradius
1
5
3
1
1
NIL
HORIZONTAL

SLIDER
329
167
501
200
numberofnests
numberofnests
1
5
5
1
1
NIL
HORIZONTAL

MONITOR
374
222
456
267
Turtle Count
count turtles
17
1
11

MONITOR
248
223
368
268
Mean Age of Death
deathmean
17
1
11

PLOT
9
278
209
428
Colour
NIL
NIL
0.0
139.0
0.0
10.0
true
false
"set-histogram-num-bars 139" ""
PENS
"default" 1.0 0 -16777216 true "" ""

SLIDER
11
441
183
474
plotcolnum
plotcolnum
0
initnumofcols - 1
0
1
1
NIL
HORIZONTAL

BUTTON
15
236
78
269
plot
runplot
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
209
441
382
474
seebackgroundcolour
seebackgroundcolour
1
1
-1000

MONITOR
105
224
209
269
Lack Colour Num
count turtles with [getcolour plotcolnum < 0]
17
1
11

PLOT
247
280
447
430
Number of Colours
NIL
NIL
0.0
11.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

SWITCH
10
168
141
201
randomcolour
randomcolour
0
1
-1000

MONITOR
416
447
490
492
NIL
nestcounts
17
1
11

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
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <exitCondition>ticks &gt; maxticks</exitCondition>
    <metric>[nest] of turtles</metric>
    <metric>[getcolour 0] of turtles</metric>
    <metric>[getcolour 1] of turtles</metric>
    <metric>[getcolour 0] of turtles</metric>
    <metric>[getcolour 1] of turtles</metric>
    <metric>[getcolour 0] of turtles</metric>
    <metric>[getcolour 1] of turtles</metric>
    <enumeratedValueSet variable="numberofnests">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
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
