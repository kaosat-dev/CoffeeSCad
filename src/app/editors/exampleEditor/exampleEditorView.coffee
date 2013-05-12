define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  appVent = require 'core/messaging/appVent'
  
  template =  require "text!./exampleEditorView.tmpl"


  class ExampleEditorView extends Backbone.Marionette.ItemView
    template: template
    tagName:  "ul"
    className: "exampleEditor"
    
    events:
      "resize:start": "onResizeStart"
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      
    constructor:(options)->
      super options
      @settings = options.settings
      @_setupEventHandlers()
    
    _setupEventHandlers: =>
      appVent.on("project:compiled",@onProjectCompiled)
    
    _tearDownEventHandlers:=>
      appVent.off("project:compiled",@onProjectCompiled)
      
    onProjectCompiled:(project)=>
      @project = project
      @render()
    
    onDomRefresh:()=>
      #apply any jquery or other plugins here, this is AFTER dom insertions, so its safe 
      #for example:
      #@$el.jstree
      #  "plugins" : ["themes","html_data","ui","crrm"],

    onResizeStart:=>
      
    onResizeStop:=>

    onRender:=>
      
    onClose:=>
      #don't forget to clean up !
      @_tearDownEventHandlers()
      @project = null
      
  return ExampleEditorView