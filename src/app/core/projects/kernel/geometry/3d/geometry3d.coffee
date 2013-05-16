define (require)->
  base = require './csgBase'
  CSGBase = base.CSGBase
  
  maths = require './maths'
  Vertex = maths.Vertex
  Vector3D = maths.Vector3D
  Polygon = maths.Polygon
  
  properties = require './properties'
  Properties = properties.Properties
  Connector = properties.Connector
   
  utils = require './utils'
  parseOptionAs3DVector = utils.parseOptionAs3DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  parseOptionAsBool = utils.parseOptionAsBool
  parseCenter = utils.parseCenter
 
  class Cube extends CSGBase
    # Construct a solid cuboid. with optional corner roundings (making it, you guessed it, a rounded cube)
    # Parameters:
    #   center: center of cube (default [0,0,0])
    #   size: size of cube (default [1,1,1]), can be specified as scalar or as 3D vector
    #   r: radius of corners
    #   $fn: corner resolution
    #  
    # Example code:
    #     cube = new Cube({
    #       center: [0, 0, 0],
    #       radius: 1
    #     });
    constructor : (options) ->
      #use splat for options?
      options = options or {}
      defaults = {size:[1,1,1],center:[0,0,0],r:0,$fn:0}
      #options = utils.parseOptions(options, defaults)
      super options
      
      size = parseOptionAs3DVector(options, "size", defaults["size"])
      center = parseCenter(options,"center",size.dividedBy(2),defaults["center"], Vector3D)
      
      #do params validation
      throw new Error("Cube size should be non-negative") if size.x <0 or size.y <0 or size.z <0
      
      #for rounded corners
      cornerRadius= parseOptionAsFloat(options, "r", 0)
      cornerResolution= parseOptionAsFloat(options, "$fn", 0)
      cornerResolution = 4  if cornerResolution < 4
      
      #Add attributes?
      
      #polygons = []
      #vertexMultipliers = [[-1,-1,-1],[-1,1,-1],[1,1,-1],[-1,1,-1]]
      #faceNormals = [[-1, 0, 0], [+1, 0, 0], [0, -1, 0], [0, +1, 0], [0, 0, -1], [0, 0, +1]]
      #vertices = [new Vector3D(center.x-size.x/2,center.y-size.y/2,0), new Vector3D(center.x+size.x/2,center.y-size.y/2,0), new Vector3D(center.x-size.x/2,center.y+size.y/2,0)]
      #constructor : (vertices, shared, plane)
      
      @polygons = [[[0, 4, 6, 2], [-1, 0, 0]], [[1, 3, 7, 5], [+1, 0, 0]], [[0, 1, 5, 4], [0, -1, 0]], [[2, 6, 7, 3], [0, +1, 0]], [[0, 2, 3, 1], [0, 0, -1]], [[4, 5, 7, 6], [0, 0, +1]]].map((info) ->
        normal = new Vector3D(info[1])
        vertices = info[0].map((i) ->
          pos = new Vector3D(center.x+size.x/2 * (2 * !!(i & 1) - 1), center.y+size.y/2 * (2 * !!(i & 2) - 1), center.z+size.z/2 * (2 * !!(i & 4) - 1))
          new Vertex(pos)
          )
        new Polygon(vertices, null)
      )
      @properties.cube = new Properties()
      @properties.cube.center = new Vector3D(center)
      # add 6 connectors, at the centers of each face:
      @properties.cube.facecenters = [new Connector(new Vector3D([size.x, 0, 0]).plus(center), [1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([-size.x, 0, 0]).plus(center), [-1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([0, size.y, 0]).plus(center), [0, 1, 0], [0, 0, 1]), new Connector(new Vector3D([0, -size.y, 0]).plus(center), [0, -1, 0], [0, 0, 1]), new Connector(new Vector3D([0, 0, size.z]).plus(center), [0, 0, 1], [1, 0, 0]), new Connector(new Vector3D([0, 0, -size.z]).plus(center), [0, 0, -1], [1, 0, 0])]

      @isCanonicalized = false
      @isRetesselated = false
  
  class RoundedCube extends CSGBase
    # Construct an axis-aligned solid rounded cuboid.
    # Parameters:
    #   center: center of cube (default [0,0,0])
    #   radius: radius of cube (default [1,1,1]), can be specified as scalar or as 3D vector
    #   roundradius: radius of rounded corners (default 0.2), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 8)
    # 
    # Example code:
    # 
    #     var cube = RoundedCube({
    #       center: [0, 0, 0],
    #       radius: 1,
    #       roundradius: 0.2,
    #       resolution: 8,
    #     });
    constructor : (options) ->
      center = parseOptionAs3DVector(options, "center", [0, 0, 0])
      cuberadius = parseOptionAs3DVector(options, "radius", [1, 1, 1])
      resolution = parseOptionAsFloat(options, "resolution", CSGBase.defaultResolution3D)
      resolution = 4  if resolution < 4
      roundradius = parseOptionAsFloat(options, "roundradius", 0.2)
      innercuberadius = cuberadius
      innercuberadius = innercuberadius.minus(new Vector3D(roundradius))
      result = new Cube(
        center: center
        radius: [cuberadius.x, innercuberadius.y, innercuberadius.z]
      )
      result = result.unionSub( new Cube(
        center: center
        radius: [innercuberadius.x, cuberadius.y, innercuberadius.z]
      ), false, false)
      result = result.unionSub( new Cube(
        center: center
        radius: [innercuberadius.x, innercuberadius.y, cuberadius.z]
      ), false, false)
      level = 0
    
      while level < 2
        z = innercuberadius.z
        z = -z  if level is 1
        p1 = new Vector3D(innercuberadius.x, innercuberadius.y, z).plus(center)
        p2 = new Vector3D(innercuberadius.x, -innercuberadius.y, z).plus(center)
        p3 = new Vector3D(-innercuberadius.x, -innercuberadius.y, z).plus(center)
        p4 = new Vector3D(-innercuberadius.x, innercuberadius.y, z).plus(center)
        sphere = Sphere(
          center: p1
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(sphere, false, false)
        sphere = new Sphere(
          center: p2
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(sphere, false, false)
        sphere = new Sphere(
          center: p3
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(sphere, false, false)
        sphere = new Sphere(
          center: p4
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(sphere, false, true)
        cylinder = new Cylinder(
          start: p1
          end: p2
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(cylinder, false, false)
        cylinder = new Cylinder(
          start: p2
          end: p3
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(cylinder, false, false)
        cylinder = new Cylinder(
          start: p3
          end: p4
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(cylinder, false, false)
        cylinder = new Cylinder(
          start: p4
          end: p1
          radius: roundradius
          resolution: resolution
        )
        result = result.unionSub(cylinder, false, false)
        if level is 0
          d = new Vector3D(0, 0, -2 * z)
          cylinder = new Cylinder(
            start: p1
            end: p1.plus(d)
            radius: roundradius
            resolution: resolution
          )
          result = result.unionSub(cylinder)
          cylinder = new Cylinder(
            start: p2
            end: p2.plus(d)
            radius: roundradius
            resolution: resolution
          )
          result = result.unionSub(cylinder)
          cylinder = new Cylinder(
            start: p3
            end: p3.plus(d)
            radius: roundradius
            resolution: resolution
          )
          result = result.unionSub(cylinder)
          cylinder = new Cylinder(
            start: p4
            end: p4.plus(d)
            radius: roundradius
            resolution: resolution
          )
          result = result.unionSub(cylinder, false, true)
        level++
      result = result.reTesselated()
      result.properties.roundedCube = new Properties()
      result.properties.roundedCube.center = new Vertex(center)
      result.properties.roundedCube.facecenters = [new Connector(new Vector3D([cuberadius.x, 0, 0]).plus(center), [1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([-cuberadius.x, 0, 0]).plus(center), [-1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([0, cuberadius.y, 0]).plus(center), [0, 1, 0], [0, 0, 1]), new Connector(new Vector3D([0, -cuberadius.y, 0]).plus(center), [0, -1, 0], [0, 0, 1]), new Connector(new Vector3D([0, 0, cuberadius.z]).plus(center), [0, 0, 1], [1, 0, 0]), new Connector(new Vector3D([0, 0, -cuberadius.z]).plus(center), [0, 0, -1], [1, 0, 0])]

      @properties= result.properties
      @polygons= result.polygons
      @isCanonicalized = result.isCanonicalized
      @isRetesselated = result.isRetesselated
       
  class Sphere extends CSGBase
    # Construct a solid sphere
    #
    # Parameters:
    #   center: center of sphere (default [0,0,0])
    #   radius: radius of sphere (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    #   axes: (optional) an array with 3 vectors for the x, y and z base vectors
    # 
    # Example usage:
    # 
    #     sphere = new Sphere({
    #       center: [0, 0, 0],
    #       r: 2,
    #       $fn: 32,
    #     });
    constructor : (options) ->
      options = options or {}
      if "r" of options then hasRadius = true
      defaults = {r:1,d:2,center:[0,0,0],$fn:CSGBase.defaultResolution3D}
      #options = utils.parseOptions(options,defaults)
      super options
      
      diameter = parseOptionAsFloat(options, "d",defaults["d"])
      radius = diameter/2 
      if hasRadius
        radius = parseOptionAsFloat(options, "r", radius)
      center= parseCenter(options,"center",defaults["center"],defaults["center"],Vector3D)
      resolution = parseOptionAsInt(options, "$fn", CSGBase.defaultResolution3D)
      
      #do params validation
      throw new Error("Sphere Radius/diameter should be non-negative") if radius < 0
      throw new Error("Sphere Resolution should be non-negative") if resolution < 0
      
      xvector = undefined
      yvector = undefined
      zvector = undefined
      if "axes" of options
        xvector = options.axes[0].unit().times(radius)
        yvector = options.axes[1].unit().times(radius)
        zvector = options.axes[2].unit().times(radius)
      else
        xvector = new Vector3D([1, 0, 0]).times(radius)
        yvector = new Vector3D([0, -1, 0]).times(radius)
        zvector = new Vector3D([0, 0, 1]).times(radius)
      resolution = 4  if resolution < 4
      qresolution = Math.round(resolution / 4)
      prevcylinderpoint = undefined
      polygons = []
      slice1 = 0
    
      while slice1 <= resolution
        angle = Math.PI * 2.0 * slice1 / resolution
        cylinderpoint = xvector.times(Math.cos(angle)).plus(yvector.times(Math.sin(angle)))
        if slice1 > 0
          
          # cylinder vertices:
          vertices = []
          prevcospitch = undefined
          prevsinpitch = undefined
          slice2 = 0
    
          while slice2 <= qresolution
            pitch = 0.5 * Math.PI * slice2 / qresolution
            cospitch = Math.cos(pitch)
            sinpitch = Math.sin(pitch)
            if slice2 > 0
              vertices = []
              vertices.push new Vertex(center.plus(prevcylinderpoint.times(prevcospitch).minus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(center.plus(cylinderpoint.times(prevcospitch).minus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(center.plus(cylinderpoint.times(cospitch).minus(zvector.times(sinpitch))))  if slice2 < qresolution
              vertices.push new Vertex(center.plus(prevcylinderpoint.times(cospitch).minus(zvector.times(sinpitch))))
              polygons.push new Polygon(vertices)
              vertices = []
              vertices.push new Vertex(center.plus(prevcylinderpoint.times(prevcospitch).plus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(center.plus(cylinderpoint.times(prevcospitch).plus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(center.plus(cylinderpoint.times(cospitch).plus(zvector.times(sinpitch))))  if slice2 < qresolution
              vertices.push new Vertex(center.plus(prevcylinderpoint.times(cospitch).plus(zvector.times(sinpitch))))
              vertices.reverse()
              polygons.push new Polygon(vertices)
            prevcospitch = cospitch
            prevsinpitch = sinpitch
            slice2++
        prevcylinderpoint = cylinderpoint
        slice1++
      
      @polygons = polygons
      @isCanonicalized = false
      @isRetesselated = false
      
      @properties.sphere = new Properties()
      @properties.sphere.center = new Vector3D(center)
      @properties.sphere.facepoint = center.plus(xvector)
    
  
  class Cylinder extends CSGBase
    # Construct a solid cylinder.
    #
    # Parameters:
    #   start: start point of cylinder (default [0, -1, 0])
    #   end: end point of cylinder (default [0, 1, 0])
    #   radius: radius of cylinder (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    # 
    # Example usage:
    # 
    #     cylinder = new Cylinder({
    #       start: [0, -1, 0],
    #       end: [0, 1, 0],
    #       radius: 1,
    #       resolution: 16,
    #       center: true
    #     });
    constructor : (options) ->
      options = options or {}
      if ("r" of options or "r1" of options) then hasRadius = true
      defaults = {h:1,center:[0,0,0],r:1,d:2,$fn:CSGBase.defaultResolution2D,rounded:false}
      #options = utils.parseOptions(options,defaults)
      super options
      
      point = (stack, slice, radius) ->
        angle = slice * Math.PI * 2
        out = axisX.times(Math.cos(angle)).plus(axisY.times(Math.sin(angle)))
        pos = s.plus(ray.times(stack)).plus(out.times(radius))
        new Vertex(pos)
      
      h = parseOptionAsFloat(options, "h", defaults["h"])
      s = new Vector3D([0, 0, -h/2])
      e = new Vector3D([0, 0, h/2])
      #s = parseOptionAs3DVector(options, "start", [0, -1, 0])
      #e = parseOptionAs3DVector(options, "end", [0, 1, 0])
      radius = parseOptionAsFloat(options, "d", defaults["d"])/2
      rEnd = parseOptionAsFloat(options, "d1", (radius*2))/2
      rStart = parseOptionAsFloat(options, "d2", radius*2)/2
      
      if hasRadius
        radius = parseOptionAsFloat(options, "r", radius)
        rEnd = parseOptionAsFloat(options, "r2", radius)
        rStart = parseOptionAsFloat(options, "r1", radius)
      
      min = s.min(e)
      max = s.max(e)
      halfHeightVect = max.minus(min).dividedBy(2)
      
      center= parseCenter(options,"center", (halfHeightVect),  defaults["center"], Vector3D)
      
      s = center.minus(halfHeightVect) 
      e = center.plus(halfHeightVect) 
      throw new Error("Radius should be non-negative")  if (rEnd < 0) or (rStart < 0)
      throw new Error("Either radiusStart or radiusEnd should be positive")  if (rEnd is 0) and (rStart is 0)
      
      roundEnds = parseOptionAsBool(options, "rounded", false)
      if roundEnds
        radiusOffset = new Vector3D(0,0,radius)
        #s = if s.z > center.z then s.minus(radiusOffset) else s.plus(radiusOffset)
        #e = if e.z > center.z then e.minus(radiusOffset) else e.minus(radiusOffset)
        reducedEnd = e.minus(radiusOffset)
        reducedStart = s.plus(radiusOffset)
        throw new Error("Size with roundings is too small") if reducedEnd.lengthSquared() == 0 and reducedStart.lengthSquared()==0
        s = reducedStart
        e = reducedEnd
      
      slices = parseOptionAsFloat(options, "$fn", defaults["$fn"])
      ray = e.minus(s)
      axisZ = ray.unit()
      axisX = axisZ.randomNonParallelVector().unit()
      axisY = axisX.cross(axisZ).unit()
      start = new Vertex(s)
      end = new Vertex(e)
      polygons = []
      i = 0
    
      while i < slices
        t0 = i / slices
        t1 = (i + 1) / slices
        if rEnd is rStart
          polygons.push new Polygon([start, point(0, t0, rEnd), point(0, t1, rEnd)])
          polygons.push new Polygon([point(0, t1, rEnd), point(0, t0, rEnd), point(1, t0, rEnd), point(1, t1, rEnd)])
          polygons.push new Polygon([end, point(1, t1, rEnd), point(1, t0, rEnd)])
        else
          if rStart > 0
            polygons.push new Polygon([start, point(0, t0, rStart), point(0, t1, rStart)])
            polygons.push new Polygon([point(0, t0, rStart), point(1, t0, rEnd), point(0, t1, rStart)])
          if rEnd > 0
            polygons.push new Polygon([end, point(1, t1, rEnd), point(1, t0, rEnd)])
            polygons.push new Polygon([point(1, t0, rEnd), point(1, t1, rEnd), point(0, t1, rStart)])
        i++
      
      @polygons= polygons
      @isCanonicalized = false
      @isRetesselated = false
      @properties.cylinder = new Properties()
      @properties.cylinder.start = new Connector(s, axisZ.negated(), axisX)
      @properties.cylinder.end = new Connector(e, axisZ, axisX)
      @properties.cylinder.facepoint = s.plus(axisX.times(rStart))
      
      if roundEnds
        @union(new Sphere({r:radius,$fn:slices}).translate(e))
        @union(new Sphere({r:radius,$fn:slices}).translate(s))
      
  return {
    "Cube": Cube
    "Sphere": Sphere
    "Cylinder": Cylinder
    }