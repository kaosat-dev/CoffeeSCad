ELEC_COLOR =[ 0.5, 0.5, 0.6]
class AdaServoDriver
  width:25.4
  length:62.5
  height:3
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    
  render: =>
    result = new CSG()
    pcb = CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]}).setColor(ELEC_COLOR)
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2])
    
servoDriver = new AdaServoDriver()
return servoDriver.render()

############################

resolution = 5
cube1 = CSG.roundedCube({center: [0,0,0], radius: [10,10,10],roundradius: 2, resolution: resolution})
result = cube1
return result 


############################

class CubeClass
  width:20
  length:20
  height:20
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
  
  render: =>
    result = new CSG()
    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})
    result = cube1
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) 

cubeStuff = new CubeClass()
return cubeStuff
############################
class CubeClass
  width:20
  length:20
  height:20
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
  
  render: =>
    result = new CSG()
    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})
    result = cube1.setColor(1.0, 0.5, 0.0)
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) 

class CoffeeCup
  constructor: (@height=20, @lowerDia=20, @upperDia=24,
                @thickness=3, @pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
 
  render: =>
    cyl = CSG.cylinder({
    start: [0, 0, 0],
    end: [0, @height, 0],
    radiusStart: @lowerDia/2,
    radiusEnd:@upperDia/2,
    resolution: 100})
    
    hole = CSG.cylinder({
    start: [0, 2, 0],
    end: [0, @height+2, 0],
    radiusStart: (@lowerDia-@thickness)/2,
    radiusEnd:(@upperDia-@thickness)/2,
    resolution: 32})
    return  cyl.subtract(hole).setColor(1, 0.8, 0.0)
  
result = new CSG()
cof = new CoffeeCup(35,30,40)

cb1 = new CubeClass().setColor(0.0, 0.8, 0.0)
cb2 = new CubeClass([3,12,7])
result= result.union(cb1).union(cb2).translate([0,45,0]).union(cof)

return result 
###############
        
resolution = 16# increase to get smoother corners (will get slow!)
      
cube1 = CSG.roundedCube({center: [0,0,0], radius: [10,10,10], roundradius: 2, resolution: resolution})
sphere1 = CSG.sphere({center: [5, 5, 5], radius: 10, resolution: resolution })
sphere2 = sphere1.translate([12, 5, 0])
sphere3 = CSG.sphere({center: [20, 0, 0], radius: 30, resolution: resolution })
    
result = cube1;
result = result.union(sphere1)
result = result.subtract(sphere2)
result = result.intersect(sphere3)
return result.setColor(1.0, 0.5, 0.0) 
###############
##2d
shape1 = CAG.fromPoints([[0,0], [5,0], [3,5], [0,5]])
shape2 = CAG.circle({center: [-2, -2], radius: 4, resolution: 20})
shape3 = CAG.rectangle({center: [5, -2], radius: [2, 3]})
shape4 = CAG.roundedRectangle({center: [5, 7], radius: [4, 4], roundradius: 1, resolution: 24})


shape1 = shape1.expand(1, 20)

shape = shape1.union([shape2, shape3, shape4])
extruded=shape.extrude({
  offset: [0.5, 0, 10],   
  twistangle: 30,       
  twiststeps: 10        
}) 
return shape

###Openscad conversion, manual more complex 
xtra=0.01
MECHA_COLOR = [ 0.99, 0.85, 0.0 ]

class tibia2
  constructor: (@pos=[0,0,0],@rot=[0,0,0], @length=54.4, @thickness=5, @servo_borders=3)->
    servo_width=12.5
    servo_length=23
    servo_height=22.5
  
    servo_hole_dia=2
    servo_mount_dist=2.5
    leg_width= 20

    r1= servo_width/2+servo_borders

    servo_mount_offset= servo_length/2+servo_mount_dist
    end_offset=10
    global_offset=3.2

    front_cut_corner_rad=1
    front_cut_center=5
    front_cut_corners=servo_length/2-front_cut_corner_rad


  render: () =>
    result = new CSG()
    
    return result.setColor(MECHA_COLOR)
    
        
shape1 = fromPoints([[global_offset,15], [global_offset,-5], [0,-5]])
shape = shape1.expand(2, 30)

shape=shape.extrude({offset:[0, 0, 5]}) 
    
    
    rotate([90,0,0])
    translate(pos) rotate(rot) 
    {
      .setColor(MECHA_COLOR)
    
      difference()
      {
        linear_extrude(height =thickness)
        {
          hull()
          {
            translate([global_offset,15]) circle(r=r1);   
            translate([global_offset,-5])circle(r=r1);  
            translate([end_offset,front_cut_center])  circle(r=r1-1);   
          }
          hull()
          {
            translate([end_offset,front_cut_center])  circle(r=r1-1);   
            translate([0,-length+10])  circle(r=4);     
          }
          hull()
          {
            translate([0,-length+10])  circle(r=3);   
            translate([0,-length])  circle(r=2.8);  
          }
        }
        translate([0,5,thickness/2]) cube([servo_width,servo_length,thickness+xtra], center=true);
  
        translate([0,5-servo_mount_offset,thickness/2+xtra/2]) cylinder(r= servo_hole_dia/2, h= thickness+xtra+10, center=true, $fn=32);
        translate([0,5+servo_mount_offset,thickness/2+xtra/2]) cylinder(r= servo_hole_dia/2, h= thickness+xtra+10, center=true, $fn=32);
        
        //translate([12,3,-xtra/2]) cylinder(r=3, h= thickness+xtra);
  
        translate([0,0,-xtra/2]) 
        linear_extrude(height =thickness+xtra)
        {
          hull()
          {
          
          translate([10,front_cut_center+front_cut_corners])circle(r=1.0); 
          translate([13,front_cut_center]) circle(r=2);   
          translate([10,front_cut_center-front_cut_corners]) circle(r=1.0);   
          } 
        }
  
        translate([0,0,-xtra/2]) 
        linear_extrude(height =thickness+xtra*2)
        {
          hull()
          {
          translate([5,-20]) circle(r=2);   
          translate([0.5,-40])circle(r=1); 
          } 
        }
      }
      
#2d other test (hull() reproduction)
shape1 = CAG.fromPoints([[0,0], [5,0], [7,5], [0,5]])
shape2 = CAG.circle({center: [-2, -2], radius: 4, resolution: 20})
shape3 = CAG.rectangle({center: [5, -2], radius: [2, 3]})
shape4 = CAG.roundedRectangle({center: [5, 7], radius: [4, 4], roundradius: 1, resolution: 24})


shape1 = shape1.expand(1, 10)
shape = shape1
#shape = shape1.union([shape2, shape3, shape4])
extruded=shape.extrude({ 
  offset: [0.5, 0, 10],    
  twistangle: 30,       
  twiststeps: 10        
}) 

c1 = CAG.circle({radius: 2, resolution: 10})
c2= CAG.circle({center: [15, 5], radius: 2, resolution: 10})
c3= CAG.circle({center: [0, -5], radius: 2, resolution: 10})

shapeGroup = c1.union([c2, c3])

extruded=shapeGroup.extrude({offset: [0.5, 0, 10]})  


return shapeGroup

#and again
shape1 = CAG.fromPoints([[0,0], [15,5], [0,-5]])

shape = shape1.expand(2, 30)

shape=shape.extrude({ 
  offset: [0, 0, 5]     
}) 
return shape.setColor(1,0.5,0)
###
c1 = CAG.circle({radius: 2, resolution: 10})
c2= CAG.circle({center: [15, 5], radius: 2, resolution: 10})
c3= CAG.circle({center: [0, -5], radius: 2, resolution: 10})

shapeGroup = c1.union([c2, c3])
shapeGroup=shapeGroup.expand(2, 10)
extruded=shapeGroup.extrude({offset: [0.5, 0, 10]})  
return shapeGroup
###test with prefix removal (see missing CAG. before the "fromPoints method")
shape1 = fromPoints([[0,0], [15,5], [0,-5]])

shape = shape1.expand(2, 30)

shape=shape.extrude({offset:[0, 0, 5]}) 
return shape.setColor(1,0.5,0)


cylinder = CSG.cylinder({
  start: [0, -1, 0],
  end: [0, 1, 0],
  radius: 1,
  resolution: 16
});


########

shape1 = fromPoints([[0,0], [150,50], [0,-50]])
shape = shape1.expand(20, 30)
shape=shape.extrude({offset:[0, 0, 50]}) 
return shape.color([1,0.5,0])

#######
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
    #return @render()
  
  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 30)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)



