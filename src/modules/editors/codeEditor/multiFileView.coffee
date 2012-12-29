define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  
  filesCodeTemplate =  require "text!./multiFile.tmpl"
  fileTabTemplate = require "text!./fileTab.tmpl"
  filesTabTemplate = require "text!./filesTab.tmpl"
  
  FileCodeView = require "./fileCodeView"
  ConsoleView =  require "./consoleView"

  class FileTabView extends Backbone.Marionette.ItemView
    template: fileTabTemplate
    tagName: "li"
    events:
      "click a[data-toggle=\"tab\"]" : "selectFile" 
      "click em.close":    "closeTab"

    selectFile:->
      vent.trigger("file:selected",@model)
      
    closeTab:->
      @close()
      vent.trigger("file:closed",@model.get("name"))
    
  
  class FilesTabView extends Backbone.Marionette.CompositeView
    itemView: FileTabView
    tagName: "ul"
    template: filesTabTemplate
    className: "nav nav-tabs"
    
    constructor:(options) ->
      super options
      
  
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
      
  
  class MultiFileView extends Backbone.Marionette.Layout
    template: filesCodeTemplate
    regions: 
      tabHeaders: "#tabHeaders"
      tabContent: "#tabContent"
      console:    "#console"
    
    constructor:(options)->
      super options
      @settings = options.settings
      

    onRender:=>
      #show console
      consoleView = new ConsoleView()
      @console.show consoleView
      #show tab nav
      headerView = new FilesTabView
        collection: @model.pfiles
      @tabHeaders.show headerView
      
      #show content
      codeView = new FilesCodeView
        collection: @model.pfiles
        settings:   @settings
      @tabContent.show codeView

      #activate first tab      
      @tabHeaders.$el.find('a:first').tab('show')
      defaultItem = @tabContent.$el.find('div .tab-pane:first')
      defaultItem.addClass('active')
      defaultItem.removeClass('fade')
      
      $("a[data-toggle=\"tab\"]").on "shown", (e) ->
        e.target # activated tab
        e.relatedTarget # previous tab
        console.log "lkjljlk"

      
  return MultiFileView