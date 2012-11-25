define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  require 'csg' 
  
  ###here we define various shorthands, wrappers etc for the base csg.js syntax,
  all in the mindset of "simple, clearer better"
  Some of these can eventually be migrated into csg.js as modified /added methods
  and classes .
  ###
  
  
  
  ###experimenting
        
      class Cylinder 
        constructor:(start=[0, -1, 0],end=[0, 1, 0],radius=1,radiusEnd=1,radiusStart=1)->
          return CSG.cylinder
            start:start
            end:end
            radius:radius
            radiusEnd:radiusEnd
            radiusStart:radiusStart
  ###
  
  ###CSG
  Cube = CSG.cube
  Sphere = CSG.Sphere
  Cylinder = CSG.cylinder
  roundedCylinder = CSG.roundedCylinder
  roundedCube = CSG.roundedCube
  ###
  
  ###CAG
  fromPoints= CAG.fromPoints
  Circle= CAG.circle
  Rectangle = CAG.rectangle
  roundedRectangle = CAG.roundedRectangle
  ###
  
  Cylinder= """(options)=>
    if "size" of options
      console.log "tutu"
    return CSG.cylinder options"""
  
  
  
  csgSugar = ""
  #csgSugar += "Cube = CSG.cube\n"
  csgSugar += """Cube=(options)=> 
    if "size" of options
      options.radius = options.size.map (comp) -> comp/2
    if "$fn" of options
      options.resolution = options.$fn
    if "r" of options
      options.roundradius = options.r
    if "d" of options
      options.roundradius = options.d/2
    if "center" of options
      if options.center == true
        options.center= [0,0,0]
    else
      if options.roundradius?
        result = CSG.roundedCube options
      else
        result = CSG.cube options
      result = result.translate([options.radius[0],options.radius[1],options.radius[2]])
    if not result?
      if options.roundradius? 
        result = CSG.roundedCube options
      else
        result = CSG.cube options
    return result
  \n"""
  csgSugar += "RoundedCube = CSG.roundedCube\n"
  csgSugar += """Sphere =(options)=>
    if "r" of options
      options.radius = options.r
    if "d" of options
      options.radius = options.d/2
    if "$fn" of options
      options.resolution = options.$fn
    if "center" of options
      if options.center == true
        options.center = [0,0,0]
    return CSG.sphere options
  \n"""
  csgSugar += """Cylinder=(options)=> 
    if "h" of options
      options.start = [0, 0, 0]
      options.end = [0, 0, options.h]
    if "r" of options
      options.radius = options.r
    else
      if "r1" of options
        options.radiusStart = options.r1
      if "r2" of options
        options.radiusEnd= options.r2
    if "d" of options
      options.radius = options.d/2
    else
      if "d1" of options
        options.radiusStart = options.d1/2
      if "d2" of options
        options.radiusEnd = options.d2/2  
    if "center" of options
      if options.center == true
        result = CSG.cylinder options
        result = result.translate([0,0,-options.h/2])
      else
        options.center= [0,0,0]
    if not result?
      result = CSG.cylinder options
    return result
  \n"""
  #csgSugar += "Cylinder = CSG.cylinder\n"
  csgSugar += "RoundedCylinder = CSG.roundedCylinder\n"

  csgSugar += "fromPoints = CAG.fromPoints\n"
  csgSugar += "Circle = CAG.circle\n"
  csgSugar += "Rectangle = CAG.rectangle\n"
  csgSugar += "RoundedRectangle = CAG.roundedRectangle\n"
  

  
  return csgSugar
