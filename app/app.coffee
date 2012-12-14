define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  require 'bootstrap'
  require 'bootbox'
  
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
  

  Settings = require "modules/settings"
  
  ###############################
 
  app = new Backbone.Marionette.Application
    root: "/coffeescad"
      
  app.addRegions
    navigationRegion: "#navigation"
    mainRegion: "#mainContent"
    
  app.on "start", (opts)->
    console.log "App Started"
    $("[rel=tooltip]").tooltip
      placement:'bottom' 
    
  app.addInitializer (options)->
    ################ 
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
    
    """Show all necessary view in the correct regions"""
    
    @mainRegion.show @mainContentLayout
    #@mainContentLayout.edit.show @codeEditorView
    @mainContentLayout.gl.show @glThreeView
    
    @dialogRegion.show @codeEditorView
    @navigationRegion.show @mainMenuView
    @fileBrowseRegion.show @fileBrowserView
    
    
    @modal.app = @
    
      
    showEditor=()=>
      if not @codeEditorView.isVisible
        @dialogRegion.show @codeEditorView
      
    @vent.bind("fileSaveRequest", saveProject)
    @vent.bind("fileLoadRequest", loadProject)
    @vent.bind("fileDeleteRequest", deleteProject)
    @vent.bind("editorShowRequest", showEditor)
    
    @settingsChanged=(settings, value)=> 
      console.log "gnu"
      for key, val of @settings.get("General").changedAttributes()
        switch key
          when "theme"
            $("#mainTheme").attr("href","assets/css/themes/#{val}/bootstrap.css");

    
    @bindTo(@settings.get("General"), "change", @settingsChanged)
    
   
    
    
    
    
    $("link").attr("href",$(this).attr('rel'))
    
    ################
    
    @mainMenuView.on "project:new:mouseup",=>

    @mainMenuView.on "file:new:mouseup",=>
      @newProject()
      
    @mainMenuView.on "file:save:mouseup",=>
      if @project.isNew2()
        @modView = new SaveView
        @modal.show(@modView)
      else
        console.log "save existing"
        @vent.trigger("fileSaveRequest",@project.get("name"))
      
    @mainMenuView.on "file:saveas:mouseup",=>
      @modView = new SaveView
      @modal.show(@modView)
    
    @mainMenuView.on "file:load:mouseup",=>
      @modView = new LoadView
        collection: @lib
      @modal.show(@modView)
     
    @mainMenuView.on "settings:mouseup",=>
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