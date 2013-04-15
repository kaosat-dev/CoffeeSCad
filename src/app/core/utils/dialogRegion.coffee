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
      @title = options.title ? "Title"
      @large = options.large ? false
      elName = options.elName ? "dummyDiv"
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
      
      @docked = false
    
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
      ### 
      view.isVisible=true
      @$el.dialog
        title : @title#view.model.get("name")
        width: @width
        height: @height
        closeOnEscape: false
        position: 
          my: "left top"
          at: "left top+100"
          of: "#mainContent"
        beforeClose: =>
          view.isVisible=false
          view.close()
          
        resize:=>
          view.$el.trigger("resize")
        #open:(event, ui)=>
          #$(".ui-dialog-titlebar-close", ui.dialog or ui).hide()
      .parent().resizable({
        containment: "#mainContent"
      }).draggable({
        containment: "#mainContent", 
        opacity: 0.70 
      }); 
      
    
    _touchingNorth:(elem)->
      return (elem.offsetTop <= 1);

    _touchingWest:(elem)->
      return (elem.offsetLeft <= 1);

    _touchingEast:(elem)->
      rm = $(elem).parent().width() - (elem.offsetLeft + $(elem).outerWidth());
      return (rm <= 1);

    _touchingSouth:(elem)->
      bm = $(elem).parent().height() - (elem.offsetTop + $(elem).outerHeight());
      return (bm <= 1);
    
    touchingBoundary:(p)->
      bTouching = true
      if @touchingNorth(p)
        $('#_umsg').text('Snapping North!')
        snapNorth(p, $('#_dockZoneNorth'))
      else if touchingWest(p)
        $('#_umsg').text('Snapping West!')
        snapWest(p, $('#_dockZoneWest'))
      else if touchingEast(p)
        $('#_umsg').text('Snapping East!')
        snapEast(p, $('#_dockZoneEast'))
      else if touchingSouth(p)
        $('#_umsg').text('Snapping South!')
        snapSouth(p, $('#_dockZoneSouth'))
      else 
        bTouching = false
      return bTouching
    
    _snapNorth:(elem, zone)->
      $(elem).addClass('dockableDraggable')
      $(zone).addClass('dockZoneHighlight')

    _snapWest:(elem, zone)->
      $(elem).addClass('dockableDraggable')
      $(zone).addClass('dockZoneHighlight')

    _snapEast:(elem, zone)->
      $(elem).addClass('dockableDraggable')
      $(zone).addClass('dockZoneHighlight')
      
    _snapSouth:(elem, zone)->
      $(elem).addClass('dockableDraggable')
      $(zone).addClass('dockZoneHighlight')
      
    _unsnapAll:(elem, zones)->
      $(elem).removeClass('dockableDraggable')
      $(zones).removeClass('dockZoneHighlight')
       
    hideDialog: ->
      @$el.modal 'hide'
      @$el.remove()
      @trigger("closed")
      
      
  return DialogRegion