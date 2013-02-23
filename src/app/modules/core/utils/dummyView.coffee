define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  dummyTmpl = require "text!./dummy.tmpl"
  
  class DummyView extends Backbone.Marionette.ItemView
    template: dummyTmpl
    
  return DummyView