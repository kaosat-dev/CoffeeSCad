define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  
  Dummy = require './dummy'
  
  class DummyCollection extends Backbone.Collection
    model: Dummy
    
    constructor:(options)->
      super options
  

  return DummyCollection