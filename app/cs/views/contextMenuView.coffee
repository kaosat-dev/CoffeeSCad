define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  jstree = require 'jquery_jstree'
  contextMenuTemplate = require "text!templates/contextMenu.tmpl"
  
  jquery_ui = require 'jquery_ui'
  
  
  class ContextMenuRegion extends Backbone.Marionette.Region
    el: "#"
    constructor:(options) ->
      super options
      @initialMouseCoords = options.mouseCoords
      console.log options.selection
      @makeEl()
      @$el = $("#contexMenu")
      
      _.bindAll(this)
      @on("view:show", @showModal, @)
    
    makeEl:()->
      $ '<div/>',
        id: 'contexMenu',
      .appendTo('body')

    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el
  
    showModal_:(view)=>
      #@contextMenu.show()
      @$el.dropdown()  
      #$('.dropdown-toggle').dropdown()  
      
      
    showModal: (view)=>
      $el = @getEl()
      view.isVisible=true
      el = "#contexMenu"
      $(el).dialog
        #title : "Projects"#view.model.get("name")
        width: 120
        height: 200
        resizable:false
        draggable:false
        
        position:@initialMouseCoords
        #  my: "right top"
        #  at: @initialMouseCoords
        
        beforeClose: =>
          view.isVisible=false
          #view.off("close", @hideModal, @)#: unbind this on close
          view.close()
      
    hideModal: ->
      @$el.modal 'hide'
      
  
  class ContextMenu extends Backbone.Marionette.ItemView
    template: contextMenuTemplate
   
    constructor:(options)->
      super options
      @app = require 'app'
 
  

  return {ContextMenu, ContextMenuRegion}