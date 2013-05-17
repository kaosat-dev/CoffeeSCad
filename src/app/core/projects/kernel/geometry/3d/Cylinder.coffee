define (require) ->
  ObjectBase = require '../base'
  
  
  class Cylinder extends ObjectBase
    # Construct a solid cylinder.
    #
    # Parameters:
    #   start: start point of cylinder (default [0, -1, 0])
    #   end: end point of cylinder (default [0, 1, 0])
    #   radius: radius of cylinder (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    # 
    # Example usage:
    # 
    #     cylinder = new Cylinder({
    #       start: [0, -1, 0],
    #       end: [0, 1, 0],
    #       radius: 1,
    #       resolution: 16,
    #       center: true
    #     });
    constructor:(options)->
      options = options or {}
      if ("r" of options or "r1" of options) then hasRadius = true
      defaults = {h:1,center:[0,0,0],r:1,d:2,$fn:CSGBase.defaultResolution3D,rounded:false}
      
      radiusTop = r1
      radiusBottom = r2 
      height = h 
      heightSegments = 2
      
      geometry = new THREE.CylinderGeometry(radiusTop, radiusBottom, height, $fn, heightSegments)
      
      super(geometry)
  
  
