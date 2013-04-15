define (require)->
  TransformBase = require './transformBase'
  
  maths = require './maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex2D
  Vector3D = maths.Vector3D
  Polygon = maths.Polygon
  PolygonShared = maths.PolygonShared
  Vector2D = maths.Vector2D
  Side = maths.Side
  solve2Linear = maths.solve2Linear
  OrthoNormalBasis = maths.OrthoNormalBasis
  
  properties = require './properties'
  Properties = properties.Properties
  
  trees= require './trees'
  Tree = trees.Tree
  
  utils= require './utils'
  reTesselateCoplanarPolygons = utils.reTesselateCoplanarPolygons
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAs3DVector = utils.parseOptionAs3DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  FuzzyCSGFactory = utils.FuzzyCSGFactory
  FuzzyCAGFactory = utils.FuzzyCAGFactory
  
  globals = require './globals'
  _CSGDEBUG = globals._CSGDEBUG
  
  materials = require './materials'
  
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
  guid = ->
    s4() + s4() + "-" + s4() + "-" + s4() + "-" + s4() + "-" + s4() + s4() + s4()
  
  Function::getter = (prop, get) ->
    Object.defineProperty @prototype, prop, {get, configurable: yes}
  
  Function::setter = (prop, set) ->
    Object.defineProperty @prototype, prop, {set, configurable: yes}
  
  #IMPORTANT : ALWAYS ensure that all operations that MIGHT change the bounding box , invalidate or recompute the bounding box
  
  class CSGBase extends TransformBase
    @defaultResolution2D : 32
    @defaultResolution3D : 12
    
    constructor:(options)->
      super options
      @polygons = []
      @properties = new Properties()
      @isCanonicalized = true
      @isRetesselated = true
      
      @uid = guid()
      @parent = null
      @children = [] 
      @_material = new materials.BaseMaterial()
      @color(@_material.color)
          
    @getter 'material', -> @_material
    @setter 'material', (material)->
      @_material = material
      @color(material.color)
     
    injectOptions:(defaults, options)=>
      #optionsParser = (options,defaults)->
      #this generated this.param entries based on the merge between defaults and options
      fullOptions = utils.merge(defaults, options)
      for key, value of fullOptions when not @hasOwnProperty(key) #key not in moduleKeywords
        # Assign properties to the prototype
        #@::[key] = value
        @[key]=value
      return fullOptions
    
    #TODO fix positioning and rotation
    add:(objectsToAdd...)=>
      for obj in objectsToAdd
        obj.position = obj.position.plus(@position)
        if obj.parent?
          obj.parent.remove(obj)
        obj.parent = @
        @children.push(obj)
        
    remove:(childrenToRemove...)=>
      #TODO: reset position & rotation ? 
      for child in childrenToRemove
        index = @children.indexOf(child)
        if (index!=-1)
          child.parent = null
          @children.splice(index, 1) 
          
    clear:=>
      #removes all children
      for i in [@children.length-1..0] by -1
        child = @children[i]
        @remove(child)
      @children = []
      #@children.splice(index, 1) for index, value of childrenToRemove when value in @children
      #for index, value of childrenToRemove
      #  if value in @children
      #    @children.splice(index, 1)
      
      
    clone:->
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
        if obj instanceof CSGBase or obj instanceof CAGBase
          return obj.clone()
        newInstance = new obj.constructor()
        for key of obj
          newInstance[key] = _clone obj[key]
        return newInstance

      newInstance = new @constructor()
      tmp = CSGBase.fromPolygons(@polygons)
      newInstance.polygons = tmp.polygons
      #newInstance.properties = Properties.cloneObj()
      newInstance.isCanonicalized = @isCanonicalized
      newInstance.isRetesselated = @isRetesselated
      
      for key of @
        if key not in ["polygons","isCanonicalized","isRetesselated", "constructor", "children", "uid", "parent"]
        #if key != "polygons" and key!= "isCanonicalized" and key != "isRetesselated" and key != "constructor" and key != "children" and key!= "uid" and key!= "parent"
          #console.log "key #{key}"
          if @hasOwnProperty(key)
              newInstance[key] = _clone @[key]
      for child in @children
        childClone = child.clone()
        newInstance.children.push childClone

      #newInstance = $.extend(true, {}, @)#OLD, jquery version, not web worker compatible
      newInstance.uid = guid()
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
      csg = csg.canonicalize()
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
      csg = @canonicalize()
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
  
      
      children= []
      if csg.children?
        for child in csg.children
          children.push(child.toCompactBinary()) 
  
      result =
        class: "CSG"
        realClass: @__proto__.constructor.name
        uid: @uid
        numPolygons: numpolygons
        numVerticesPerPolygon: numVerticesPerPolygon
        polygonPlaneIndexes: polygonPlaneIndexes
        polygonSharedIndexes: polygonSharedIndexes
        polygonVertices: polygonVertices
        vertexData: vertexData
        planeData: planeData
        shared: shareds
        children: children
        
  
      result
  
    toPointCloud: (cuberadius) ->
      # For debugging
      # Creates a new solid with a tiny cube at every vertex of the source solid
      csg = @reTesselate()
      result = new  CSGBase()
      
      # make a list of all unique vertices
      # For each vertex we also collect the list of normals of the planes touching the vertices
      vertexmap = {}
      csg.polygons.map (polygon) ->
        polygon.vertices.map (vertex) ->
          vertexmap[vertex.getTag()] = vertex.pos
  
      for vertextag of vertexmap
        pos = vertexmap[vertextag]
        cube = cube(
          center: pos
          radius: cuberadius
        )
        result = result.unionSub(cube, false, false)
      result = result.reTesselate()
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
        #invalidate @isCanonicalized & @isRetesselated
        @isCanonicalized = false
        @isRetesselated = false
        @reTesselate()  if retesselate
        @canonicalize()  if canonicalize
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
      #invalidate @isCanonicalized & @isRetesselated
      @isCanonicalized = false
      @isRetesselated = false
      @reTesselate()  if retesselate
      @canonicalize()  if canonicalize
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
      #invalidate @isCanonicalized & @isRetesselated
      @isCanonicalized = false
      @isRetesselated = false
      @reTesselate()  if retesselate
      @canonicalize()  if canonicalize
      @cachedBoundingBox = null
      @
      
    inverse: ->
      # Return a new CSG solid with solid and empty space switched. This solid is
      # not modified.
      flippedpolygons = (polygon.flipped() for polygon in @polygons)
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
      result = result.reTesselate()
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
      result = result.reTesselate()
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
      csg = @reTesselate()
      result = undefined
      if unionWithThis
        result = csg
      else
        result = new  CSGBase()
      
      # first extrude all polygons:
      extrudePolygon=(polygon)->
        extrudevector = polygon.plane.normal.unit().times(2 * radius)
        translatedpolygon = polygon.translate(extrudevector.times(-0.5))
        extrudedface = translatedpolygon.extrude(extrudevector)
        extrudedface = CSGBase.fromPolygons extrudedface
        result = result.unionSub(extrudedface, false, false)
      
      polygons = (extrudePolygon(polygon) for polygon in csg.polygons)
      csg.polygons = polygons
      #console.log "csg polys #{polygons}"
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
        for i in [0...numvertices]
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
        for i in [0...resolution]
          angle = i * Math.PI * 2 / resolution
          angles.push angle
        
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
  
        for i in [-1...numangles]
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
      for vertextag of vertexmap
        vertexobj = vertexmap[vertextag]
        # use the first normal to be the x axis of our sphere:
        xaxis = vertexobj.normals[0].unit()
        
        # and find a suitable z axis. We will use the normal which is most perpendicular to the x axis:
        bestzaxis = null
        bestzaxisorthogonality = 0
        
        for i in [1...vertexobj.normals.length]
          normal = vertexobj.normals[i].unit()
          cross = xaxis.cross(normal)
          crosslength = cross.length()
          if crosslength > 0.05
            if crosslength > bestzaxisorthogonality
              bestzaxisorthogonality = crosslength
              bestzaxis = normal
              
        bestzaxis = xaxis.randomNonParallelVector()  unless bestzaxis
        yaxis = xaxis.cross(bestzaxis).unit()
        zaxis = yaxis.cross(xaxis)
        sphere = sphereUtil(
          center: vertexobj.pos
          radius: radius
          resolution: resolution
          axes: [xaxis, yaxis, zaxis]
        )
        result = result.unionSub(sphere, false, false)
      result
      
    canonicalize: ->
      #"merges" duplicate vertices : if two vertices share the same position (or close to)
      #returns the first one, discards the second
      if @isCanonicalized
        return @
      else
        factory = new FuzzyCSGFactory()
        @polygons = factory.getCSGPolygons(@)
        @isCanonicalized = true
        @
  
    reTesselate: ->
      #redundant vertices issues (overlapping ones, causing the stl export problem) comes from here (finally traced it down)
      if @isRetesselated
        return @
      else
        @canonicalize()
        polygonsPerPlane = {}
        @polygons.map (polygon) ->
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
        #this is done in order to force canonicalization
        @isCanonicalized = false 
        @canonicalize()
        @
        
    getBounds: ->
      # returns an array of two Vector3Ds (minimum coordinates and maximum coordinates)
      unless @cachedBoundingBox
        minpoint = new Vector3D(0, 0, 0)
        maxpoint = new Vector3D(0, 0, 0)
        polygons = @polygons
        
        getMinMaxPoints=(polygon, i)=>
          bounds = polygon.boundingBox()
          if i is 0
            minpoint = bounds[0]
            maxpoint = bounds[1]
          else
            minpoint = minpoint.min(bounds[0])
            maxpoint = maxpoint.max(bounds[1])
            
        (getMinMaxPoints(polygon, i) for polygon,i in polygons)
       
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
    
    cutByPlane: (plane, cutTop=true) ->
      # Cut the solid by a plane. Returns the solid on the back side of the plane (cutTop == true ) or the front side (cutTop==false)
      return @ if @polygons.length is 0
      
      # Ideally we would like to do an intersection with a polygon of inifinite size
      # but this is not supported by our implementation. As a workaround, we will create
      # a cube, with one face on the plane, and a size larger enough so that the entire
      # solid fits in the cube.
      
      #do we keep the top or the bottom
      if not cutTop
        plane.flipped()
      
      # find the max distance of any vertex to the center of the plane:
      planecenter = plane.normal.times(plane.w)
      maxdistance = 0
      
      getMaxDistance = (polygon)=>
        for vertex in polygon.vertices
          distance = vertex.pos.distanceToSquared(planecenter)
          maxdistance = distance  if distance > maxdistance
        
      (getMaxDistance(polygon) for polygon in @polygons)
  
      maxdistance = Math.sqrt(maxdistance)
      maxdistance *= 1.01 # make sure it's really larger
      
      # Now build a polygon on the plane, at any point farther than maxdistance from the plane center:
      vertices = []
      orthobasis = new OrthoNormalBasis(plane)
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(maxdistance, -maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(-maxdistance, -maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(-maxdistance, maxdistance)))
      vertices.push new Vertex(orthobasis.to3D(new Vector2D(maxdistance, maxdistance)))
      polygon = new Polygon(vertices, null, plane.flipped())
      
      # and extrude the polygon into a cube, backwards of the plane:
      cube = CSGBase.fromPolygons( polygon.extrude(plane.normal.times(-maxdistance)))
      # Now we can do the intersection:
      @intersect(cube)
      #result.properties = @properties # keep original properties
      #result
      @
  
    connectTo: (myConnector, otherConnector, mirror, normalrotation) ->
      # Connect a solid to another solid, such that two Connectors become connected
      #   myConnector: a Connector of this solid
      #   otherConnector: a Connector to which myConnector should be connected
      #   mirror: false: the 'axis' vectors of the connectors should point in the same direction
      #           true: the 'axis' vector[{"vertices":[{"pos":{"_x":0,"_y":17.320508075688767,"_z":0},"tag":109},{"pos":{"_x":0,"_y":17.320508075688764,"_z":50},"tag":110},{"pos":{"_x":0,"_y":100,"_z":50},"tag":111},{"pos":{"_x":0,"_y":100,"_z":0},"tag":112}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":-1,"_y":0,"_z":0},"w":0,"tag":101}},{"vertices":[{"pos":{"_x":50,"_y":0,"_z":0},"tag":113},{"pos":{"_x":50,"_y":100,"_z":0},"tag":114},{"pos":{"_x":50,"_y":100,"_z":50},"tag":115},{"pos":{"_x":50,"_y":0,"_z":50},"tag":116}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":1,"_y":0,"_z":0},"w":50,"tag":103}},{"vertices":[{"pos":{"_x":29.999999999999975,"_y":0,"_z":0},"tag":117},{"pos":{"_x":50,"_y":0,"_z":0},"tag":113},{"pos":{"_x":50,"_y":0,"_z":50},"tag":116},{"pos":{"_x":29.99999999999997,"_y":0,"_z":50},"tag":118}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":0,"_y":-1,"_z":0},"w":0,"tag":104}},{"vertices":[{"pos":{"_x":0,"_y":100,"_z":0},"tag":112},{"pos":{"_x":0,"_y":100,"_z":50},"tag":111},{"pos":{"_x":50,"_y":100,"_z":50},"tag":115},{"pos":{"_x":50,"_y":100,"_z":0},"tag":114}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":0,"_y":1,"_z":0},"w":100,"tag":105}},{"vertices":[{"pos":{"_x":50,"_y":100,"_z":0},"tag":114},{"pos":{"_x":50,"_y":0,"_z":0},"tag":113},{"pos":{"_x":29.999999999999975,"_y":0,"_z":0},"tag":117},{"pos":{"_x":0,"_y":17.320508075688767,"_z":0},"tag":109},{"pos":{"_x":0,"_y":100,"_z":0},"tag":112}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":0,"_y":0,"_z":-1},"w":0,"tag":106}},{"vertices":[{"pos":{"_x":50,"_y":0,"_z":50},"tag":116},{"pos":{"_x":50,"_y":100,"_z":50},"tag":115},{"pos":{"_x":0,"_y":100,"_z":50},"tag":111},{"pos":{"_x":0,"_y":17.320508075688764,"_z":50},"tag":110},{"pos":{"_x":29.99999999999997,"_y":0,"_z":50},"tag":118}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":0,"_y":0,"_z":1},"w":50,"tag":107}},{"vertices":[{"pos":{"_x":29.999999999999975,"_y":0,"_z":0},"tag":117},{"pos":{"_x":29.99999999999997,"_y":0,"_z":50},"tag":118},{"pos":{"_x":0,"_y":17.320508075688764,"_z":50},"tag":110},{"pos":{"_x":0,"_y":17.320508075688767,"_z":0},"tag":109}],"shared":{"color":null,"name":null,"tag":102},"plane":{"normal":{"_x":-0.4999999999999998,"_y":-0.8660254037844389,"_z":0},"w":-15,"tag":108}}] s of the connectors should point in opposite direction
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
  
    color: (rgba) ->
      if rgba.length<4
        rgba[3]=1
      newshared = new PolygonShared([rgba[0], rgba[1], rgba[2], rgba[3]])
      @setShared newshared
    
    getTransformationToFlatLying: ->
      # Get the transformation that transforms this CSG such that it is lying on the z=0 plane, 
      # as flat as possible (i.e. the least z-height).
      # So that it is in an orientation suitable for CNC milling    
      if @polygons.length is 0
        new Matrix4x4() # unity
      else
        
        # get a list of unique planes in the CSG:
        csg = @canonicalize()
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
        z0connectorx = new Connector([0, 0, 0], [0, 0, -1], xvector)
        z0connectory = new Connector([0, 0, 0], [0, 0, -1], yvector)
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
            planeconnector = new Connector(pointonplane, plane.normal, xvector)
            transformation = planeconnector.getTransformationTo(z0connectorx, false, 0)
          else
            
            # y is better:
            planeconnector = new Connector(pointonplane, plane.normal, yvector)
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
            transformation = transformation.multiply(Matrix4x4.translation(translation))
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
      csg = @clone().canonicalize()
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
          
          throw new Error("Assertion failed")  unless sidetag of sidemap
          idx = -1
          sideobjs = sidemap[sidetag]
          for i in [0...sideobjs.length]
            sideobj = sideobjs[i]
            continue  unless sideobj.vertex0 is vertex0
            continue  unless sideobj.vertex1 is vertex1
            if polygonindex?
              if(sideobj.polygonindex != polygonindex) then continue
            idx = i
            break
            
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
  
              for directionindex in [0...2]
                startvertex = (if (directionindex is 0) then sideobj.vertex0 else sideobj.vertex1)
                endvertex = (if (directionindex is 0) then sideobj.vertex1 else sideobj.vertex0)
                startvertextag = startvertex.getTag()
                endvertextag = endvertex.getTag()
                matchingsides = []
                if directionindex is 0
                  matchingsides = vertextag2sideend[startvertextag]  if startvertextag of vertextag2sideend
                else
                  matchingsides = vertextag2sidestart[startvertextag]  if startvertextag of vertextag2sidestart
  
                for matchingsideindex in [0...matchingsides.length]
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
    constructor:(options) ->
      super(options)
      @sides = []
      @isCanonicalized=false
      
      @uid = guid()
      @parent = null
      @children = [] 
  
    add:(objectsToAdd...)=>
      for obj in objectsToAdd
        obj.position = obj.position.plus(@position)
        if obj.parent?
          obj.parent.remove(obj)
        obj.parent = @
        @children.push(obj)
        
    remove:(childrenToRemove...)=>   
      for child in childrenToRemove
        index = @children.indexOf(child)
        if (index!=-1)
          child.parent = null
          @children.splice(index, 1) 
    clear:=>
      #removes all children
      for i in [@children.length-1...0] by -1
        child = @children[i]
        @remove(child)
      @children = []
      
    clone:->
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
        for key of obj
          newInstance[key] = _clone obj[key]
        return newInstance

      newInstance = new @constructor()
      tmp = CAGBase.fromSides(@sides)
      newInstance.sides = tmp.sides
      #newInstance.properties = Properties.cloneObj()
      newInstance.isCanonicalized = @isCanonicalized
      for key of @
        if key not in ["polygons","isCanonicalized","isRetesselated", "constructor", "children", "uid", "parent"]
        #if key != "polygons" and key!= "isCanonicalized"
          if @.hasOwnProperty(key)
              newInstance[key] = _clone @[key]
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
      result.canonicalize()
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
      cag = @canonicalize()
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
        
      children= []
      if cag.children?
        for child in cag.children
          children.push(child.toCompactBinary()) 
  
  
      result =
        class: "CAG"
        realClass: @__proto__.constructor.name
        children:children
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
  
      r.reTesselate()
      r.canonicalize()
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
      r.reTesselate()
      r.canonicalize()
      r = CAGBase.fromFakeCSG(r)
      r.canonicalize()
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
  
      r.reTesselate()
      r.canonicalize()
      r = CAGBase.fromFakeCSG(r)
      r.canonicalize()
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
      cag = @canonicalize()
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
  
    canonicalize: ->
      if @isCanonicalized
        return @
      else
        factory = new FuzzyCAGFactory()
        @polygons = factory.getCAGSides(@)
        @isCanonicalized = true
        @
  
    getOutlinePaths: ->
      cag = @canonicalize()
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
        path = new Path2D(connectedVertexPoints, true)
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
        alphas = solve2Linear(-d0.x, d1.x, -d0.y, d1.y, p0start.x - p1start.x, p0start.y - p1start.y)
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


  rootAssembly = new CSGBase()
  ### 
  class Assembly extends csg.CSGBase
        constructor:()->
          super
  ###
  return {
    "CSGBase": CSGBase
    "CAGBase": CAGBase
    "rootAssembly":rootAssembly
  }
