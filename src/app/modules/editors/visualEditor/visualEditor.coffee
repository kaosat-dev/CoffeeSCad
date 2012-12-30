define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  vent = require 'core/vent'
  
  View = require './visualEditorView'
  Project = require 'core/projects/project'
  VisualEditorRouter = require "./visualEditorRouter"
  ###############################
 
  class VisualEditor extends Backbone.Marionette.Application
    title: "VisualEditor"
    regions:
      mainRegion: "#Content"
    
    constructor:(options)->
      super options
      @vent = vent
      @addRegions @regions
      
      @router = new VisualEditorRouter
        controller: @
        
      @init()

      @on("start", @onStart)
      
    init:=>
      @addInitializer ->
        @vent.trigger "app:started", "#{@title}"
        
    onStart:()=>
      
  return DummySubApp