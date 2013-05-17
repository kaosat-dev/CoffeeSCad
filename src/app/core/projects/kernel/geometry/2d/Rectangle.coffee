define (require) ->
  ObjectBase = require '../base'
  
  
  class Rectangle extends ObjectBase
    # Construct a 2D Rectangle
    #
    # Parameters:
    #   center: center of rectangle (default [0,0,0])
    #   size : 2D vector or scalar
    # 
    constructor:(options)->
      options = options or {}
      defaults = { size:[1,1], center:[0,0,0] , $fn:1 }
      
      size = options.size or defaults.size

      shape = new THREE.Shape()

      shape = new THREE.Shape()
      shape.moveTo( 0,0 )
      shape.lineTo( 0, size[0] )
      shape.lineTo( size[1], size[0] )
      shape.lineTo( size[1], 0 )
      shape.lineTo( 0, 0 )
    
      points = shape.createPointsGeometry()
      spacedPoints = shape.createSpacedPointsGeometry( 100 )
      geometry = new THREE.ShapeGeometry( shape )
      
      super( geometry )

  return Rectangle
        