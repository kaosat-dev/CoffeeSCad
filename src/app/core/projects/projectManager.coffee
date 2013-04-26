define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  ModalRegion = require 'core/utils/modalRegion'
  
  Settings = require 'core/settings/settings'
  Project = require 'core/projects/project'
  ProjectBrowserView = require './projectBrowseView2'
  
  Compiler = require './compiler'
  
  class ProjectManager
    
    constructor:(options)->
      options = options or {appSettings:null}
      @appSettings = options.appSettings ? new Settings()
      @settings = @appSettings.getByName("General")
      @stores = options.stores ? null
      
      @vent = vent
      @project = null
      @compiler = new Compiler()
      
      @vent.on("project:new", @onNewProject)
      @vent.on("project:saveAs", @onSaveAsProject)
      @vent.on("project:save", @onSaveProject)
      @vent.on("project:load", @onLoadProject)
      @vent.on("project:loaded",@onProjectLoaded)
      @vent.on("project:compile",@compileProject)
      
      @appSettings.on("reset", @onAppSettingsChanged)
    
    onAppSettingsChanged:(model, attributes)=>
      @settings = @appSettings.getByName("General")
      @settings.on("change", @_onSettingsChanged)
            
    _onSettingsChanged:(settings, value)=> 
      mode = @settings.get("csgCompileMode")
      if mode is "onCodeChange" or mode is "onCodeChangeDelayed"
        if @project.isCompileAdvised
            @compileProject()
      
      autoSave = @settings.autoSave
      @_setupAutoSave()

    _setupProjectEventHandlers: =>
      @project.on("change", @onProjectChanged)
      @project.on("save", @onProjectSaved)
      @project.on("compiled", @onProjectCompiled)
      @project.on("compile:error",@onProjectCompileError)
    
    _tearDownProjectEventHandlers:=>
      @project.off("change",@onProjectChanged)
      @project.off("save",@onProjectSaved)
      @project.off("compiled", @onProjectCompiled)
      @project.off("compile:error",@onProjectCompileError)

    createProject:()->
      if @project?
        @_tearDownProjectEventHandlers()
        @project.compiler.project=null
        @project = null
        
      @project = new Project
        compiler:@compiler
      @project.addFile
        name: @project.get("name")+".coffee"
        content:"""
        myCube = new Cube({size:20}).color([0.9,0.5,0.1])
        assembly.add(myCube)
        """
      @project.addFile
        name: "config.coffee"
        content:""" """
      @project._clearFlags()
      @_setupProjectEventHandlers()
      @_setupAutoSave()
      
      return @project
    
    onProjectChanged:()=>
      switch @settings.get("csgCompileMode")
        when "onCodeChange"
          if @project.isCompileAdvised
            @compileProject()
        when "onCodeChangeDelayed"
          if @project.isCompileAdvised
            if @CodeChangeTimer
              clearTimeout @CodeChangeTimer
              @CodeChangeTimer = null
            callback=()=>
              @compileProject()
            @CodeChangeTimer = setTimeout callback, @settings.get("csgCompileDelay")*1000
            
    onProjectCompiled:=>
      console.log "project compile event dispatch"
      @vent.trigger("project:compiled",@project)
      
    onProjectCompileError:(compileResult)=>
      @vent.trigger("project:compile:error",compileResult)
       
    compileProject:=>
      console.log "compile project"
      @project.compile
        backgroundProcessing : @settings.get("csgBackgroundProcessing")
      
    onNewProject:()=>
      if @project.isSaveAdvised
        bootbox.dialog "Project is unsaved, you will loose your changes, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @createProject()
            @vent.trigger("project:created", @project)
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      else
        @createProject()
        @vent.trigger("project:created", @project) 
      
    onSaveAsProject:=>
      projectBrowserView = new ProjectBrowserView
        model: @project
        operation: "save"
        stores: @stores
      
      modReg = new ModalRegion({elName:"library",large:true})
      modReg.show projectBrowserView
    
    onSaveProject:=>
      if @project.rootFolder.sync is null and @project.dataStore is null
        projectBrowserView = new ProjectBrowserView
          model: @project
          operation: "save"
          stores: @stores
        modReg = new ModalRegion({elName:"library",large:true})
        modReg.show projectBrowserView
      else
        @project.save()
      
    onLoadProject:=>
      projectBrowserView = new ProjectBrowserView
        model: @project
        operation: "load"
        stores: @stores
      
      modReg = new ModalRegion({elName:"library",large:true})
      modReg.show projectBrowserView
      
    onProjectLoaded:(project)=>
      if @project?
        @_tearDownProjectEventHandlers()
        @project = null
      @project = project
      @project.compiler = @compiler
      @_setupProjectEventHandlers()
      
      if project.name != "autosave"
        @_setupAutoSave()
        @_memoizeCurrentProject()
      else
        project.dataStore=null
        project.rootFolder.sync=null
        originalName = localStorage.getItem("autosaveOriginalProjectName")
        console.log "setting autosavedProject name to original (#{originalName})"
        project.name = originalName
        @_setupAutoSave()
        @_memoizeCurrentProject()
        
      
    onProjectSaved:()=>
      if @settings.get("csgCompileMode") is "onSave"
        @compileProject()
      @_memoizeCurrentProject()
    
    _setupAutoSave:=>
      #checks if autosave is enabled, if yes, sets up
      if @autoSaveTimer?
        #cancel previously running autosave
        clearInterval(@autoSaveTimer)
        
      if @settings.autoSave
        console.log "setting up autosave"
        saveCallback = =>
          #FIXME: this brakes modularity (accessing a store directly), this should be done with a command
          #or something similarly decoupled
          console.log "autosaving"
          localStorage.setItem("autosaveOriginalProjectName",@project.name)
          @stores["browser"].autoSaveProject @project
        @autoSaveTimer = setInterval saveCallback, @settings.autoSaveFrequency*1000
    
    _handleAutoSave:=>
      #check if there is an autosaved project , if there is, ask user if he wants to reload
      autosavedProject = @stores["browser"].getProject("autosave")
      if autosavedProject?
        #there was an autosave, ie failure?
        showDialog = =>
          bootbox.dialog "An autosave file was detected, do you want to reload it?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @stores["browser"].loadProject("autosave").done ()=>
                try
                  @stores["browser"].deleteProject("autosave")
                catch error
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
        setTimeout showDialog, 800
        return true
      return false
    
    _memoizeCurrentProject:=>
      #store current project name + storage, to be able to auto reload it
      if @project.dataStore?
        console.log "Saving project #{@project.name}"
        localStorage.setItem("coffeescad_lastProjectStore",@project.dataStore.name)  
        localStorage.setItem("coffeescad_lastProjectName",@project.name)
      
    _handleReloadLast:=>
      if @settings.autoReloadLastProject is true
        #attempt to auto reload last project
        lastProjectName = localStorage.getItem("coffeescad_lastProjectName")
        if lastProjectName?
          storeName = localStorage.getItem("coffeescad_lastProjectStore")
          storeName = storeName.replace("Store","")
          console.log storeName
          console.log "please reload last project: #{lastProjectName} from #{storeName}"
          @stores[storeName].loadProject(lastProjectName)
          loadProj= =>
            @stores[storeName].loadProject(lastProjectName)
            
    start:=>  
      console.log "starting project manager"
      #first check if there are autosaves
      if @_handleAutoSave()
        return
      #no autosaves where found or user did not wish to reload them
      #next step: check if autoreload is true, and reload
      if @_handleReloadLast()
        return
     
        
      
  return ProjectManager
  