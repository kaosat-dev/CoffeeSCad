define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  
  reqRes = require 'core/messaging/appReqRes'
  
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
      @modelBinder = new Backbone.ModelBinder()
      @bindings = 
        compiled: [{selector: '#bomExportBtn', elAttribute: 'disabled', converter:=>return (not @model.isCompiled)} ]
    
    onExport:->
      if @model.isCompiled
        exportUrl = reqRes.request("bomExportUrl")
        if exportUrl != null
          fileName = @model.get("name")
          @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}")
          @ui.exportButton.prop("href", exportUrl)
     
    onRender:->
      @modelBinder.bind(@model, @el, @bindings)
      bomPartListView = new BomPartListView
        collection: @model.bom
      @partsList.show bomPartListView
          
    onClose:=>
      @modelBinder.unbind()

        
  return BomExporterView