define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  template = require "text!templates/help.tmpl"
  
  class HelpView extends Backbone.Marionette.ItemView
    template: template
    
    constructor:( options) ->
      super options
      @app = require 'app'
      @model = new Backbone.Model
      
    onRender:()=>
      
      
  return AlertView