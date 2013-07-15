include "config.coffee"

#dimentions and position of testCube can be set via the params editor
testCube = new Cube({size:[params.width,params.depth,params.height]}).color(params.boxColor)

wheels= null
if params.wheels == "boxy"
  wheels = new Cube({size:10, center:[0,0,params.height]})
else 
  wheels = new Sphere({r:15,center:[0,0,params.height]})
testCube.add(wheels.color(params.boxColor2))
assembly.add(testCube)

#substract a cube, whose size and positions is settable via the params editor
sub = new Cube({size:params.vary,center:[params.xpos,params.ypos,params.zpos]}).color(params.boxColor2)
testCube.subtract(sub)

#show a nice semi transparent cube the same shape as the substracted cube
overlay = sub.clone()
overlay.color([params.boxColor2[0],params.boxColor2[1],params.boxColor2[2],0.5])
assembly.add(overlay)
