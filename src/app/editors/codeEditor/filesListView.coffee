define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  #require 'jquery_hotkeys'
  modelBinder = require 'modelbinder'
  
  vent = require 'core/messaging/appVent'
  
  fileTabTemplate = require "text!./fileTab.tmpl"
  filesTabTemplate = require "text!./filesTab.tmpl"
  filesListTemplate = require "text!./filesList.tmpl"
  FileCodeView = require "./fileCodeViewAce"
  ConsoleView =  require "./consoleView"

  DummyView = require 'core/utils/dummyView'
  
  
  class FileTabView extends Backbone.Marionette.ItemView
    template: fileTabTemplate
    tagName: "li"
    events:
      "click a[data-toggle=\"tab\"]" : "selectFile" 
      "click .closeFile":    "closeTab"

    constructor:(options)->
      super options
      #model binding
      converter=()=>
        extra = ""
        if @model.isSaveAdvised
          extra = "*"
        return @model.name+extra+"  "
      
      @bindings = 
        name: [{selector: "[name=fileName]",converter:converter}]
        isSaveAdvised:[{selector: "[name=fileName]",converter:converter}]
      @modelBinder = new Backbone.ModelBinder()

    selectFile:(e)=>
      e.stopImmediatePropagation()
      vent.trigger("file:selected",@model)
      @trigger("file:selected",@model)
      
    closeTab:(e)->
      e.stopImmediatePropagation()
      @trigger("file:closed",@model)
      vent.trigger("file:closed",@model)
      @close()
    
    onShow:()=>
      vent.trigger("file:selected",@model)
      @$el.tab('show')
      @$el.addClass("active")
    
    onRender:=>
      @modelBinder.bind(@model, @el, @bindings)
    
    onClose:=>
      @modelBinder.unbind()

  
  class FilesTabView extends Backbone.Marionette.CompositeView
    itemView: FileTabView
    tagName: "ul"
    template: filesTabTemplate
    className: "nav nav-tabs"
    
    constructor:(options) ->
      super options
      @on("itemview:file:selected", @onFileSelected)
      @on("itemview:file:closed", @onFileClosed)
    
    onFileSelected:(childView, file)=>
      @children.each (childView)->
        childView.$el.removeClass("active")
      childView.$el.addClass("active")
      
    onFileClosed:(childView, file)=>
      #if there was only two view open, and the one that got closed was the second one (on the right of the remaining one)
      console.log @children.length
      console.log childView.cid
      console.log @children
      if @children.length > 1
        console.log @children.rest()
        @children.each (childView)->
          childView.$el.removeClass("active")
        @children.first().$el.addClass("active")
        
      
    selectFile:(file)=>
      @children.each (childView)->
        childView.$el.removeClass("active")
        if childView.model is file
          childView.$el.addClass("active")
    
    onRender:->
      @$el.sortable()
  
  class FilesCodeView extends Backbone.Marionette.CompositeView
    itemView: FileCodeView
    tagName: "div"
    template: filesTabTemplate
    className:"tab-content"
    
    constructor:(options) ->
      super options
      @settings = options.settings
      vent.on("file:closed",@onFileClosed)
      
    itemViewOptions:()->
      settings:@settings
    
    selectFile:(file)=>
      @children.each (childView)->
        childView.$el.removeClass("active")
        if childView.model is file
          childView.$el.addClass("active")
          childView.$el.removeClass('fade')
    
    onFileClosed:(childView, file)=>
      #if there was only two view open, and the one that got closed was the second one (on the right of the remaining one)
      if @children.length > 0
        @children.each (childView)->
          childView.$el.addClass("active")
          childView.$el.removeClass('fade')
  
  
  class FilesListView extends Backbone.Marionette.Layout
    template: filesListTemplate
    regions: 
      tabHeaders: "#tabHeaders"
      tabHeadersList: "#tabList"
      tabContent: "#tabContent"
      console: "#console"
    ui: 
      console: "#console"
      tabContent: "#tabContent"
    
    constructor:(options)->
      super options
      @settings = options.settings
      
      
      
      @activeFile = if @model.activeFile? then @model.activeFile else @collection.first()
      #@activeFile = @collection.first()
      console.log "setting active file",@activeFile
      
      @openFiles = new Backbone.Collection()
      @openFiles.add @activeFile
      
      @collection.on('remove',(item)=>@openFiles.remove(item) )
      
      vent.on("file:selected", @showFile)
      #vent.on("file:OpenRequest", @showFile)
      vent.on("file:closed", @hideFile)
      
      @_setupKeyboardBindings()
    
    _setupKeyboardBindings:=>
      #Setup keyBindings
      ###
      @$el.bind 'keydown', 'ctrl+s', ->
        console.log "i want to save a FILE"
        return false

      $(document).bind "keydown", "ctrl+s", ->
        console.log "I WANT TO SAVE2"
        return false
      ###
    
    onDomRefresh:=>
      @console.el=  @ui.console
      @tabContent.el = @ui.tabContent
      #elHeight = 500#@$el.parent().height()-200
      #@$el.css('height':"#{elHeight}px")
      @$el.parent().addClass("filesListContainer")
      $(@console.el).addClass("ui-layout-south")
      $(@tabContent.el).addClass("ui-layout-center")
      innerLayoutOptions = {
        defaults: {
            applyDefaultStyles: true
        },
      }
      #@myLayout = @$el.layout({applyDefaultStyles: true})
      #@codeView.setHeight(@$el.parent().height())
      
    
    onRender:=>
      #show tab nav
      @headerView = new FilesTabView
        collection: @openFiles
      @tabHeaders.show @headerView
      
      #show content
      @codeView = new FilesCodeView
        collection: @openFiles
        settings:   @settings
      @tabContent.show @codeView
      
      #show console
      consoleView = new ConsoleView
        model:@model
      @console.show consoleView
 
    showFile:(file)=>
      found = @openFiles.find (item)=>
        return (item.get('name') == file.get('name'))# and item.get('ext') == file.get('ext'))
        
      if not found?
        console.log "new File #{file.get('name')}"
        @openFiles.add(file)
      else
        try
          @headerView.selectFile(found)
          @codeView.selectFile(found)
          @model.makeFileActive(found)
        catch error
        
    hideFile:(file)=>
      found = @openFiles.find (item)=>
        return (item.get('name') == file.get('name'))# and item.get('ext') == file.get('ext'))
      if found
        @openFiles.remove(file)
        console.log "removed File #{file.get('name')}"

  return FilesListView