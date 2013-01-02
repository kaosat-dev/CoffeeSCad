define (require)->
  class CAG.Circle extends CAG
    constructor: (options) ->
      # Construct a circle
      #   options:
      #     center: a 2D center point
      #     radius: a scalar
      #     resolution: number of sides per 360 degree rotation
      #   returns a CAG object
      #
      options = options or {}
      center = CSG.parseOptionAs2DVector(options, "center", [0, 0])
      radius = CSG.parseOptionAsFloat(options, "radius", 1)
      resolution = CSG.parseOptionAsInt(options, "resolution", CSG.defaultResolution2D)
      sides = []
      prevvertex = undefined
      i = 0
    
      while i <= resolution
        radians = 2 * Math.PI * i / resolution
        point = CSG.Vector2D.fromAngleRadians(radians).times(radius).plus(center)
        vertex = new CAG.Vertex(point)
        sides.push new CAG.Side(prevvertex, vertex)  if i > 0
        prevvertex = vertex
        i++
      CAG.fromSides sides
  
  class CAG.Rectangle extends CAG
    # Construct a rectangle
    #   options:
    #     center: a 2D center point
    #     radius: a 2D vector with width and height
    #   returns a CAG object
    #
    constructor: (options) ->
      options = options or {}
      c = CSG.parseOptionAs2DVector(options, "center", [0, 0])
      r = CSG.parseOptionAs2DVector(options, "radius", [1, 1])
      rswap = new CSG.Vector2D(r.x, -r.y)
      points = [c.plus(r), c.plus(rswap), c.minus(r), c.minus(rswap)]
      CAG.fromPoints points
  
  class CAG.RoundedRectangle extends CAG
    #     var r = CSG.roundedRectangle({
    #       center: [0, 0],
    #       radius: [2, 1],
    #       roundradius: 0.2,
    #       resolution: 8,
    #     });
    constructor: (options) ->
      options = options or {}
      center = CSG.parseOptionAs2DVector(options, "center", [0, 0])
      radius = CSG.parseOptionAs2DVector(options, "radius", [1, 1])
      roundradius = CSG.parseOptionAsFloat(options, "roundradius", 0.2)
      resolution = CSG.parseOptionAsFloat(options, "resolution", CSG.defaultResolution2D)
      maxroundradius = Math.min(radius.x, radius.y)
      maxroundradius -= 0.1
      roundradius = Math.min(roundradius, maxroundradius)
      roundradius = Math.max(0, roundradius)
      radius = new CSG.Vector2D(radius.x - roundradius, radius.y - roundradius)
      rect = CAG.rectangle(
        center: center
        radius: radius
      )
      rect = rect.expand(roundradius, resolution)  if roundradius > 0
      rect
      
  class CAG.Vertex 
    constructor : (pos) ->
      @pos = pos
  
    getTag: ->
      result = @tag
      unless result
        result = CSG.getTag()
        @tag = result
      result
  
  class CAG.Side 
    constructor : (vertex0, vertex1) ->
      throw new Error("Assertion failed")  unless vertex0 instanceof CAG.Vertex
      throw new Error("Assertion failed")  unless vertex1 instanceof CAG.Vertex
      @vertex0 = vertex0
      @vertex1 = vertex1
  
    @fromFakePolygon = (polygon) ->
      throw new Error("Assertion failed")  unless polygon.vertices.length is 4
      pointsZeroZ = []
      indicesZeroZ = []
      i = 0
    
      while i < 4
        pos = polygon.vertices[i].pos
        if (pos.z >= -1.001) and (pos.z < -0.999)
    
        else throw new Error("Assertion failed")  unless (pos.z >= 0.999) and (pos.z < 1.001)
        if pos.z > 0
          pointsZeroZ.push new CSG.Vector2D(pos.x, pos.y)
          indicesZeroZ.push i
        i++
      throw new Error("Assertion failed")  unless pointsZeroZ.length is 2
      d = indicesZeroZ[1] - indicesZeroZ[0]
      p1 = undefined
      p2 = undefined
      if d is 1
        p1 = pointsZeroZ[1]
        p2 = pointsZeroZ[0]
      else if d is 3
        p1 = pointsZeroZ[0]
        p2 = pointsZeroZ[1]
      else
        throw new Error("Assertion failed")
      result = new CAG.Side(new CAG.Vertex(p1), new CAG.Vertex(p2))
      result
  
    toString: ->
      "(" + @vertex0.pos.x + "," + @vertex0.pos.y + ") -> (" + @vertex1.pos.x + "," + @vertex1.pos.y + ")"
    #    return "("+Math.round(this.vertex0.pos.x*10)/10+","+Math.round(this.vertex0.pos.y*10)/10+") -> ("+Math.round(this.vertex1.pos.x*10)/10+","+Math.round(this.vertex1.pos.y*10)/10+")";
    
    toPolygon3D: (z0, z1) ->
      vertices = [new CSG.Vertex(@vertex0.pos.toVector3D(z0)), new CSG.Vertex(@vertex1.pos.toVector3D(z0)), new CSG.Vertex(@vertex1.pos.toVector3D(z1)), new CSG.Vertex(@vertex0.pos.toVector3D(z1))]
      new CSG.Polygon(vertices)
  
    transform: (matrix4x4) ->
      newp1 = @vertex0.pos.transform(matrix4x4)
      newp2 = @vertex1.pos.transform(matrix4x4)
      new CAG.Side(new CAG.Vertex(newp1), new CAG.Vertex(newp2))
  
    flipped: ->
      new CAG.Side(@vertex1, @vertex0)
  
    direction: ->
      @vertex1.pos.minus @vertex0.pos
  
    getTag: ->
      result = @tag
      unless result
        result = CSG.getTag()
        @tag = result
      result
  return