return thing.render().union(thing2.render().mirroredX())

########
class CubeClass
  constructor: (@width=10,@length=20,@height=20, @pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
  
  render: =>
    result = new CSG()
    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})
    result = cube1
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) 

cubeStuff = new CubeClass(75,50,50,[-20,10,10])
cubeStuff2 = new CubeClass(50,100,50)


return cubeStuff2.subtract(cubeStuff).setColor([0,1,0])

#return cubeStuff2.subtract(cubeStuff).setColor([1,0.25,0.1])
#####
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
    #return @render()
  
  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 30)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)



tmpres = thing.render().union(thing2.render().mirroredX()) 

res = tmpres.unionForNonIntersecting(tmpres.translate([0,0,75]).color([0.2,0.5,0.6]))  

return res

##
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
    #return @render()
  
  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 30)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)


tmpres = thing.render().union(thing2.render().mirroredX().color([0.2,0.5,0.6])) 

res = tmpres  

return res

#########
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->

  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 25)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10, resolution:12})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)


tmpres = thing.render().color([0.2,0.2,0.2]).union(thing2.render().
                                                   mirroredX().color([0.2,0.5,0.6])) 
tmpres2 = thing.render().union(thing2.render().mirroredX().color([0.2,0.2,0.2])) 
tmpres3 = thing.render().union(thing2.render().mirroredX().color([0.2,0.2,0.2])) 


