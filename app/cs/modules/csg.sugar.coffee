define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  ###here we define various shorthands, wrappers etc for the base csg.js syntax,
  all in the mindset of "simple, clearer better"
  Some of these can eventually be migrated into csg.js as modified /added methods
  and classes .
  ###
  
  ##CSG
  Cube = CSG.cube
  Sphere = CSG.Sphere
  Cylinder = CSG.cylinder
  roundedCylinder = CSG.roundedCylinder
  roundedCube = CSG.roundedCube
  
  ###CAG
  fromPoints= CAG.fromPoints
  Circle= CAG.circle
  Rectangle = CAG.rectangle
  roundedRectangle = CAG.roundedRectangle
