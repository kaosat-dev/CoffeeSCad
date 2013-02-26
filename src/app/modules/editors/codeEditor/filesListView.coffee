define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  
  fileTabTemplate = require "text!./fileTab.tmpl"
  filesTabTemplate = require "text!./filesTab.tmpl"
  filesListTemplate = require "text!./filesList.tmpl"
  FileCodeView = require "./fileCodeView"
  ConsoleView =  require "./consoleView"

  DummyView = require 'modules/core/utils/dummyView'
  
  
  class FileTabView extends Backbone.Marionette.ItemView
    template: fileTabTemplate
    tagName: "li"
    events:
      "click a[data-toggle=\"tab\"]" : "selectFile" 
      "click em.close":    "closeTab"

    constructor:(options)->
      super options
      #model binding
      @model.on("change:name", @render)

    selectFile:(e)=>
      e.stopImmediatePropagation()
      #@$el.addClass("active")
      vent.trigger("file:selected",@model)
      @trigger("file:selected",@model)
      
    closeTab:(e)->
      e.stopImmediatePropagation()
      @close()
      vent.trigger("file:closed",@model)
    
    onShow:()=>
      vent.trigger("file:selected",@model)
      @$el.tab('show')
      @$el.addClass("active")

  
  class FilesTabView extends Backbone.Marionette.CompositeView
    itemView: FileTabView
    tagName: "ul"
    template: filesTabTemplate
    className: "nav nav-tabs"
    
    constructor:(options) ->
      super options
    
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
      
    itemViewOptions:()->
        settings:@settings
  
  
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
      
      @openFiles = new Backbone.Collection()
      @openFiles.add @collection.first()
      @activeFile = @collection.first()
      
      vent.on("file:selected", @showFile)
      vent.on("file:OpenRequest", @showFile)
      vent.on("file:closed", @hideFile)
    
    onDomRefresh:=>
      console.log "pouet"
      @console.el=  @ui.console
      @tabContent.el = @ui.tabContent
      
      #elHeight = 500#@$el.parent().height()-200
      #@$el.css('height':"#{elHeight}px")
      
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
      headerView = new FilesTabView
        collection: @openFiles
      @tabHeaders.show headerView
      
      #show content
      @codeView = new FilesCodeView
        collection: @openFiles
        settings:   @settings
      @tabContent.show @codeView
      
      #show console
      consoleView = new ConsoleView
        model:@model
      @console.show consoleView
      
      #$(@tabContent.el).css("overflow-y": "hidden")
      #$(@tabHeaders.el).css("overflow-y": "hidden")
      
      ### 
      #activate first tab      
      #firstFile = @tabHeaders.$el.find('a:first')
      try
        @tabHeaders.$el.find('a:first').tab('show')
        defaultItem = @tabContent.$el.find('div .tab-pane:first')
        defaultItem.addClass('active')
        defaultItem.removeClass('fade')
        #vent.trigger("file:selected", @activeFile)
      catch error
      ###
      
      
    showFile:(file)=>
      found = @openFiles.find (item)=>
        return (item.get('name') == file.get('name') and item.get('ext') == file.get('ext'))
        
      if not found
        @openFiles.add(file)
        console.log "new File #{file.get('name')}"
        
    hideFile:(file)=>
      found = @openFiles.find (item)=>
        return (item.get('name') == file.get('name') and item.get('ext') == file.get('ext'))
      if found
        @openFiles.remove(file)
        console.log "removed File #{file.get('name')}"

  return FilesListView