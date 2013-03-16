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
      
      if @project is null
        throw new Error("No project given to the compiler")
        
      console.log "compiling"
      console.log @project
      start = new Date().getTime()
      
      
      try
        @preProcessor.process(@project,false).done( (fullSource) =>
          @csgProcessor.processScript fullSource,@backgroundProcessing, (rootAssembly, partRegistry, error)=>
            if error?
              @project.trigger("compile:error",[error])
              return
            @project.bom = new Backbone.Collection()
            for name,params of partRegistry
              for param, quantity of params
                variantName = "Default"
                if param != ""
                  variantName=""
                @project.bom.add { name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true } 
            
            @project.rootAssembly = rootAssembly
            end = new Date().getTime()
            console.log "Csg computation time: #{end-start}"
            @project.trigger("compiled",rootAssembly)
        )
        #fullSource = @preProcessor.process(@project,false)
      catch error
        @project.trigger("compile:error",[error])
        return
        
      

  return  Compiler