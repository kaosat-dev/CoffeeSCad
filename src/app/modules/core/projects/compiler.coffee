define (require)->
  utils = require 'modules/core/utils/utils'
  merge = utils.merge
  
  PreProcessor = require "./preprocessor"
  CsgProcessor = require "./csg/processor"
  
  class Compiler
    
    constructor:(options)->
      defaults = {project:null, backgroundProcessing:false}
      options = merge defaults, options
      {@project, @backgroundProcessing} = options
      
      @preProcessor = new PreProcessor()
      @csgProcessor = new CsgProcessor()
    
    compile:(options)=>
      defaults = {backgroundProcessing:false}
      options = merge defaults, options
      {@backgroundProcessing} = options
      
      @deferred = $.Deferred()
      
      if @project is null
        error = new Error("No project given to the compiler")
        @deferred.reject(error)
        throw error
        return
        
      console.log "compiling"
      @_compileStartTime = new Date().getTime()
      try
        @preProcessor.process(@project,false).pipe(@_processScript)
      catch error
        @deferred.reject("compile:error",[error])
        @project.trigger("compile:error",[error])
        
      return @deferred.promise()
      
    _processScript:(source)=>
      @csgProcessor.processScript source,@backgroundProcessing, (rootAssembly, partRegistry, error)=>
        if error?
          @deferred.reject("compile:error",[error])
          @project.trigger("compile:error",[error])
        
        @_generateBomEntries(rootAssembly, partRegistry)
        @project.rootAssembly = rootAssembly
        
        @_compileEndTime = new Date().getTime()
        console.log "Csg computation time: #{@_compileEndTime-@_compileStartTime}"
        
        @project.trigger("compiled",rootAssembly)
        @deferred.resolve(rootAssembly)
      
    _generateBomEntries:(rootAssembly, partRegistry)=>
      availableParts = new Backbone.Collection()
      for name,params of partRegistry
          for param, quantity of params
            variantName = "Default"
            if param != ""
              variantName=""
            @project.bom.add { name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true } 
      
      partInstances = new Backbone.Collection()
      
      parts = {}
      
      getChildrenData=(assembly) =>
        for index, part of assembly.children
          #TODO: make recursive
          partClassName = part.__proto__.constructor.name
          params = Object.keys(partRegistry[partClassName])[0]
          #params = partRegistry[partClassName][index]
          variantName = "Default"
          if params != ""
            variantName=""
          
          if not (partClassName of parts)
            parts[partClassName] = {}
            parts[partClassName][params] = 0
          parts[partClassName][params] += 1
          getChildrenData(part)
          
      getChildrenData(rootAssembly)
        
      for name,params of parts
        for param, quantity of params
          partInstances.add({ name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true })
        
      @project.bom = partInstances
      
      
  return  Compiler