define (require)->
  _DEBUG = false
  defaultResolution2D = 32
  defaultResolution3D = 12
  all = 0
  top = 1
  bottom = 2
  left = 3
  right = 4
  front = 5
  back = 6
  
  return {
    "_DEBUG": _DEBUG
    "defaultResolution2D":defaultResolution2D
    "defaultResolution3D":defaultResolution3D
    "all",all
    "top":top
    "bottom":bottom
    "left":left
    "right":right
    "front":front
    "back":back
  }