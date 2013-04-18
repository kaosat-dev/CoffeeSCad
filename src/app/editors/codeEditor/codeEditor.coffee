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

  DummyView = require 'core/utils/dummyView'
 
 
  class CodeEditor extends Backbone.Marionette.Application
    title: "CodeEditor"
    regions:
      mainRegion: "#code"
    
    constructor:(options)->
      super options
      @appSettings = options.appSettings ? null
      @settings = options.settings ? new CodeEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new CodeEditorRouter
        controller: @
        
      @vent.on("project:loaded",@resetEditor)
      @init()

      @addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("CodeEditor", CodeEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
      
      #if requested we send back the type of SettingsView to use for this specific sub app
      reqRes.addHandler "CodeEditorSettingsView", ()->
        return CodeEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.get("CodeEditor")
      @showRegions()
      
    showRegions:=>
      DialogRegion = require 'core/utils/dialogRegion'
      DialogLayout = require 'core/utils/dialogLayout'
      
      @codeEditorView = new CodeEditorView 
        model:    @project
        settings: @settings
      
      #@diaReg = new DialogRegion({elName:"codeEdit", title: "CodeEditor", width:500, height:350})
      
      #@dialLayout = new DialogLayout()
      #@dialLayout.render()
      #@dialLayout.contentRegion.show(codeEditorView)
      #@diaReg.show(@dialLayout)
      #@diaReg.show codeEditorView
      
      #other attempt
      DialogView = require 'core/utils/dialogView'
      @dia = new DialogView({elName:"codeEdit", title: "CodeEditor", width:400, height:250})
      @dia.render()
      @dia.show(@codeEditorView)
      
      #Setup keyBindings
      ### 
      $(document).bind('keydown', 'ctrl+a', (event)->
        console.log "I WANT TO SAVE"
        )
      ###
    resetEditor:(newProject)=>
      console.log "resetting code editor"
      @project = newProject
      @codeEditorView = new CodeEditorView 
        model:    @project
        settings: @settings
      @dia.hide()
      @dia.show(@codeEditorView)
      ### 
      if @diaReg?
        console.log "closing current code editor"
        @diaReg.close()
      @showRegions()
      ###
      #@mainRegion.close()
  
  return CodeEditor