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
  
  
  class FilesListView extends Backbone.Marionette.Layout
    template: filesListTemplate
    regions: 
      tabHeaders: "#tabHeaders"
      tabHeadersList: "#tabList"
      tabContent: "#tabContent"
    
    constructor:(options)->
      super options
      @settings = options.settings
      vent.on("file:OpenRequest", @showFile)
    
    onRender:=>
      #show tab nav
      headerView = new FilesTabView
        collection: @model.pfiles
      @tabHeaders.show headerView
      
      #show content
      codeView = new FilesCodeView
        collection: @model.pfiles
        settings:   @settings
      @tabContent.show codeView
      $(@tabContent.el).addClass("ui-layout-center")

      #activate first tab      
      #firstFile = @tabHeaders.$el.find('a:first')
      @tabHeaders.$el.find('a:first').tab('show')
      defaultItem = @tabContent.$el.find('div .tab-pane:first')
      defaultItem.addClass('active')
      defaultItem.removeClass('fade')
      vent.trigger("file:selected",@model.pfiles.first)
      #FIXME not working
      $("a[data-toggle=\"tab\"]").on "shown", (e) ->
        e.target # activated tab
        e.relatedTarget # previous tab
        
    showFile:(file)=>
      console.log file

  return FilesListView