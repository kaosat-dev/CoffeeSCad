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
  {GlViewSettings,GlThreeView} = require "views/glThreeView"
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
  
  app.on "start", (opts)->
    console.log "at start"
    $("[rel=tooltip]").tooltip
      placement:'bottom' 
    #$(".toggleGrid").tooltip()
    #$(".tooltip").tooltip()
    
    
  app.on "initialize:after", ->
    console.log "after init"
    ###fetch all settings###
   
  app.addInitializer (options)->
    exporter = new CsgStlExporterMin()
    
    
    @settings = new Settings
    #@settings.save()
    @settings.fetch()
    
    @lib  = new Library
    @csgProcessor = new CsgProcessor
    
    @project = new Project({name:'MainProject'})  
    @mainPart = new ProjectFile
      name: "main"
      ext: "coscad"
      content: testcode    
      
    @lib.add @project
    @project.save()
    @project.add @mainPart
    
    testmodel2 = new ProjectFile
      name: "part"
      ext: "coscad"
      content: "Cube()"  
    @project.add testmodel2
    
    
    
    #testmodel2.save()
    ###
    testmodel = new ProjectFile
      name: "assembly"
      ext: "coscad"
      content: testcode   
      
    testmodel2 = new ProjectFile
      name: "part"
      ext: "coscad"
      content: "Cube()"  
      
    
    proj.add testmodel
    proj.add testmodel2
    
    proj2 = new Project({name:'proj2'})
    proj2.add testmodel2
    
    @lib  = new Library
    @lib.add(proj)
    @lib.add(proj2)
    @lib.save( )
    @lib.fetch()
    ###
    #proj.save() 
    
    #proj3= @lib.fetch({id:"proj1"})
    #console.log(proj3)
    #if @lib.get("proj2")?
    #  alert("OH ma gad, overwrite?")
    #else
    #  alert("all is fine")
    ###############
    CsgStlExporterMin = require "modules/csg.stlexporter"
    
    stlexport=()=>
      #console.log "export stl"
      stlExp = new CsgStlExporterMin @mainPart.csg
      blobUrl = stlExp.export()
      #toto.step1()
      
      @vent.trigger("stlGenDone", blobUrl)
    
    @vent.bind("downloadStlRequest", stlexport)

      
    ################  
    @codeEditorView = new CodeEditorView
      model: @mainPart 
    @mainMenuView = new MainMenuView
      model: @lib
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
    @statusRegion.show @projectView
    
    @modal.app = @
    
    saveProject= (params) =>
      console.log("Saving part to file : #{params}")
      #@mainPart.set("name",params)
      @mainPart.save()
      #console.log("saved model")
      #console.log(@mainPart)
      #@project.save()
    loadProject= (params) =>
      console.log("Loading part: #{params}")
      part = @project.fetch_file({id:"part"})
      console.log(part)
      
      
    @vent.bind("fileSaveRequest", saveProject)
    @vent.bind("fileLoadRequest", loadProject)
    
    ################
    
    app.mainMenuView.on "project:new:mouseup",=>

    app.mainMenuView.on "file:new:mouseup",=>
      #TODO: check if all files are saved etc
      #@project.remove @mainPart
      @mainPart = new ProjectFile
        name: "main"
        ext: "coscad"
        content: ""
      #@project.add @mainPart 
      ########VIEW UPDATES
      @codeEditorView.switchModel @mainPart 
      @glThreeView.switchModel @mainPart
      
    app.mainMenuView.on "file:save:mouseup",=>
      app.modView = new SaveView
      app.modal.show(@modView)
    
    app.mainMenuView.on "file:load:mouseup",=>
      app.modView = new LoadView
      app.modal.show(@modView)
     
    app.mainMenuView.on "settings:mouseup",=>
      setTest = @settings.first()
      
      @modView = new SettingsView 
        model: setTest
        
      @modView.render()
      console.log @modView
      
      app.modal.show(@modView)      
      
    app.glThreeView.fromCsg()
    
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app