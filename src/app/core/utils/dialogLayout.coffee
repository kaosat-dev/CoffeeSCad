define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'

  dialogTemplate =  require "text!./dialog.tmpl"
  
  class DialogLayout extends Backbone.Marionette.Layout
    template: dialogTemplate
    regions: 
      contentRegion: '#contentContainer'

    constructor:(options) ->
      options = options or {}
      super options
  
  return DialogLayout