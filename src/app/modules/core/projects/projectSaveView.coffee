define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  sF_template = require "text!templates/saveFile.tmpl"
  lF_template = require "text!templates/loadFile.tmpl"
  sF2_template = require "text!templates/singleFile.tmpl"
  
  class SaveView extends Backbone.Marionette.ItemView
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
  

  return LoadView