define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'core/messaging/appVent'
  
  template =  require "text!./geometryEditorView.tmpl"


  class GeometryEditorView extends Backbone.Marionette.Layout
    template: template
    className: "geometryEditor"
    
    events:
      "resize:start": "onResizeStart"
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      
    constructor:(options)->
      super options
      @settings = options.settings
    
    onDomRefresh:()=>

    onResizeStart:=>
      
    onResizeStop:=>

    onRender:=>
      
  return GeometryEditorView