define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'

  
  class DialogRegion extends Backbone.Marionette.Region
    el: "#none"

    constructor:(options) ->
      options = options or {}
      @width = options.width ? 640
      @height = options.height ? 480
      @large = options.large ? false
      elName = options.elName ? "dummyDiv"
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
    
    onShow:(view)=>
      @showDialog(view)
    
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
      ###
      #workaround for twitter bootstrap multi modal bug
      oldFocus = @$el.modal.Constructor.prototype.enforceFocus
      @$el.modal.Constructor.prototype.enforceFocus = ()->{}

      #@$el.modal({'show':true,'backdrop':false})
      @$el.addClass('modal fade')
      @$el.removeClass('fade')#to increase drag responsiveness
      @$el.draggable({ snap: ".mainContent", snapMode: "outer",containment: ".mainContent" })
      @$el.resizable({minWidth:200, minHeight:200})#{handles : "se"})
      
      @$el.css("width",800)
      @$el.css("margin",0)
      
      
      @$el.css("z-index",200)
      #cleanup for workaround
      @$el.modal.Constructor.prototype.enforceFocus = oldFocus
      @$el.css("overflow-y": "hidden")
      
      #@$el.on 'resize' , (event,ui)=>
      #view.$el.trigger("resize")
      @$el.on 'resizestart' , (event,ui)=>
        view.$el.trigger("resize:start")
      @$el.on 'resizestop' , (event,ui)=>
        view.$el.trigger("resize:stop")
        
      #console.log @$el.parent().size()
      @$el.offset({ top: -500, left: 30 })
      #@$el.position({collision:"none"})
      #@$el.position({my:"right bottom",at:"center bottom", of: "#toto"})
      ### 
      view.isVisible=true
      @$el.dialog
        title : "CodeEditor"#view.model.get("name")
        width: 800
        height: 350
        closeOnEscape: false
        position: 
          my: "left top"
          at: "left top+50"
          #of: @el
        beforeClose: =>
          view.isVisible=false
          view.close()
          
        resize:=>
          view.$el.trigger("resize")
        open:(event, ui)=>
          $(".ui-dialog-titlebar-close", ui.dialog or ui).hide()
       
    hideDialog: ->
      @$el.modal 'hide'
      @$el.remove()
      @trigger("closed")
      
      
  return DialogRegion