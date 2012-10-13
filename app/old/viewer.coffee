define (require) ->
  lightgl = require 'lightgl'
  csg = require 'csg'
  
  class Viewer
    #A viewer is a WebGL canvas that lets the user view a mesh. The user can
    #tumble it around by dragging the mouse.
    constructor: (@containerelement, width, height, initialdepth)->
      console.log("in viewer init: container element")
      console.log(@containerelement)
      @width = if width? then width else 800
      @height = if height? then height else 600
      @initialdepth = if initialdepth? then initialdepth else 50
  
      gl = GL.create()
      @gl = gl
      @angleX = 0
      @angleY = 0
      @viewpointX = 0
      @viewpointY = 0
      @viewpointZ = @initialdepth
      
      
      #Draw triangle lines:
      @drawLines = false
      # Set to true so lines don't use the depth buffer
      @lineOverlay = false
  
      if !OpenCoffeeScad.isChrome()
        msg="Please note: OpenJsCad currently only runs reliably on Google Chrome!"
      # Set up the viewport
      gl.canvas.width = @width
      gl.canvas.height = @height
      gl.viewport(0, 0, @width, @height)
      gl.matrixMode(gl.PROJECTION)
      gl.loadIdentity()
      gl.perspective(45, @width / @height, 0.5, 1000)
      gl.matrixMode(gl.MODELVIEW)
  
      # Set up WebGL state
      gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
      #gl.clearColor(0.95, 0.95, 0.95, 1)
      gl.clearColor(1, 1, 1, 1)
      gl.enable(gl.DEPTH_TEST)
      gl.enable(gl.CULL_FACE)
      gl.polygonOffset(1, 1)
  
      # Black shader for wireframe
      @blackShader = new GL.Shader("void main() {gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;}",
        "void main() {gl_FragColor = vec4(0.0, 0.0, 0.0, 0.1);}")
      # Shader with diffuse and specular lighting
      @lightingShader = new GL.Shader("
        varying vec3 color;
        varying vec3 normal;
        varying vec3 light;
        void main() {
          const vec3 lightDir = vec3(1.0, 2.0, 3.0) / 3.741657386773941;
          light = lightDir;
          color = gl_Color.rgb;
          normal = gl_NormalMatrix * gl_Normal;
          gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        }", 
        "
        varying vec3 color;
        varying vec3 normal;
        varying vec3 light;
        void main() {
          vec3 n = normalize(normal);
          float diffuse = max(0.0, dot(light, n));
          float specular = pow(max(0.0, -reflect(light, n).z), 10.0) * sqrt(diffuse);
          gl_FragColor = vec4(mix(color * (0.3 + 0.7 * diffuse), vec3(1.0), specular), 1.0);
        }
      "
      )
      @containerelement.appendChild(gl.canvas)
  
      gl.onmousemove = (e) =>
        @onMouseMove(e)
  
      gl.ondraw = (e) =>
        @onDraw()
      @clear()
  
    setCsg:(csg) =>
      @mesh = @csgToMesh(csg)
      @onDraw()
      return
  
    clear: () =>
      # empty mesh:
      @mesh = new GL.Mesh()
      @onDraw()
      return
      
    supported: () ->
      return !!@gl
  
    onMouseMove: (e) ->
      if (e.dragging)
        e.preventDefault()
        if(e.altKey)
          factor = 1e-2
          @viewpointZ *= Math.pow(2,factor * e.deltaY)
        else if(e.shiftKey)
          factor = 5e-3;
          @viewpointX += factor * e.deltaX * @viewpointZ
          @viewpointY -= factor * e.deltaY * @viewpointZ
        else
          @angleY += e.deltaX * 2;
          @angleX += e.deltaY * 2;
          @angleX = Math.max(-90, Math.min(90, @angleX))
        @onDraw()
  
    onDraw: (e) =>
      #console.log("on draw")
      gl = @gl
      gl.makeCurrent()
  
      gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
      gl.loadIdentity()
      gl.translate(@viewpointX, @viewpointY, -@viewpointZ)
      gl.rotate(@angleX, 1, 0, 0)
      gl.rotate(@angleY, 0, 1, 0)
  
      if !@lineOverlay
        gl.enable(gl.POLYGON_OFFSET_FILL)
      @lightingShader.draw(@mesh, gl.TRIANGLES)
      if !@lineOverlay
        gl.disable(gl.POLYGON_OFFSET_FILL)
  
      if(@drawLines)
        if (@lineOverlay) then gl.disable(gl.DEPTH_TEST)
        gl.enable(gl.BLEND)
        @blackShader.draw(@mesh, gl.LINES)
        gl.disable(gl.BLEND)
        if (@lineOverlay) then gl.enable(gl.DEPTH_TEST)
  
    
    csgToMesh : (csg) ->
     # Convert from CSG solid to GL.Mesh object
     csg = csg.canonicalized()
     mesh = new GL.Mesh({ normals: true, colors: true })
     vertexTag2Index = {}
     vertices = []
     colors = []
     triangles = []
    # set to true if we want to use interpolated vertex normals
    # this creates nice round spheres but does not represent the shape of
    # the actual model
     smoothlighting = false
     polygons = csg.toPolygons()
     numpolygons = polygons.length
     #console.log("numpolygons: #{numpolygons}")
     try
       for polygonindex in [0...numpolygons]  
         polygon = polygons[polygonindex]
         #console.log("Polygon: index #{polygonindex}")
         #console.log(polygon)
         color = [0,0,1]
         if(polygon.shared && polygon.shared.color)
            color = polygon.shared.color
         indices = polygon.vertices.map( (vertex) ->
             vertextag = vertex.getTag()
             vertexindex
             if(smoothlighting && (vertextag in vertexTag2Index))
               vertexindex = vertexTag2Index[vertextag]
             else
              vertexindex = vertices.length
              vertexTag2Index[vertextag] = vertexindex
              vertices.push([vertex.pos.x, vertex.pos.y, vertex.pos.z])
              colors.push(color)
             return vertexindex
         )
         for i in [2...indices.length] 
            triangles.push([indices[0], indices[i - 1], indices[i]])
      catch e
        console.log("Error #{e}")
      mesh.triangles = triangles
      mesh.vertices = vertices
      mesh.colors = colors
      mesh.computeWireframe()
      mesh.computeNormals()
      return mesh
  return Viewer
