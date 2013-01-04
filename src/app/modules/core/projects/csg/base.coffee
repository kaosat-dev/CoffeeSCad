define (require)->
  console.log "in csg main"
  CSG = {}
  TransformBase = require './transformBase'
  
  maths = require './csg.maths'
  Vertex = maths.Vertex
  Vector3D = maths.Vector3D
  Polygon = maths.Polygon
  
  props = require './csg.props'
  Properties = props.CSG.Properties
  
  class CSGBase extends TransformBase
    @defaultResolution2D : 32
    @defaultResolution3D : 12
    
    constructor:->
      @polygons = []
      @properties = new Properties()
      @isCanonicalized = true
      @isRetesselated = true
      
    
    @fromPolygons : (polygons) ->
      #Construct a CSG solid from a list of `CSG.Polygon` instances.
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
        normal = new CSG.Vector3D(x, y, z)
        plane = new CSG.Plane(normal, w)
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
        pos = new CSG.Vector3D(x, y, z)
        vertex = new CSG.Vertex(pos)
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
      
  return CSGBase