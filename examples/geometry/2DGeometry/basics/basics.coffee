#2d geometry
#square
shape2d = new Rectangle({size:10,center:[0,0]})

#roundedsquare
shape2d = new Rectangle({size:10,center:true,cr:2,$fn:15})

#square rounded at specific corner
shape2d = new Rectangle({size:[20,20],cr:1,$fn:15,center:[true,-10], corners:["left front"]})


#shape2d = new Circle({r:10,$fn:15,center:[10,true]})
#square rounded at specific corner
#shape2d = new Rectangle({size:20,center:false,cr:2,$fn:5, corners:["front"]})

###
size=new Vector2D(20,20)
center = size.dividedBy(2).negated()
cornerRadius=2
cornerResolution=5

sizeOffset = new Vector2D(cornerRadius*2,cornerRadius*2)
adjustedSize = size.minus(sizeOffset)
rect = new Rectangle({size:adjustedSize,center:center.plus(sizeOffset.dividedBy(2))})
rect = rect.expand(cornerRadius, cornerResolution)

rect2 = new Rectangle({size:size.minus(new Vector2D(0,cornerRadius)),center:center.plus(new Vector2D(0,cornerRadius))})
cutoffrect = rect2.clone()
shape2d = rect2.intersect(rect)
###

shape3d = shape2d.extrude({offset:[0,0,10]})
assembly.add(shape3d)
#assembly.add(rect.extrude({offset:[0,0,10]}).color([0,0,1]))
#assembly.add(cutoffrect.extrude({offset:[0,0,10]}).color([1,0,0]))
