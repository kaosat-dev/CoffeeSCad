#so, I heard you want to do some boolean operations ? well here we go!
#first let's create a cube
cube = new Cube({size:20}).color([0.9,0.5,0.1])
#and a cylinder
cylinder = new Cylinder({r:5,h:20,center:false})
cylinder.color([0.9,0.1,0.3,1])
#also, our friendly friend, the sphere
sphere = new Sphere({r:25})
sphere.color([0,0.5,0.8,1])

cube2 = new Cube({size:10})
#Boolean operations
#union
cube.union(cube2)
#substraction
cube.subtract(cylinder)
#intersection
cube.intersect(sphere)

assembly.add(cube)