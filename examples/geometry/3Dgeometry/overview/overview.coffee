#Basic cube
cubeTest = new Cube({size:20})
#cube center as vector
cubeTest = new Cube({size:20,center:[-10, 10,-10]})
#cube center as booleans /numeric vector
cubeTest = new Cube({size:20,center:[-10,-10,false]})
#cube center as booleans vector
cubeTest = new Cube({size:20,center:[true,true,false]})
#Rounded cube radius specified, default corner resolution
#roundedCube = new Cube({size:20,r:5})

#Basic sphere
sphereTest = new Sphere()
#size set via radius
sphereTest = new Sphere({r:10, $fn:18})
#size set via diameter
sphereTest = new Sphere({d:10, $fn:18})
#size set via diameter, centered
sphereTest = new Sphere({d:20, $fn:18, center:false})
#size set via diameter, center set via vector
sphereTest = new Sphere({d:20, $fn:18, center:[10,10,10]})

#Basic cylinder
#radius set via radius parameter
cylinderTest = new Cylinder({r:10, $fn:18,h:25})
#radius set via diameter parameter
cylinderTest = new Cylinder({d:20, $fn:18,h:25})
#radius set via diameter parameter, centered
cylinderTest = new Cylinder({d:20, $fn:18,h:-25, center:[false,50,false]})
#radius set via diameter parameter, center set via vector
cylinderTest = new Cylinder({d:20, $fn:18,h:25, center:[10,10,10]})
#radius set via diameter parameter, center set via vector, rounded
cylinderTest = new Cylinder({d:20, $fn:25,h:35, center:[-45,20,false],rounded:true})

#uncomment based on what you want to see
assembly.add(cubeTest)
#assembly.add(sphereTest)
#assembly.add(cylinderTest)