define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  class MainLayout extends Backbone.Marionette.Layout
    template: "#my-layout"
    regions:
      menu:    "#menu"
      content: "#content"

  class CoffeeScadApp extends Backbone.Marionette.Application
    root: "/coffeescad"
    title: "Coffeescad"
    regions:
      mainRegion: "#content"
    
    constructor:(options)->
      super options
      @on("initialize:before",@onInitializeBefore)
      @on("initialize:after",@onInitializeAfter)
      @on("start",@onStart)
      #@initLayout()
      ###
      @vent.bind("downloadStlRequest", stlexport)
      @vent.bind("fileSaveRequest", saveProject)
      @vent.bind("fileLoadRequest", loadProject)
      @vent.bind("fileDeleteRequest", deleteProject)
      @vent.bind("editorShowRequest", showEditor)
      ###
    initLayout:->
      @layout = new MainLayout @title
      @mainRegion.show @layout
    
    initSettings:->
      @settings = new Settings()
      @bindTo(@settings.get("General"), "change", @settingsChanged)
      
    onStart:()->
      console.log "app started"
      #$("[rel=tooltip]").tooltip
      #  placement:'bottom' 
      #@glThreeView.fromCsg()#YIKES  
      
    onInitializeBefore:()->
      console.log "before init"
      
    onInitializeAfter:()->
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"

  return CoffeeScadApp   


