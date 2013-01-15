define (require) ->
  utils = require "modules/core/utils/utils"
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  Project = require 'modules/core/projects/project'
  ModalRegion = require 'modules/core/utils/modalRegion' 
  
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
      reqRes.addHandler "bomExportBlobUrl", ()=>
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
      modReg = new ModalRegion({elName:"exporter"})
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
        data = []
        blob = new Blob(data, {type: @mimeType})
      catch error
        console.log "Failed to generate bom blob data: #{error}"
      
      windowURL=utils.getWindowURL()
      outputFileBlobUrl = windowURL.createObjectURL(blob)
      if not outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      return outputFileBlobUrl   
      
  return BomExporter
 
  