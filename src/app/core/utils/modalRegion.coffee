define (require)->
  $ = require 'jquery'
  bootstrap = require 'bootstrap'
  marionette = require 'marionette'
  
  
  class ModalRegion extends Backbone.Marionette.Region
    el: "#none"

    constructor:(options) ->
      options = options or {}
      @large = options.large ? false
      elName = options.elName ? "dummyDiv"
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
     
    onShow:(view)=>
      @showModal(view)
      
    makeEl:(elName)->
      if ($("#" + elName).length == 0)
        $ '<div/>',
          id: elName,
        .appendTo('body')
      
    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el
      
    showModal: (view)=>
      view.on("close", @hideModal, @)
      
      #workaround for twitter bootstrap multi modal bug
      oldFocus = @$el.modal.Constructor.prototype.enforceFocus
      @$el.modal.Constructor.prototype.enforceFocus = ()->{}
      
      
      @$el.addClass('fade modal')
      @$el.modal({'show':true,'backdrop':true})
      if @large
        @$el.addClass('modal-reallyBig')
     
      #cleanup for workaround
      @$el.modal.Constructor.prototype.enforceFocus = oldFocus
        
    hideModal: ->
      @$el.modal 'hide'
      @$el.removeClass('fade')
      @$el.remove()
      @trigger("closed")
      
  return ModalRegion