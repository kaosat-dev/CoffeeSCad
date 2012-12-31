###
Documentation functions
=======================

These functions extract relevant documentation info from AST nodes as returned
by the coffeescript parser.
###

define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  vent = require './core/vent'
  
  contentTemplate = require "text!./core/content.tmpl"
  MenuView = require './core/menuView'
  Project = require "./core/projects/project"  
  
  class MainLayout extends Backbone.Marionette.Layout
    template: contentTemplate
    regions:
      menu:    "#menu"
      content: "#content"
      
    constructor:(options)->
      super options
      @headerRegion.show @layout
      
      
  class CoffeeScadApp extends Backbone.Marionette.Application
    ###
    This docstring documents MyClass. It can include *Markdown* syntax,
    which will be converted to html.
    ###
    root: "/CoffeeSCad/index.html/"
    title: "Coffeescad"
    regions:
      headerRegion: "#header"
      mainRegion: "#content"
      
    constructor:(options)->
      super options
      @vent = vent
      @addRegions @regions
        
      @on("initialize:before",@onInitializeBefore)
      @on("initialize:after",@onInitializeAfter)
      @on("start", @onStart)
      @vent.on("app:started", @onAppStarted)
      
      @initLayout()
      @initData()
      ###
      @vent.bind("downloadStlRequest", stlexport)#COMMAND
      @vent.bind("fileSaveRequest", saveProject)#COMMAND
      @vent.bind("fileLoadRequest", loadProject)#COMMAND
      @vent.bind("fileDeleteRequest", deleteProject)#COMMAND
      @vent.bind("editorShowRequest", showEditor)#COMMAND
      ###
    initLayout:=>
      @menuView = new MenuView()
      #@layout = new MainLayout()
      @headerRegion.show @menuView
    
    initSettings:->
      @settings = new Settings()
      @bindTo(@settings.get("General"), "change", @settingsChanged)
    
    initData:->
      @project = new Project()
      @project.create_part
        name:"config"
        content:"""#This is the project's main configuration file
        #It is better to keep global configuration elements here"""
      @project.create_part
        name:"assembly"
      @project.create_part
        name:"testPart"
      @project.create_part
        name:"otherPart"
      
      
    onStart:()=>
      console.log "app started"
      
      CodeEditor = require './editors/codeEditor/codeEditor'
      codeEditor = new CodeEditor
        regions: 
          mainRegion: "#content"
        project: @project
      codeEditor.start()
      
      ### 
      VisualEditor = require './editors/visualEditor/visualEditor'
      visualEditor = new VisualEditor
        regions: 
          mainRegion: "#content"
        project:
          @project
      visualEditor.start()
      ###
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
      
    onInitializeBefore:()->
      console.log "before init"
      
    onInitializeAfter:()=>
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"

  return CoffeeScadApp   


