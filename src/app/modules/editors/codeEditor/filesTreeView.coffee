define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  filesTreeTemplate =  require "text!./filesTree.tmpl"
  #testTemplate = require "text!./testTmpl.tmpl"
  
  class TreeView extends Backbone.Marionette.CompositeView
    template: filesTreeTemplate
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
    
  class TreeRoot_ extends Backbone.Marionette.CollectionView
    tagName: "ul"
    itemView: TreeView
    
    constructor:(options)->
      super options
    
    onRender:->
      @$el.addClass("align-left")
  
  class TreeRoot extends Backbone.Marionette.ItemView
    #template : testTemplate
    el: "#bloodyFuch"
      
    onRender:->
      @$el.addClass('blaze')
      @$el.css('height':'400px')
      @$el.css('color': '#FF8900')
      @myLayout = @$el.layout({ applyDefaultStyles: true })
      @myLayout.close("west")
  
  class WrapperTest extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      $ '<div/>',
          id: "bloodyFuch",
          "class": 'test',
        .appendTo('body')
        
      @wrappedStuff= new TreeRoot
        model: @model    
        collection: @collection
       
    render:()=>
      tmp = @wrappedStuff.render()
      
      console.log tmp.el
      @$el.append(tmp.el)
      console.log tmp.el
      return @el  
    
  return TreeRoot_
