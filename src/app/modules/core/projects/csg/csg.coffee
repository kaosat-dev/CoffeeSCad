define (require)->
  CSG = {}
  TransformBase = require './transformBase'
  
  maths = require './csg.maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex2D
  Vector3D = maths.Vector3D
  Polygon = maths.Polygon
  PolygonShared = maths.PolygonShared
  Vector2D = maths.Vector2D
  Side = maths.Side
  
  props = require './csg.props'
  Properties = props.CSG.Properties
  
  trees= require './csg.trees'
  Tree = trees.Tree
  
  utils= require './csg.utils'
  reTesselateCoplanarPolygons = utils.reTesselateCoplanarPolygons
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAs3DVector = utils.parseOptionAs3DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  FuzzyCSGFactory = utils.FuzzyCSGFactory
  FuzzyCAGFactory = utils.FuzzyCAGFactory
  
  globals = require './csg.globals'
  _CSGDEBUG = globals._CSGDEBUG
  
  #FIXME: ensure that all operations that MIGHT change the bounding box , invalidate or recompute the bounding box
  
  class CSGBase extends TransformBase
    @defaultResolution2D : 32
    @defaultResolution3D : 12
    
    constructor:(options)->
      super options
      @polygons = []
      @properties = new Properties()
      @isCanonicalized = true
      @isRetesselated = true
      
    clone:()->
      _clone=(obj)->
        if not obj? or typeof obj isnt 'object'
          return obj
      
        if obj instanceof Date
          return new Date(obj.getTime()) 
      
        if obj instanceof RegExp
          flags = ''
          flags += 'g' if obj.global?
          flags += 'i' if obj.ignoreCase?
          flags += 'm' if obj.multiline?
          flags += 'y' if obj.sticky?
          return new RegExp(obj.source, flags) 
      
        newInstance = new obj.constructor()
        console.log "newInstsub"
        console.log obj
              
        for key of obj
          console.log "   key"
          console.log key
          newInstance[key] = _clone obj[key]
      
        return newInstance
      
      ###
      newInstance = new @constructor()
      #newInstance = CSGBase.fromPolygons(@polygons)
      newInstance.properties = Properties.cloneObj()
      newInstance.isCanonicalized = @isCanonicalized
      newInstance.isRetesselated = @isRetesselated
      
      console.log "building new obj"
      for key of @
        if key != "polygons" and key != "properties" and key!= "isCanonicalized" and key != "isRetesselated"
          newInstance[key] = _clone @[key]
      console.log "new instance"
      console.log newInstance
      ###
      #FIXME: concise, works, but depends on jquery
      newInstance = $.extend(true, {}, @)
      return newInstance
      
      
    @fromPolygons : (polygons) ->
      #Construct a CSG solid from a list of `Polygon` instances.
      csg = new CSGBase()
      csg.polygons = polygons
      csg.isCanonicalized = false
      csg.isRetesselated = false
      csg
  
    @fromObject : (obj) ->
      # create from an untyped object with identical property names:
      polygons = obj.polygons.map((p) ->
        Polygon.fromObject p
      )
      csg = CSGBase.fromPolygons(polygons)
      csg = csg.canonicalized()
      csg
      
    @fromCompactBinary : (bin) ->
      # Reconstruct a CSG from the output of toCompactBinary()
      throw new Error("Not a CSG")  unless bin.class is "CSG"
      planes = []
      planeData = bin.planeData
      numplanes = planeData.length / 4
      arrayindex = 0
      planeindex = 0
    
      while planeindex < numplanes
        x = planeData[arrayindex++]
        y = planeData[arrayindex++]
        z = planeData[arrayindex++]
        w = planeData[arrayindex++]
        normal = new Vector3D(x, y, z)
        plane = new Plane(normal, w)
        planes.push plane
        planeindex++
      vertices = []
      vertexData = bin.vertexData
      numvertices = vertexData.length / 3
      arrayindex = 0
      vertexindex = 0
    
      while vertexindex < numvertices
        x = vertexData[arrayindex++]
        y = vertexData[arrayindex++]
        z = vertexData[arrayindex++]
        pos = new Vector3D(x, y, z)
        vertex = new Vertex(pos)
        vertices.push vertex
        vertexindex++
      shareds = bin.shared.map((shared) ->
        Polygon.Shared.fromObject shared
      )
      polygons = []
      numpolygons = bin.numPolygons
      numVerticesPerPolygon = bin.numVerticesPerPolygon
      polygonVertices = bin.polygonVertices
      polygonPlaneIndexes = bin.polygonPlaneIndexes
      polygonSharedIndexes = bin.polygonSharedIndexes
      arrayindex = 0
      polygonindex = 0
    
      while polygonindex < numpolygons
        numpolygonvertices = numVerticesPerPolygon[polygonindex]
        polygonvertices = []
        i = 0
    
        while i < numpolygonvertices
          polygonvertices.push vertices[polygonVertices[arrayindex++]]
          i++
        plane = planes[polygonPlaneIndexes[polygonindex]]
        shared = shareds[polygonSharedIndexes[polygonindex]]
        polygon = new Polygon(polygonvertices, shared, plane)
        polygons.push polygon
        polygonindex++
      csg = CSGBase.fromPolygons(polygons)
      csg.isCanonicalized = true
      csg.isRetesselated = true
      csg
      
    toPolygons : ->
      @polygons
        
    toString: ->
      result = "CSG solid:\n"
      @polygons.map (p) ->
        result += p.toString()
      result
  
    toCompactBinary: ->
      csg = @canonicalized()
      numpolygons = csg.polygons.length
      numpolygonvertices = 0
      numvertices = 0
      vertexmap = {}
      vertices = []
      numplanes = 0
      planemap = {}
      polygonindex = 0
      planes = []
      shareds = []
      sharedmap = {}
      numshared = 0
      csg.polygons.map (p) ->
        p.vertices.map (v) ->
          ++numpolygonvertices
          vertextag = v.getTag()
          unless vertextag of vertexmap
            vertexmap[vertextag] = numvertices++
            vertices.push v
  
        planetag = p.plane.getTag()
        unless planetag of planemap
          planemap[planetag] = numplanes++
          planes.push p.plane
        sharedtag = p.shared.getTag()
        unless sharedtag of sharedmap
          sharedmap[sharedtag] = numshared++
          shareds.push p.shared
  
      numVerticesPerPolygon = new Uint32Array(numpolygons)
      polygonSharedIndexes = new Uint32Array(numpolygons)
      polygonVertices = new Uint32Array(numpolygonvertices)
      polygonPlaneIndexes = new Uint32Array(numpolygons)
      vertexData = new Float64Array(numvertices * 3)
      planeData = new Float64Array(numplanes * 4)
      polygonVerticesIndex = 0
      polygonindex = 0
  
      while polygonindex < numpolygons
        p = csg.polygons[polygonindex]
        numVerticesPerPolygon[polygonindex] = p.vertices.length
        p.vertices.map (v) ->
          vertextag = v.getTag()
          vertexindex = vertexmap[vertextag]
          polygonVertices[polygonVerticesIndex++] = vertexindex
  
        planetag = p.plane.getTag()
        planeindex = planemap[planetag]
        polygonPlaneIndexes[polygonindex] = planeindex
        sharedtag = p.shared.getTag()
        sharedindex = sharedmap[sharedtag]
        polygonSharedIndexes[polygonindex] = sharedindex
        ++polygonindex
      verticesArrayIndex = 0
      vertices.map (v) ->
        pos = v.pos
        vertexData[verticesArrayIndex++] = pos._x
        vertexData[verticesArrayIndex++] = pos._y
        vertexData[verticesArrayIndex++] = pos._z
  
      planesArrayIndex = 0
      planes.map (p) ->
        normal = p.normal
        planeData[planesArrayIndex++] = normal._x
        planeData[planesArrayIndex++] = normal._y
        planeData[planesArrayIndex++] = normal._z
        planeData[planesArrayIndex++] = p.w
  
      result =
        class: "CSG"
        numPolygons: numpolygons
        numVerticesPerPolygon: numVerticesPerPolygon
        polygonPlaneIndexes: polygonPlaneIndexes
        polygonSharedIndexes: polygonSharedIndexes
        polygonVertices: polygonVertices
        vertexData: vertexData
        planeData: planeData
        shared: shareds
  
      result
  
    toPointCloud: (cuberadius) ->
      # For debugging
      # Creates a new solid with a tiny cube at every vertex of the source solid
      csg = @reTesselated()
      result = new  CSGBase()
      
      # make a list of all unique vertices
      # For each vertex we also collect the list of normals of the planes touching the vertices
      vertexmap = {}
      csg.polygons.map (polygon) ->
        polygon.vertices.map (vertex) ->
          vertexmap[vertex.getTag()] = vertex.pos
  
      for vertextag of vertexmap
        pos = vertexmap[vertextag]
        cube = CSG.cube(
          center: pos
          radius: cuberadius
        )
        result = result.unionSub(cube, false, false)
      result = result.reTesselated()
      result
   
    union:(csg) ->
      # Return the current CSG solid representing space in either this solid or in the
      # solid `csg`. This solid is modified but not the solid `csg` .
      # 
      #     A.union(B)
      # 
      #     +-------+            +-------+
      #     |       |            |       |
      #     |   A   |            |       |
      #     |    +--+----+   =   |       +----+
      #     +----+--+    |       +----+       |
      #          |   B   |            |       |
      #          |       |            |       |
      #          +-------+            +-------+
      #       csgs = undefined
      if csg instanceof Array
        csgs = csg
      else
        csgs = [csg]
        
      i = 0
      while i < csgs.length
        islast = (i is (csgs.length - 1))
        @unionSub(csgs[i], islast, islast)
        i++
      @
   
    unionSub: (csg, retesselate, canonicalize) ->
      unless @mayOverlap(csg)
        @unionForNonIntersecting csg
      else
        a = new Tree(@polygons)
        b = new Tree(csg.polygons)
        a.clipTo b, false
        #b.clipTo(a, true) # ERROR: this doesn't work
        b.clipTo a
        b.invert()
        b.clipTo a
        b.invert()
        
        @polygons = a.allPolygons().concat(b.allPolygons())
        @properties = @properties._merge(csg.properties)
        @reTesselated()  if retesselate
        @canonicalized()  if canonicalize
        @cachedBoundingBox = null
        @
        
    unionForNonIntersecting: (csg) ->
      # Like union, but when we know that the two solids are not intersecting
      # Do not use if you are not completely sure that the solids do not intersect!
      newpolygons = @polygons.concat(csg.polygons)
      @polygons = newpolygons
      @properties = @properties._merge(csg.properties)
      @isCanonicalized = @isCanonicalized and csg.isCanonicalized
      @isRetesselated = @isRetesselated and csg.isRetesselated
      @cachedBoundingBox = null
      @
    
    subtract:(csg) ->
      # Return the current CSG solid modified for representing space in this solid but not in the
      # solid `csg`. This solid is modified but not the solid `csg` .
      # 
      #     A.subtract(B)
      # 
      #     +-------+            +-------+
      #     |       |            |       |
      #     |   A   |            |       |
      #     |    +--+----+   =   |    +--+
      #     +----+--+    |       +----+
      #          |   B   |
      #          |       |
      #          +-------+
      # 
      csgs = undefined
      if csg instanceof Array
        csgs = csg
      else
        csgs = [csg]
        
      i = 0
      while i < csgs.length
        islast = (i is (csgs.length - 1))
        @subtractSub(csgs[i], islast, islast)
        i++
      @
    
    subtractSub: (csg, retesselate, canonicalize) ->
      a = new Tree(@polygons)
      b = new Tree(csg.polygons)
      a.invert()
      a.clipTo b
      b.clipTo a, true
      a.addPolygons b.allPolygons()
      a.invert()
    
      @polygons = a.allPolygons()
      @properties = @properties._merge(csg.properties)
      @reTesselated()  if retesselate
      @canonicalized()  if canonicalize
      @cachedBoundingBox = null
      @
    
    intersect :(csg)->
      # Return this solid modified to represent space both this solid and in the
      # solid `csg`. This solid is modified but not the solid `csg` .
      # 
      #     A.intersect(B)
      # 
      #     +-------+
      #     |       |
      #     |   A   |
      #     |    +--+----+   =   +--+
      #     +----+--+    |       +--+
      #          |   B   |
      #          |       |
      #          +-------+
      # 
      csgs = undefined
      if csg instanceof Array
        csgs = csg
      else
        csgs = [csg]
        
      i = 0
  
      while i < csgs.length
        islast = (i is (csgs.length - 1))
        @intersectSub(csgs[i], islast, islast)
        i++   
      @
      
    intersectSub: (csg, retesselate, canonicalize) ->
      a = new Tree(@polygons)
      b = new Tree(csg.polygons)
      a.invert()
      b.clipTo a
      b.invert()
      a.clipTo b
      b.clipTo a
      a.addPolygons b.allPolygons()
      a.invert()
      @polygons = a.allPolygons()
      @properties = @properties._merge(csg.properties)
      @reTesselated()  if retesselate
      @canonicalized()  if canonicalize
      @cachedBoundingBox = null
      @
      
    inverse: ->
      # Return a new CSG solid with solid and empty space switched. This solid is
      # not modified.
      flippedpolygons = @polygons.map((p) ->
        p.flipped()
      )
      @polygons = flippedpolygons
      # TODO: flip properties
      @cachedBoundingBox = null
      @
          
    transform: (matrix4x4) ->
      ismirror = matrix4x4.isMirroring()
      transformedvertices = {}
      transformedplanes = {}
      newpolygons = @polygons.map((p) ->
        newplane = undefined
        plane = p.plane
        planetag = plane.getTag()
        if planetag of transformedplanes
          newplane = transformedplanes[planetag]
        else
          newplane = plane.transform(matrix4x4)
          transformedplanes[planetag] = newplane
        newvertices = p.vertices.map((v) ->
          newvertex = undefined
          vertextag = v.getTag()
          if vertextag of transformedvertices
            newvertex = transformedvertices[vertextag]
          else
            newvertex = v.transform(matrix4x4)
            transformedvertices[vertextag] = newvertex
          newvertex
        )
        newvertices.reverse()  if ismirror
        new Polygon(newvertices, p.shared, newplane)
      )
      
      @polygons= newpolygons
      @properties= @properties._transform(matrix4x4)
      @cachedBoundingBox = null
      @
     
    expand: (radius, resolution) ->
      # Expand the solid
      # resolution: number of points per 360 degree for the rounded corners
      result = @expandedShell(radius, resolution, true)
      result = result.reTesselated()
      #result.properties = @properties # keep original properties
      @polygons = result.polygons
      @isRetesselated = result.isRetesselated
      @isCanonicalized = result.isCanonicalized
      @
    
    contract: (radius, resolution) ->
      # Contract the solid
      # resolution: number of points per 360 degree for the rounded corners
      expandedshell = @expandedShell(radius, resolution, false)
      result = @subtract(expandedshell)
      result = result.reTesselated()
      result.properties = @properties # keep original properties
      result
  
    expandedShell: (radius, resolution, unionWithThis) ->
      # Create the expanded shell of the solid:
      # All faces are extruded to get a thickness of 2*radius
      # Cylinders are constructed around every side
      # Spheres are placed on every vertex
      # unionWithThis: if true, the resulting solid will be united with 'this' solid;
      #   the result is a true expansion of the solid
      #   If false, returns only the shell 
      csg = @reTesselated()
      result = undefined
      if unionWithThis
        result = csg
      else
        result = new  CSGBase()
      
      # first extrude all polygons:
      csg.polygons.map (polygon) ->
        extrudevector = polygon.plane.normal.unit().times(2 * radius)
        translatedpolygon = polygon.translate(extrudevector.times(-0.5))
        extrudedface = translatedpolygon.extrude(extrudevector)
        extrudedface = CSGBase.fromPolygons extrudedface
        result = result.unionSub(extrudedface, false, false)
  
      
      # Make a list of all unique vertex pairs (i.e. all sides of the solid)
      # For each vertex pair we collect the following:
      #   v1: first coordinate
      #   v2: second coordinate
      #   planenormals: array of normal vectors of all planes touching this side
      vertexpairs = {} # map of 'vertex pair tag' to {v1, v2, planenormals}
      csg.polygons.map (polygon) ->
        numvertices = polygon.vertices.length
        prevvertex = polygon.vertices[numvertices - 1]
        prevvertextag = prevvertex.getTag()
        i = 0
  
        while i < numvertices
          vertex = polygon.vertices[i]
          vertextag = vertex.getTag()
          vertextagpair = undefined
          if vertextag < prevvertextag
            vertextagpair = vertextag + "-" + prevvertextag
          else
            vertextagpair = prevvertextag + "-" + vertextag
          obj = undefined
          if vertextagpair of vertexpairs
            obj = vertexpairs[vertextagpair]
          else
            obj =
              v1: prevvertex
              v2: vertex
              planenormals: []
  
            vertexpairs[vertextagpair] = obj
          obj.planenormals.push polygon.plane.normal
          prevvertextag = vertextag
          prevvertex = vertex
          i++
  
      
      # now construct a cylinder on every side
      # The cylinder is always an approximation of a true cylinder: it will have <resolution> polygons 
      # around the sides. We will make sure though that the cylinder will have an edge at every
      # face that touches this side. This ensures that we will get a smooth fill even
      # if two edges are at, say, 10 degrees and the resolution is low.
      # Note: the result is not retesselated yet but it really should be!
      for vertextagpair of vertexpairs
        vertexpair = vertexpairs[vertextagpair]
        startpoint = vertexpair.v1.pos
        endpoint = vertexpair.v2.pos
        
        # our x,y and z vectors:
        zbase = endpoint.minus(startpoint).unit()
        xbase = vertexpair.planenormals[0].unit()
        ybase = xbase.cross(zbase)
        
        # make a list of angles that the cylinder should traverse:
        angles = []
        
        # first of all equally spaced around the cylinder:
        i = 0
  
        while i < resolution
          angle = i * Math.PI * 2 / resolution
          angles.push angle
          i++
        
        # and also at every normal of all touching planes:
        vertexpair.planenormals.map (planenormal) ->
          si = ybase.dot(planenormal)
          co = xbase.dot(planenormal)
          angle = Math.atan2(si, co)
          angle += Math.PI * 2  if angle < 0
          angles.push angle
          angle = Math.atan2(-si, -co)
          angle += Math.PI * 2  if angle < 0
          angles.push angle
  
        
        # this will result in some duplicate angles but we will get rid of those later.
        # Sort:
        angles = angles.sort((a, b) ->
          a - b
        )
        
        # Now construct the cylinder by traversing all angles:
        numangles = angles.length
        prevp1 = undefined
        prevp2 = undefined
        startfacevertices = []
        endfacevertices = []
        polygons = []
        prevangle = undefined
        i = -1
  
        while i < numangles
          angle = angles[(if (i < 0) then (i + numangles) else i)]
          si = Math.sin(angle)
          co = Math.cos(angle)
          p = xbase.times(co * radius).plus(ybase.times(si * radius))
          p1 = startpoint.plus(p)
          p2 = endpoint.plus(p)
          skip = false
          skip = true  if p1.distanceTo(prevp1) < 1e-5  if i >= 0
          unless skip
            if i >= 0
              startfacevertices.push new Vertex(p1)
              endfacevertices.push new Vertex(p2)
              polygonvertices = [new Vertex(prevp2), new Vertex(p2), new Vertex(p1), new Vertex(prevp1)]
              polygon = new Polygon(polygonvertices)
              polygons.push polygon
            prevp1 = p1
            prevp2 = p2
          i++
        endfacevertices.reverse()
        polygons.push new Polygon(startfacevertices)
        polygons.push new Polygon(endfacevertices)
        cylinder = CSGBase.fromPolygons(polygons)
        result = result.unionSub(cylinder, false, false)
      
      # make a list of all unique vertices
      # For each vertex we also collect the list of normals of the planes touching the vertices
      vertexmap = {}
      csg.polygons.map (polygon) ->
        polygon.vertices.map (vertex) ->
          vertextag = vertex.getTag()
          obj = undefined
          if vertextag of vertexmap
            obj = vertexmap[vertextag]
          else
            obj =
              pos: vertex.pos
              normals: []
  
            vertexmap[vertextag] = obj
          obj.normals.push polygon.plane.normal
  
      # and build spheres at each vertex
      # We will try to set the x and z axis to the normals of 2 planes
      # This will ensure that our sphere tesselation somewhat matches 2 planes
      console.log "here"
      for vertextag of vertexmap
        vertexobj = vertexmap[vertextag]
        # use the first normal to be the x axis of our sphere:
        xaxis = vertexobj.normals[0].unit()
        
        # and find a suitable z axis. We will use the normal which is most perpendicular to the x axis:
        bestzaxis = null
        bestzaxisorthogonality = 0
        i = 1
  
        while i < vertexobj.normals.length
          normal = vertexobj.normals[i].unit()
          cross = xaxis.cross(normal)
          crosslength = cross.length()
          if crosslength > 0.05
            if crosslength > bestzaxisorthogonality
              bestzaxisorthogonality = crosslength
              bestzaxis = normal
          i++
        bestzaxis = xaxis.randomNonParallelVector()  unless bestzaxis
        yaxis = xaxis.cross(bestzaxis).unit()
        zaxis = yaxis.cross(xaxis)
        console.log "here s"
        sphere = sphereUtil(
          center: vertexobj.pos
          radius: radius
          resolution: resolution
          axes: [xaxis, yaxis, zaxis]
        )
        console.log "here sdfs"
        result = result.unionSub(sphere, false, false)
        console.log "here toto"
      console.log "at end"
      result
      
    canonicalized: ->
      if @isCanonicalized
        return @
      else
        factory = new FuzzyCSGFactory()
        @polygons = factory.getCSGPolygons(@)
        @isCanonicalized = true
        @
  
    reTesselated: ->
      if @isRetesselated
        return @
      else
        csg = @canonicalized()
        polygonsPerPlane = {}
        csg.polygons.map (polygon) ->
          planetag = polygon.plane.getTag()
          sharedtag = polygon.shared.getTag()
          planetag += "/" + sharedtag
          polygonsPerPlane[planetag] = []  unless planetag of polygonsPerPlane
          polygonsPerPlane[planetag].push polygon
  
        destpolygons = []
        for planetag of polygonsPerPlane
          sourcepolygons = polygonsPerPlane[planetag]
          if sourcepolygons.length < 2
            destpolygons = destpolygons.concat(sourcepolygons)
          else
            retesselayedpolygons = []
            reTesselateCoplanarPolygons sourcepolygons, retesselayedpolygons
            destpolygons = destpolygons.concat(retesselayedpolygons)
        @polygons = destpolygons
        @isRetesselated = true
        @canonicalized()
        @
        
    getBounds: ->
      # returns an array of two Vector3Ds (minimum coordinates and maximum coordinates)
      unless @cachedBoundingBox
        minpoint = new Vector3D(0, 0, 0)
        maxpoint = new Vector3D(0, 0, 0)
        polygons = @polygons
        numpolygons = polygons.length
        i = 0
  
        while i < numpolygons
          polygon = polygons[i]
          bounds = polygon.boundingBox()
          if i is 0
            minpoint = bounds[0]
            maxpoint = bounds[1]
          else
            minpoint = minpoint.min(bounds[0])
            maxpoint = maxpoint.max(bounds[1])
          i++
        @cachedBoundingBox = [minpoint, maxpoint]
      @cachedBoundingBox
    
    mayOverlap: (csg) ->
      # returns true if there is a possibility that the two solids overlap
      # returns false if we can be sure that they do not overlap
      if (@polygons.length is 0) or (csg.polygons.length is 0)
        false
      else
        mybounds = @getBounds()
        otherbounds = csg.getBounds()
        return false  if mybounds[1].x < otherbounds[0].x
        return false  if mybounds[0].x > otherbounds[1].x
        return false  if mybounds[1].y < otherbounds[0].y
        return false  if mybounds[0].y > otherbounds[1].y
        return false  if mybounds[1].z < otherbounds[0].z
        return false  if mybounds[0].z > otherbounds[1].z
        true
    
    cutByPlane: (plane) ->
      # Cut the solid by a plane. Returns the solid on the back side of the plane
      return new  CSGBase()  if @polygons.length is 0
      
      # Ideally we would like to do an intersection with a polygon of inifinite size
      # but this is not supported by our implementation. As a workaround, we will create
      # a cube, with one face on the plane, and a size larger enough so that the entire
      # solid fits in the cube.
      
      # find the max distance of any vertex to the center of the plane:
      planecenter = plane.normal.times(plane.w)
      maxdistance = 0
      @polygons.map (polygon) ->
        polygon.vertices.map (vertex) ->
          distance = vertex.pos.distanceToSquared(planecenter)
          maxdistance = distance  if distance > maxdistance
  
  
      maxdistance = Math.sqrt(maxdistance)
      maxdistance *= 1.01 # make sure it's really larger
      
      # Now build a polygon on the plane, at any point farther than maxdistance from the plane center:
      vertices = []
      orthobasis = new CSG.OrthoNormalBasis(plane)
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(maxdistance, -maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(-maxdistance, -maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(-maxdistance, maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(maxdistance, maxdistance)))
      polygon = new Polygon(vertices, null, plane.flipped())
      
      # and extrude the polygon into a cube, backwards of the plane:
      cube = polygon.extrude(plane.normal.times(-maxdistance))
      
      # Now we can do the intersection:
      result = @intersect(cube)
      result.properties = @properties # keep original properties
      result
  
    connectTo: (myConnector, otherConnector, mirror, normalrotation) ->
      # Connect a solid to another solid, such that two CSG.Connectors become connected
      #   myConnector: a CSG.Connector of this solid
      #   otherConnector: a CSG.Connector to which myConnector should be connected
      #   mirror: false: the 'axis' vectors of the connectors should point in the same direction
      #           true: the 'axis' vectors of the connectors should point in opposite direction
      #   normalrotation: degrees of rotation between the 'normal' vectors of the two
      #                   connectors
      matrix = myConnector.getTransformationTo(otherConnector, mirror, normalrotation)
      @transform matrix
   
    setShared: (shared) ->
      # set the .shared property of all polygons
      # Returns the current CSG solid he original is modified
      polygons = @polygons.map((p) ->
        new Polygon(p.vertices, shared, p.plane)
      )
      #result = CSGBase.fromPolygons(polygons)
      #result.properties = @properties # keep original properties
      #result.isRetesselated = @isRetesselated
      #result.isCanonicalized = @isCanonicalized
      #result
      @polygons = polygons
      @
      
  
    setColor: (red, green, blue) ->
      newshared = new PolygonShared([red, green, blue])
      @setShared newshared
  
    color: (rgb) ->
      newshared = new PolygonShared([rgb[0], rgb[1], rgb[2]])
      @setShared newshared
    
    getTransformationToFlatLying: ->
      # Get the transformation that transforms this CSG such that it is lying on the z=0 plane, 
      # as flat as possible (i.e. the least z-height).
      # So that it is in an orientation suitable for CNC milling    
      if @polygons.length is 0
        new CSG.Matrix4x4() # unity
      else
        
        # get a list of unique planes in the CSG:
        csg = @canonicalized()
        planemap = {}
        csg.polygons.map (polygon) ->
          planemap[polygon.plane.getTag()] = polygon.plane
  
        
        # try each plane in the CSG and find the plane that, when we align it flat onto z=0,
        # gives the least height in z-direction.
        # If two planes give the same height, pick the plane that originally had a normal closest
        # to [0,0,-1].
        xvector = new Vector3D(1, 0, 0)
        yvector = new Vector3D(0, 1, 0)
        zvector = new Vector3D(0, 0, 1)
        z0connectorx = new CSG.Connector([0, 0, 0], [0, 0, -1], xvector)
        z0connectory = new CSG.Connector([0, 0, 0], [0, 0, -1], yvector)
        isfirst = true
        minheight = 0
        maxdotz = 0
        besttransformation = undefined
        for planetag of planemap
          plane = planemap[planetag]
          pointonplane = plane.normal.times(plane.w)
          transformation = undefined
          
          # We need a normal vecrtor for the transformation
          # determine which is more perpendicular to the plane normal: x or y?
          # we will align this as much as possible to the x or y axis vector
          xorthogonality = plane.normal.cross(xvector).length()
          yorthogonality = plane.normal.cross(yvector).length()
          if xorthogonality > yorthogonality
            
            # x is better:
            planeconnector = new CSG.Connector(pointonplane, plane.normal, xvector)
            transformation = planeconnector.getTransformationTo(z0connectorx, false, 0)
          else
            
            # y is better:
            planeconnector = new CSG.Connector(pointonplane, plane.normal, yvector)
            transformation = planeconnector.getTransformationTo(z0connectory, false, 0)
          transformedcsg = csg.transform(transformation)
          dotz = -plane.normal.dot(zvector)
          bounds = transformedcsg.getBounds()
          zheight = bounds[1].z - bounds[0].z
          isbetter = isfirst
          unless isbetter
            if zheight < minheight
              isbetter = true
            else isbetter = true  if dotz > maxdotz  if zheight is minheight
          if isbetter
            
            # translate the transformation around the z-axis and onto the z plane:
            translation = [-0.5 * (bounds[1].x + bounds[0].x), -0.5 * (bounds[1].y + bounds[0].y), -bounds[0].z]
            transformation = transformation.multiply(CSG.Matrix4x4.translation(translation))
            minheight = zheight
            maxdotz = dotz
            besttransformation = transformation
          isfirst = false
        besttransformation
  
    lieFlat: ->
      transformation = @getTransformationToFlatLying()
      @transform transformation
    
    projectToOrthoNormalBasis: (orthobasis) ->
      # project the 3D CSG onto a plane
      # This returns a 2D CAG with the 'shadow' shape of the 3D solid when projected onto the
      # plane represented by the orthonormal basis
      cags = []
      @polygons.map (polygon) ->
        cag = polygon.projectToOrthoNormalBasis(orthobasis)
        cags.push cag  if cag.sides.length > 0
  
      result = new CAGBase().union(cags)
      result
  
    sectionCut: (orthobasis) ->
      plane1 = orthobasis.plane
      plane2 = orthobasis.plane.flipped()
      plane1 = new Plane(plane1.normal, plane1.w + 1e-4)
      plane2 = new Plane(plane2.normal, plane2.w + 1e-4)
      cut3d = @cutByPlane(plane1)
      cut3d = cut3d.cutByPlane(plane2)
      cut3d.projectToOrthoNormalBasis orthobasis
      
    fixTJunctions: ->
      console.log "fixing TJUNCTIONS"
      #
      #  fixTJunctions:
      #
      #  Suppose we have two polygons ACDB and EDGF:
      #
      #   A-----B
      #   |     |
      #   |     E--F
      #   |     |  |
      #   C-----D--G
      #
      #  Note that vertex E forms a T-junction on the side BD. In this case some STL slicers will complain
      #  that the solid is not watertight. This is because the watertightness check is done by checking if
      #  each side DE is matched by another side ED.
      #
      #  This function will return a new solid with ACDB replaced by ACDEB
      #
      #  Note that this can create polygons that are slightly non-convex (due to rounding errors). Therefore the result should
      #  not be used for further CSG operations!
      #  
      idx = undefined
      csg = @canonicalized()
      sidemap = {}
      polygonindex = 0
  
      while polygonindex < csg.polygons.length
        polygon = csg.polygons[polygonindex]
        numvertices = polygon.vertices.length
        if numvertices >= 3 # should be true
          vertex = polygon.vertices[0]
          vertextag = vertex.getTag()
          vertexindex = 0
  
          while vertexindex < numvertices
            nextvertexindex = vertexindex + 1
            nextvertexindex = 0  if nextvertexindex is numvertices
            nextvertex = polygon.vertices[nextvertexindex]
            nextvertextag = nextvertex.getTag()
            sidetag = vertextag + "/" + nextvertextag
            reversesidetag = nextvertextag + "/" + vertextag
            if reversesidetag of sidemap
              
              # this side matches the same side in another polygon. Remove from sidemap:
              ar = sidemap[reversesidetag]
              ar.splice -1, 1
              delete sidemap[reversesidetag]  if ar.length is 0
            else
              sideobj =
                vertex0: vertex
                vertex1: nextvertex
                polygonindex: polygonindex
  
              unless sidetag of sidemap
                sidemap[sidetag] = [sideobj]
              else
                sidemap[sidetag].push sideobj
            vertex = nextvertex
            vertextag = nextvertextag
            vertexindex++
        polygonindex++
      
      # now sidemap contains 'unmatched' sides
      # i.e. side AB in one polygon does not have a matching side BA in another polygon
      vertextag2sidestart = {}
      vertextag2sideend = {}
      sidestocheck = {}
      sidemapisempty = true
      for sidetag of sidemap
        sidemapisempty = false
        sidestocheck[sidetag] = true
        sidemap[sidetag].map (sideobj) ->
          starttag = sideobj.vertex0.getTag()
          endtag = sideobj.vertex1.getTag()
          if starttag of vertextag2sidestart
            vertextag2sidestart[starttag].push sidetag
          else
            vertextag2sidestart[starttag] = [sidetag]
          if endtag of vertextag2sideend
            vertextag2sideend[endtag].push sidetag
          else
            vertextag2sideend[endtag] = [sidetag]
  
      unless sidemapisempty
        
        # make a copy of the polygons array, since we are going to modify it:
        addSide = (vertex0, vertex1, polygonindex) ->
          starttag = vertex0.getTag()
          endtag = vertex1.getTag()
          throw new Error("Assertion failed")  if starttag is endtag
          newsidetag = starttag + "/" + endtag
          reversesidetag = endtag + "/" + starttag
          if reversesidetag of sidemap
            
            # we have a matching reverse oriented side. Instead of adding the new side, cancel out the reverse side:
            #  console.log("addSide("+newsidetag+") has reverse side:");
            deleteSide vertex1, vertex0, null
            return null
          
          #  console.log("addSide("+newsidetag+")");
          newsideobj =
            vertex0: vertex0
            vertex1: vertex1
            polygonindex: polygonindex
  
          unless newsidetag of sidemap
            sidemap[newsidetag] = [newsideobj]
          else
            sidemap[newsidetag].push newsideobj
          if starttag of vertextag2sidestart
            vertextag2sidestart[starttag].push newsidetag
          else
            vertextag2sidestart[starttag] = [newsidetag]
          if endtag of vertextag2sideend
            vertextag2sideend[endtag].push newsidetag
          else
            vertextag2sideend[endtag] = [newsidetag]
          newsidetag
        deleteSide = (vertex0, vertex1, polygonindex) ->
          starttag = vertex0.getTag()
          endtag = vertex1.getTag()
          sidetag = starttag + "/" + endtag
          
          # console.log("deleteSide("+sidetag+")");
          throw new Error("Assertion failed")  unless sidetag of sidemap
          idx = -1
          sideobjs = sidemap[sidetag]
          i = 0
  
          while i < sideobjs.length
            sideobj = sideobjs[i]
            continue  unless sideobj.vertex0 is vertex0
            continue  unless sideobj.vertex1 is vertex1
            continue  unless sideobj.polygonindex is polygonindex  if polygonindex isnt null
            idx = i
            break
            i++
          throw new Error("Assertion failed")  if idx < 0
          sideobjs.splice idx, 1
          delete sidemap[sidetag]  if sideobjs.length is 0
          idx = vertextag2sidestart[starttag].indexOf(sidetag)
          throw new Error("Assertion failed")  if idx < 0
          vertextag2sidestart[starttag].splice idx, 1
          delete vertextag2sidestart[starttag]  if vertextag2sidestart[starttag].length is 0
          idx = vertextag2sideend[endtag].indexOf(sidetag)
          throw new Error("Assertion failed")  if idx < 0
          vertextag2sideend[endtag].splice idx, 1
          delete vertextag2sideend[endtag]  if vertextag2sideend[endtag].length is 0
        polygons = csg.polygons.slice(0)
        loop
          sidemapisempty = true
          for sidetag of sidemap
            sidemapisempty = false
            sidestocheck[sidetag] = true
          break  if sidemapisempty
          donesomething = false
          loop
            sidetagtocheck = null
            for sidetag of sidestocheck
              sidetagtocheck = sidetag
              break
            break  if sidetagtocheck is null # sidestocheck is empty, we're done!
            donewithside = true
            if sidetagtocheck of sidemap
              sideobjs = sidemap[sidetagtocheck]
              throw new Error("Assertion failed")  if sideobjs.length is 0
              sideobj = sideobjs[0]
              directionindex = 0
  
              while directionindex < 2
                startvertex = (if (directionindex is 0) then sideobj.vertex0 else sideobj.vertex1)
                endvertex = (if (directionindex is 0) then sideobj.vertex1 else sideobj.vertex0)
                startvertextag = startvertex.getTag()
                endvertextag = endvertex.getTag()
                matchingsides = []
                if directionindex is 0
                  matchingsides = vertextag2sideend[startvertextag]  if startvertextag of vertextag2sideend
                else
                  matchingsides = vertextag2sidestart[startvertextag]  if startvertextag of vertextag2sidestart
                matchingsideindex = 0
  
                while matchingsideindex < matchingsides.length
                  matchingsidetag = matchingsides[matchingsideindex]
                  matchingside = sidemap[matchingsidetag][0]
                  matchingsidestartvertex = (if (directionindex is 0) then matchingside.vertex0 else matchingside.vertex1)
                  matchingsideendvertex = (if (directionindex is 0) then matchingside.vertex1 else matchingside.vertex0)
                  matchingsidestartvertextag = matchingsidestartvertex.getTag()
                  matchingsideendvertextag = matchingsideendvertex.getTag()
                  throw new Error("Assertion failed")  unless matchingsideendvertextag is startvertextag
                  if matchingsidestartvertextag is endvertextag
                    
                    # matchingside cancels sidetagtocheck
                    deleteSide startvertex, endvertex, null
                    deleteSide endvertex, startvertex, null
                    donewithside = false
                    directionindex = 2 # skip reverse direction check
                    donesomething = true
                    break
                  else
                    startpos = startvertex.pos
                    endpos = endvertex.pos
                    checkpos = matchingsidestartvertex.pos
                    direction = checkpos.minus(startpos)
                    
                    # Now we need to check if endpos is on the line startpos-checkpos:
                    t = endpos.minus(startpos).dot(direction) / direction.dot(direction)
                    if (t > 0) and (t < 1)
                      closestpoint = startpos.plus(direction.times(t))
                      distancesquared = closestpoint.distanceToSquared(endpos)
                      if distancesquared < 1e-10
                        
                        # Yes it's a t-junction! We need to split matchingside in two:                
                        polygonindex = matchingside.polygonindex
                        polygon = polygons[polygonindex]
                        
                        # find the index of startvertextag in polygon:
                        insertionvertextag = matchingside.vertex1.getTag()
                        insertionvertextagindex = -1
                        i = 0
  
                        while i < polygon.vertices.length
                          if polygon.vertices[i].getTag() is insertionvertextag
                            insertionvertextagindex = i
                            break
                          i++
                        throw new Error("Assertion failed")  if insertionvertextagindex < 0
                        
                        # split the side by inserting the vertex:
                        newvertices = polygon.vertices.slice(0)
                        newvertices.splice insertionvertextagindex, 0, endvertex
                        newpolygon = new Polygon(newvertices, polygon.shared) #polygon.plane
                        polygons[polygonindex] = newpolygon
                        
                        # remove the original sides from our maps:
                        # deleteSide(sideobj.vertex0, sideobj.vertex1, null);
                        deleteSide matchingside.vertex0, matchingside.vertex1, polygonindex
                        newsidetag1 = addSide(matchingside.vertex0, endvertex, polygonindex)
                        newsidetag2 = addSide(endvertex, matchingside.vertex1, polygonindex)
                        sidestocheck[newsidetag1] = true  if newsidetag1 isnt null
                        sidestocheck[newsidetag2] = true  if newsidetag2 isnt null
                        donewithside = false
                        directionindex = 2 # skip reverse direction check
                        donesomething = true
                        break
                  matchingsideindex++
                directionindex++
            # if(distancesquared < 1e-10)
            # if( (t > 0) && (t < 1) )
            # if(endingstidestartvertextag == endvertextag)
            # for matchingsideindex
            # for directionindex
            # if(sidetagtocheck in sidemap)
            delete sidestocheck[sidetag]  if donewithside
          break  unless donesomething
        newcsg = CSGBase.fromPolygons(polygons)
        newcsg.properties = csg.properties
        newcsg.isCanonicalized = true
        newcsg.isRetesselated = true
        csg = newcsg
      # if(!sidemapisempty)
      sidemapisempty = true
      for sidetag of sidemap
        sidemapisempty = false
        break
      throw new Error("!sidemapisempty")  unless sidemapisempty
      csg
      
  sphereUtil = (options) ->
    options = options or {}
    center = parseOptionAs3DVector(options, "center", [0, 0, 0])
    radius = parseOptionAsFloat(options, "radius", 1)
    resolution = parseOptionAsInt(options, "resolution", CSGBase.defaultResolution3D)
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
    result
    
    
  class CAGBase extends TransformBase
    # CAG: solid area geometry: like CSG but 2D
    # Each area consists of a number of sides
    # Each side is a line between 2 points
    constructor: ->
      @sides = []
      @isCanonicalized=false
  
    clone:->
      newInstance = $.extend(true, {}, @)
      return newInstance
  
    @fromSides : (sides) ->
      # Construct a CAG from a list of `Side` instances.
      cag = new CAGBase()
      cag.sides = sides
      cag
  
    @fromPoints : (points) ->
      # Construct a CAG from a list of points (a polygon)
      # Rotation direction of the points is not relevant. Points can be a convex or concave polygon.
      # Polygon must not self intersect
      numpoints = points.length
      throw new Error("CAG shape needs at least 3 points")  if numpoints < 3
      sides = []
      prevpoint = new Vector2D(points[numpoints - 1])
      prevvertex = new Vertex2D(prevpoint)
      points.map (p) ->
        point = new Vector2D(p)
        vertex = new Vertex2D(point)
        side = new Side(prevvertex, vertex)
        sides.push side
        prevvertex = vertex
    
      result = CAGBase.fromSides(sides)
      throw new Error("Polygon is self intersecting!")  if result.isSelfIntersecting()
      area = result.area()
      throw new Error("Degenerate polygon!")  if Math.abs(area) < 1e-5
      result = result.flipped()  if area < 0
      result = result.canonicalized()
      result
    
    @hull : (cag) ->
      #quickhull hull implementation experiment
      #see here http://westhoffswelt.de/blog/0040_quickhull_introduction_and_php_implementation.html/
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      
      pts = []
      #--------------------------------------
      #First two points on the convex hull
      minPoint = {x:+Infinity,y:0}
      maxPoint = {x:-Infinity,y:0}
      cags.map (cag) ->
        for side in cag.sides
          v0 = side.vertex0.pos
          v1 = side.vertex1.pos
            
          if v0.x<minPoint.x
            console.log "her"
            minPoint = v0
          if v0.x>maxPoint.x
            maxPoint = v0
          if v1.x<minPoint.x
            minPoint=v1
          if v1.x>maxPoint.x
            maxPoint = v1
            
          pts.push(side.vertex0.pos)
          pts.push(side.vertex1.pos)
     
      sign=(a,b,c)->
          return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x))
      console.log "found min: #{minPoint} and max: #{maxPoint}"
      #--------------------------------------
      #divide into two sets of point : on the left and right from the line created by minPoint->maxPoint
      rightSet = []
      leftSet = []
      for point in pts
        #console.log "point #{point}"
        xp = sign(minPoint,maxPoint,point)
        if xp > 0
            #console.log 'on left side'
            leftSet.push(point)
        else if xp < 0
            #console.log 'on right side'
            rightSet.push(point)
        else
            #console.log 'on the same line!'
            rightSet.push(point)
      console.log "left:"
      console.log leftSet
      console.log "right:"
      console.log rightSet
      #--------------------------------------
      #max distance search
      maxDistPoint = null
      
      #--------------------------------------
      #Point exclusion
      PointInTriangle = (pt, v1, v2, v3)->
        b1 = sign(pt, v1, v2) < 0.0
        b2 = sign(pt, v2, v3) < 0.0
        b3 = sign(pt, v3, v1) < 0.0
        return ((b1 == b2) and (b2 == b3))
      for point in leftSet
        if PointInTriangle(point, maxDistPoint, minPoint, maxPoint)
      
      for point in rightSet
      
      result = new CAGBase()
      result
  
    @fromPointsNoCheck : (points) ->
      # Like CAGBase.fromPoints but does not check if it's a valid polygon.
      # Points should rotate counter clockwise
      sides = []
      prevpoint = new Vector2D(points[points.length - 1])
      prevvertex = new Vertex2D(prevpoint)
      points.map (p) ->
        point = new Vector2D(p)
        vertex = new Vertex2D(point)
        side = new Side(prevvertex, vertex)
        sides.push side
        prevvertex = vertex
    
      CAGBase.fromSides sides
  
    @fromFakeCSG : (csg) ->
      # Converts a CSG to a CAGBase. The CSG must consist of polygons with only z coordinates +1 and -1
      # as constructed by CAGBase.toCSG(-1, 1). This is so we can use the 3D union(), intersect() etc
      sides = csg.polygons.map((p) ->
        Side.fromFakePolygon p
      )
      CAGBase.fromSides sides
  
    @fromCompactBinary : (bin) ->
      # Reconstruct a CAG from the output of toCompactBinary()
      throw new Error("Not a CAG")  unless bin.class is "CAG"
      vertices = []
      vertexData = bin.vertexData
      numvertices = vertexData.length / 2
      arrayindex = 0
      vertexindex = 0
    
      while vertexindex < numvertices
        x = vertexData[arrayindex++]
        y = vertexData[arrayindex++]
        pos = new Vector2D(x, y)
        vertex = new Vertex2D(pos)
        vertices.push vertex
        vertexindex++
      sides = []
      numsides = bin.sideVertexIndices.length / 2
      arrayindex = 0
      sideindex = 0
    
      while sideindex < numsides
        vertexindex0 = bin.sideVertexIndices[arrayindex++]
        vertexindex1 = bin.sideVertexIndices[arrayindex++]
        side = new Side(vertices[vertexindex0], vertices[vertexindex1])
        sides.push side
        sideindex++
      cag = CAGBase.fromSides(sides)
      cag.isCanonicalized = true
      cag
      
    toString: ->
      result = "CAG (" + @sides.length + " sides):\n"
      @sides.map (side) ->
        result += "  " + side.toString() + "\n"
      result
  
    toCSG: (z0, z1) ->
      polygons = @sides.map((side) ->
        side.toPolygon3D z0, z1
      )
      CSGBase.fromPolygons polygons
  
    toDebugString1: ->
      @sides.sort (a, b) ->
        a.vertex0.pos.x - b.vertex0.pos.x
  
      str = ""
      @sides.map (side) ->
        str += "(" + side.vertex0.pos.x + "," + side.vertex0.pos.y + ") - (" + side.vertex1.pos.x + "," + side.vertex1.pos.y + ")\n"
  
      str
  
    toDebugString: ->
      #    this.sides.sort(function(a,b){
      #      return a.vertex0.pos.x - b.vertex0.pos.x; 
      #    });
      str = "CAGBase.fromSides([\n"
      @sides.map (side) ->
        str += "  new Side(new Vertex2D(new Vector2D(" + side.vertex0.pos.x + "," + side.vertex0.pos.y + ")), new Vertex2D(new Vector2D(" + side.vertex1.pos.x + "," + side.vertex1.pos.y + "))),\n"
  
      str += "]);\n"
      str
  
    toCompactBinary: ->
      cag = @canonicalized()
      numsides = cag.sides.length
      vertexmap = {}
      vertices = []
      numvertices = 0
      sideVertexIndices = new Uint32Array(2 * numsides)
      sidevertexindicesindex = 0
      cag.sides.map (side) ->
        [side.vertex0, side.vertex1].map (v) ->
          vertextag = v.getTag()
          vertexindex = undefined
          unless vertextag of vertexmap
            vertexindex = numvertices++
            vertexmap[vertextag] = vertexindex
            vertices.push v
          else
            vertexindex = vertexmap[vertextag]
          sideVertexIndices[sidevertexindicesindex++] = vertexindex
  
  
      vertexData = new Float64Array(numvertices * 2)
      verticesArrayIndex = 0
      vertices.map (v) ->
        pos = v.pos
        vertexData[verticesArrayIndex++] = pos._x
        vertexData[verticesArrayIndex++] = pos._y
  
      result =
        class: "CAG"
        sideVertexIndices: sideVertexIndices
        vertexData: vertexData
      result
  
    toDxf: (blobbuilder) ->
      paths = @getOutlinePaths()
      CAGBase.PathsToDxf paths, blobbuilder
  
    union: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r.unionSub(cag.toCSG(-1, 1), false, false)
  
      r.reTesselated()
      r.canonicalized()
      cag = CAGBase.fromFakeCSG(r)
      @sides = cag.sides
      @isCanonicalized = cag.isCanonicalized
      @ 
  
    subtract: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r.subtractSub(cag.toCSG(-1, 1), false, false)
      r.reTesselated()
      r.canonicalized()
      r = CAGBase.fromFakeCSG(r)
      r.canonicalized()
      @sides = r.sides
      @isCanonicalized = cag.isCanonicalized
      @
      
  
    intersect: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r.intersectSub(cag.toCSG(-1, 1), false, false)
  
      r.reTesselated()
      r.canonicalized()
      r = CAGBase.fromFakeCSG(r)
      r.canonicalized()
      @sides = r.sides
      @isCanonicalized = cag.isCanonicalized
      @
      
  
    transform: (matrix4x4) ->
      ismirror = matrix4x4.isMirroring()
      newsides = @sides.map((side) ->
        side.transform matrix4x4
      )

      @sides = newsides
      @flipped() if ismirror
      @
      
    area: ->
      # see http://local.wasp.uwa.edu.au/~pbourke/geometry/polyarea/ :
      # Area of the polygon. For a counter clockwise rotating polygon the area is positive, otherwise negative
      polygonArea = 0
      @sides.map (side) ->
        polygonArea += side.vertex0.pos.cross(side.vertex1.pos)
  
      polygonArea *= 0.5
      polygonArea
  
    flipped: ->
      newsides = @sides.map((side) ->
        side.flipped()
      )
      ###
      newsides.reverse()
      CAGBase.fromSides newsides
      ###
      @sides = newsides
      @sides.reverse()
      @

  
    getBounds: ->
      minpoint = undefined
      if @sides.length is 0
        minpoint = new Vector2D(0, 0)
      else
        minpoint = @sides[0].vertex0.pos
      maxpoint = minpoint
      @sides.map (side) ->
        minpoint = minpoint.min(side.vertex0.pos)
        minpoint = minpoint.min(side.vertex1.pos)
        maxpoint = maxpoint.max(side.vertex0.pos)
        maxpoint = maxpoint.max(side.vertex1.pos)
  
      [minpoint, maxpoint]
  
    isSelfIntersecting: ->
      numsides = @sides.length
      i = 0
  
      while i < numsides
        side0 = @sides[i]
        ii = i + 1
  
        while ii < numsides
          side1 = @sides[ii]
          return true  if CAGBase.linesIntersect(side0.vertex0.pos, side0.vertex1.pos, side1.vertex0.pos, side1.vertex1.pos)
          ii++
        i++
      false
  
    expandedShell: (radius, resolution) ->
      resolution = resolution or 8
      resolution = 4  if resolution < 4
      cags = []
      pointmap = {}
      cag = @canonicalized()
      cag.sides.map (side) ->
        d = side.vertex1.pos.minus(side.vertex0.pos)
        dl = d.length()
        if dl > 1e-5
          d = d.times(1.0 / dl)
          normal = d.normal().times(radius)
          shellpoints = [side.vertex1.pos.plus(normal), side.vertex1.pos.minus(normal), side.vertex0.pos.minus(normal), side.vertex0.pos.plus(normal)]
          
          #      var newcag = CAGBase.fromPointsNoCheck(shellpoints); 
          newcag = CAGBase.fromPoints(shellpoints)
          cags.push newcag
          step = 0
  
          while step < 2
            p1 = (if (step is 0) then side.vertex0.pos else side.vertex1.pos)
            p2 = (if (step is 0) then side.vertex1.pos else side.vertex0.pos)
            tag = p1.x + " " + p1.y
            pointmap[tag] = []  unless tag of pointmap
            pointmap[tag].push
              p1: p1
              p2: p2
  
            step++
  
      for tag of pointmap
        m = pointmap[tag]
        angle1 = undefined
        angle2 = undefined
        pcenter = m[0].p1
        if m.length is 2
          end1 = m[0].p2
          end2 = m[1].p2
          angle1 = end1.minus(pcenter).angleDegrees()
          angle2 = end2.minus(pcenter).angleDegrees()
          angle2 += 360  if angle2 < angle1
          angle2 -= 360  if angle2 >= (angle1 + 360)
          if angle2 < angle1 + 180
            t = angle2
            angle2 = angle1 + 360
            angle1 = t
          angle1 += 90
          angle2 -= 90
        else
          angle1 = 0
          angle2 = 360
        fullcircle = (angle2 > angle1 + 359.999)
        if fullcircle
          angle1 = 0
          angle2 = 360
        if angle2 > (angle1 + 1e-5)
          points = []
          points.push pcenter  unless fullcircle
          numsteps = Math.round(resolution * (angle2 - angle1) / 360)
          numsteps = 1  if numsteps < 1
          step = 0
  
          while step <= numsteps
            angle = angle1 + step / numsteps * (angle2 - angle1)
            angle = angle2  if step is numsteps # prevent rounding errors
            point = pcenter.plus(Vector2D.fromAngleDegrees(angle).times(radius))
            points.push point  if (not fullcircle) or (step > 0)
            step++
          newcag = CAGBase.fromPointsNoCheck(points)
          cags.push newcag
      result = new CAGBase()
      result = result.union(cags)
      result
  
    expand: (radius, resolution) ->
      @union(@expandedShell(radius, resolution))
      @
  
    contract: (radius, resolution) ->
      @subtract(@expandedShell(radius, resolution))
      @
  
    extrude: (options) ->
      # extruded=cag.extrude({offset: [0,0,10], twistangle: 360, twiststeps: 100});
      # linear extrusion of 2D shape, with optional twist
      # The 2d shape is placed in z=0 plane and extruded into direction <offset> (a Vector3D)
      # The final face is rotated <twistangle> degrees. Rotation is done around the origin of the 2d shape (i.e. x=0, y=0)
      # twiststeps determines the resolution of the twist (should be >= 1)  
      # returns a CSG object
      return new CSGBase()  if @sides.length is 0
      offsetvector = parseOptionAs3DVector(options, "offset", [0, 0, 1])
      twistangle = parseOptionAsFloat(options, "twist", 0)
      twiststeps = parseOptionAsInt(options, "slices", 10)
      twiststeps = 1  if twistangle is 0
      twiststeps = 1  if twiststeps < 1
      newpolygons = []
      prevtransformedcag = undefined
      prevstepz = undefined
      step = 0
  
      while step <= twiststeps
        stepfraction = step / twiststeps
        transformedcag = this.clone()
        angle = twistangle * stepfraction
        transformedcag = transformedcag.rotateZ(angle)  unless angle is 0
        translatevector = new Vector2D(offsetvector.x, offsetvector.y).times(stepfraction)
        transformedcag = transformedcag.translate(translatevector)
        bounds = transformedcag.getBounds()
        bounds[0] = bounds[0].minus(new Vector2D(1, 1))
        bounds[1] = bounds[1].plus(new Vector2D(1, 1))
        stepz = offsetvector.z * stepfraction
        if (step is 0) or (step is twiststeps)
          # bottom or top face:
          csgshell = transformedcag.toCSG(stepz - 1, stepz + 1)
          csgplane = CSGBase.fromPolygons([new Polygon([new Vertex(new Vector3D(bounds[0].x, bounds[0].y, stepz)), new Vertex(new Vector3D(bounds[1].x, bounds[0].y, stepz)), new Vertex(new Vector3D(bounds[1].x, bounds[1].y, stepz)), new Vertex(new Vector3D(bounds[0].x, bounds[1].y, stepz))])])
          flip = (step is 0)
          flip = not flip  if offsetvector.z < 0
          csgplane.inverse()  if flip
          csgplane.intersect(csgshell)
          
          # only keep the polygons in the z plane:
          csgplane.polygons.map (polygon) ->
            newpolygons.push polygon  if Math.abs(polygon.plane.normal.z) > 0.99
  
        if step > 0
          numsides = transformedcag.sides.length
          sideindex = 0
  
          while sideindex < numsides
            thisside = transformedcag.sides[sideindex]
            prevside = prevtransformedcag.sides[sideindex]
            #FIXME: see if it is possible to solve the weird triangle structure visual glitches by changing these
            p1 = new Polygon([new Vertex(thisside.vertex1.pos.toVector3D(stepz)), new Vertex(thisside.vertex0.pos.toVector3D(stepz)), new Vertex(prevside.vertex0.pos.toVector3D(prevstepz))])
            p2 = new Polygon([new Vertex(thisside.vertex1.pos.toVector3D(stepz)), new Vertex(prevside.vertex0.pos.toVector3D(prevstepz)), new Vertex(prevside.vertex1.pos.toVector3D(prevstepz))])
            
            if offsetvector.z < 0
              p1 = p1.flipped()
              p2 = p2.flipped()
            newpolygons.push p1
            newpolygons.push p2
            sideindex++
        prevtransformedcag = transformedcag
        prevstepz = stepz
        step++
      # for step  
      CSGBase.fromPolygons newpolygons
    
    check: ->
      # check if we are a valid CAG (for debugging)
      errors = []
      errors.push "Self intersects"  if @isSelfIntersecting()
      pointcount = {}
      @sides.map (side) ->
        mappoint = (p) ->
          tag = p.x + " " + p.y
          pointcount[tag] = 0  unless tag of pointcount
          pointcount[tag]++
        mappoint side.vertex0.pos
        mappoint side.vertex1.pos
  
      for tag of pointcount
        count = pointcount[tag]
        errors.push "Uneven number of sides (" + count + ") for point " + tag  if count & 1
      area = @area()
      errors.push "Area is " + area  if area < 1e-5
      if errors.length > 0
        ertxt = ""
        errors.map (err) ->
          ertxt += err + "\n"
  
        throw new Error(ertxt)
  
    canonicalized: ->
      if @isCanonicalized
        return @
      else
        factory = new FuzzyCAGFactory()
        @polygons = factory.getCAGSides(@)
        @isCanonicalized = true
        @
  
    getOutlinePaths: ->
      cag = @canonicalized()
      sideTagToSideMap = {}
      startVertexTagToSideTagMap = {}
      cag.sides.map (side) ->
        sidetag = side.getTag()
        sideTagToSideMap[sidetag] = side
        startvertextag = side.vertex0.getTag()
        startVertexTagToSideTagMap[startvertextag] = []  unless startvertextag of startVertexTagToSideTagMap
        startVertexTagToSideTagMap[startvertextag].push sidetag
  
      paths = []
      loop
        startsidetag = null
        for aVertexTag of startVertexTagToSideTagMap
          sidesForThisVertex = startVertexTagToSideTagMap[aVertexTag]
          startsidetag = sidesForThisVertex[0]
          sidesForThisVertex.splice 0, 1
          delete startVertexTagToSideTagMap[aVertexTag]  if sidesForThisVertex.length is 0
          break
        break  if startsidetag is null # we've had all sides
        connectedVertexPoints = []
        sidetag = startsidetag
        thisside = sideTagToSideMap[sidetag]
        startvertextag = thisside.vertex0.getTag()
        loop
          connectedVertexPoints.push thisside.vertex0.pos
          nextvertextag = thisside.vertex1.getTag()
          break  if nextvertextag is startvertextag # we've closed the polygon
          throw new Error("Area is not closed!")  unless nextvertextag of startVertexTagToSideTagMap
          nextpossiblesidetags = startVertexTagToSideTagMap[nextvertextag]
          nextsideindex = -1
          if nextpossiblesidetags.length is 1
            nextsideindex = 0
          else
            
            # more than one side starting at the same vertex. This means we have
            # two shapes touching at the same corner
            bestangle = null
            thisangle = thisside.direction().angleDegrees()
            sideindex = 0
  
            while sideindex < nextpossiblesidetags.length
              nextpossiblesidetag = nextpossiblesidetags[sideindex]
              possibleside = sideTagToSideMap[nextpossiblesidetag]
              angle = possibleside.direction().angleDegrees()
              angledif = angle - thisangle
              angledif += 360  if angledif < -180
              angledif -= 360  if angledif >= 180
              if (nextsideindex < 0) or (angledif > bestangle)
                nextsideindex = sideindex
                bestangle = angledif
              sideindex++
          nextsidetag = nextpossiblesidetags[nextsideindex]
          nextpossiblesidetags.splice nextsideindex, 1
          delete startVertexTagToSideTagMap[nextvertextag]  if nextpossiblesidetags.length is 0
          thisside = sideTagToSideMap[nextsidetag]
        # inner loop
        path = new CSG.Path2D(connectedVertexPoints, true)
        paths.push path
      # outer loop
      paths
      
    @linesIntersect : (p0start, p0end, p1start, p1end) ->
      # see if the line between p0start and p0end intersects with the line between p1start and p1end
      # returns true if the lines strictly intersect, the end points are not counted!
      if p0end.equals(p1start) or p1end.equals(p0start)
        d = p1end.minus(p1start).unit().plus(p0end.minus(p0start).unit()).length()
        return true  if d < 1e-5
      else
        d0 = p0end.minus(p0start)
        d1 = p1end.minus(p1start)
        return false  if Math.abs(d0.cross(d1)) < 1e-9 # lines are parallel
        alphas = CSG.solve2Linear(-d0.x, d1.x, -d0.y, d1.y, p0start.x - p1start.x, p0start.y - p1start.y)
        return true  if (alphas[0] > 1e-6) and (alphas[0] < 0.999999) and (alphas[1] > 1e-5) and (alphas[1] < 0.999999)
      #    if( (alphas[0] >= 0) && (alphas[0] <= 1) && (alphas[1] >= 0) && (alphas[1] <= 1) ) return true;
      false
      
    @PathsToDxf : (paths, blobbuilder) ->
      str = "999\nDXF generated by OpenJsCad\n  0\nSECTION\n  2\nENTITIES\n"
      blobbuilder.append str
      paths.map (path) ->
        numpoints_closed = path.points.length + ((if path.closed then 1 else 0))
        str = "  0\nLWPOLYLINE\n  90\n" + numpoints_closed + "\n  70\n" + ((if path.closed then 1 else 0)) + "\n"
        pointindex = 0
    
        while pointindex < numpoints_closed
          pointindexwrapped = pointindex
          pointindexwrapped -= path.points.length  if pointindexwrapped >= path.points.length
          point = path.points[pointindexwrapped]
          str += " 10\n" + point.x + "\n 20\n" + point.y + "\n 30\n0.0\n"
          pointindex++
        blobbuilder.append str
    
      str = "  0\nENDSEC\n  0\nEOF\n"
      blobbuilder.append str

  return {
    "CSGBase": CSGBase
    "CAGBase": CAGBase
  }
