#Cylinders and Spheres!

#Simple Sphere:
shape1 = new Sphere({r:20})


shape2 = new Sphere(
  {
    r:20 #r: is the radius
    $fn:32 #$fn is a modifier to change
      #the resolution of a round object.
  })

#Cylinders have a few more modifiers:
shape3 = new Cylinder(
  {
    r: 15
    h: 10 #cylinders need a height!
    $fn:32
  })
  
shape4 = new Cylinder(
  {
    r:15
    h:10
    $fn:6 #this can be usefull for making
      #hex, cube or even triangular cylinders
    center: [20, 20, false] #as with cubes,
      #you can use center: to position it.
  })

shape5 = new Cylinder(
  {
    r1:20 #you can use r1 and r2 to makea cone
    r2:5
    h:30
  })
  
shape6 = new Cylinder(
  {
    d:20 #you can use d: (diameter) instead of r:
    h:10
  })

assembly.add(shape6)