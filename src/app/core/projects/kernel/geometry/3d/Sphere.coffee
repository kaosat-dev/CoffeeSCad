define (require) ->
  ObjectBase = require '../base'
  Constants = require '../constants'
  
  class Sphere extends ObjectBase
    # Construct a solid sphere
    #
    # Parameters:
    #   center: center of sphere (default [0,0,0])
    #   radius: radius of sphere (default 1), must be a scalar
    #   resolution: determines the number of polygons per 360 degree revolution (default 12)
    #   axes: (optional) an array with 3 vectors for the x, y and z base vectors
    #   icosa: (optional): if true, the sphere will actually be an icosahedron (default true)
    # 
    constructor:(options)->
      options = options or {}
      defaults = { r:1, center:[0,0,0] , $fn:Constants.defaultResolution3D, icosa:true }
      
      r = options.r or 1
      $fn = options.$fn or $fn
      icosa = options.icosa or true
      console.log "r", r , "$fn", $fn, "ico", icosa
      
      if icosa
        geometry = new THREE.SphereGeometry( r, $fn, $fn )
      else
        geometry = new THREE.IcosahedronGeometry( r, $fn )
        
      super( geometry )

  return Sphere