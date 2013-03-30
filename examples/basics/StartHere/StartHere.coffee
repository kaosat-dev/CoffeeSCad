#let's start at the beginning shall we ?
#the begining is a cube (we all know that don't we?) so let's draw a cube:

cube = new Cube({size:42})#create an instance of a superb 42x42x42 cube

#now "draw" it
assembly.add(cube)

#the "assembly" is the root element of your scene/project, you can add 
#as many elements to it as you want

#every element you draw create also have sub elements:
#let's create a sphere
sphere = new Sphere({r:42})

#and add it as a child element to the cube
cube.add(sphere)
#the sphere will ge drawn too , as it is a sub element of cube

#now you can turn the view around, see that there is indeed a cube and a 
#sphere , and that they are both selectable individually (right click)
