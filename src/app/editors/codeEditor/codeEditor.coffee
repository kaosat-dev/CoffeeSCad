define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  
  CodeEditorSettings = require './codeEditorSettings'
  CodeEditorSettingsView = require './codeEditorSettingsView'
  CodeEditorRouter = require "./codeEditorRouter"
  CodeEditorView = require './codeEditorView'
  DialogView = require 'core/utils/dialogView'
 
  class CodeEditor extends Backbone.Marionette.Application
    title: "CodeEditor"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new CodeEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new CodeEditorRouter
        controller: @
      
      #TODO: should this be here? in the settings?
      @startWithParent = true
      @showOnAppStart = true
      @addMainMenuIcon = true
      @icon = "icon-code" 
        
      @vent.on("project:loaded",@resetEditor)
      @vent.on("project:created",@resetEditor)
      @vent.on("CodeEditor:show",@showView)
      @init()
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("CodeEditor", CodeEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}", @
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      reqRes.addHandler "CodeEditorSettingsView", ()->
        return CodeEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("CodeEditor")
      if @showOnAppStart
        @showView()
      
    showView:=>
      if not @dia?
        #@dia.close()
        @dia = new DialogView({elName:"codeEdit", title: "CodeEditor", width:450, height:250,position:[25,125],dockable:true})
        @dia.render()
      
      if not @codeEditorView?
        @codeEditorView = new CodeEditorView 
          model:    @project
          settings: @settings
      if not @dia.currentView?    
        @dia.show(@codeEditorView)
      else
        @dia.showDialog()
      #Setup keyBindings
      ### 
      $(document).bind('keydown', 'ctrl+a', (event)->
        console.log "I WANT TO SAVE"
        )
      ###
    hideView:=>
      @dia.hideDialog()
      
    resetEditor:(newProject)=>
      console.log "resetting code editor"
      @project = newProject
      
      if @dia?
        @dia.close()
        @codeEditorView = null
      if @showOnAppStart
        @showView()
  
  return CodeEditor