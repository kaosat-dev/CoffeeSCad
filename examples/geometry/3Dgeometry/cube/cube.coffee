#Cubes!

#simple cube
cube1 = new Cube({size:20})

#coloured, semitransperent cube, RGBA (red green blue alpha)
#values from 0 to 1
cube2 =  new Cube({size:20}).color([0, 1, 0, 0.75])

#slightly more complex cube and different format
cube3 = new Cube(
  {
    size: [10, 15, 5] #size can be an array
    center: true #center: true centers the object
  })

#centering can be complex:
cube4 = new Cube(
  {
    size: [10, 15, 5]
    center: [true, true, false] #see how usefull that is!?
  })

cube5 = new Cube(
  {
    size: [10, 15, 5]
    center: [5, 5, false] #you can mix numbers and bools
  })

#finaly, 'assembly.add(object) to add an object to the scene
#change the cube below to see the different examples above:
assembly.add(cube1)