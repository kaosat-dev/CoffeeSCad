#just a comment

cube = new Cube({size:20}).color([0.9,0.5,0.1])

otherCube = cube.clone().translate([10,10,50])

cube.translate([10,10,-10])


assembly.add(cube)
assembly.add(otherCube)

log.level = log.DEBUG
log.info(cube.position)


