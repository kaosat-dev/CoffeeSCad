circle1 = new Circle(r:25,center:[0,0],$fn:10)
rectangle1 = new Rectangle(size:20)
rectangle2 = new Rectangle(size:20)
rectangle2.translate([100,0,0])
circle1.translate([0,-25,0])

#create a 2d hull around the shapes
hulled = hull(circle1,rectangle2)

#extrude
hulled = hulled.extrude(offset: [0, 0, 100],twist:180,slices:100)

assembly.add hulled.color([0.9,0.4,0])