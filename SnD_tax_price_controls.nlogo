extensions [csv]
turtles-own [surplus reservation-price item?]
breed [sellers seller]
breed [buyers buyer]
globals [ price-history history tax-revenue ]

;;;;;;;;;;;
;; Notes ;;
;;;;;;;;;;;

;I'm currently building in taxes. This has caused problems.
;It's harder to let the price be the mid-point between buyers and sellers
;so I'm just taking the seller's reservation price as the price and adding taxes on top.
;I think I'm handling subsidies correctly, but my efficiency values for taxes seem off.
;I've made a bit of a mess here, so I'm glad I pushed to github before I started tinkering.

to setup
  clear-all
  create-sellers n-sellers [
    set reservation-price random-float 100 + 1 ; no zero-value sellers (makes drawing the supply curve easier)
    set color red
    set item? true
  ]
  create-buyers n-buyers [
    set reservation-price random-float 100 + 1 ; no zero-value buyers (makes drawing the demand curve easier)
    set color blue
    set item? false
  ]
  ask turtles [
    set surplus 0
    draw-graph
    set size 3
  ]
  set history (list "price" "buyer" "seller")
  set price-history (list equilibrium-price) ; placeholder value to make plotting easier
  reset-ticks
end

to draw-graph
  let demand-schedule reverse sort ([reservation-price] of buyers) ; sort prices from highest to lowest
  let ld length demand-schedule
  let supply-schedule sort ([reservation-price] of sellers) ; sort prices from lowest to highest
  let ls length supply-schedule
  ask buyers [
    set ycor reservation-price
    set xcor (rank reservation-price demand-schedule / max list ld ls) * 100
  ]
  ask sellers [
    set ycor reservation-price
    set xcor (rank reservation-price supply-schedule / max list ld ls) * 100
  ]
end

to go
  ; stopping condition
  if not good-trades? [
    stop
  ]
  ask buyers with [not item?] [try-to-buy] ; if you don't have the item, try to buy it
  draw-graph
  tick
end

to try-to-buy
  let partners n-of seller-pool other turtles with [item?] ; shop around
  ask partners [
    move-to myself ; move here to make visualization easier
    fd 1
  ]
  let partner min-one-of partners [reservation-price]
  let price [reservation-price] of partner ; consumers extract most of the surplus, but that will make it easier to add taxes to the model.
  if price-controls? = "ceiling" [
    set price min list price price-ceiling
  ]
  if price-controls? = "floor" [
    set price max list price price-floor
  ]
  if reservation-price < price + tax [
    stop
  ] ; don't buy if the price is too high
  if [reservation-price] of partner > price [
    stop
  ] ; don't let suppliers sell if the price isn't high enough
  buy-at (price + tax)
  ask partner [ sell-at price ]
  set history lput (list price self partner) history ; gather data
  set price-history lput price price-history ; specifically price data
  set tax-revenue tax-revenue + tax
end

to buy-at [price]
  set surplus surplus + (reservation-price - price);
  set color grey
  set size 1
  set item? true
end

to sell-at [price]
  if breed = sellers [
    set surplus surplus + (price - reservation-price)
    set color grey
    set size 1
    set item? false
  ]
  if breed = buyers [
    set color blue
    set surplus surplus + (price - reservation-price)
    set size 5
    set item? false
  ]
end


to-report equilibrium-price
  let demand-schedule reverse sort [reservation-price] of buyers ; descending order of benefits
  let supply-schedule sort [reservation-price] of sellers ; ascending order of costs
  if first demand-schedule < first supply-schedule [ report false ]
  let p 0
  while [first demand-schedule > first supply-schedule] [ ; if there's a trade to make...
    set p mean (list first demand-schedule first supply-schedule) ; make a price
    set demand-schedule but-first demand-schedule ; move down the demand curve
    set supply-schedule but-first supply-schedule ; and up the supply curve
  ]
  report p
end

to-report equilibrium-quantity
  report count buyers with [reservation-price >= equilibrium-price]
end

to-report max-surplus
  let B buyers with [reservation-price > equilibrium-price]
  let S sellers with [reservation-price < equilibrium-price]
  report (sum [reservation-price] of B) - (sum [reservation-price] of S)
end

to-report rank [ x sorted-list ]
  if not member? x sorted-list [
    report 0 ; item not in list
  ]
  report position x sorted-list
end

to-report efficiency
  report (tax-revenue + sum [surplus] of turtles) / max-surplus
end

to-report good-trades?
  let low-ask min [reservation-price] of turtles with [ item? ]
  let high-bid max [reservation-price] of turtles with [ not item? ]
  if not (low-ask + tax < high-bid) [
    report false
  ]
  if price-controls? = "ceiling" [
    if price-ceiling < low-ask [
      report false
    ]
  ]
  if price-controls? = "floor" [
    if price-floor > high-bid [
      report false
    ]
  ]
  report true
end

;; Copyright Rick Weber, 2020
@#$#@#$#@
GRAPHICS-WINDOW
210
10
723
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
100
0
100
0
0
1
ticks
30.0

BUTTON
42
44
115
77
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
52
112
115
145
NIL
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

