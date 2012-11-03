define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  
  CodeEditorView = require "views/codeView"
  MainMenuView = require "views/menuView"
  ProjectView = require "views/projectsview"
  SettingsView = require "views/settingsView"
  MainContentLayout = require "views/mainContentView"
  ModalRegion = require "views/modalRegion"
  {LoadView, SaveView} = require "views/fileSaveLoadView"
  AlertView = require "views/alertView"
  GlThreeView = require "views/glThreeView"
  {Library,Project,ProjectFile} = require "modules/project"

  Settings = require "modules/settings"
  CsgProcessor    = require "modules/csg.processor"
  CsgStlExporterMin     = require "modules/csg.stlexporter"

  
  
  ###############################

  testcode = 
  """
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
  
  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 25)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10, resolution:12})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)

res = thing.render().union(thing2.render().mirroredX().color([0.2,0.5,0.6]))
res= res.rotateX(37)
res= res.rotateZ(190)
res= res.translate([0,0,100])
return res
  """

  app = new marionette.Application
    root: "/opencoffeescad"
      
  app.addRegions
    navigationRegion: "#navigation"
    mainRegion: "#mainContent"
    statusRegion: "#statusBar"
    modal: ModalRegion
    alertModal: ModalRegion
    
  app.on "start", (opts)->
    console.log "App Started"
    $("[rel=tooltip]").tooltip
      placement:'bottom' 
    
  app.on "initialize:after", ->
    console.log "after init"
    
    ###fetch all settings###
   
  app.addInitializer (options)->
    exporter = new CsgStlExporterMin()
    
    @settings = new Settings()
    @settings.fetch()
    
    @lib  = new Library()
    @lib.fetch()
    
    @project = new Project({name:'TestProject'})  
    @mainPart = new ProjectFile
        name: "mainPart"
        ext: "coscad"
        content: testcode    
    @project.add @mainPart
    ###
    TODO: replace this hack with an actual reload of the LATEST project
    if @lib.length > 0
      @project = @lib.at(0)
      name = @project.get("name")
      @project = @lib.fetch({id:name})
      @mainPart = @project.pfiles.at(0)
      @project.add @mainPart
    else
      @project = new Project({name:'TestProject'})  
      @mainPart = new ProjectFile
        name: "mainPart"
        ext: "coscad"
        content: testcode    
      @project.add @mainPart
    ###
    
    ###############
    @csgProcessor = new CsgProcessor()
    CsgStlExporterMin = require "modules/csg.stlexporter"
    
    stlexport=()=>
      stlExp = new CsgStlExporterMin @mainPart.csg
      blobUrl = stlExp.export()
      @vent.trigger("stlGenDone", blobUrl)
    
    @vent.bind("downloadStlRequest", stlexport)

      
    ################  
    @codeEditorView = new CodeEditorView
      model: @mainPart 
      settings: @settings.at(2)
    @mainMenuView = new MainMenuView
      collection: @lib
    @projectView = new ProjectView
      collection:@lib
    @glThreeView = new GlThreeView
      model: @mainPart
      settings: @settings.at(1)
      
    @mainContentLayout = new MainContentLayout
    @mainRegion.show @mainContentLayout
    @mainContentLayout.edit.show @codeEditorView
    @mainContentLayout.gl.show @glThreeView
    
    @navigationRegion.show @mainMenuView
    #@statusRegion.show @projectView
    
    @alertModal.el= alertmodal
    @modal.app = @
    
    saveProject= (params) =>
      #console.log("Saving part to file : #{params}")
      foundProjects = @lib.get(params)
      if foundProjects?
        console.log "project exists"
        @project.set("name",params)
        @lib.add @project
        #bla = new AlertView
        #@alertModal.show(bla)
      else
        console.log "new project"
        @project.set("name",params)
        @lib.add @project
      
      @project.save()
      #hack to ensure the various sub files(only the one for now) are saved aswell: this should be done within the project class'
      #save method
      @mainPart.save()
      
      console.log "Saved Elems"
      console.log @project
      console.log @mainPart
      
      return      
      
    loadProject= (name) =>
      console.log("Loading part: #{name}")
      if name != @project.get("name")
        project = @lib.fetch({id:name})
        @project = project
        @mainPart = project.pfiles.at(0)
        @project.add @mainPart
        @lib.add @project
        @codeEditorView.switchModel @mainPart 
        @glThreeView.switchModel @mainPart
      else
        console.log "Project already loaded"
      return
      #console.log "Loaded Elems"
      #console.log @project
      #console.log @mainPart
    
    deleteProject=(name)=>
      console.log("deleting project #{name}")
      @project.destroy()
      @lib.remove(@project)
      for i,model of @project.pfiles.models
        model.destroy()
      #FIXME: yuck, ugly hack to remove the complete collection too
      localStorage.removeItem(@project.pfiles.localStorage.name)
      
      #ReCreate Fresh project and part
      @project = new Project({name:'TestProject'}) 
      @mainPart = new ProjectFile()
      @project.add @mainPart 
      
      @codeEditorView.switchModel @mainPart 
      @glThreeView.switchModel @mainPart
      
      return
      
      
    @vent.bind("fileSaveRequest", saveProject)
    @vent.bind("fileLoadRequest", loadProject)
    @vent.bind("fileDeleteRequest", deleteProject)
    
    ################
    
    app.mainMenuView.on "project:new:mouseup",=>

    app.mainMenuView.on "file:new:mouseup",=>
      #TODO: check if all files are saved etc
      @project = new Project({name:'TestProject'}) 
      @mainPart = new ProjectFile()
      @project.add @mainPart 
      ########VIEW UPDATES
      @codeEditorView.switchModel @mainPart 
      @glThreeView.switchModel @mainPart
      
    app.mainMenuView.on "file:save:mouseup",=>
      if @project.isNew2()
        @modView = new SaveView
        @modal.show(@modView)
      else
        console.log "save existing"
        @vent.trigger("fileSaveRequest",@project.get("name"))
      
    app.mainMenuView.on "file:saveas:mouseup",=>
      @modView = new SaveView
      @modal.show(@modView)
    
    app.mainMenuView.on "file:load:mouseup",=>
      @modView = new LoadView
        collection: @lib
      @modal.show(@modView)
     
    app.mainMenuView.on "settings:mouseup",=>
      @modView = new SettingsView 
        model: @settings
      @modal.show(@modView)      
      
    app.glThreeView.fromCsg()
    
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app