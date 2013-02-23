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


  class MultiFileView extends Backbone.Marionette.Layout
    template: filesCodeTemplate
    regions: 
      filesList:  "#filesList"
      filesTree:  "#filesTree"
      console:    "#console"
    
    constructor:(options)->
      super options
      @settings = options.settings
    
    onDomRefresh:()=>
      elHeight = @$el.height()
      @$el.css('height':"#{elHeight}px")
      @$el.css('color': '#FF8900')
      
      $(@filesTree.el).addClass("ui-layout-west")
      $(@filesList.el).addClass("ui-layout-center")
      @myLayout = @$el.layout({ applyDefaultStyles: true })

    onRender:=>
      #show files tree
      filesTreeView = new FilesTreeView
        collection: @model.pfiles
      @filesTree.show filesTreeView
      
      #show files list (tabs)
      filesListView = new FilesListView
        collection: @model.pfiles
        settings: @settings
      @filesList.show(filesListView)
      
      #show console
      consoleView = new ConsoleView()
      @console.show consoleView
      #$(@console.el).addClass("ui-layout-south")
      
      #innerLayout = $(outerLayout.options.center.paneSelector ).layout()
      
  return MultiFileView