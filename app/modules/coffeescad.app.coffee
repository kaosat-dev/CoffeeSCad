define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  

  class CoffeeScad extends Backbone.Marionette.Application
    root: "/coffeescad"
    
    constructor:()=>
      @settings = new Settings()
      @lib  = new Library()
      
      @addInitializer (options)=> @setup
      
      #@vent.bind("downloadStlRequest", stlexport)
      @on "initialize:after", ->
    
    setup:(options)=>
      """Fetch settings"""
      @settings.fetch()
      
      """Initialize correct theme css"""
      theme = @settings.get("General").get("theme")
      $("#mainTheme").attr("href","assets/css/themes/#{theme}/bootstrap.css");
      
      """Fetch library content"""
      @lib.fetch()
    
    exportProjectToStl:(mainpart)=>
      stlExp = new CsgStlExporterMin mainpart.csg
      blobUrl = stlExp.export()
      @vent.trigger("stlGenDone", blobUrl)
    
    afterInit:()->
      """For exampel here close and 'please wait while app loads' display"
      console.log "after init"
      @glThreeView.fromCsg()#YIKES
    
      