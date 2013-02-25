define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  Project = require 'modules/core/projects/project'
  
  CodeEditorSettings = require './codeEditorSettings'
  CodeEditorSettingsView = require './codeEditorSettingsView'
  CodeEditorRouter = require "./codeEditorRouter"
  CodeEditorView = require './codeEditorView'

  DummyView = require 'modules/core/utils/dummyView'
 
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
      @settings = @appSettings.getByName("CodeEditor")
      @showRegions()
      
    showRegions:=>
      ###   
      @mainRegion.show new CodeEditorView 
        model:    @project
        settings: @settings
      ###
      DialogRegion = require 'modules/core/utils/dialogRegion'
      @diaReg = new DialogRegion({elName:"codeEdit"})
      @diaReg.show new CodeEditorView 
        model:    @project
        settings: @settings
    
    resetEditor:(newProject)=>
      console.log "resetting code editor"
      @project = newProject
      if @diaReg?
        console.log "closing current code editor"
        @diaReg.close()
      @showRegions()
      #@mainRegion.close()
  
  return CodeEditor