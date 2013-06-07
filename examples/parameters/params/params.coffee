include "config.coffee"

cube = new Cube({size:[params.width,params.depth,params.height]}).color(params.boxColor)

wheels= null
if params.wheels == "boxy"
  wheels = new Cube({size:10, center:[0,0,params.height]})
else 
  wheels = new Sphere({r:15,center:[0,0,params.height]})
cube.add(wheels.color(params.boxColor2))
assembly.add(cube)



assembly.add( new Cube({size:params.vary,center:[params.xpos,params.ypos,params.zpos]}).color(params.boxColor2))

assembly.add( new Sphere({r:10,center:true}) )

assembly.add( new Cube({size:15,center:true}) )

assembly.add( new Cylinder({r:10,h:30,center:true}) )
