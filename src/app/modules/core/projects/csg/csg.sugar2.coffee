define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  
  base = require './csg' 
  CSGBase = base.CSGBase
  CAGBase = base.CAGBase
  
  shapes3d = require './csg.geometry'
  shapes2d = require './cag.geometry' 
  
  Cube = shapes3d.Cube
  Sphere = shapes3d.Sphere
  Cylinder= shapes3d.Cylinder
  Rectangle = shapes2d.Rectangle
  Circle = shapes2d.Circle
  
  extras = require './extras'
  quickHull2d = extras.quickHull2d
  
  try
    #FIXME: bunch of hacks, needs cleanup
    window.CSGBase = CSGBase
    window.CAGBase = CAGBase
    window.Cube = Cube
    window.Sphere = Sphere
    window.Cylinder = Cylinder
    window.Rectangle = Rectangle
    window.Circle = Circle
    
    window.quickHull2d = quickHull2d
    
    window.CSG={}
  
    window.classRegistry={}
    window.otherRegistry={}
    
    
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
      console.log "Params #{compressedParams}"
      
      if not (classname of classRegistry)
        window.classRegistry[classname] = {}
        #window.classRegistry[classname] = 0
        window.otherRegistry[classname]= {}
      if not (compressedParams of classRegistry[classname])
        window.classRegistry[classname][compressedParams] = 0
          
      #window.classRegistry[classname] += 1
      window.classRegistry[classname][compressedParams] += 1
      window.otherRegistry[classname] =  klass  
      
    
    doMagic=()=>
      for i,v of window.otherRegistry
        #console.log "i #{i}, v #{v}"
        console.log i
        klass= v
        #console.log "klassString"
        #console.log klass
        #console.log JSON.stringify klass
    
    #FROM COFFEESCRIPT HELPERS
    merge = (options, overrides) ->
      extend (extend {}, options), overrides

    extend = (object, properties) ->
      for key, val of properties
        object[key] = val
      object
    
    window.merge = merge
    window.extend = extend
    
    class Part extends CSGBase
      constructor:(options)->
        super options
        parent= @__proto__.__proto__.constructor.name
        #console.log "Parent:"+parent
        register(@__proto__.constructor.name, @, options)
    
    class Screw extends Part
       constructor:(options)->
        super options
        c = new Cube
          radius:[50,50,100]
        @unionSelf c
        
    class SpecialScrew extends Screw
      constructor:(options)->
        super options
        head = new Cube
          radius:[75,75,10]
        @unionSelf head#head.translate [0,0,100]
        
    window.classRegistry = classRegistry
    window.Part = Part
    window.Screw = Screw
    window.SpecialScrew= SpecialScrew
    
    window.register=register
    window.doMagic=doMagic
    # class ReallySpecialScrew extends SpecialScrew
    #   constructor:(options)->
    #     super options

  catch error
    console.log "ERROR"+error
  csgSugar = ""
  csgSugar += """typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
  \n"""
  csgSugar += """Cube=(options)=> 
    if "size" of options
      if typeIsArray options.size
        options.radius = options.size.map (comp) -> comp/2
      else
        options.radius = options.size
    if "$fn" of options
      options.resolution = options.$fn
    if "r" of options
      options.roundradius = options.r
    if "d" of options
      options.roundradius = options.d/2
    if "center" of options
      if options.center == true
        options.center= [0,0,0]
    if not result?
        result = Cube options
    return result
  \n"""
  csgSugar = ""
  return csgSugar
