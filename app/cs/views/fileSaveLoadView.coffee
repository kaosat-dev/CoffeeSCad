define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  sF_template = require "text!templates/saveFile.tmpl"
  lF_template = require "text!templates/loadFile.tmpl"
  s_template = require "text!templates/settings.tmpl"
  
  class SaveView extends marionette.ItemView
    template: sF_template
    
    triggers: 
      "mouseup .saveFile":    "file:save:mouseup"
      
    constructor:( options) ->
      super options
      @app = require 'app'
      @on "file:save:mouseup" ,=>
        @app.vent.trigger("fileSaveRequest", @)
        @.close()
        
  class LoadView extends marionette.ItemView
    template: lF_template
    
    triggers: 
      "mouseup .loadFile":    "file:load:mouseup"
      
    constructor:( options) ->
      super options
      @app = require 'app'

      @on "file:load:mouseup" ,=>
        @app.vent.trigger("fileLoadRequest", @)
        @.close()    

  class SettingsView extends marionette.ItemView
    template: s_template
      
    constructor:( options) ->
      super options
      @app = require 'app'


  class ModalRegion extends marionette.Region
    el: "#modal",

    constructor: ->
      _.bindAll(this)
      @on("view:show", @showModal, @)

    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el

    showModal: (view)=>
      #console.log "showing modal"
      view.on("close", @hideModal, @)
      @$el.modal('show')
      
    hideModal: ->
      #console.log "hiding modal"
      @$el.modal 'hide'
  
  
  
  return [ModalRegion,SaveView,LoadView,SettingsView]