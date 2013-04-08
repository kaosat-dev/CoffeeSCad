define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  #require 'jquery_hotkeys'
  
  vent = require 'modules/core/messaging/appVent'
  
  MenuView = require './core/menuView'
  ModalRegion = require './core/utils/modalRegion'
  
  Project = require './core/projects/project'
  ProjectBrowserView = require './core/projects/projectBrowseView'
  
  ProjectManager = require './core/projects/projectManager'
  
  Settings = require './core/settings/settings'
  SettingsView = require './core/settings/settingsView'
   
  
  class CoffeeScadApp extends Backbone.Marionette.Application
    ###
    Main application class, gets instanciated only once on startup
    ###
    root: "/CoffeeSCad/index.html/"
    title: "Coffeescad"
    regions:
      headerRegion: "#header"
      
    constructor:(options)->
      super options
      @vent = vent
      
      @settings = new Settings()
      @initSettings()
      
      @projectManager = new ProjectManager
        appSettings: @settings
      
      @editors = {}
      @exporters = {}
      @stores = {}
      
      #Exporters
      BomExporter = require './exporters/bomExporter/bomExporter'
      StlExporter = require './exporters/stlExporter/stlExporter'
      #AmfExporter = require './exporters/amfExporter/amfExporter'
      @exporters["stl"] = new StlExporter()
      @exporters["bom"] = new BomExporter()
      #@exporters["amf"] = new AmfExporter()
      
      #stores 
      DropBoxStore = require './stores/dropbox/dropBoxStore'
      #GithubStore = require './stores/github/gitHubStore'
      BrowserStore = require './stores/browser/browserStore'
      @stores["Dropbox"] = new DropBoxStore()
      #@stores["gitHub"] = new GithubStore()
      @stores["browser"] = new BrowserStore()
      
      #events
      $(window).bind('beforeunload',@onAppClosing)
      @vent.on("app:started", @onAppStarted)
      @vent.on("settings:show", @onSettingsShow)
      @vent.on("project:loaded", @onProjectLoaded)
      
      #handle exporters initialization
      for name, exporter of @exporters
        @vent.on("#{name}Exporter:start", do(name)=> =>@exporters[name].start({project:@project}))
      
      @initPreVisuals()
      @addRegions @regions
      @initData()
      @initLayout()
      
    initLayout:=>
      @menuView = new MenuView
        stores: @stores
        exporters: @exporters
        model : @project
      @headerRegion.show @menuView
    
    initSettings:->
      setupSettingsBindings= =>
        @initPreVisuals()
        mySettings = @settings.getByName("General")
        mySettings.on("change", @onSettingsChanged)
      @settings.on("reset",setupSettingsBindings)
      
    initPreVisuals:->
      """Initialize correct theme css"""
      @theme = @settings.get("General").get("theme")
      $("#mainTheme").attr("href","assets/css/themes/#{@theme}/bootstrap.css")
      
    initData:->
      @projectManager.stores = @stores
      @project = @projectManager.createProject()
    
    _setupKeyboardBindings:=>
      #Setup keyBindings
      ### 
      @$el.bind 'keydown', 'ctrl+s', ->
        console.log "i want to save a FILE"
        return false
      ###
      $(document).bind "keydown", "alt+n", =>
        @vent.trigger("project:new")
        return false
        
      $(document).bind "keydown", "ctrl+s", =>
        @vent.trigger("project:save")
        return false
        
      $(document).bind "keydown", "ctrl+l", =>
        @vent.trigger("project:load")
        return false
      
      $(document).bind "keydown", "alt+c", =>
        @vent.trigger("project:compile")
        return false
      
      $(document).bind "keydown", "f4", =>
        @vent.trigger("project:compile")
        return false
      
    onStart:()=>
      console.log "app started"
      #@_setupKeyboardBindings()
      @codeEditor.start()
      @visualEditor.start()
      #@hierarchyEditor.start()
      #we check if we came back form an oauth redirect/if we have already been authorized
      for index, store of @stores
        store.authCheck()
     
      @projectManager.reloadLast()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
    
    onAppClosing:()=>
      if @project.isSaveAdvised
        console.log "on close foo"
        return 'You have unsaved changes!'
      else
        console.log "on close bar"
        localStorage.setItem("appCloseOk",true)
    
    onSettingsShow:()=>
      settingsView = new SettingsView
        model : @settings 
      
      modReg = new ModalRegion({elName:"settings",large:true})
      modReg.show settingsView
    
    onSettingsChanged:(settings, value)=> 
      for key, val of @settings.get("General").changedAttributes()
        switch key
          when "theme"
            @theme = val
            $("#mainTheme").attr("href","assets/css/themes/#{@theme}/bootstrap.css")
    
    onProjectLoaded:(newProject)=>
      console.log "project loaded"
      @project = newProject
      
    onInitializeBefore:()->
      console.log "before init"
      CodeEditor = require './editors/codeEditor/codeEditor'
      @codeEditor = new CodeEditor
        regions: 
          mainRegion: "#code"
        project: @project
        appSettings: @settings
      
      VisualEditor = require './editors/visualEditor/visualEditor'
      @visualEditor = new VisualEditor
        regions: 
          mainRegion: "#visual"
        project: @project
        appSettings: @settings
      
      ### 
      HierarchyEditor = require './editors/hierarchyEditor/hierarchyEditor'
      @hierarchyEditor = new HierarchyEditor
        project: @project
        appSettings: @settings ### 
     
      @settings.fetch()
      
    onInitializeAfter:()=>
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"
      $("#initialLoader").text("")

  return CoffeeScadApp   
