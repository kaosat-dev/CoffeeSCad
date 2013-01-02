define (require)->
  Function::property = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc
 
  class  CSG.Vector2D 
    # Represents a 2 element vector
    constructor : (x, y) ->
      if arguments_.length is 2
        @_x = parseFloat(x)
        @_y = parseFloat(y)
      else
        ok = true
        if arguments_.length is 1
          if typeof (x) is "object"
            if x instanceof CSG.Vector2D
              @_x = x._x
              @_y = x._y
            else if x instanceof Array
              @_x = parseFloat(x[0])
              @_y = parseFloat(x[1])
            else if ("x" of x) and ("y" of x)
              @_x = parseFloat(x.x)
              @_y = parseFloat(x.y)
            else
              ok = false
          else
            v = parseFloat(x)
            @_x = v
            @_y = v
        else
          ok = false
        ok = false  if (not CSG.IsFloat(@_x)) or (not CSG.IsFloat(@_y))  if ok
        throw new Error("wrong arguments")  unless ok
        
        #getters setters
        @property 'x',
          get: -> return this._x
          set: (v) -> throw new Error("Vector2D is immutable")
        
        @property 'y',
          get: -> return this._y
          set: (v) -> throw new Error("Vector2D is immutable")
          
    @fromAngle : (radians) ->
      CSG.Vector2D.fromAngleRadians radians
    
    @fromAngleDegrees : (degrees) ->
      radians = Math.PI * degrees / 180
      CSG.Vector2D.fromAngleRadians radians
    
    @fromAngleRadians : (radians) ->
      new CSG.Vector2D(Math.cos(radians), Math.sin(radians))
  
    toVector3D: (z) ->
      # extend to a 3D vector by adding a z coordinate:
      new CSG.Vector3D(@_x, @_y, z)
  
    equals: (a) ->
      (@_x is a._x) and (@_y is a._y)
  
    clone: ->
      new CSG.Vector2D(@_x, @_y)
  
    negated: ->
      new CSG.Vector2D(-@_x, -@_y)
  
    plus: (a) ->
      new CSG.Vector2D(@_x + a._x, @_y + a._y)
  
    minus: (a) ->
      new CSG.Vector2D(@_x - a._x, @_y - a._y)
  
    times: (a) ->
      new CSG.Vector2D(@_x * a, @_y * a)
  
    dividedBy: (a) ->
      new CSG.Vector2D(@_x / a, @_y / a)
  
    dot: (a) ->
      @_x * a._x + @_y * a._y
  
    lerp: (a, t) ->
      @plus a.minus(this).times(t)
  
    length: ->
      Math.sqrt @dot(this)
  
    distanceTo: (a) ->
      @minus(a).length()
  
    distanceToSquared: (a) ->
      @minus(a).lengthSquared()
  
    lengthSquared: ->
      @dot this
  
    unit: ->
      @dividedBy @length()
  
    cross: (a) ->
      @_x * a._y - @_y * a._x
  
    normal: ->
      # returns the vector rotated by 90 degrees clockwise
      new CSG.Vector2D(@_y, -@_x)
  
    multiply4x4: (matrix4x4) ->
      # Right multiply by a 4x4 matrix (the vector is interpreted as a row vector)
      # Returns a new CSG.Vector2D
      matrix4x4.leftMultiply1x2Vector this
  
    transform: (matrix4x4) ->
      matrix4x4.leftMultiply1x2Vector this
  
    angle: ->
      @angleRadians()
  
    angleDegrees: ->
      radians = @angleRadians()
      180 * radians / Math.PI
  
    angleRadians: ->
      # y=sin, x=cos
      Math.atan2 @_y, @_x
  
    min: (p) ->
      new CSG.Vector2D(Math.min(@_x, p._x), Math.min(@_y, p._y))
  
    max: (p) ->
      new CSG.Vector2D(Math.max(@_x, p._x), Math.max(@_y, p._y))
  
    toString: ->
      "(" + @_x + ", " + @_y + ")"
  
  class CSG.Vector3D
    # # class Vector3D
    # Represents a 3D vector.
    # 
    # Example usage:
    # 
    #     new CSG.Vector3D(1, 2, 3);
    #     new CSG.Vector3D([1, 2, 3]);
    #     new CSG.Vector3D({ x: 1, y: 2, z: 3 });
    #     new CSG.Vector3D(1, 2); // assumes z=0
    #     new CSG.Vector3D([1, 2]); // assumes z=0
    constructor: (x, y, z) ->
      if arguments_.length is 3
        @_x = parseFloat(x)
        @_y = parseFloat(y)
        @_z = parseFloat(z)
      else if arguments_.length is 2
        @_x = parseFloat(x)
        @_y = parseFloat(y)
        @_z = 0
      else
        ok = true
        if arguments_.length is 1
          if typeof (x) is "object"
            if x instanceof CSG.Vector3D
              @_x = x._x
              @_y = x._y
              @_z = x._z
            else if x instanceof CSG.Vector2D
              @_x = x._x
              @_y = x._y
              @_z = 0
            else if x instanceof Array
              if (x.length < 2) or (x.length > 3)
                ok = false
              else
                @_x = parseFloat(x[0])
                @_y = parseFloat(x[1])
                if x.length is 3
                  @_z = parseFloat(x[2])
                else
                  @_z = 0
            else if ("x" of x) and ("y" of x)
              @_x = parseFloat(x.x)
              @_y = parseFloat(x.y)
              if "z" of x
                @_z = parseFloat(x.z)
              else
                @_z = 0
            else
              ok = false
          else
            v = parseFloat(x)
            @_x = v
            @_y = v
            @_z = v
        else
          ok = false
        ok = false  if (not CSG.IsFloat(@_x)) or (not CSG.IsFloat(@_y)) or (not CSG.IsFloat(@_z))  if ok
        throw new Error("wrong arguments")  unless ok
        
        #getters setters
        @property 'x',
          get: -> return this._x
          set: (v) -> throw new Error("Vector3D is immutable")
        
        @property 'y',
          get: -> return this._y
          set: (v) -> throw new Error("Vector3D is immutable")
          
        @property 'z',
          get: -> return this._z
          set: (v) -> throw new Error("Vector3D is immutable")
       
    clone: ->
      new CSG.Vector3D(this)
  
    negated: ->
      new CSG.Vector3D(-@_x, -@_y, -@_z)
  
    abs: ->
      new CSG.Vector3D(Math.abs(@_x), Math.abs(@_y), Math.abs(@_z))
  
    plus: (a) ->
      new CSG.Vector3D(@_x + a._x, @_y + a._y, @_z + a._z)
  
    minus: (a) ->
      new CSG.Vector3D(@_x - a._x, @_y - a._y, @_z - a._z)
  
    times: (a) ->
      new CSG.Vector3D(@_x * a, @_y * a, @_z * a)
  
    dividedBy: (a) ->
      new CSG.Vector3D(@_x / a, @_y / a, @_z / a)
  
    dot: (a) ->
      @_x * a._x + @_y * a._y + @_z * a._z
  
    lerp: (a, t) ->
      @plus a.minus(this).times(t)
  
    lengthSquared: ->
      @dot this
  
    length: ->
      Math.sqrt @lengthSquared()
  
    unit: ->
      @dividedBy @length()
  
    cross: (a) ->
      new CSG.Vector3D(@_y * a._z - @_z * a._y, @_z * a._x - @_x * a._z, @_x * a._y - @_y * a._x)
  
    distanceTo: (a) ->
      @minus(a).length()
  
    distanceToSquared: (a) ->
      @minus(a).lengthSquared()
  
    equals: (a) ->
      (@_x is a._x) and (@_y is a._y) and (@_z is a._z)
  
    multiply4x4: (matrix4x4) ->
      # Right multiply by a 4x4 matrix (the vector is interpreted as a row vector)
      # Returns a new CSG.Vector3D
      matrix4x4.leftMultiply1x3Vector this
  
    transform: (matrix4x4) ->
      matrix4x4.leftMultiply1x3Vector this
  
    toStlString: ->
      @_x + " " + @_y + " " + @_z
  
    toString: ->
      "(" + @_x + ", " + @_y + ", " + @_z + ")"
  
    randomNonParallelVector: ->
      # find a vector that is somewhat perpendicular to this one
      abs = @abs()
      if (abs._x <= abs._y) and (abs._x <= abs._z)
        new CSG.Vector3D(1, 0, 0)
      else if (abs._y <= abs._x) and (abs._y <= abs._z)
        new CSG.Vector3D(0, 1, 0)
      else
        new CSG.Vector3D(0, 0, 1)
  
    min: (p) ->
      new CSG.Vector3D(Math.min(@_x, p._x), Math.min(@_y, p._y), Math.min(@_z, p._z))
  
    max: (p) ->
      new CSG.Vector3D(Math.max(@_x, p._x), Math.max(@_y, p._y), Math.max(@_z, p._z))
  
  class CSG.Vertex 
    # # class Vertex
    # Represents a vertex of a polygon. Use your own vertex class instead of this
    # one to provide additional features like texture coordinates and vertex
    # colors. Custom vertex classes need to provide a `pos` property
    # `flipped()`, and `interpolate()` methods that behave analogous to the ones
    # defined by `CSG.Vertex`.
    constructor: (pos) ->
      @pos = pos
  
    @fromObject : (obj) ->
      # create from an untyped object with identical property names:
      pos = new CSG.Vector3D(obj.pos)
      new CSG.Vertex(pos)
      
    flipped: ->
      # Return a vertex with all orientation-specific data (e.g. vertex normal) flipped. Called when the
      # orientation of a polygon is flipped.
      this
  
    getTag: ->
      result = @tag
      unless result
        result = CSG.getTag()
        @tag = result
      result
    
    interpolate: (other, t) ->
      # Create a new vertex between this vertex and `other` by linearly
      # interpolating all properties using a parameter of `t`. Subclasses should
      # override this to interpolate additional properties.
      newpos = @pos.lerp(other.pos, t)
      new CSG.Vertex(newpos)
  
    transform: (matrix4x4) ->
      # Affine transformation of vertex. Returns a new CSG.Vertex
      newpos = @pos.multiply4x4(matrix4x4)
      new CSG.Vertex(newpos)
  
    toStlString: ->
      "vertex " + @pos.toStlString() + "\n"
  
    toString: ->
      @pos.toString()
      
  class CSG.Line2D 
    # Represents a directional line in 2D space
    # A line is parametrized by its normal vector (perpendicular to the line, rotated 90 degrees counter clockwise)
    # and w. The line passes through the point <normal>.times(w).
    # normal must be a unit vector!
    # Equation: p is on line if normal.dot(p)==w
    constructor: (normal, w) ->
      normal = new CSG.Vector2D(normal)
      w = parseFloat(w)
      l = normal.length()
      
      # normalize:
      w *= l
      normal = normal.times(1.0 / l)
      @normal = normal
      @w = w
  
    @fromPoints = (p1, p2) ->
      p1 = new CSG.Vector2D(p1)
      p2 = new CSG.Vector2D(p2)
      direction = p2.minus(p1)
      normal = direction.normal().negated().unit()
      w = p1.dot(normal)
      new CSG.Line2D(normal, w)
  
    reverse: ->
      # same line but opposite direction:
      new CSG.Line2D(@normal.negated(), -@w)
  
    equals: (l) ->
      l.normal.equals(@normal) and (l.w is @w)
  
    origin: ->
      @normal.times @w
  
    direction: ->
      @normal.normal()
  
    xAtY: (y) ->
      # (py == y) && (normal * p == w)
      # -> px = (w - normal._y * y) / normal.x
      x = (@w - @normal._y * y) / @normal.x
      x
  
    absDistanceToPoint: (point) ->
      point = new CSG.Vector2D(point)
      point_projected = point.dot(@normal)
      distance = Math.abs(point_projected - @w)
      distance
  
    closestPoint: (point) ->
      point = new CSG.Vector2D(point)
      vector = point.dot(@direction())
      origin.plus vector
    
    intersectWithLine: (line2d) ->
      # intersection between two lines, returns point as Vector2D
      point = CSG.solve2Linear(@normal.x, @normal.y, line2d.normal.x, line2d.normal.y, @w, line2d.w)
      point = new CSG.Vector2D(point) 
      point
  
    transform: (matrix4x4) ->
      origin = new CSG.Vector2D(0, 0)
      pointOnPlane = @normal.times(@w)
      neworigin = origin.multiply4x4(matrix4x4)
      neworiginPlusNormal = @normal.multiply4x4(matrix4x4)
      newnormal = neworiginPlusNormal.minus(neworigin)
      newpointOnPlane = pointOnPlane.multiply4x4(matrix4x4)
      neww = newnormal.dot(newpointOnPlane)
      new CSG.Line2D(newnormal, neww)
  
  
  
  class  CSG.Line3D 
    # Represents a line in 3D space
    # direction must be a unit vector 
    # point is a random point on the line
    constructor: (point, direction) ->
      point = new CSG.Vector3D(point)
      direction = new CSG.Vector3D(direction)
      @point = point
      @direction = direction.unit()
  
    @fromPoints = (p1, p2) ->
      p1 = new CSG.Vector3D(p1)
      p2 = new CSG.Vector3D(p2)
      direction = p2.minus(p1).unit()
      new CSG.Line3D(p1, direction)
    
    @fromPlanes = (p1, p2) ->
      direction = p1.normal.cross(p2.normal)
      l = direction.length()
      throw new Error("Parallel planes")  if l < 1e-10
      direction = direction.times(1.0 / l)
      mabsx = Math.abs(direction.x)
      mabsy = Math.abs(direction.y)
      mabsz = Math.abs(direction.z)
      origin = undefined
      if (mabsx >= mabsy) and (mabsx >= mabsz)
        
        # direction vector is mostly pointing towards x
        # find a point p for which x is zero:
        r = CSG.solve2Linear(p1.normal.y, p1.normal.z, p2.normal.y, p2.normal.z, p1.w, p2.w)
        origin = new CSG.Vector3D(0, r[0], r[1])
      else if (mabsy >= mabsx) and (mabsy >= mabsz)
        
        # find a point p for which y is zero:
        r = CSG.solve2Linear(p1.normal.x, p1.normal.z, p2.normal.x, p2.normal.z, p1.w, p2.w)
        origin = new CSG.Vector3D(r[0], 0, r[1])
      else
        
        # find a point p for which z is zero:
        r = CSG.solve2Linear(p1.normal.x, p1.normal.y, p2.normal.x, p2.normal.y, p1.w, p2.w)
        origin = new CSG.Vector3D(r[0], r[1], 0)
      new CSG.Line3D(origin, direction)
  
    intersectWithPlane: (plane) ->
      # plane: plane.normal * p = plane.w
      # line: p=line.point + labda * line.direction
      labda = (plane.w - plane.normal.dot(@point)) / plane.normal.dot(@direction)
      point = @point.plus(@direction.times(labda))
      point
  
    clone: (line) ->
      new CSG.Line3D(@point.clone(), @direction.clone())
  
    reverse: ->
      new CSG.Line3D(@point.clone(), @direction.negated())
  
    transform: (matrix4x4) ->
      newpoint = @point.multiply4x4(matrix4x4)
      pointPlusDirection = @point.plus(@direction)
      newPointPlusDirection = pointPlusDirection.multiply4x4(matrix4x4)
      newdirection = newPointPlusDirection.minus(newpoint)
      new CSG.Line3D(newpoint, newdirection)
  
    closestPointOnLine: (point) ->
      point = new CSG.Vector3D(point)
      t = point.minus(@point).dot(@direction) / @direction.dot(@direction)
      closestpoint = @point.plus(@direction.times(t))
      closestpoint
  
    distanceToPoint: (point) ->
      point = new CSG.Vector3D(point)
      closestpoint = @closestPointOnLine(point)
      distancevector = point.minus(closestpoint)
      distance = distancevector.length()
      distance
  
    equals: (line3d) ->
      return false  unless @direction.equals(line3d.direction)
      distance = @distanceToPoint(line3d.point)
      return false  if distance > 1e-8
      true
  
  class CSG.Plane
    # # class Plane
    # Represents a plane in 3D space.
    @EPSILON : 1e-5
    # `CSG.Plane.EPSILON` is the tolerance used by `splitPolygon()` to decide if a
    # point is on the plane.
    constructor: (normal, w) ->
      @normal = normal
      @w = w
  
    # create from an untyped object with identical property names:
    @fromObject : (obj) ->
      normal = new CSG.Vector3D(obj.normal)
      w = parseFloat(obj.w)
      new CSG.Plane(normal, w)
  
    @fromVector3Ds : (a, b, c) ->
      #console.log("here")
      #  console.log(a);
      #  console.log(b);
      #  console.log(c);
      n = b.minus(a).cross(c.minus(a)).unit()
      new CSG.Plane(n, n.dot(a))
  
    @anyPlaneFromVector3Ds : (a, b, c) ->
      # like fromVector3Ds, but allow the vectors to be on one point or one line
      # in such a case a random plane through the given points is constructed
      v1 = b.minus(a)
      v2 = c.minus(a)
      v1 = v2.randomNonParallelVector()  if v1.length() < 1e-5
      v2 = v1.randomNonParallelVector()  if v2.length() < 1e-5
      normal = v1.cross(v2)
      if normal.length() < 1e-5
        
        # this would mean that v1 == v2.negated()
        v2 = v1.randomNonParallelVector()
        normal = v1.cross(v2)
      normal = normal.unit()
      new CSG.Plane(normal, normal.dot(a))
  
    @fromPoints : (a, b, c) ->
      a = new CSG.Vector3D(a)
      b = new CSG.Vector3D(b)
      c = new CSG.Vector3D(c)
      CSG.Plane.fromVector3Ds a, b, c
  
    @fromNormalAndPoint : (normal, point) ->
      normal = new CSG.Vector3D(normal)
      point = new CSG.Vector3D(point)
      normal = normal.unit()
      w = point.dot(normal)
      new CSG.Plane(normal, w)
  
    flipped: ->
      new CSG.Plane(@normal.negated(), -@w)
  
    getTag: ->
      result = @tag
      unless result
        result = CSG.getTag()
        @tag = result
      result
  
    equals: (n) ->
      @normal.equals(n.normal) and @w is n.w
  
    transform: (matrix4x4) ->
      ismirror = matrix4x4.isMirroring()
      
      # get two vectors in the plane:
      r = @normal.randomNonParallelVector()
      u = @normal.cross(r)
      v = @normal.cross(u)
      
      # get 3 points in the plane:
      point1 = @normal.times(@w)
      point2 = point1.plus(u)
      point3 = point1.plus(v)
      
      # transform the points:
      point1 = point1.multiply4x4(matrix4x4)
      point2 = point2.multiply4x4(matrix4x4)
      point3 = point3.multiply4x4(matrix4x4)
      
      # and create a new plane from the transformed points:
      newplane = CSG.Plane.fromVector3Ds(point1, point2, point3)
      
      # the transform is mirroring
      # We should mirror the plane:
      newplane = newplane.flipped()  if ismirror
      newplane
  
    splitPolygon: (polygon) ->
      # Returns object:
      # .type:
      #   0: coplanar-front
      #   1: coplanar-back
      #   2: front
      #   3: back
      #   4: spanning
      # In case the polygon is spanning, returns:
      # .front: a CSG.Polygon of the front part 
      # .back: a CSG.Polygon of the back part 
      result =
        type: null
        front: null
        back: null
  
      
      # cache in local vars (speedup):
      planenormal = @normal
      vertices = polygon.vertices
      numvertices = vertices.length
      if polygon.plane.equals(this)
        result.type = 0
      else
        EPS = @EPSILON
        thisw = @w
        hasfront = false
        hasback = false
        vertexIsBack = []
        MINEPS = -EPS
        i = 0
  
        while i < numvertices
          t = planenormal.dot(vertices[i].pos) - thisw
          isback = (t < 0)
          vertexIsBack.push isback
          hasfront = true  if t > EPS
          hasback = true  if t < MINEPS
          i++
        if (not hasfront) and (not hasback)
          
          # all points coplanar
          t = planenormal.dot(polygon.plane.normal)
          result.type = (if (t >= 0) then 0 else 1)
        else unless hasback
          result.type = 2
        else unless hasfront
          result.type = 3
        else
          
          # spanning
          result.type = 4
          frontvertices = []
          backvertices = []
          isback = vertexIsBack[0]
          vertexindex = 0
  
          while vertexindex < numvertices
            vertex = vertices[vertexindex]
            nextvertexindex = vertexindex + 1
            nextvertexindex = 0  if nextvertexindex >= numvertices
            nextisback = vertexIsBack[nextvertexindex]
            if isback is nextisback
              
              # line segment is on one side of the plane:
              if isback
                backvertices.push vertex
              else
                frontvertices.push vertex
            else
              
              # line segment intersects plane:
              point = vertex.pos
              nextpoint = vertices[nextvertexindex].pos
              intersectionpoint = @splitLineBetweenPoints(point, nextpoint)
              intersectionvertex = new CSG.Vertex(intersectionpoint)
              if isback
                backvertices.push vertex
                backvertices.push intersectionvertex
                frontvertices.push intersectionvertex
              else
                frontvertices.push vertex
                frontvertices.push intersectionvertex
                backvertices.push intersectionvertex
            isback = nextisback
            vertexindex++
          # for vertexindex
          
          # remove duplicate vertices:
          EPS_SQUARED = @EPSILON * @EPSILON
          if backvertices.length >= 3
            prevvertex = backvertices[backvertices.length - 1]
            vertexindex = 0
  
            while vertexindex < backvertices.length
              vertex = backvertices[vertexindex]
              if vertex.pos.distanceToSquared(prevvertex.pos) < EPS_SQUARED
                backvertices.splice vertexindex, 1
                vertexindex--
              prevvertex = vertex
              vertexindex++
          if frontvertices.length >= 3
            prevvertex = frontvertices[frontvertices.length - 1]
            vertexindex = 0
  
            while vertexindex < frontvertices.length
              vertex = frontvertices[vertexindex]
              if vertex.pos.distanceToSquared(prevvertex.pos) < EPS_SQUARED
                frontvertices.splice vertexindex, 1
                vertexindex--
              prevvertex = vertex
              vertexindex++
          result.front = new CSG.Polygon(frontvertices, polygon.shared, polygon.plane)  if frontvertices.length >= 3
          result.back = new CSG.Polygon(backvertices, polygon.shared, polygon.plane)  if backvertices.length >= 3
      result
  
    splitLineBetweenPoints: (p1, p2) ->
      # robust splitting of a line by a plane
      # will work even if the line is parallel to the plane  
      direction = p2.minus(p1)
      labda = (@w - @normal.dot(p1)) / @normal.dot(direction)
      labda = 0  if isNaN(labda)
      labda = 1  if labda > 1
      labda = 0  if labda < 0
      result = p1.plus(direction.times(labda))
      result
  
    intersectWithLine: (line3d) ->
      # returns CSG.Vector3D
      line3d.intersectWithPlane this
    
    intersectWithPlane: (plane) ->
      # intersection of two planes
      CSG.Line3D.fromPlanes this, plane
  
    signedDistanceToPoint: (point) ->
      t = @normal.dot(point) - @w
      t
  
    toString: ->
      "[normal: " + @normal.toString() + ", w: " + @w + "]"
  
    mirrorPoint: (point3d) ->
      distance = @signedDistanceToPoint(point3d)
      mirrored = point3d.minus(@normal.times(distance * 2.0))
      mirrored
  
  class CSG.Polygon
    #class Polygon
    # Represents a convex polygon. The vertices used to initialize a polygon must
    # be coplanar and form a convex loop. They do not have to be `CSG.Vertex`
    # instances but they must behave similarly (duck typing can be used for
    # customization).
    # 
    # Each convex polygon has a `shared` property, which is shared between all
    # polygons that are clones of each other or were split from the same polygon.
    # This can be used to define per-polygon properties (such as surface color).
    # 
    # The plane of the polygon is calculated from the vertex coordinates
    # To avoid unnecessary recalculation, the plane can alternatively be
    # passed as the third argument 
    constructor : (vertices, shared, plane) ->
      @vertices = vertices
      shared = CSG.Polygon.defaultShared  unless shared
      @shared = shared
      numvertices = vertices.length
      if arguments_.length >= 3
        @plane = plane
      else
        @plane = CSG.Plane.fromVector3Ds(vertices[0].pos, vertices[1].pos, vertices[2].pos)
      @checkIfConvex()  if _CSGDEBUG
  
    @fromObject : (obj) ->
      # create from an untyped object with identical property names:
      vertices = obj.vertices.map((v) ->
        CSG.Vertex.fromObject v
      )
      shared = CSG.Polygon.Shared.fromObject(obj.shared)
      plane = CSG.Plane.fromObject(obj.plane)
      new CSG.Polygon(vertices, shared, plane)
  
    checkIfConvex: ->
      # check whether the polygon is convex (it should be, otherwise we will get unexpected results)
      unless CSG.Polygon.verticesConvex(@vertices, @plane.normal)
        CSG.Polygon.verticesConvex @vertices, @plane.normal
        throw new Error("Not convex!")
  
    extrude: (offsetvector) ->
      # Extrude a polygon into the direction offsetvector
      # Returns a CSG object
      newpolygons = []
      polygon1 = this
      direction = polygon1.plane.normal.dot(offsetvector)
      polygon1 = polygon1.flipped()  if direction > 0
      newpolygons.push polygon1
      polygon2 = polygon1.translate(offsetvector)
      numvertices = @vertices.length
      i = 0
  
      while i < numvertices
        sidefacepoints = []
        nexti = (if (i < (numvertices - 1)) then i + 1 else 0)
        sidefacepoints.push polygon1.vertices[i].pos
        sidefacepoints.push polygon2.vertices[i].pos
        sidefacepoints.push polygon2.vertices[nexti].pos
        sidefacepoints.push polygon1.vertices[nexti].pos
        sidefacepolygon = CSG.Polygon.createFromPoints(sidefacepoints, @shared)
        newpolygons.push sidefacepolygon
        i++
      polygon2 = polygon2.flipped()
      newpolygons.push polygon2
      CSG.fromPolygons newpolygons
  
    translate: (offset) ->
      @transform CSG.Matrix4x4.translation(offset)
    
    boundingSphere: ->
      # returns an array with a CSG.Vector3D (center point) and a radius
      unless @cachedBoundingSphere
        box = @boundingBox()
        middle = box[0].plus(box[1]).times(0.5)
        radius3 = box[1].minus(middle)
        radius = radius3.length()
        @cachedBoundingSphere = [middle, radius]
      @cachedBoundingSphere
  
    boundingBox: ->
      # returns an array of two CSG.Vector3Ds (minimum coordinates and maximum coordinates)
      unless @cachedBoundingBox
        minpoint = undefined
        maxpoint = undefined
        vertices = @vertices
        numvertices = vertices.length
        if numvertices is 0
          minpoint = new CSG.Vector3D(0, 0, 0)
        else
          minpoint = vertices[0].pos
        maxpoint = minpoint
        i = 1
  
        while i < numvertices
          point = vertices[i].pos
          minpoint = minpoint.min(point)
          maxpoint = maxpoint.max(point)
          i++
        @cachedBoundingBox = [minpoint, maxpoint]
      @cachedBoundingBox
  
    flipped: ->
      newvertices = @vertices.map((v) ->
        v.flipped()
      )
      newvertices.reverse()
      newplane = @plane.flipped()
      new CSG.Polygon(newvertices, @shared, newplane)
  
    transform: (matrix4x4) ->
      # Affine transformation of polygon. Returns a new CSG.Polygon
      newvertices = @vertices.map((v) ->
        v.transform matrix4x4
      )
      newplane = @plane.transform(matrix4x4)
      scalefactor = matrix4x4.elements[0] * matrix4x4.elements[5] * matrix4x4.elements[10]
      
      # the transformation includes mirroring. We need to reverse the vertex order
      # in order to preserve the inside/outside orientation:
      newvertices.reverse()  if scalefactor < 0
      new CSG.Polygon(newvertices, @shared, newplane)
  
    toStlString: ->
      result = ""
      if @vertices.length >= 3 # should be!
        
        # STL requires triangular polygons. If our polygon has more vertices, create
        # multiple triangles:
        firstVertexStl = @vertices[0].toStlString()
        i = 0
  
        while i < @vertices.length - 2
          result += "facet normal " + @plane.normal.toStlString() + "\nouter loop\n"
          result += firstVertexStl
          result += @vertices[i + 1].toStlString()
          result += @vertices[i + 2].toStlString()
          result += "endloop\nendfacet\n"
          i++
      result
  
    toString: ->
      result = "Polygon plane: " + @plane.toString() + "\n"
      @vertices.map (vertex) ->
        result += "  " + vertex.toString() + "\n"
  
      result
    
    projectToOrthoNormalBasis: (orthobasis) ->
      # project the 3D polygon onto a plane
      points2d = @vertices.map((vertex) ->
        orthobasis.to2D vertex.pos
      )
      result = CAG.fromPointsNoCheck(points2d)
      area = result.area()
      if Math.abs(area) < 1e-5
        
        # the polygon was perpendicular to the orthnormal plane. The resulting 2D polygon would be degenerate 
        # return an empty area instead:
        result = new CAG()
      else result = result.flipped()  if area < 0
      result
  
    @verticesConvex : (vertices, planenormal) ->
      numvertices = vertices.length
      if numvertices > 2
        prevprevpos = vertices[numvertices - 2].pos
        prevpos = vertices[numvertices - 1].pos
        i = 0
    
        while i < numvertices
          pos = vertices[i].pos
          return false  unless CSG.Polygon.isConvexPoint(prevprevpos, prevpos, pos, planenormal)
          prevprevpos = prevpos
          prevpos = pos
          i++
      true
  
    @createFromPoints : (points, shared, plane) ->
      # Create a polygon from the given points
      normal = undefined
      if arguments_.length < 3
        
        # initially set a dummy vertex normal:
        normal = new CSG.Vector3D(0, 0, 0)
      else
        normal = plane.normal
      vertices = []
      points.map (p) ->
        vec = new CSG.Vector3D(p)
        vertex = new CSG.Vertex(vec)
        vertices.push vertex
    
      polygon = undefined
      if arguments_.length < 3
        polygon = new CSG.Polygon(vertices, shared)
      else
        polygon = new CSG.Polygon(vertices, shared, plane)
      polygon
  
    @isConvexPoint : (prevpoint, point, nextpoint, normal) ->
      # calculate whether three points form a convex corner 
      #  prevpoint, point, nextpoint: the 3 coordinates (CSG.Vector3D instances)
      #  normal: the normal vector of the plane
      crossproduct = point.minus(prevpoint).cross(nextpoint.minus(point))
      crossdotnormal = crossproduct.dot(normal)
      crossdotnormal >= 0
  
    @isStrictlyConvexPoint : (prevpoint, point, nextpoint, normal) ->
      crossproduct = point.minus(prevpoint).cross(nextpoint.minus(point))
      crossdotnormal = crossproduct.dot(normal)
      crossdotnormal >= 1e-5
    
  
  class CSG.Polygon.Shared
    # Holds the shared properties for each polygon (currently only color)
    constructor:(color, name) ->
      @color = color
      @name = name
  
    @fromObject : (obj) ->
      new CSG.Polygon.Shared(obj.color, obj.name)
  
    getTag: ->
      result = @tag
      unless result
        result = CSG.getTag()
        @tag = result
      result
    
    # get a string uniquely identifying this object
    getHash: ->
      return "null"  unless @color
      "" + @color[0] + "/" + @color[1] + "/" + @color[2]
    
    # get this object's name
    getName: ->
      return "null"  unless @name
      @name
  
  CSG.Polygon.defaultShared = new CSG.Polygon.Shared(null, null)
  
  
  class CSG.Path2D 
    constructor: (points, closed) ->
      closed = !!closed
      points = points or []
      # re-parse the points into CSG.Vector2D
      # and remove any duplicate points
      prevpoint = null
      prevpoint = new CSG.Vector2D(points[points.length - 1])  if closed and (points.length > 0)
      newpoints = []
      points.map (point) ->
        point = new CSG.Vector2D(point)
        skip = false
        if prevpoint isnt null
          distance = point.distanceTo(prevpoint)
          skip = distance < 1e-5
        newpoints.push point  unless skip
        prevpoint = point
    
      @points = newpoints
      @closed = closed
  
    @arc : (options) ->
      #
      #Construct a (part of a) circle. Parameters:
      #  options.center: the center point of the arc (CSG.Vector2D or array [x,y])
      #  options.radius: the circle radius (float)
      #  options.startangle: the starting angle of the arc, in degrees
      #    0 degrees corresponds to [1,0]
      #    90 degrees to [0,1]
      #    and so on
      #  options.endangle: the ending angle of the arc, in degrees
      #  options.resolution: number of points per 360 degree of rotation
      #  options.maketangent: adds two extra tiny line segments at both ends of the circle
      #    this ensures that the gradients at the edges are tangent to the circle
      #Returns a CSG.Path2D. The path is not closed (even if it is a 360 degree arc).
      #close() the resultin path if you want to create a true circle.    
      #
      center = CSG.parseOptionAs2DVector(options, "center", 0)
      radius = CSG.parseOptionAsFloat(options, "radius", 1)
      startangle = CSG.parseOptionAsFloat(options, "startangle", 0)
      endangle = CSG.parseOptionAsFloat(options, "endangle", 360)
      resolution = CSG.parseOptionAsFloat(options, "resolution", CSG.defaultResolution2D)
      maketangent = CSG.parseOptionAsBool(options, "maketangent", false)
      
      # no need to make multiple turns:
      endangle -= 360  while endangle - startangle >= 720
      endangle += 360  while endangle - startangle <= -720
      points = []
      absangledif = Math.abs(endangle - startangle)
      if absangledif < 1e-5
        point = CSG.Vector2D.fromAngle(startangle / 180.0 * Math.PI).times(radius)
        points.push point.plus(center)
      else
        numsteps = Math.floor(resolution * absangledif / 360) + 1
        edgestepsize = numsteps * 0.5 / absangledif # step size for half a degree
        edgestepsize = 0.25  if edgestepsize > 0.25
        numsteps_mod = (if maketangent then (numsteps + 2) else numsteps)
        i = 0
    
        while i <= numsteps_mod
          step = i
          if maketangent
            step = (i - 1) * (numsteps - 2 * edgestepsize) / numsteps + edgestepsize
            step = 0  if step < 0
            step = numsteps  if step > numsteps
          angle = startangle + step * (endangle - startangle) / numsteps
          point = CSG.Vector2D.fromAngle(angle / 180.0 * Math.PI).times(radius)
          points.push point.plus(center)
          i++
      new CSG.Path2D(points, false)
  
    concat: (otherpath) ->
      throw new Error("Paths must not be closed")  if @closed or otherpath.closed
      newpoints = @points.concat(otherpath.points)
      new CSG.Path2D(newpoints)
  
    appendPoint: (point) ->
      throw new Error("Paths must not be closed")  if @closed
      newpoints = @points.concat([point])
      new CSG.Path2D(newpoints)
  
    close: ->
      new CSG.Path2D(@points, true)
  
    rectangularExtrude: (width, height, resolution) ->
      # Extrude the path by following it with a rectangle (upright, perpendicular to the path direction)
      # Returns a CSG solid
      #   width: width of the extrusion, in the z=0 plane
      #   height: height of the extrusion in the z direction
      #   resolution: number of segments per 360 degrees for the curve in a corner
      cag = @expandToCAG(width / 2, resolution)
      result = cag.extrude(offset: [0, 0, height])
      result
    
    expandToCAG: (pathradius, resolution) ->
      # Expand the path to a CAG
      # This traces the path with a circle with radius pathradius
      sides = []
      numpoints = @points.length
      startindex = 0
      startindex = -1  if @closed and (numpoints > 2)
      prevvertex = undefined
      i = startindex
  
      while i < numpoints
        pointindex = i
        pointindex = numpoints - 1  if pointindex < 0
        point = @points[pointindex]
        vertex = new CAG.Vertex(point)
        if i > startindex
          side = new CAG.Side(prevvertex, vertex)
          sides.push side
        prevvertex = vertex
        i++
      shellcag = CAG.fromSides(sides)
      expanded = shellcag.expandedShell(pathradius, resolution)
      expanded
  
    innerToCAG: ->
      throw new Error("The path should be closed!")  unless @closed
      CAG.fromPoints @points
  
    transform: (matrix4x4) ->
      newpoints = @points.map((point) ->
        point.multiply4x4 matrix4x4
      )
      new CSG.Path2D(newpoints, @closed)
  
  class CSG.Matrix4x4
    # Represents a 4x4 matrix. Elements are specified in row order
    constructor: (elements) ->
      if arguments_.length >= 1
        @elements = elements
      else
        
        # if no arguments passed: create unity matrix  
        @elements = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
  
    plus: (m) ->
      r = []
      i = 0
  
      while i < 16
        r[i] = @elements[i] + m.elements[i]
        i++
      new CSG.Matrix4x4(r)
  
    minus: (m) ->
      r = []
      i = 0
  
      while i < 16
        r[i] = @elements[i] - m.elements[i]
        i++
      new CSG.Matrix4x4(r)
  
    multiply: (m) ->
      # right multiply by another 4x4 matrix:
      # cache elements in local variables, for speedup:
      this0 = @elements[0]
      this1 = @elements[1]
      this2 = @elements[2]
      this3 = @elements[3]
      this4 = @elements[4]
      this5 = @elements[5]
      this6 = @elements[6]
      this7 = @elements[7]
      this8 = @elements[8]
      this9 = @elements[9]
      this10 = @elements[10]
      this11 = @elements[11]
      this12 = @elements[12]
      this13 = @elements[13]
      this14 = @elements[14]
      this15 = @elements[15]
      m0 = m.elements[0]
      m1 = m.elements[1]
      m2 = m.elements[2]
      m3 = m.elements[3]
      m4 = m.elements[4]
      m5 = m.elements[5]
      m6 = m.elements[6]
      m7 = m.elements[7]
      m8 = m.elements[8]
      m9 = m.elements[9]
      m10 = m.elements[10]
      m11 = m.elements[11]
      m12 = m.elements[12]
      m13 = m.elements[13]
      m14 = m.elements[14]
      m15 = m.elements[15]
      result = []
      result[0] = this0 * m0 + this1 * m4 + this2 * m8 + this3 * m12
      result[1] = this0 * m1 + this1 * m5 + this2 * m9 + this3 * m13
      result[2] = this0 * m2 + this1 * m6 + this2 * m10 + this3 * m14
      result[3] = this0 * m3 + this1 * m7 + this2 * m11 + this3 * m15
      result[4] = this4 * m0 + this5 * m4 + this6 * m8 + this7 * m12
      result[5] = this4 * m1 + this5 * m5 + this6 * m9 + this7 * m13
      result[6] = this4 * m2 + this5 * m6 + this6 * m10 + this7 * m14
      result[7] = this4 * m3 + this5 * m7 + this6 * m11 + this7 * m15
      result[8] = this8 * m0 + this9 * m4 + this10 * m8 + this11 * m12
      result[9] = this8 * m1 + this9 * m5 + this10 * m9 + this11 * m13
      result[10] = this8 * m2 + this9 * m6 + this10 * m10 + this11 * m14
      result[11] = this8 * m3 + this9 * m7 + this10 * m11 + this11 * m15
      result[12] = this12 * m0 + this13 * m4 + this14 * m8 + this15 * m12
      result[13] = this12 * m1 + this13 * m5 + this14 * m9 + this15 * m13
      result[14] = this12 * m2 + this13 * m6 + this14 * m10 + this15 * m14
      result[15] = this12 * m3 + this13 * m7 + this14 * m11 + this15 * m15
      new CSG.Matrix4x4(result)
  
    clone: ->
      elements = @elements.map((p) ->
        p
      )
      new CSG.Matrix4x4(elements)
  
    rightMultiply1x3Vector: (v) ->
      # Right multiply the matrix by a CSG.Vector3D (interpreted as 3 row, 1 column)
      # (result = M*v)
      # Fourth element is taken as 1
      v0 = v._x
      v1 = v._y
      v2 = v._z
      v3 = 1
      x = v0 * @elements[0] + v1 * @elements[1] + v2 * @elements[2] + v3 * @elements[3]
      y = v0 * @elements[4] + v1 * @elements[5] + v2 * @elements[6] + v3 * @elements[7]
      z = v0 * @elements[8] + v1 * @elements[9] + v2 * @elements[10] + v3 * @elements[11]
      w = v0 * @elements[12] + v1 * @elements[13] + v2 * @elements[14] + v3 * @elements[15]
      
      # scale such that fourth element becomes 1:
      unless w is 1
        invw = 1.0 / w
        x *= invw
        y *= invw
        z *= invw
      new CSG.Vector3D(x, y, z)
  
    leftMultiply1x3Vector: (v) ->
      # Multiply a CSG.Vector3D (interpreted as 3 column, 1 row) by this matrix
      # (result = v*M)
      # Fourth element is taken as 1
      v0 = v._x
      v1 = v._y
      v2 = v._z
      v3 = 1
      x = v0 * @elements[0] + v1 * @elements[4] + v2 * @elements[8] + v3 * @elements[12]
      y = v0 * @elements[1] + v1 * @elements[5] + v2 * @elements[9] + v3 * @elements[13]
      z = v0 * @elements[2] + v1 * @elements[6] + v2 * @elements[10] + v3 * @elements[14]
      w = v0 * @elements[3] + v1 * @elements[7] + v2 * @elements[11] + v3 * @elements[15]
      
      # scale such that fourth element becomes 1:
      unless w is 1
        invw = 1.0 / w
        x *= invw
        y *= invw
        z *= invw
      new CSG.Vector3D(x, y, z)
  
    rightMultiply1x2Vector: (v) ->
      # Right multiply the matrix by a CSG.Vector2D (interpreted as 2 row, 1 column)
      # (result = M*v)
      # Fourth element is taken as 1
      v0 = v.x
      v1 = v.y
      v2 = 0
      v3 = 1
      x = v0 * @elements[0] + v1 * @elements[1] + v2 * @elements[2] + v3 * @elements[3]
      y = v0 * @elements[4] + v1 * @elements[5] + v2 * @elements[6] + v3 * @elements[7]
      z = v0 * @elements[8] + v1 * @elements[9] + v2 * @elements[10] + v3 * @elements[11]
      w = v0 * @elements[12] + v1 * @elements[13] + v2 * @elements[14] + v3 * @elements[15]
      
      # scale such that fourth element becomes 1:
      unless w is 1
        invw = 1.0 / w
        x *= invw
        y *= invw
        z *= invw
      new CSG.Vector2D(x, y)
  
    leftMultiply1x2Vector: (v) ->
      # Multiply a CSG.Vector2D (interpreted as 2 column, 1 row) by this matrix
      # (result = v*M)
      # Fourth element is taken as 1
      v0 = v.x
      v1 = v.y
      v2 = 0
      v3 = 1
      x = v0 * @elements[0] + v1 * @elements[4] + v2 * @elements[8] + v3 * @elements[12]
      y = v0 * @elements[1] + v1 * @elements[5] + v2 * @elements[9] + v3 * @elements[13]
      z = v0 * @elements[2] + v1 * @elements[6] + v2 * @elements[10] + v3 * @elements[14]
      w = v0 * @elements[3] + v1 * @elements[7] + v2 * @elements[11] + v3 * @elements[15]
      
      # scale such that fourth element becomes 1:
      unless w is 1
        invw = 1.0 / w
        x *= invw
        y *= invw
        z *= invw
      new CSG.Vector2D(x, y)
  
    isMirroring: ->
      # determine whether this matrix is a mirroring transformation
      u = new CSG.Vector3D(@elements[0], @elements[4], @elements[8])
      v = new CSG.Vector3D(@elements[1], @elements[5], @elements[9])
      w = new CSG.Vector3D(@elements[2], @elements[6], @elements[10])
      
      # for a true orthogonal, non-mirrored base, u.cross(v) == w
      # If they have an opposite direction then we are mirroring
      mirrorvalue = u.cross(v).dot(w)
      ismirror = (mirrorvalue < 0)
      ismirror
  
    @unity = ->
      # return the unity matrix
      new CSG.Matrix4x4()
  
    @rotationX = (degrees) ->
      # Create a rotation matrix for rotating around the x axis
      radians = degrees * Math.PI * (1.0 / 180.0)
      cos = Math.cos(radians)
      sin = Math.sin(radians)
      els = [1, 0, 0, 0, 0, cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1]
      new CSG.Matrix4x4(els)
  
  
    @rotationY = (degrees) ->
      # Create a rotation matrix for rotating around the y axis
      radians = degrees * Math.PI * (1.0 / 180.0)
      cos = Math.cos(radians)
      sin = Math.sin(radians)
      els = [cos, 0, -sin, 0, 0, 1, 0, 0, sin, 0, cos, 0, 0, 0, 0, 1]
      new CSG.Matrix4x4(els)
  
  
  
    @rotationZ = (degrees) ->
      # Create a rotation matrix for rotating around the z axis
      radians = degrees * Math.PI * (1.0 / 180.0)
      cos = Math.cos(radians)
      sin = Math.sin(radians)
      els = [cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
      new CSG.Matrix4x4(els)
  
  
    @rotation = (rotationCenter, rotationAxis, degrees) ->
      # Matrix for rotation about arbitrary point and axis
      rotationCenter = new CSG.Vector3D(rotationCenter)
      rotationAxis = new CSG.Vector3D(rotationAxis)
      rotationPlane = CSG.Plane.fromNormalAndPoint(rotationAxis, rotationCenter)
      orthobasis = new CSG.OrthoNormalBasis(rotationPlane)
      transformation = CSG.Matrix4x4.translation(rotationCenter.negated())
      transformation = transformation.multiply(orthobasis.getProjectionMatrix())
      transformation = transformation.multiply(CSG.Matrix4x4.rotationZ(degrees))
      transformation = transformation.multiply(orthobasis.getInverseProjectionMatrix())
      transformation = transformation.multiply(CSG.Matrix4x4.translation(rotationCenter))
      transformation
  
  
  
    @translation = (v) ->
      # Create an affine matrix for translation:
      
      # parse as CSG.Vector3D, so we can pass an array or a CSG.Vector3D
      vec = new CSG.Vector3D(v)
      els = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, vec.x, vec.y, vec.z, 1]
      new CSG.Matrix4x4(els)
  
  
    @mirroring = (plane) ->
      # Create an affine matrix for mirroring into an arbitrary plane:
      nx = plane.normal.x
      ny = plane.normal.y
      nz = plane.normal.z
      w = plane.w
      els = [(1.0 - 2.0 * nx * nx), (-2.0 * ny * nx), (-2.0 * nz * nx), 0, (-2.0 * nx * ny), (1.0 - 2.0 * ny * ny), (-2.0 * nz * ny), 0, (-2.0 * nx * nz), (-2.0 * ny * nz), (1.0 - 2.0 * nz * nz), 0, (-2.0 * nx * w), (-2.0 * ny * w), (-2.0 * nz * w), 1]
      new CSG.Matrix4x4(els)
  
    @scaling = (v) ->
      # Create an affine matrix for scaling:
      
      # parse as CSG.Vector3D, so we can pass an array or a CSG.Vector3D
      vec = new CSG.Vector3D(v)
      els = [vec.x, 0, 0, 0, 0, vec.y, 0, 0, 0, 0, vec.z, 0, 0, 0, 0, 1]
      new CSG.Matrix4x4(els)
  
  
  class CSG.OrthoNormalBasis 
    # Reprojects points on a 3D plane onto a 2D plane
    # or from a 2D plane back onto the 3D plane
    constructor: (plane, rightvector) ->
      if arguments_.length < 2
        
        # choose an arbitrary right hand vector, making sure it is somewhat orthogonal to the plane normal:
        rightvector = plane.normal.randomNonParallelVector()
      else
        rightvector = new CSG.Vector3D(rightvector)
      @v = plane.normal.cross(rightvector).unit()
      @u = @v.cross(plane.normal)
      @plane = plane
      @planeorigin = plane.normal.times(plane.w)
  
    @Z0Plane = ->
      # The z=0 plane, with the 3D x and y vectors mapped to the 2D x and y vector
      plane = new CSG.Plane(new CSG.Vector3D([0, 0, 1]), 0)
      new CSG.OrthoNormalBasis(plane, new CSG.Vector3D([1, 0, 0]))
  
    getProjectionMatrix: ->
      new CSG.Matrix4x4([@u.x, @v.x, @plane.normal.x, 0, @u.y, @v.y, @plane.normal.y, 0, @u.z, @v.z, @plane.normal.z, 0, 0, 0, -@plane.w, 1])
  
    getInverseProjectionMatrix: ->
      p = @plane.normal.times(@plane.w)
      new CSG.Matrix4x4([@u.x, @u.y, @u.z, 0, @v.x, @v.y, @v.z, 0, @plane.normal.x, @plane.normal.y, @plane.normal.z, 0, p.x, p.y, p.z, 1])
  
    to2D: (vec3) ->
      new CSG.Vector2D(vec3.dot(@u), vec3.dot(@v))
  
    to3D: (vec2) ->
      @planeorigin.plus(@u.times(vec2.x)).plus @v.times(vec2.y)
  
    line3Dto2D: (line3d) ->
      a = line3d.point
      b = line3d.direction.plus(a)
      a2d = @to2D(a)
      b2d = @to2D(b)
      CSG.Line2D.fromPoints a2d, b2d
  
    line2Dto3D: (line2d) ->
      a = line2d.origin()
      b = line2d.direction().plus(a)
      a3d = @to3D(a)
      b3d = @to3D(b)
      CSG.Line3D.fromPoints a3d, b3d
  
    transform: (matrix4x4) ->
      # todo: this may not work properly in case of mirroring
      newplane = @plane.transform(matrix4x4)
      rightpoint_transformed = @u.transform(matrix4x4)
      origin_transformed = new CSG.Vector3D(0, 0, 0).transform(matrix4x4)
      newrighthandvector = rightpoint_transformed.minus(origin_transformed)
      newbasis = new CSG.OrthoNormalBasis(newplane, newrighthandvector)
      newbasis
  
  return {
    "CSG":
      "Vector2D": CSG.Vector2D
      "Vector3D": CSG.Vector3D
      "Vertex": CSG.Vertex
      "Line2D": CSG.Line2D
      "Line3D": CSG.Line3D
      "Plane": CSG.Plane
      "Polygon": CSG.Polygon
      "Shared": CSG.Shared
      "Path2D": CSG.Path2D
      "Matrix4x4": CSG.Path2D
      "OrthoNormalBasis": CSG.OrthoNormalBasis
  }
