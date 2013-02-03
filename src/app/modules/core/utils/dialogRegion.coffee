define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'

  
  class DialogRegion extends Backbone.Marionette.Region
    el: "#none"

    constructor:(options) ->
      @large = options.large
      elName = options.elName
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
      
      @on("view:show", @showDialog, @)
      
    makeEl:(elName)->
      if ($("#" + elName).length == 0)
        $ '<div/>',
          id: elName,
        .appendTo('body')
      
    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el

    showDialog: (view)=>
      view.on("close", @hideDialog, @)
      #FIXME: weird bug: modal() does not add a modal class, but an "in" class to the div ??
      @$el.modal({'show':true,'backdrop':'data-static'}).addClass('modal fade')
      @$el.removeClass('fade')#to increase drag responsiveness
      @$el.draggable({grid: [ 1, 1 ]}).resizable({handles : "se"})
      
      ###
      $el = @getEl()
      view.isVisible=true
      el = "#dialogRegion"
      $(el).dialog
        title : "Part Code Editor"#view.model.get("name")
        width: 550
        height: 700
        position: 
          my: "right center"
          at: "right bottom"
        beforeClose: =>
          view.isVisible=false
          view.close()
          
      ###
       
    hideDialog: ->
      @$el.modal 'hide'
      @$el.remove()
      @trigger("closed")
      
      
  return DialogRegion