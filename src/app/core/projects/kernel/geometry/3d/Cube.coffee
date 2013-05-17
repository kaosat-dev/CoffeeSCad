define (require) ->
  ObjectBase = require '../base'
  
  
  class Cube extends ObjectBase
    # Construct a solid cuboid. with optional corner roundings (making it, you guessed it, a rounded cube)
    # Parameters:
    #   center: center of cube (default [0,0,0])
    #   size: size of cube (default [1,1,1]), can be specified as scalar or as 3D vector
    #   r: radius of corners
    #   $fn: corner resolution
    #  
    # Example code:
    #     cube = new Cube({
    #       center: [0, 0, 0],
    #       radius: 1
    #     })
    constructor:(options)->
      options = options or {}
      defaults = {size:[1,1,1],center:[0,0,0],r:0,$fn:0}
      
      size = options.size or [1,1,1]
      geometry = new THREE.CubeGeometry( size[0], size[1], size[2] )
      super( geometry )
  
  return Cube
