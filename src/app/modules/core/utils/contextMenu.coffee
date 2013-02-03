define (require)->
  $ = require 'jquery'
  bootstrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  marionette = require 'marionette'
  
  class ContextMenu extends Backbone.Marionette.Region
    el: "#none"

    constructor:(options) ->
      options = options or {}
      elName = options.elName ? "contextMenu"
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
      
      @on("view:show", @showMenu, @)
      
    makeEl:(elName)->
      if ($("#" + elName).length == 0)
        $ '<div/>',
          id: elName,
        .appendTo('body')
      
    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el
      
    showMenu: (view)=>
      view.on("close", @hideMenu, @)
      @$el.contextmenu()
        
    hideMenu: ->
      @$el.remove()
      @trigger("closed")
      
  return ContextMenu