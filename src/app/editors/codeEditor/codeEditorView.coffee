define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'core/messaging/appVent'
  
  filesCodeTemplate =  require "text!./codeEditorView.tmpl"
  
  FilesTreeView = require "./filesTreeView"
  FilesListView = require "./filesListView"


  class CodeEditorView extends Backbone.Marionette.Layout
    template: filesCodeTemplate
    className: "codeEditor"
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
      @$el.parent().addClass("codeEditorContainer")
      
      $(@filesTree.el).addClass("ui-layout-west filesTreeContainer")
      $(@filesList.el).addClass("ui-layout-center")
      
      elHeight = @$el.parent().height()
      @$el.height(elHeight)
      @myLayout = @$el.layout( {
        applyDefaultStyles: true,
        west__size:         220,
        west__minSize:      220,
        west__initClosed:   true,
        center__childOptions: {
          center__paneSelector: "#tabContent",
          south__paneSelector: "#console",
          applyDefaultStyles: true,
          #size:"auto"
          north__size: 'auto',
          south__size: 100,
          south__initClosed:   true
          
        }
      })
      
      elHeight = @$el.parent().height()
      @$el.height(elHeight)
      
      $("#codeArea").height(elHeight-40)
      $(".codeEditorBlock").height(elHeight-40)
      @myLayout.resizeAll()

    onResizeStart:=>
      console.log "resized start"
      console.log "old size: #{@$el.parent().height()}"
      console.log @$el.parent()
      
    onResizeStop:(ev,args)=>
      if args?
        elHeight = args.ui.size.height
      else
        elHeight = $("#codeEdit").outerHeight(false) #what the heck ?#FIXME:horrible hackery to get the different elements to resize correctly
        elHeight = $("#codeEdit").height()
      #console.log "elHeight", elHeight
      @$el.height(elHeight)
      #@$el.height("100")
      
      $("#codeArea").height(elHeight-40)
      $(".codeEditorBlock").height(elHeight-40)
      @myLayout.resizeAll()
      
      
      #hack
      vent.trigger("codeEditor:refresh",elHeight)

    onRender:=>
      #show files tree
      filesTreeView = new FilesTreeView
        collection: @model.rootFolder
        model: @model
      @filesTree.show filesTreeView
      
      #show files list (tabs)
      filesListView = new FilesListView
        collection: @model.rootFolder
        model: @model
        settings: @settings
      @filesList.show(filesListView)
    
    onClose:=>
      console.log "closing code editor"
      
  return CodeEditorView