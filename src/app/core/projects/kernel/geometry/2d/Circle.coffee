define (require) ->
  #ObjectBase = require '../base'
  
  
  class Circle #extends ObjectBase
    # Construct a 2D Circle
    #
    # Parameters:
    #   center: center of sphere (default [0,0,0])
    #   radius: radius of sphere (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    # 
    constructor:(options)->
      options = options or {}
      defaults = { r:1, center:[0,0,0] , $fn:1 }
      
      circleRadius = options.r or 1
      $fn = options.$fn or $fn

      shape = new THREE.Shape()
      ### 
      shape.moveTo( 0, circleRadius )
      shape.quadraticCurveTo( circleRadius, circleRadius, circleRadius, 0 )
      shape.quadraticCurveTo( circleRadius, -circleRadius, 0, -circleRadius )
      shape.quadraticCurveTo( -circleRadius, -circleRadius, -circleRadius, 0 )
      shape.quadraticCurveTo( -circleRadius, circleRadius, 0, circleRadius )
      ###
      
      shape.absarc( 0, 0, circleRadius, 0, Math.PI+0.1, false )
      
      points = shape.createPointsGeometry()
      spacedPoints = shape.createSpacedPointsGeometry( 100 )
      #geometry = new THREE.ShapeGeometry( shape )
      
      #super( geometry )

  return Circle