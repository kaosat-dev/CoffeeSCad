define (require)->
  base = require './csgBase' 
  CSGBase = base.CSGBase
  CAGBase = base.CAGBase
  
  shapes3d = require './geometry3d'
  shapes2d = require './geometry2d' 
  
  Cube = shapes3d.Cube
  Sphere = shapes3d.Sphere
  Cylinder= shapes3d.Cylinder
  Rectangle = shapes2d.Rectangle
  Circle = shapes2d.Circle
  
  maths = require './maths'
  Plane = maths.Plane
  
  extras = require './extras'
  properties = require './properties'
  
  ##Additional helpers
  classRegistry = {}
  otherRegistry = {}
  
  register=(classname, klass, params)=>
    ###Registers a class (instance) based on its name,  
    and params (different params need to show up as different object in the bom for examples)
    ### 
    
    #console.log arg for arg in arguments
    #console.log "registering " + classname
    #TODO: generate hash
    if not params?
      compressedParams=""
    else
      compressedParams =  JSON.stringify(params) 
    #console.log "Params #{compressedParams}"
    
    if not (classname of classRegistry)
      classRegistry[classname] = {}
      #classRegistry[classname] = 0
      otherRegistry[classname]= {}
    if not (compressedParams of classRegistry[classname])
      classRegistry[classname][compressedParams] = 0
        
    #classRegistry[classname] += 1
    classRegistry[classname][compressedParams] += 1
    otherRegistry[classname] =  klass  
  
  #FROM COFFEESCRIPT HELPERS
  merge = (options, overrides) ->
    extend (extend {}, options), overrides

  extend = (object, properties) ->
    for key, val of properties
      object[key] = val
    object
  
  class Part extends CSGBase
    constructor:(options)->
      super options
      parent= @__proto__.__proto__.constructor.name
      register(@__proto__.constructor.name, @, options)
      
      defaults = {manufactured:true}
      options = merge defaults, options
      @manufactured = options.manufactured

  additional = {
    "Part":Part,
    "register":register,
    "classRegistry":classRegistry,
    "otherRegistry":otherRegistry
  }
  
  exports = merge(shapes2d,shapes3d)
  exports = merge(exports,base)
  exports = merge(exports,maths)
  exports = merge(exports,extras)
  exports = merge(exports,properties)
  exports = merge(exports,additional)
  
  return exports