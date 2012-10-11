define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  mainMenu_template = require "text!templates/mainMenu.tmpl"
  
  class MainMenuView extends marionette.ItemView
    template: mainMenu_template
    
    onBeforeRender:() =>
      console.log "pouet"
    onRender: =>
      console.log "tjtj"
  return MainMenuView