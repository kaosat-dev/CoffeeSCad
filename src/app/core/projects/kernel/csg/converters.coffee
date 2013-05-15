define (require)->
  base = require './csgBase' 
  CSGBase = base.CSGBase
  CAGBase = base.CAGBase
  
  maths = require './maths'
  Plane = maths.Plane
  Vector3D= maths.Vector3D
  Vector2D= maths.Vector2D
  
  Vertex= maths.Vertex
  Vertex2D= maths.Vertex
  Polygon = maths.Polygon
  PolygonShared= maths.PolygonShared
  Side = maths.Side
  
  CSGfromCompactBinary = (bin) ->
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
      PolygonShared.fromObject shared
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
    
    #necessary hack as we lose the actual class/proto information when transfering back from a web worker
    csg.realClassName = bin.realClass
    csg.uid = bin.uid
    #csg.__proto__.constructor.name = bin.realClass
    
    csg.children = []
    for child in bin.children
      csg.children.push(fromCompactBinary(child))
    csg
    
  CAGfromCompactBinary = (bin) ->
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
      
      cag.children = []
      for child in bin.children
        cag.children.push(fromCompactBinary(child))
      cag  
  
  fromCompactBinary = (bin)-> 
    if bin.class is "CSG"
      return CSGfromCompactBinary(bin)
    else if bin.class is "CAG"
      return CAGfromCompactBinary(bin)
    else throw new Error("Not a CSG or a CAG")
      
      
  return {
    "CSGfromCompactBinary":CSGfromCompactBinary
    "CAGfromCompactBinary":CAGfromCompactBinary
    "fromCompactBinary":fromCompactBinary
  }
