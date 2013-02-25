define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  toolBarTemplate =  require "text!./toolBarView.tmpl"
  
  
  class ToolBarView extends Backbone.Marionette.ItemView
    template: toolBarTemplate
    
    serializeData: ()->
      null
    
    constructor:(options)->
      super options

    
  return ToolBarView
