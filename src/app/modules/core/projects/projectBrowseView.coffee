define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  jstree = require 'jquery_jstree'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
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
      fileNameInput : "#fileName"
      projectThumbNail: "#projectThumbNail"
      
    events:
      "click .newProject":   "onProjectNewRequested"
      "click .saveProject":  "onProjectSaveRequested"
      "click .loadProject":  "onProjectLoadRequested"

    constructor:(options) ->
      super options
      @operation = options.operation ? "save"
      @connectors = options.connectors ? {}
      @vent = vent
      @vent.on("project:saved",()=>@close())
      @vent.on("project:loaded",()=>@close())
      
    serializeData:->
      operation: @operation
      name: @model.get("name")
     
    onRender:=>
      tmpCollection = new Backbone.Collection()
      for name, connector of @connectors
        #hack, to inject current, existing project to sub views (for saving only)
        connector.targetProject = @model
        tmpCollection.add connector
        
      @projectStores.show new ProjectsStoreView
        collection:tmpCollection
        model: @model
    
    onProjectNewRequested:=>
      console.log "project creation requested"
      
    onProjectSaveRequested:=>
      fileName = @ui.fileNameInput.val()
      vent.trigger("project:saveRequest", fileName)
      
      screenshotUrl = reqRes.request("project:getScreenshot")
      @ui.projectThumbNail.attr("src",screenshotUrl)
      
    onProjectLoadRequested:=>
      fileName = $(@ui.fileNameInput).val()
      vent.trigger("project:loadRequest", fileName)
  
  
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
    events:
      "click :checkbox" : "onStoreSelected"
      
    constructor:(options)->
      super options
      #hack
      @selected = false
      vent.on("project:saveRequest",@onSaveRequested)
    
    onStoreSelected:()=>
      @selected = true
    
    onSaveRequested:(fileName)=>
      if @selected
        #console.log "save to #{fileName} requested"
        if @model.targetProject?
          @model.targetProject.set("name",fileName)
          @model.targetProject.pfiles.at(0).set("name",fileName)
          @model.saveProject(@model.targetProject)
    
    onRender:->
      @model.getProjectsName(@onProjectsFetched)
      
    onProjectsFetched:(projectNames)=>
      #console.log "projectNames #{projectNames}"
      #console.log @
      for name in projectNames
        @ui.projects.append("<li><a href='#'>#{name}</a></li>")
    
    
  class ProjectsStoreView extends Backbone.Marionette.CompositeView
    template:projectStoreListTemplate
    itemView:StoreView
    
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