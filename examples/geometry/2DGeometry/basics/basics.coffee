#2d geometry
#square/rectangle
shape2d = new Rectangle({size:10,center:[0,0]})

#and circle
shape2d = new Circle({r:10,$fn:15,center:[10,true]})

#2d polygon shape from points
shape2d = CAGBase.fromPoints(
  [
    [0,0],
    [0,15],
    [15,0]
  ])
 
shape3d = shape2d.extrude({offset:[0,0,10]})
assembly.add(shape3d)
