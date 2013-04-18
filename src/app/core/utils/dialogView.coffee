define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'

  require 'slider'

  dialogTemplate =  require "text!./dialog.tmpl"

  class DialogView extends Backbone.Marionette.ItemView
    template: dialogTemplate
    el: "#none"

    constructor:(options) ->
      options = options or {}
      @width = options.width ? 640
      @height = options.height ? 480
      @resizeable = options.resizeable ? true
      @title = options.title ? "Title"
      elName = options.elName ? "dummyDiv"
      @makeEl(elName)
      options.el = "##{elName}"
      
      super options
      _.bindAll(this)
      @docked = false
    
    
    makeEl:(elName)->
      if ($("#" + elName).length == 0)
        $ '<div>',
          id: elName,
        .appendTo('#mainContent')
      
    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el
    
    serializeData:->
      console.log "here"
      return {"title":@title}
      
    _setResizeable:=>
      if @resizeable
        @$el.resizable
          containment: "#mainContent"
          handles: "all"
          stop:(event,ui)=>
            @currentView.$el.trigger("resize")
            @$el.css("height","auto")
    
    _setDragable:=>
      @$el.draggable
        containment: '#mainContent'
        handle: '.dialog-header'
        scroll: false
    
    render:()=>
      @isClosed = false
      @triggerMethod("before:render", @)
      @triggerMethod("item:before:render", @)
  
      realTemplate = $(dialogTemplate).filter('#dialogTmpl')
      realTemplate = _.template($(dialogTemplate).filter('#dialogTmpl').html())
      
      data = this.serializeData()
      data = this.mixinTemplateHelpers(data)

      template = this.getTemplate();
      html = Marionette.Renderer.render(template, data)
      
      @$el.html(html)
      
      @bindUIElements()
      @triggerMethod("render", @)
      @triggerMethod("item:rendered", @)
      
      #additional
      @$el.addClass("dialog floatpanel")
      @$el.css("width",@width)
      @$el.css("height",@height)
      triggerResize= =>
        @currentView.$el.trigger("resize")
        @$el.css("height","auto")
        $('#visual').trigger("resize")
        
      setTimeout triggerResize, 5
      
      @_setDragable() 
      @_setResizeable()
      @_setupBindings()
      @_setupDockZones()
      return @
   
    _setupDockZones:()->
      #should be done once, on start
      that = @
      $('.dockZone').droppable
        tolerance: 'touch',
        drop: (event, ui)->
          that._dockDraggable(this, ui.draggable)
          
    _dockDraggable:(dockzone, draggable)=>
      console.log "docking attempt"
      $(draggable).resizable('destroy')
      $(draggable).addClass('docked')
      if (dockzone.id.indexOf("North") != -1)
        @_dockNorth(dockzone, draggable)
      else if (dockzone.id.indexOf("West") != -1)
        @_dockWest(dockzone, draggable)
      else if (dockzone.id.indexOf("East") != -1)
        @_dockEast(dockzone, draggable)
      else if (dockzone.id.indexOf("South") != -1)
        @_dockSouth(dockzone, draggable)
        
      $(draggable).removeClass('floatpanel dockableDraggable')
      $('.dockZoneHighlight').removeClass('dockZoneHighlight') 
      
    _setupBindings:()=>
      that = @
      $('.slider').slider()
      #workaround for twitter bootstrap collapse limitations
      $('#contentContainer').on 'show hide', ()->
        $(this).css('height', 'auto')
      
      @$el.bind "dragstart", (e, ui)=>
        if @$el.hasClass('floatpanel')
          @$el.addClass('draggingpanel')
      
      @$el.bind "drag", (e, ui)=>
        if @$el.hasClass('floatpanel')
          if not @_touchingBoundary(@$el)
            @_unsnapAll(@$el, $('.dockZone'))
        else if (@$el.hasClass('docked'))
          that._undoc(@$el, e, ui)
          
      @$el.bind "dragstop", (e)=>
          @$el.removeClass('draggingpanel')
    
    _touchingBoundary:(p)->
      bTouching = true
      if @_touchingNorth(p)
        #console.log('Snapping North!')
        @_snapNorth(p, $('#_dockZoneNorth'))
      else if @_touchingWest(p)
        #console.log('Snapping West!')
        @_snapWest(p, $('#_dockZoneWest'))
      else if @_touchingEast(p)
        #console.log('Snapping East!')
        @_snapEast(p, $('#_dockZoneEast'))
      else if @_touchingSouth(p)
        #console.log('Snapping South!')
        @_snapSouth(p, $('#_dockZoneSouth'))
      else 
        bTouching = false
      return bTouching
      
    _touchingNorth:(elem)->
      return (elem.offset().top <= 1)

    _touchingWest:(elem)->
      return (elem.offset().left <= $("#_dockZoneWest").width())

    _touchingEast:(elem)->
      rm = (elem.offset().left+$(elem).width() >= $("#_dockZoneEast").offset().left)
      return rm

    _touchingSouth:(elem)->
      bm = $(elem).parent().height() - (elem.offset().top + $(elem).outerHeight())
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
      dockZone = elem
      @docked = true
      @dock = elem
      #save dockable's current attributes
      @savedWidth = draggable.width()
      @savedHeight = draggable.height()
      #fill container: 30 is the navbar size...should be dynamic
      $(draggable).height($(dockZone).height()-32)
      $(draggable).css("right","0px")
      $(draggable).css("top",30)
      $(draggable).addClass('dockEast')
      
      $('#_dockZoneEast').width(draggable.width())
      $(".dockEast").resizable
        containment: "#mainContent"
        handles: "w"
        stop:(event,ui)=>
          @currentView.$el.trigger("resize")
          $('#_dockZoneEast').width( $(".dockEast").width())
          #hack
          $('#visual').trigger("resize")
          
      #workaround for positioning
      $(".dockEast").css("position","absolute") 
      triggerResize= =>
        @currentView.$el.trigger("resize")
      setTimeout triggerResize, 5
      
      $('#visual').trigger("resize")
      
      
    _dockWest:(elem, draggable)=>
      dockZone = elem
      @docked = true
      @dock = elem
      #save dockable's current attributes
      @savedWidth = draggable.width()
      @savedHeight = draggable.height()
      #fill container: 30 is the navbar size...should be dynamic
      $(draggable).height($(dockZone).height()-32)
      $(draggable).css("left",0)
      $(draggable).css("top",30)
      $(draggable).addClass('dockWest')
      
      $('#_dockZoneWest').width(draggable.width())
      $(".dockWest").resizable
        containment: "#mainContent"
        handles: "e"
        stop:(event,ui)=>
          @currentView.$el.trigger("resize")
          $('#_dockZoneWest').width( $(".dockWest").width())
          #hack
          $('#visual').trigger("resize")
          
          
      #workaround for positioning
      $(".dockWest").css("position","absolute") 
      triggerResize= =>
        @currentView.$el.trigger("resize")
      setTimeout triggerResize, 5
      
      $('#visual').trigger("resize")

    _dockSouth:(elem, draggable)->
      $(draggable).addClass('dockSouth')
      $(draggable).removeAttr('style')
      $(".dockSouth").resizable
          handles: 'n'
      
    _undoc:(p, e, ui)=>
      console.log "undocking"
      console.log @
      
      if @dock?
        $(@dock).css('width', 10)
        
      console.log "recalling saved dims: width/height", @savedWidth, @savedHeight
      if @savedHeight?
        $(p).css("height",@savedHeight)
      if @savedWidth?
        $(p).css("wdith",@savedWidth)
      
      $(p).removeClass('docked dockNorth dockEast dockWest dockSouth')
      $(p).addClass('floatpanel draggingpanel')
      
      ### 
      ui.position.left = e.pageX
      ui.position.top = e.pageY
      ui.originalPosition.left = e.pageX
      ui.originalPosition.top = e.pageY
      ui.offset.top = 0
      ui.offset.left = 0
      $(p).css('top', e.pageY + 2)
      $(p).css('left', e.pageX + 2)
      ###
      $(p).css('top', 100)
      $(p).resizable('destroy')#destroy previous , constrained resize
      
      @_setDragable()
      @_setResizeable()
      
      bla= =>
        #resize the pannels etc (inner elements first)
         $('#visual').trigger("resize")
        @currentView.$el.trigger("resize")
        #now that the inner elements, have the right size, switch back to auto height to enable correct collapsing
        @$el.css("height","auto")
      setTimeout bla, 5
      
      return (true)
    
    ### 
    hide: ->
      @$el.modal 'hide'
      @$el.remove()
      @trigger("closed")
    ###  
    show:(view)->
      view.render()
      injectTarget = @$el.find("#contentContainer")
      injectTarget.append(view.el)
      Marionette.triggerMethod.call(view, "show")
      Marionette.triggerMethod.call(this, "show", view)
      this.currentView = view
      
    hide:(view)->
      this.currentView.close()
      injectTarget = @$el.find("#contentContainer")
      injectTarget.html("")
      this.currentView = null
        
  return DialogView