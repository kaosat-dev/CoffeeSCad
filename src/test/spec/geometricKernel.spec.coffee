define (require)->
  ObjectBase = require "core/projects/kernel/geometry/base"
  
    
  describe "CSG boolean operations", ->
    beforeEach -> 
      @addMatchers 
        toBeEqualToObject: (expected) -> 
          _.isEqual @actual, expected
          
    it 'can do substractions between 3d shapes' , ->
      c1 = new THREE.CubeGeometry( 3, 3, 3 )
      console.log "simple cube", c1
      cube = new ObjectBase new THREE.CubeGeometry( 100, 100, 100 )
      sphere = new ObjectBase new THREE.SphereGeometry( 1.8, 32, 32 )
        
      cube2 = new ObjectBase new THREE.CubeGeometry(100, 100, 50 )
      cube2.position.x = -90
      cube2.position.y = -20
      
      console.log "original cube", cube.geometry
      cube.subtract(cube2)
      console.log "result cube", cube.geometry
    
    ###  
    it 'can do unions between two 3d shapes' , ->
      cube = new Cube({size:100,center:true})
      cube2 = new Cube(size:100,center:[90,90,0])
      cube.union(cube2)
      expect(cube.polygons.length).toBe(14)
      
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
   ###

