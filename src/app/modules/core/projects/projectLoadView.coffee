define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  sF_template = require "text!templates/saveFile.tmpl"
  lF_template = require "text!templates/loadFile.tmpl"
  sF2_template = require "text!templates/singleFile.tmpl"
  
  class SingleFileView extends Backbone.Marionette.ItemView
      template: sF2_template
      tagName:  "tr"
      
      onRender:()=>
        @$el.attr("id",@model.get("name"))
       
       
    class LoadView extends Backbone.Marionette.CompositeView
      template: lF_template
      itemView: SingleFileView
      itemViewContainer: "tbody"
       
      events: 
        "mouseup .loadFile":    "requestFileLoad"
        "mouseup .deleteFile":  "requestFileDelete"
      
      requestFileLoad:(ev)=>
        fileName = $(ev.currentTarget).html()
        @app.vent.trigger("fileLoadRequest", fileName)
        @close()    
      
      requestFileDelete:(ev)=>
        id = $(ev.currentTarget)
        fileName = id.closest('tr').attr('id');
        @app.vent.trigger("fileDeleteRequest", fileName)
        @close() 
       
      constructor:( options) ->
        super options
        @app = require 'app'