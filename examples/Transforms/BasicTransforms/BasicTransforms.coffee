include "config.coffee"

cube = new Cube({size:20}).color([0.9,0.5,0.1])
cube.subtract(new Cylinder({r:5,h:20,center:true}))
log.info(cube.position)
cube.translate([10,10,0])
log.info(cube.position)

log.info(cube.rotation)
#cube.rotate([0,25,10])
log.info(cube.rotation)

assembly.add(cube)