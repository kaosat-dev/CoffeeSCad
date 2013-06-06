define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
  ParamsEditorSettings = require './paramsEditorSettings'
  #ParamsEditorSettingsView = require './paramsEditorSettingsView'
  #ParamsEditorRouter = require "./paramsEditorRouter"
  ParamsEditorView = require './paramsEditorView'
  DialogView = require 'core/utils/dialogView'
 
  class ParamsEditor extends Backbone.Marionette.Application
    title: "ParamsEditor"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new ParamsEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      #@router = new ParamsEditorRouter
      #  controller: @
      
      @startWithParent = true
      @showOnAppStart = true
      @addMainMenuIcon = true
      @icon = "icon-edit"
      
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @vent.on("exampleEditor:show",@showView)
      @init()
      
    init:=>
      #if @appSettings?
      #  @appSettings.registerSettingClass("ParamsEditor", ParamsEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}",@
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      #reqRes.addHandler "ParamsEditorSettingsView", ()->
      #  return ParamsEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("ParamsEditor")
      if @showOnAppStart
        @showView()
      
    showView:=>
      if not @dia?
        @dia = new DialogView({elName:"paramsEdit", title: "Parameters", width:200, height:150, position:[25,25]})
        @dia.render()
      
      if not @exampleEditorView?
        @exampleEditorView = new ParamsEditorView 
          model:    @project
          settings: @settings
      if not @dia.currentView?    
        @dia.show(@exampleEditorView)
      else
        @dia.showDialog()
      
    hideView:=>
      @dia.hideDialog()
      
    resetEditor:(newProject)=>
      console.log "resetting example editor"
      @project = newProject
      if @dia?
        console.log "closing current example editor"
        @dia.close()
        @exampleEditorView = null
      if @showOnAppStart  
        @showView()
  
  return ParamsEditor