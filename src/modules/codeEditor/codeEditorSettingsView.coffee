define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'forms'
  forms_bstrap= require 'forms_bootstrap'
  s_template  = require "text!templates/settings.tmpl"
  sh_template = require "text!templates/settingsHeader.tmpl"
  sha_template = require "text!templates/settingsHeaderAll.tmpl"
  
  sc_template = require "text!templates/settingsContent.tmpl"
  sca_template = require "text!templates/settingsContentAll.tmpl"
  
  class EditorSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          startLine    : 'Number'
        options.fieldsets=[
          "legend": "General settings"
          "fields": ["startLine"]
        ]
      super options
  
  class CodeEditorSettingsView extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new EditorSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el   
      
  return CodeEditorSettingsView 