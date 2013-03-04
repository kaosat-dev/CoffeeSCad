define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  PreProcessor = require "./preprocessor"
  CsgProcessor = require "./csg/processor"
  
  vent = require 'modules/core/vent'
  reqRes = require 'modules/core/reqRes'
  ModalRegion = require 'modules/core/utils/modalRegion'
  
  Settings = require 'modules/core/settings/settings'
  Project = require 'modules/core/projects/project'
  ProjectBrowserView = require './projectBrowseView'
  
  
  class ProjectManager
    
    constructor:(options)->
      options = options or {appSettings:null}
      @appSettings = options.appSettings ? new Settings()
      @settings = @appSettings.getByName("General")
      @connectors = options.connectors ? null
      @preProcessor = new PreProcessor()
      @csgProcessor = new CsgProcessor()
      
      @vent = vent
      @vent.on("project:new", @onNewProject)
      @vent.on("project:saveAs", @onSaveAsProject)
      @vent.on("project:save", @onSaveProject)
      @vent.on("project:load", @onLoadProject)
      @vent.on("project:loaded",@onProjectLoaded)
      @vent.on("project:compile",@compileProject)
      
      @appSettings.on("reset", @onAppSettingsChanged)
      @appSettings.on("change",@onAppSettingsChanged)
      
      @project = null
    
    onAppSettingsChanged:(model, attributes)=>
      @settings = @appSettings.getByName("General")

    createProject:()->
      @project = new Project()
      @project.createFile
        name: @project.get("name")
        content:"""
        #just a comment
        cube = new Cube({size:100}).color([0.9,0.5,0.1])
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
      @project.createFile
        name: "config"
        content:""" """
      @project.on("change",@onProjectChanged)
    
    onProjectChanged:()=>
      console.log "on project changed"
      switch @settings.get("csgCompileMode")
        when "onRequest"
          console.log ""
        when "onSaved"
          console.log ""
        when "onCodeChange"
          @compileProject()
        when "onCodeChangeDelayed"
          console.log "here"
          if @CodeChangeTimer
            clearTimeout @CodeChangeTimer
            @CodeChangeTimer = null
          callback=()=>
            @compileProject()
          @CodeChangeTimer = setTimeout callback, @settings.get("csgCompileDelay")*1000
      
    compileProject:()=> 
      start = new Date().getTime()
      
      backgroundProcessing = false
      if @settings?
        backgroundProcessing = @settings.get("csgBackgroundProcessing")
      
      try
        fullSource = @preProcessor.process(@project,false)
      catch error
        @project.trigger("compile:error",[error])
        return
        
      @csgProcessor.processScript fullSource,backgroundProcessing, (rootAssembly, partRegistry, error)=>
        if error?
          #console.log "CSG processing failed : #{error.msg} on line #{error.lineNumber} stack:"
          #console.log error.stack
          @project.trigger("compile:error",[error])
          return
          
        #@set({"partRegistry":window.classRegistry}, {silent: true})
        @project.bom = new Backbone.Collection()
        for name,params of partRegistry
          for param, quantity of params
            variantName = "Default"
            if param != ""
              variantName=""
            @project.bom.add { name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true } 
        
        @project.rootAssembly = rootAssembly
        end = new Date().getTime()
        console.log "Csg computation time: #{end-start}"
        @project.trigger("compiled",rootAssembly)

    onNewProject:()=>
      @createProject()
      
      #projectBrowserView = new ProjectBrowserView
      #  model: @project
      #  operation: "new"
      #  connectors: @connectors
      #
      #modReg = new ModalRegion({elName:"library",large:true})
      #modReg.show projectBrowserView
      if @project.dirty
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
        connectors: @connectors
      
      modReg = new ModalRegion({elName:"library",large:true})
      modReg.show projectBrowserView
    
    onSaveProject:=>
      #if project.pfiles.sync != null
      
      ###  
      projectBrowserView = new ProjectBrowserView
        model: @project
        operation: "save"
        connectors: @connectors
      ###
      
    onLoadProject:=>
      projectBrowserView = new ProjectBrowserView
        model: @project
        operation: "load"
        connectors: @connectors
      
      modReg = new ModalRegion({elName:"library",large:true})
      modReg.show projectBrowserView
      
    onProjectLoaded:(project)=>
      @project=project
      @project.on("change",@onProjectChanged)
      
  return ProjectManager
  