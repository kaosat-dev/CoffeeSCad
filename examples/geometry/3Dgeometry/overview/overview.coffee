#Basic cube
cube = new Cube({size:20})
#cube center as vector
cube = new Cube({size:20,center:[-10, 10,-10]})
#cube center as booleans /numeric vector
cube = new Cube({size:20,center:[-10,-10,false]})
#cube center as booleans vector
cube = new Cube({size:20,center:[true,true,false]})
#Rounded cube radius specified, default corner resolution
#roundedCube = new Cube({size:20,r:5})

#Basic sphere
sphere = new Sphere()
#size set via radius
sphere = new Sphere({r:10, $fn:18})
#size set via diameter
sphere = new Sphere({d:10, $fn:18})
#size set via diameter, centered
sphere = new Sphere({d:20, $fn:18, center:false})
#size set via diameter, center set via vector
sphere = new Sphere({d:20, $fn:18, center:[10,10,10]})

#Basic cylinder
#radius set via radius parameter
cylinder = new Cylinder({r:10, $fn:18,h:25})
#radius set via diameter parameter
cylinder = new Cylinder({d:20, $fn:18,h:25})
#radius set via diameter parameter, centered
cylinder = new Cylinder({d:20, $fn:18,h:-25, center:[false,50,false]})
#radius set via diameter parameter, center set via vector
cylinder = new Cylinder({d:20, $fn:18,h:25, center:[10,10,10]})
#radius set via diameter parameter, center set via vector, rounded
cylinder = new Cylinder({d:20, $fn:25,h:35, center:[-45,20,false],rounded:true})

assembly.add(cube)
#assembly.add(sphere)
assembly.add(cylinder)