define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  
  filesTreeTemplate =  require "text!./filesTreeView.tmpl"
  
  fileTemplate = _.template($(filesTreeTemplate).filter('#fileTmpl').html())
  rootTemplate = _.template($(filesTreeTemplate).filter('#rootTmpl').html())
  
  
  class TreeView extends Backbone.Marionette.CompositeView
    template: fileTemplate
    tagName: "li"
    itemViewContainer: "ul",
    
    events:
      'dblclick .openFile' : "onFileOpenClicked"
    
    constructor:(options)->
      super options
      @collection = @model.nodes
    
    onFileOpenClicked:(ev)=>
      console.log @model.get("name")
      vent.trigger("file:OpenRequest",@model)
      
    
  class TreeRoot extends Backbone.Marionette.CompositeView
    template: rootTemplate
    itemView: TreeView
    tagName: "ul"
    className: "filesTree"
    
    constructor:(options)->
      super options
    
    onRender:->
      @$el.addClass("align-left")
  
  return TreeRoot
