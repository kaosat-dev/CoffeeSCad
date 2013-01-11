define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  Project = require 'modules/core/projects/project'
  
  VisualEditorSettings = require './visualEditorSettings'
  VisualEditorSettingsView = require './visualEditorSettingsView'
  VisualEditorRouter = require "./visualEditorRouter"
  VisualEditorView = require './visualEditorView'
  
  
  class VisualEditor extends Backbone.Marionette.Application
    title: "VisualEditor"
    regions:
      mainRegion: "#visual"
    
    constructor:(options)->
      super options
      
      @settings = options.settings ? new VisualEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new VisualEditorRouter
        controller: @
      @on("start", @onStart)
      @init()

      @addRegions @regions
      
    init:=>
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
      reqRes.addHandler "foo", ()->
        return "foo requested. VISUAL EDITOR RESPONDING"
        
    onStart:()=>
      @mainRegion.show new VisualEditorView 
        model:    @project.pfiles.at(0)
        settings: @settings
      
  return VisualEditor