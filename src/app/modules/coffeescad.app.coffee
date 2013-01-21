define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  
  vent = require './core/vent'
  Settings = require './core/settings/settings'
  
  MenuView = require './core/menuView'
  Project = require './core/projects/project'
  
  SettingsView = require './core/settings/settingsView'
  ModalRegion = require './core/utils/modalRegion' 
  

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
      
      @editors = []
      @exporters = {}
      @connectors = {}
      
      #Exporters
      BomExporter = require './exporters/bomExporter/bomExporter'
      StlExporter = require './exporters/stlExporter/stlExporter'
      
      @exporters["stl"] = new StlExporter()
      @exporters["bom"] = new BomExporter()
      
      #events
      @on("initialize:before",@onInitializeBefore)
      @on("initialize:after",@onInitializeAfter)
      @on("start", @onStart)
      @vent.on("app:started", @onAppStarted)
      @vent.on("settings:show", @onSettingsShow)
      @vent.on("bomExporter:start", ()=> @exporters["bom"].start({project:@project}))
      @vent.on("stlExporter:start", ()=> @exporters["stl"].start({project:@project}))
      
      @addRegions @regions
      @initLayout()
      @initData()
     
    initLayout:=>
      @menuView = new MenuView
        connector: @connectors
        exporters: @exporters
        
      @headerRegion.show @menuView
    
    initSettings:->
      @settings = new Settings()
      @bindTo(@settings.get("General"), "change", @settingsChanged)
    
    initData:->
      @project = new Project()
      @project.createFile
        name:"config"
        #FIXME: apparently the csg refac broken the TJUNCTION system: MUST FIX (Error: !sidemapisempty)
        content:"""
        #just a comment :fix me
        toto = new Cube(size:[50,100,50])
        c = new Cylinder(h:300, r:20,$fn:3)
        toto = toto.subtract(c.translate([10,0,-150]))
        assembly.add(toto)
        """
        
        contentsfd:"""
        #just a comment :fix me
        class Thinga extends Part
          constructor:(options) ->
            super options
            @toto = new Cube(size:[50,100,50])
            c = new Cylinder(h:300, r:20,$fn:3)
            @union(@toto)
            @subtract(c.translate([10,0,-150]))
        
        thinga1 = new Thinga()
        
        assembly.add(thinga1)
        """
        content_basic:"""
        #just a comment
        cb = new Cube({size:[50,100,50]})
        project.add(cb)
        """
        content____s:"""
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
        #thinga3 = thinga2.clone()
        assembly.add(thinga1.translate([-150,0,0]))
        
        
        wobble = new WobblyBobbly(rot:[5,25,150],pos:[-100,150,10])
        wobble2 = new WobblyBobbly(pos:[0,10,20])
        wobble3 = new WobblyBobbly(pos:[-100,10,20])
        
        assembly.add(wobble)
        assembly.add(wobble2)
        assembly.add(wobble3)
        """
        content_1:"""
        #This is the project's main configuration file
        #It is better to keep global configuration elements here
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
        content____:"""
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
        
        contentzer:"""
        #bla
        cube = new Cube(size: 100)
        
        cube2 = cube.clone()
        cube.rotate([50,50,0]).translate([2,1,50])
        
        
        return cube.union(cube2)
        """
        contentdfg:"""
        #2d hull
        #circle = new Circle(r:10,center:[0,0])
        rectangle = new Rectangle(size:50)
        rectangle2 = new Rectangle(size:20)
        rectangle2.translate([100,0,0])
        
        hulled = quickHull2d(rectangle,rectangle2)
        hulled = hulled.extrude(offset: [0, 0, 100])
        
        return hulled.color([0.9,0.4,0])
        """
        content_dsfd:"""
        #2d hull
        circle = new Circle(r:25,center:[0,0],$fn:10)
        rectangle = new Rectangle(size:20)
        rectangle2 = new Rectangle(size:20)
        rectangle2.translate([100,0,0])
        circle.translate([0,-25,0])
        hulled = quickHull2d(circle,rectangle2)
        hulled = hulled.extrude(offset: [0, 0, 100],twist:180,slices:100)
        
        return hulled.color([0.9,0.4,0])
        """
      ###   
      @project.createFile
        name:"assembly"
      @project.createFile
        name:"testPart"
      ###
      
    onStart:()=>
      console.log "app started"
      @codeEditor.start()
      @visualEditor.start()
      
    onAppStarted:(appName)->
      console.log "I see app: #{appName} has started"
      
    onSettingsShow:()=>
      settingsView = new SettingsView
        model : @settings 
      
      modReg = new ModalRegion({elName:"settings",large:true})
      modReg.show settingsView
      
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