tmpres = tmpres2.translate([0,0,-100]).union(tmpres)
tmpres = tmpres3.translate([0,0,100]).union(tmpres)

res = tmpres  

return res

#########
class CubeClass
  constructor: (@width=10,@length=20,@height=20, @pos=[0,0,0], @rot=[0,0,0]) ->
    return @render()
  
  render: =>
    result = new CSG()
    cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})
    result = cube1
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) 

cubeStuff = new CubeClass(75,50,50,[-20,10,10])
cubeStuff2 = new CubeClass(50,100,50)#.color([0,1,0])


return cubeStuff2.subtract(cubeStuff).color([0,1,0]).setobjTag("tutu") 



class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
  
  render: =>
    result = new CSG()
    shape1 = fromPoints([[0,0], [150,50], [0,-50]])
    shape = shape1.expand(20, 25)
    shape = shape.extrude({offset:[0, 0, @thickness]}) 
    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10, resolution:12})
    result = shape.subtract(cyl)
    return result.translate(@pos).rotateX(@rot[0]).
    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])

thing = new Thingy(50)
thing2 = new Thingy(35)

res = thing.render().union(thing2.render().mirroredX().color([0.2,0.5,0.6]))
res= res.rotateX(9)
res= res.rotateZ(180)
res=res.rotateY(0)
res= res.translate([0,0,100])
return res

###################
cube1 = new Cube 
  radius: 12
cube2 = new Cube
  radius: 5

# define a connector on the center of one face of cube1
# The connector's axis points outwards and its normal points
# towards the positive z axis:
cube1.properties.myConnector = new CSG.Connector([30, 0, 0], [1, 0, 0], [0, 0, 1])

# define a similar connector for cube 2:
cube2.properties.myConnector = new CSG.Connector([0, -4, 0], [0, -1, 0], [0, 0, 1])

#do some random transformations on cube 1:
cube1 = cube1.rotateX(0).rotateY(40)
cube1 = cube1.translate([3.1, 30, 0])

#Now attach cube2 to cube 1:
cube2 = cube2.connectTo(
  cube2.properties.myConnector, 
  cube1.properties.myConnector, 
  true,   # mirror 
  0       # normalrotation
)
result = cube2.union(cube1);
return result 