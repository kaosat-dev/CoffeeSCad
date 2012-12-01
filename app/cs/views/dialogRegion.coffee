define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  jquery_ui = require 'jquery_ui'
  
  class DialogRegion extends Backbone.Marionette.Region
    el: "#dialogRegion",

    constructor: ->
      _.bindAll(this)
      @on("view:show", @showModal, @)

    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el

    showModal: (view)=>
      view.on("close", @hideModal, @)
      $("#dialog").dialog
        title : "Part Code Editor"#view.model.get("name")
        width: 550
        height: 700
        position: 
          my: "right center"
          at: "right bottom"
      ###
      $(".draggable").draggable
        grid: [ 1, 1 ]
      $(".draggable").resizable
        handles : "se"
      ###
       
    hideModal: ->
      @$el.modal 'hide'
      
  return DialogRegion