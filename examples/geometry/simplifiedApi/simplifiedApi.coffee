#now you can also use a simmplified api to define basic shapes

#for cubes:
cube1=cube({size:10, center:[-25,-25,0]})
#the above is the same as 
#cube1 = new Cube({size:20,center:[-25,-25,0]})
#assembly.add(cube1)

#for spheres:
sphere1 = sphere({r:10})
#the above is the same as 
#sphere1 = new Sphere({r:10})
#assembly.add(sphere1)

#same goes for cylinders
cylinder1 = cylinder({r:10,h:20,center:[0,30,0]})

#circles
circle2 = circle({r:10,center:10})

#and rectangles
rectangle1 = rectangle({size:10,center:[-20,30]})

#for all the helpers above, the options you pass are the
#same as you would to their normal constructors

#you can also pass in a second parameter (besides the options hash)
#to set the object's parent
#for example

redCube = cube({size:30,center:[-50,-50,0]}).color([1,0,0])
#see here
greenSphere = sphere({r:20,center:-50,50},redCube).color([0,1,0])
#the green sphere's parent is the red cube