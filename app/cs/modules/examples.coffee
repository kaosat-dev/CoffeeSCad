define (require)->
  
  examples=[
    "name": "basics"
    "content": """ 
#Simple comment, yay!
sphere = new Sphere
  d: 100
  $fn: 10
  center: [-100,-25,0]
  
cube = new Cube
  size: 25
  center: [100,0,0]

cylinder = new Cylinder
  h:100
  r:10
  
###
Comments blocks are done like this
###  
cone = new Cylinder
  h:100
  d1:25
  d2:75
  center:[100,0,0]

#Don't forget to 'return' what you want to see rendered (api might change)
return sphere.union(cube).union(cylinder).union(cone)
    """
  ,
    "name":"shapes"
    "content": """ 
circle = new Circle
  d:100
  $fn:10

rect = new Rectangle
  size: [200,100]
  center: [150,10]
  d: 15
  $fn: 10
  
 

shape1 = fromPoints([[0,0], [150,50], [0,-50]])
shape = shape1.expand(15, 10)

shape = shape.union circle
shape = shape.union rect


shape = shape.extrude
  offset: [0, 0, 100]
  twist:45
  slices:10
       
return shape 
    """
  ,
    "name": "mix"
    "content": """
class Thingy
  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->
  
  render: =>
    result = new CSG()
    shape1 = fromPoints [[0,0], [150,50], [0,-50]]
    shape = shape1.expand(20, 25)
    shape = shape.extrude
      offset:[0, 0, @thickness]
      
    cyl = new Cylinder
      r:10
      $fn:12
      h:100
      
    result = shape.subtract cyl
    return result.translate(@pos).rotate(@rot).
    color([1,0.5,0])

thing = new Thingy(35)
thing2 = new Thingy(25)

res = thing.render().union(
  thing2.render()
  .mirroredX()
    .color([0.2,0.5,0.6]))
    
res= res.rotateX(37)
res= res.rotateZ(190)
res= res.translate([0,0,100])
return res"""
  ,
    
  ]
  return examples
