define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require '../coffeescad.vent'
  dummyTemplate = require "text!./dummy.tmpl"
  
  
  class DummyView extends Backbone.Marionette.ItemView
    template: dummyTemplate
    events:
      'click .doSomething ': 'doSomething'

    constructor:(options)->
      super options
    
    doSomething:()->
      console.log "doing something"
      vent.trigger("doSomething", @model)
      
  class DummyCollectionView extends Backbone.Marionette.CollectionView
    itemView:DummyView

  return DummyCollectionView