define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
  stlExporterTemplate =  require "text!./stlExporter.tmpl"
 
 
  class StlExporterView extends Backbone.Marionette.ItemView
    template: stlExporterTemplate
    
    ui:
      exportButton:   "#stlExportBtn"
      fileNameinput:  "#fileNameinput"
    
    events:
      "click .exportStl":   "onExport"   
    
    constructor:(options)->
      super options
      @vent = vent
      @vent.on("project:new",     ()->@ui.exportButton.addClass "disabled") 
      @vent.on("project:compiled",()->@ui.exportButton.removeClass "disabled")
      
    onExport:->
      vent.trigger("export:stl")
      exportBlobUrl = reqRes.request("stlexportBlobUrl")
      if exportBlobUrl != null
        @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}.stl")
        @ui.exportButton.prop("href", exportBlobUrl)
        
    onRender:->
      if @model.get("compiled")
          @ui.exportButton.removeClass "disabled"
    
    #serializeData: ()->
    #  null
        
  return StlExporterView