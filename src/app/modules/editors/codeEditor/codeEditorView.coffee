define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  
  filesCodeTemplate =  require "text!./codeEditorView.tmpl"
  
  FilesTreeView = require "./filesTreeView"
  FilesListView = require "./filesListView"
  ToolBarView   = require "./toolBarView"

  class CodeEditorView extends Backbone.Marionette.Layout
    template: filesCodeTemplate
    className: "codeEditor"
    regions: 
      filesList:  "#filesList"
      filesTree:  "#filesTree"
      toolBar  :  "#toolBar"
    
    events:
      "resize:start": "onResizeStart"
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      
    constructor:(options)->
      super options
      @settings = options.settings
    
    onDomRefresh:()=>
      @$el.parent().addClass("codeEditorContainer")
      
      $(@filesTree.el).addClass("ui-layout-west filesTreeContainer")
      $(@filesList.el).addClass("ui-layout-center")
      
      elHeight = @$el.parent().height()
      @$el.height(elHeight)
      @myLayout = @$el.layout( {
        applyDefaultStyles: true,
        center__childOptions: {
          center__paneSelector: "#tabContent"
          south__paneSelector: "#console"
          applyDefaultStyles: true
          size:"auto"
        }
      }
      )

    onResizeStart:=>
      console.log "resized start"
      console.log "old size: #{@$el.parent().height()}"
      console.log @$el.parent()
      
    onResizeStop:=>
      elHeight = @$el.parent().height()
      @$el.height(elHeight)
      #@myLayout.resizeAll()

    onRender:=>
      #show toolBar 
      toolBarView = new ToolBarView
      @toolBar.show(toolBarView)
      
      #show files tree
      filesTreeView = new FilesTreeView
        collection: @model.pfiles
        model: @model
      @filesTree.show filesTreeView
      
      #show files list (tabs)
      filesListView = new FilesListView
        collection: @model.pfiles
        settings: @settings
      @filesList.show(filesListView)
      
  return CodeEditorView