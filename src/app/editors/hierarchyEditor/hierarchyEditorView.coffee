define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  appVent = require 'core/messaging/appVent'
  
  template =  require "text!./hierarchyEditorView.tmpl"
  require 'jquery_jstree'

  class HierarchyEditorView extends Backbone.Marionette.ItemView
    template: template
    tagName:  "ul"
    className: "hierarchyEditor"
    
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
      @$el.jstree
        "plugins" : ["themes","html_data","ui","crrm"],
        #"core" : { "initially_open" : [ "parts_1" ] }

    onResizeStart:=>
      
    onResizeStop:=>

    onRender:=>
      
    render:=>
      @isClosed = false
      @triggerMethod("before:render", @)
      @triggerMethod("item:before:render", @)
      
      @$el.html("")
      
      if @project?
        treeRoot = $('<ul>')
        partCounter=0
        createItem = (rootPart, rootEl)=>
          #rootEl = rootEl ? $('<ul>')
          for part in rootPart.children
            elem = $('<li>')
            elem.attr('id',"parts_#{partCounter}")
            if part.realClassName? #necessary workaround for "fake" classes (all of the parts are actually CSGBase instance) returned from web workers
              partClassName = part.realClassName
            else
              partClassName = part.__proto__.constructor.name
            partEntry = $('<a>').attr('href', "#").text(partClassName)
            partHide = $('<span>')
            partEntry.append partHide
            
            #partHide.css('right',"-50px")
            #partHide.append($('<i>').addClass("icon-eye-open"))
            #partHide.addClass("pull-right")
            
            elem.append(partEntry)
            #rootEl.append(elem)
            partCounter+=1
            rootEl.append(createItem(part,elem))
          return rootEl
        @$el.append(createItem(@project.rootAssembly,treeRoot))
      @bindUIElements()
      @triggerMethod("render", @)
      @triggerMethod("item:rendered", @)
      return @
      
    onClose:=>
      @_tearDownEventHandlers()
      @project = null
      
  return HierarchyEditorView