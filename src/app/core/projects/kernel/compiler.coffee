define (require)->
  utils = require 'core/utils/utils'
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
      
      #this data structure is filled with log & error data 
      @compileResultData = {}
      @compileResultData["logEntries"] = null
      @compileResultData["errors"] = null
    
    compile:(options)=>
      defaults = {backgroundProcessing:false}
      options = merge defaults, options
      {@backgroundProcessing} = options
      
      @compileResultData["logEntries"] = []
      @compileResultData["errors"] = []
      
      console.log "compiling"
      @_compileStartTime = new Date().getTime()
      
      return @preProcessor.process(@project,false).pipe(@_processScript)
        .done () =>
          @project.trigger("compiled",@compileResultData)
          #TODO : should this be merged into the event above?
          #@project.trigger(log:messages
          #@project.trigger("log:messages",logEntries)
          return
        .fail (errors) =>
          if errors not instanceof Array
            errors = [errors]
          @compileResultData["errors"] = errors
          @project.trigger("compile:error",@compileResultData)
      
    _processScript:(source)=>
      deferred = $.Deferred()
      
      if @project is null
        error = new Error("No project given to the compiler")
        deferred.reject(error)
      
      params = @project.meta.params
      @csgProcessor.processScript source,@backgroundProcessing,params, (rootAssembly, partRegistry, logEntries, error)=>
        @compileResultData["logEntries"] = logEntries or []
        if error?
          deferred.reject([error])
        else          
          #@_parseLogEntries(logEntries)
          @_generateBomEntries(rootAssembly, partRegistry)
          @project.rootAssembly = rootAssembly
          
          @_compileEndTime = new Date().getTime()
          console.log "Csg computation time: #{@_compileEndTime-@_compileStartTime}"
          deferred.resolve()
      return deferred
    
    _parseLogEntries:(logEntries)=>
      result = []
      return result
      
    _generateBomEntries:(rootAssembly, partRegistry)=>
      #TODO : clean this up
      partInstances = new Backbone.Collection()
      parts = {}
      
      getChildrenData=(assembly) =>
        for index, part of assembly.children
          if part.realClassName? #necessary workaround for "fake" classes (all of the parts are actually CSGBase instance) returned from web workers
            partClassName = part.realClassName
          else
            partClassName = part.__proto__.constructor.name
          if partClassName of partRegistry
            partClassEntry = partRegistry[partClassName]
            isInAssembly = false
            params = ""
            for params,index of partClassEntry
              if part.uid in partClassEntry[params].uids
                isInAssembly =true
                partIndex = index
                break
            if isInAssembly
              if not (partClassName of parts)
                parts[partClassName] = {}
              if not (params of parts[partClassName])
                 parts[partClassName][params]= 0
              parts[partClassName][params] += 1
            
          getChildrenData(part)
          
      getChildrenData(rootAssembly)
        
      for name,params of parts
        for param, quantity of params
          variantName = "Default"
          if param != ""
            variantName=""
          partInstances.add({ name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true })
        
      @project.bom = partInstances
      
      
  return  Compiler