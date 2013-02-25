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
  

  class CodeEditorView extends Backbone.Marionette.Layout
    template: filesCodeTemplate
    regions: 
      filesList:  "#filesList"
      filesTree:  "#filesTree"
    
    events:
      "resize:start": "onResizeStart"
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      
    constructor:(options)->
      super options
      @settings = options.settings
    
    onDomRefresh:()=>
      console.log "dom refresh"
      elHeight = @$el.parent().height()
      #@$el.css('height':"#{elHeight}px")
      #@$el.css('color': '#FF8900')
      @$el.height(elHeight)
      $(@filesTree.el).addClass("ui-layout-west")
      $(@filesList.el).addClass("ui-layout-center")
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
      #show files tree
      filesTreeView = new FilesTreeView
        collection: @model.pfiles
      @filesTree.show filesTreeView
      
      #show files list (tabs)
      filesListView = new FilesListView
        collection: @model.pfiles
        settings: @settings
      @filesList.show(filesListView)
      
      
  return CodeEditorView