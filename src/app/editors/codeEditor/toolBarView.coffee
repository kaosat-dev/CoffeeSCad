define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'core/messaging/appVent'
  toolBarTemplate =  require "text!./toolBarView.tmpl"
  
  
  class ToolBarView extends Backbone.Marionette.ItemView
    template: toolBarTemplate
    
    serializeData: ()->
      null
    
    events:
      "click .newFile": "onNewFile"
    
    constructor:(options)->
      super options
    
    onNewFile:->
      console.log "adding new file"
      $('.newFile').popover
        content:'<div><div><input type="text" value="file.coffee"></input></div></div> '
        template: '<div class="popover" style="height:45px"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title" style="display: none"></h3><div class="popover-content"><p></p></div></div></div>'
      $('.newFile').popover
        show:true
        #<div class="row toolBar pull-left"></div>   
        #<div class="row toolBar pull-left"><a href="#"> <div class="span6 pagination-centered"><i class="icon-plus icon-large"></i></div></a></div>       
          #<div class="row toolBar"><a href="#"> <div class="span6 pagination-centered"><i class="icon-plus icon-large"></i></div></a></div>
  return ToolBarView
