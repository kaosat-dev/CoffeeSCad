define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
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
      @visualEditorView = null
      @project= options.project ? new Project()
      @vent = vent
      @router = new VisualEditorRouter
        controller: @
        
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @init()

      @addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("VisualEditor", VisualEditorSettings)
      
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}", @
        
      reqRes.addHandler "VisualEditorSettingsView", ()->
        return VisualEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.getByName("VisualEditor")
      @visualEditorView = new VisualEditorView
        model:    @project
        settings: @settings
      @visualEditorView.render()
      @visualEditorView.onDomRefresh()
      #@mainRegion.show @visualEditorView
        
    resetEditor:(newProject)=>
      @project = newProject
      if @visualEditorView?
        @visualEditorView.switchModel(@project)
      ### 
      @mainRegion.close()
      visualEditorView = new VisualEditorView
        model:    @project
        settings: @settings
      @mainRegion.show visualEditorView###
      
  return VisualEditor