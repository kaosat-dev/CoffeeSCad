var a = CSG.cube();
var b = CSG.sphere({ radius: 1.35 });
var c = CSG.sphere({ radius: 1.50 });
a.setColor(0, 1, 0);
b.setColor(0, 0.5, 0);
return a.subtract(b).intersect(c);