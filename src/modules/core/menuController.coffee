define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  
  class MenuController extends Backbone.Marionette.Controller

    constructor: (options)->
      @stuff = options.stuff

    doStuff: ()->
      @trigger("stuff:done", @stuff)

    @mainMenuView.on "project:new:mouseup",=>

    @mainMenuView.on "file:new:mouseup",=>
      @newProject()
      
    @mainMenuView.on "file:save:mouseup",=>
      if @project.isNew2()
        @modView = new SaveView
        @modal.show(@modView)
      else
        console.log "save existing"
        @vent.trigger("fileSaveRequest",@project.get("name"))
      
    @mainMenuView.on "file:saveas:mouseup",=>
      @modView = new SaveView
      @modal.show(@modView)
    
    @mainMenuView.on "file:load:mouseup",=>
      @modView = new LoadView
        collection: @lib
      @modal.show(@modView)
     
    @mainMenuView.on "settings:mouseup",=>
      @modView = new SettingsView 
        model: @settings
      @modal.show(@modView)      