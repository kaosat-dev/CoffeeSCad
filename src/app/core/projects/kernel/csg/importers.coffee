define (require)->
  #slightly modified STLLoader from three.js : https://github.com/mrdoob/three.js/blob/master/examples/js/loaders/STLLoader.js
  #and using bits of https://github.com/garyhodgson/openscad-openjscad-translator
  maths = require './maths'
  Vertex = maths.Vertex
  Vector3D = maths.Vector2D
  Polygon = maths.Polygon
  
  class StlDecoder
    constructor:->
      @headerLength = 80
      @dataType = null

    import:(data)=>
      
    bin2str: (buf) ->
      array_buffer = new Uint8Array(buf)
      str = ""
      i = 0
  
      while i < buf.byteLength
        str += String.fromCharCode(array_buffer[i]) # implicitly assumes little-endian
        i++
      str

    isASCII: (buf) ->
      dv = new DataView(buf)
      str = ""
      i = 0
  
      while i < 5
        str += String.fromCharCode(dv.getUint8(i, true)) # assume little-endian
        i++
      str.toLowerCase() is "solid" # All ASCII stl files begin with 'solid'

    parse: (buf) ->
      if @isASCII(buf)
        str = @bin2str(buf)
        @parseASCII str
      else
        @parseBinary buf

    parseASCII: (data) ->
      csgPolygons = []
      
      patternFace = /facet([\s\S]*?)endfacet/g
      result = undefined
      while (result = patternFace.exec(data))?
        text = result[0]
        csgVertices = []
        # Normal
        patternNormal = /normal[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g
        normal = new Vector3D(parseFloat(result[1]), parseFloat(result[3]), parseFloat(result[5]))  while (result = patternNormal.exec(text))?
        # Vertex
        patternVertex = /vertex[\s]+([-+]?[0-9]+\.?[0-9]*([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+[\s]+([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)+/g
        csgVertices.push(new Vertex(new Vector3D(parseFloat(result[1]), parseFloat(result[3]), parseFloat(result[5]))))  while (result = patternVertex.exec(text))?
        
        csgNormal = new Vector3D(normal)
        csgPlane = new Plane(csgNormal, 1)
        csgPolygons.push(new Polygon(csgVertices, null, csgPlane))
        
      csgPolygons

    parseBinary: (buf) ->
      # STL binary format specification, as per http://en.wikipedia.org/wiki/STL_(file_format)
      #
      # UINT8[80] – Header
      # UINT32 – Number of triangles
      #
      # foreach triangle
      #   REAL32[3] – Normal vector
      #   REAL32[3] – Vertex 1
      #   REAL32[3] – Vertex 2
      #   REAL32[3] – Vertex 3
      #   UINT16 – Attribute byte count
      # end
      #
      csgPolygons = []
      
      headerLength = 80
      dataOffset = 84
      faceLength = 12 * 4 + 2
      le = true # is little-endian  // This might be processor dependent...
      
      # var header = new Uint8Array(buf, 0, headerLength); // not presently used
      dvTriangleCount = new DataView(buf, headerLength, 4)
      numTriangles = dvTriangleCount.getUint32(0, le)
      i = 0
      while i < numTriangles
        dv = new DataView(buf, dataOffset + i * faceLength, faceLength)
        normal = new Vector3D(dv.getFloat32(0, le), dv.getFloat32(4, le), dv.getFloat32(8, le))
        v = 3
        csgVertices = []
        while v < 12
          csgVertices.push new Vertex(new Vector3D(dv.getFloat32(v * 4, le), dv.getFloat32((v + 1) * 4, le), dv.getFloat32((v + 2) * 4, le)))
          v += 3
        len = csgVertices.length
        csgPlane = new Plane(normal, 1)
        #csgPolygons.push new THREE.Face3(len - 3, len - 2, len - 1, normal)
        csgPolygons.push(new Polygon(csgVertices, null, csgPlane))
        i++
      csgPolygons


