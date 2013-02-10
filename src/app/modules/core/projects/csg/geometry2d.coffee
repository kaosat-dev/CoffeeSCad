define (require)->
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
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  
  ###2D shapes###
  class Circle extends CAGBase
    constructor: (options) ->
      # Construct a circle
      #   options:
      #     center: a 2D center point
      #     radius: a scalar
      #     resolution: number of sides per 360 degree rotation
      #   returns a CAG object
      #
      options = options or {}
      center = parseOptionAs2DVector(options, "center", [0, 0])
      radius = parseOptionAsFloat(options, "r", 1)
      resolution = parseOptionAsInt(options, "$fn", defaultResolution2D)
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
    #     radius: a 2D vector with width and height
    #   returns a CAGBase object
    #
    constructor: (options) ->
      options = options or {}
      c = parseOptionAs2DVector(options, "center", [0, 0])
      r = parseOptionAs2DVector(options, "size", [1, 1])
      #TODO:remove the hack below
      r = r.dividedBy(2)
      rswap = new Vector2D(r.x, -r.y)
      points = [c.plus(r), c.plus(rswap), c.minus(r), c.minus(rswap)]
      result = CAGBase.fromPoints points
      @sides = result.sides
  
  class RoundedRectangle extends CAGBase
    #     var r = CSG.roundedRectangle({
    #       center: [0, 0],
    #       size: [2, 1],
    #       roundradius: 0.2,
    #       resolution: 8,
    #     });
    constructor: (options) ->
      options = options or {}
      center = parseOptionAs2DVector(options, "center", [0, 0])
      radius = parseOptionAs2DVector(options, "size", [1, 1])
      roundradius = parseOptionAsFloat(options, "roundradius", 0.2)
      resolution = parseOptionAsFloat(options, "$fn", defaultResolution2D)
      maxroundradius = Math.min(radius.x, radius.y)
      maxroundradius -= 0.1
      roundradius = Math.min(roundradius, maxroundradius)
      roundradius = Math.max(0, roundradius)
      radius = new Vector2D(radius.x - roundradius, radius.y - roundradius)
      rect = new Rectangle(
        center: center
        radius: radius
      )
      rect = rect.expand(roundradius, resolution)  if roundradius > 0
      rect
      
  return {
    "Rectangle": Rectangle
    "RoundedRectangle": RoundedRectangle
    "Circle": Circle
    }    
  