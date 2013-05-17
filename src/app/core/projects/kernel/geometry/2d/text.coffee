define (require) ->
  #ObjectBase = require '../base'
  
  
  class Text extends ObjectBase
    # Construct a 2D text (extrudeable)
    # Parameters:
    #   size: size of text (default 10)
    #   font: font of text (default "helvetiker")
    #   $fn: corner resolution
    #  
    constructor:(options)->
      options = options or {}
      defaults = { text: "Hello coffee!", size:10, divisions:10, font:"helvetiker" }
      
      textShapes = THREE.FontUtils.generateShapes(theText,{size:10, divisions : 10, font:"helvetiker"})
      ### 
      text3d = new THREE.ExtrudeGeometry( textShapes, extrudeSettings )
      text3d.computeBoundingBox()
      text3d.computeVertexNormals()
      ###