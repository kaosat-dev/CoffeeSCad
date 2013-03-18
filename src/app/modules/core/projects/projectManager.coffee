define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  ModalRegion = require 'modules/core/utils/modalRegion'
  
  Settings = require 'modules/core/settings/settings'
  Project = require 'modules/core/projects/project'
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
      console.log "settings changed"
      mode = @settings.get("csgCompileMode")
      if mode is "onCodeChange" or mode is "onCodeChangeDelayed"
        console.log "blah"
        if @project.isCompileAdvised
            @compileProject()

    _setupProjectEventHandlers: =>
      @project.on("change",@onProjectChanged)
      @project.on("save",@onProjectSaved)
      @project.on("compiled", @onProjectCompiled)

    createProject:()->
      @project = new Project
        compiler:@compiler
      @project.addFile
        name: @project.get("name")+".coffee"
        content:"""
        #just a comment
        cube = new Cube({size:20}).color([0.9,0.5,0.1])
        assembly.add(cube)
        """
        content_3:"""
        #just a comment
        sphere = new Sphere({r:100,$fn:15}) 
        sphere2 = new Sphere({r:100,$fn:15}).translate([50,0,0])
        
        sphere.subtract(sphere2)
        assembly.add(sphere)
        """
        
        content_2:"""
        #just a comment
        class Body extends Part
          constructor:(options)->
            super options
            
            outShellRes = 15
            @union new Sphere({r:50,$fn:outShellRes}).color([0.9,0.5,0.1]).rotate([90,0,0])
        body = new Body()  
        assembly.add(body)
        """
        
        content_:"""
      #just a comment
      class Body extends Part
        constructor:(options)->
          super options
          
          outShellRes = 15
          @union new Sphere({r:50,$fn:outShellRes}).color([0.9,0.5,0.1]).rotate([90,0,0])
          
          sideIndent = new Sphere({r:30,$fn:15}).rotate([90,0,0])
          @subtract sideIndent.clone().translate([0,65,0])
          @subtract sideIndent.translate([0,-65,0])
          
          innerSphere = new Sphere({r:45,$fn:outShellRes}).color([0.3,0.5,0.8]).rotate([90,0,0])
          @subtract innerSphere
          
          c = new Circle({r:25,center:[10,50,20]})
          r = new Rectangle({size:10})
          hulled = hull(c,r).extrude({offset:[0,0,100],steps:25,twist:180}).color([0.8,0.3,0.1])
          hulled.rotate([0,90,90]).translate([35,-12,0])
          #
          @union hulled.clone()
          @union hulled.mirroredY()
      
      body = new Body()
      
      plane = Plane.fromNormalAndPoint([0, 1, 0], [0, 0, 0])
      #body.cutByPlane(plane)
      
      assembly.add(body)
        """
      @project.addFile
        name: "config.coffee"
        content:""" """
      @_setupProjectEventHandlers()
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
            
    onProjectSaved:()=>
      if @settings.get("csgCompileMode") is "onSave"
        @compileProject()
      @memoizeCurrentProject()
    
    onProjectCompiled:=>
      @vent.trigger("project:compiled")
       
    compileProject:=>
      @project.compile
        backgroundProcessing : @settings.get("csgBackgroundProcessing")
      
    onNewProject:()=>
      @createProject()
      if @project.isSaveAdvised
        bootbox.dialog "Project is unsaved, you will loose your changes, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @vent.trigger("project:loaded", @project) 
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      
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
      @project=project
      @project.compiler = @compiler
      @_setupProjectEventHandlers()
      @memoizeCurrentProject()
      
    memoizeCurrentProject:=>
      #store current project name + storage, to be able to auto reload it
      if @project.dataStore?
        console.log "Saving project"
        localStorage.setItem("coffeescad_lastProjectStore",@project.dataStore.name)  
        localStorage.setItem("coffeescad_lastProjectName",@project.name)
      
    reloadLast:=>
      if @settings.get("autoReloadLastProject") is true
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
        
        
      
  return ProjectManager
  