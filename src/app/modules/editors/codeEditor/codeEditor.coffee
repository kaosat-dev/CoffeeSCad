define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  Project = require 'modules/core/projects/project'
  
  CodeEditorView = require './multiFileView'
  CodeEditorSettings = require './codeEditorSettings'
  CodeEditorRouter = require "./codeEditorRouter"
  
  ###############################
 
  class CodeEditor extends Backbone.Marionette.Application
    title: "CodeEditor"
    regions:
      mainRegion: "#Content"
    
    constructor:(options)->
      super options
      @settings = options.settings ? new CodeEditorSettings()
      @project= options.project ? new Project()
      @vent = vent
      @addRegions @regions
      
      @router = new CodeEditorRouter
        controller: @
        
      @init()

      @on("start", @onStart)
      
    init:=>
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
        
    onStart:()=>
      @mainRegion.show new CodeEditorView 
        model:    @project
        settings: @settings
      
  return CodeEditor