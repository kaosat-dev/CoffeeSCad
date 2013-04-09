define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  
  reqRes = require 'core/messaging/appReqRes'
  
  amfExporterTemplate =  require "text!./amfExporter.tmpl"
 
 
  class AmfExporterView extends Backbone.Marionette.ItemView
    template: amfExporterTemplate
    
    ui:
      fileNameinput:  "#fileNameinput"
      exportButton:   "#amfExportBtn"
    
    events:
      "mousedown #amfExportBtn":   "onExport"
    
    constructor:(options)->
      super options
      @modelBinder = new Backbone.ModelBinder()
      @bindings = 
        compiled: [{selector: '#amfExportBtn', elAttribute: 'disabled', converter:=>return (not @model.isCompiled)} ]
      
    onExport:->
      if not @ui.exportButton.attr('disabled')
        exportBlobUrl = reqRes.request("amfexportBlobUrl")
        if exportBlobUrl != null
          @ui.exportButton.prop("download", "#{@ui.fileNameinput.val()}")
          @ui.exportButton.prop("href", exportBlobUrl)
        
    onRender:->
      @modelBinder.bind(@model, @el, @bindings)
          
    onClose:=>
      @modelBinder.unbind()
        
  return AmfExporterView