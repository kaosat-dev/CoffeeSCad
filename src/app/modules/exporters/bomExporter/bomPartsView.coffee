define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  bomPartTemplate =  require "text!./bomPart.tmpl"
  bomPartsListTemplate =  require "text!./bomPartList.tmpl"
  
  class BomPartView extends Backbone.Marionette.ItemView
    template: bomPartTemplate
    tagName:  'tr'
    
    constructor:(options)->
      super options
      
  class BomPartListView extends Backbone.Marionette.CompositeView
    template: bomPartsListTemplate
    tagName:  'table'
    className: 'table table-condensed table-bordered'
    itemView: BomPartView
    
    constructor:(options)->
      super options      
      
  return BomPartListView