define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  require './csg.geometry' 
  
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
        result = CSG.cube options
    return result
  \n"""
  
  return csgSugar
