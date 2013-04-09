define (require)=>
  base = require './csgBase' 
  geometry3d = require './geometry3d'
  geometry2d = require './geometry2d'
  logging = require './logging'
  log = logging.log
  
  rootAssembly = base.rootAssembly
  #this file defines a set of helpers to get a higher level (more accessible ) api
  
  #Geometry
  cube = (options, parent=null)=>
    #create a cube with the specified options, adds it to the assembly unless
    #parent is specified
    _cube = new geometry3d.Cube(options)
    if not parent?
      parent = rootAssembly
    parent.add(_cube)
    return _cube
    
  sphere = (options, parent=null)=>
    #create a sphere with the specified options, adds it to the assembly unless
    #parent is specified
    _sphere = new geometry3d.Sphere(options)
    if not parent?
      parent = rootAssembly
    parent.add(_sphere)
    return _sphere
  
  cylinder = (options, parent=null)=>
    #create a cylinder with the specified options, adds it to the assembly unless
    #parent is specified
    _cylinder = new geometry3d.Cylinder(options)
    if not parent?
      parent = rootAssembly
    parent.add(_cylinder)
    return _cylinder
  
  rectangle = (options, parent=null)=>
    #create a rectangle with the specified options, adds it to the assembly unless
    #parent is specified
    _rectangle = new geometry2d.Rectangle(options)
    if not parent?
      parent = rootAssembly
    parent.add(_rectangle)
    return _rectangle
  
  circle = (options, parent=null)=>
    #create a rectangle with the specified options, adds it to the assembly unless
    #parent is specified
    _circle = new geometry2d.Circle(options)
    if not parent?
      parent = rootAssembly
    parent.add(_circle)
    return _circle

  return {
    "cube":cube,
    "sphere":sphere,
    "cylinder":cylinder,
    "rectangle": rectangle,
    "circle":circle
  }
