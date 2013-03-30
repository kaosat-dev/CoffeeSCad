circle = new Circle(r:25,center:[0,0],$fn:10)
rectangle = new Rectangle(size:20)
rectangle2 = new Rectangle(size:20)
rectangle2.translate([100,0,0])
circle.translate([0,-25,0])
hulled = hull(circle,rectangle2)
hulled = hulled.extrude(offset: [0, 0, 100],twist:180,slices:100)

assembly.add hulled.color([0.9,0.4,0])