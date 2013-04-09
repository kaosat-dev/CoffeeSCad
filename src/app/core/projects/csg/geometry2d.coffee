define (require)->
  globals = require './globals'
  
  base = require './csgBase'
  CAGBase = base.CAGBase
  
  maths = require './maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex2D
  Vector2D = maths.Vector2D
  Side = maths.Side
  
  globals = require './globals'
  defaultResolution2D = globals.defaultResolution2D
  
  utils = require './utils'
  parseOptionAsLocations = utils.parseOptionAsLocations
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  parseCenter = utils.parseCenter
  
  extras = require './extras'
  
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
      #options = utils.parseOptions(options,defaults)
      super options
      
      diameter = parseOptionAsFloat(options, "d",defaults["d"])
      radius = diameter/2 
      if hasRadius
        radius = parseOptionAsFloat(options, "r", radius)
      center= parseCenter(options, "center", defaults["center"], defaults["center"], Vector2D)
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
      defaults = {size:[1,1],center:[0,0],cr:0,$fn:0,corners:["all"]}
      #options = utils.parseOptions(options,defaults)
      super options
      
      size = parseOptionAs2DVector(options, "size", defaults["size"])
      #center= parseOptionAs2DVector(options,"center",defaults["center"], size.dividedBy(2))
      center= parseCenter(options, "center", size.dividedBy(2), defaults["center"], Vector2D)

      #rounding
      corners = parseOptionAsLocations(options, "corners",defaults["corners"])
      cornerRadius = parseOptionAsFloat(options,"cr",defaults["cr"])
      cornerResolution = parseOptionAsInt(options,"$fn",defaults["$fn"])
      
      
      if cornerRadius is 0 or cornerResolution is 0
        halfSize = size.dividedBy(2)
        sSwap = new Vector2D(halfSize.x, -halfSize.y)
        points = [center.plus(halfSize), center.plus(sSwap), center.minus(halfSize), center.minus(sSwap)]
        
        #points = [center.plus(size), center.plus(new Vector2D(size.x, 0)), center, center.minus(new Vector2D(0, -size.y))]
        result = CAGBase.fromPoints points
        @sides = result.sides
      else if cornerRadius > 0 and cornerResolution > 0
        #2D so we only care about left/right, front/back
        
        #helper
        sign = (p1,p2,p3)->
          return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
        
        
        chosenIndices = []
        
        #console.log corners.toString(2)
        validCorners = parseInt(corners,2) & (parseInt("001111",2))
        #console.log validCorners.toString(2)
        backFlag = 0x1#hex vs bin compare?
        frontFlag = 0x2
        rightFlag = parseInt("100",2)
        leftFlag = parseInt("1000",2)
        #console.log "front: #{frontFlag.toString(2)} left: #{leftFlag.toString(2)} right: #{rightFlag.toString(2)}"
        #FIXME: god awfull hack?
        if (validCorners & frontFlag)
          if (validCorners & leftFlag)
            chosenIndices.push(3)
          if (validCorners & rightFlag)
            chosenIndices.push(1)
        if (validCorners & backFlag)  
          if (validCorners & leftFlag)
            chosenIndices.push(2)
          if (validCorners & rightFlag)
            chosenIndices.push(0)      
        
        
        subShapes = []
        rCornerPositions = []
        for i in [-1,1]
          for j in [-1,1]
            #sizeOffset = new Vector2D(size).dividedBy(2)
            subCenter = new Vector2D(i*size.x/2,j*size.y/2).plus(center)#.plus(sizeOffset)
            rCornerPositions.push(subCenter)
        
        for i in [0...rCornerPositions.length]
          r =  new Rectangle({size:cornerRadius,center:true})
          corner = rCornerPositions[i]
          bX = if corner.x > center.x then +1 else -1
          bY = if corner.y > center.y then +1 else -1
          
          insetVector = corner.minus(new Vector2D(bX,bY).times(cornerRadius/2))
          r.translate(insetVector)
          #console.log "corner: #{corner.x} #{corner.y}"
          #console.log "cornerElement position: #{insetVector.x} #{insetVector.y}"
          subShapes.push(r)
          
        for index in chosenIndices
          corner = rCornerPositions[index]
          bX = if corner.x > center.x then +1 else -1
          bY = if corner.y > center.y then +1 else -1
          
          insetVector = corner.minus(new Vector2D(bX,bY).times(cornerRadius))
          #console.log "Rounded cornerElement position: #{insetVector.x} #{insetVector.y}"
          c = new Circle({r:cornerRadius,$fn:cornerResolution,center:true})
          c.translate(insetVector)
          subShapes[index] = c  
        
        ### 
        result = new CAGBase()
        for shape in subShapes
          result.union(shape)
        ###
        result = extras.hull(subShapes)
        @sides = result.sides

  return {
    "Rectangle": Rectangle
    "Circle": Circle
    }    
  