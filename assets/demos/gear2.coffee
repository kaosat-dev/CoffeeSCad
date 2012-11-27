involuteGear=(numTeeth, circularPitch, pressureAngle, clearance, thickness)->
  # default values:
  ###
  if(arguments.length < 3) then pressureAngle = 20
  if(arguments.length < 4) then clearance = 0
  if(arguments.length < 4) then thickness = 1
  ###
  
  addendum = circularPitch / Math.PI
  dedendum = addendum + clearance
  
  #radiuses of the 4 circles:
  pitchRadius = numTeeth * circularPitch / (2 * Math.PI)
  baseRadius = pitchRadius * Math.cos(Math.PI * pressureAngle / 180)
  outerRadius = pitchRadius + addendum
  rootRadius = pitchRadius - dedendum

  maxtanlength = Math.sqrt(outerRadius*outerRadius - baseRadius*baseRadius)
  maxangle = maxtanlength / baseRadius

  tl_at_pitchcircle = Math.sqrt(pitchRadius*pitchRadius - baseRadius*baseRadius)
  angle_at_pitchcircle = tl_at_pitchcircle / baseRadius
  diffangle = angle_at_pitchcircle - Math.atan(angle_at_pitchcircle)
  angularToothWidthAtBase = Math.PI / numTeeth + 2*diffangle
  
  #build a single 2d tooth in the 'points' array:
  resolution = 5
  points = [new CSG.Vector2D(0,0)]
  for i in [0..resolution]
    # first side of the tooth:
    console.log "i: "+i
    angle = maxangle * i / resolution
    tanlength = angle * baseRadius
    radvector = CSG.Vector2D.fromAngle(angle)
    tanvector = radvector.normal()
    console.log "radvector: "+radvector
    p = radvector.times(baseRadius).plus(tanvector.times(tanlength))
    points[i+1] = p
    console.log "p1: "+p
     
    # opposite side of the tooth:
    radvector = CSG.Vector2D.fromAngle(angularToothWidthAtBase - angle)
    tanvector = radvector.normal().negated()
    p = radvector.times(baseRadius).plus(tanvector.times(tanlength))
    console.log "p2: "+p
    points[2 * resolution + 2 - i] = p
  console.log(points)
    
  # create the polygon and extrude into 3D:
  #tooth3d = new CSG.Polygon2D(points).extrude({offset: [0, 0, thickness]})
  tooth3d = fromPoints(points)
  tooth3d = tooth3d.extrude
    offset: [0, 0, thickness]
  allteeth = new CSG()
  for i in [0..numTeeth]
    angle = i*360/numTeeth
    rotatedtooth = tooth3d.rotateZ(angle)
    allteeth = allteeth.unionForNonIntersecting(rotatedtooth)
  
  # build the root circle:
  points = []
  toothAngle = 2 * Math.PI / numTeeth
  toothCenterAngle = 0.5 * angularToothWidthAtBase
  for i in [0...numTeeth]
    angle = toothCenterAngle + i * toothAngle
    p = CSG.Vector2D.fromAngle(angle).times(rootRadius)
    points.push(p)

  # build the root circle:  
  points = []
  toothAngle = 2 * Math.PI / numTeeth
  toothCenterAngle = 0.5 * angularToothWidthAtBase
  i = 0

  while i < numTeeth
    angle = toothCenterAngle + i * toothAngle
    p = CSG.Vector2D.fromAngle(angle).times(rootRadius)
    points.push p
    i++
  
 # create the polygon and extrude into 3D:
  rootcircle = new CSG.Polygon2D(points).extrude(offset: [0, 0, thickness])
  result = rootcircle.union(allteeth)
  console.log "toto7"
  # center at origin:
  result = result.translate([0, 0, -thickness / 2])
  result

tmp =involuteGear(10,5,0,5,5)
console.log tmp
return tmp