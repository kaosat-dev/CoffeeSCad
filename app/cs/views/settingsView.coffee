define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'forms'
  forms       = require 'forms'
  s_template  = require "text!templates/settings.tmpl"
  st_template = require "text!templates/setting.tmpl"
  
  
  class SettingView extends marionette.ItemView
    template: st_template
    tagName: "li"
  
  
  class SettingsView extends marionette.CollectionView
    template: s_template
    itemView: SettingView
    tagName: "ul"
    ui:
        settingsList: "#settings"
      
    constructor:(options) ->
      super options
      @app = require 'app'

    render:()=>
      #console.log @template
      tmpl = _.template(@template)
      r1 = tmpl(@collection.toJSON())
      #console.log r1
      #console.log @collection.toJSON()
      $(@ui.settingsList).html(r1)
      return @
  
  
  class GeneralSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          'Max nb of recent files'    : 'Number'
          'view auto update'          : 'Checkbox' 
      super options
  
  class GlViewSettingsForm extends Backbone.Form
    #Backbone.Form.editors.List.Modal.ModalAdapter = Backbone.BootstrapModal
    constructor:(options)->
      if not options.schema
        options.schema=
          showGrid     : 'Checkbox'
          showAxis     : 'Checkbox' 
          renderer     :
            type: 'Select'
            options : ["webgl", "canvas"]
          antialiasing : 'Checkbox'
          shadows      : 'Checkbox'
          
      super options
  
  class EditorSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          'Start line'    : 'Number'
      super options
   
  class GitHubSettingsForm extends Backbone.Form
    
    constructor:(options)->
      if not options.schema
        options.schema=
          'Start line'    : 'Number'
      super options
  
      

  return GlViewSettingsForm