define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  template = require "text!templates/alert.tmpl"
  
  class AlertView extends Backbone.Marionette.ItemView
    template: template
    
    constructor:( options) ->
      super options
      @app = require 'app'
      @model = new Backbone.Model
        "title":"blahg"
      
    onRender:()=>
      $(".alert").alert()
      
  return AlertView