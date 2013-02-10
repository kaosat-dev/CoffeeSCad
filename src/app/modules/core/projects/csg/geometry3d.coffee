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

 
  class Cube extends CSGBase
    # Construct an axis-aligned solid cuboid.
    # Parameters:
    #   center: center of cube (default [0,0,0])
    #   radius: radius of cube (default [1,1,1]), can be specified as scalar or as 3D vector
    #  
    # Example code:
    #     var cube = Cube({
    #       center: [0, 0, 0],
    #       radius: 1
    #     });
    constructor : (options) ->
      super options
      options = options or {}
      #if options.c?
      #  if options.c == true #
      center= true
      c = parseOptionAs3DVector(options, "center", [0, 0, 0])
      r = parseOptionAs3DVector(options, "size", [1, 1, 1])
      #radius (size) is nonsensical, divide by 2 to get real dimentions
      r = r.dividedBy(2)
      ### 
      result = null
      CSGBase.fromPolygons
      vertices = a*a for a in list when a%2 == 0
      count item  for item in [1..10 ] when item % 3 isnt 0
      [
        [pos,norm],
        [pos,norm]
      ]
      ###
      
      result = CSGBase.fromPolygons([[[0, 4, 6, 2], [-1, 0, 0]], [[1, 3, 7, 5], [+1, 0, 0]], [[0, 1, 5, 4], [0, -1, 0]], [[2, 6, 7, 3], [0, +1, 0]], [[0, 2, 3, 1], [0, 0, -1]], [[4, 5, 7, 6], [0, 0, +1]]].map((info) ->
        normal = new Vector3D(info[1])
        vertices = info[0].map((i) ->
          pos = new Vector3D(c.x + (r.x) * (2 * !!(i & 1) - 1), c.y + (r.y) * (2 * !!(i & 2) - 1), c.z + (r.z) * (2 * !!(i & 4) - 1))
          new Vertex(pos)
          )
        new Polygon(vertices, null)
      ))
      
      result.properties.cube = new Properties()
      result.properties.cube.center = new Vector3D(c)
  
      # add 6 connectors, at the centers of each face:
      result.properties.cube.facecenters = [new Connector(new Vector3D([r.x, 0, 0]).plus(c), [1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([-r.x, 0, 0]).plus(c), [-1, 0, 0], [0, 0, 1]), new Connector(new Vector3D([0, r.y, 0]).plus(c), [0, 1, 0], [0, 0, 1]), new Connector(new Vector3D([0, -r.y, 0]).plus(c), [0, -1, 0], [0, 0, 1]), new Connector(new Vector3D([0, 0, r.z]).plus(c), [0, 0, 1], [1, 0, 0]), new Connector(new Vector3D([0, 0, -r.z]).plus(c), [0, 0, -1], [1, 0, 0])]
      
      #FIXME: if possible remove this additional operation (this one is here to have positioning a la openscad)
      result.translate(r)
      @properties= result.properties
      @polygons= result.polygons
      @isCanonicalized = result.isCanonicalized
      @isRetesselated = result.isRetesselated
  
       
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
    #     var sphere = Sphere({
    #       center: [0, 0, 0],
    #       radius: 2,
    #       resolution: 32,
    #     });
    constructor : (options) ->
      options = options or {}
      ###
      if options.center
        if options.center == true
          center = [0,0,0]
      else
      ###
      center = parseOptionAs3DVector(options, "center", [0, 0, 0])
      
      radius = parseOptionAsFloat(options, "r", 1)
      if options.d
        radius = parseOptionAsFloat(options, "d", 0.5)/2
      
      resolution = parseOptionAsInt(options, "$fn", CSGBase.defaultResolution3D)
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
      result = CSGBase.fromPolygons(polygons)
      result.properties.sphere = new Properties()
      result.properties.sphere.center = new Vector3D(center)
      result.properties.sphere.facepoint = center.plus(xvector)
      
      @properties= result.properties
      @polygons= result.polygons
      @isCanonicalized = result.isCanonicalized
      @isRetesselated = result.isRetesselated
  
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
    #     var cylinder = Cylinder({
    #       start: [0, -1, 0],
    #       end: [0, 1, 0],
    #       radius: 1,
    #       resolution: 16
    #     });
    constructor : (options) ->
      options = options or {}
      #, isY = (Math.abs(axisZ.y) > 0.5);
      #  var axisX = new Vector3D(isY, !isY, 0).cross(axisZ).unit();
      point = (stack, slice, radius) ->
        angle = slice * Math.PI * 2
        out = axisX.times(Math.cos(angle)).plus(axisY.times(Math.sin(angle)))
        pos = s.plus(ray.times(stack)).plus(out.times(radius))
        new Vertex(pos)
      
      h = parseOptionAsFloat(options, "h", 1)
      s = new Vector3D([0, 0, 0])
      e = new Vector3D([0, 0, h])
      #s = parseOptionAs3DVector(options, "start", [0, -1, 0])
      #e = parseOptionAs3DVector(options, "end", [0, 1, 0])
      
      r = parseOptionAsFloat(options, "r", 1)
      rEnd = parseOptionAsFloat(options, "r2", r)
      rStart = parseOptionAsFloat(options, "r1", r)
      
      if options.d1?
        rEnd = parseOptionAsFloat(options, "d2", r)/2
        rStart = parseOptionAsFloat(options, "d1", r)/2
        
      throw new Error("Radius should be non-negative")  if (rEnd < 0) or (rStart < 0)
      throw new Error("Either radiusStart or radiusEnd should be positive")  if (rEnd is 0) and (rStart is 0)
      slices = parseOptionAsFloat(options, "$fn", CSGBase.defaultResolution2D)
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
      result = CSGBase.fromPolygons(polygons)
      result.properties.cylinder = new Properties()
      result.properties.cylinder.start = new Connector(s, axisZ.negated(), axisX)
      result.properties.cylinder.end = new Connector(e, axisZ, axisX)
      result.properties.cylinder.facepoint = s.plus(axisX.times(rStart))
      
      @properties= result.properties
      @polygons= result.polygons
      @isCanonicalized = result.isCanonicalized
      @isRetesselated = result.isRetesselated
  
  class RoundedCylinder extends CSGBase
    # Like a cylinder, but with rounded ends instead of flat
    #
    # Parameters:
    #   start: start point of cylinder (default [0, -1, 0])
    #   end: end point of cylinder (default [0, 1, 0])
    #   radius: radius of cylinder (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    #   normal: a vector determining the starting angle for tesselation. Should be non-parallel to start.minus(end)
    # 
    # Example usage:
    # 
    #     var cylinder = RoundedCylinder({
    #       start: [0, -1, 0],
    #       end: [0, 1, 0],
    #       radius: 1,
    #       resolution: 16
    #     });
    constructor : (options) ->
      options = options or {}
      p1 = parseOptionAs3DVector(options, "start", [0, -1, 0])
      p2 = parseOptionAs3DVector(options, "end", [0, 1, 0])
      radius = parseOptionAsFloat(options, "r", 1)
      
      h = parseOptionAsFloat(options, "h", 1)
      s = new Vector3D([0, 0, 0])
      e = new Vector3D([0, 0, h])
      
      direction = p2.minus(p1)
      defaultnormal = undefined
      if Math.abs(direction.x) > Math.abs(direction.y)
        defaultnormal = new Vector3D(0, 1, 0)
      else
        defaultnormal = new Vector3D(1, 0, 0)
      normal = parseOptionAs3DVector(options, "normal", defaultnormal)
      resolution = parseOptionAsFloat(options, "resolution", CSGBase.defaultResolution3D)
      resolution = 4  if resolution < 4
      polygons = []
      qresolution = Math.floor(0.25 * resolution)
      length = direction.length()
      if length < 1e-10
        return Sphere(
          center: p1
          radius: radius
          resolution: resolution
        )
      zvector = direction.unit().times(radius)
      xvector = zvector.cross(normal).unit().times(radius)
      yvector = xvector.cross(zvector).unit().times(radius)
      prevcylinderpoint = undefined
      slice1 = 0
    
      while slice1 <= resolution
        angle = Math.PI * 2.0 * slice1 / resolution
        cylinderpoint = xvector.times(Math.cos(angle)).plus(yvector.times(Math.sin(angle)))
        if slice1 > 0
          
          # cylinder vertices:
          vertices = []
          vertices.push new Vertex(p1.plus(cylinderpoint))
          vertices.push new Vertex(p1.plus(prevcylinderpoint))
          vertices.push new Vertex(p2.plus(prevcylinderpoint))
          vertices.push new Vertex(p2.plus(cylinderpoint))
          polygons.push new Polygon(vertices)
          prevcospitch = undefined
          prevsinpitch = undefined
          slice2 = 0
    
          while slice2 <= qresolution
            pitch = 0.5 * Math.PI * slice2 / qresolution
            
            #var pitch = Math.asin(slice2/qresolution);
            cospitch = Math.cos(pitch)
            sinpitch = Math.sin(pitch)
            if slice2 > 0
              vertices = []
              vertices.push new Vertex(p1.plus(prevcylinderpoint.times(prevcospitch).minus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(p1.plus(cylinderpoint.times(prevcospitch).minus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(p1.plus(cylinderpoint.times(cospitch).minus(zvector.times(sinpitch))))  if slice2 < qresolution
              vertices.push new Vertex(p1.plus(prevcylinderpoint.times(cospitch).minus(zvector.times(sinpitch))))
              polygons.push new Polygon(vertices)
              vertices = []
              vertices.push new Vertex(p2.plus(prevcylinderpoint.times(prevcospitch).plus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(p2.plus(cylinderpoint.times(prevcospitch).plus(zvector.times(prevsinpitch))))
              vertices.push new Vertex(p2.plus(cylinderpoint.times(cospitch).plus(zvector.times(sinpitch))))  if slice2 < qresolution
              vertices.push new Vertex(p2.plus(prevcylinderpoint.times(cospitch).plus(zvector.times(sinpitch))))
              vertices.reverse()
              polygons.push new Polygon(vertices)
            prevcospitch = cospitch
            prevsinpitch = sinpitch
            slice2++
        prevcylinderpoint = cylinderpoint
        slice1++
      result = CSGBase.fromPolygons(polygons)
      ray = zvector.unit()
      axisX = xvector.unit()
      result.properties.roundedCylinder = new Properties()
      result.properties.roundedCylinder.start = new Connector(p1, ray.negated(), axisX)
      result.properties.roundedCylinder.end = new Connector(p2, ray, axisX)
      result.properties.roundedCylinder.facepoint = p1.plus(xvector)
      
      @properties= result.properties
      @polygons= result.polygons
      @isCanonicalized = result.isCanonicalized
      @isRetesselated = result.isRetesselated
    

  return {
    "Cube": Cube
    "RoundedCube": RoundedCube
    "Sphere": Sphere
    "Cylinder": Cylinder
    "RoundedCylinder":RoundedCylinder
    }