define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  
  filesCodeTemplate =  require "text!./multiFile.tmpl"
  
  FilesTreeView = require "./filesTreeView"
  FilesListView = require "./filesListView"
  ConsoleView =  require "./consoleView"

  
  class CodeViewsLayoutContainer extends Backbone.Marionette.Layout
    constructor:(options)->
      super options
      @settings = options.settings
      
      $ '<div/>',
          id: "codeViewsContainer",
        .appendTo('body')
        
      @wrappedStuff= new MultiFileView
        model:    @model
        settings: @settings
       
    render:()=>
      tmp = @wrappedStuff.render()
      @$el.append(tmp.el)
      return @el  
    
  
  class MultiFileView extends Backbone.Marionette.Layout
    el: "#codeViewsContainer"
    template: filesCodeTemplate
    regions: 
      filesList:  "#filesList"
      filesTree:  "#filesTree"
      console:    "#console"
    
    constructor:(options)->
      super options
      @settings = options.settings

    onRender:=>
      @$el.css('height':'700px')
      @$el.css('color': '#FF8900')
      
      #show files tree
      filesTreeView = new FilesTreeView
        collection: @model.pfiles
      @filesTree.show filesTreeView
      $(@filesTree.el).addClass("ui-layout-west")
      
      #show files list (tabs)
      filesListView = new FilesListView
        model: @model
        settings: @settings
      @filesList.show(filesListView)
      $(@filesList.el).addClass("ui-layout-center")
      
      #show console
      consoleView = new ConsoleView()
      @console.show consoleView
      #$(@console.el).addClass("ui-layout-south")
      
        
      @myLayout = @$el.layout({ applyDefaultStyles: true })
      #innerLayout = $(outerLayout.options.center.paneSelector ).layout()
      
      
  return CodeViewsLayoutContainer