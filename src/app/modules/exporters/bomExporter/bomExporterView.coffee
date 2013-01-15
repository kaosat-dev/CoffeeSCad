define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
  bomExporterTemplate =  require "text!./bomExporter.tmpl"
  BomPartListView = require './bomPartsView'
  
  class BomExporterView extends Backbone.Marionette.Layout
    template: bomExporterTemplate
    regions:
      partsList: "#partsList"
    
    ui:
      exportButton: "#bomExportBtn"
      fileNameinput: "#fileNameinput"
      
    events:
      "click .exportBom":   "onExport"   
      
    constructor:(options)->
      super options
      @vent = vent
      @vent.on("project:new",     ()->@ui.exportButton.addClass "disabled") 
      @vent.on("project:compiled",()->@ui.exportButton.removeClass "disabled")
    
    onExport:->
      vent.trigger("export:bom")
      exportBlobUrl = reqRes.request("bomExportBlobUrl")
      if exportBlobUrl != null
        fileName = @model.get("name")
        @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}.json")
        @ui.exportButton.prop("href", exportBlobUrl)
        
    onRender:->
      if @model.get("compiled")
          @ui.exportButton.removeClass "disabled"
      
      console.log @model.get("partRegistry")
      #hack
      partsCollection = null
      if @model.get("partRegistry")?
        partsCollection = new Backbone.Collection()
        for name,params of @model.get("partRegistry")
          for param, number of params
            console.log "name #{name}, number:#{number} "
            console.log param
            partsCollection.add { name: name, params: param,number: number }
        
        
      console.log @model.get("partRegistry")   
      console.log partsCollection
      @partsList.show new BomPartListView
        collection:partsCollection
       
      
          
    #serializeData: ()->
    #  null
        
  return BomExporterView