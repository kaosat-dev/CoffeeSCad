define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  require 'marionette'
  require 'modelbinder'
  require 'pickysitter'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  
  projectBrowserTemplate = require "text!./projectBrowser2.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())
  
  projectListTemplate = _.template($(projectBrowserTemplate).filter('#projectListTmpl').html())
  projectTemplate = _.template($(projectBrowserTemplate).filter('#projectTmpl').html())

  debug = false
  
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
      @stores = options.stores ? {}
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
      for name, store of @stores
        #hack, to inject current, existing project to sub views (for saving only)
        store.targetProject = @model
        tmpCollection.add store
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
          @model.addFile
            name:".thumbnail.png"
            content:screenshotUrl
        $.when(screenshotPromise).done(doScreenShotRes)
        
      else if @operation is "load"
        $(@ui.fileNameInput).attr("readonly", "readonly")
      #$(@ui.errorConsole).alert()
      #$(@ui.errorConsole).css("z-index",12000)
      #@projectStores.currentView.on("project:selected", ()=>console.log "vgsdmflsfsdfsdfdsf")
    
    
    onProjectSelected:(projectName)=>
      #hack
      onProjectFilesResponse=(entries)=>
        @ui.projectFiles.html("<ul></ul>")
        for name in projectNames
          @ui.projectFiles.append("<li><a href='#' >#{name}  </a></li>")
        @delegateEvents()
        @ui.projectFiles.slimScroll({size:"10px";height:"300px",alwaysVisible: true})
      
      $(@ui.fileNameInput).val(projectName)
      
    onProjectSaveRequested:=>
      fileName = @ui.fileNameInput.val()
      vent.trigger("project:saveRequest", fileName)
      
    onProjectLoadRequested:=>
      fileName = $(@ui.fileNameInput).val()
      if @model.isSaveAdvised
        bootbox.dialog "Project is unsaved, you will loose your changes, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            
            setTimeout ( =>
              vent.trigger("project:loadRequest", fileName)
              @close()
            ), 10
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
      
  
  
  class ProjectView extends Backbone.Marionette.ItemView
    template: projectTemplate
    
    constructor:(options)->
      @store = options.store
      
    
    onProjectDeleteRequest:=>
      #FIXME: YUCK CODE
      bootbox.dialog "Are you sure you want to delete <b>#{@selectedModelName}</b> ? There is no going back!", [
        label: "Ok"
        class: "btn-inverse"
        callback: =>
          onDeleted= =>
            #console.log "#{@model.name}#{@selectedModelName}"
            #console.log $("##{@model.name}#{@selectedModelName}")
            $("##{@model.name}#{@selectedModelName}").parent().remove()
            $("#projectFilesList").html("")
          @store.deleteProject(@selectedModelName).done(onDeleted)
      ,
        label: "Cancel"
        class: "btn-inverse"
        callback: ->
      ]
      
    onProjectRenameRequest:()=>
      onRenameOk=(fileName)=>
        $("##{@model.name}#{@selectedModelName}").text("#{fileName}")
        $("##{@model.name}#{@selectedModelName}").attr("id",fileName)
        @selectedModelName = fileName
        
        onFilesFetched=(files)=>
          $("#projectFilesList").html("")
          for file in files
            fullName = file.split('.')
            ext = fullName.pop()
            $("#projectFilesList").append("<tr><td>#{file}</td><td>#{ext}</td></tr>")
        @store.getProjectFiles(@selectedModelName).done(onFilesFetched)
      
      onReallyRename=(fileName)=>
        console.log "renaming to #{fileName}"
        projectToSave = @selectedModelName
        projectNameExists = @model.getProject(fileName)
        if projectNameExists?
          bootbox.dialog "A project called #{fileName} already exists, overwrite?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @store.renameProject(projectToSave, fileName).done(()=>onRenameOk(fileName))
              
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
         else
           @store.renameProject(projectToSave, fileName).done(()=>onRenameOk(fileName))
      
      bootbox.prompt "New name","Cancel","Rename",
        (result) =>
          if result?
            onReallyRename(result)
        ,"#{@selectedModelName}"
    
    onProjectSelected:(e)=>
      @trigger("store:selected",@store)
      e.preventDefault()
      projectName = $(e.currentTarget).attr("id")
      projectName= projectName.split("#{@model.name}").pop()
      @selectedModelName = projectName
      
      vent.trigger("project:selected",projectName)
      @trigger("project:selected", @model)
      
      onFilesFetched=(files)=>
        $("#projectFilesList").html("")
        for file in files
          fullName = file.split('.')
          ext = fullName.pop()
          $("#projectFilesList").append("<tr><td>#{file}</td><td>#{ext}</td></tr>")
      
      @model.getProjectFiles(projectName).done(onFilesFetched)
      
      #fetch thumbnail
      try
        onThumbNailFetched = (imageUrl)=>
          $("#thumbNail").html("""<img id="projectThumbNail" class="img-rounded"/>""")
          $("#projectThumbNail").attr("src", imageUrl)
          $("#thumbNail").removeClass("hide")
        $("#thumbNail").removeClass("hide")  
        $("#thumbNail").html("""<div style="height:100%;line-height:100px;">&nbsp &nbsp<i class="icon-spinner icon-spin icon-large"></i> Loading</div>""")
        @model.getThumbNail(projectName).done(onThumbNailFetched)
      catch error
      
    
    onSaveRequested:(fileName)=>
      if @selected
        console.log "save to #{fileName} requested"
        projectToSave = @model.targetProject
        projectNameExists = @model.getProject(fileName)
        if projectNameExists?
          bootbox.dialog "A project called #{fileName} already exists, overwrite?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @model.saveProject(projectToSave,fileName)
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
        else
          if projectToSave?
            @model.saveProject(projectToSave,fileName)
    
    onLoadRequested:(fileName)=>
      if @selected
        #console.log "load requested from #{@model.name}"
        @model.loadProject(fileName)
    
    
    
    
  class FolderView extends Backbone.Marionette.CompositeView
 
     
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
      
    events:
      #"mousedown .projectSelector" : "onProjectSelected"
      #"click .deleteProject": "onProjectDeleteRequest"
      #"click .renameProject": "onProjectRenameRequest"
      "click .exportStore" : "onStoreExportRequested"
      "click .store-header": "onStoreSelected"
      
    #triggers:
    #  "click .store-header": "store:selected" 
    
    constructor:(options)->
      super options
      selectable = new Backbone.PickySitter.Selectable(@)
      _.extend(this, selectable)
      
      @on("selected", @onStoreSelectToggled)
      @on("deselected",@onStoreSelectToggled)
      
      @selectedModelName = null
      vent.on("project:newRequest", @onCreateRequested)
      vent.on("project:saveRequest",@onSaveRequested)
      vent.on("project:loadRequest",@onLoadRequested)
      
      @bindings = 
        loggedIn: [{selector: '.storeConnection', elAttribute: 'hidden'} ]
      
      @modelBinder = new Backbone.ModelBinder()
    
    onStoreSelected:=>
      @trigger("store:selected")
    
    onStoreExportRequested:(ev)=>
      #console.log "store #{@model.name} EXPORT requested"
      $(".exportStore > i").removeClass("icon-download-alt")
      $(".exportStore > i").addClass("icon-spinner icon-spin")
      
      packedDataUrl = @model.dumpAllProjects()
      
      if packedDataUrl != null
        fileName = "CoScadStoreExport.zip"
        if $(".exportStore").prop("download") != "#{fileName}"
          @packedDataUrl = packedDataUrl
          $(".exportStore").prop("download", "#{fileName}")
          $(".exportStore").prop("href", packedDataUrl)
      $(".exportStore > i").removeClass("icon-spinner icon-spin")
      $(".exportStore > i").addClass("icon-download-alt")
      
      return true
    
    onStoreSelectToggled:()=>
      if @selected
        console.log "#{@model.name} selected"
        @model.getProjectsName(@onProjectsFetched)
        header = @$el.find(".store-header")
        header.toggleClass('store-header-activated')
        
      else
        header = @$el.find(".store-header")
        header.toggleClass('store-header-activated')
      
      return true
    
    onRender:->
      console.log "getting projects from #{@model.name}"
      #@model.getProjectsName(@onProjectsFetched)
      #modelBinding
      #@modelBinder.bind(@model, @el, @bindings)
    
    onSaveRequested:(fileName)=>
      if @selected
        console.log "save to #{fileName} requested"
        projectToSave = @model.targetProject
        projectNameExists = @model.getProject(fileName)
        if projectNameExists?
          bootbox.dialog "A project called #{fileName} already exists, overwrite?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @model.saveProject(projectToSave,fileName)
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
        else
          if projectToSave?
            @model.saveProject(projectToSave,fileName)
      
      
    onProjectsFetched:(projectNames)=>
      #console.log "projectNames #{projectNames}"
      #console.log @
      @rootFolderCollection = new Backbone.Collection()
      
      ### 
      for projectName in projectNames
        projectFolder = new Backbone.Model()
        @rootFolderCollection.add( projectFolder ) 
      
      projectsView = new ProjectsListView
        collection: @rootFolderCollection
      ###  
      #@projectStores.show projectsStoreView
      
      
      
      targetElem = $("#projects")#@ui.projects 
      targetElem.html("")
      for name in projectNames
        targetElem.append("""<li class='projectBlock'>
          <div class="flip">
            <div class="front">
              <table>
                <thead>
                  <tr>
                    <th> 
                      <div class="titleContainer">
                      <a id='#{@model.name}#{name}' class='projectSelector' href='#' data-toggle='context' data-target='##{@model.name}ProjectContextMenu'>#{name}</a>
                      </div>
                    </th>
                  </tr>
                </thead>
              
              </table>
              
            </div>
            <div class="back">
              Some text here
            </div>
          </div>
          </li>""")
      
      targetElem.on("click",(event)=>
        console.log "$(event.target)", $(event.target)
        console.log "closest", $(event.target).parent()
        $(event.target).parent().toggleClass("flipped")
        #@onProjectSelected($(event.target).closest("li").att("id")
      )
      #cache images with new Image()
      
      @delegateEvents()
      height = 400#targetElem.height()
      console.log "elem height", height
      targetElem.slimScroll({size:"10px";height:height+"px",alwaysVisible: true})
      #@$el.find('[rel=tooltip]').tooltip({'placement': 'right'})
    
    onClose:->
      #clean up events
      vent.off("project:saveRequest",@onSaveRequested)
      vent.off("project:loadRequest",@onLoadRequested)
      vent.off("store:selected",@onStoreSelected)
      @modelBinder.unbind()
      
  class ProjectsStoreView extends Backbone.Marionette.CompositeView
    template:projectStoreListTemplate
    itemView:StoreView
    
    constructor:(options)->
      super options
      singleSelect = new Backbone.PickySitter.SingleSelect(@itemViewContainer)
      _.extend(this, singleSelect)
      
      @currentStore = null
      @on("itemview:project:selected",@onProjectSelected)
      @on("itemview:store:selected" ,  @onStoreViewSelected)
    
    onProjectSelected:(childView)=>
      @trigger("project:selected")
      
    onStoreViewSelected:(childView)=>
      @currentStore = childView.model
      @select(childView)
      
      
  return ProjectBrowserView2