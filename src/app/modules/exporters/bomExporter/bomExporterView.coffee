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
      exportUrl = reqRes.request("bomExportUrl")
      
      if exportUrl != null
        fileName = @model.get("name")
        @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}")
        @ui.exportButton.prop("href", exportUrl)
        
    onRender:->
      if @model.get("compiled")
          @ui.exportButton.removeClass "disabled"
          
      @partsList.show new BomPartListView
        collection:@model.get("partsCollection")
          
    #serializeData: ()->
    #  null
        
  return BomExporterView