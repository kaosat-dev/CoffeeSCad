define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  sF_template = require "text!templates/saveFile.tmpl"
  lF_template = require "text!templates/loadFile.tmpl"
  
  class SaveView extends marionette.ItemView
    template: sF_template
    ui:
      fileNameInput: "#projectFileName"
    
    triggers: 
      "mouseup .saveFile":    "file:save:mouseup"
      
    constructor:( options) ->
      super options
      @app = require 'app'
      @on "file:save:mouseup" ,=>
        fileName = $(@ui.fileNameInput).val()
        @app.vent.trigger("fileSaveRequest", fileName)
        @.close()
        
  class LoadView extends marionette.ItemView
    template: lF_template
    ui:
      fileNameInput: "#projectFileName"
      
    triggers: 
      "mouseup .loadFile":    "file:load:mouseup"
      
    constructor:( options) ->
      super options
      @app = require 'app'

      @on "file:load:mouseup" ,=>
        fileName = $(@ui.fileNameInput).val()
        @app.vent.trigger("fileLoadRequest", fileName)
        @.close()    

  
  return {SaveView,LoadView}