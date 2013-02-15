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
  
  Project = require 'modules/core/projects/project'
  ProjectBrowserView = require './projectBrowseView'
  
  
  class ProjectManager
    
    constructor:(connectors)->
      @connectors = connectors ? null
      @vent = vent
      @vent.on("project:new", @onNewProject)
      @vent.on("project:saveAs", @onSaveAsProject)
      @vent.on("project:save", @onSaveProject)
      @vent.on("project:load", @onLoadProject)
      @vent.on("project:loaded",@onProjectLoaded)

    createProject:()->
      @project = new Project({"settings": @settings}) #settings : temporary hack
      @project.createFile
        name: @project.get("name")
        content:"""
        #some comment
        class Body extends Part
          constructor:(options)->
            super options
            outShellRes = 20
            @union new Sphere({r:50,$fn:outShellRes}).color([0.9,0.5,0.1]).rotate([90,0,0])
        
        body = new Body()
        assembly.add(body)
        """

    compileProject:()-> 
      compile:()=>
        doCompile=()=>
          start = new Date().getTime()
          
          backgroundProcessing = false
          if @settings?
            backgroundProcessing = @settings.get("csgBackgroundProcessing")
          
          @preProcessor = new PreProcessor()
          fullSource = @preProcessor.process(@,false)
          @csgProcessor = new CsgProcessor()
          @csgProcessor.processScript fullSource,backgroundProcessing, (rootAssembly, partRegistry, error)=>
            if error?
              console.log "CSG processing failed : #{error.msg} on line #{error.lineNumber} stack:"
              console.log error.stack
              throw error.msg
            #@set({"partRegistry":window.classRegistry}, {silent: true})
            console.log  partRegistry 
            @bom = new Backbone.Collection()
            for name,params of partRegistry
              for param, quantity of params
                variantName = "Default"
                if param != ""
                  variantName=""
                
                @bom.add { name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true } 
            
            @rootAssembly = rootAssembly
            console.log "triggering compiled event"
            end = new Date().getTime()
            console.log "Csg computation time: #{end-start}"
            @trigger("compiled",rootAssembly)
        
        
      switch @settings.get("csgCompileMode")
        when "onRequest"
          console.log ""
        when "onSaved"
          console.log ""
        when "onCodeChange"
          doCompile()
        when "onCodeChangeDelayed"
          if @CodeChangeTimer
            clearTimeout @CodeChangeTimer
            @CodeChangeTimer = null
          callback=()=>
            doCompile()
          @CodeChangeTimer = setTimeout callback, @settings.get("csgCompileDelay")*1000
      
      
    
         

    onNewProject:()=>
      @project = new Project()
      
      projectBrowserView = new ProjectBrowserView
        model: @project
        operation: "new"
        connectors: @connectors
      
      modReg = new ModalRegion({elName:"library",large:true})
      modReg.show projectBrowserView
      
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
      
  return ProjectManager