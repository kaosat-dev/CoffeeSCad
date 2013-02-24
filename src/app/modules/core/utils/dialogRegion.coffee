define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'

  
  class DialogRegion extends Backbone.Marionette.Region
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
      #  view.$el.trigger("resize")
      @$el.on 'resizestart' , (event,ui)=>
        view.$el.trigger("resize:start")
      @$el.on 'resizestop' , (event,ui)=>
        view.$el.trigger("resize:stop")
        
        
      #console.log @$el.parent().size()
      @$el.offset({ top: -500, left: 30 })
      #@$el.position({collision:"none"})
      #@$el.position({my:"right bottom",at:"center bottom", of: "#toto"})
      ###
      <div class="modal-header">
        <h3 id="myModalLabel"><i class="icon-cogs icon-large"></i>Blabla</h3>
      </div>
      <div class="modal-body">
      </div>
      ###
      ###
      @$el.css("margin-left", @$el.size.width/2)
      @$el.css("margin-left", @$el.size.width/2)
      @$el.css("margin-top",  @$el.size.height/2)
      @$el.css("top", "50%")
      @$el.css("top", "50%")
      $(ui.element).find(".modal-body").each(()=>
        @$el.css("max-height", 400 + @$el.size.height - @$el.size.originalSize.height)
    )###
      
      ###
      $(".modal").on "resize", (event, ui) ->
        ui.element.css "margin-left", -ui.size.width / 2
        ui.element.css "margin-top", -ui.size.height / 2
        ui.element.css "top", "50%"
        ui.element.css "left", "50%"
        $(ui.element).find(".modal-body").each ->
          $(this).css "max-height", 400 + ui.size.height - ui.originalSize.height
      ###
      
      
      #@$el.append('<div class="ui-resizable-handle ui-resizable-e" style="z-index: 90; "></div>')
      #@$el.append('<div class="ui-resizable-handle ui-resizable-s" style="z-index: 90; "></div>')
      #@$el.append('<div class="ui-resizable-handle ui-resizable-se ui-icon ui-icon-gripsmall-diagonal-se" style="z-index: 90; "></div>')
        
        
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