define (require)->
  _CSGDEBUG = false
  staticTag = 1
  getTag =  () ->
    return staticTag++
  
  return {
    "_CSGDEBUG": _CSGDEBUG
    "CSG":
      "staticTag": staticTag
      "getTag": getTag
  }