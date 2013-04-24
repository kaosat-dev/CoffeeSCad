define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
  GeometryEditorSettings = require './geometryEditorSettings'
  GeometryEditorSettingsView = require './geometryEditorSettingsView'
  GeometryEditorRouter = require "./geometryEditorRouter"
  GeometryEditorView = require './geometryEditorView'

 
  class GeometryEditor extends Backbone.Marionette.Application
    title: "GeometryEditor"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new GeometryEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new GeometryEditorRouter
        controller: @
        
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @init()

      #@addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("GeometryEditor", GeometryEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      reqRes.addHandler "GeometryEditorSettingsView", ()->
        return GeometryEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("GeometryEditor")
      #@showRegions()
      
    showRegions:=>
      DialogRegion = require 'core/utils/dialogRegion'
      @diaReg = new DialogRegion({elName:"geometryEdit", title: "GeometryEditor", width:200, height:150})
      geometryEditorView = new GeometryEditorView 
        model:    @project
        settings: @settings
      @diaReg.show geometryEditorView
      
    resetEditor:(newProject)=>
      console.log "resetting geometry editor"
      @project = newProject
      if @diaReg?
        console.log "closing current geometry editor"
        @diaReg.close()
      #@showRegions()
      #@mainRegion.close()
  
  return GeometryEditor