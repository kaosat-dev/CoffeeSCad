define (require) ->
  THREE = require 'three'
  
  class GeometryVisitor
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
      return ""
     
  class CoffeeSCadVisitor extends GeometryVisitor
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
      geom = geometryObj.geometry
      position = geometryObj.position
      positionStr = ""
      if position.x != 0 or position.y != 0 or position.z != 0 #!= new THREE.Vector3()
        positionStr = ".translate([#{position.x},#{position.y},#{position.z}])"
      
      if geom instanceof THREE.CubeGeometry
          return "cube#{geometryObj.id} = new Cube({size:[#{geom.width},#{geom.depth},#{geom.height}]})"+positionStr
      else if geom instanceof THREE.CylinderGeometry
          return "cylinder#{geometryObj.id} = new Cylinder({r1:#{geom.radiusTop},r2:#{geom.radiusBottom},h:#{geom.height},center:true})"+positionStr
      else if geom instanceof THREE.SphereGeometry
          return "sphere#{geometryObj.id} = new Sphere({r:#{geom.radius},center:true})"+positionStr
    
  cubeGenerator = (size)->
    size = size or [20,20,20]
    cube = new THREE.Mesh( new THREE.CubeGeometry( size[0], size[1], size[2] ), new THREE.MeshNormalMaterial() )
    cube.accept = (visitor)=>
      visitor.visit(cube)
    
    #mesh's code /metadata to bind instances to their declaration in code
    ### 
    cube.meta = cube.meta or {}
    cube.meta.startIndex = 0
    cube.meta.blockLength = 0
    cube.meta.code = ""
    ###
    return cube
    
  cylinderGenerator = (height, r1, r2)->
    height = height or 30
    r1 = r1 or 10
    r2 = r2 or 10
    cylinder = new THREE.Mesh( new THREE.CylinderGeometry( r1, r2, height ), new THREE.MeshNormalMaterial() )
    cylinder.accept = (visitor)=>
      visitor.visit(cylinder)
    
    #mesh's code /metadata to bind instances to their declaration in code
    cylinder.meta = cylinder.meta or {}
    cylinder.meta.startIndex = 0
    cylinder.meta.blockLength = 0
    cylinder.meta.code = ""
    
    return cylinder
  
  sphereGenerator = (r)->
    r = r or 20
    sphere = new THREE.Mesh( new THREE.SphereGeometry( r ), new THREE.MeshNormalMaterial() )
    sphere.accept = (visitor)=>
      visitor.visit(sphere)
    
    #mesh's code /metadata to bind instances to their declaration in code
    sphere.meta = sphere.meta or {}
    sphere.meta.startIndex = 0
    sphere.meta.blockLength = 0
    sphere.meta.code = ""
      
    return sphere
  
  return {"CoffeeSCadVisitor":CoffeeSCadVisitor,"cubeGenerator":cubeGenerator,"cylinderGenerator":cylinderGenerator,"sphereGenerator",sphereGenerator}
