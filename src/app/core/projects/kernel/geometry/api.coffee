define (require)->
  ### 
  cube
  sphere
  cylinder
  ?torus
  ?polygon3D

  square
  circle
  plane
  text
  from points
  ?from lines
  ?polygon2D/shape
    
  translate
  rotate
  scale
  
  union
  subtract
  intersect
  invert

  cutByPlane
  ###
  ObjectBase = require "./base"
  Cube = require "./3d/Cube"
  Sphere = require "./3d/Sphere"
  Rectangle = require "./2d/Rectangle"
  Circle = require "./2d/Circle"
  
  return {ObjectBase:ObjectBase, Cube:Cube, Sphere:Sphere, Circle:Circle, Rectangle:Rectangle}
