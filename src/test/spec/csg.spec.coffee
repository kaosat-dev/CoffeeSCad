define (require)->
  base = require "modules/core/projects/csg/csg"
  CSGBase = base.CSGBase
  CAGBase = base.CAGBase
  shapes3d = require 'modules/core/projects/csg/csg.geometry'
  Cube = shapes3d.Cube
  Sphere = shapes3d.Sphere
  Cylinder= shapes3d.Cylinder
  maths = require 'modules/core/projects/csg/csg.maths'
  Plane = maths.Plane
  
  
  describe "CSG transforms", ->
    it 'can translate a csg object', ->
      cube = new Cube(size:100)
      cube.translate([100,0,0])
      expect(cube.polygons[0].vertices[0].pos.x).toBe(100)
      
    it 'can rotate a csg object', ->
      cube = new Cube(size:100)
      cube.rotate([45,45,45])
      expect(cube.polygons[0].vertices[1].pos.x).toBe(85.35533905932736)
    
    it 'can scale a csg object', ->
      cube = new Cube(size:100)
      cube.scale([100,100,100])
      expect(cube.polygons[0].vertices[1].pos.z).toBe(10000)
  
  describe "CSG boolean operations", ->
      
    it 'can do unions between two csg objects' , ->
      cube = new Cube(size:100)
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.union(cube2)
      expect(cube.polygons.length).toBe(14)
      
    it 'can do substractions between two csg objects' , ->
      cube = new Cube(size:100)
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.subtract(cube2)
      expect(cube.polygons.length).toBe(10)
    
    it 'can do intersection between two csg objects' , ->
      cube = new Cube(size:100)
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.intersect(cube2)
      expect(cube.polygons.length).toBe(6)
    
    it 'can slice a csg object by a plane' , ->
      cube = new Cube(size:100)
      cube2 = new Cube(size:100,center:[90,90,0])
      plane = Plane.fromNormalAndPoint([0, 0, 1], [0, 0, 25])
      cube.cutByPlane(plane)
      expect(cube.polygons.length).toBe(6)
      
