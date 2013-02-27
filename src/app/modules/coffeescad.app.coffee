define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  vent = require './core/vent'
  
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
      @projectManager = new ProjectManager
        appSettings: @settings
      
      @editors = {}
      @exporters = {}
      @connectors = {}
      
      #Exporters
      BomExporter = require './exporters/bomExporter/bomExporter'
      StlExporter = require './exporters/stlExporter/stlExporter'
      AmfExporter = require './exporters/amfExporter/amfExporter'
      @exporters["stl"] = new StlExporter()
      @exporters["bom"] = new BomExporter()
      @exporters["amf"] = new AmfExporter()
      
      #Connectors
      DropBoxConnector = require './connectors/dropbox/dropBoxConnector'
      #GithubConnector = require './connectors/github/gitHubConnector'
      BrowserConnector = require './connectors/browser/browserConnector'
      @connectors["dropBox"] = new DropBoxConnector()
      #@connectors["gitHub"] = new GithubConnector()
      @connectors["browser"] = new BrowserConnector()
      
      #events
      $(window).bind('beforeunload',@onAppClosing)
      @vent.on("app:started", @onAppStarted)
      @vent.on("settings:show", @onSettingsShow)
      
      #handle exporters initialization
      for name, exporter of @exporters
        @vent.on("#{name}Exporter:start", do(name)=> =>@exporters[name].start({project:@project}))
        
      
      @addRegions @regions
      @initLayout()
      @initData()
     
    initLayout:=>
      @menuView = new MenuView
        connectors: @connectors
        exporters: @exporters
      @headerRegion.show @menuView
    
    initSettings:->
      @settings = new Settings()
      @bindTo(@settings.get("General"), "change", @settingsChanged)
    
    initData:->
      @projectManager.connectors = @connectors
      @project = @projectManager.createProject()

    onStart:()=>
      console.log "app started"
      @codeEditor.start()
      @visualEditor.start()
      #we check if we came back form an oauth redirect/if we have already been authorized
      for index, connector of @connectors
        connector.authCheck()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
    
    onAppClosing:()=>
      #if @project.dirty
      #  return 'You have unsaved changes!'
    
    onSettingsShow:()=>
      settingsView = new SettingsView
        model : @settings 
      
      modReg = new ModalRegion({elName:"settings",large:true})
      modReg.show settingsView
    
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
      
      @settings.fetch()
      
    onInitializeAfter:()=>
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"

  return CoffeeScadApp   
