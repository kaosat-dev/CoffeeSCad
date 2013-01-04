define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  shapes = require './csg.geometry' 
  CSGBase= require './csg' 
  #Cube = shapes.Cube
  #Sphere = shapes.Sphere
  Cylinder=shapes.Cylinder
  
  Cube = shapes.oldCube
  Sphere= shapes.oldSphere
  
  try
    #FIXME: bunch of hacks, needs cleanup
    window.CSGBase = CSGBase
    window.Cube = Cube
    window.Sphere = Sphere
    window.Cylinder = Cylinder
    
    window.CSG={}
  
    window.classRegistry={}
    window.otherRegistry={}
    #classRegistry= {}
    
    register=(classname,klass)=>
      #console.log "registering " + classname
      if not (classname of classRegistry)
        window.classRegistry[classname] = 0
        window.otherRegistry[classname]={}
          
      window.classRegistry[classname]+=1
      window.otherRegistry[classname] =  klass  
      
    
    doMagic=()=>
      for i,v of window.otherRegistry
        #console.log "i #{i}, v #{v}"
        console.log i
        klass= v
        #console.log "klassString"
        #console.log klass
        #console.log JSON.stringify klass
    
    class Meta extends CSGBase
      constructor:(options)->
        super options
        parent= @__proto__.__proto__.constructor.name
        #console.log "Parent:"+parent
        register(@__proto__.constructor.name, @)
    
    class Screw extends Meta
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
    window.Meta = Meta
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
