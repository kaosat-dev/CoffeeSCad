define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
  amfExporterTemplate =  require "text!./amfExporter.tmpl"
 
 
  class AmfExporterView extends Backbone.Marionette.ItemView
    template: amfExporterTemplate
    
    ui:
      exportButton:   "#amfExportBtn"
      fileNameinput:  "#fileNameinput"
    
    events:
      "click .exportAmf":   "onExport"   
    
    constructor:(options)->
      super options
      @vent = vent
      @vent.on("project:new",     ()->@ui.exportButton.addClass "disabled") 
      @vent.on("project:compiled",()->@ui.exportButton.removeClass "disabled")
      
    onExport:->
      vent.trigger("export:amf")
      exportBlobUrl = reqRes.request("amfexportBlobUrl")
      if exportBlobUrl != null
        @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}")
        @ui.exportButton.prop("href", exportBlobUrl)
        
    onRender:->
      if @model.get("compiled")
          @ui.exportButton.removeClass "disabled"
    
        
  return AmfExporterView