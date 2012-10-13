define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  
  CodeEditorView = require "views/codeView"
  MainMenuView = require "views/menuView"
  ProjectView = require "views/projectsview"
  {Library,Project,ProjectFile} = require "modules/project"

  modTest = require "views/fileSaveLoadView"
  ModalRegion = modTest[0]
  SaveView = modTest[1]
  LoadView = modTest[2]
  SettingsView = modTest[3]
  
  
  Settings = require "modules/settings"
  
  CsgProcessor = require "modules/csg.processor"
  
  MainContentLayout = (require "views/mainContentView")
  
  {GlViewSettings,GlThreeView} = require "views/glThreeView"
  
  ###############################
  
  testcode = 
  """
class CubeClass
  width:20
  length:20
  height:20
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
  
  render: =>
    result = new CSG()
    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})
    result = cube1
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) 

cubeStuff = new CubeClass()
return cubeStuff"""
  #testcode = testcode.replace(/^\s*/g, "") #ltrim
  #testcode = testcode.replace(/\s*$/g, "") #rtrim
  #testcode = testcode.replace(/^\s*|\s*$/g, "")
  #testcode = testcode.replace /^\s+|\s+$/g, ""

  app = new marionette.Application
    root: "/opencoffeescad"
    cadProcessor: null
    updateSolid: () ->
      app.cadProcessor.setCoffeeSCad(app.cadEditor.getValue())
      
  
  app.addRegions
    navigationRegion: "#navigation"
    mainRegion: "#mainContent"
    statusRegion: "#statusBar"
    modal: ModalRegion
  
  app.on "start", (opts)->
    console.log "at start"
    
  app.on "initialize:after", ->
    console.log "after init"
    
  app.addInitializer (options)->
    app.settings = new Settings
    app.csgProcessor = new CsgProcessor
    app.lib = new Library
    
    app.project = new Project
      name: "MyProject"
      content : "this is the first project's content"
      
    app.project2 = new Project
      name:"toto"
      content : "something completely different"
    
    app.lib.add app.project
    app.lib.add app.project2
     
      
    app.model = new ProjectFile
      name: "main"
      ext: "coscad"
      content: testcode    


    ################  
    app.codeEditorView = new CodeEditorView
      model: @model 
    app.mainMenuView = new MainMenuView
      model: @lib
    app.projectView = new ProjectView
      collection:@lib
      
    app.glThreeView = new GlThreeView
      model: @model
      
    app.mainContentLayout = new MainContentLayout
    
    #app.mainRegion.show app.codeEditorView
    @mainRegion.show @mainContentLayout
    @mainContentLayout.edit.show @codeEditorView
    @mainContentLayout.gl.show @glThreeView
    
    app.navigationRegion.show app.mainMenuView
    app.statusRegion.show app.projectView
    
    app.modal.app = app
    
    displayTheThing= (params) =>
      console.log("SaveRequested")
      console.log "params: #{params}"
    displayTheThing2= (params) =>
      console.log("LoadRequested")
      console.log "params: #{params}"
      
    #app.modView = new SaveView app:app
    app.vent.bind("fileSaveRequest", displayTheThing)
    app.vent.bind("fileLoadRequest", displayTheThing2)
    #vent = new marionette.EventAggregator()
    #vent.bindTo("fileSaveRequest", displayTheThing)
   # app.vent.trigger("fileSaveRequest")
    ################
    
    app.mainMenuView.on "project:new:mouseup",=>

    app.mainMenuView.on "file:new:mouseup",=>
      #TODO: check if all files are saved etc
      console.log("newfile")
      @project.remove @model
      @model = new ProjectFile
        name: "main"
        ext: "coscad"
        content: ""
      @project.add @model 
      @codeEditorView.close()
      @codeEditorView = new CodeEditorView
        model: @model
      @mainRegion.show @codeEditorView
      #return true
      
    app.mainMenuView.on "file:save:mouseup",=>
      app.modView = new SaveView #app:app
      app.modal.show(@modView)
      console.log("savefile")
      
      ###
      @project.save null,
        success: (project, response) ->
          console.log "sucess"
          #console.log project
        error: (project, response) ->
          console.log 'failed'
      ###
    
    app.mainMenuView.on "file:load:mouseup",=>
      app.modView = new LoadView #app:app
      app.modal.show(@modView)
      
      console.log("loadfile")
      ###
      @project.fetch 
        success: (project, response)=> 
          console.log "sucess"
          @codeEditorView = new CodeEditorView
            model: @model
          @mainRegion.show @codeEditorView
        error: -> 
          console.log "error"
       ###   
    app.mainMenuView.on "settings:mouseup",=>
      app.modView = new SettingsView(model:app.settings)
      app.modal.show(@modView)      
      
    app.project.on "change", ->
      console.log "project changed"
      
   
      
    #app.mainRegion.hide
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app