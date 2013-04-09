define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'backbone-forms'
  
  class GeometryEditorSettingsForm extends Backbone.Form
    constructor:(options)->
      super options
      
      
  class GeometryEditorSettingsView extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new GeometryEditorSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el   
      
  return GeometryEditorSettingsView 