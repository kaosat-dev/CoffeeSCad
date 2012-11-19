define (require)->
  csg = require 'csg'
  
  class InvoluteGear
    
    constructor:(@numTeeth, @circularPitch, @pressureAngle, @clearance, @thickness)->
      
      
    render:()=>
      numTeeth= @numTeeth
      circularPitch= @circularPitch
      pressureAngle= @pressureAngle 
      clearance =  @clearance
      thickness= @thickness 
      console.log "gear render1"
      
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
      
      console.log "gear render2"
      #build a single 2d tooth in the 'points' array:
      resolution = 5
      points = [new CSG.Vector2D(0,0)]
      for i in [0...resolution]
        #first side of the tooth:
        angle = maxangle * i / resolution
        tanlength = angle * baseRadius
        radvector = CSG.Vector2D.fromAngle(angle)    
        tanvector = radvector.normal()
        p = radvector.times(baseRadius).plus(tanvector.times(tanlength))
        points[i+1] = p
        
        #opposite side of the tooth:
        radvector = CSG.Vector2D.fromAngle(angularToothWidthAtBase - angle)    
        tanvector = radvector.normal().negated()
        p = radvector.times(baseRadius).plus(tanvector.times(tanlength))
        points[2 * resolution + 2 - i] = p
    
      console.log "gear render3"
      #create the polygon and extrude into 3D:
      tooth3d = new CSG.Polygon2D(points).extrude({offset: [0, 0, thickness]})
    
      allteeth = new CSG()
      for i in [0..numTeeth]
        angle = i*360/numTeeth
        rotatedtooth = tooth3d.rotateZ(angle)
        allteeth = allteeth.unionForNonIntersecting(rotatedtooth)
    
      #build the root circle:  
      points = []
      toothAngle = 2 * Math.PI / numTeeth
      toothCenterAngle = 0.5 * angularToothWidthAtBase 
      for i in [0..numTeeth]
        angle = toothCenterAngle + i * toothAngle
        p = CSG.Vector2D.fromAngle(angle).times(rootRadius)
        points.push(p)
      console.log "gear render4"
      
      #create the polygon and extrude into 3D:
      #debugger 
      rootcircle = new CSG.Polygon2D(points)
      console.log "gear render5"
      console.log rootcircle
      
      rootcircle = CAG.circle({center: [0, 0], radius: 4, resolution: 20});
      rootcircle = rootcircle.extrude
        offset: [0, 0, 10]
      
      ###
      rootcircle = rootcircle.extrude
        offset: [0, 0, 10]
      console.log "gear render6"
      ###
      
      result = result = rootcircle.union(allteeth)
      #center at origin:
      result = result.translate([0, 0, -thickness/2])
      console.log "gear render LAST"
      return result
  
  gear = new InvoluteGear(10,5,20,0,5)
  gearCSG = gear.render()
  console.log gearCSG
  return gearCSG