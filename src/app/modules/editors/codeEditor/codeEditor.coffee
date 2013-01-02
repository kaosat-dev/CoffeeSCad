define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  Project = require 'modules/core/projects/project'
  
  CodeEditorSettings = require './codeEditorSettings'
  CodeEditorRouter = require "./codeEditorRouter"
  CodeEditorView = require './multiFileView'
  
 
  class CodeEditor extends Backbone.Marionette.Application
    title: "CodeEditor"
    regions:
      mainRegion: "#code"
    
    constructor:(options)->
      super options
      
      @settings = options.settings ? new CodeEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @router = new CodeEditorRouter
        controller: @
        
      @on("start", @onStart)
      @init()

      @addRegions @regions
      
    init:=>
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
        
    onStart:()=>
      @mainRegion.show new CodeEditorView 
        model:    @project
        settings: @settings
      
  return CodeEditor