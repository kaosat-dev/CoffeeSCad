define (require) ->
  ObjectBase = require '../base'
  utils = require '../utils'
  
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
      
      size = utils.parseOptionAs3DVector(options, "size", defaults["size"])
      center = utils.parseCenter(options,"center",size.divideScalar(2),defaults["center"], THREE.Vector3)
      
      console.log "size", size, "center",center
      #do params validation
      throw new Error("Cube size should be non-negative") if size.x <0 or size.y <0 or size.z <0
      
      geometry = new THREE.CubeGeometry( size.x, size.y, size.z )
      #TODO: handle center
      super( geometry )
  
  return Cube
