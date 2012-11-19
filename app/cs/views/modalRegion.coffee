define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  
  class ModalRegion extends Backbone.Marionette.Region
    el: "#modal",

    constructor: ->
      _.bindAll(this)
      @on("view:show", @showModal, @)

    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el

    showModal: (view)=>
      view.on("close", @hideModal, @)
      @$el.modal({'show':true,'backdrop':false}).addClass('modal-big')
        
    hideModal: ->
      @$el.modal 'hide'
      
  return ModalRegion