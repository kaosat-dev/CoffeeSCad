define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  contextMenuTemplate = require "text!templates/contextMenu.tmpl"
  

  class ContextMenu extends Backbone.Marionette.ItemView
    template: contextMenuTemplate
      
    constructor:(options)->
      super options


  return ContextMenuView