define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  #modelbinder = require 'modelbinder'
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
