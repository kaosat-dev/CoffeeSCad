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
  CodeEditorView = require './multiFileView'
  
 
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
        
      @on("start", @onStart)
      @init()

      @addRegions @regions
      
    init:=>
      if @appSettings?
        @appSettings.registerSettingClass("CodeEditor", CodeEditorSettings)
        
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
      
      reqRes.addHandler "CodeEditorSettingsView", ()->
        return CodeEditorSettingsView
        
    onStart:()=>
      @settings = @appSettings.getByName("CodeEditor")
      
      @mainRegion.show new CodeEditorView 
        model:    @project
        settings: @settings
  
  return CodeEditor