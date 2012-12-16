define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  DummyView = require './dummyView'
  Dummy = require './dummy'
  DummyCollection = require './dummyCollection'
  
  class DummyController #extends Backbone.Marionette.Controller
  
    constructor: (options)->
      console.log "in dummy controller constructor"
      @dummies = new DummyCollection()

    newDummy:->
      console.log "so you want a new dummy eh ?"
      
    deleteDummy:->
      console.log "killing a dummy"
    
    listDummies:->
      console.log "showing dummies"
      @dummy = new Dummy()
      @dummyView = new DummyView
        model : @dummy
      

  return new DummyController()
