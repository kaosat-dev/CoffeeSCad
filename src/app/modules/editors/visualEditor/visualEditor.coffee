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
      
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new VisualEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new VisualEditorRouter
        controller: @
      @on("start", @onStart)
      @init()

      @addRegions @regions
      
      @vent.on("project:compiled",()=>@project.set("compiled",true))#TODO: remove this , this is a hack
      @vent.on("project:setBomData",(data)=>@project.set("partRegistry",data))#TODO: remove this , this is a hack
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("VisualEditor", VisualEditorSettings)
      
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
        
      reqRes.addHandler "VisualEditorSettingsView", ()->
        return VisualEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.getByName("VisualEditor")
      
      @mainRegion.show new VisualEditorView 
        model:    @project.pfiles.at(0)
        settings: @settings
      
  return VisualEditor