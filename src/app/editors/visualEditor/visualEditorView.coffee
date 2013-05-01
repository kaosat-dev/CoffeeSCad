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
  
  includeMixin = require 'core/utils/mixins/mixins'
  dndMixin = require 'core/utils/mixins/dragAndDropRecieverMixin'
  
  
  class VisualEditorView extends Backbone.Marionette.ItemView
    el: $("#visual")
    @include dndMixin
    template: threedView_template
    ui:
      renderBlock :   "#glArea"
      glOverlayBlock: "#glOverlay" 
      overlayDiv:     "#overlay" 
      dropOverlay: "#dropOverlay"
      
    events:
      'contextmenu' : 'rightclick'
      'dragover': 'onDragOver'
      'dragenter': 'onDragEnter'
      'dragexit' :'onDragExit'
      'drop':'onDrop'
      
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      "mousemove": "onMouseMove"
    
    onDummy:(e)=>
      console.log "dummy event fired"
    
    onDragOver:(e)=>
      e.preventDefault()
      e.stopPropagation()
      #console.log "event", e
      #console.log "e.dataTransfer",e.dataTransfer
      #offset = e.dataTransfer.getData("text/plain").split(',');
      dm = @ui.dropOverlay[0]
      #console.log "dm", dm
      dm.style.left = (e.clientX + e.offsetX) + 'px'
      dm.style.top = (e.clientY + e.offsetY) + 'px'
      
      dm.style.left =e.originalEvent.clientX+'px'
      dm.style.top = e.originalEvent.clientY+'px'
      
    onDragEnter:(e)->
      @ui.dropOverlay.removeClass("hide")
    
    onDragExit:(e)=>
      @ui.dropOverlay.addClass("hide")
      
    onDrop:(e)->
      # this / e.target is current target element.
      if (e.stopPropagation)
        e.stopPropagation()
      e.preventDefault()
      
      @ui.dropOverlay.addClass("hide")
      
      files = e.originalEvent.dataTransfer.files
      for file in files
        console.log "dropped file", file
        
        do(file)=>
          name = file.name
          ext = name.split(".").pop()
          if ext == "coffee"
            
            reader = new FileReader()
            reader.onload=(e) =>
              fileContent = e.target.result
              console.log "fileContent",fileContent
            reader.readAsText(file)
           
            #reader.onload = ((fileHandler)->
      # See the section on the DataTransfer object.
      return false
      
    constructor:(options, settings)->
      super options
      @vent = vent 
      @settings = options.settings
        
      @stats = new stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '30px'
      @stats.domElement.style.zIndex = 100
      
      @settings.on("change", @settingsChanged)
      @_setupEventBindings()
      
      #screenshoting
      reqRes.addHandler "project:getScreenshot", ()=>
        return @makeScreeshot()
      
      ##########
      @defaultCameraPosition = new THREE.Vector3(100,100,200)
      @width = 100
      @height = 100
      @init()
      
      @selectionHelper = new helpers.SelectionHelper({renderCallback:@_render, camera:@camera,color:0x000000,textColor:@settings.textColor})
    
    _setupEventBindings:=>
      @model.on("compiled", @projectCompiled)
      @model.on("compile:error", @projectCompileFailed)
      
    makeScreeshot:(width=300, height=300)=>
      return helpers.captureScreen(@renderer.domElement,width,height)
    
    rightclick:(ev)=>
      """used either for selection or context menu"""
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      hiearchyRoot = if @assembly? then @assembly.children else @scene.children
      @selectionHelper.hiearchyRoot=hiearchyRoot
      @selectionHelper.viewWidth=@width
      @selectionHelper.viewHeight=@height
      @selectionHelper.selectObjectAt(x,y)
      
      ev.preventDefault()
      return false
    
    onMouseMove:(ev)->
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      
      hiearchyRoot = if @assembly? then @assembly.children else @scene.children
      @selectionHelper.hiearchyRoot=hiearchyRoot
      @selectionHelper.viewWidth=@width
      @selectionHelper.viewHeight=@height
      @selectionHelper.highlightObjectAt(x,y)
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindAll()
      @model.off("compiled", @projectCompiled)
      @model.off("compile:error", @projectCompileFailed)
      try
        @scene.remove @current.cageView
      if @assembly?
        @scene.remove @assembly
        @current=null
      
      @model = newModel
      @_setupEventBindings()
      @_render()
      
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
              @_updateAssemblyVisualAttrs()
              @_render()
              @renderer.shadowMapAutoUpdate = false
              if @settings.showGrid
                @removeGrid()
                @addGrid()
            else
              @renderer.shadowMapAutoUpdate = true
              @_updateAssemblyVisualAttrs()
              @_render()
              if @settings.showGrid
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
          when "objectViewMode"
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
      @renderer=null
      #TODO: do this properly
      @configure(@settings)
      @renderer.shadowMapEnabled = true
      @renderer.shadowMapAutoUpdate = true
      
      @projector = new THREE.Projector()
      @setupScene()
      @setupOverlayScene()
      @setBgColor()
      
      if @settings.shadows
        @renderer.shadowMapAutoUpdate = @settings.shadows
      if @settings.showGrid
        @addGrid()
      if @settings.showAxes
        @addAxes()
      if @settings.projection is "orthographic"
        @camera.toOrthographic()
        @camera.setZoom(6)
      else
        #@camera.toPerspective()
      if @mesh?
        @mesh.material.wireframe = @settings.wireframe
      
      val = @settings.position
      @setupView(val)
        
    configure:(settings)=>
      if settings.renderer
          renderer = settings.renderer
          if renderer == "webgl"
            if detector.webgl
              console.log "Gl Renderer"
              @renderer = new THREE.WebGLRenderer 
                clearColor: 0x00000000
                clearAlpha: 0
                antialias: true
                preserveDrawingBuffer   : true
              @renderer.clear() 
              @renderer.setSize(@width, @height)
              
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
      NEAR = 1
      FAR = 10000
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
      spotLight.position.z = 300
      #spotLight.shadowCameraVisible = true
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
          @camera.toTopView()
          @overlayCamera.toTopView()
          console.log @camera
          ###
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
          ###
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
      bgColor1 = @settings.bgColor
      bgColor2 = @settings.bgColor2
      $("body").css("background-color", bgColor1)
      
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
      
      @overlayAxes = new helpers.LabeledAxes({textColor:@settings.textColor, size:@settings.axesSize})
      @overlayScene.add @overlayAxes
      
    removeAxes:()->
      @scene.remove @axes
      @overlayScene.remove @overlayAxes
      delete @axes
      delete @overlayAxes
            
    _computeViewSize:=>
      @height = window.innerHeight-10
      @height = @$el.height()

      if not @initialized?
        @initialized = true
        westWidth = $("#_dockZoneWest").width()
        eastWidth = $("#_dockZoneEast").width()
        @width = window.innerWidth - (westWidth + eastWidth)
      else
        westWidth = $("#_dockZoneWest").width()
        eastWidth = $("#_dockZoneEast").width()
        @width = window.innerWidth - (westWidth + eastWidth)
      #console.log "window.innerWidth", window.getCoordinates().width#window.outerWidth
      @height = window.innerHeight-30
    
    onResize:()=>
      @_computeViewSize()
      
      @camera.aspect = @width / @height
      @camera.setSize(@width,@height)
      @renderer.setSize(@width, @height)
      @camera.updateProjectionMatrix()
      
      @_render()
    
    onResizeStop:=>
      @onResize()
    
    onDomRefresh:()=>
      if @settings.showStats
        @ui.overlayDiv.append(@stats.domElement)
        
      @_computeViewSize()
      
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
      @renderer.domElement.setAttribute("id","3dView")
      console.log @renderer.domElement.id
      
      @controls = new CustomOrbitControls(@camera, @el)#
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
      @overlayControls.noZoom = true
      @overlayControls.rotateSpeed = 1.8
      @overlayControls.zoomSpeed = 0
      @overlayControls.panSpeed = 0
      @overlayControls.userZoomSpeed=0
      
      @animate()
    
    _render:()=>
      ###
      #experimental 2d overlay for projected min max values of the objects 3d bounding box
      if @selectionHelper?
        if @selectionHelper.currentSelect?
          [minLeft,minTop,maxLeft,maxTop]=@selectionHelper.get2DBB(@selectionHelper.currentSelect,@width, @height)
          
          $("#testOverlay").css("top",minTop)
          $("#testOverlay").css("left",minLeft+@$el.offset().left)
          
          
          $("#testOverlay2").css("left",maxLeft+@$el.offset().left)
          #$("#testOverlay2").css("top",@$el.offset().top-maxTop)
          $("#testOverlay2").css('top', (maxTop - $("#testOverlay2").height() / 2))
          
          $("#testOverlay2").text(@selectionHelper.currentSelect.name)
      ###
      
      @renderer.render(@scene, @camera)
      @overlayRenderer.render(@overlayScene, @overlayCamera)
      
      if @settings.showStats
        @stats.update()
      #@cameraHelper.update()
      
    animate:()=>
      @controls.update()
      @overlayControls.update()
      requestAnimationFrame(@animate)
    
    fromCsg:()=>
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
      
      @_updateAssemblyVisualAttrs()
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
      #@_addIndicator2(mesh)
      
      #recursive, for sub objects
      if csgObj.children?
        for index, child of csgObj.children
          @_importGeom(child, mesh) 
     
    _updateAssemblyVisualAttrs:=>
      console.log "applying object visual style"
      removeRenderHelpers=(child)=>
        if child.renderSubElementsHelper?
          child.remove(child.renderSubElementsHelper)
          child.renderSubElementsHelper = null
      
      applyStyle=(child)=>
        child.castShadow =  @settings.shadows
        child.receiveShadow = @settings.selfShadows and @settings.shadows
        switch @settings.objectViewMode
          when "shaded"
            removeRenderHelpers(child)
            if child.material?
              child.material.wireframe = false
          when "wireframe"
            removeRenderHelpers(child)
            if child.material?
              child.material.wireframe = true
          when "structural"
            if child.material?
              child.material.wireframe = false
            if child.geometry?
              removeRenderHelpers(child)
              basicMaterial1 = new THREE.MeshBasicMaterial( { color: 0xccccdd, side: THREE.DoubleSide, depthTest: true, polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1 } )
              dashMaterial = new THREE.LineDashedMaterial( { color: 0x000000, dashSize: 2, gapSize: 3, depthTest: false, polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1  } )
              wireFrameMaterial = new THREE.MeshBasicMaterial( { color: 0x000000, depthTest: true, polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1, wireframe: true } )
              renderSubElementsHelper  = new THREE.Object3D()
              renderSubElementsHelper.name = "renderSubs"
              
              geom = child.geometry
              obj2 = new THREE.Mesh( geom.clone(), basicMaterial1 )
              obj3 = new THREE.Line( helpers.geometryToline(geom.clone()), dashMaterial, THREE.LinePieces )
              obj4 = new THREE.Mesh( geom.clone(), wireFrameMaterial)
      
              renderSubElementsHelper.add(obj2)
              renderSubElementsHelper.add(obj3)
              renderSubElementsHelper.add(obj4)
              child.add(renderSubElementsHelper)
              child.renderSubElementsHelper = renderSubElementsHelper
              
        for subchild in child.children
          if subchild.name != "renderSubs" and subchild.name !="connectors"
            applyStyle(subchild)
          
      if @assembly?
        for child in @assembly.children  
          applyStyle(child)
    

  return VisualEditorView