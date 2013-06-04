define (require) ->
  reqRes = require 'core/messaging/appReqRes'
  utils = require "core/utils/utils"
  CoffeeScript = require 'CoffeeScript'
  geometryKernel = require './geometry/api'

   
  class Processor
    #processes a csg script
    construtor:()->
      @async = false
      @debug = false
      
    processScript:(script, async=false, params, callback)-> 
      @script = script
      @async = async
      @params = params      
      @callback = callback
      @rebuildSolid()
      
    rebuildSolid:() =>
      @processing = true
      try
        @_prepareScriptSync()
        @parseScriptSync(@script, @params)
        @processing = false
      catch error
        #correct the line number to account for all the pre-injected code
        if error.location?
          if @async
            lineOffset = -11
          else
            lineOffset = -15
          error.location.first_line = (error.location.first_line + lineOffset)
      
        #console.log "raw error", error
        #console.log error.stack
        #trace = printStackTrace({e: error})
        #console.log trace
        @callback(null,null,null, error)
        @processing = false
   
    _prepareScriptSync:()=>
      #prepare the source for compiling : convert to coffeescript, inject dependencies etc
      @script = """
      {ObjectBase, Cube, Sphere, Cylinder, Circle, Rectangle, Text}=geometryKernel

      assembly = new THREE.Object3D()
      

      #clear log entries
      log = {}
      log.entries = []
      #clear rootAssembly
      #rootAssembly.clear()
      
      classRegistry = {}
      
      #include script
      #{@script}
      
      rootAssembly = assembly
      
      #return results as an object for cleaness
      return result = {"rootAssembly":rootAssembly,"partRegistry":classRegistry, "logEntries":log.entries}
      
      """
      @script = CoffeeScript.compile(@script, {bare: true})
      #console.log "JSIFIED script"
      #console.log @script
    
    
    parseScriptSync: (script, params) -> 
      #Parse the given coffeescad script in the UI thread (blocking but simple)
      workerscript = script
      if @debug
        workerscript += "//Debugging;\n"
        workerscript += "debugger;\n"
      
      ### 
      partRegistry = {}
      logEntries = []
      
      f = new Function("partRegistry", "logEntries","csg", "params", workerscript)
      result = f(partRegistry,logEntries, csg, params)
      {rootAssembly,partRegistry,logEntries} = result
      console.log "RootAssembly", rootAssembly
      @_convertResultsTo3dSolid(rootAssembly)
      ###
      rootAssembly = new THREE.Object3D()
      f = new Function("geometryKernel", workerscript)
      result = f(geometryKernel)
      {rootAssembly,partRegistry,logEntries} = result
      
      console.log "compile result", result
      @callback(rootAssembly,partRegistry,logEntries)
    
  return Processor