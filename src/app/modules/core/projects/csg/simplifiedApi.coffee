define (require)=>
  base = require './csgBase' 
  geometry3d = require './geometry3d'
  logging = require './logging'
  log = logging.log
  
  rootAssembly = base.rootAssembly
  #this file defines a set of helpers to get a higher level (more accessible ) api
  #Geometry
  cube = (options,parent=null)=>
    #create a cube with the specified options, adds it to the assembly unless
    #parent is specified
    _cube = new geometry3d.Cube(options)
    #if not parent?
    
    rootAssembly.add(_cube)
    return _cube


  return {
    "cube":cube
    
  }