MONITOR
274
535
495
580
NIL
count turtles with [color = grey]
17
1
11

PLOT
770
58
1237
431
Reservation prices of remaining agents
reservation price
frequency
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"Buyers' values" 5.0 1 -13345367 true "" "histogram [round reservation-price] of buyers with [color = blue]"
"Sellers' values" 5.0 1 -2674135 true "" "histogram [round reservation-price] of sellers with [color = red]"

BUTTON
52
178
199
211
NIL
repeat 10 [ go ]
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
59
260
122
293
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

MONITOR
21
537
263
582
Last exchange
last price-history
17
1
11

MONITOR
38
318
165
363
NIL
max price-history
17
1
11

MONITOR
41
392
165
437
NIL
min price-history
17
1
11

MONITOR
42
465
178
510
NIL
mean price-history
17
1
11

PLOT
514
547
714
697
Average price
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean price-history"
"pen-1" 1.0 0 -7500403 true "" "plot last price-history"

SLIDER
794
469
966
502
n-buyers
n-buyers
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
803
528
975
561
n-sellers
n-sellers
10
500
100.0
1
1
NIL
HORIZONTAL

MONITOR
274
596
402
641
remaining buyers
count turtles with [ color = blue ]
17
1
11

MONITOR
275
654
403
699
remaining sellers
count turtles with [color = red]
17
1
11

MONITOR
30
604
130
649
Minimum ask
min [reservation-price] of sellers with [color = red]
17
1
11

MONITOR
31
664
131
709
Maximum bid
max [reservation-price] of buyers with [color = blue]
17
1
11

MONITOR
776
598
876
643
Total surplus
sum [surplus] of turtles
17
1
11

MONITOR
885
599
1033
644
Consumers' Surplus
sum [surplus] of buyers
17
1
11

MONITOR
781
660
920
705
Producers' Surplus
sum [surplus] of sellers
17
1
11

MONITOR
31
726
154
771
NIL
equilibrium-price
17
1
11

MONITOR
202
736
344
781
NIL
equilibrium-quantity
17
1
11

MONITOR
987
668
1082
713
NIL
max-surplus
17
1
11

MONITOR
803
743
877
788
efficiency
efficiency
6
1
11

SLIDER
998
466
1170
499
seller-pool
seller-pool
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
998
536
1170
569
tax
tax
-50
50
0.0
5
1
NIL
HORIZONTAL

SLIDER
1291
242
1463
275
price-ceiling
price-ceiling
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
1296
303
1468
336
price-floor
price-floor
0
100
70.0
1
1
NIL
HORIZONTAL

CHOOSER
1293
365
1431
410
price-controls?
price-controls?
"ceiling" "floor" "free"
0

@#$#@#$#@
## WHAT IS IT?

This is a model of Supply and Demand incorporating taxes (or subsidies) and price controls. 

## HOW IT WORKS

Buyers start with some expected value from purchasing "the item" held in the `reservation-price` variable. Sellers start with analogous cost (also held in `reservation-price`) and have the variable `item?` set to _true`.

Buyers look to buy at a price below their reservation price while sellers look to sell at a price higher than their reservation price. 

Buyers randomly select some agents with an item to sell ('with [item? = true]') and then select the agent with the lowest reservation price. If that reservation price is lower than the buyers' they make the exchange at a price half way between each of their reservation prices. 

Buyers who successfully purchase the good can resell if another buyer is willing to pay them more than their reservation price.

## HOW TO USE IT

You can adjust the number of buyers and sellers. You can also adjust the number of sellers approached each time a buyer tries to buy the item.

Otherwise, just hit the `setup` button followed by the `go` button.

## THINGS TO NOTICE

Agents are working without perfect information, and rationality is limited to avoiding exchanges that reduce an agent's surplus value. Also, outcomes are highly efficient, even when buyers are buying from a small pool of sellers. 

## THINGS TO TRY

Try playing with the seller-pool variable. Observe what happens to the efficiency level and the number of ticks it takes for the model to stop ("market clearing"). Try using the observer to manually override the size of the seller-pool. Does it matter much if a buyer approaches every single seller rather than just a few? 

Look at the turtles. Which turtles sell and which buy? How does this change when we set seller-pool to a very low number?

## EXTENDING THE MODEL

Currently each agent can buy or sell one unit. In effect, the agents are really modeling the marginal uses and sources. A 'buyer' is really _some_ person buying for one particular use. We could imagine multiple buyer turtles representing the purchase of various units of "the item" for specific uses. Analogously, the seller agents are essentially representing a single source of "the item" to be tapped independently of any consideration beyond an agreeable price. This simplifies implementation, but prevents modeling imperfectly competetive behavior. 

## NETLOGO FEATURES

The rank reporter might be of use in other models. 

## RELATED MODELS

I'm not aware of any at this time.

## CREDITS AND REFERENCES

This model was built by Rick Weber of Patchogue, Long Island, NY. I'm assuming this model is only really of use for educational purposes which is certainly fair use. If you think you've got a way to make money off this model, please let me know; I'd love for this to be useful, but I'd also like a cut!
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
NetLogo 6.1.1
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
