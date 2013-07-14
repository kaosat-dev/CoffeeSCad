define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  require 'bootstrap'
  THREE = require 'three'
  combo_cam = require 'combo_cam'
  detector = require 'detector'
  stats = require  'stats'
  utils = require 'utils'
  reqRes = require 'core/messaging/appReqRes'
  vent = require 'core/messaging/appVent'
  
  #
  require 'backbone_mousetrap'
  
  #OrbitControls = require './controls/orbitControls'
  OrbitControls = require 'OrbitControls'
  CustomOrbitControls = require './controls/customOrbitControls'
  transformControls = require 'transformControls'
  
  Shaders = require './shaders/shaders'
  helpers = require './helpers'
  RenderManager = require 'RenderManager'
  
  ObjectExport = require 'ObjectExport'
  ObjectParser = require 'ObjectParser'
  
  threedView_template = require "text!./visualEditorView.tmpl"
  requestAnimationFrame = require 'core/utils/anim'
  THREE.CSG = require 'core/projects/csg/csg.Three'
  
  
  includeMixin = require 'core/utils/mixins/mixins'
  dndMixin = require 'core/utils/mixins/dragAndDropRecieverMixin'
  
  ###
     keyboardEvents: 
      'command+shift+t': 'totoPouet'
      'control+shift+t': 'totoPouet'
      'control+t': 'totoPouet'
      'control+e': 'totoPouet'
      'shift+e': 'totoPouet'
      'ctrl+s': 'totoPouet'
    ###

  class VisualEditorView extends Backbone.Marionette.ItemView
    el: $("#visual")
    @include dndMixin
    template: threedView_template
    ui:
      renderBlock :   "#glArea"
      glOverlayBlock: "#glOverlay" 
      overlayDiv:     "#overlay" 
      
    events:
      "mousedown"   : "_onSelectAttempt"
      "contextmenu" : "_onRightclick"
      "mousemove"   : "_onMouseMove"
      "resize:stop" : "onResizeStop"
      "resize"      : "onResizeStop"
      
      "mousedown .switchProjection":          "switchProjection"
      "mousedown .toggleGrid"      :          "toggleGrid"
      "mousedown .toggleAxes"      :          "toggleAxes"
      "mousedown .toggleAutoRotate"      :    "toggleAutoRotate"
      "mousedown .toggleOutlines"      :    "toggleOutlines"
      "mousedown .switchViewType":      "switchViewType"
     
     
    totoPouet:(e)->
      if e.preventDefault
        e.preventDefault()
      else
        # internet explorer
        e.returnValue = false
      console.log "oh yeah , keyboard"
            
    constructor:(options, settings)->
      super options
      @vent = vent 
      @settings = options.settings
      
      @settings.on("change", @settingsChanged)
      @_setupEventBindings()
      
      #screenshoting
      reqRes.addHandler "project:getScreenshot", ()=>
        return @makeScreenshot()
      
      ##########
      @renderer=null
      @overlayRenderer = null
      @selectionHelper = null
      
      @defaultCameraPosition = new THREE.Vector3(100,100,200)
      @width = 320
      @height = 240
      @resUpscaler = 1
      @dpr = 1
      @hRes = 320
      @vRes = 240
      
      @noControlChange = false 
      
      @stats = new stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '30px'
      @stats.domElement.style.zIndex = 100

    init:()=>
      # Setup the RenderManager
      @renderManager = new THREE.Extras.RenderManager(@renderer)
      
      @setupRenderers(@settings)
      @setupScenes()
      @setupPostProcess()
      
      @selectionHelper = new helpers.SelectionHelper({camera:@camera,color:0x000000,textColor:@settings.textColor})
      @selectionHelper.addEventListener( 'selected',  @onObjectSelected)
      @selectionHelper.addEventListener( 'unselected', @onObjectUnSelected)
      @selectionHelper.addEventListener( 'hoverIn', @onObjectHover)
      @selectionHelper.addEventListener( 'hoverOut', @onObjectHover)
      
      if @settings.shadows then @renderer.shadowMapAutoUpdate = @settings.shadows
      if @settings.showGrid then @addGrid()
      if @settings.showAxes then @addAxes()
      
      @setBgColor()
      @setupView(@settings.position)
      @setupContextMenu()
      
    
    setupRenderers:(settings)=>
      getValidRenderer=(settings)->
        renderer = settings.renderer
        if not detector.webgl and not detector.canvas
          throw new Error("No Webgl and no canvas (fallback) support, cannot render")
        if renderer == "webgl"
          if detector.webgl
            return renderer
          else if not detector.webgl and detector.canvas
            return "canvas"
        if renderer == "canvas"
          if detector.canvas
            return renderer
      
      renderer = getValidRenderer(settings)
      console.log "#{renderer} renderer"
      if renderer is "webgl"
        @renderer = new THREE.WebGLRenderer 
          antialias: true
          preserveDrawingBuffer   : true
        @renderer.setSize(@width, @height)
        @renderer.clear() 
        @renderer.setClearColor(0x00000000,0)
        @renderer.shadowMapEnabled = true
        @renderer.shadowMapAutoUpdate = true
        @renderer.shadowMapSoft = true
        
        @overlayRenderer = new THREE.WebGLRenderer 
          antialias: true
        @overlayRenderer.setSize(350, 250)
        @overlayRenderer.setClearColor(0x00000000,0)
      else if renderer is "canvas"
        @renderer = new THREE.CanvasRenderer 
          antialias: true
        @renderer.setSize(@width, @height)
        @renderer.clear()
        
        @overlayRenderer = new THREE.CanvasRenderer 
          clearColor: 0x000000
          clearAlpha: 0
          antialias: true
        @overlayRenderer.setSize(350, 250)
        @overlayRenderer.setClearColor(0x00000000,0)

    setupScenes:()->
      @scene = require './scenes/main'
      @renderManager.add("main", @scene, @camera)
      @setupScene()
      @setupOverlayScene() 
             
    setupScene:()->
      @viewAngle=40
      ASPECT = @width / @height
      @NEAR = 1
      @FAR = 10000
      @camera =
       new THREE.CombinedCamera(
          @width,
          @height,
          @viewAngle,
          @NEAR,
          @FAR,
          @NEAR,
          @FAR)

      @camera.up = new THREE.Vector3( 0, 0, 1 )
      @camera.position.copy(@defaultCameraPosition)
      @camera.defaultPosition.copy(@defaultCameraPosition)
          
      @scene.add(@camera)
      @cameraHelper = new THREE.CameraHelper(@camera)
      
    setupOverlayScene:()->
      #Experimental overlay
      NEAR = 0.1
      FAR = 1000
      @overlayCamera = new THREE.CombinedCamera(350 / 2,250 / 2, @viewAngle, NEAR, FAR, NEAR, FAR)
      @overlayCamera.position.copy(new THREE.Vector3( 150, 150, 250 ))
      @overlayCamera.defaultPosition.copy(new THREE.Vector3( 150, 150, 250 ))
      @overlayCamera.up = new THREE.Vector3( 0, 0, 1 )
      @overlayCamera.toOrthographic()
      
      @overlayScene = new THREE.Scene()
      @overlayScene.add(@overlayCamera)

    setupPostProcess:=>
      if @renderer instanceof THREE.WebGLRenderer
        EffectComposer = require 'EffectComposer'
        DotScreenPass = require 'DotScreenPass'
        FXAAShader = require 'FXAAShader'
        EdgeShader2 = require 'EdgeShader2'
        EdgeShader = require 'EdgeShader'
        VignetteShader = require 'VignetteShader'
        BlendShader = require 'BlendShader'
        BrightnessContrastShader = require 'BrightnessContrastShader'
        
        AdditiveBlendShader = require 'AdditiveBlendShader'
        EdgeShader3 = require 'EdgeShader3'
        
        #shaders, post processing etc
        resolutionBase = 1
        resolutionMultiplier = 1.5
        
        @fxaaResolutionMultiplier = resolutionBase/resolutionMultiplier
        composerResolutionMultiplier = resolutionBase*resolutionMultiplier
        
        #various passes and rtts
        renderPass = new THREE.RenderPass(@scene, @camera)
        
        copyPass = new THREE.ShaderPass( THREE.CopyShader )
        
        @edgeDetectPass3 = new THREE.ShaderPass(THREE.EdgeShader3)
        
        contrastPass = new THREE.ShaderPass(THREE.BrightnessContrastShader)
        contrastPass.uniforms['contrast'].value=0.5
        contrastPass.uniforms['brightness'].value=-0.4
        
        vignettePass = new THREE.ShaderPass(THREE.VignetteShader)
        vignettePass.uniforms["offset"].value = 0.4;
        vignettePass.uniforms["darkness"].value = 5;
        
        @hRes = @width * @dpr * @resUpscaler
        @vRes = @height * @dpr * @resUpscaler
        
        @fxAAPass = new THREE.ShaderPass(THREE.FXAAShader)
        #@fxAAPass.uniforms['resolution'].value.set(@fxaaResolutionMultiplier / (@width * @dpr), @fxaaResolutionMultiplier / (@height * @dpr))
        @fxAAPass.uniforms['resolution'].value.set(1/@hRes, 1/@vRes)
        @edgeDetectPass3.uniforms[ 'aspect' ].value = new THREE.Vector2( @width, @height )
         
        #depth data generation
        @depthTarget = new THREE.WebGLRenderTarget(@width, @height, { minFilter: THREE.NearestFilter, magFilter: THREE.NearestFilter, format: THREE.RGBFormat } )
        @depthMaterial = new THREE.MeshDepthMaterial()
        depthPass = new THREE.RenderPass(@scene, @camera, @depthMaterial)
        
        @depthComposer = new THREE.EffectComposer( @renderer, @depthTarget )
        @depthComposer.setSize(@hRes, @vRes)
        @depthComposer.addPass( depthPass )
        @depthComposer.addPass( @edgeDetectPass3 )
        @depthComposer.addPass( copyPass )
        #@depthComposer.addPass(@fxAAPass)
        
        #normal data generation
        @normalTarget = new THREE.WebGLRenderTarget(@width, @height, { minFilter: THREE.NearestFilter, magFilter: THREE.NearestFilter, format: THREE.RGBFormat } )
        @normalMaterial = new THREE.MeshNormalMaterial()
        normalPass = new THREE.RenderPass(@scene, @camera, @normalMaterial)
        
        @normalComposer = new THREE.EffectComposer( @renderer, @normalTarget )
        @normalComposer.setSize(@hRes, @vRes)
        @normalComposer.addPass( normalPass )
        @normalComposer.addPass( @edgeDetectPass3 )
        @normalComposer.addPass(copyPass)
        #@normalComposer.addPass(@fxAAPass)
        
        
        #final compositing
        #steps:
        #render default to @colorTarget
        #render depth
        #render normal
        
        renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false };
        renderTarget = new THREE.WebGLRenderTarget( @width , @height, renderTargetParameters );
        
        @finalComposer = new THREE.EffectComposer( @renderer , renderTarget )
        @finalComposer.setSize(@hRes, @vRes)
        #prepare the final render passes
        @finalComposer.addPass( renderPass )
        #@finalComposer.addPass(@fxAAPass)
        #blend in the edge detection results
        effectBlend = new THREE.ShaderPass( THREE.AdditiveBlendShader, "tDiffuse1" )
        effectBlend.uniforms[ 'tDiffuse2' ].value = @normalComposer.renderTarget2
        effectBlend.uniforms[ 'tDiffuse3' ].value = @depthComposer.renderTarget2
        @finalComposer.addPass( effectBlend )
        #
        #@finalComposer.addPass( vignettePass )
        #make sure the last in line renders to screen
        @finalComposer.passes[@finalComposer.passes.length-1].renderToScreen = true
    
    setupContextMenu:=>
      #experimental context menu
      contextMenu = require 'contextMenu'
      generatorTest = require "./generators/generatorGeometry"
      
      language = "coffee"
      visitor = new generatorTest.CoffeeSCadVisitor()
      
      switch language
        when "coffee"
          visitor = new generatorTest.CoffeeSCadVisitor()
        when "jscad"
          visitor = new generatorTest.OpenJSCadVisitor()
        when "scad"
          visitor = new generatorTest.OpenSCadVisitor()
            
      @$el.contextmenu
        target:'#context-menu'
        before: =>
          #console.log "@noControlChange", @noControlChange
          if @noControlChange
            @controls.disable()
            return true
          return false
        onItem: (e, element)=>
          visitResult = ""
          mesh = null
          objectType = $(element).attr("data-value")
          switch objectType
            when "Cube"
              mesh = generatorTest.cubeGenerator()
            when "Sphere"
              mesh = generatorTest.sphereGenerator()
            when "Cylinder"
              mesh = generatorTest.cylinderGenerator()
          
          if not @assembly?
            @assembly = new THREE.Object3D()
            @assembly.name = "assembly"
          
          if mesh?
            @assembly.add( mesh ) 
            visitResult = visitor.visit(mesh)
            @_render()
            meshCode = "\nassembly.add(#{visitResult})"
            line = @model.injectContent(meshCode)
            mesh.meta = mesh.meta or {}
            mesh.meta.startIndex = line
            mesh.meta.blockLength = meshCode.length
            mesh.meta.code = meshCode
            console.log "mesh.meta", mesh.meta
          
        after: =>  
          @controls.enable()
          @noControlChange = false
          @contextMenuRequested = false
          return false
          
    setupView:(val)=>
      #@camera.defaultPosition = @defaultCameraPosition
      #@overlayCamera.defaultPosition = new THREE.Vector3(150,150,250)
      
      if @settings.projection is "orthographic"
        @camera.toOrthographic()
        
      switch val
        when 'diagonal'
          @camera.toDiagonalView()
          @overlayCamera.toDiagonalView()
          #@camera.position.copy(@defaultCameraPosition)
        when 'top'
          @camera.toTopView()
          @overlayCamera.toTopView()
          
        when 'bottom'
          @camera.toBottomView()
          @overlayCamera.toBottomView()
        when 'front'
          @camera.toFrontView()
          @overlayCamera.toFrontView()
          
        when 'back'
          @camera.toBackView()
          @overlayCamera.toBackView()
          
        when 'left'
          @camera.toLeftView()
          @overlayCamera.toLeftView()
          
        when 'right' 
          @camera.toRightView()
          @overlayCamera.toRightView()
        
        when 'center'
          #todo : handle this correctly 
          try
            offset = new THREE.Vector3().sub(@camera.target.clone())
            #@controls.target.addSelf(offset)
            @camera.position.addSelf(offset)
          catch error
            console.log "error #{error} "
      
      @settings.position = ""
      if @initialized 
        @_render()
        
    
    _setupEventBindings:=>
      @model.on("compiled", @_onProjectCompiled)
      @model.on("compile:error", @_onProjectCompileFailed)
      
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "bgColor"
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
          when "gridNumberingPosition"
            @grid.setTextLocation(val)
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
              helpers.updateVisuals(@assembly, @settings)
              @_render()
              @renderer.shadowMapAutoUpdate = false
              if @settings.showGrid
                @removeGrid()
                @addGrid()
            else
              @renderer.shadowMapAutoUpdate = true
              helpers.updateVisuals(@assembly, @settings)
              @_render()
              if @settings.showGrid
                @removeGrid()
                @addGrid()
          when "shadowResolution"
            #TODO: this does not seem to get applied
            shadowResolution = parseInt(val.split("x")[0])
            @light.shadowMapWidth = shadowResolution
            @light.shadowMapHeight = shadowResolution
            if @settings.shadows
              @renderer.shadowMapAutoUpdate = true
              helpers.updateVisuals(@assembly, @settings)
              @_render()
              if @settings.showGrid
                @removeGrid()
                @addGrid()
          
          when "objectOutline"
            console.log "objectOutline",val
            if val
              @settings.objectOutline = val
              #TODO: move this to a seperate method
              if detector.webgl
                @fxAAPass.uniforms['resolution'].value.set(1/@hRes, 1/@vRes)
                @normalComposer.setSize(@hRes, @vRes)
                @depthComposer.setSize(@hRes, @vRes)
                @finalComposer.setSize(@hRes, @vRes)
              else
                @settings.objectOutline = false
            @_render()
          
          when "selfShadows"
            helpers.updateVisuals(@assembly, @settings)
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
          when "autoRotate"
            @controls.autoRotate = val
            @overlayControls.autoRotate = val
          when "objectViewMode"
            #TODO: should not be global , but object specific?
            helpers.updateVisuals(@assembly, @settings)
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
            if @grid?
              @grid.setColor(val)
          when 'textColor'
            if @axes?
              @removeAxes()
              @addAxes()
            if @grid?
              @grid.setTextColor(val)
          when 'showConnectors'
            if val
              @assembly.traverse (object)->
                if object.name is "connectors"
                  object.visible = true 
            else
              @assembly.traverse (object)->
                console.log "pouet"
                console.log object
                if object.name is "connectors"
                  object.visible = false 
      @_render()  
  
    reloadAssembly:()=>
      reloadedAssembly = @model.rootFolder.get(".assembly")
      console.log "reloadedAssembly",reloadedAssembly
      if reloadedAssembly?
        reloadedAssembly = JSON.parse(reloadedAssembly.content)
        loader = new THREE.ObjectParser()
        
        @assembly = loader.parse(reloadedAssembly)
        console.log "parse Result", @assembly
        @scene.add @assembly
        
        #hack because three.js does not reload the vertexColors flag correctly
        helpers.updateVisuals(@assembly, @settings)
        #@blablabla()
        @_render()
    
    blablabla:=>
      if @assembly?
        @tmpScene.remove(@assembly)
        dup = @assembly.clone()
        @tmpScene.add(dup)
        @tmpScene.assembly = dup
        @tmpScene.add(@scene.lights) 
      
      helpers.toggleHelpers(@tmpScene.assembly)
    
      
    makeScreenshot:(width=600, height=600)=>
      return helpers.captureScreen(@renderer.domElement,width,height)
    
    onObjectSelected:(selectionInfo)=>
      #experimental 2d overlay for projected min max values of the objects 3d bounding box
      [centerLeft,centerTop,length,width,height]=@selectionHelper.get2DBB(selectionInfo.selection,@width, @height)
      $("#testOverlay2").removeClass("hide")
      $("#testOverlay2").css("left",centerLeft+@$el.offset().left)
      $("#testOverlay2").css('top', (centerTop - $("#testOverlay2").height()/2)+'px')
      
      screenCoords = @selectionHelper.getScreenCoords(selectionInfo.selection,@width, @height)
      $("#testOverlay2").css("left",screenCoords.x+@$el.offset().left)
      $("#testOverlay2").css('top', (screenCoords.y - $("#testOverlay2").height()/2)+'px')
      
      
      infoText = "#{@selectionHelper.currentSelect.name}"#\n w:#{width} <br\> l:#{length} <br\>h:#{height}"
      $("#testOverlay2").html("""<span>#{infoText} <a class="toto"><i class="icon-exclamation-sign"></a></span>""")
      $(".toto").click ()=>
        volume = @selectionHelper.currentSelect.volume or 0
        
        htmlStuff = """<span>#{infoText} <br>Volume:#{volume} <a class="toto"><i class="icon-exclamation-sign"></a></span>"""
        $("#testOverlay2").html(htmlStuff)
      @_render()
      
    onObjectUnSelected:(selectionInfo)=>
      $("#testOverlay2").addClass("hide")
      @_render()
      
    onObjectHover:()=>
      @_render()
    
    _onSelectAttempt:(ev)=>
      """used either for selection or context menu"""
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      hiearchyRoot = if @assembly? then @assembly.children else @scene.children
      @selectionHelper.hiearchyRoot=hiearchyRoot
      @selectionHelper.viewWidth=@width
      @selectionHelper.viewHeight=@height
      
      selected = @selectionHelper.selectObjectAt(x,y)
      
      ###
      selectionChange = false
      if selected?
        if @currentSelection?
          if @currentSelection != selected
            selectionChange = true
        else 
          selectionChange = true
     
      if selectionChange
        if @currentSelection?
          controls = @currentSelection.controls
          if controls?
            controls.detatch(@currentSelection)
            controls.removeEventListener( 'change', @_render)
            @scene.remove(controls.gizmo)
            controls = null
            @currentSelection = null
        
        @currentSelection = selected        
        controls = new THREE.TransformControls(@camera, @renderer.domElement)
        console.log controls
        controls.addEventListener( 'change', @_render );
        controls.attatch( selected );
        controls.scale = 0.65;
        @scene.add( controls.gizmo );
        selected.controls = controls
      
      @_render()
      ###      
      
      ev.preventDefault()
      return false
      
    _onRightclick:(ev)=>
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      if not @selectionHelper.isThereObjectAt(x,y)
        @selectionHelper._unSelect()
      @contextMenuRequested = true
    
    _onMouseMove:(ev)->
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      
      hiearchyRoot = if @assembly? then @assembly.children else @scene.children
      @selectionHelper.hiearchyRoot=hiearchyRoot
      @selectionHelper.viewWidth=@width
      @selectionHelper.viewHeight=@height
      @selectionHelper.highlightObjectAt(x,y)
    
    _onControlsChange:(ev)=>
      #console.log "controls change"
      @noControlChange = false 
      #@oldCamPos = if @newCamPos? then @newCamPos.clone()
      #@newCamPos = ev.target.object.position
      
      if @controlChangeTimeOut?
        clearTimeout(@controlChangeTimeOut)
      @controlChangeTimeOut = null  
      @controlChangeTimeOut = setTimeout ( =>
        @noControlChange = true
        if @contextMenuRequested?
          if @contextMenuRequested
            @setupContextMenu()
            
      ), 600
      return false

    switchProjection:(ev)->
      projection = @settings.projection
      if projection is "perspective"
        @settings.projection = "orthographic"
        $(ev.target).addClass("uicon-off")
      else
        @settings.projection = "perspective"
        $(ev.target).removeClass("uicon-off")
      return false
    
    toggleGrid: (ev)=>
      toggled = @settings.showGrid
      if toggled
        @settings.showGrid = false
        $(ev.target).addClass("uicon-off")
      else
        @settings.showGrid = true
        $(ev.target).removeClass("uicon-off")
      return false
    
    toggleAxes:(ev)=>
      toggled = @settings.showAxes
      if toggled
        @settings.showAxes = false
        $(ev.target).addClass("uicon-off")
      else
        @settings.showAxes = true
        $(ev.target).removeClass("uicon-off")
      return false
    
    toggleAutoRotate:(ev)=>
      toggled = @settings.autoRotate
      if toggled
        @settings.autoRotate = false
        $(ev.target).addClass("uicon-off")
      else
        @settings.autoRotate = true
        $(ev.target).removeClass("uicon-off")
      return false

    toggleOutlines:(ev)=>
      toggled = @settings.objectOutline
      if toggled
        @settings.objectOutline = false
        $(ev.target).addClass("uicon-off")
      else
        @settings.objectOutline = true
        $(ev.target).removeClass("uicon-off")
      return false
    
    switchViewType:(ev)=>
      myClass = $(ev.currentTarget).attr("class")
      myClass = myClass.replace("switchViewType",'')
      viewType = myClass.replace(/\s/g, '')
      viewType = viewType.split('-').pop()
      console.log viewType
      @settings.position = viewType
      #@setupView(@settings.projection)
      
    _onProjectCompiled:(res)=>
      #compile succeeded, generate geometry from csg
      @selectionHelper._unSelect()
      @fromCsg res
      
      @grid.rootAssembly = @assembly
      @grid.updateGridSize()
    
    _onProjectCompileFailed:()=>
      #in case project compilation failed, remove previously generated geometry
      if @assembly?
        @scene.remove @assembly
        @assembly = null
      @_render()
      
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindAll()
      @model.off("compiled", @_onProjectCompiled)
      @model.off("compile:error", @_onProjectCompileFailed)

      if @assembly?
        @scene.remove @assembly
        @current=null
      
      @model = newModel
      
      @selectionHelper._unSelect() #clear selection
      @_setupEventBindings()
      @_render()
      
      @reloadAssembly()
    
    setBgColor:()=>
      bgColor = @settings.bgColor
      $("body").css("background-color", bgColor)
      
      _HexTO0x=(c)->
        hex = parseInt("0x"+c.split('#').pop(),16)
        return  hex 
      
      color = _HexTO0x(bgColor)
      alpha = if @renderer.getClearAlpha? then @renderer.getClearAlpha() else 1
      alpha = 1
      @renderer.setClearColor( color, alpha )
      
      
    addGrid:()=>
      ###
      Adds both grid & plane (for shadow casting), based on the parameters from the settings object
      ###
      if not @grid 
        gridSize = @settings.gridSize
        gridStep = @settings.gridStep
        gridColor = @settings.gridColor
        gridOpacity = @settings.gridOpacity
        gridText = @settings.gridText
        
        @grid = new helpers.Grid({size:gridSize,step:gridStep,color:gridColor,opacity:gridOpacity,addText:gridText,textColor:@settings.textColor})
        @scene.add @grid
       
    removeGrid:()=>
      if @grid
        @scene.remove @grid
        delete @grid
      
    addAxes:()->
      helpersColor = @settings.helpersColor
      @axes = new helpers.LabeledAxes({xColor:helpersColor, yColor:helpersColor, zColor:helpersColor, size:@settings.gridSize/2, addLabels:false, addArrows:false})
      @scene.add(@axes)
      
      @overlayAxes = new helpers.LabeledAxes({textColor:@settings.textColor, size:100})
      @overlayScene.add @overlayAxes
      
    removeAxes:()->
      @scene.remove @axes
      @overlayScene.remove @overlayAxes
      delete @axes
      delete @overlayAxes
            
    _computeViewSize:=>
      @height = window.innerHeight-($("#header").height())
      if window.devicePixelRatio?
        @dpr = window.devicePixelRatio

      if not @initialized?
        westWidth = $("#_dockZoneWest").width()
        eastWidth = $("#_dockZoneEast").width()
        @width = window.innerWidth - (westWidth + eastWidth)
      else
        westWidth = $("#_dockZoneWest").width()
        eastWidth = $("#_dockZoneEast").width()
        @width = window.innerWidth - (westWidth + eastWidth)
        #@width = Math.floor(window.innerWidth*@dpr) - (westWidth + eastWidth)
      
      #BUG in firefox: dpr is not 1 on desktop, scaling issue ensue, so forcing to "1"
      @dpr=1
      @hRes = @width * @dpr * @resUpscaler
      @vRes = @height * @dpr * @resUpscaler
    
    onResize:()=>
      @_computeViewSize()
      
      @camera.aspect = @width / @height
      @camera.setSize(@width,@height)
      @renderer.setSize(@hRes, @vRes)
      @camera.updateProjectionMatrix()
      
      if (@renderer instanceof THREE.WebGLRenderer and @settings.objectOutline is true)
        #shader uniforms updates
        @edgeDetectPass3.uniforms[ 'aspect' ].value = new THREE.Vector2( @width, @height )
        @fxAAPass.uniforms['resolution'].value.set(1/@hRes, 1/@vRes)
        #@fxAAPass.uniforms['resolution'].value.set(@fxaaResolutionMultiplier / (@width * @dpr), @fxaaResolutionMultiplier / (@height * @dpr))
        
        @normalComposer.setSize(@hRes, @vRes)
        @depthComposer.setSize(@hRes, @vRes)
        @finalComposer.setSize(@hRes, @vRes)
      
      @_render()
    
    onResizeStop:=>
      @onResize()
    
    onDomRefresh:()=>
      #recompute view size
      @_computeViewSize()
      #setup everything 
      @init()
      
      if @settings.showStats
        @ui.overlayDiv.append(@stats.domElement)
      
      @camera.aspect = @width / @height
      @camera.setSize(@width,@height)
      @renderer.setSize(@width, @height)
      @camera.updateProjectionMatrix()
            
      @$el.resize @onResize
      window.addEventListener('resize', @onResize, false)
      ##########
      
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      @renderer.domElement.setAttribute("id","3dView")
      
      @controls = new THREE.OrbitControls(@camera, @el)
      @controls.staticMoving = true
      @controls.userPanSpeed = 3.0
      @controls.autoRotate = @settings.autoRotate
      @controls.autoRotateSpeed = 4.0
      @controls.addEventListener( 'change', @_onControlsChange )
      
      container2 = $(@ui.glOverlayBlock)
      container2.append(@overlayRenderer.domElement)
      
      @overlayControls = new THREE.OrbitControls(@overlayCamera, @el)
      @overlayControls.userPan = false
      @overlayControls.userZoom = false
      @overlayControls.userPanSpeed = 0
      @overlayControls.userZoomSpeed=0
      
      @overlayControls.autoRotate = @settings.autoRotate
      @overlayControls.autoRotateSpeed = 4.0
      
      @initialized = true
      @animate()
    
    _render:()=>
      
      if (@renderer instanceof THREE.WebGLRenderer and @settings.objectOutline is true)
        #necessary hack for effectomposer
        THREE.EffectComposer.camera = new THREE.OrthographicCamera( -1, 1, 1, -1, 0, 1 )
        THREE.EffectComposer.quad = new THREE.Mesh( new THREE.PlaneGeometry( 2, 2 ), null )
        THREE.EffectComposer.scene = new THREE.Scene()
        THREE.EffectComposer.scene.add( THREE.EffectComposer.quad )
        
        originalStates = helpers.toggleHelpers(@scene)#hide helpers from scene
        @depthComposer.render()
        @normalComposer.render()
        helpers.enableHelpers(@scene, originalStates)#show previously shown helpers again
        
        @finalComposer.passes[@finalComposer.passes.length-1].uniforms[ 'tDiffuse2' ].value = @normalComposer.renderTarget2
        @finalComposer.passes[@finalComposer.passes.length-1].uniforms[ 'tDiffuse3' ].value = @depthComposer.renderTarget2
        @finalComposer.render()
      else
        @renderer.render( @scene, @camera)
      
      if @settings.showStats
        @stats.update()
      
    
    _renderOverlay:()=>
      @overlayRenderer.render(@overlayScene, @overlayCamera)
        
    animate:()=>
      @controls.update()
      @overlayControls.update()
      
      blaZoom = Math.pow( 0.95, @controls.userZoomSpeed )
      #@camera.setZoom(@controls.scale*10)
      #@camera.setFov(10)
      #console.log @camera.position
      @_render()
      @_renderOverlay()
      requestAnimationFrame(@animate)
    
    fromCsg:()=>
      #try
      start = new Date().getTime()
      #console.log "project compiled, updating view"
      if @assembly?
        @scene.remove @assembly
        @current=null
      
      @assembly = new THREE.Object3D()
      @assembly.name = "assembly"
      
      if @model.rootAssembly.children?
        for index, part of @model.rootAssembly.children
          @_importGeom(part,@assembly)
        
      @scene.add @assembly 
      end = new Date().getTime()
      console.log "Csg visualization time: #{end-start}"
      
      helpers.updateVisuals(@assembly, @settings)
      
      #TODO: once the core has been migrated to three.js, this should be in the compiler/project's after compile step
      exporter = new THREE.ObjectExporter()
      exported = exporter.parse(@assembly)
      exported = JSON.stringify(exported)
      #console.log "exported",exported
      
      if not @model.rootFolder.get(".assembly")
        @model.addFile
          name:".assembly"
          content:exported
      else
        @model.rootFolder.get(".assembly").content = exported
      
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
      mesh = new THREE.Mesh(geom, mat)
      
      #TODO: solve this positioning issue
      mesh.position = geom.tmpPos
      delete geom.tmpPos
      
      mesh.castShadow =  @settings.shadows
      mesh.receiveShadow = @settings.selfShadows and @settings.shadows
      mesh.material.wireframe = @settings.wireframe
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
      
      #recursive, for sub objects
      if csgObj.children?
        for index, child of csgObj.children
          @_importGeom(child, mesh) 
 
  return VisualEditorView