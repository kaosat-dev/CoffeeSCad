define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  wreqr = require 'wreqr'
  
  return new Backbone.Wreqr.EventAggregator()