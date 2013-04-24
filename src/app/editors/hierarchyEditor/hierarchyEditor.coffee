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
  DialogView = require 'core/utils/dialogView'

 
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
      @icon = "icon-list"
      
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @vent.on("HierarchyEditor:show",@showView)
      @init()

      #@addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("HierarchyEditor", HierarchyEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}",@
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      reqRes.addHandler "HierarchyEditorSettingsView", ()->
        return HierarchyEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("HierarchyEditor")
      @showView()
      
    showView:=>
      if @dia?
        @dia.close()
      @dia = new DialogView({elName:"hiearchyEdit", title: "Assembly", width:200, height:150,position:[25,25]})
      @dia.render()
      
      if not @hierarchyEditorView?
        @hierarchyEditorView = new HierarchyEditorView 
          model:    @project
          settings: @settings
      
      @dia.show(@hierarchyEditorView)
      
    resetEditor:(newProject)=>
      console.log "resetting hiearchy editor"
      @project = newProject
      if @dia?
        console.log "closing current hiearchy editor"
        @dia.close()
        @hierarchyEditorView.close()
        @hierarchyEditorView = null
        
      @showView()
  
  return HierarchyEditor