define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  
  stlExporterTemplate =  require "text!./stlExporter.tmpl"
  
  class StlExporterView extends Backbone.Marionette.ItemView
    template: stlExporterTemplate
    
    constructor:(options)->
      super options
      @vent = vent
      
    serializeData: ()->
      null
      
    onRender:=>
      @clearConsole()

        
  return StlExporterView