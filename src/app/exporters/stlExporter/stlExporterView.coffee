define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  
  reqRes = require 'core/messaging/appReqRes'
  
  stlExporterTemplate =  require "text!./stlExporter.tmpl"
 
 
  class StlExporterView extends Backbone.Marionette.ItemView
    template: stlExporterTemplate
    
    ui:
      fileNameinput:  "#fileNameinput"
      exportButton:   "#stlExportBtn"
    
    events:
      "click #stlExportBtn":   "onExport"   
    
    constructor:(options)->
      super options
      @modelBinder = new Backbone.ModelBinder()
      @bindings = 
        compiled: [{selector: '#stlExportBtn', elAttribute: 'disabled', converter:=>return (not @model.isCompiled)} ]
      
    onExport:->
      if not @ui.exportButton.attr('disabled')
        exportBlobUrl = reqRes.request("stlexportBlobUrl")
        if exportBlobUrl != null
          @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}")
          @ui.exportButton.prop("href", exportBlobUrl)
        
    onRender:->
      @modelBinder.bind(@model, @el, @bindings)
          
    onClose:=>
      @modelBinder.unbind()
        
  return StlExporterView