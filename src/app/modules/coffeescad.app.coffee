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
        content_0:"""
        #This is the project's main configuration file
        #It is better to keep global configuration elements here
        class Thinga extends Meta
          constructor:(options) ->
            super options
            @toto = new Cube
              size:[50,100,50]
            @c1 = new Cube
              size:[50,25,50]
              center:[100,-12.5,0]
               
            s = new Sphere(r:75, $fn:45)
            c = new Cylinder(h:300, r:20).color([0.8,0.5,0.2])
               
            @union(@toto.color([0.2,0.8,0.5]))
            @union(@c1)
            @union(s.color([0.6,0.8,0.9]))
            @subtract(c.translate([10,0,-150]))
             
        thinga1 = new Thinga()
        ###
        tmp = new SpecialScrew()
        console.log "BOM:"
        for i, v of classRegistry
          console.log "You Have: \#{v} \#{i} (s)"
        
        doMagic()
        ###        
        
        return thinga1#.color([0.9,0.2,0])
        """
        content_1:"""
        #test 
        sphere = new Sphere
          d: 100
          $fn: 10
          center: [87.505,-25,20]
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
        
        cube.translate [0,10,0]
        
        #cube.union(cone).subtract(cylinder).union(sphere)
        cube.color([0.8,0,0])
        cylinder.color([0,1,0])
        cone.color([0,0,1])
        sphere.color([0.9,0.5,0])
        sphere.union(cube).union(cone).subtract(cylinder)
        
        cube2 = cube.clone().color([0.5,0.5,1]).translate(120)
        cube3 = cube.clone().translate([-25,150,0])
        cube3.rotate([0,50,100])
        
        
        return sphere.union([cube2,cube3])
        """
        content:"""
        #Yeah , we can use classes
        class Thingy extends CSGBase
          constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
            super
            shape = CAGBase.fromPoints([[0,0], [150,50], [0,-50]])
            shape.expand(20,25)
            shape = shape.extrude(offset:[0, 0, @thickness])
            
            cyl = new Cylinder(r:10, $fn:12, h:100, center:true)
        
            @union(shape).subtract(cyl).translate(@pos).rotate(@rot).color([1,0.5,0])
            
        #Here we create two new class instances
        thing = new Thingy(35)
        thing2 = new Thingy(25)
        
        res = thing.clone().mirroredX().color([0.2,0.5,0.6]).union(thing2)
        res.rotateX(37).rotateZ(5).translate([0,0,100])
        return res
        """
        content__:"""
        #another test 
        circle = new Circle(r:25,center:[10,10])
        rectangle = new Rectangle(size:25)
        
        circle.intersect(rectangle)
        c = circle.extrude(offset: [0, 0, 100], slices:100,twist:180)
        
        #r = rectangle.extrude(offset: [0, 0, 120], slices:1)
        
        ###
        tmp = new SpecialScrew()
        ###
        return c.color([0.9,0.4,0])
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
