define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  vent = require '../coffeescad.vent'
  
  
  DummyCollectionView = require './dummyView'
  Dummy = require './dummy'
  DummyCollection = require './dummyCollection'
  DummyRouter = require "./dummyRouter"
  ###############################
 
  class DummySubApp extends Backbone.Marionette.Application
    title: "DummySubApp"
    regions:
      mainRegion: "#dummyContent"
    
    constructor:(options)->
      super options
      @vent = vent
      @addRegions @regions
      
      @router = new DummyRouter
        controller: @
        
      @init()
      @dummies = new DummyCollection()
      
    init:=>
      @addInitializer ->
        console.log "oh yeah, initializing"
        @vent.trigger "app:started", "#{@title}"
        
    newDummy:=>
      console.log "so you want a new dummy eh ?"
      @dummies.add(new Dummy())
      
    deleteDummy:=>
      console.log "killing a dummy"
    
    listDummies:=>
      console.log "showing dummies"
      @dummyView = new DummyCollectionView
        collection : @dummies
      @mainRegion.show(@dummyView)
 
  #dummySubApp = new DummySubApp()
  return DummySubApp