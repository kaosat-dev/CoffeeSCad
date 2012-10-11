define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  CodeEditorView = require "views/codeView"
  MainMenuView = require "views/menuView"
  #ProjectFile = require "modules/Project"
  bla = require "modules/tutu"
  ProjectFile=bla[0]
  Project =bla[1]

  
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


  app = new marionette.Application
    root: "/opencoffeescad"
    cadProcessor: null
    cadEditor: null
    cadViewer: null
    projectName: "MyProject"
    codeUpdated: true
    updateSolid: () ->
      app.cadProcessor.setCoffeeSCad(app.cadEditor.getValue())
  
  app.addRegions
    navigationRegion: "#navigation"
    mainRegion: "#mainContent"
    statusRegion: "#statusBar"
  
  app.on "start", (opts)->
    console.log "at start"
    
  app.on "initialize:after", ->
    console.log "after init"
    
  app.vent.on "tutu", ->
    console.log "on TUTU"
    
  app.addInitializer (options)->
    app.model = new ProjectFile
      name: "toto"
      ext: "coscad"
      content: testcode
      
    app.codeEditorView = new CodeEditorView
      model: app.model
      
    app.mainMenuView = new MainMenuView
      model: app.model
      
    app.mainRegion.show app.codeEditorView
    app.navigationRegion.show app.mainMenuView


    #event tests
    app.codeEditorView.on "item:on:beforerender",->
      console.log "the view is about to be rendered" 
      
    app.codeEditorView.on "something:do:it", ->
      console.log("I DID IT!")
      
    app.codeEditorView.on "foo:bar", ->
      console.log("I fooed IT!")

 
    #app.mainRegion.hide
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###
  return app