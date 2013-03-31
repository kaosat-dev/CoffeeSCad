cube = new Cube({size:20}).color([0.9,0.5,0.1])

#translate
greenCube = cube.clone().translate([30,0,0])
#color it so it is visually identifiable
greenCube.color([0.2,0.8,0.2])#greenish
#rotate
redCube = cube.clone().rotate([45,45,45]).translate(40)
redCube.color([1,0,0])
#scale
blueCube = cube.clone().scale([3,1,1])
blueCube.translate([-40,-30,0])#we also translate it to get it out of way
blueCube.color([0,0,1])

assembly.add(cube)
assembly.add(greenCube)
assembly.add(redCube)
assembly.add(blueCube)
