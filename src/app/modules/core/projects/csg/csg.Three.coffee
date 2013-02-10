define (require) ->
  THREE = require 'three'
  #
  #    THREE.CSG
  # @author Chandler Prall <chandler.prall@gmail.com> http://chandler.prallfamily.com
  # @modified by Mark Moissette 
  # Wrapper for Evan Wallace's CSG library (https://github.com/evanw/csg.js/)
  # Provides CSG capabilities for Three.js models.
  # 
  # Provided under the MIT License
  #
  THREE.CSG =
    toCSG: (three_model, offset, rotation) ->
      i = undefined
      geometry = undefined
      offset = undefined
      polygons = undefined
      vertices = undefined
      rotation_matrix = undefined
      
      #if ( !CSG ) {
      #     throw 'CSG library not loaded. Please get a copy from https://github.com/evanw/csg.js';
      #   }
      if three_model instanceof THREE.Mesh
        geometry = three_model.geometry
        offset = offset or three_model.position
        rotation = rotation or three_model.rotation
      else if three_model instanceof THREE.Geometry
        geometry = three_model
        offset = offset or new THREE.Vector3(0, 0, 0)
        rotation = rotation or new THREE.Vector3(0, 0, 0)
      else
        throw "Model type not supported."
      rotation_matrix = new THREE.Matrix4().setRotationFromEuler(rotation)
      
      #console.log("geometry");
      #console.log(geometry);
      #FIXME: changed vertices[x].position.clone( ) to vertices[x].clone( ) (as per changes in the geometry class)
      polygons = []
      i = 0
      while i < geometry.faces.length
        if geometry.faces[i] instanceof THREE.Face3
          vertices = []
          
          #vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].a].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #                vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].b].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #                vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].c].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #                
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].a].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].b].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].c].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          
          #console.log("before poly push");
          polygons.push new CSG.Polygon(vertices)
        else if geometry.faces[i] instanceof THREE.Face4
          
          #console.log("4 sided faces");
          vertices = []
          
          #vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].a].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].b].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].d].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       
          
          #CORRECTED , but clunky
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].a].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].b].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].d].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          polygons.push new CSG.Polygon(vertices)
          vertices = []
          
          #CORRECTED , but clunky
          #vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].b].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].c].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       vertices.push( new CSG.Vertex( rotation_matrix.multiplyVector3( geometry.vertices[geometry.faces[i].d].clone( ).addSelf( offset ) ), [ geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z ] ) );
          #       
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].b].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].c].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          v = rotation_matrix.multiplyVector3(geometry.vertices[geometry.faces[i].d].clone().addSelf(offset))
          v_cor = new CSG.Vector3D(v.x, v.y, v.z)
          vertices.push new CSG.Vertex(v_cor, [geometry.faces[i].normal.x, geometry.faces[i].normal.y, geometry.faces[i].normal.z])
          polygons.push new CSG.Polygon(vertices)
        else
          throw "Model contains unsupported face."
        i++
      console.log "THREE.CSG toCSG done"
      CSG.fromPolygons polygons
  
    fromCSG: (csg_model) ->
      #TODO: fix normals?
      i = undefined
      j = undefined
      vertices = undefined
      face = undefined
      three_geometry = new THREE.Geometry()
      polygons = csg_model.toPolygons()
      properties = csg_model.properties    
      #console.log(csg_model);
      #throw "CSG library not loaded. Please get a copy from https://github.com/evanw/csg.js"  unless CSG
      i = 0
      while i < polygons.length
        color = new THREE.Color(0xaaaaaa)
        try
          poly = polygons[i]
          
          #console.log("poly");
          #         console.log(poly);
          #         console.log("shared");
          #         console.log(poly.shared.name);
          
          # console.log("color check");
          #                console.log(poly.shared.color[0]);
          color.r = poly.shared.color[0]
          color.g = poly.shared.color[1]
          color.b = poly.shared.color[2]
        
        #console.log("Error: "+e);
        
        # Vertices
        vertices = []
        j = 0
        while j < polygons[i].vertices.length
          vertices.push @getGeometryVertice(three_geometry, polygons[i].vertices[j].pos)
          j++
        vertices.pop()  if vertices[0] is vertices[vertices.length - 1]
        j = 2
  
        while j < vertices.length
          tmp = new THREE.Vector3().copy(polygons[i].plane.normal)
          b = tmp[2]
          tmp[2] = tmp[1]
          tmp[1] = b
          face = new THREE.Face3(vertices[0], vertices[j - 1], vertices[j], tmp)
          face.vertexColors[0] = color
          face.vertexColors[1] = color
          face.vertexColors[2] = color
          three_geometry.faces.push face
          three_geometry.faceVertexUvs[0].push new THREE.UV()
          j++
        i++
        
      
      connectors = []
      searchForConnectors = (obj)->
        for index, prop of obj
          if (typeof prop) != "function"
            #console.log prop
            #console.log "type "+ typeof prop
            if prop.constructor.name is "Connector"
              #console.log "connector"
              connector = {}
              point = prop.point
              axisvector = prop.axisvector
              geometry = new THREE.CubeGeometry(10,10,10)
              geometry.basePoint = new THREE.Vector3(point.x, point.y, point.z)
             
              ###
              geometry = new THREE.Geometry()
              geometry.vertices.push(new THREE.Vector3(point.x, point.y, point.z))
              end = new THREE.Vector3(point.x+axisvector.x, point.y+axisvector.y, point.z+axisvector.z)
              end.multiplyScalar(3)
              geometry.vertices.push(end)
              ###
              
              connectors.push(geometry)
            ###
            try
              if "point" of prop
                #console.log "haspoint"
            catch error
            ###
            searchForConnectors(prop)
      
      searchForConnectors(properties)
     
      three_geometry.connectors  = connectors
      
      three_geometry.computeBoundingBox()
      three_geometry
  
    getGeometryVertice: (geometry, vertice_position) ->
      i = undefined
      i = 0
      while i < geometry.vertices.length
        
        # Vertice already exists
        return i  if geometry.vertices[i].x is vertice_position.x and geometry.vertices[i].y is vertice_position.y and geometry.vertices[i].z is vertice_position.z
        i++
      geometry.vertices.push new THREE.Vector3(vertice_position.x, vertice_position.y, vertice_position.z)
      geometry.vertices.length - 1
  return THREE.CSG