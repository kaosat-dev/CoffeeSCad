define (require)->
  $ = require 'jquery'
  bootstrap = require 'bootstrap'
  marionette = require 'marionette'
  
  
  class ModalRegion extends Backbone.Marionette.Region
    el: "#none"

    constructor:(options) ->
      super options
      
      elName = options.elName
      @makeEl(elName)
      @$el = $("##{elName}")
      
      _.bindAll(this)
      @on("view:show", @showModal, @)
      
    makeEl:(elName)->
      $ '<div/>',
        id: elName,
      .appendTo('body')
      
    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el
      
    showModal: (view)=>
      view.on("close", @hideModal, @)
      #FIXME: weird bug: modal() does not add a modal class, but an "in" class to the div ??
      @$el.modal({'show':true}).addClass('modal-big').addClass('modal')
        
    hideModal: ->
      @$el.modal 'hide'
      
  return ModalRegion