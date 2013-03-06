define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  
  projectBrowserTemplate = require "text!./projectBrowser2.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())

  
  class ProjectBrowserView2 extends Backbone.Marionette.Layout
    template:rootTemplate
    
    regions:
      projectStores: "#projectStores"
      projectFiles : "#projectFiles"
    
    ui:
      fileNameInput : "#fileName"
      thumbNail: "#thumbNail"
      projectThumbNail: "#projectThumbNail"
      validationButton: "#validateOperationBtn"
      errorConsole: "#errorConsole"
      storesContainer: "#storesContainer"
      
      projectFiles:"#projectFiles"
      
    events:
      "click .saveProject":  "onProjectSaveRequested"
      "click .loadProject":  "onProjectLoadRequested"
      
    constructor:(options) ->
      super options
      console.log "options"
      console.log options.operation
      @operation = options.operation ? "save"
      @connectors = options.connectors ? {}
      @vent = vent
      @vent.on("project:created",@onOperationSucceeded)
      @vent.on("project:saved",@onOperationSucceeded)
      @vent.on("project:loaded",@onOperationSucceeded)
      @vent.on("project:selected",@onProjectSelected)
      
    serializeData:->
      operation: @operation
      name: @model.get("name")
     
    onRender:=>
      tmpCollection = new Backbone.Collection()
      for name, connector of @connectors
        #hack, to inject current, existing project to sub views (for saving only)
        connector.targetProject = @model
        tmpCollection.add connector
      @stores =  tmpCollection
      
      projectsStoreView = new ProjectsStoreView
        collection:tmpCollection
        model: @model
      @projectStores.show projectsStoreView
        
      if @operation is "save"
        screenshotPromise = reqRes.request("project:getScreenshot")
        doScreenShotRes=(screenshotUrl)=>
          @ui.projectThumbNail.attr("src",screenshotUrl)
          @ui.thumbNail.removeClass("hide")
          @model.createFile
            name:".thumbnail"
            content:screenshotUrl
            ext:"png"  
        $.when(screenshotPromise).done(doScreenShotRes)
        
      else if @operation is "load"
        $(@ui.fileNameInput).attr("readonly", "readonly")
      #$(@ui.errorConsole).alert()
      #$(@ui.errorConsole).css("z-index",12000)
    
    onProjectSelected:(projectName)=>
      #hack
      onProjectFilesResponse=(entries)=>
        @ui.projectFiles.html("<ul></ul>")
        for name in projectNames
          @ui.projectFiles.append("<li><a href='#' >#{name}  </a></li>")
        @delegateEvents()
        @ui.projectFiles.slimScroll({size:"10px";height:"300px",alwaysVisible: true})
      
      
      $(@ui.fileNameInput).val(projectName)
      ### 
      console.log "connector collection"
      console.log @stores
      console.log "current project: #{projectName}"
      currentConnector = @stores.get("projectName")
      currentConnector.getProjectFiles(fileNameInput,onProjectFilesResponse)
      ###
      
    onProjectSaveRequested:=>
      fileName = @ui.fileNameInput.val()
      vent.trigger("project:saveRequest", fileName)
      
      #most of our job is done, disable the view
      @close()
      #@ui.validationButton.attr("disabled",true)
      #@projectStores.close()
      #@ui.storesContainer.hide()
      
    onProjectLoadRequested:=>
      fileName = $(@ui.fileNameInput).val()
      if @model.dirty
        bootbox.dialog "Project is unsaved, you will loose your changes, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            
            setTimeout ( =>
              vent.trigger("project:loadRequest", fileName)
              @close()
            ), 10
            ###
            vent.trigger("project:loadRequest", fileName)
            @close()###
            #most of our job is done, disable the view
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      else
        vent.trigger("project:loadRequest", fileName)
        #most of our job is done, disable the view
        @close()
       
    onOperationSucceeded:=>
      @close()
      
    onClose:->
      #clean up events
      @vent.off("project:saved",@onOperationSucceeded)
      @vent.off("project:loaded",@onOperationSucceeded)
      @vent.off("project:selected",(id)=>$(@ui.fileNameInput).val(id))
      
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
      
    events:
      "click .accordion-heading" : "onStoreSelected"
      "click .projectSelector" : "onProjectSelected"
     
    constructor:(options)->
      super options
      #hack
      @selected = false
      vent.on("project:newRequest", @onCreateRequested)
      vent.on("project:saveRequest",@onSaveRequested)
      vent.on("project:loadRequest",@onLoadRequested)
      vent.on("connector:selected", @onStoreSelected)
      
      #testConverter = (direction, value)->
      testConverter = ()=>
        return @model.get("name")+"30"
      testConverter2 = ()=> 
        if @model.get("loggedIn") is true
          return "hide"
        else 
          return ""
      testConverter3 = ()=> 
        return true
      testConverter4 = ()=> 
        return (not @model.get("loggedIn"))
      
      @bindings = {
        loggedIn: [{selector: '.connectorConnection', elAttribute: 'hidden'} ]
      }
      
      #bindings = {loggedIn: [{selector: '[class=connectorConnection]', elAttribute: 'class'},"[name=loggedIn]"]}
      @modelBinder = new Backbone.ModelBinder()
    
    onStoreSelected:(name)=>
      if name.currentTarget?
        if @selected
          @selected = false
          header = @$el.find(".connector-header")
          header.removeClass('alert-info')
        else
          @selected = true
          header = @$el.find(".connector-header")
          header.addClass('alert-info')
          vent.trigger("connector:selected",@model.get("name"))
      else
        if name != @model.get("name")
          @selected = false
          header = @$el.find(".connector-header")
          header.removeClass('alert-info')
        else
          @selected = true
          header = @$el.find(".connector-header")
          header.addClass('alert-info')
    
    onProjectSelected:(e)=>
      e.preventDefault()
      id = $(e.currentTarget).attr("id")
      vent.trigger("project:selected",id)
      
      vent.trigger("connector:selected",@model.get("name"))
      @trigger("project:selected", @model)
      
    
    onCreateRequested:(fileName)=>
      if @selected
        @model.createProject(fileName)
    
    onSaveRequested:(fileName)=>
      if @selected
        #console.log "save to #{fileName} requested"
        projectToSave = @model.targetProject
        if projectToSave?
          projectToSave.rename(fileName)
          @model.saveProject(projectToSave)
    
    onLoadRequested:(fileName)=>
      console.log "load requested"
      if @selected
        @model.loadProject(fileName)
    
    onRender:->
      @model.getProjectsName(@onProjectsFetched)
      #modelBinding
      @modelBinder.bind(@model, @el, @bindings)
      
    onProjectsFetched:(projectNames)=>
      #console.log "projectNames #{projectNames}"
      #console.log @
      for name in projectNames
        @ui.projects.append("<li><a id=#{name} class='projectSelector' href='#' data-toggle='context' data-target='#context-menu'>#{name}  </a></li>")
          
      @delegateEvents()
      @ui.projects.slimScroll({size:"10px";height:"100px",alwaysVisible: true})
      @$el.find('[rel=tooltip]').tooltip({'placement': 'right'})
    
    onClose:->
      #clean up events
      vent.off("project:saveRequest",@onSaveRequested)
      vent.off("project:loadRequest",@onLoadRequested)
      vent.off("connector:selected",@onStoreSelected)
      @modelBinder.unbind()
      
  class ProjectsStoreView extends Backbone.Marionette.CompositeView
    template:projectStoreListTemplate
    itemView:StoreView
    
    constructor:(options)->
      super options
      @currentStore = null
      @on("itemview:project:selected",@toto)
    
    toto:(childView, connector)=>
      console.log connector
    
      
  ###    
  SomeModel = Backbone.Model.extend(
    defaults:
      firstName: "Bob"
      lastName: "Morane"
      totalYears: 25
      age: 1
      isOk: true

    calculateYearsLeft: ->
      console.log "it is a kind of magic"
      console.log this
      @get("totalYears") - @get("age")
  )
  model = new SomeModel()
  
  bindings =
    firstName: "[name=firstName]"
    lastName: [
      selector: "[name=lastName]"
    ,
      selector: "[name=operatorSelectEl]"
    ]
    age: "[name=age]"
    isOk: "[name=isOk],[name=isChecked]"
    yearsLeft: [
      selector: "[name=yearsLeft]"
      converter: model.calculateYearsLeft
    ]

  model.bind "change", ->
    $("#modelData").html JSON.stringify(model.toJSON())

  ViewClass = Backbone.View.extend(
    _modelBinder: `undefined`
    initialize: ->
      @_modelBinder = new Backbone.ModelBinder()

    close: ->
      @_modelBinder.unbind()

    render: ->
      html = "<div id=\"welcome\"> Welcome, <span name=\"firstName\"></span> <span name=\"lastName\"></span><br><br>Edit your information:<input type=\"text\" name=\"firstName\"/><input type=\"text\" name=\"lastName\"/><input type=\"number\" name=\"age\" min=\"1\" max=\"5\"/><input type=\"text\" name=\"yearsLeft\"/><select name=\"operatorSelectEl\">      <option value=\"Dan\">Dan</option>      <option value=\"Eli\">Eli</option>      <option value=\"Frank\">Frank</option></select><input type=\"radio\" name=\"isOk\" value=\"yes\"><input type=\"checkbox\" name=\"isChecked\" checked></div>"
      @$el.html html
      @_modelBinder.bind model, @el, bindings
      this
  )
  view = new ViewClass()
  $("#viewContent").append view.render().$el
  ###    
      
  return ProjectBrowserView2