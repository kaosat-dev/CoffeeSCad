define (require) ->
  THREE = require 'three'
  utils = require 'modules/core/utils/utils'
  merge = utils.merge
  
  
  class BaseHelper extends THREE.Object3D
    constructor:(options)->
      super options
      
    drawText:(text)=>
      canvas = document.createElement('canvas')
      size = 256
      canvas.width = size
      canvas.height = size
      context = canvas.getContext('2d')
      context.font = "17px sans-serif"
      context.textAlign = 'center'
      context.fillStyle = @textColor
      context.fillText(text, canvas.width/2, canvas.height/2)
     
      context.strokeStyle = @textColor
      context.strokeText(text, canvas.width/2, canvas.height/2)
      
      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      
      spriteMaterial = new THREE.SpriteMaterial
         map: texture
         transparent:true
         #alphaTest: 0.5
         #alignment: THREE.SpriteAlignment.topLeft,
         useScreenCoordinates: false
         scaleByViewport:false
         color: 0xffffff
      sprite = new THREE.Sprite(spriteMaterial)
      sprite.scale.set( size, size, 1 )
      return sprite
      
    drawText2:(text)=>
      helpersColor = @settings.get("helpersColor")
      if helpersColor.indexOf "0x" == 0
        helpersColor= "#"+helpersColor[2..]
      
      canvas = document.createElement('canvas')
      
      context = canvas.getContext('2d')
      context.font = "17px sans-serif"
      context.fillStyle = helpersColor
      context.fillText(text, 0, 10);
      context.strokeStyle = '#FFFFFF'
      context.strokeText(text, 0, 10)
      
      texture = new THREE.Texture(canvas)
      texture.needsUpdate = true
      return texture
  
  class LabeledAxes extends BaseHelper
    constructor:(options)->
      super options
      defaults = {size:50, xColor:"0xFF7700",yColor:0x77FF00,zColor:0x0077FF,textColor:"#FFFFFF",addLabels:true, addArrows:true}
      options = merge defaults, options
      {@size, @xColor, @yColor, @zColor, @textColor, addLabels, addArrows} = options

      @xColor = new THREE.Color().setHex(@xColor)
      @yColor = new THREE.Color().setHex(@yColor)
      @zColor = new THREE.Color().setHex(@zColor)

      if addLabels
        @xLabel=@drawText("X")
        @xLabel.position.set(@size+5,0,0)
        
        @yLabel=@drawText("Y")
        @yLabel.position.set(0,@size+5,0)
        
        @zLabel=@drawText("Z")
        @zLabel.position.set(0,0,@size+5)
        
      if addArrows
        @xArrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(0,0,0),@size, @xColor)
        @yArrow = new THREE.ArrowHelper(new THREE.Vector3(0,1,0),new THREE.Vector3(0,0,0),@size, @yColor)
        @zArrow = new THREE.ArrowHelper(new THREE.Vector3(0,0,1),new THREE.Vector3(0,0,0),@size, @zColor)
        @add @xArrow
        @add @yArrow
        @add @zArrow
      else
        @_buildAxes()
        
      @add @xLabel
      @add @yLabel 
      @add @zLabel
    
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
      
      defaults = {size:1000, step:100, color:0xFFFFFF, opacity:0.1}
      options = merge defaults, options
      {@size, @step, @color, @opacity} = options
      
      gridGeometry = new THREE.Geometry()
      gridMaterial = new THREE.LineBasicMaterial
        color: new THREE.Color().setHex(@color)
        opacity: @opacity
        linewidth:2
        transparent:true
      
      for i in [-@size/2..@size/2] by @step
        gridGeometry.vertices.push(new THREE.Vector3(-@size/2, i, 0))
        gridGeometry.vertices.push(new THREE.Vector3(@size/2, i, 0))
        
        gridGeometry.vertices.push(new THREE.Vector3(i, -@size/2, 0))
        gridGeometry.vertices.push(new THREE.Vector3(i, @size/2, 0))
        
      @mainGrid = new THREE.Line(gridGeometry, gridMaterial, THREE.LinePieces)
      
      
      subGridGeometry = new THREE.Geometry()
      subGridMaterial = new THREE.LineBasicMaterial({ color: new THREE.Color().setHex(@color), opacity: @opacity/2 ,transparent:true})
      
      for i in [-@size/2..@size/2] by @step/10
        subGridGeometry.vertices.push(new THREE.Vector3(-@size/2, i, 0))
        subGridGeometry.vertices.push(new THREE.Vector3(@size/2, i, 0))
        
        subGridGeometry.vertices.push(new THREE.Vector3(i, -@size/2, 0))
        subGridGeometry.vertices.push(new THREE.Vector3(i, @size/2, 0))
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
      @plane.position.z = -2
      @plane.name = "workplane"
      @plane.receiveShadow = true
      
      @add @mainGrid
      @add @subGrid
      @add @plane
     
     setOpacity:(opacity)=>
       @opacity = opacity
       @mainGrid.material.opacity = opacity
       @subGrid.material.opacity = opacity
       
     setColor:(color)=>
       @color = color 
       @mainGrid.material.color = new THREE.Color().setHex(@color)
       @subGrid.material.color = new THREE.Color().setHex(@color)
      
      
  class BoundingCage extends BaseHelper
    #Draws a bounding box (wireframe) around a mesh, and shows its dimentions
    constructor:(options)->
      super options
      defaults = {mesh:null,color:0xFFFFFF,textColor:"#FFFFFF",addLabels:true}
      options = merge defaults, options
      {mesh, @color, @textColor,@addLabels} = options
      console.log @size, @step, @color, @opacity
      
      color = new THREE.Color().setHex(@color)
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
          color: color
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
        
        if @addLabels
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

  return {"LabeledAxes":LabeledAxes, "Grid":Grid, "BoundingCage":BoundingCage}
