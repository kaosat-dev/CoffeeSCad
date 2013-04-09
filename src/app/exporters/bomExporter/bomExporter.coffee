define (require) ->
  utils = require "core/utils/utils"
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  ModalRegion = require 'core/utils/modalRegion' 
  
  BomExporterView = require './bomExporterView'
  
  
  class BomExporter extends Backbone.Marionette.Application
    ###
    exports the given projects' bom (BILL of material) as a json file
    ###
    constructor:(options)->
      super options
      @mimeType = "application/sla"
      @on("start", @onStart)
    
    start:(options)=>
      @project= options.project ? new Project()
      reqRes.addHandler "bomExportUrl", ()=>
        try
          blobUrl = @export(@project)
          return blobUrl
        catch error
          return null
      
      @trigger("initialize:before", options)
      @initCallbacks.run(options, this)
      @trigger("initialize:after", options)
      @trigger("start", options)
    
    onStart:()=>
      bomExporterView = new BomExporterView
        model: @project  
      modReg = new ModalRegion({elName:"exporter",large:true})
      modReg.on("closed", @stop)
      modReg.show bomExporterView
    
    stop:->
      console.log "closing bom exporter"
      #taken from marionette module
      # if we are not initialized, don't bother finalizing
      return  unless @_isInitialized
      @_isInitialized = false
      Marionette.triggerMethod.call this, "before:stop"
      
      # stop the sub-modules; depth-first, to make sure the
      # sub-modules are stopped / finalized before parents
      _.each @submodules, (mod) ->
        mod.stop()
      
      # run the finalizers
      @_finalizerCallbacks.run()
      
      # reset the initializers and finalizers
      @_initializerCallbacks.reset()
      @_finalizerCallbacks.reset()
      Marionette.triggerMethod.call this, "stop"
      
    export:(project)=>
      try
        jsonResult = project.bom.toJSON()
        jsonResult = encodeURIComponent(JSON.stringify(jsonResult))
      catch error
        console.log "Failed to generate bom data url: #{error}"
      
      exportUrl = "data:text/json;charset=utf-8," + jsonResult
      if not exportUrl then throw new Error("createing object url failed") 
      return exportUrl   
      
  return BomExporter
 
  