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
    console.log options
    if "size" of options
      console.log "found"
      options.radius = options.size
    if "center" of options
      if options.center == true
        console.log "pouet"
        options.center= [0,0,0]
    console.log options
    return CSG.cube options
  \n"""
  csgSugar += "RoundedCube = CSG.roundedCube\n"
  csgSugar += "Sphere = CSG.sphere\n"
  csgSugar += """Cylinder=(options)=> 
    if "size" of options
      console.log "tutu"
    return CSG.cylinder options
  \n"""
  #csgSugar += "Cylinder = CSG.cylinder\n"
  csgSugar += "RoundedCylinder = CSG.roundedCylinder\n"

  csgSugar += "fromPoints = CAG.fromPoints\n"
  csgSugar += "Circle = CAG.circle\n"
  csgSugar += "Rectangle = CAG.rectangle\n"
  csgSugar += "RoundedRectangle = CAG.roundedRectangle\n"
  
  return csgSugar
