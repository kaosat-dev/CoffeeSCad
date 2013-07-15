define (require) ->
  THREE = require 'three'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  
  class BaseHelper extends THREE.Object3D
    constructor:(options)->
      super options
      
    drawText:(text, displaySize, background,scale)=>
      fontSize = displaySize or 18
      background = background or false
      scale = scale or 1.0
      
      canvas = document.createElement('canvas')
      borderThickness = 2
      context = canvas.getContext('2d')
      context.font = "15px Arial"
      context.textAlign = 'center'
      context.fillStyle = @textColor
      context.fillStyle = "rgba(0, 0, 0, 1.0)";
      
      
      rect=(ctx, x, y, w, h, r)->
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x+w, y);
        ctx.lineTo(x+w, y+h);
        ctx.lineTo(x, y+h);
        ctx.lineTo(x, y);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();   
      
      if background
        metrics = context.measureText( text )
        textWidth = metrics.width;
        context.fillStyle = "rgba(255, 255, 255, 0.55)";
        context.strokeStyle = "rgba(255,255,255,0.55)";
        rect(context, canvas.width/2-fontSize, canvas.height/2-fontSize, textWidth + borderThickness, fontSize * 1.4 + borderThickness, 6);
      
      #context.fillStyle = "rgba(0, 0, 0, 1.0)";
      #context.fillText(text, canvas.width/2, canvas.height/2)
      context.strokeStyle = @textColor
      context.strokeText(text, canvas.width/2, canvas.height/2)
      
      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      #texture.magFilter = THREE.LinearFilter
      #texture.minFilter = THREE.LinearFilter
      
      spriteMaterial = new THREE.SpriteMaterial
         map: texture
         transparent:true
         alphaTest: 0.5
         #alignment: THREE.SpriteAlignment.topLeft,
         useScreenCoordinates: false
         scaleByViewport:false
         color: 0xffffff
      sprite = new THREE.Sprite(spriteMaterial)
      sprite.scale.set( 100*scale, 50*scale, 1.0)
      return sprite
    
    drawTextOnPlane:(text, size=256)=>
      #unlike a sprite, does not orient itself to face the camera
      #also, no snakes here
      canvas = document.createElement('canvas')
      canvas.width = size
      canvas.height = size
      context = canvas.getContext('2d')
      context.font = "18px sans-serif"
      context.textAlign = 'center'
      context.fillStyle = @textColor
      context.fillText(text, canvas.width/2, canvas.height/2)
     
      context.strokeStyle = @textColor
      context.strokeText(text, canvas.width/2, canvas.height/2)
      
      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      texture.generateMipmaps = true
      texture.magFilter = THREE.LinearFilter
      texture.minFilter = THREE.LinearFilter
      #texture.anisotropy = 32
      
      material = new THREE.MeshBasicMaterial
        map: texture
        transparent: true 
        color: 0xffffff
        alphaTest: 0.2
      
      plane = new THREE.Mesh(new THREE.PlaneGeometry(size/8, size/8),material)
      plane.doubleSided = true
      plane.overdraw = true
      return plane
    
    
  class Arrow extends BaseHelper
    constructor:(options)->
      super options
      defaults = {direction:new THREE.Vector3(1,0,0),origin:new THREE.Vector3(0,0,0),length:50, color:"#FF0000"}
      options = merge defaults, options
      {@direction, @origin, @length, @color} = options

      #dir, origin, length, hex
      lineGeometry = new THREE.Geometry()
      lineGeometry.vertices.push(@origin)
      lineGeometry.vertices.push(@direction.setLength(@length))
      @line = new THREE.Line( lineGeometry, new THREE.LineBasicMaterial( { color: @color } ) )
      @add @line
      
      @arrowHeadRootPosition = @origin.clone().add(@direction)
      @arrowHead = new THREE.Mesh(new THREE.CylinderGeometry(0, 1, 5, 10, 10, false),new THREE.MeshBasicMaterial({color:@color}))
      @arrowHead.position = @arrowHeadRootPosition
      #@arrowHead.rotation = Math.PI/2
      @add @arrowHead
      
  
  class LabeledAxes extends BaseHelper
    constructor:(options)->
      super options
      defaults = {size:50, xColor:"0xFF7700",yColor:0x77FF00,zColor:0x0077FF,textColor:"#FFFFFF",addLabels:true, addArrows:true}
      options = merge defaults, options
      {@size, @xColor, @yColor, @zColor, @textColor, addLabels, addArrows} = options

      @xColor = new THREE.Color().setHex(@xColor)
      @yColor = new THREE.Color().setHex(@yColor)
      @zColor = new THREE.Color().setHex(@zColor)

      #addLabels = false
      if addLabels
        s = @size * 1.1
        fontSize = 18
        scale = 0.008
        @xLabel=@drawText("X",fontSize,false, scale)
        @xLabel.position.set(s,0,0)
        
        @yLabel=@drawText("Y",fontSize,false, scale)
        @yLabel.position.set(0,s,0)
        
        @zLabel=@drawText("Z",fontSize,false, scale)
        @zLabel.position.set(0,0,s)
        
      if addArrows
        s = @size / 1.25 # THREE.ArrowHelper arrow length
        @xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),s, @xColor)
        @yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),s, @yColor)
        @zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,0),s, @zColor)
        @add @xArrow
        @add @yArrow
        @add @zArrow
      else
        @_buildAxes()
        
      @add @xLabel
      @add @yLabel 
      @add @zLabel
      @name = "axes"
    
    _buildAxes:()=>
      lineGeometryX = new THREE.Geometry()
      lineGeometryX.vertices.push( new THREE.Vector3(-@size, 0, 0 ))
      lineGeometryX.vertices.push( new THREE.Vector3( @size, 0, 0 ))
      xLine = new THREE.Line( lineGeometryX, new THREE.LineBasicMaterial( { color: @xColor } ) )
      
      lineGeometryY = new THREE.Geometry()
      lineGeometryY.vertices.push( new THREE.Vector3(0, -@size, 0 ))
      lineGeometryY.vertices.push( new THREE.Vector3( 0, @size, 0 ))
      yLine = new THREE.Line( lineGeometryY, new THREE.LineBasicMaterial( { color: @yColor } ) )
      
      lineGeometryZ = new THREE.Geometry()
      lineGeometryZ.vertices.push( new THREE.Vector3(0, 0, -@size ))
      lineGeometryZ.vertices.push( new THREE.Vector3(0, 0, @size ))
      zLine = new THREE.Line( lineGeometryZ, new THREE.LineBasicMaterial( { color: @zColor } ) )
      
      @add xLine
      @add yLine
      @add zLine

  
  class Grid extends BaseHelper
    #Grid class: contains a basic flat grid, a subgrid and an invisible "plane" for shadow projection "onto" the grid
      
    constructor:(options)->
      super options
      
      defaults = {size:1000, step:100, color:0xFFFFFF, opacity:0.1, addText:true, textColor:"#FFFFFF", textLocation:"f",rootAssembly:null}
      options = merge defaults, options
      {@size, @step, @color, @opacity, @addText, @textColor, @textLocation, @rootAssembly} = options
      
      @name = "grid"
      @_drawGrid()
    
    _drawGrid:->
      mainGridZ = -0.05
      gridGeometry = new THREE.Geometry()
      gridMaterial = new THREE.LineBasicMaterial
        color: new THREE.Color().setHex(@color)
        opacity: @opacity
        linewidth:2
        transparent:true
      
      for i in [-@size/2..@size/2] by @step
        gridGeometry.vertices.push(new THREE.Vector3(-@size/2, i, mainGridZ))
        gridGeometry.vertices.push(new THREE.Vector3(@size/2, i, mainGridZ))
        
        gridGeometry.vertices.push(new THREE.Vector3(i, -@size/2, mainGridZ))
        gridGeometry.vertices.push(new THREE.Vector3(i, @size/2, mainGridZ))
        
      @mainGrid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
      
      subGridZ = -0.05
      subGridGeometry = new THREE.Geometry()
      subGridMaterial = new THREE.LineBasicMaterial({ color: new THREE.Color().setHex(@color), opacity: @opacity/2 ,transparent:true})
      
      for i in [-@size/2..@size/2] by @step/10
        subGridGeometry.vertices.push(new THREE.Vector3(-@size/2, i, subGridZ))
        subGridGeometry.vertices.push(new THREE.Vector3(@size/2, i, subGridZ))
        
        subGridGeometry.vertices.push(new THREE.Vector3(i, -@size/2, subGridZ))
        subGridGeometry.vertices.push(new THREE.Vector3(i, @size/2, subGridZ))
      @subGrid = new THREE.Line(subGridGeometry, subGridMaterial, THREE.LinePieces)
      
      
      #######
      planeGeometry = new THREE.PlaneGeometry(-@size, @size, 5, 5)
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
      @plane.position.z = -0.3
      @plane.name = "workplane"
      @plane.receiveShadow = true
      
      @add @mainGrid
      @add @subGrid
      @add @plane
      @_drawNumbering()
    
    _drawNumbering:->
      if @labels?
        @mainGrid.remove(@labels)
      
      @labels = new THREE.Object3D()
      xLabelsLeft = new THREE.Object3D()
      yLabelsFront = new THREE.Object3D()
      
      for i in [-@size/2..@size/2] by @step
        #Add size labeling
        sizeLabel=@drawTextOnPlane("#{i}",32)
        sizeLabel2 =sizeLabel.clone() #for other direction labeling
        sizeLabel.rotation.z=Math.PI/2
        sizeLabel.position.set(i,@size/2,0.1)
        xLabelsLeft.add(sizeLabel)
        
        if @textLocation is "center"
          if i!=0
            #don't draw 0 twice
            sizeLabel2.position.set(@size/2,i,0.1)
            sizeLabel2.rotation.z=Math.PI/2
            yLabelsFront.add(sizeLabel2)
        else 
          if i!=@size/2 and i!= -@size/2
            #don't draw max values twice
            sizeLabel2.position.set(@size/2,i,0.1)
            sizeLabel2.rotation.z=Math.PI/2
            yLabelsFront.add(sizeLabel2)
      
      if @textLocation is "center"
        xLabelsLeft.translateY(-@size/2)
        yLabelsFront.translateX(-@size/2)
      else
        xLabelsRight = xLabelsLeft.clone().translateY(-@size)
        yLabelsBack  = yLabelsFront.clone().translateX(-@size)
        @labels.add(xLabelsRight) 
        @labels.add(yLabelsBack)
      
      @labels.add(xLabelsLeft)  
      @labels.add(yLabelsFront)
      
      for label in @labels.children
        label.visible = @addText
      
      @mainGrid.add(@labels)
     
    setOpacity:(opacity)=>
      @opacity = opacity
      @mainGrid.material.opacity = opacity
      @subGrid.material.opacity = opacity
       
    setColor:(color)=>
      @color = color 
      @mainGrid.material.color = new THREE.Color().setHex(@color)
      @subGrid.material.color = new THREE.Color().setHex(@color)
     
    toggleText:(toggle)=>
      @addText = toggle
      for label in @labels.children
        label.visible = toggle

    setTextColor:(color)=>
      @textColor = color
      @_drawNumbering()
    
    setTextLocation:(location)=>
      @textLocation = location
      @_drawNumbering()
    
    resize:(size)=>
      if size != @size
        @size = size
        @remove @mainGrid
        @remove @subGrid
        @remove @plane
        @_drawGrid()
        
    
    updateGridSize:()=>
      #autgrow grid to accomodate all objects in assembly
      minX = 99999
      maxX = -99999
      minY = 99999
      maxY = -99999
      
      _getBounds=(mesh)=>
        if (mesh instanceof THREE.Mesh)
          mesh.geometry.computeBoundingBox()
          bBox = mesh.geometry.boundingBox

          # compute overall bbox
          #TODO: mesh.position additions are actually correct, the way we get shapes from csg.js is NOT
          minX = Math.min(minX, bBox.min.x)#+mesh.position.x
          maxX = Math.max(maxX, bBox.max.x)#+mesh.position.x
          minY = Math.min(minY, bBox.min.y)#+mesh.position.y
          maxY = Math.max(maxY, bBox.max.y)#+mesh.position.y
          
          for subchild in mesh.children
            _getBounds(subchild)
        
      if @rootAssembly?
        for subchild in @rootAssembly.children
          if subchild.name != "renderSubs" and subchild.name !="connectors"
            _getBounds(subchild)
      
      #console.log("Bounds for grid", minX, maxX, minY, maxY)
      max = Math.max(Math.max(maxX, maxY),100)
      min = Math.min(Math.min(minX, minY),-100)
      #console.log("Bounds for grid", max, min)
      size = (Math.max(max, Math.abs(min)))*2
      #console.log("New size for grid", size)
      size = Math.ceil(size / 10) * 10
      if size >= 200
        @resize(size)
      
  class BoundingCage extends BaseHelper
    #Draws a bounding box (wireframe) around a mesh, and shows its dimentions
    constructor:(options)->
      super options
      defaults = {mesh:null,color:0xFFFFFF,textColor:"#FFFFFF",addLabels:true}
      options = merge defaults, options
      {mesh, @color, @textColor,@addLabels} = options
      color = new THREE.Color().setHex(@color)
      #attempt to draw bounding box
      try
        if not mesh.geometry.boundingBox
          mesh.geometry.computeBoundingBox()
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
          color: color
          wireframe: true
          shading:THREE.FlatShading
        
        cage = new THREE.Object3D()#new THREE.Mesh(cageGeo, lineMat)
        #cage = new THREE.Line(cageGeo, lineMat, THREE.Lines)
        middlePoint=(geometry)->
          middle  = new THREE.Vector3()
          middle.x  = ( geometry.boundingBox.max.x + geometry.boundingBox.min.x ) / 2
          middle.y  = ( geometry.boundingBox.max.y + geometry.boundingBox.min.y ) / 2
          middle.z  = ( geometry.boundingBox.max.z + geometry.boundingBox.min.z ) / 2
          return middle
        
        delta = middlePoint(mesh.geometry)
        cage.position = delta
        
        
        
        widthArrowPos = new THREE.Vector3( length/2+10, 0, -height/2 )
        lengthArrowPos = new THREE.Vector3( 0, width/2+10, -height/2)
        heightArrowPos = new THREE.Vector3( -length/2-5,-width/2-5,0)
        
        if @addLabels
          labelSize = 24
          widthLabel=@drawText("#{width.toFixed(2)}",labelSize)
          widthLabel.position = widthArrowPos 
          
          lengthLabel=@drawText("#{length.toFixed(2)}",labelSize)
          lengthLabel.position = lengthArrowPos
    
          heightLabel=@drawText("#{height.toFixed(2)}",labelSize)
          heightLabel.position = heightArrowPos
          
          cage.add widthLabel
          cage.add lengthLabel
          cage.add heightLabel
       
          widthLabel.material.depthTest = false
          widthLabel.material.depthWrite = false
          widthLabel.material.side= THREE.FrontSide 
          
          lengthLabel.material.depthTest = false
          lengthLabel.material.depthWrite = false
          lengthLabel.material.side= THREE.FrontSide 
          
          heightLabel.material.depthTest = false
          heightLabel.material.depthWrite = false
          heightLabel.material.side= THREE.FrontSide 
          
          
       
        forceOverlay=(arrows,sideLines)=>
          for arrow in arrows
            arrow.cone.material.side= THREE.FrontSide 
            arrow.line.material.side= THREE.FrontSide 
            #arrow.line.material.depthWrite = false
            arrow.line.material.depthTest = false
            #arrow.cone.material.depthWrite = false
            arrow.cone.material.depthTest = false
            arrow.line.renderDepth = 1e20
            arrow.cone.renderDepth = 1e20
          
          for line in sideLines
            line.material.side= THREE.FrontSide 
            line.material.depthTest = false
            line.renderDepth = 1e20
          
        require 'ArrowHelper2'  
        
        widthArrow1 = new THREE.ArrowHelper2(new THREE.Vector3(0,-1,0),widthArrowPos,width/2, 0x000000)
        widthArrow2 = new THREE.ArrowHelper2(new THREE.Vector3(0,1,0),widthArrowPos,width/2, 0x000000)
        
        widthLineGeometry = new THREE.Geometry();
        widthLineGeometry.vertices.push( new THREE.Vector3( length/2, width/2, -height/2 ) );
        widthLineGeometry.vertices.push( new THREE.Vector3( length/2+10, width/2, -height/2 ) );
        widthLine = new THREE.Line( widthLineGeometry, new THREE.LineBasicMaterial( { color: 0x000000,depthTest:false,depthWrite:false,renderDepth : 1e20 } ) );
        cage.add( widthLine)
        
        widthLineGeometry2 = new THREE.Geometry();
        widthLineGeometry2.vertices.push( new THREE.Vector3( length/2, -width/2, -height/2 ) );
        widthLineGeometry2.vertices.push( new THREE.Vector3( length/2+10, -width/2, -height/2 ) );
        widthLine2 = new THREE.Line( widthLineGeometry2, new THREE.LineBasicMaterial( { color: 0x000000 } ) );
        cage.add( widthLine2)
        forceOverlay([widthArrow1,widthArrow2], [widthLine,widthLine2])
         
        lengthArrow1 = new THREE.ArrowHelper2(new THREE.Vector3(1,0,0),lengthArrowPos,length/2, 0x000000)
        lengthArrow2 = new THREE.ArrowHelper2(new THREE.Vector3(-1,0,0),lengthArrowPos,length/2, 0x000000)
        
        lengthLineGeometry = new THREE.Geometry();
        lengthLineGeometry.vertices.push( new THREE.Vector3( length/2, width/2,  -height/2 ) )
        lengthLineGeometry.vertices.push( new THREE.Vector3( length/2, width/2+10, -height/2 ) )
        lengthLine = new THREE.Line( lengthLineGeometry, new THREE.LineBasicMaterial( { color: 0x000000 } ) )
        cage.add( lengthLine);
        
        lengthLineGeometry2 = new THREE.Geometry();
        lengthLineGeometry2.vertices.push( new THREE.Vector3( -length/2, width/2, -height/2 ) )
        lengthLineGeometry2.vertices.push( new THREE.Vector3( -length/2, width/2 +10, -height/2 ) )
        lengthLine2 = new THREE.Line( lengthLineGeometry2, new THREE.LineBasicMaterial( { color: 0x000000 } ) )
        cage.add( lengthLine2)
        
        forceOverlay([lengthArrow1,lengthArrow2], [lengthLine,lengthLine2])
        
        
        heightArrow1 = new THREE.ArrowHelper2(new THREE.Vector3(0,0,1),heightArrowPos,height/2, 0x000000)
        heightArrow2 = new THREE.ArrowHelper2(new THREE.Vector3(0,0,-1),heightArrowPos,height/2, 0x000000)
        
        
        heightLineGeometry = new THREE.Geometry();
        heightLineGeometry.vertices.push( new THREE.Vector3( -length/2, -width/2, -height/2 ) )
        heightLineGeometry.vertices.push( new THREE.Vector3( -length/2-5, -width/2 -5, -height/2 ) )
        heightLine = new THREE.Line( heightLineGeometry, new THREE.LineBasicMaterial( { color: 0x000000 } ) )
        
        heightLineGeometry2 = new THREE.Geometry();
        heightLineGeometry2.vertices.push( new THREE.Vector3( -length/2, -width/2, height/2 ) )
        heightLineGeometry2.vertices.push( new THREE.Vector3( -length/2-5, -width/2 -5, height/2 ) )
        heightLine2 = new THREE.Line( heightLineGeometry2, new THREE.LineBasicMaterial( { color: 0x000000 } ) )
        
        
        forceOverlay([heightArrow1,heightArrow2], [heightLine,heightLine2])
        
        cage.add( heightLine)
        cage.add( heightLine2)
        
        
        ###
        selectionAxis = new THREE.AxisHelper(Math.min(width,length, height))
        selectionAxis.material.depthTest = false
        selectionAxis.material.transparent = true
        selectionAxis.position = mesh.position###
        #selectionAxis.matrixAutoUpdate = false
        
        dashMaterial = new THREE.LineDashedMaterial( { color: 0x000000, dashSize: 0.5, gapSize: 2, depthTest: false,linewidth:2} )
        baseCubeGeom = new THREE.CubeGeometry(length,width,0)
        baseOutline = new THREE.Line( geometryToline(baseCubeGeom.clone()), dashMaterial, THREE.LinePieces )
        baseOutline.renderDepth = 1e20
        baseOutline.position = new THREE.Vector3(delta.x,delta.y,-delta.z)
        cage.add(baseOutline)
        
        
        cage.name = "boundingCage"
        cage.add widthArrow1
        cage.add widthArrow2
        
        cage.add lengthArrow1
        cage.add lengthArrow2
        
        cage.add heightArrow1
        cage.add heightArrow2
        
        mesh.cage = cage
        mesh.add cage
        
        computeVolume(mesh)
        
      catch error
      
  
  class SelectionHelper extends BaseHelper
    #Helper to detect intersection with mouse /touch position (hover and click) and apply effect  
    constructor:(options)->
      super options
      defaults = {hiearchyRoot:null,camera :null ,viewWidth:640, viewHeight:480}
      options = merge defaults, options
      {@hiearchyRoot, @camera, @viewWidth, @viewHeight} = options
      @options = options
      @currentHover = null
      @currentSelect = null
      @selectionColor = 0xfffccc
      @projector = new THREE.Projector()
      
      
      @addEventListener = THREE.EventDispatcher.prototype.addEventListener
      @hasEventListener = THREE.EventDispatcher.prototype.hasEventListener
      @removeEventListener = THREE.EventDispatcher.prototype.removeEventListener
      @dispatchEvent = THREE.EventDispatcher.prototype.dispatchEvent
      
    
    _onHover:(selection)=>
      #console.log "currentHover", selection
      if selection?
        @currentHover = selection
        
        if not (selection.hoverOutline?) and not (selection.outline?) and not (selection.name is "hoverOutline") and not (selection.name is "boundingCage") and not (selection.name is "selectOutline")
          selection.currentHoverHex = selection.material.color.getHex()
          selection.material.color.setHex( @selectionColor )
          #
          outlineMaterial = new THREE.MeshBasicMaterial( { color: 0xffc200, side: THREE.BackSide } )
          outline = new THREE.Mesh( selection.geometry.clone(), outlineMaterial )
          #outline.position = selection.position
          outline.scale.multiplyScalar(1.03)
          outline.name = "hoverOutline"
          #selection.material.side = THREE.FrontSide
          selection.hoverOutline = outline
          selection.add( outline )
          
        @dispatchEvent({type:'hoverIn',selection:selection})
      
    _unHover:=>
      if @currentHover
        if @currentHover.hoverOutline?
          @currentHover.material.color.setHex( @currentHover.currentHoverHex )
          @currentHover.remove(@currentHover.hoverOutline)
          @currentHover.hoverOutline = null
        
        @currentHover = null
        @dispatchEvent({type:'hoverOut',selection:@currentHover})
    
    _onSelect:(selection)=>
      #console.log "currentSelect", selection
      @_unHover()
      @currentSelect = selection
      new BoundingCage({mesh:selection,color:@options.color,textColor:@options.textColor})
      #selection.currentSelectHex = selection.material.color.getHex()
      #selection.material.color.setHex( @selectionColor )
      
      outlineMaterial = new THREE.MeshBasicMaterial( { color: 0xffc200, side: THREE.BackSide } )
      outline = new THREE.Mesh( selection.geometry.clone(), outlineMaterial )
      outline.name = "selectOutline"
      #outline.position = selection.position
      outline.scale.multiplyScalar(1.03)
      selection.outline = outline
      selection.add( outline )
      
      @dispatchEvent({type:'selected',selection:selection})
      
    _unSelect:=>
      if @currentSelect
        selection = @currentSelect
        #selection.material.color.setHex( selection.currentSelectHex )
        selection.remove(selection.cage)
        selection.remove(selection.outline)
        selection.cage = null
        selection.outline =null
        @currentSelect = null
        @dispatchEvent({type:'unselected',selection:selection})
      #@currentHover.material = @currentHover.origMaterial if @currentHover.origMaterial
      ###
            newMat = new  THREE.MeshLambertMaterial
                color: 0xCC0000
            @currentHover.origMaterial = @currentHover.material
            @currentHover.material = newMat
            ###
          
    _get3DBB:(object)=>
      #shorthand to get object bounding box
      if object?
        if object.geometry?
          if object.geometry.boundingBox?
            return object.geometry.boundingBox
          else
            object.geometry.computeBoundingBox()
            return object.geometry.boundingBox
      return null
    
    getScreenCoords:(object, width, height)=>
      if object?
        vector = @projector.projectVector( object.position.clone(), @camera )
        result = new THREE.Vector2()
        result.x = Math.round( vector.x * (width/2) ) + width/2
        result.y = Math.round( (0-vector.y) * (height/2) ) + height/2
        return result
      
             
    get2DBB:(object,width,height)=>
      #get the 2d (screen) bounding box of 3d object
      if object?
        bbox3d = @_get3DBB(object)
        min3d = bbox3d.min.clone()
        max3d = bbox3d.max.clone()
        
        objLength = bbox3d.max.x-bbox3d.min.x
        objWidth  = bbox3d.max.y-bbox3d.min.y
        objHeight = bbox3d.max.z-bbox3d.min.z
        
        
        pMin = @projector.projectVector(min3d, @camera) #projectedMin
        pMax = @projector.projectVector(max3d, @camera) #projectedMax
      
        minPercX = (pMin.x + 1) / 2
        minPercY = (-pMin.y + 1) / 2
        # scale these values to our viewport size
        minLeft = minPercX * width
        minTop = minPercY * height
        
        maxPercX = (pMax.x + 1) / 2
        maxPercY = (-pMax.y + 1) / 2
        # scale these values to our viewport size
        maxLeft = maxPercX * width
        maxTop = maxPercY * height
        
        #console.log "min3d",min3d,"pMin",pMin,"max3d", max3d,"pMax" ,pMax
        #,centerX,centerY
        pos = object.position.clone()
        pos = @projector.projectVector(pos, @camera) #projectedMin
        centerPercX = (pos.x + 1) / 2
        centerPercY = (-pos.y + 1) / 2
        centerLeft = centerPercX * width
        centerTop = centerPercY * height
        
        
        #result = [minLeft, minTop, maxLeft, maxTop, centerLeft,centerTop]
        result = [centerLeft,centerTop,objLength,objWidth,objHeight]
        #console.log "selection positions",result
        return result
        
    isThereObjectAt:(x,y)=>
      v = new THREE.Vector3((x/@viewWidth)*2-1, -(y/@viewHeight)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      raycaster = new THREE.Raycaster(@camera.position, v.sub(@camera.position).normalize())
      intersects = raycaster.intersectObjects(@hiearchyRoot, true )
      
      if intersects.length > 0
        return true
      return false
      
    selectObjectAt:(x,y)=>
      v = new THREE.Vector3((x/@viewWidth)*2-1, -(y/@viewHeight)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      raycaster = new THREE.Raycaster(@camera.position, v.sub(@camera.position).normalize())
      intersects = raycaster.intersectObjects(@hiearchyRoot, true )
      
      if intersects.length > 0
        if intersects[0].object != @currentSelect
          @_unSelect()
          @_onSelect(intersects[0].object)
          return @currentSelect
      else if @currentSelect?
        return @currentSelect
      else
        @_unSelect()
    
    highlightObjectAt:(x,y)=>
      v = new THREE.Vector3((x/@viewWidth)*2-1, -(y/@viewHeight)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      raycaster = new THREE.Raycaster(@camera.position, v.sub(@camera.position).normalize())
      intersects = raycaster.intersectObjects(@hiearchyRoot, true )
      
      if intersects.length > 0
        if intersects[0].object != @currentHover
          if intersects[0].object.name != "workplane"
            @_unHover()
            @_onHover(intersects[0].object)
      else
        @_unHover()
    
   
  captureScreen=(domElement, width=600, height=600)->
    # Save screenshot of 3d view
    if not domElement
      throw new Error("Cannot Do screeshot without canvas domElement")
    #resizing
    srcImg = domElement.toDataURL("image/png")
    #canvas = document.createElement("canvas")
    #canvas.width = width
    #canvas.height = height
    #ctx = canvas.getContext('2d')
    #imgAsDataURL =null
    d = $.Deferred()
    
    _aspectResize = (srcUrl, dstW, dstH) =>
      #taken from THREE.x by Jerome Etienne
      ### 
      resize an image to another resolution while preserving aspect
     
      @param {String} srcUrl the url of the image to resize
      @param {Number} dstWidth the destination width of the image
      @param {Number} dstHeight the destination height of the image
      @param {Number} callback the callback to notify once completed with callback(newImageUrl)
      ###
    
      cpuScaleAspect = (maxW, maxH, curW, curH)->
        ratio = curH / curW
        if( curW >= maxW and ratio <= 1 )
          curW  = maxW
          curH  = maxW * ratio
        else if(curH >= maxH)
          curH  = maxH
          curW  = maxH / ratio
        return { width: curW, height: curH }
    
      onLoad = =>
        canvas  = document.createElement('canvas')
        canvas.width  = dstW
        canvas.height = dstH
        ctx   = canvas.getContext('2d')
  
        #ctx.fillStyle = "black";
        #ctx.fillRect(0, 0, canvas.width, canvas.height);
  
        # scale the image while preserving the aspect
        scaled  = cpuScaleAspect(canvas.width, canvas.height, img.width, img.height)
  
        # actually draw the image on canvas
        offsetX = (canvas.width  - scaled.width )/2
        offsetY = (canvas.height - scaled.height)/2
        ctx.drawImage(img, offsetX, offsetY, scaled.width, scaled.height)
  
        #dump the canvas to an URL    
        mimetype  = "image/png"
        newDataUrl  = canvas.toDataURL(mimetype)
        d.resolve(newDataUrl)
    
    
      img = new Image()
      img.onload = onLoad
      ###.onload = ()=> 
        ctx.drawImage(img, 0,0,width, height)
        imgAsDataURL = canvas.toDataURL("image/png")
        d.resolve(imgAsDataURL)###
      img.src = srcUrl
      
    _aspectResize( srcImg, width, height)
    return d
  
  geometryToline=( geo )->
    # credit to WestLangley!
    geometry = new THREE.Geometry()
    vertices = geometry.vertices;

    for i in [0...geo.faces.length]
      face = geo.faces[i]
      if face instanceof THREE.Face3
        a = geo.vertices[ face.a ].clone()
        b = geo.vertices[ face.b ].clone()
        c = geo.vertices[ face.c ].clone()
        vertices.push( a,b, b,c, c,a )
      else if face instanceof THREE.Face4
        a = geo.vertices[ face.a ].clone()
        b = geo.vertices[ face.b ].clone()
        c = geo.vertices[ face.c ].clone()
        d = geo.vertices[ face.d ].clone()
        vertices.push( a,b, b,c, c,d, d,a )

    geometry.computeLineDistances()
    return geometry
      
  computeVolume=(mesh)->
    geometry = null
    if mesh instanceof THREE.Mesh
      geometry = mesh.geometry
    else if mesh instanceof THREE.Geometry
      geometry = mesh
    else
      throw("Please provide either a mesh or a geometry for volume calculation")
    
    if not (mesh.volume?)
      console.log "Computing Volume"
      volume = 0
      for face in geometry.faces
        if face instanceof THREE.Face4
          #a, b ,c  AND a, c , d
          a = geometry.vertices[face.a]
          b = geometry.vertices[face.b]
          c = geometry.vertices[face.c]
          
          pv1 =  a.x*b.y*c.z  + a.y*b.z*c.x + a.z*b.x*c.y - a.x*b.z*c.y - a.y*b.x*c.z - a.z*b.y*c.x
          
          a = geometry.vertices[face.a]
          b = geometry.vertices[face.c]
          c = geometry.vertices[face.d]
          pv2 =  a.x*b.y*c.z  + a.y*b.z*c.x + a.z*b.x*c.y - a.x*b.z*c.y - a.y*b.x*c.z - a.z*b.y*c.x
          
          volume += (pv1 + pv2)
          
        else if face instanceof THREE.Face3
          #a, b ,c  #PxQyRz + PyQzRx + PzQxRy - PxQzRy - PyQxRz - PzQyRx
          a = geometry.vertices[face.a]
          b = geometry.vertices[face.b]
          c = geometry.vertices[face.c]
          pv =  a.x*b.y*c.z  + a.y*b.z*c.x + a.z*b.x*c.y - a.x*b.z*c.y - a.y*b.x*c.z - a.z*b.y*c.x
          volume += pv
      
      volume = volume/6
      mesh.volume = volume
    else
      volume = mesh.volume
    console.log "volume is: #{volume}"
    return volume
  
  
  toggleHelpers = (rootAssembly)->
    originalStates = {}
    
    _hideHelpers=(child, hide)=>
      if hide?
        if hide 
          originalStates[child]= child.visible
          child.visible = false
      else
        if child.name == "boundingCage" or child.name == "grid" or child.name == "hoverOutline" or child.name =="selectOutline" or child.name =="axes"
          originalStates[child]= child.visible
          child.visible = false
          hide = true
          
      for subchild in child.children
        _hideHelpers(subchild,hide)
          
    if rootAssembly?
      for child in rootAssembly.children  
        _hideHelpers(child)
    return originalStates
   
  enableHelpers = (rootAssembly, originalStates)->
    _enableHelpers=(child)=>
      if child of originalStates
        child.visible = originalStates[child]
        for subchild in child.children
          _enableHelpers(subchild)
      
    if rootAssembly?
      for child in rootAssembly.children  
        _enableHelpers(child)
  
  updateVisuals=(rootAssembly, settings)->
      console.log "applying visual style to #{rootAssembly}"
      
      removeRenderHelpers=(child)=>
        if child.renderSubElementsHelper?
          child.remove(child.renderSubElementsHelper)
          child.renderSubElementsHelper = null
      
      applyStyle=(child)=>
        child.castShadow =  settings.shadows
        child.receiveShadow = settings.selfShadows and settings.shadows
        
        #hack
        if child.material?
          child.material.vertexColors= THREE.VertexColors
        
        switch settings.objectViewMode
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
              obj3 = new THREE.Line( geometryToline(geom.clone()), dashMaterial, THREE.LinePieces )
              obj4 = new THREE.Mesh( geom.clone(), wireFrameMaterial)
      
              renderSubElementsHelper.add(obj2)
              renderSubElementsHelper.add(obj3)
              renderSubElementsHelper.add(obj4)
              child.add(renderSubElementsHelper)
              child.renderSubElementsHelper = renderSubElementsHelper
              
        for subchild in child.children
          if subchild.name != "renderSubs" and subchild.name !="connectors"
            applyStyle(subchild)
          
      if rootAssembly?
        for child in rootAssembly.children  
          applyStyle(child)
      

  return {"LabeledAxes":LabeledAxes, "Arrow":Arrow, "Grid":Grid, "BoundingCage":BoundingCage, "SelectionHelper":SelectionHelper, "captureScreen":captureScreen, "geometryToline":geometryToline, "toggleHelpers":toggleHelpers, "enableHelpers":enableHelpers, "updateVisuals":updateVisuals}
