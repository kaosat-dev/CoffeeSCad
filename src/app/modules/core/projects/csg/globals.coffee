define (require)->
  _CSGDEBUG = false
  defaultResolution2D = 32
  defaultResolution3D = 12
  staticTag = 1
  getTag =  () ->
    return staticTag++
  
  return {
    "_CSGDEBUG": _CSGDEBUG
    "defaultResolution2D":defaultResolution2D
    "defaultResolution3D":defaultResolution3D
    "staticTag": staticTag
    "getTag": getTag
  }