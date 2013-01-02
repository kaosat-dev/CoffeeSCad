define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  
  bomExporterTemplate =  require "text!./bomExporter.tmpl"
  
  class BomExporterView extends Backbone.Marionette.ItemView
    template: bomExporterTemplate
    
    constructor:(options)->
      super options
      @vent = vent
      
    serializeData: ()->
      null
      
    onRender:=>
        
  return BomExporterView