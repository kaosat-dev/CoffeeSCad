define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  

  class CoffeeScad extends Backbone.Marionette.Application
    