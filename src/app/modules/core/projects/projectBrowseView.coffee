define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  jstree = require 'jquery_jstree'
  
  vent = require '../vent'
  
  projectBrowserTemplate = require "text!./projectBrowser.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())
  
  
  class ProjectBrowserView extends Backbone.Marionette.Layout
    template:rootTemplate
    
    regions:
      projectStores: "#projectStores"
      projectFiles : "#projectFiles"
    
    ui:
      fileNameInput : "#fileNameInput"
      
    events:
      "click .newProject":   "onProjectNewRequested"
      "click .saveProject":  "onProjectSaveRequested"
      "click .loadProject":  "onProjectLoadRequested"

    constructor:(options) ->
      super options
      @operation = options.operation ? "save"
      @connectors = options.connectors ? {}
      
    serializeData:->
      operation: @operation
      name: @model.get("name")
     
    onRender:=>
      tmpCollection = new Backbone.Collection()
      for name, connector of @connectors
        tmpCollection.add connector
        
      @projectStores.show new ProjectsStoreView
        collection:tmpCollection
    
    onProjectNewRequested:=>
      console.log "project creation requested"
      
    onProjectSaveRequested:=>
      fileName = $(@ui.fileNameInput).val()
      vent.trigger("project:saveRequest", fileName)
      @.close()
      
    onProjectLoadRequested:=>
      fileName = $(@ui.fileNameInput).val()
      vent.trigger("project:saveRequest", fileName)
      @.close()
  
  
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
      
    constructor:(options)->
      super options
    
    onRender:->
      @model.getProjectsName(@onProjectsFetched)
      
    onProjectsFetched:(projectNames)=>
      console.log "projectNames #{projectNames}"
      console.log @
      for name in projectNames
        @ui.projects.append("<li><a href='#'>#{name}</a></li>")
    
    
  class ProjectsStoreView extends Backbone.Marionette.CompositeView
    template:projectStoreListTemplate
    itemView:StoreView
    
    ui: 
      treeTest: "#treeTest"
    
    onRenderOLD:->
      @ui.treeTest.jstree 
        "core":
          "animation":0
        "plugins" : ["html_data","ui","contextmenu","themeroller"]
        "html_data" : 
          "data" : """
          <li id='root'>
            <a href='#'>Root node</a>
            <ul><li><a href='#'>Child node</a></li></ul>
            <ul><li><a href='#'>Child node2</a></li></ul>
            <ul>
              <li>
                <a href='#'>Child node2</a>
                <ul>
                  <li><a href='#'>Child node2 sub 1</a></li>
                </ul>
              </li>
            </ul>
          </li>"""

  return ProjectBrowserView