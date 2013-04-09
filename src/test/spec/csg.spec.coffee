define (require)->
  csg = require "core/projects/csg/csg"
  CSGBase = csg.CSGBase
  CAGBase = csg.CAGBase
  Cube = csg.Cube
  Sphere = csg.Sphere
  Cylinder= csg.Cylinder
  Plane = csg.Plane
  hull = csg.hull
  Rectangle = csg.Rectangle
  Circle = csg.Circle
  utils = require "core/projects/csg/utils"
  
  
  
  describe "csg objects as elements of a hierarchy", ->
    it "csg objects can add  children to themselves", ->
      parent = new Cube()
      firstChild = new Sphere()
      seconChild = new Cylinder()
      parent.add(firstChild, seconChild)
      expect(parent.children).toEqual([firstChild,seconChild])
    
    it 'csg object can remove children from themselves', ->
      parent = new Cube()
      firstChild = new Sphere()
      seconChild = new Cylinder()
      parent.add(firstChild)
      parent.add(seconChild)
      expect(parent.children).toEqual([firstChild,seconChild])
      parent.remove(firstChild,seconChild)
      expect(parent.children).toEqual([])
    
    it "can change the hierarchy if added as a child of another object", ->
      parent = new Cube()
      otherParent = new Cube()
      child = new Sphere()
      
      parent.add(child)
      expect(parent.children).toEqual([child])
      expect(child.parent).toBe(parent)
      
      otherParent.add(child)
      expect(parent.children).toEqual([])
      expect(otherParent.children).toEqual([child])
      expect(child.parent).toBe(otherParent)
  
  describe "Options parsing utilities (not public api)", ->
    it 'has a centerParser, no input (should default to false)', ->
      options = {}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(5,5,5)
      expect(parsed).toEqual(expCenter)
    
    it 'has a centerParser, vector input', ->
      options = {"center":[0,0,5]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(0,0,5)
      expect(parsed).toEqual(expCenter)
    
    it 'has a centerParser, single boolean, false', ->
      options = {"center":false}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(5)
      expect(parsed).toEqual(expCenter)
      
    it 'has a centerParser, single boolean, true', ->
      options = {"center":true}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(0)
      expect(parsed).toEqual(expCenter)
    
      
    it 'has a centerParser, boolean array , all true', ->
      options = {"center":[true,true,true]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(0)
      expect(parsed).toEqual(expCenter)
    
    
    it 'has a centerParser, boolean array , all false', ->
      options = {"center":[false,false,false]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(5)
      expect(parsed).toEqual(expCenter)
      
    it 'has a centerParser, boolean array , first false', ->
      options = {"center":[false,true,true]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(5,0,0)
      expect(parsed).toEqual(expCenter)
    
    it 'has a centerParser, boolean array , first & second false', ->
      options = {"center":[false,false,true]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(5,5,0)
      expect(parsed).toEqual(expCenter)
    
    it 'has a centerParser, boolean array , second & last false', ->
      options = {"center":[true,false,false]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(0,5,5)
      expect(parsed).toEqual(expCenter)
    
    it 'has a centerParser, boolean and float array var1', ->
      options = {"center":[3,false,false]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(3,5,5)
      expect(parsed).toEqual(expCenter)
      
    it 'has a centerParser, boolean and float array var2', ->
      options = {"center":[3,true,2]}
      size = new csg.Vector3D(10)
      parsed = utils.parseCenter(options,"center",size.dividedBy(2), [0,0,0], csg.Vector3D)
      expCenter = new csg.Vector3D(3,0,2)
      expect(parsed).toEqual(expCenter)  

    
    it 'has a locationsParser', ->
      
      options = {"corners":["left"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "111011".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["right"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "110111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "101111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "11111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["right","left"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "111111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top","bottom"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "111111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top right"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "100111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top left"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "101011".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom right"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "10111".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom left"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "11011".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["left front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "111010".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["right front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "110110".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["left back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "111001".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["right back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "110101".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      #FULL
      options = {"corners":["top right front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "100110".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top right back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "100101".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top left front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "101010".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["top left back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "101001".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom right front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "10110".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom right back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "10101".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom left front"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "11010".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      options = {"corners":["bottom left back"]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "11001".toString(2)
      expect(parsed).toEqual(expBitMap)
      
      #even more complex
      ###
      options = {"corners":["bottom left back","top right front" ]}
      parsed = utils.parseOptionAsLocations(options,"corners","111111")
      expBitMap = "11001".toString(2)
      expect(parsed).toEqual(expBitMap)
      ###
      
  
  describe "CSG: Basic , configurable geometry (3d) ", ->
    #CUBE
    ###No support for splats/simple arguments, might stay this way 
    it 'has a Cube geometry, simple arguments', ->
      cube = new Cube(null,100)
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D()) 
    ###
    it 'has a Cube geometry, default settings', ->
      cube = new Cube()
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(0,0,0))
      
    it 'has a Cube geometry, object as arguments', ->
      cube = new Cube({size:100})
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(0,0,0))
      
    it 'has a Cube geometry, center as boolean:true', ->
      cube = new Cube({size:100,center:true})
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(-50,-50,-50))
    
    it 'has a Cube geometry, center as boolean:false', ->
      cube = new Cube({size:100,center:false})
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D())
    
    it 'has a Cube geometry, center as vector', ->
      cube = new Cube({size:100,center:[100,100,100]})
      expect(cube.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(50,50,50))
    
    it 'has a Cube geometry, size as vector', ->
      cube = new Cube({size:[100,5,50]})
      expect(cube.polygons[0].vertices[2].pos).toEqual(new csg.Vector3D(0,5,50))
    
    ###
    it 'has a Cube geometry, optional corner rounding , with rounding radius parameter, default rounding resolution', ->
      cube = new Cube({size:100,r:10})
      console.log cube
      expect(cube.polygons[0].vertices[2].pos).toEqual(new csg.Vector3D(0,5,50))
     
    it 'has a Cube geometry, optional corner rounding , with all rounding parameters', ->
      cube = new Cube({size:100,r:10,$fn:3})
      console.log cube
      expect(cube.polygons[0].vertices[2].pos).toEqual(new csg.Vector3D(0,5,50))
    ###  
    
    #SPHERE
    it 'has a Sphere geometry, size set by radius', ->
      sphere = new Sphere({r:50})
      expect(sphere.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(50,0,0))
    
    it 'has a Sphere geometry, size set by diameter', ->
      sphere = new Sphere({d:100})
      expect(sphere.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(50,0,0))
    
    it 'has a Sphere geometry, settable resolution', ->
      sphere = new Sphere({d:25,$fn:15})
      expect(sphere.polygons.length).toEqual(120)
    
    it 'has a Sphere geometry, center as boolean', ->
      sphere = new Sphere({d:25, center:true})
      expect(sphere.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(12.5,0,0))
    
    it 'has a Sphere geometry, center as vector', ->
      sphere = new Sphere({d:25, center:[100,100,100]})
      expect(sphere.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(112.5,100,100))
    
    #CYLINDER
    it 'has a Cylinder geometry, top and bottom radius set by radius parameter, default height', ->
      cylinder = new Cylinder({r:25,$fn:5})
      expect(cylinder.polygons[14].vertices[1].pos).toEqual(new csg.Vector3D(25,6.123031769111886e-15,1))

    it 'has a Cylinder geometry, top and bottom radius set by radius parameter, specified height', ->
      cylinder = new Cylinder({r:25, h:10,$fn:5})
      expect(cylinder.polygons[14].vertices[0].pos).toEqual(new csg.Vector3D(0,0,10))
    
    it 'has a Cylinder geometry, top and bottom radius set by diameter parameter', ->
      cylinder = new Cylinder({d:100,$fn:3})
      expect(cylinder.polygons[3].vertices[2].pos).toEqual(new csg.Vector3D(-25.00000000000002,43.30127018922192,0))
    
    it 'has a Cylinder geometry, with settable resolution', ->
      cylinder = new Cylinder({d:25,$fn:15})
      expect(cylinder.polygons.length).toEqual(45)
    
    it 'has a Cylinder geometry, center as boolean', ->
      cylinder = new Cylinder({d:25, center:true, $fn:5})
      expect(cylinder.polygons[0].vertices[1].pos).toEqual(new csg.Vector3D(12.5,0,-0.5))
    
    it 'has a Cylinder geometry, center as vector', ->
      cylinder = new Cylinder({d:25, center:[100,100,100], $fn:5})
      expect(cylinder.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(100,100,99.5))
      
    it 'has a Cylinder geometry, with optional end rounding', ->
      cylinder = new Cylinder({d:25, center:[100,100,100], $fn:5})
      expect(cylinder.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(100,100,99.5))
      
      
  describe "CSG: Basic , configurable geometry (2d) ", ->
    #SQUARE
    it 'has a Rectangle geometry, default settings', ->
      rectangle = new Rectangle()
      console.log rectangle
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(0,1))
      
    it 'has a Rectangle geometry, object as arguments', ->
      rectangle = new Rectangle({size:100})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(0,100))
      
    it 'has a Rectangle geometry, center as boolean:true', ->
      rectangle = new Rectangle({size:100,center:true})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(-50,50))
    
    it 'has a Rectangle geometry, center as boolean:false', ->
      rectangle = new Rectangle({size:100,center:false})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(0,100))
    
    it 'has a Rectangle geometry, center as vector', ->
      rectangle = new Rectangle({size:100,center:[100,100]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(50,150))
    
    it 'has a Rectangle geometry, size as vector', ->
      rectangle = new Rectangle({size:[100,5],center:true})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(-50,2.5))
    
    it 'has a Rectangle geometry, optional corner rounding , with rounding radius parameter, default rounding resolution, all corners', ->
      rectangle = new Rectangle({size:10,cr:2,$fn:5})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,2))
    
    it 'has a Rectangle geometry, optional corner rounding , with rounding radius parameter, default rounding resolution, left corners', ->
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["left"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,2))
    
    it 'has a Rectangle geometry, corner rounding , various corners', ->
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["right"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,0))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["left"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,2))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["front"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,0))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["back"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,2))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["front left"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,0))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["front right"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,0))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["back left"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,2))
      
      rectangle = new Rectangle({size:10,cr:2,$fn:5, corners:["back right"]})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(10,0))
      
      
    #CIRCLE
    it 'has a Circle geometry, size set by radius', ->
      circle = new Circle({r:50})
      expect(circle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(50,0))
    
    it 'has a Circle geometry, size set by diameter', ->
      circle = new Circle({d:100})
      expect(circle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(50,0))
    
    it 'has a Circle geometry, settable resolution', ->
      circle = new Circle({d:25,$fn:15})
      expect(circle.sides.length).toEqual(15)
    
    it 'has a Circle geometry, center as boolean', ->
      circle = new Circle({d:25, center:true})
      expect(circle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(12.5,0))
    
    it 'has a Circle geometry, center as vector', ->
      circle = new Circle({d:25, center:[100,100]})
      expect(circle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(112.5,100))
  
  describe "there is a simplified , optional api for fast geometry creation and display",->
    it "has a cube shortcut default parent (rootAssembly)", ->
      cube = csg.cube({size:100})
      expect(cube.polygons[5].vertices[2].pos).toEqual(new csg.Vector3D(100,100,100))
    
    it "has a cube shortcut, custom parent ", ->
      parent = new Cube()
      cube = csg.cube
      cube = cube({size:100},parent)
      expect(cube.polygons[5].vertices[2].pos).toEqual(new csg.Vector3D(100,100,100))
      expect(cube.parent).toBe(parent)
      
    it "has a sphere shortcut", ->
      #this is the equivalent of
      # sphere = new Sphere({r:50})
      # assembly.add(sphere)
      sphere = csg.sphere({r:50})
      expect(sphere.polygons[0].vertices[0].pos).toEqual(new csg.Vector3D(50,0,0))
    
    it "has a cylinder shortcut", ->
      #this is the equivalent of
      # cylinder = new Cylinder({r:50})
      # assembly.add(cylinder)
      cylinder = csg.cylinder({r:25,$fn:5})
      expect(cylinder.polygons[14].vertices[1].pos).toEqual(new csg.Vector3D(25,6.123031769111886e-15,1))
      
    it "has a rectangle shortcut", ->
      rectangle = csg.rectangle({size:100})
      expect(rectangle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(0,100))
      
    it "has a circle shortcut", ->
      #this is the equivalent of
      # circle = new circle({r:50})
      # assembly.add(circle)
      circle = csg.circle({r:50})
      expect(circle.sides[0].vertex0.pos).toEqual(new csg.Vector2D(50,0))
  
  describe "Lines, points, and all shapes can be translated, rotated, scaled ", ->
    #TODO: see when / IF the various transformbase operations actually apply
  
  describe "CSG transforms", ->
    it 'can translate a csg object', ->
      cube = new Cube({size:100,center:true})
      cube.translate([100,0,0])
      expect(cube.polygons[0].vertices[0].pos.x).toBe(50)
      
    it 'can rotate a csg object', ->
      cube = new Cube({size:100,center:true})
      cube.rotate([45,45,45])
      expect(cube.polygons[0].vertices[1].pos.x).toBe(25.000000000000004)
    
    it 'can scale a csg object', ->
      cube = new Cube({size:100,center:true})
      cube.scale([100,100,100])
      expect(cube.polygons[0].vertices[1].pos.z).toBe(5000)
  
  describe "CSG boolean operations", ->
    beforeEach -> 
      @addMatchers 
        toBeEqualToObject: (expected) -> 
          _.isEqual @actual, expected
      
    it 'can do unions between two 3d shapes' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.union(cube2)
      expect(cube.polygons.length).toBe(14)
    
    it 'can do unions between multiple 3d shapes' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      cube3 = new Cube(size:100,center:[90,90,-90])
      cube.union([cube2,cube3])
      expect(cube.polygons.length).toBe(16)
      
    it 'can do substractions between 3d shapes' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.subtract(cube2)
      expect(cube.polygons.length).toBe(10)
    
    it 'can do intersection between 3d shapes' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.intersect(cube2)
      expect(cube.polygons.length).toBe(6)
    
    it 'can slice a csg object by a plane' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      plane = Plane.fromNormalAndPoint([0, 0, 1], [0, 0, 25])
      cube.cutByPlane(plane)
      expect(cube.polygons.length).toBe(6)
      
  describe "CSG 2d shapes manipulation", ->
    beforeEach -> 
      @addMatchers 
        toBeEqualToObject: (expected) -> 
          _.isEqual @actual, expected
          
    it 'can do unions between 2d shapes' , ->
      circle = new Circle({r:25,center:[0,0],$fn:10})
      rectangle = new Rectangle({size:20,center:true}).translate([100,0,0])
      circle.union(rectangle)
      expect(circle.sides.length).toBe(14)
    
    it 'can do subtraction between 2d shapes' , ->
      circle = new Circle({r:25,center:[0,0],$fn:10})
      rectangle = new Rectangle({size:20,center:true}).translate([100,0,0])
      circle.subtract(rectangle)
      expect(circle.sides.length).toBe(10)
    
    it 'can do intersections between 2d shapes' , ->
      circle = new Circle({r:25,center:[0,0],$fn:10})
      rectangle = new Rectangle({size:25,center:true})
      circle.intersect(rectangle)
      expect(circle.sides.length).toBe(4)
    
    it 'can extrude 2d shapes', ->
      circle = new Circle({r:10,center:[0,0],$fn:10})
      cylinder = circle.extrude(offset: [0, 0, 100],twist:180,slices:20)
      expect(cylinder.polygons.length).toBe(402)
    
    it 'can generate a convex hull around 2d shapes', ->
      circle = new Circle({r:25,center:[0,0],$fn:10}).translate([0,-25,0])
      rectangle = new Rectangle({size:20,center:true}).translate([100,0,0])
      hulled = hull([circle,rectangle])
      expect(hulled.sides.length).toBe(9)
  
  describe "Base CSG class utilities", ->
    
    it 'clone csg objects' , ->
      cube = new Cube({size:100,center:true})
      cube2 = cube.clone()
      expect(cube2.polygons.length).toBe(cube.polygons.length)
  
  describe "CSG object can have 'children' to define object assemblies", ->
    it 'Can add any csg object as child' , ->
      cube = new Cube({size:100,center:true})
      cube2 = cube.clone()
      sphere = new Sphere({size:20})
      
      cube.add(cube2)
      cube.add(sphere)
      expect(cube.children.length).toBe(2)
      expect(cube.children[0]).toBe(cube2)
      expect(cube.children[1]).toBe(sphere)
      
    it 'Can add a 2d (cag) object as child, extruding it automatically by a height of 1' , ->
      cube = new Cube({size:100,center:true})
      rectangle = new Rectangle({size:10})
      cube.add(rectangle)
      expect(cube.children.length).toBe(1)
      expect(cube.children[0].polygons[9].vertices[0].pos._z).toBe(1)
   
  describe "Advances 2d & 3d shapes manipulation", ->
    
    it 'can generate valid (stl compatible) data out of 3d geometry' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube({size:100,center:[20,20,0]})
      cube.subtract(cube2)
      stlCube = cube.fixTJunctions()
      expect(cube.polygons.length).toBe(10)
    
    it 'can generate valid (stl compatible) data out of tranformed 3d geometry' , -> 
      cube = new Cube({size:100,center:true})
      cube.rotate([25,10,15])
      stlCube = cube.fixTJunctions()
      expect(stlCube.polygons.length).toBe(6)
    
    it 'can generate valid (stl compatible) data out of "hulled", and extruded 2d geometry' , ->
      circle = new Circle({r:25,center:[10,50,20], $fn:6})
      circle2 = new Circle({r:25,center:[10,100,20], $fn:6})
      #rectangle = new Rectangle({size:10})
      hulled = hull([circle,circle2])
      hulledExtruded = hulled.extrude({offset:[0,0,1],steps:1,twist:0})
      hulledExtruded.fixTJunctions()
      expect(hulledExtruded.polygons.length).toBe(182)
   
   ###Can get slow, hence why it is commented
   describe "Speed and limitations", ->
     it 'does not cause recursion/stack overflow error with more detailed geometry' , ->
       sphere = new Sphere({r:100,$fn:100})
       sphere2 = new Sphere({r:100,$fn:100})
       
       expect(sphere.union(sphere2)).not.toThrow(new RangeError())
   ###  
     
    
    
    

