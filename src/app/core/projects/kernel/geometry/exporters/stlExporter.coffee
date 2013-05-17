define (require)->
  ###
  @author kaosat-dev 
  resulting js will be cleaned up , and contributed to three.js
  ###
  THREE = require 'three'
  THREE.stlExporter = ->
  
  THREE.stlExporter:: =
    constructor: THREE.stlExporter
    parse: (geometry) ->
      console.log geometry
      output = ""
      
      _generateString=(geometry)->
        header = "solid geometry.name \n"
        
        
        vertices = []
        for vertex in geometry.vertices
          vertices
        facets = []
        for index, face of geometry.faces
          facetData = "facet "
          normal = face.normal
          normalData = "normal #{normal.x} #{normal.y} #{normal.z}\n"
          
          if face instanceof THREE.Face3
            numvertices = 3
          else if face instanceof THREE.Face4
            numvertices = 4
            
          verticesData = "outer loop "
          for i in [0...numvertices-2]
            vertex = face.vertices[i]
            verticesData += "vertex #{vertex.x} #{vertex.y} #{vertex.z}\n"
            
          verticesData += "endloop\n"
          
          facetData = facetData + normalData + verticesData + "endfacet\n"
          facets.push()
        return header + facets.join("\n")
        ### 
        facet normal ni nj nk
          outer loop
              vertex v1x v1y v1z
              vertex v2x v2y v2z
              vertex v3x v3y v3z
          endloop
        endfacet
        ###
        
      _generateBinary=(geometry)->
        blobData = []
        
        buffer = new ArrayBuffer(4)
        int32buffer = new Int32Array(buffer, 0, 1)
        int8buffer = new Int8Array(buffer, 0, 4)
        int32buffer[0] = 0x11223344
        if int8buffer[0] != 0x44
          throw new Error("Binary STL output is currently only supported on little-endian (Intel) processors")
          
        numtriangles=0
        @currentObject.faces.map (face) ->
          numvertices = face.vertices.length
          thisnumtriangles = if numvertices >= 3 then numvertices-2 else 0 
          numtriangles += thisnumtriangles 
          
        headerarray = new Uint8Array(80)
        for i in [0...80]
          headerarray[i] = 65
        blobData.push(headerarray)
        
        ar1 = new Uint32Array(1)
        ar1[0] = numtriangles
        blobData.push(ar1)
        
        for index, face of geometry.faces
          numvertices = face.vertices.length
          for i in [0...numvertices-2]
            vertexDataArray = new Float32Array(12) 
            normal = face.normal
            vertexDataArray[0] = normal.x
            vertexDataArray[1] = normal.y
            vertexDataArray[2] = normal.z
            
            arindex = 3
            for v in [0...3]
              vv = v + ((if (v > 0) then i else 0))
              pos    = face.vertices[vv].pos
              vertexDataArray[arindex++] = pos.x
              vertexDataArray[arindex++] = pos.y
              vertexDataArray[arindex++] = pos.z
            
            attribDataArray = new Uint16Array(1)
            attribDataArray[0]=0
              
            blobData.push(vertexDataArray)
            blobData.push(attribDataArray)
            
        return blobData
        
      return _generateString(geometry)
      
  return THREE.stlExporter