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
      #mainRegion: "#content"
      
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
        
        content_0:"""#This is the project's main configurationfil
        #It is better to keep global configuration elements here
        toto = new Cube
          radius:[50,50,25]
          center:[50,50,25]
          
        toto.name = "toto"
        #console.log "toto"
        #console.log JSON.stringify toto
        
        tutu = new Cube
          radius:[100,25,25]
          center:[100,25,25]
        
        tutu.name = "tutu"
        #console.log "tutu"
        #console.log JSON.stringify tutu
        
        tmp =toto.union(tutu)
        tmp.name = "result"
        #console.log "result"
        #console.log JSON.stringify tmp
        
        return tmp
        """
        content1:"""#This is the project's main configuration file 
        #It is better to keep global configuration elements here
        toto = new Cube
          radius:[50,50,25]
          center:[50,50,25]
          
        toto.name = "toto"
        console.log "toto"
        #console.log JSON.stringify toto
        
        tutu = new Cube
          radius:[100,25,25]
          center:[100,25,25]
        
        tutu.name = "tutu" 
        console.log "tutu"
        #console.log JSON.stringify tutu
        
        tmp =toto.union(tutu)
        tmp.name = "result"
        console.log "result"
        #console.log JSON.stringify tmp
        
        ###
        for i, poly of tutu.polygons
          vs = poly.vertices
          
          vsLine = ""
          for i, vertex of vs
            vsLine+= "\#{vertex.pos} "
          console.log vsLine
          vn = poly.plane.normal
          console.log "\#{vn}\n\\\n" 
        ###
        #register(Thinga.__proto__.constructor.name, truc)
        return tmp
        """
        
        content_:"""#This is the project's main configuration file
        #It is better to keep global configuration elements here
        toto = new Cube
          radius:[25,50,25]
          center:[12.5,25,12.5]
        s = new Sphere
          radius:75
                
        return s.subtract(toto)
        """
        content222:"""#This is the project's main configuration file
        #It is better to keep global configuration elements here
        class Thinga extends Meta
          constructor:(options) ->
            super options
            @toto = new Cube
              radius:[50,100,50]
            @c1 = new Cube
              radius:[50,25,50]
              center:[100,-12.5,0]
              
            s = new Sphere
              radius:75
            c = new Cylinder
              start:[0, 0, -100]
              end: [0, 0, 100]
              radius:20
              
            @unionSelf(@toto)
            @unionSelf(@c1)
            @unionSelf(s)
            #@unionSelf(c)
            @subtractSelf(c)
            
            #@expandSelf 3, 12
            
        truc = new Thinga()
        c = new Cube
          radius:[100,50,100]
          center:[100,0,0]
        troc = truc.subtract c
        
        tmp = new SpecialScrew()
        
        console.log "BOM:"
        for i, v of classRegistry
          console.log "You Have: \#{v} \#{i} (s)"
       
        doMagic()
        return truc.color([0.9,0.2,0])
        """
        content:"""
        #test
        sphere = new Sphere
          d: 100
          $fn: 10
          center: [-100,-25,0]
        cube = new Cube
          size: 100
          #center: [100,0,0]
        cylinder = new Cylinder
          h:200
          r:25
        
        cone = new Cylinder
          h:100
          d1:25
          d2:75
          center:[100,0,0]
        #Don't forget to 'return' what you want t o see rendered (api might change)
        
        console.log cube
        cube.translate [0,100,0]
        return sphere.union(cube).union(cone).subtract(cylinder)
        """
          
      @project.create_part
        name:"assembly"
      @project.create_part
        name:"testPart"
      
      
    onStart:()=>
      console.log "app started"
      
      CodeEditor = require './editors/codeEditor/codeEditor'
      codeEditor = new CodeEditor
        regions: 
          mainRegion: "#code"
        project: @project
      codeEditor.start()
      
      VisualEditor = require './editors/visualEditor/visualEditor'
      visualEditor = new VisualEditor
        regions: 
          mainRegion: "#visual"
        project:
          @project
      visualEditor.start()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
      
    onInitializeBefore:()->
      console.log "before init"
      
    onInitializeAfter:()=>
      """For exampel here close and 'please wait while app loads' display"""
      console.log "after init"

  return CoffeeScadApp   
