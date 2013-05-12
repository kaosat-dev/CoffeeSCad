define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
  ExampleEditorSettings = require './exampleEditorSettings'
  #exampleEditorSettingsView = require './exampleEditorSettingsView'
  ExampleEditorView = require './exampleEditorView'
  DialogView = require 'core/utils/dialogView'

 
  class ExampleEditor extends Backbone.Marionette.Application
    title: "exampleEditor"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new exampleEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      
      @startWithParent = true
      @showOnAppStart = true
      @addMainMenuIcon = true
      @icon = "icon-list"
      
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @vent.on("exampleEditor:show",@showView)
      @init()
      
    init:=>
      ### 
      only if you want this editors settings to be displayed in the main settings view:
      BUT you need to provide a settings view of course (see other editors)
      if @appSettings?
        @appSettings.registerSettingClass("exampleEditor", ExampleEditorSettings)
      ###  
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}",@
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      ###reqRes.addHandler "ExampleEditorSettingsView", ()->
        return ExampleEditorSettingsView
      ###  
      
    onStart:()=>
      @settings = @appSettings.get("ExampleEditor")
      if @showOnAppStart
        @showView()
      
    showView:=>
      if not @dia?
        @dia = new DialogView({elName:"exampleEdit", title: "My dialog", width:200, height:150, position:[25,25]})
        @dia.render()
      
      if not @exampleEditorView?
        @exampleEditorView = new ExampleEditorView 
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
  
  return ExampleEditor