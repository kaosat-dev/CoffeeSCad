define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  require 'bootstrap'
  #csg = require 'csg'
  THREE = require 'three'
  #THREE.CSG = require 'three_csg'
  combo_cam = require 'combo_cam'
  detector = require 'detector'
  stats = require  'stats'
  utils = require 'utils'
  
  reqRes = require 'modules/core/reqRes'
  vent = require 'modules/core/vent'
  
  threedView_template = require "text!./visualEditorView.tmpl"
  requestAnimationFrame = require 'modules/core/utils/anim'
  orbit_ctrl = require 'orbit_ctrl'
  
  THREE.CSG = require 'modules/core/projects/csg/csg.Three'
  
  #FIXME: memory leaks: When removing objects from scene do we really need: renderer.deallocateObject(Object); ?
  
  class MyAxisHelper
    constructor:(size, xcolor, ycolor, zcolor)->
      geometry = new THREE.Geometry()
      
      geometry.vertices.push(
        new THREE.Vector3(-size or -1, 0, 0 ), new THREE.Vector3( size or 1, 0, 0 ),
        new THREE.Vector3(0, -size or -1, 0), new THREE.Vector3( 0, size or 1, 0 ),
        new THREE.Vector3(0, 0, -size or -1 ), new THREE.Vector3( 0, 0, size or 1 )
        )
        
      geometry.colors.push(
        xcolor or new THREE.Color(0xffaa00), xcolor or new THREE.Color(0xffaa00),
        ycolor or new THREE.Color(0xaaff00), ycolor or new THREE.Color(0xaaff00),
        zcolor or new THREE.Color(0x00aaff), zcolor or new THREE.Color(0x00aaff)
        )
        
      material = new THREE.LineBasicMaterial
        vertexColors: THREE.VertexColors
        #depthTest:false
        linewidth:1
      
      return new THREE.Line(geometry, material, THREE.LinePieces)
  
  class VisualEditorView extends Backbone.Marionette.ItemView
    template: threedView_template
    ui:
      renderBlock :   "#glArea"
      glOverlayBlock: "#glOverlay" 
      overlayDiv:     "#overlay" 
      
    events:
      #'mousemove'   : 'mousemove'
      'mouseup'     : 'mouseup'
      #'mousewheel'  : 'mousewheel'
      #'mousedown'   : 'mousedown'
      'contextmenu' : 'rightclick'
      #'DOMMouseScroll' : 'mousewheel'
      "mousedown .toggleGrid":          "toggleGrid"
      "mousedown .toggleAxes":          "toggleAxes"
      "mousedown .toggleShadows":       "toggleShadows"
      "mousedown .toggleAA":            "toggleAA"
      "mousedown .toggleAutoUpdate":    "toggleAutoUpdate"
      
    constructor:(options, settings)->
      super options
      @vent = vent 
      @settings = options.settings
        
      @stats = new stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '30px'
      @stats.domElement.style.zIndex = 100
        
      @bindTo(@settings, "change", @settingsChanged)
      @bindTo(@model, "compiled", @projectCompiled)
      
      #screenshoting
      reqRes.addHandler "project:getScreenshot", ()=>
        return @makeScreeshot()
      
      #Controls:
      @dragging = false
      ##########
      @width = 800
      @height = 600
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
      #imgAsDataURL=canvas.toDataURL("image/png")
      #imgAsDataURL = @renderer.domElement.toDataURL("image/png")
      #console.log imgAsDataURL
      # ,300, 300
      return d
    
    toggleGrid: (ev)=>
        toggled = @settings.get("showGrid")
        if toggled
          @settings.set("showGrid",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("showGrid",true)
          $(ev.target).removeClass("uicon-off")
        return false
        
    toggleAxes:(ev)=>
        toggled = @settings.get("showAxes")
        if toggled
          @settings.set("showAxes",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("showAxes",true)
          $(ev.target).removeClass("uicon-off")
        return false
     
    toggleShadows:(ev)=>
        #FIXME: to deactivate shadows on the plane, regenerate its texture (amongst other things)
        toggled = @settings.get("shadows")
        if toggled
          @settings.set("shadows",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("shadows",true)
          $(ev.target).removeClass("uicon-off")
        return false
            
    toggleAA:(ev)=>
        toggled = @settings.get("antialiasing")
        if toggled
          @settings.set("antialiasing",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("antialiasing",true)
          $(ev.target).removeClass("uicon-off")
        return false
        
    toggleAutoUpdate:(ev)=>
        toggled = @settings.get("autoUpdate")
        if toggled
          @settings.set("autoUpdate",false)
          $(ev.target).addClass("uicon-off")
        else
          @settings.set("autoUpdate",true)
          $(ev.target).removeClass("uicon-off")
        return false
      
    rightclick:(ev)=>
      """used either for selection or context menu"""
      normalizeEvent(ev)
      x = ev.offsetX
      y = ev.offsetY
      @selectObj(x,y)
      
      #context-menu
      # = require "modules/core/utils/contextMenu"
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
      
    mousewheel:(ev)=>
      #fix for firefox scroll
      ev = window.event or ev
      wheelDelta = null
      if ev.originalEvent?
        wheelDelta = if ev.originalEvent.detail? then ev.originalEvent.detail*(-120)
      else
        wheelDelta = ev.wheelDelta
      console.log "tet"+wheelDelta
      ###
      if wheelDelta > 0
        @controls.zoomOut()
      else 
        @controls.zoomIn()
      ev.preventDefault()
      ev.stopPropagation()
      return false
      ###
      
      
      ###ev = window.event or ev; # old IE support  
      #@controls.onMouseWheel(ev)
      delta = Math.max(-1, Math.min(1, (ev.wheelDelta or -ev.detail)))
      delta*=75
      if delta - @camera.position.z <= 100
        @camera.position.z-=delta
      return false
      ###

    mousemove:(ev)->
      #return false
      ###if @dragStart?
        moveMinMax = 10
        
        @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
        #@dragAmount[1]=@height-@dragAmount[1]
        #console.log "bleh #{@dragAmount[0]/500}"
        x_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[0]/10))
        y_move = Math.max(-moveMinMax, Math.min(moveMinMax, @dragAmount[1]/10))
        #x_move = (x_move/x_move+0.0001)*moveMinMax
        #y_move = (y_move/y_move+0.0001)*moveMinMax
        #console.log("moving by #{y_move}")
        @camera.position.x+=  x_move #@dragAmount.x/10000
        @camera.position.y-=  y_move#@dragAmount.y/100
        return false
      ###  
    dragstart:(ev)=>
      @dragStart={'x':ev.offsetX, 'y':ev.offsetY}
      
    mouseup:(ev)=>
      
      #if @contextMenuRegion?
      #  @contextMenuRegion.close()
      #if @dragStart?
      #  @dragAmount=[@dragStart.x-ev.offsetX, @dragStart.y-ev.offsetY]
      #  @dragStart=null
     
      #x = ev.offsetX
      #y = ev.offsetY
      #v = new THREE.Vector3((x/@width)*2-1, -(y/@height)*2+1, 0.5)
      
    mousedown:(ev)=>
      #ev.preventDefault()
      #return false
             
    selectObj:(mouseX,mouseY)=>
      v = new THREE.Vector3((mouseX/@width)*2-1, -(mouseY/@height)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      ray = new THREE.Ray(@camera.position, v.subSelf(@camera.position).normalize())
      intersects=ray.intersectObjects(@scene.children, true )
      
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
      @_render()
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindAll()
      @scene.remove(@mesh)
      
      try
        @scene.remove @current.cageView
        @current=null
      
      @model = newModel
      @bindTo(@model, "change", @modelChanged)
      @fromCsg @model
      
    projectCompiled:(res)=>
      @fromCsg res
              
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
              @grid.material.color.setHex(val)
              @subGrid.material.color.setHex(val)
          when "gridOpacity"
            if @grid?
              @grid.material.opacity=val
              @subGrid.material.opacity=val
          when "showAxes"
            if val
              @addAxes()
            else
              @removeAxes()
          when "shadows"
            if not val
              @renderer.clearTarget(@light.shadowMap)
              @fromCsg @model
              @render()
              @renderer.shadowMapAutoUpdate = false
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
            else
              @renderer.shadowMapAutoUpdate = true
              @fromCsg @model
              @render()
              if @settings.get("showGrid")
                @removeGrid()
                @addGrid()
            
          when "selfShadows"
            @fromCsg @model
            @render()
            
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
            if @mesh?
              @mesh.material.wireframe = val
          
          when 'center'
            try
              tgt = @controls.target
              offset = new THREE.Vector3().subSelf(@controls.target.clone())
              @controls.target.addSelf(offset)
              @camera.position.addSelf(offset)
            catch error
              console.log "error #{error} in center"
            @camera.lookAt(@scene.position)
          when 'helpersColor'
            if @axes?
              @axes.material.color.setHex(val)
          when 'showConnectors'
            if val
              THREE.SceneUtils.traverseHierarchy @assembly, (object)-> 
                if object.name is "connectors"
                  object.visible = true 
            else
              THREE.SceneUtils.traverseHierarchy @assembly, (object)-> 
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
      
      csgRenderMode = @settings.get "csgRenderMode"
      switch csgRenderMode
        when "onCodeChange"
          console.log "onCodeChange"
          if @modelSaveBinding?
            unbindFrom @modelSaveBinding
          @modelChangeBinding=@bindTo(@model, "change", @modelChanged)
        when "onCodeChangeDelayed"
          console.log "onCodeChangeDelayed"
          #TODO: add delay handling (any "change" events must invalidate the timer)
          if @modelSaveBinding?
            unbindFrom @modelSaveBinding
          @modelChangeBinding=@bindTo(@model, "change", @modelChanged)
        when "onDemand"
          if @modelChangeBinding?
            unbindFrom @modelChangeBinding
          if @modelSaveBinding?
            unbindFrom @modelSaveBinding
          @vent.bind "parseCsgRequest", =>
            @fromCsg @model
        when "onSave"
          if @modelChangeBinding?
            unbindFrom @modelChangeBinding
          @modelSaveBinding=@bindTo(@model, "saved", @modelSaved)
      
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
        @camera.toPerspective()
      
      if @mesh?
        @mesh.material.wireframe = @settings.get("wireframe")
      
      
      val = @settings.get("position")
      @setupView(val)
        
    configure:(settings)=>
      if settings.get("renderer")
          renderer = settings.get("renderer")
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
      #function ( @width, @height, @viewAngle, NEAR, FAR, NEAR, FAR ) 
      
      @camera.up = new THREE.Vector3( 0, 0, 1 )
      
      @camera.position.x = 450
      @camera.position.y = 450
      @camera.position.z = 750
      
          
      @scene = new THREE.Scene()
      @scene.add(@camera)
      @setupLights()
      
      
      @cameraHelper = new THREE.CameraHelper(@camera)
      #@camera.add(@cameraHelper)
      ###
      xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(100,0,0),50, 0xFF7700)
      yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(100,0,0),50, 0x77FF00)
      zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(100,0,0),50, 0x0077FF)
      @scene.add xArrow
      @scene.add yArrow
      @scene.add zArrow
      ###
      
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
      
      #@overlayCamera.position.x = 150
      #@overlayCamera.position.y = 150
      #@overlayCamera.position.z = 250
      
      #@overlayCamera.toOrthographic()
      #@overlayCamera.setZoom(0.05)
      @overlayscene = new THREE.Scene()
      @overlayscene.add(@overlayCamera)

    setupLights:()=>
      pointLight =
        new THREE.PointLight(0x333333,3)
      pointLight.position.x = -2500
      pointLight.position.y = -2500
      pointLight.position.z = 2200
      
      pointLight2 =
        new THREE.PointLight(0x333333,3)
      pointLight2.position.x = 2500
      pointLight2.position.y = 2500
      pointLight2.position.z = -5200

      @ambientColor = '0x253565'
      @ambientColor = '0x354575'
      @ambientColor = '0x455585'
      @ambientColor = '0x565595'
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
          @camera.position.x = -450
          @camera.position.y = -450
          @camera.position.z = 750
          
          @overlayCamera.position.x = -150
          @overlayCamera.position.y = -150
          @overlayCamera.position.z = 250
          
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          
        when 'top'
          #@camera.toTopView()
          #@overlayCamera.toTopView()
          
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new THREE.Vector3()
            nPost.z = offset.length()
            @camera.position = nPost
            
          catch error
            @camera.position = new THREE.Vector3(0,0,750)
            
          @overlayCamera.position = new THREE.Vector3(0,0,250)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          #@camera.rotationAutoUpdate = true
          #@overlayCamera.rotationAutoUpdate = true
          
          
        when 'bottom'
          #@camera.toBottomView()
          #@overlayCamera.toBottomView()
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.z = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,0,-750)
            
          @overlayCamera.position = new THREE.Vector3(0,0,-250)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          #@camera.rotationAutoUpdate = true
          
        when 'front'
          #@camera.toFrontView()
          #@overlayCamera.toFrontView()
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.y = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,-450,0)
            
          @overlayCamera.position = new THREE.Vector3(0,-250,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          #@camera.rotationAutoUpdate = true
          
          
        when 'back'
          #@camera.toBackView()
          #@overlayCamera.toBackView()
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.y = offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(0,450,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(0,250,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          
        when 'left'
          #@camera.toLeftView()
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.x = offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(450,0,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(250,0,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
          
        when 'right'
          #@camera.toRightView()
          try
            offset = @camera.position.clone().subSelf(@controls.target)
            nPost = new  THREE.Vector3()
            nPost.x = -offset.length()
            @camera.position = nPost
          catch error
            @camera.position = new THREE.Vector3(-450,0,0)
          #@camera.rotationAutoUpdate = true
          @overlayCamera.position = new THREE.Vector3(-250,0,0)
          @camera.lookAt(@scene.position)
          @overlayCamera.lookAt(@overlayscene.position)
         
          
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
        
        gridGeometry = new THREE.Geometry()
        gridMaterial = new THREE.LineBasicMaterial
          color: new THREE.Color().setHex(gridColor)
          opacity: gridOpacity
          linewidth:2
          transparent:true
        
        for i in [-gridSize/2..gridSize/2] by gridStep
          gridGeometry.vertices.push(new THREE.Vector3(-gridSize/2, i, 0))
          gridGeometry.vertices.push(new THREE.Vector3(gridSize/2, i, 0))
          
          gridGeometry.vertices.push(new THREE.Vector3(i, -gridSize/2, 0))
          gridGeometry.vertices.push(new THREE.Vector3(i, gridSize/2, 0))
        @grid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
        @scene.add @grid
        
        gridGeometry = new THREE.Geometry()
        gridMaterial = new THREE.LineBasicMaterial({ color: new THREE.Color().setHex(gridColor), opacity: gridOpacity/2 ,transparent:true})
        
        for i in [-gridSize/2..gridSize/2] by gridStep/10
          gridGeometry.vertices.push(new THREE.Vector3(-gridSize/2, i, 0))
          gridGeometry.vertices.push(new THREE.Vector3(gridSize/2, i, 0))
          
          gridGeometry.vertices.push(new THREE.Vector3(i, -gridSize/2, 0))
          gridGeometry.vertices.push(new THREE.Vector3(i, gridSize/2, 0))
        @subGrid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
        @scene.add @subGrid
        
        #######
        planeGeometry = new THREE.PlaneGeometry(-gridSize, gridSize, 5, 5)
        #taken from http://stackoverflow.com/questions/12876854/three-js-casting-a-shadow-onto-a-webpage
        planeFragmentShader = [
            "uniform vec3 diffuse;",
            "uniform float opacity;",

            THREE.ShaderChunk[ "color_pars_fragment" ],
            THREE.ShaderChunk[ "map_pars_fragment" ],
            THREE.ShaderChunk[ "lightmap_pars_fragment" ],
            THREE.ShaderChunk[ "envmap_pars_fragment" ],
            THREE.ShaderChunk[ "fog_pars_fragment" ],
            THREE.ShaderChunk[ "shadowmap_pars_fragment" ],
            THREE.ShaderChunk[ "specularmap_pars_fragment" ],

            "void main() {",

                "gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0 );",

                THREE.ShaderChunk[ "map_fragment" ],
                THREE.ShaderChunk[ "alphatest_fragment" ],
                THREE.ShaderChunk[ "specularmap_fragment" ],
                THREE.ShaderChunk[ "lightmap_fragment" ],
                THREE.ShaderChunk[ "color_fragment" ],
                THREE.ShaderChunk[ "envmap_fragment" ],
                THREE.ShaderChunk[ "shadowmap_fragment" ],
                THREE.ShaderChunk[ "linear_to_gamma_fragment" ],
                THREE.ShaderChunk[ "fog_fragment" ],

                "gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 - shadowColor.x );",

            "}"

        ].join("\n")

        planeMaterial = new THREE.ShaderMaterial
            uniforms: THREE.ShaderLib['basic'].uniforms,
            vertexShader: THREE.ShaderLib['basic'].vertexShader,
            fragmentShader: planeFragmentShader,
            color: 0x0000FF
            transparent:true
        
        @plane = new THREE.Mesh(planeGeometry, planeMaterial)
        @plane.rotation.x = Math.PI
        @plane.position.z = -2
        @plane.name = "workplane"
        @plane.receiveShadow = true
        
        @scene.add(@plane)
       
    removeGrid:()=>
      if @grid
        @scene.remove @plane
        @scene.remove @grid
        @scene.remove @subGrid
        delete @grid
        delete @subGrid
        delete @plane
      
    addAxes:()->
      helpersColor = @settings.get("helpersColor")
      helpersColor = new THREE.Color().setHex(helpersColor)
      @axes = new MyAxisHelper(200,helpersColor,helpersColor, helpersColor)
      @scene.add(@axes)
      
      @xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),50, 0xFF7700)
      @yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),50, 0x77FF00)
      @zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,0),50, 0x0077FF)
      @overlayscene.add @xArrow
      @overlayscene.add @yArrow
      @overlayscene.add @zArrow
      
      @xLabel=@drawText("X")
      @xLabel.position.set(55,0,0)
      @overlayscene.add(@xLabel)
      
      @yLabel=@drawText("Y")
      @yLabel.position.set(0,55,0)
      @overlayscene.add(@yLabel)
      
      @zLabel=@drawText("Z")
      @zLabel.position.set(0,0,55)
      @overlayscene.add(@zLabel)
      
    removeAxes:()->
      @scene.remove @axes
      
      @overlayscene.remove @xArrow
      @overlayscene.remove @yArrow
      @overlayscene.remove @zArrow
      
      @overlayscene.remove @xLabel
      @overlayscene.remove @yLabel
      @overlayscene.remove @zLabel
      
    addCage:(mesh)=>
      helpersColor = @settings.get("helpersColor")
      helpersColor = new THREE.Color().setHex(helpersColor)
      #attempt to draw bounding box
      try
        bbox = mesh.geometry.boundingBox
        length = bbox.max.x-bbox.min.x
        width  = bbox.max.y-bbox.min.y
        height = bbox.max.z-bbox.min.z
        
        cageGeo= new THREE.CubeGeometry(length,width,height)
        v=(x,y,z)->
           return new THREE.Vector3(x,y,z)
       
        ###lineMat = new THREE.LineBasicMaterial
          color: helpersColor
          lineWidth: 2
        ###
        lineMat = new THREE.MeshBasicMaterial
          color: helpersColor
          wireframe: true
          shading:THREE.FlatShading
        
        cage = new THREE.Mesh(cageGeo, lineMat)
        #cage = new THREE.Line(cageGeo, lineMat, THREE.Lines)
        middlePoint=(geometry)->
          middle  = new THREE.Vector3()
          middle.x  = ( geometry.boundingBox.max.x + geometry.boundingBox.min.x ) / 2
          middle.y  = ( geometry.boundingBox.max.y + geometry.boundingBox.min.y ) / 2
          middle.z  = ( geometry.boundingBox.max.z + geometry.boundingBox.min.z ) / 2
          return middle
        
        delta = middlePoint(mesh.geometry)
        cage.position = delta
           
        ###
        texture = @drawText2(height.toFixed(2))
        testLabel = new THREE.Sprite
          map: texture
          useScreenCoordinates: false
          #alignment: THREE.SpriteAlignment.bottom
        testLabel.position.set(-length/2,-width/2,0)
        cage.add testLabel
        ###
        widthLabel=@drawText("w: #{width.toFixed(2)}")
        widthLabel.position.set(-length/2-10,0,height/2)
        
        lengthLabel=@drawText("l: #{length.toFixed(2)}")
        lengthLabel.position.set(0,-width/2-10,height/2)
  
        heightLabel=@drawText("h: #{height.toFixed(2)}")
        heightLabel.position.set(-length/2-10,-width/2-10,height/2)
        
        cage.add widthLabel
        cage.add lengthLabel
        cage.add heightLabel
      
        #TODO: solve z fighting issue
        widthArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),50, 0xFF7700)
        lengthArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),50, 0x77FF00)
        heightArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(-length/2,-width/2,-height/2),height, 0x0077FF)
        
        cage.add widthArrow
        cage.add lengthArrow
        cage.add heightArrow
        
        mesh.cage = cage
        mesh.add cage
      catch error
      
    drawText:(text)=>
      helpersColor = @settings.get("helpersColor")
      if helpersColor.indexOf "0x" == 0
        helpersColor= "#"+helpersColor[2..]
      
      canvas = document.createElement('canvas')
      
      canvas.width = 640
      canvas.height = 640
      context = canvas.getContext('2d')
      context.font = "17px sans-serif"
      context.fillStyle = helpersColor
      context.fillText(text, canvas.width/2, canvas.height/2)
     
      context.strokeStyle = '#FFFFFF'
      context.strokeText(text, canvas.width/2, canvas.height/2)
      

      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      sprite = new THREE.Sprite
        map: texture
        transparent: true
        useScreenCoordinates: false
        scaleByViewport:false
      return sprite
      
    drawText2:(text)=>
      helpersColor = @settings.get("helpersColor")
      if helpersColor.indexOf "0x" == 0
        helpersColor= "#"+helpersColor[2..]
      
      canvas = document.createElement('canvas')
      
      context = canvas.getContext('2d')
      context.font = "17px sans-serif"
      context.fillStyle = helpersColor
      context.fillText(text, 0, 17);
      context.strokeStyle = '#FFFFFF'
      context.strokeText(text, 0, 17)
      
      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      return texture
    
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
      @particleMaterial = new THREE.MeshBasicMaterial( { map: texture, transparent: true ,color: 0x000000} );
    
    onResize:()=>
      
      @width =  $("#glArea").width()
      @height = window.innerHeight-10
      #@camera.aspect = @width / @height
      #@camera.updateProjectionMatrix()
      
      @camera.setSize(@width,@height)
      @camera.updateProjectionMatrix()
      
      @renderer.setSize(@width, @height)
      
      #@overlayCamera.position.z = @camera.position.z/3
      #@overlayCamera.position.y = @camera.position.y/3
      #@overlayCamera.position.x = @camera.position.x/3
      
      @_render()
    
    onRender:()=>
      selectors = @ui.overlayDiv.children(" .uicons")
      selectors.tooltip()
      
      if @settings.get("showStats")
        @ui.overlayDiv.append(@stats.domElement)
        
      @width = $("#visual").width()
      @height = window.innerHeight-10#$("#gl").height()
     
      #@camera.aspect = @width / @height
      #@camera.updateProjectionMatrix()
      @camera.setSize(@width,@height)
      @camera.updateProjectionMatrix()
      @renderer.setSize(@width, @height)
      
      #FIXME: remove this totally random stuff
      #@overlayCamera.position.z = @camera.position.z
      #@overlayCamera.position.y = @camera.position.y
      #@overlayCamera.position.x = @camera.position.x
      #@overlayCamera.position.z = 150
      #@overlayCamera.position.y = 250
      #@overlayCamera.position.x = 150
            
      @_render()
      
      
      @$el.resize @onResize
      window.addEventListener('resize', @onResize, false)
      ##########
      
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      @controls = new THREE.CustomOrbitControls(@camera, @el)
      @controls.rotateSpeed = 1.8
      @controls.zoomSpeed = 4.2
      @controls.panSpeed = 1.8
      
      #CustomOrbitControls
      #OrbitControls
      ###TrackballControls
      @controls.autoRotate = false
      

      @controls.noZoom = false
      @controls.noPan = false

      @controls.staticMoving = true
      @controls.dynamicDampingFactor = 0.3
      ###
      @controls.addEventListener( 'change', @_render )
      
      ########
      container2 = $(@ui.glOverlayBlock)
      container2.append(@overlayRenderer.domElement)
      
      @overlayControls = new THREE.CustomOrbitControls(@overlayCamera, @el)
      @overlayControls.noPan = true
      #@overlayControls.noZoom = true
      @overlayControls.rotateSpeed = 1.8
      @overlayControls.zoomSpeed = 0
      @overlayControls.panSpeed = 0
      @overlayControls.userZoomSpeed=0
      ### 
      @overlayControls.autoRotate = false
      @overlayControls.staticMoving = true
      @overlayControls.dynamicDampingFactor = 0.3
      ###
      @animate()
      
    
    _render:()=>
      @renderer.render(@scene, @camera)
      @overlayRenderer.render(@overlayscene, @overlayCamera)
      
      if @settings.get("showStats")
        @stats.update()
      #@cameraHelper.update()
      
    animate:()=>
      @controls.update()
      @overlayControls.update()

      requestAnimationFrame(@animate)
    
    toCsgTest:(mesh)->
      csgResult = THREE.CSG.toCSG(mesh)
      if csgResult?
        console.log "CSG conversion result ok:"
      
    fromCsg:(csg)=>
      #try
      start = new Date().getTime()
      res = csg
      #console.log "project compiled, updating view"
      if @assembly?
        @scene.remove @assembly
        @current=null
      
      @assembly = new THREE.Mesh(new THREE.Geometry())
      @assembly.name = "assembly"
      
      for index, part of res.children
        @_importGeom(part,@assembly)
        
      @scene.add @assembly 
      #catch error
      #  console.log "Csg Generation error: #{error} "
      #  @vent.trigger("csgParseError", error)
      #finally
      end = new Date().getTime()
      console.log "Csg visualization time: #{end-start}"
      @_render()
      
    _importGeom:(csgObj,rootObj)=>
      geom = THREE.CSG.fromCSG(csgObj)
      shine= 1500
      spec= 10000000000
      if @renderer instanceof THREE.CanvasRenderer
        mat = new THREE.MeshLambertMaterial({color:  0xFFFFFF}) 
        mat.overdraw = true
      else 
        mat = new THREE.MeshPhongMaterial({color:  0xFFFFFF , shading: THREE.SmoothShading,  shininess: shine, specular: spec, metal: true, vertexColors: THREE.VertexColors}) 
      mesh = new THREE.Mesh(geom, mat)
      mesh.castShadow =  @settings.get("shadows")
      mesh.receiveShadow = @settings.get("selfShadows") and @settings.get("shadows")
      mesh.material.wireframe = @settings.get("wireframe")
      mesh.name = csgObj.constructor.name
      mesh.geometry.computeCentroids()
      
      if @renderer instanceof THREE.CanvasRenderer
        mesh.doubleSided = true
      
      #get object connectors
      for i, conn of geom.connectors
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
