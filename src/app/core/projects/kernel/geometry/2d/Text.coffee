define (require) ->
  ObjectBase = require '../base'
  
  utils = require '../utils'
  merge = utils.merge
  
  class Text
    # Construct a 2D text (extrudeable)
    # Parameters:
    #   size: size of text (default 10)
    #   font: font of text (default "helvetiker")
    #   $fn: corner resolution
    #  
    constructor:(options)->
      options = options or {}
      defaults = { text: "Hello coffee!", size:10, divisions:10, font:"helvetiker" }
      options = merge(defaults, options)
      
      @textShapes = THREE.FontUtils.generateShapes(options.text,options)
      ###      hash = document.location.hash.substr( 1 )
      if ( hash.length != 0 )
        theText = hash###
      
    extrude:(options)->
      #TODO: move to higher level class
      defaults = { amount: 5,  bevelEnabled: false, bevelSegments: 2, steps: 2 }
      options = merge(defaults, options)
      
      text3d = new THREE.ExtrudeGeometry( @textShapes, options )
      text3d.computeBoundingBox()
      text3d.computeVertexNormals()
      
      textMaterial = new THREE.MeshBasicMaterial( { color: Math.random() * 0xffffff})
      
      text3d = new ObjectBase( text3d, textMaterial )
      return text3d 
       
  return Text