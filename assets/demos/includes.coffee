include("includee")
include "dummy"

cube = new Cube
  size: 50
  
sphere = mySphere()
tmp = cube.union(sphere)

return tmp

####

mySphere=()->
 s =new Sphere
  r: 100
 return s