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
      
      @_setupDockZones()
    
    makeEl:(elName)->
      if ($("#" + elName).length == 0)
        $ '<div>',
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
      
      ### 
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
      #console.log @$el
      console.log @$el[0].parentElement
      @_bindNewPanel($(@$el[0].parentElement))
      ###
      @_setupBindings()
    
    _setupDockZones:()->
      #should be done once, on start
      that = @
      $('.dockZone').droppable
        tolerance: 'pointer',
        drop: (event, ui)->
          that._dockDraggable(this, ui.draggable)
          
    _dockDraggable:(dockzone, draggable)=>
      $(draggable).resizable('destroy')
      $(draggable).addClass('docked')
      if (dockzone.id.indexOf("North") != -1)
        @_dockNorth(dockzone, draggable)
      else if (dockzone.id.indexOf("West") != -1)
        @_dockWest(dockzone, draggable)
      else if (dockzone.id.indexOf("East") != -1)
        @_dockEast(dockzone, draggable);
      else if (dockzone.id.indexOf("South") != -1)
        @_dockSouth(dockzone, draggable);
      $(draggable).removeClass('floatpanel dockableDraggable')
      $('.dockZoneHighlight').removeClass('dockZoneHighlight') 
      
      #fill container
      #$(draggable).height($(dockzone).height())
      #$(draggable).
      
    
    _setupBindings:()=>
      @$el.draggable
        containment: '#mainContent'
        
      @$el.bind "dragstart", (e, ui)=>
        if @$el.hasClass('floatpanel')
          @$el.addClass('draggingpanel')
      
      @$el.bind "drag", (e, ui)=>
        if @$el.hasClass('floatpanel')
          if not @_touchingBoundary(@)
            #console.log ""
            @unsnapAll(@, $('.dockZone'))
        else if (@$el.hasClass('docked'))
          @_undoc(@, e, ui)
          
      @$el.bind "dragstop", (e)=>
          @$el.removeClass('draggingpanel')
      
      @$el.bind "drag", (e,ui)=>
        console.log "dragging"
          
    _bindNewPanel_old:(p)=>
      #$(p).draggable
      #  containment: 'parent'
      that = @
      $(p).bind "dragstart", (e, ui)->
        if $(this).hasClass('floatpanel')
          $(this).addClass('draggingpanel')

      $(p).bind "drag", (e, ui)-> 
        if $(this).hasClass('floatpanel')
          if not that._touchingBoundary(this)
            $('#_umsg').text('')
            unsnapAll(this, $('.dockZone'))
        else if ($(this).hasClass('docked'))
          undoc(this, e, ui)
              
      $(p).bind "dragstop", (e)->
          $(this).removeClass('draggingpanel')
      
      console.log $(p)
    
    _touchingBoundary:(p)->
      bTouching = true
      if @_touchingNorth(p)
        $('#_umsg').text('Snapping North!')
        @_snapNorth(p, $('#_dockZoneNorth'))
      else if @_touchingWest(p)
        $('#_umsg').text('Snapping West!')
        @_snapWest(p, $('#_dockZoneWest'))
      else if touchingEast(p)
        $('#_umsg').text('Snapping East!')
        _snapEast(p, $('#_dockZoneEast'))
      else if touchingSouth(p)
        $('#_umsg').text('Snapping South!')
        _snapSouth(p, $('#_dockZoneSouth'))
      else 
        bTouching = false
      return bTouching
      
    _touchingNorth:(elem)->
      return (elem.offsetTop <= 1)

    _touchingWest:(elem)->
      return (elem.offsetLeft <= 1)

    _touchingEast:(elem)->
      rm = $(elem).parent().width() - (elem.offsetLeft + $(elem).outerWidth())
      return (rm <= 1);

    _touchingSouth:(elem)->
      bm = $(elem).parent().height() - (elem.offsetTop + $(elem).outerHeight())
      return (bm <= 1)
    
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
    
    _dockNorth:(elem, draggable)->
      $(draggable).addClass('dockNorth')
      $(draggable).removeAttr('style')
      $(".dockNorth").resizable
        handles: 's'
        
    _dockEast:(elem, draggable)->
      $(draggable).addClass('dockEast')
      $(draggable).removeAttr('style')
      $(".dockEast").resizable
        handles: 'w'
        
    _dockWest:(elem, draggable)->
      $(draggable).addClass('dockWest')
      $(draggable).removeAttr('style')
      $(".dockWest").resizable
          handles: 'e'

    _dockSouth:(elem, draggable)->
      $(draggable).addClass('dockSouth')
      $(draggable).removeAttr('style')
      $(".dockSouth").resizable
          handles: 'n'

    
    _undoc:(p, e, ui)->
      $(p).removeClass('docked dockNorth dockEast dockWest dockSouth')
      $(p).addClass('floatpanel draggingpanel')
      $(p).css('height', 100)
      $(p).css('width', 100)
      $(p).resizable()
      ui.position.left = e.pageX
      ui.position.top = e.pageY
      ui.originalPosition.left = e.pageX
      ui.originalPosition.top = e.pageY
      ui.offset.top = 0
      ui.offset.left = 0
      $(p).css('top', e.pageY + 2)
      $(p).css('left', e.pageX + 2)
      return (true)

    hideDialog: ->
      @$el.modal 'hide'
      @$el.remove()
      @trigger("closed")
      
      
  return DialogRegion