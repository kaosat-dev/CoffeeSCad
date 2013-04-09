define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  dataBoundViews = require 'core/utils/DataBoundViews'
  buildProperties = require 'core/utils/buildProperties'
  
  projectBrowserTemplate = require "text!./projectBrowser3.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())



  class ProjectBrowserViewModel extends Backbone.Model
    defaults:
      operation: "save"
      currentStore:  null
      project: null
      
    attributeNames: ['operation','currentStore','project']
    constructor:(options)->
      super options
      @stores = options.stores ? {}
      tmpCollection = new Backbone.Collection()
      for name, store of @stores
        #hack, to inject current, existing project to sub views (for saving only)
        tmpCollection.add store
      @stores =  tmpCollection
      
      
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    #ui: 
    #  projects: "#projects"

  
  class ProjectBrowserView extends Backbone.Marionette.Layout
    template: projectBrowserTemplate
    
    constructor:(options)->
      options.project = options.model
      delete options.model
      options.model = new ProjectBrowserViewModel(options)
      super options
      
      @modelBinder = new Backbone.ModelBinder()
      @bindings = 
        compiled: [{selector: '#validateOperationBtn', elAttribute: 'disabled', converter:=>(not (@model.currentStore is null))} ]
      
    onRender:->
      @modelBinder.bind(@model, @el, @bindings)
          
    onClose:=>
      @modelBinder.unbind()
      
      
  return ProjectBrowserView