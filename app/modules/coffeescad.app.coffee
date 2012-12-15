define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  class MainLayout extends Backbone.Marionette.Layout
  template: "#my-layout"
  regions:
    menu: "#menu"
    content: "#content"


  class CoffeeScad extends Backbone.Marionette.Application
    root: "/coffeescad"
    
    constructor:()=>
      @addRegions
        #navigationRegion: "#navigation"
        mainRegion: "#mainContent"      
      @settings = new Settings()
      @lib  = new Library()
      
      @addInitializer (options)=> @setup
      
      @bindTo(@settings.get("General"), "change", @settingsChanged)
      #@vent.bind("downloadStlRequest", stlexport)
      @vent.bind("fileSaveRequest", saveProject)
      @vent.bind("fileLoadRequest", loadProject)
      @vent.bind("fileDeleteRequest", deleteProject)
      @vent.bind("editorShowRequest", showEditor)
     
    setup:(options)=>
      """Fetch settings"""
      @settings.fetch()
      
      """Initialize correct theme css"""
      theme = @settings.get("General").get("theme")
      $("#mainTheme").attr("href","assets/css/themes/#{theme}/bootstrap.css")
      #$("link").attr("href",$(this).attr('rel'))
      """Fetch library content"""
      @lib.fetch()
    
    exportProjectToStl:(mainpart)=>
      stlExp = new CsgStlExporterMin mainpart.csg
      blobUrl = stlExp.export()
      @vent.trigger("stlGenDone", blobUrl)
    
    onInitializeAfter:()->
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"
      
      """Create all main views"""
      @codeEditorView = new CodeEditorView
        model: @mainPart 
        settings: @settings.at(2)
      @mainMenuView = new MainMenuView
        collection: @lib
        model: @project
      @projectView = new ProjectView
        collection:@lib
      @glThreeView = new GlThreeView
        model: @mainPart
        settings: @settings.at(1)
      @fileBrowserView = new FileBrowserView
        collection: @lib
        
      @mainContentLayout = new MainContentLayout
      """Show all necessary views in the correct regions"""
      @mainRegion.show @mainContentLayout
      #@mainContentLayout.edit.show @codeEditorView
      @mainContentLayout.gl.show @glThreeView
      
      @dialogRegion.show @codeEditorView
      @navigationRegion.show @mainMenuView
      @fileBrowseRegion.show @fileBrowserView
    
    onStart:()->
      $("[rel=tooltip]").tooltip
        placement:'bottom' 
      @glThreeView.fromCsg()#YIKES  
      
    
    settingsChanged=(settings, value)=> 
        for key, val of @settings.get("General").changedAttributes()
          switch key
            when "theme"
              $("#mainTheme").attr("href","assets/css/themes/#{val}/bootstrap.css")
              
    showEditor=()=>
      if not @codeEditorView.isVisible
        @dialogRegion.show @codeEditorView
     
     ###
     CodeEditorView = require "views/codeView"
      MainMenuView = require "views/menuView"
      ProjectView = require "views/projectsview"
      SettingsView = require "views/settingsView"
      MainContentLayout = require "views/mainContentView"
      ModalRegion = require "views/modalRegion"
      DialogRegion = require "views/dialogRegion"
      {LoadView, SaveView} = require "views/fileSaveLoadView"
      GlThreeView = require "views/glThreeView"
      {FileBrowseRegion,FileBrowserView} = require "views/fileBrowserView"
      
      {Library,Project,ProjectFile} = require "modules/project"
   ###

  Settings = require "modules/settings"
