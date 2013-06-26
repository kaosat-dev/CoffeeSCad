define (require) ->
  THREE = require 'three'
  
  class GeometryVisitor
    #base class for all the visitors/ code generators
    constructor:->
      #TODO: this (instance type counting) should be done via instrumentation  . (see esprima) ??
      @geomInstanceIndices = {}
      @geomInstanceIndices["cube"]=0
      @geomInstanceIndices["sphere"]=0
      @geomInstanceIndices["cylinder"]=0
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
      return ""
     
  class CoffeeSCadVisitor extends GeometryVisitor
    
    constructor:->
      super()
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
      geom = geometryObj.geometry
      position = geometryObj.position
      positionStr = ""
      if position.x != 0 or position.y != 0 or position.z != 0 #!= new THREE.Vector3()
        positionStr = ".translate([#{position.x},#{position.y},#{position.z}])"
      
      #if (Object.prototype.toString.call(modifier) === '[object Array]')
      if geom instanceof THREE.CubeGeometry
          id = @geomInstanceIndices["cube"]
          meshCode = "cube#{id} = new Cube({size:[#{geom.width},#{geom.depth},#{geom.height}],center:true})"+positionStr
          @geomInstanceIndices["cube"] += 1
          return meshCode
      else if geom instanceof THREE.CylinderGeometry
          id = @geomInstanceIndices["cylinder"]
          meshCode =  "cylinder#{id} = new Cylinder({r1:#{geom.radiusTop},r2:#{geom.radiusBottom},h:#{geom.height},center:true})"+positionStr
          @geomInstanceIndices["cylinder"] += 1
          return meshCode
      else if geom instanceof THREE.SphereGeometry
          id = @geomInstanceIndices["sphere"]
          meshCode = "sphere#{id} = new Sphere({r:#{geom.radius},center:true})"+positionStr
          @geomInstanceIndices["sphere"] += 1
          return meshCode
  
  class OpenJSCadVisitor extends GeometryVisitor
    constructor:->
      super()
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
  
  class OpenSCadVisitor extends GeometryVisitor
    constructor:->
      super()
    
    visit:(geometryObj)=>
      console.log("visiting", geometryObj)
      geom = geometryObj.geometry
      position = geometryObj.position
      positionStr = ""
      if position.x != 0 or position.y != 0 or position.z != 0 #!= new THREE.Vector3()
        positionStr = ".translate([#{position.x},#{position.y},#{position.z}])"
      
      if geom instanceof THREE.CubeGeometry
          id = @geomInstanceIndices["cube"]
          meshCode = "cube(size=[#{geom.width},#{geom.depth},#{geom.height}],center=true)"+positionStr
          @geomInstanceIndices["cube"] += 1
          return meshCode
      else if geom instanceof THREE.CylinderGeometry
          id = @geomInstanceIndices["cylinder"]
          meshCode =  "cylinder(r1=#{geom.radiusTop},r2=#{geom.radiusBottom},h=#{geom.height},center:true)"+positionStr
          @geomInstanceIndices["cylinder"] += 1
          return meshCode
      else if geom instanceof THREE.SphereGeometry
          id = @geomInstanceIndices["sphere"]
          meshCode = "sphere(r=#{geom.radius},center=true})"+positionStr
          @geomInstanceIndices["sphere"] += 1
          return meshCode
  
  
  cubeGenerator = (size)->
    size = size or [20,20,20]
    cube = new THREE.Mesh( new THREE.CubeGeometry( size[0], size[1], size[2] ), new THREE.MeshNormalMaterial() )
    cube.accept = (visitor)=>
      visitor.visit(cube)
    
    #mesh's code /metadata to bind instances to their declaration in code
    cube.meta = cube.meta or {}
    cube.meta.startIndex = 0
    cube.meta.blockLength = 0
    cube.meta.code = ""
    
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
  
  return {"CoffeeSCadVisitor":CoffeeSCadVisitor,"OpenJSCadVisitor":OpenJSCadVisitor,"OpenSCadVisitor":OpenSCadVisitor, "cubeGenerator":cubeGenerator,"cylinderGenerator":cylinderGenerator,"sphereGenerator",sphereGenerator}
