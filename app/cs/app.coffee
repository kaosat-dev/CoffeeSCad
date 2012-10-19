define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  
  CodeEditorView = require "views/codeView"
  MainMenuView = require "views/menuView"
  ProjectView = require "views/projectsview"
  SettingsView = require "views/settingsView"
  MainContentLayout = (require "views/mainContentView")
  modTest = require "views/fileSaveLoadView"
  
  {Library,Project,ProjectFile} = require "modules/project"


  ModalRegion = modTest[0]
  SaveView = modTest[1]
  LoadView = modTest[2]
  
  
  
  SettingsManager = require "modules/settings"
  SettingsTest = require "modules/testSettings"
  
  CsgProcessor = require "modules/csg.processor"
  

  
  {GlViewSettings,GlThreeView} = require "views/glThreeView"
  
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

  class TestStuff
    constructor:()->
      @size=10
      @name ="bleh"
      shortcut = -> @doThat
      #for key, value of @
      #    shortcut[key] = value
      return @doThat
    
    doThat:()=>
      console.log @size+ " "+ @name

  app = new marionette.Application
    root: "/opencoffeescad"
      
  
  app.addRegions
    navigationRegion: "#navigation"
    mainRegion: "#mainContent"
    statusRegion: "#statusBar"
    modal: ModalRegion
  
  app.on "start", (opts)->
    console.log "at start"
    
    
  app.on "initialize:after", ->
    console.log "after init"
    ###fetch all settings###
   
  app.addInitializer (options)->
    @settingsmgr = new SettingsManager
    #@settingsmgr.save()
    @settingsmgr.fetch()
    
    @lib  = new Library
    ###
    testmodel = new ProjectFile
      name: "assembly"
      ext: "coscad"
      content: testcode   
      
    testmodel2 = new ProjectFile
      name: "part"
      ext: "coscad"
      content: "Cube()"  
      
    proj = new Project({name:'proj1'})
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
    app.csgProcessor = new CsgProcessor
    
    app.project = new Project
      name: "MyProject"
      content : "this is the first project's content"
      
    app.project2 = new Project
      name:"toto"
      content : "something completely different"
    
   # app.lib.add app.project
   # app.lib.add app.project2
     
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
      settings: new GlViewSettings()
      
    app.mainContentLayout = new MainContentLayout
    
    #app.mainRegion.show app.codeEditorView
    @mainRegion.show @mainContentLayout
    @mainContentLayout.edit.show @codeEditorView
    @mainContentLayout.gl.show @glThreeView
    
    app.navigationRegion.show app.mainMenuView
    app.statusRegion.show app.projectView
    
    app.modal.app = app
    
    saveProject= (params) =>
      console.log("SaveRequested")
      console.log "params: #{params}"
      console.log params
    loadProject= (params) =>
      console.log("LoadRequested")
      console.log "params: #{params}"
      
    app.vent.bind("fileSaveRequest", saveProject)
    app.vent.bind("fileLoadRequest", loadProject)
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
      app.modView = new SaveView
      app.modal.show(@modView)
    
    app.mainMenuView.on "file:load:mouseup",=>
      app.modView = new LoadView
      app.modal.show(@modView)
      
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
      console.log app.settingsmgr
      app.modView = new SettingsView(model: app.settingsmgr, collection:app.settingsmgr.settings)
      app.modal.show(@modView)      
      
    app.project.on "change", ->
      console.log "project changed"
   
    app.glThreeView.fromCsg()
      
   
    #app.mainRegion.hide
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app