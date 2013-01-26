define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  vent = require './core/vent'
  
  MenuView = require './core/menuView'
  ModalRegion = require './core/utils/modalRegion'
  
  Project = require './core/projects/project'
  ProjectBrowserView = require './core/projects/projectBrowseView'
  
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
      
      @editors = {}
      @exporters = {}
      @connectors = {}
      
      #Exporters
      BomExporter = require './exporters/bomExporter/bomExporter'
      StlExporter = require './exporters/stlExporter/stlExporter'
      @exporters["stl"] = new StlExporter()
      @exporters["bom"] = new BomExporter()
      
      #Connectors
      DropBoxConnector = require './connectors/dropbox/dropBoxConnector'
      @connectors["dropBox"] = new DropBoxConnector()
      
      #events
      $(window).bind('beforeunload',@onAppClosing)
      @on("initialize:before",@onInitializeBefore)
      @on("initialize:after",@onInitializeAfter)
      @on("start", @onStart)
      @vent.on("app:started", @onAppStarted)
      @vent.on("settings:show", @onSettingsShow)
      @vent.on("bomExporter:start", ()=> @exporters["bom"].start({project:@project}))
      @vent.on("stlExporter:start", ()=> @exporters["stl"].start({project:@project}))
      
      #just temporary
      @vent.on("project:save", @onNewProject)
      @vent.on("project:load")
      
      
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
      @project = new Project()
      @project.createFile
        name: @project.get("name")
        content:"""
        #just a comment
        class Thinga extends Part
          constructor:(options) ->
            super options
            @cb = new Cube({size:[50,100,50]})
            c = new Cylinder({h:300, r:20}).color([0.8,0.5,0.2])
            @union(@cb.color([0.2,0.8,0.5]))
            @subtract(c.translate([10,0,-150]))
        
        class WobblyBobbly extends Part
          constructor:(options) ->
            defaults = {pos:[0,0,0],rot:[0,0,0]}
            options = merge defaults, options
            {@pos, @rot} = options
            super options
            @union  new Cube(size:[50,100,50],center:@pos).rotate(@rot)
        
        thinga1 = new Thinga()
        thinga2 = new Thinga()
        assembly.add(thinga1.translate([100,0,0]))
        #thinga1.getBounds()
        plane = Plane.fromNormalAndPoint([0, 0, 1], [0, 0, 25])
        thinga1.cutByPlane(plane)
        #thinga1.expand(3,5)
        assembly.add(thinga1.translate([100,0,0]))
        
        wobble = new WobblyBobbly(rot:[5,25,150],pos:[-100,150,10])
        wobble2 = new WobblyBobbly(pos:[0,10,20])
        wobble3 = new WobblyBobbly(pos:[-100,10,20])
        
        assembly.add(wobble)
        assembly.add(wobble2)
        assembly.add(wobble3)
        """
      @project.createFile
        name:"config"
        content:"""
        #just a comment
        console.log assembly
        ###
        console.log "options"
        console.log options
        console.log "toto"
        console.log toto
        try
          console.log options.toto
        catch error
          console.log "options.toto does not work"
        try
          console.log toto
        catch error
          console.log "toto does not work"
        ###
       
        """
      
    onStart:()=>
      console.log "app started"
      @codeEditor.start()
      @visualEditor.start()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
    
    onAppClosing:()=>
      console.log "app closing, bye"
      if @project.dirty
        return 'You have unsaved changes!'
    
    onSettingsShow:()=>
      settingsView = new SettingsView
        model : @settings 
      
      modReg = new ModalRegion({elName:"settings",large:true})
      modReg.show settingsView
      
    onNewProject:()=>
      console.log "new project"
      
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
