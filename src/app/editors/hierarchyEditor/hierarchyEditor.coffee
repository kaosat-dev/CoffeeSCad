define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
  HierarchyEditorSettings = require './hierarchyEditorSettings'
  #HierarchyEditorSettingsView = require './hierarchyEditorSettingsView'
  #HierarchyEditorRouter = require "./hierarchyEditorRouter"
  HierarchyEditorView = require './hierarchyEditorView'

 
  class HierarchyEditor extends Backbone.Marionette.Application
    title: "HierarchyEditor"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new HierarchyEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      #@router = new HierarchyEditorRouter
      #  controller: @
        
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @init()

      #@addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("HierarchyEditor", HierarchyEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      reqRes.addHandler "HierarchyEditorSettingsView", ()->
        return HierarchyEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("HierarchyEditor")
      @showRegions()
      
    showRegions:=>
      hierarchyEditorView = new HierarchyEditorView 
        model:    @project
        settings: @settings
      
      DialogView = require 'core/utils/dialogView'
      @dia = new DialogView({elName:"hiearchyEdit", title: "Assembly", width:200, height:150,position:[25,25]})
      @dia.render()
      @dia.show(hierarchyEditorView)
      
    resetEditor:(newProject)=>
      console.log "resetting hiearchy editor"
      @project = newProject
      if @diaReg?
        console.log "closing current hiearchy editor"
        @diaReg.close()
      @showRegions()
      #@mainRegion.close()
  
  return HierarchyEditor