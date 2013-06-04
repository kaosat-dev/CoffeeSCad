define (require) ->
  require 'three'
  require 'ThreeCSG'
  
  #TODO: where to do canonicalization and normalization?
  #TODO: review inheritance : basic geometry (cube, sphere) should not have children etc (like "mesh") but should have position, rotation etc
  #TODO: add connectors ?
  
  class ObjectBase extends THREE.Mesh
    #base class regrouping feature of THREE.Mesh and THREE.CSG
    
    constructor:( geometry, material )->
      if not material?
        material = new THREE.MeshBasicMaterial( { color: 0xffffff, wireframe: false } )
        shine= 1500
        spec= 1000
        opacity = 1
        material = new THREE.MeshPhongMaterial({color:  0xFFFFFF , shading: THREE.SmoothShading,  shininess: shine, specular: spec, metal: false}) 
      super(geometry, material)
      THREE.Mesh.call( @, geometry, material )
      
      #FIXME: see THREE.jS constructors thingamajig
      #console.log @prototype
      #Object.create(@prototype)
      @bsp = null
      
      @connectors = []
    
    
    color:(rgba)->
      @material.color = rgba
      
    
    union:(object)=>
      @bsp = new ThreeBSP(@)
      if not object.bsp?
        object.bsp = new ThreeBSP(object)
      @bsp = @bsp.union( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
    subtract:(object)=>
      @bsp = new ThreeBSP(@)
      
      object.bsp = new ThreeBSP(object)
      @bsp = @bsp.subtract( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
      @geometry.computeBoundingBox()
      @geometry.computeCentroids()
      @geometry.computeFaceNormals();
      @geometry.computeBoundingSphere()
      
    intersect:=>
      @bsp = @bsp.intersect( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
    inverse:=>
      @bsp = @bsp.invert()
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
  
  return ObjectBase