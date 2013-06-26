define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  require 'bootstrap'
  THREE = require 'three'
  combo_cam = require 'combo_cam'
  detector = require 'detector'
  stats = require  'stats'
  utils = require 'utils'
  OrbitControls = require './orbitControls'
  CustomOrbitControls = require './customOrbitControls'
  TrackballControls = require './trackballControls'
  
  reqRes = require 'core/messaging/appReqRes'
  vent = require 'core/messaging/appVent'
  
  threedView_template = require "text!./visualEditorView.tmpl"
  requestAnimationFrame = require 'core/utils/anim'
  THREE.CSG = require 'core/projects/csg/csg.Three'
  
  helpers = require './helpers'
  
  contextMenuTemplate = require "text!./contextMenu.tmpl"
  
  require "ThreeCSGV2"
  
  outlineShader = require './shaders'

  class VisualEditorView extends Backbone.Marionette.ItemView
    template: threedView_template
    ui:
      renderBlock :   "#glArea"
      glOverlayBlock: "#glOverlay" 
      overlayDiv:     "#overlay" 
      
    events:
      'contextmenu' : 'rightclick'
      
    constructor:(options, settings)->
      super options
      @vent = vent 
      @settings = options.settings
        
      @stats = new stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '30px'
      @stats.domElement.style.zIndex = 100
      
      @settings.on( "change", @settingsChanged)
      @model.on("compiled", @projectCompiled)
      @model.on("compile:error", @projectCompileFailed)
      
      #screenshoting
      reqRes.addHandler "project:getScreenshot", ()=>
        return @makeScreeshot()
      
      ##########
      @defaultCameraPosition = new THREE.Vector3(100,100,200)
      @width = window.innerWidth
      @height = window.innerHeight
      @init()
      
    makeScreeshot:(width=300, height=300)=>
      # Save screenshot of 3d view
      #resizing
      srcImg = @renderer.domElement.toDataURL("image/png")
      canvas = document.createElement("canvas")
      canvas.width = width
      canvas.height = height
      ctx = canvas.getContext('2d')
      #ctx.fillStyle = "red"
      #ctx.fillRect(0, 0, canvas.width, canvas.height)
      d = $.Deferred()
      imgAsDataURL =null 
      img = new Image()
      img.onload = ()=> 
        ctx.drawImage(img, 0,0,width, height)
        imgAsDataURL = canvas.toDataURL("image/png")
        d.resolve(imgAsDataURL)
      img.src = srcImg
      return d
    
    rightclick:(ev)=>
      """used either for selection or context menu"""
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      @selectObj(x,y)
      #context-menu
      # = require "core/utils/contextMenu"
      #@contextMenu = new ContextMenu()
      #@contextMenu.show()
      
      #Contextmenu
      ###
      {ContextMenuRegion,ContextMenu} = require "views/contextMenuView"
      @contextMenu = new ContextMenu()
      @contextMenuRegion.show @contextMenu
      ###
      ev.preventDefault()
      return false
             
    selectObj:(mouseX,mouseY)=>
      v = new THREE.Vector3((mouseX/@width)*2-1, -(mouseY/@height)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      raycaster = new THREE.Raycaster(@camera.position, v.sub(@camera.position).normalize())
      intersects = raycaster.intersectObjects(@scene.children, true )
      
      unselect=()=>
        if @current?
          @current.selected=false
          @current.material = @current.origMaterial
          if @current.cage?
            @current.remove @current.cage
            @current.cage = null
          @current=null
      
      if @current?
        unselect()
      if intersects? 
        if intersects.length > 0
          if intersects[0].object.name != "workplane"
              @current = intersects[0].object
              newMat = new  THREE.MeshLambertMaterial
                color: 0xCC0000
              @current.origMaterial = @current.material
              @current.material = newMat
              @addCage @current
              #center cam on object
              @camera.lookAt(@current.position.clone())
              @controls.zoomInOn(@current)
              
              @_render()
              
      @_render()
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindAll()
      @scene.remove(@mesh)
      
      try
        @scene.remove @current.cageView
        @current=null
      
      @model = newModel
      @model.on("compiled", @projectCompiled)
      @fromCsg @model
      
    projectCompiled:(res)=>
      #compile succeeded, generate geometry from csg
      @fromCsg res
    
    projectCompileFailed:()=>
      #in case project compilation failed, remove previously generated geometry
      if @assembly?
        @scene.remove @assembly
        @assembly = null
      @_render()
              
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "bgColor"
            @setBgColor()
          when "bgColor2"
            @setBgColor()
          when "renderer"
            delete @renderer
            @init()
            @fromCsg @model
            @render()
          when "showGrid"
            if val
              @addGrid()
            else
              @removeGrid()
          when "gridSize"
            if @grid?
              @removeGrid()
              @addGrid()
          when "gridStep"
            if @grid?
              @removeGrid()
              @addGrid()
          when "gridColor"
            if @grid?
              @grid.setColor(val)
          when "gridOpacity"
            if @grid?
              @grid.setOpacity(val)
          when "gridText"
            @grid.toggleText(val)
          when "showAxes"
            if val
              @addAxes()
            else
              @removeAxes()
          when "axesSize"
              @removeAxes()
              @addAxes()
          when "shadows"
            if not val
              @renderer.clearTarget(@light.shadowMap)
              @_updateAssemblyVisualAttrs()
              @_render()
              @renderer.shadowMapAutoUpdate = false
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
            else
              @renderer.shadowMapAutoUpdate = true
              @_updateAssemblyVisualAttrs()
              @_render()
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
          when "selfShadows"
            @_updateAssemblyVisualAttrs()
            @_render()
          when "showStats"
            if val
              @ui.overlayDiv.append(@stats.domElement)
            else
              $(@stats.domElement).remove()
          when  "projection"
            if val == "orthographic"
              @camera.toOrthographic()
              #@camera.setZoom(6)
            else
              @camera.toPerspective()
              @camera.setZoom(1)
          when "position"
            @setupView(val)
          when "wireframe"
            #TODO: should not be global , but object specific?
            @_updateAssemblyVisualAttrs()
            @_render()
          when 'center'
            try
              tgt = @controls.target
              offset = new THREE.Vector3().sub(@controls.target.clone())
              @controls.target.addSelf(offset)
              @camera.position.addSelf(offset)
            catch error
              console.log "error #{error} in center"
            @camera.lookAt(@scene.position)
          when 'helpersColor'
            if @axes?
              @removeAxes()
              @addAxes()
          when 'textColor'
            if @axes?
              @removeAxes()
              @addAxes()
          when 'showConnectors'
            if val
              @assembly.traverse (object)->
                console.log "pouet"
                console.log object
                if object.name is "connectors"
                  object.visible = true 
            else
              @assembly.traverse (object)->
                console.log "pouet"
                console.log object
                if object.name is "connectors"
                  object.visible = false 
      @_render()  
       
    init:()=>
      EffectComposer = require 'EffectComposer'
      DotScreenPass = require 'DotScreenPass'
      FXAAShader = require 'FXAAShader'
      EdgeShader2 = require 'EdgeShader2'
      EdgeShader = require 'EdgeShader'
      VignetteShader = require 'VignetteShader'
      BlendShader = require 'BlendShader'
      
      @renderer=null
      #TODO: do this properly
      @configure(@settings)
      @renderer.shadowMapEnabled = true
      @renderer.shadowMapAutoUpdate = true
      
      @projector = new THREE.Projector()
      @setupScene()
      @setupOverlayScene()
      @setBgColor()
      
      if @settings.get("shadows")
        @renderer.shadowMapAutoUpdate = @settings.get("shadows")
      if @settings.get("showGrid")
        @addGrid()
      if @settings.get("showAxes")
        @addAxes()
      if @settings.get("projection") == "orthographic"
        @camera.toOrthographic()
        @camera.setZoom(6)
      else
        #@camera.toPerspective()
      if @mesh?
        @mesh.material.wireframe = @settings.get("wireframe")
      
      ####################################
      #shaders, post processing etc
      dpr = 1
      if (window.devicePixelRatio is not undefined)
        dpr = window.devicePixelRatio
      
      renderPass = new THREE.RenderPass(@scene, @camera)
      overlayRenderPass = new THREE.RenderPass(@overlayScene, @overlayCamera)
      
      copyPass = new THREE.ShaderPass( THREE.CopyShader )
      dotScreenPass = new THREE.ShaderPass( THREE.DotScreenShader )
      
      @fxAAPass = new THREE.ShaderPass(THREE.FXAAShader)
      @fxAAPass.uniforms['resolution'].value.set(1 / (@width * dpr), 1 / (@height * dpr))
      
      edgeDetectPass = new THREE.ShaderPass(THREE.EdgeShader)
      edgeDetectPass2 = new THREE.ShaderPass(THREE.EdgeShader2)
      
      vignettePass = new THREE.ShaderPass(THREE.VignetteShader) 
      
      ###
      @composer = new THREE.EffectComposer( @renderer )
      @composer.setSize(@width * dpr, @height * dpr);
      @composer.addPass(renderPass)
      @composer.addPass(@fxAAPass)
      @composer.addPass(edgeDetectPass)
      @composer.addPass(edgeDetectPass2)
      #@composer.addPass(copyPass)
      #@composer.addPass(dotScreenPass)
      @composer.addPass(vignettePass)
      ###
      #make sure the last in line renders to screen
      #@composer.passes[@composer.passes.length-1].renderToScreen = true
      
      NEAR = 0.1
      FAR = 100.0
      #depth textures, experimental
      depthTextureShader = 
        uniforms:
            "tDiffuse":   { type: "t", value:0, texture: null }
            "tDepth":     { type: "t", value: 1, texture: null }
            "cameraNear": { type: "f", value: 1.0 }
            "cameraFar":  { type: "f", value: 100.0 }
            "fogNear":    { type: "f", value: NEAR}
            "fogFar":     { type: "f", value: FAR }
        vertexShader: 
            """
            uniform float cameraNear;
            uniform float cameraFar;
            
            varying vec2 vUv;
            varying float depth;

            void main() {
                vUv = vec2( uv.x, uv.y );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                vec4 position = modelViewMatrix * vec4( position, 1.0 );
                depth =((position.z / position.w/100.0) + 1.0) * 0.1;
                //depth = 1.0 - ((gl_Position.w - 1.0) / (150.0 - 1.0));
            }"""
        fragmentShader: 
            """
            uniform sampler2D tDiffuse;
            uniform sampler2D tDepth;
            uniform float cameraNear;
            uniform float cameraFar;
            uniform float fogNear;
            uniform float fogFar;
            
            varying vec2 vUv;
            varying float depth;
            
            float cameraFarPlusNear = cameraFar + cameraNear;
            float cameraFarMinusNear = cameraFar - cameraNear;
            float cameraCoef = 2.0 * cameraNear;
            
            //Rgba depth
            float unpackDepth( const in vec4 rgba_depth )
            {
              const vec4 bit_shift = vec4( 1.0 / ( 256.0 * 256.0 * 256.0 ), 1.0 / ( 256.0 * 256.0 ), 1.0 / 256.0, 1.0 );
              float depth = dot( rgba_depth, bit_shift );
              return depth;
            }
            
            float readDepth( const in vec2 coord )
            {
              return cameraCoef / ( cameraFarPlusNear - unpackDepth( texture2D( tDepth, coord ) ) * cameraFarMinusNear );
            }
     
            void main() {
                vec4 srcColor = texture2D( tDiffuse, vUv );
                //float depth = readDepth( vUv );
                //vec3 endColor = vec3(depth);
                gl_FragColor = vec4(depth,depth,depth, 1.0);
            }"""
      depthPass = new THREE.ShaderPass(depthTextureShader)
      
      
      #color invert + alpha setting shader
      colorInvertShader = 
        uniforms:
            "tDiffuse": { type: "t", value: null }
        vertexShader: 
            """varying vec2 vUv;
            void main() {
                vUv = vec2( uv.x, uv.y );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }"""
        fragmentShader: 
            """
            uniform sampler2D tDiffuse;
            varying vec2 vUv;
     
            void main() {
                vec4 srcColor = texture2D( tDiffuse, vUv );
                vec4 endColor = vec4(1.0, 1.0, 1.0, 1.0)- srcColor * 200.0;
                if(endColor[0]<0.3)
                {
                  endColor[3]=1.0;
                }
                else
                {
                  endColor[3]=0.0;
                }
                gl_FragColor = endColor;//vec4(1.0, 1.0, 1.0, 1.0)- srcColor * 200.0 ;
            }"""
      
      #First draw using edge detect
      renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBufer: false }
      target = new THREE.WebGLRenderTarget( @width, @height, renderTargetParameters )
      
      colorInvertPass = new THREE.ShaderPass(colorInvertShader)
      
      @edgeComposer = new THREE.EffectComposer( @renderer ,target)
      @edgeComposer.setSize(@width * dpr, @height * dpr);
      @edgeComposer.addPass(renderPass)
      @edgeComposer.addPass(@fxAAPass)
      #@edgeComposer.addPass(edgeDetectPass)
      #@edgeComposer.addPass(colorInvertPass)
      #@edgeComposer.addPass(depthPass)
      @edgeComposer.passes[@edgeComposer.passes.length-1].renderToScreen = true
      
      ###
      finalshader = {
        uniforms: {
            tDiffuse: { type: "t", value: 0, texture: null }, # The base scene buffer
            tEdge: { type: "t", value: 1, texture: null } # The edge scene buffer
        },
 
        vertexShader: [
            "varying vec2 vUv;",
     
            "void main() {",
     
                "vUv = vec2( uv.x, uv.y );",
                "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
     
            "}"
        ].join("\n"),
   
        fragmentShader: [
            "uniform sampler2D tDiffuse;",
            "uniform sampler2D tEdge;",
     
            "varying vec2 vUv;",
     
            "void main() {",
     
                "vec4 texel = texture2D( tDiffuse, vUv );",
                "vec4 edge = texture2D( tEdge, vUv );",
                "gl_FragColor = texel + vec4(1.0, 0.0, 0.0, 0.0) * edge;", # Blend the two buffers together (I colorized and intensified the glow at the same time)
     
            "}"
        ].join("\n")
      }
      
      finalshader.uniforms[ "tEdge" ].texture = @edgeComposer.renderTarget2
 
      # Prepare the base scene render pass
 
      # Prepare the additive blending pass
      finalPass = new THREE.ShaderPass( finalshader )
      finalPass.needsSwap = true
      
      renderTarget = new THREE.WebGLRenderTarget( @width, @height, renderTargetParameters )
      
      @composer = new THREE.EffectComposer( @renderer, renderTarget )
      @composer.setSize(@width * dpr, @height * dpr);
      @composer.addPass(renderPass)
      
      #Add all passes
      @composer.addPass( renderPass )
      @composer.addPass( finalPass )
      finalPass.renderToScreen = true
      ###
      
      
      #here
      ###
      renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBufer: false }
      renderTarget = new THREE.WebGLRenderTarget( @width, @height, renderTargetParameters )
      @baseComposer= new THREE.EffectComposer( @renderer, renderTarget )
      @baseComposer.addPass( renderPass )
      
      #blend Composer runs the AdditiveBlendShader to combine the output of edgeComposer and baseComposer
      blendPass = new THREE.ShaderPass( THREE.BlendShader )
      blendPass.uniforms[ 'tDiffuse1' ].value = @baseComposer.renderTarget1
      blendPass.uniforms[ 'tDiffuse2' ].value = @edgeComposer.renderTarget2
      blendPass.uniforms[ 'mixRatio' ].value = 0.5
      
      @composer = new THREE.EffectComposer(@renderer )
      @composer.addPass( blendPass )
      blendPass.renderToScreen = true
      
      #@composer.passes[@composer.passes.length-1].renderToScreen = true
      ###
      @setupView(@settings.position)
      
        
    configure:(settings)=>
      if settings.get("renderer")
          renderer = settings.get("renderer")
          if renderer == "webgl"
            if detector.webgl
              console.log "Gl Renderer"
              @renderer = new THREE.WebGLRenderer 
                clearColor: 0x363335
                clearAlpha: 1
                antialias: true
                preserveDrawingBuffer   : true
              @renderer.clear() 
              @renderer.setSize(@width, @height)
              @renderer.autoClear = false
              
              @overlayRenderer = new THREE.WebGLRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
            else if not detector.webgl and not detector.canvas
              #TODO: handle this correctly
              console.log("No Webgl and no canvas (fallback) support, cannot render")
            else if not detector.webgl and detector.canvas
              @renderer = new THREE.CanvasRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
              @renderer.clear() 
              @overlayRenderer = new THREE.CanvasRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
              @renderer.setSize(@width, @height)
            else
              console.log("No Webgl and no canvas (fallback) support, cannot render")
          else if renderer =="canvas"
            if detector.canvas
              @renderer = new THREE.CanvasRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
              @renderer.clear() 
              @overlayRenderer = new THREE.CanvasRenderer 
                clearColor: 0x000000
                clearAlpha: 0
                antialias: true
              @overlayRenderer.setSize(350, 250)
              @renderer.setSize(@width, @height)
            else if not detector.canvas
              #TODO: handle this correctly
              console.log("No canvas support, cannot render")
    
    setupScene:()->
      @viewAngle=45
      ASPECT = @width / @height
      NEAR = 0.1
      FAR = 10000
      ### 
      @camera =
      new THREE.PerspectiveCamera(
          @viewAngle,
          ASPECT,
          NEAR,
          FAR)
      ###
      @camera =
       new THREE.CombinedCamera(
          @width,
          @height,
          @viewAngle,
          NEAR,
          FAR,
          NEAR,
          FAR)

      #function ( width, height, fov, near, far, orthoNear, orthoFar )
      @camera.up = new THREE.Vector3( 0, 0, 1 )
      @camera.position = @defaultCameraPosition
          
      @scene = new THREE.Scene()
      @scene.add(@camera)
      @setupLights()
      
      @cameraHelper = new THREE.CameraHelper(@camera)
    
    testCSG:()->
      if @csgExperiment?
        @scene.remove @csgExperiment?
      cube_geometry = new THREE.CubeGeometry(50, 50, 50,1,1,1)
      cube_mesh = new THREE.Mesh(cube_geometry)
      mat = new THREE.MeshLambertMaterial(
        shading: THREE.SmoothShading
        #map: THREE.ImageUtils.loadTexture("texture.png")
      )
      cube_geometry.computeVertexNormals()
      cube_mesh.material = mat
      
      @csgExperiment  = cube_mesh
      @scene.add @csgExperiment 
      return
      
      start_time = (new Date()).getTime()
      cube_geometry = new THREE.CubeGeometry(20, 20, 20)
      cube_mesh = new THREE.Mesh(cube_geometry)
      cube_mesh.position.x = 0
      cube_bsp = new ThreeBSP(cube_mesh)
      
      sphere_geometry = new THREE.SphereGeometry(12, 30, 30)
      
      sphere_mesh = new THREE.Mesh(sphere_geometry)
      sphere_mesh.position.x = 0
      sphere_mesh.rotation.y = Math.PI / 90
      sphere_bsp = new ThreeBSP(sphere_mesh)
      
      subtract_bsp = cube_bsp.subtract(sphere_bsp)
      result = subtract_bsp.toMesh(new THREE.MeshLambertMaterial(
        shading: THREE.SmoothShading
        #map: THREE.ImageUtils.loadTexture("texture.png")
      ))
      result.geometry.computeVertexNormals()
      
      if @renderer instanceof THREE.CanvasRenderer
        result.doubleSided = true
        result.material.overdraw = true
      result.name = "toto"
      @csgExperiment = result
      @scene.add @csgExperiment  
      console.log( 'Example 1: ' + ((new Date()).getTime() - start_time) + 'ms' )
      
      
    setupOverlayScene:()->
      #Experimental overlay
      ASPECT = 350 / 250
      NEAR = 1
      FAR = 10000
      @overlayCamera =
        #new THREE.PerspectiveCamera(@viewAngle,ASPECT, NEAR, FAR)
        new THREE.CombinedCamera(
          350,
          250,
          @viewAngle,
          NEAR,
          FAR,
          NEAR,
          FAR)
      @overlayCamera.up = new THREE.Vector3( 0, 0, 1 )
      
      #@overlayCamera.toOrthographic()
      #@overlayCamera.setZoom(0.05)
      @overlayScene = new THREE.Scene()
      @overlayScene.add(@overlayCamera)

    setupLights:()=>
      #console.log "Setting up lights"
      pointLight =
        new THREE.PointLight(0x333333,4)
      pointLight.position.x = -2500
      pointLight.position.y = -2500
      pointLight.position.z = 2200
      
      pointLight2 =
        new THREE.PointLight(0x333333,3)
      pointLight2.position.x = 2500
      pointLight2.position.y = 2500
      pointLight2.position.z = -5200

      @ambientColor = 0x253565
      @ambientColor = 0x354575
      @ambientColor = 0x455585
      @ambientColor = 0x565595
      ambientLight = new THREE.AmbientLight(@ambientColor)
      
      spotLight = new THREE.SpotLight( 0xbbbbbb, 1.5)    
      spotLight.position.x = 0
      spotLight.position.y = 0
      spotLight.position.z = 4000
      spotLight.castShadow = true
      @light= spotLight 
      
      @scene.add(ambientLight)
      @scene.add(pointLight)
      @scene.add(pointLight2)
      @scene.add(spotLight)
      
      @camera.add(pointLight)
      
    setupView:(val)=>
      resetCam=()=>
        @camera.position.z = 0
        @camera.position.y = 0
        @camera.position.x = 0
      switch val
        when 'diagonal'
          @camera.position = @defaultCameraPosition
          
          @overlayCamera.position.x = 150
          @overlayCamera.position.y = 150
          @overlayCamera.position.z = 250
          
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          
        when 'top'
          #@camera.toTopView()
          #@overlayCamera.toTopView()
          
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new THREE.Vector3()
            nPost.z = offset.length()
            @camera.position = nPost
            
          catch error
            @camera.position = new THREE.Vector3(0,0,@defaultCameraPosition.z)
            
          @overlayCamera.position = new THREE.Vector3(0,0,250)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          #@camera.rotationAutoUpdate = true
          #@overlayCamera.rotationAutoUpdate = true
          
        when 'bottom'
          #@camera.toBottomView()
          #@overlayCamera.toBottomView()
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.z = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,0,-@defaultCameraPosition.z)
            
          @overlayCamera.position = new THREE.Vector3(0,0,-250)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          #@camera.rotationAutoUpdate = true
          
        when 'front'
          #@camera.toFrontView()
          #@overlayCamera.toFrontView()
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.y = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,-@defaultCameraPosition.y,0)
            
          @overlayCamera.position = new THREE.Vector3(0,-250,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          #@camera.rotationAutoUpdate = true
          
        when 'back'
          #@camera.toBackView()
          #@overlayCamera.toBackView()
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.y = offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,@defaultCameraPosition.y,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(0,250,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          
        when 'left'
          #@camera.toLeftView()
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.x = offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(@defaultCameraPosition.x,0,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(250,0,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
          
        when 'right'
          #@camera.toRightView()
          try
            offset = @camera.position.clone().sub(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.x = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(-@defaultCameraPosition.x,0,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(-250,0,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayScene.position)
         
      @_render()
     
    setBgColor:()=>
      console.log "setting bg color"
      bgColor1 = @settings.get("bgColor")
      bgColor2 = @settings.get("bgColor2")
      $("body").css("background-color", bgColor1)
      if bgColor1 != bgColor2
        $("body").css("background-image", "-moz-radial-gradient(center center, circle cover, #{bgColor1},#{bgColor2}  100%)")
        $("body").css("background-image", "-webkit-radial-gradient(center center, circle cover, #{bgColor1},#{bgColor2}  100%)")
        $("body").css("background-image", "-o-radial-gradient(center center, circle cover, #{bgColor1},#{bgColor2}  100%)")
        $("body").css("background-image", "-ms-radial-gradient(center center, circle cover, #{bgColor1},#{bgColor2}  100%)")
        $("body").css("background-image", "radial-gradient(center center, circle cover, #{bgColor1},#{bgColor2}  100%)")
        $("body").css("background-repeat", "no-repeat")
        $("body").css("background-attachment", "fixed")
      else
        $("body").css("background-image", "")
        $("body").css("background-image", "")
        $("body").css("background-repeat", "")
        $("body").css("background-attachment", "")
        
        #$("body").css('background-color', @settings.get("bkGndColor"))
    addGrid:()=>
      ###
      Adds both grid & plane (for shadow casting), based on the parameters from the settings object
      ###
      if not @grid 
        gridSize = @settings.get("gridSize")
        gridStep = @settings.get("gridStep")
        gridColor = @settings.get("gridColor")
        gridOpacity = @settings.get("gridOpacity")
        gridText = @settings.get("gridText")
        
        @grid = new helpers.Grid({size:gridSize,step:gridStep,color:gridColor,opacity:gridOpacity,addText:gridText,textColor:@settings.get("textColor")})
        @scene.add @grid
       
    removeGrid:()=>
      if @grid
        @scene.remove @grid
        delete @grid
      
    addAxes:()->
      helpersColor = @settings.get("helpersColor")
      @axes = new helpers.LabeledAxes({xColor:helpersColor, yColor:helpersColor, zColor:helpersColor, size:@settings.get("gridSize")/2, addLabels:false, addArrows:false})
      @scene.add(@axes)
      
      @overlayAxes = new helpers.LabeledAxes({textColor:@settings.get("textColor"), size:@settings.get("axesSize")})
      @overlayScene.add @overlayAxes
      
    removeAxes:()->
      @scene.remove @axes
      @overlayScene.remove @overlayAxes
      delete @axes
      delete @overlayAxes
      
    addCage:(mesh)=>
      new helpers.BoundingCage({mesh:mesh, color:@settings.get("helpersColor"),textColor:@settings.get("textColor")})
            
    setupPickerHelper:()->
      canvas = document.createElement('canvas')
      canvas.width = 100
      canvas.height = 100
      context = canvas.getContext('2d')
  
      PI2 = Math.PI * 2
      context.beginPath()
      context.arc( 0, 0, 1, 0, PI2, true )
      context.closePath()
      context.fill()
      context.fillText("X", 40, 40)

      texture = new THREE.Texture( canvas )
      texture.needsUpdate = true
      @particleTexture = new THREE.Texture(canvas)
      @particleTexture.needsUpdate = true
      @particleMaterial = new THREE.MeshBasicMaterial( { map: texture, transparent: true ,color: 0x000000} )
    
    onResize:()=>
      @width =  window.innerWidth# $("#glArea").width()
      @height = window.innerHeight-10
      dpr = 1
      if (window.devicePixelRatio is not undefined)
        dpr = window.devicePixelRatio
      
      @fxAAPass.uniforms['resolution'].value.set(1 / (@width * dpr), 1 / (@height * dpr));
      @composer.setSize(@width * dpr, @height * dpr);
      
      @camera.aspect = @width / @height
      @camera.setSize(@width,@height)
      @renderer.setSize(@width, @height)
      @camera.updateProjectionMatrix()
      
      @_render()
    
    onRender:()=>
      if @settings.get("showStats")
        @ui.overlayDiv.append(@stats.domElement)
        
      @width = $("#visual").width()
      @height = window.innerHeight-10#$("#gl").height()
     
      @camera.aspect = @width / @height
      @camera.setSize(@width,@height)
      @renderer.setSize(@width, @height)
      @camera.updateProjectionMatrix()
            
      @_render()
      
      @$el.resize @onResize
      window.addEventListener('resize', @onResize, false)
      ##########
      
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      
      @controls = new CustomOrbitControls(@camera, @el)
      @controls.rotateSpeed = 1.8
      @controls.zoomSpeed = 4.2
      @controls.panSpeed = 0.8#1.4
      @controls.addEventListener( 'change', @_render )

      @controls.staticMoving = true
      @controls.dynamicDampingFactor = 0.3
      
      container2 = $(@ui.glOverlayBlock)
      container2.append(@overlayRenderer.domElement)
      
      @overlayControls = new CustomOrbitControls(@overlayCamera, @el)#Custom
      @overlayControls.noPan = true
      #@overlayControls.noZoom = true
      @overlayControls.rotateSpeed = 1.8
      @overlayControls.zoomSpeed = 0
      @overlayControls.panSpeed = 0
      @overlayControls.userZoomSpeed=0
      
      @animate()
      
    onDomRefresh:=>
      #FIXME: this needs to be moved to another view
    
    _render:()=>
      #hack
      THREE.EffectComposer.camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 );
      THREE.EffectComposer.quad = new THREE.Mesh( new THREE.PlaneGeometry( 2, 2 ), null );
      THREE.EffectComposer.scene = new THREE.Scene();
      THREE.EffectComposer.scene.add( THREE.EffectComposer.quad );
      
      #@baseComposer.render()
      @edgeComposer.render()
      #@composer.render()
      ###
      @renderer.render(@scene, @camera)
      @overlayRenderer.render(@overlayScene, @overlayCamera)
      
      if @settings.get("showStats")
        @stats.update()
      #@cameraHelper.update()
      ###
      
    animate:()=>
      @controls.update()
      @overlayControls.update()
      requestAnimationFrame(@animate)
    
    toCsgTest:(mesh)->
      csgResult = THREE.CSG.toCSG(mesh)
      if csgResult?
        console.log "CSG conversion result ok:"
    
    bla:=>
      ###
      @rtTexture = new THREE.WebGLRenderTarget(@width, @height, { minFilter: THREE.LinearFilter, magFilter: THREE.NearestFilter, format: THREE.RGBFormat } )
      vertexShader =
       """
       varying vec2 vUv;

      void main() {

        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

      }
       """
      fragShaderScreen = 
        """
      varying vec2 vUv;
      uniform sampler2D tDiffuse;

      void main() {

        gl_FragColor = texture2D( tDiffuse, vUv );

      }"""
      
      materialScreen = new THREE.ShaderMaterial( {
          uniforms: { tDiffuse: { type: "t", value: rtTexture } },
          vertexShader: vertexShader,
          fragmentShader: fragShaderScreen,
          depthWrite: false

        } )
      material2 = new THREE.MeshBasicMaterial( { color: 0xffffff, map: rtTexture } )
      ###
      #@renderer.render( @scene, @camera, rtTexture, true )
    
    outLinePasses:=>
      
    outLinePass1:=>
      #color pass
      renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBufer: false }
      outlinePass1Target = new THREE.WebGLRenderTarget( @width, @height, renderTargetParameters )
 
      outlinePass1 = new THREE.RenderPass( @scene, @camera)
 
      outlineComposer = new THREE.EffectComposer(@renderer, outlinePass1Target)
      outlineComposer.addPass( outlinePass1 )
      
      outlineComposer.render()
    
    outLinePass2:=>
      #normal pass
      renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBufer: false }
      outlinePass2Target = new THREE.WebGLRenderTarget( @width, @height, renderTargetParameters )
 
      outlinePass2 = new THREE.RenderPass( @scene, @camera)
 
      outlineComposer = new THREE.EffectComposer(@renderer, outlinePass2Target)
      outlineComposer.addPass( outlinePass2 )
    
      outlineComposer.render()
      
    fromCsg:()=>
      ###
      @testCSG()
      #vertex normal to color
      normalShader=
        vertexShader :
          """
            varying vec3 vNormal;
            void main(){
              float offset = 2.0;
              vNormal = normal;
              vec4 pos = modelViewMatrix * vec4( position + normal * offset, 1.0 );
              gl_Position = projectionMatrix * pos;
          }\n"""
          
        fragmentShader :
          """
          varying vec3 vNormal;
          void main()
          {
              float r = vNormal[0];//float(1)/ 
              float g = vNormal[1];
              float b = vNormal[2];
              gl_FragColor = vec4( r, g, b, 1.0 );
          }\n"""
      
      testMaterial = new THREE.ShaderMaterial
          uniforms: THREE.ShaderLib['basic'].uniforms,
          vertexShader: normalShader.vertexShader,
          fragmentShader: normalShader.fragmentShader,
          color: 0xFFFFFF
          transparent:false
      @csgExperiment.material = testMaterial
      return 
      ###
      #try
      start = new Date().getTime()
      #console.log "project compiled, updating view"
      if @assembly?
        @scene.remove @assembly
        @current=null
      
      @assembly = new THREE.Mesh(new THREE.Geometry())
      @assembly.name = "assembly"
      
      if @model.rootAssembly.children?
        for index, part of @model.rootAssembly.children
          @_importGeom(part,@assembly)
        
      @scene.add @assembly 
      end = new Date().getTime()
      console.log "Csg visualization time: #{end-start}"
      @_render()
      
    _importGeom:(csgObj,rootObj)=>
      geom = THREE.CSG.fromCSG(csgObj)
      shine= 1500
      spec= 1000
      opacity = geom.opacity
      
      if @renderer instanceof THREE.CanvasRenderer
        mat = new THREE.MeshLambertMaterial({color:  0xFFFFFF}) 
        mat.overdraw = true
      else 
        mat = new THREE.MeshPhongMaterial({color:  0xFFFFFF , shading: THREE.SmoothShading,  shininess: shine, specular: spec, metal: false, vertexColors: THREE.VertexColors}) 
        mat.opacity = opacity
        mat.ambient = mat.color
        mat.transparent = (opacity < 1)
        
        #mat = new THREE.MeshLambertMaterial( { color: 0xFFFFFF, vertexColors: THREE.VertexColors } );
        
      mesh = new THREE.Mesh(geom, mat)
      
      #TODO: solve this positioning issue
      mesh.position = geom.tmpPos
      delete geom.tmpPos
      
      mesh.castShadow =  @settings.get("shadows")
      mesh.receiveShadow = @settings.get("selfShadows") and @settings.get("shadows")
      mesh.material.wireframe = @settings.get("wireframe")
      mesh.name = csgObj.constructor.name
      
      if @renderer instanceof THREE.CanvasRenderer
        mesh.doubleSided = true
      
      #get object connectors
      for i, conn of geom.connectors
        #console.log "I am a connector at #{i}"
        ###
        mat =  new THREE.LineBasicMaterial({color: 0xff0000})
        line = new THREE.Line(conn, mat)
        @mesh.add line
        ###
        mat =  new THREE.MeshLambertMaterial({color: 0xff0000})
        connectorMesh = new THREE.Mesh(conn, mat)
        connectorMesh.name = "connectors"
        connectorMesh.position = conn.basePoint
        if @settings.get('showConnectors') == false
          connectorMesh.visible = false
        mesh.add connectorMesh   
       
      rootObj.add mesh
      #@_addIndicator2(mesh)
      
      #recursive, for sub objects
      if csgObj.children?
        for index, child of csgObj.children
          @_importGeom(child, mesh) 
     
    _updateAssemblyVisualAttrs:=>
      if @assembly?
        for child in @assembly.children
          child.castShadow =  @settings.get("shadows")
          child.receiveShadow = @settings.get("selfShadows") and @settings.get("shadows")
          child.material.wireframe = @settings.get("wireframe")
     
    _addIndicator:(mesh)->
      #experimental ui elements
      
      #material = new THREE.LineBasicMaterial({color: 0x000000})#
      #material = new THREE.LineDashedMaterial({color: 0x0000CC, dashSize: 5, gapSize: 2.5 })
      #object = new THREE.Line( geometrySpline, new THREE.LineDashedMaterial( { color: 0xffffff, dashSize: 1, gapSize: 0.5 } ), THREE.LineStrip );
      material = new THREE.LineDashedMaterial( {color: 0xffaa00, dashSize: 3, gapSize: 1, linewidth: 2 } )
      geometry = new THREE.Geometry()
      geometry.vertices.push(new THREE.Vector3(mesh.position.x, mesh.position.y, mesh.position.z))
      geometry.vertices.push(new THREE.Vector3(150, 0, 150))
      geometry.vertices.push(new THREE.Vector3(150, 0, 157))
      geometry.vertices.push(new THREE.Vector3(150, 0, 160))
      
      line = new THREE.Line(geometry, material, THREE.LineStrip)
      mesh.add(line)
   
    _addIndicator2:(mesh)->
      hilbert3D = (center, side, iterations, v0, v1, v2, v3, v4, v5, v6, v7) ->
        half = side / 2
        vec_s = [new THREE.Vector3(center.x - half, center.y + half, center.z - half), new THREE.Vector3(center.x - half, center.y + half, center.z + half), new THREE.Vector3(center.x - half, center.y - half, center.z + half), new THREE.Vector3(center.x - half, center.y - half, center.z - half), new THREE.Vector3(center.x + half, center.y - half, center.z - half), new THREE.Vector3(center.x + half, center.y - half, center.z + half), new THREE.Vector3(center.x + half, center.y + half, center.z + half), new THREE.Vector3(center.x + half, center.y + half, center.z - half)]
        vec = [vec_s[v0], vec_s[v1], vec_s[v2], vec_s[v3], vec_s[v4], vec_s[v5], vec_s[v6], vec_s[v7]]
        if --iterations >= 0
          tmp = []
          Array::push.apply tmp, hilbert3D(vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1)
          Array::push.apply tmp, hilbert3D(vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3)
          Array::push.apply tmp, hilbert3D(vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3)
          Array::push.apply tmp, hilbert3D(vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5)
          Array::push.apply tmp, hilbert3D(vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5)
          Array::push.apply tmp, hilbert3D(vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7)
          Array::push.apply tmp, hilbert3D(vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7)
          Array::push.apply tmp, hilbert3D(vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7)
          return tmp
        vec
      cube = (size) ->
        h = size * 0.5
        geometry = new THREE.Geometry()
        geometry.vertices.push new THREE.Vector3(-h, -h, -h)
        geometry.vertices.push new THREE.Vector3(-h, h, -h)
        geometry.vertices.push new THREE.Vector3(-h, h, -h)
        geometry.vertices.push new THREE.Vector3(h, h, -h)
        geometry.vertices.push new THREE.Vector3(h, h, -h)
        geometry.vertices.push new THREE.Vector3(h, -h, -h)
        geometry.vertices.push new THREE.Vector3(h, -h, -h)
        geometry.vertices.push new THREE.Vector3(-h, -h, -h)
        geometry.vertices.push new THREE.Vector3(-h, -h, h)
        geometry.vertices.push new THREE.Vector3(-h, h, h)
        geometry.vertices.push new THREE.Vector3(-h, h, h)
        geometry.vertices.push new THREE.Vector3(h, h, h)
        geometry.vertices.push new THREE.Vector3(h, h, h)
        geometry.vertices.push new THREE.Vector3(h, -h, h)
        geometry.vertices.push new THREE.Vector3(h, -h, h)
        geometry.vertices.push new THREE.Vector3(-h, -h, h)
        geometry.vertices.push new THREE.Vector3(-h, -h, -h)
        geometry.vertices.push new THREE.Vector3(-h, -h, h)
        geometry.vertices.push new THREE.Vector3(-h, h, -h)
        geometry.vertices.push new THREE.Vector3(-h, h, h)
        geometry.vertices.push new THREE.Vector3(h, h, -h)
        geometry.vertices.push new THREE.Vector3(h, h, h)
        geometry.vertices.push new THREE.Vector3(h, -h, -h)
        geometry.vertices.push new THREE.Vector3(h, -h, h)
        geometry

      subdivisions = 6
      recursion = 1
      
      points = hilbert3D( new THREE.Vector3( 0,0,0 ), 25.0, recursion, 0, 1, 2, 3, 4, 5, 6, 7 )
  
      spline = new THREE.Spline( points )
      geometrySpline = new THREE.Geometry()
  
      for i in [0..points.length * subdivisions]
        index = i / ( points.length * subdivisions )
        position = spline.getPoint( index )
        geometrySpline.vertices[i] = new THREE.Vector3( position.x, position.y, position.z )
      
      geometryCube = cube( 350 )
      geometryCube.computeLineDistances()
      geometrySpline.computeLineDistances()
      
      #material = new THREE.LineBasicMaterial( { color: 0xffaa00,linewidth: 10 })
      material = new THREE.LineDashedMaterial( { color: 0xffaa00, dashSize: 3, gapSize: 1, linewidth: 2 } )
      cube = new THREE.Line( geometryCube, material, THREE.LinePieces)
      spline = new THREE.Line( geometrySpline, material, THREE.LinePieces)
      
      mesh.add(cube)
      mesh.add(spline)

  return VisualEditorView
