define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  vent = require 'core/vent'
  
  View = require './codeEditorView'
  Project = require 'core/projects/project'
  CodeEditorRouter = require "./codeEditorRouter"
  ###############################
 
  class CodeEditor extends Backbone.Marionette.Application
    title: "CodeEditor"
    regions:
      mainRegion: "#Content"
    
    constructor:(options)->
      super options
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
      
  return DummySubApp