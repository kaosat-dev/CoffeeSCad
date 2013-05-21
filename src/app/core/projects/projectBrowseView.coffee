define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  contextMenu = require 'contextMenu'
  require 'marionette'
  require 'modelbinder'
  require 'pickysitter'
  require 'jquery_sscroll'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  
  projectBrowserTemplate = require "text!./projectBrowser.tmpl"
  rootTemplate = $(projectBrowserTemplate).filter('#projectBrowserTmpl')
  projectStoreListTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreListTmpl').html())
  projectStoreTemplate = _.template($(projectBrowserTemplate).filter('#projectStoreTmpl').html())

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
      
      
  class StoreView extends Backbone.Marionette.ItemView
    template:projectStoreTemplate
    ui: 
      projects: "#projects"
      
    events:
      "mousedown .projectSelector" : "onProjectSelected"
      "click .deleteProject": "onProjectDeleteRequest"
      "click .renameProject": "onProjectRenameRequest"
      "click .exportStore" : "onStoreExportRequested"
      
    triggers:
      "click .accordion-heading": "store:selected" 
    
    templateHelpers:
      repairRequired:->
        if @isRepairRequired is true
          return true
        else 
          return false
      
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
    
    onStoreExportRequested:=>
      #TODO: cleanup
      console.log "store #{@model.name} EXPORT requested"
      if not @packedDataUrl?
        console.log "generating"
        packedDataUrl = @model.dumpAllProjects()
      else
        packedDataUrl = @packedDataUrl
      
      if packedDataUrl != null
        console.log "packedDataUrl not null"
        if not @packedDataUrl?
          fileName = "CoScadStoreExport.zip"
          #$(".exportStore").popover
          #  html:true
          #  content: """<a href="totot>Download Ready</a>"""
          @packedDataUrl = packedDataUrl
          $(".exportStore").prop("download", "#{fileName}")
          $(".exportStore").prop("href", packedDataUrl)
          #$(".exportStore").prop("target", "_blank")
      return true  
    
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
          @model.deleteProject(@selectedModelName).done(onDeleted)
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
        @model.getProjectFiles(@selectedModelName).done(onFilesFetched)
      
      onReallyRename=(fileName)=>
        console.log "renaming to #{fileName}"
        projectToSave = @selectedModelName
        projectNameExists = @model.getProject(fileName)
        if projectNameExists?
          bootbox.dialog "A project called #{fileName} already exists, overwrite?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @model.renameProject(projectToSave, fileName).done(()=>onRenameOk(fileName))
              
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
         else
           @model.renameProject(projectToSave, fileName).done(()=>onRenameOk(fileName))
      
      bootbox.prompt "New name","Cancel","Rename",
        (result) =>
          if result?
            onReallyRename(result)
        ,"#{@selectedModelName}"

    
    onStoreSelectToggled:()=>
      if @selected
        header = @$el.find(".store-header")
        header.toggleClass('store-header-activated')
        #header.addClass('alert-info')
        
      else
        header = @$el.find(".store-header")
        header.toggleClass('store-header-activated')
        #header.removeClass('alert-info')
     
    onProjectSelected:(e)=>
      @trigger("store:selected")
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
    
    onRender:->
      console.log "getting projects from #{@model.name}"
      @model.getProjectsName(@onProjectsFetched)
      #modelBinding
      @modelBinder.bind(@model, @el, @bindings)
      
    onProjectsFetched:(projectNames)=>
      #console.log "projectNames #{projectNames}"
      #console.log @
      for name in projectNames
        @ui.projects.append("<li><a id='#{@model.name}#{name}' class='projectSelector' href='#' data-toggle='context' data-target='##{@model.name}ProjectContextMenu'>#{name}</a></li>")
          
      @delegateEvents()
      @ui.projects.slimScroll({size:"10px";height:"100px",alwaysVisible: true})
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