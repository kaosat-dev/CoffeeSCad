define (require)->
  $ = require 'jquery'
  $ui = require 'jquery_ui'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  dialogTemplate =  require "text!./dialog.tmpl"

  class DialogView extends Backbone.Marionette.ItemView
    template: dialogTemplate
    el: "#none"

    events:
      "change .opacitySetter" : "onOpacityChanged"
      "keyup .opacitySetter" : "onOpacityChanged"

    constructor:(options) ->
      options = options or {}
      @width = options.width ? 640
      @height = options.height ? 480
      @position = options.position ? [100,100]
      @resizeable = options.resizeable ? true
      @dockable = options.dockable ? false
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
      return {"title":@title}
      
    _setResizeable:=>
      if @resizeable
        @$el.resizable
          containment: "#mainContent"
          handles: "all"
          stop:(event,ui)=>
            @currentView.$el.trigger("resize")
            @$el.css("height","auto")
        @$el.css("position","absolute")
    
    _setDragable:=>
      @$el.draggable
        containment: '#mainContent'
        handle: '.dialog-header'
        scroll: false
   
    _setTransparency:=>
      $(".dialog").css("opacity",0.9)
      ###
      elements = [".dialog",".dialog-body", "#tabContent","#filesList",".CodeMirror cm-s-lesser-dark CodeMirror-focused",".cm-s-lesser-dark.CodeMirror"]
      for elem in elements
        rawBgRgba = $(elem).css("background-color")
        if not rawBgRgba?
          rawBgRgba = $(elem).css("background")
          
        rgbvals = /rgb\((.+),(.+),(.+)\)/i.exec(rawBgRgba)
        a = 0.5
        if rgbvals?
          r = parseInt(rgbvals[1])
          g = parseInt(rgbvals[2])
          b = parseInt(rgbvals[3])
          newColor = "rgba(#{r},#{g},#{b},#{a})"
          $(elem).css("background-color",newColor)
          $(elem).css("background",newColor)
      ###  
        
      ###
      rawBgRgba = $(".dialog").css("background-color")
      rgbvals = /rgb\((.+),(.+),(.+)\)/i.exec(rawBgRgba)
      if rgbvals?
        r = parseInt(rgbvals[1])
        g = parseInt(rgbvals[2])
        b = parseInt(rgbvals[3])
      else
        r = 255
        g = 255
        b = 255
      a = 0.2
      newColor = "rgba(#{r},#{g},#{b},#{a})"
      console.log "new bg color",newColor 
      
      $(".dialog").css("background-color",newColor)
      #$(".dialog-body").css("background-color",newColor)
      
      $("#tabContent").css("background-color",newColor)
      $(".filesListContainer").css("background-color",newColor)
      
      $(".cm-s-lesser-dark.CodeMirror").css("background-color",newColor)
      #$(".CodeMirror cm-s-lesser-dark CodeMirror-focused").css("background-color",newColor)
      ###
    
    onOpacityChanged:(e)->
      opacity = parseFloat(e.currentTarget.value)/100
      console.log opacity
      if opacity >= 0.25 and opacity <= 1
        @$el.css("opacity",opacity)
      
    
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
      
      @$el.css("left",@position[0])
      @$el.css("top",@position[1])
      
      triggerResize= =>
        @currentView.$el.trigger("resize")
        @$el.css("height","auto")
        $('#visual').trigger("resize")
        
      setTimeout triggerResize, 5
      
      @_setDragable() 
      @_setResizeable()
      @_setTransparency()
      @_setupBindings()
      @_setupDockZones()
      return @
   
    _setupDockZones:()=>
      #should be done once, on start
      if @dockable 
        that = @
        $('.dockZone').droppable
          tolerance: 'touch',
          drop: (event, ui)->
            that._dockDraggable(this, ui.draggable)
          
    _dockDraggable:(dockzone, draggable)->
      if @dockable 
        console.log "docking attempt because I am dockable #{@dockable}"
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
      #workaround for twitter bootstrap collapse limitations
      $('#contentContainer').on 'show hide', ()->
        $(this).css('height', 'auto')
      
      #TODO: move this to a plugin
      @$el.on('click.collapse-next.data-api', '[data-toggle=collapse-next]', (e)->
          $target = $(this).parent().parent().next()
          if $target.data('collapse')? 
            $target.collapse('toggle')
          else $target.collapse()
        )
      $("ul.dropdown-menu").on "click", "[data-stopPropagation]", (e)->
        e.stopPropagation()
        
      #@$el.on "change.opacitySetter", @onOpacityChanged
      #"onkeyup opacitySetter" : "onOpacityChanged"
        
      @$el.on('click.data-dismiss.data-api', '[data-dismiss=dialog]', (e)=>
          that = @
          $target = $(this).parent().parent().parent()
          #this.$element
          #.removeClass('in')
          #.attr('aria-hidden', true)
          
          console.log "hiding bla"
          $target.addClass("hide")
          @close()
          @$el.remove()
        )
      
      
      
      if @dockable 
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
      console.log "docking east"
      dockZone = elem
      @docked = true
      @dock = elem
      #save dockable's current attributes
      @savedWidth = draggable.width()
      @savedHeight = draggable.height()
      #fill container: 30 is the navbar size...should be dynamic
      ###$(draggable).height($(dockZone).height()-30)
      $(draggable).css("right","0px")
      $(draggable).css("top",0)###
      
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
        $('#visual').trigger("resize")
      setTimeout triggerResize, 5
      
    _dockWest:(elem, draggable)=>
      dockZone = elem
      @docked = true
      @dock = elem
      #save dockable's current attributes
      @savedWidth = draggable.width()
      @savedHeight = draggable.height()
      #$(draggable).height($(dockZone).height()-30)#fill container: 30 is the navbar size...should be dynamic
      
      $(draggable).addClass('dockWest')  
      
      $('#_dockZoneWest').width(draggable.width())
      $(".dockWest").resizable
        containment: "#mainContent"
        handles: "e"
        stop:(event,ui)=>
          @currentView.$el.trigger("resize")
          $('#_dockZoneWest').width(@$el.width())
          #hack
          $('#visual').trigger("resize")
          
      triggerResize= =>
        @currentView.$el.trigger("resize")
        $('#visual').trigger("resize")
      setTimeout triggerResize, 5

    _dockSouth:(elem, draggable)->
      dockZone = elem
      @docked = true
      @dock = elem
      #save dockable's current attributes
      @savedWidth = draggable.width()
      @savedHeight = draggable.height()
      $(draggable).width($(dockZone).width())
      $(draggable).css("left",0)
      #$(draggable).css("top",32)
      
      $(draggable).addClass('dockSouth')
      
      $('#_dockZoneSouth').height(draggable.height())
      $(".dockSouth").resizable
        containment: "#mainContent"
        handles: "n"
        stop:(event,ui)=>
          @currentView.$el.trigger("resize")
          $('#_dockZoneSouth').width( $(".dockSouth").width())
          #hack
          $('#visual').trigger("resize")
      
      
      #workaround for positioning
      $(".dockSouth").css("position","absolute") 
      triggerResize= =>
        @currentView.$el.trigger("resize")
      setTimeout triggerResize, 5
      
      $('#visual').trigger("resize")
    
    _undoc:=>
      console.log "undocking"
      console.log @
      if @dock?
        console.log "setting dock width"
        $(@dock).css('width', 10)
        
      #console.log "recalling saved dims: width/height", @savedWidth, @savedHeight
      if @savedHeight?
        @$el.css("height",@savedHeight)
      if @savedWidth?
        @$el.css("width",@savedWidth)
      
      @$el.removeClass('docked dockNorth dockEast dockWest dockSouth')
      @$el.addClass('floatpanel draggingpanel')
      
      @$el.resizable('destroy')#destroy previous , constrained resize
      @_setResizeable()
      @_setDragable()
      
      triggerResize= =>
        #resize the pannels etc (inner elements first)
        $('#visual').trigger("resize")
        @currentView.$el.trigger("resize")
        
      setTimeout triggerResize, 15
      return true
    
    ### 
    _undoc:(p, e, ui)=>
      console.log "undocking"
      console.log @
      if @dock?
        console.log "setting dock width"
        $(@dock).css('width', 10)
        
      console.log "recalling saved dims: width/height", @savedWidth, @savedHeight
      if @savedHeight?
        $(p).css("height",@savedHeight)
      if @savedWidth?
        $(p).css("width",@savedWidth)
      
      $(p).removeClass('docked dockNorth dockEast dockWest dockSouth')
      $(p).addClass('floatpanel draggingpanel')
      
      $(p).resizable('destroy')#destroy previous , constrained resize
      @_setResizeable()
      @_setDragable()
      
      triggerResize= =>
        #resize the pannels etc (inner elements first)
        $('#visual').trigger("resize")
        @currentView.$el.trigger("resize")
        
      setTimeout triggerResize, 15
      return true
    ###
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
      
      @_setTransparency()
      
    hide:(view)->
      this.currentView.close()
      injectTarget = @$el.find("#contentContainer")
      injectTarget.html("")
      this.currentView = null
      
    close:()->
      @_isShown = false
      @isClosed = true
      console.log "fdgd"
      @_undoc()
        
  return DialogView