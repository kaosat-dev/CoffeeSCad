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
      
    onStart:()=>
      console.log "app started"
      #$("[rel=tooltip]").tooltip
      #  placement:'bottom' 
      #@glThreeView.fromCsg()#YIKES 
      CodeEditor = require './editors/codeEditor/codeEditor'
      codeEditor = new CodeEditor
        regions: 
          mainRegion: "#content"
        project:
          @project
      codeEditor.start()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
      
    onInitializeBefore:()->
      console.log "before init"
      
    onInitializeAfter:()=>
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"

  return CoffeeScadApp   


