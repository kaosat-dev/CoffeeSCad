define (require)->
  globals = require './globals'
  
  base = require './csgBase'
  CAGBase = base.CAGBase
  
  maths = require './maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex
  Vector2D = maths.Vector2D
  Side = maths.Side
  
  globals = require './globals'
  defaultResolution2D = globals.defaultResolution2D
  
  utils = require './utils'
  parseOptionAsLocations = utils.parseOptionAsLocations
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  
  ###2D shapes###
  class Circle extends CAGBase
    # Construct a circle
    #   options:
    #     center: a 2D center point
    #     radius: a scalar
    #     resolution: number of sides per 360 degree rotation
    #   returns a CAG object
    #
    constructor: (options) ->
      options = options or {}
      if "r" of options then hasRadius = true
      defaults = {r:1,d:2,center:[0,0],$fn:globals.defaultResolution2D}
      options = utils.parseOptions(options,defaults)
      super options
      
      diameter = parseOptionAsFloat(options, "d",defaults["d"])
      radius = diameter/2 
      if hasRadius
        radius = parseOptionAsFloat(options, "r", radius)
      center= parseOptionAs2DVector(options, "center", radius, defaults["center"])
      resolution = parseOptionAsInt(options, "$fn", defaults["$fn"])
      sides = []
      prevvertex = undefined
      i = 0
    
      while i <= resolution
        radians = 2 * Math.PI * i / resolution
        point = Vector2D.fromAngleRadians(radians).times(radius).plus(center)
        vertex = new Vertex2D(point)
        sides.push new Side(prevvertex, vertex)  if i > 0
        prevvertex = vertex
        i++
      @sides = sides
  
  class Rectangle extends CAGBase
    # Construct a rectangle
    #   options:
    #     center: a 2D center point
    #     size: a 2D vector with width and height
    #   returns a CAGBase object
    #
    constructor: (options) ->
      options = options or {}
      defaults = {size:[1,1],center:[0,0],cr:0,$fn:0,corners:[globals.all]}
      options = utils.parseOptions(options,defaults)
      super options
      
      size = parseOptionAs2DVector(options, "size", defaults["size"])
      center= parseOptionAs2DVector(options,"center",size.negated().dividedBy(2), defaults["center"])
      #rounding
      corners = parseOptionAsLocations(options, "corners",defaults["corners"])
      cornerRadius = parseOptionAsFloat(options,"cr",defaults["cr"])
      cornerResolution = parseOptionAsInt(options,"$fn",defaults["$fn"])
      
      if cornerRadius is 0 or cornerResolution is 0
        points = [center.plus(size), center.plus(new Vector2D(size.x, 0)), center, center.minus(new Vector2D(0, -size.y))]
        result = CAGBase.fromPoints points
        @sides = result.sides
      else if cornerRadius > 0 and cornerResolution > 0
        if corners is globals.all or globals.all in corners
          sizeOffset = new Vector2D(cornerRadius*2,cornerRadius*2)
          adjustedSize = size.minus(sizeOffset)
          rect = new Rectangle({size:adjustedSize,center:center.plus(sizeOffset.dividedBy(2))})
          rect = rect.expand(cornerRadius, cornerResolution)
          @sides = rect.sides
        else if corners is globals.left
          rect = new Rectangle({size:size,center:center})
          rect = rect.expand(cornerRadius, cornerResolution)
          rect2 = new Rectangle({size:size.minus(new Vector2D(cornerRadius,0)),center:center.plus(new Vector2D(cornerRadius,0))})
          rect = rect.intersect(rect2)
          @sides = rect.sides
        else if corners is globals.front
          sizeOffset = new Vector2D(cornerRadius*2,cornerRadius*2)
          adjustedSize = size.minus(sizeOffset)
          rect = new Rectangle({size:adjustedSize,center:center.plus(sizeOffset.dividedBy(2))})
          rect = rect.expand(cornerRadius, cornerResolution)
          rect2 = new Rectangle({size:size.minus(new Vector2D(0,cornerRadius)),center:center.plus(new Vector2D(0,cornerRadius))})
          rect = rect2.intersect(rect)
          @sides = rect.sides
        
  return {
    "Rectangle": Rectangle
    "Circle": Circle
    }    
  