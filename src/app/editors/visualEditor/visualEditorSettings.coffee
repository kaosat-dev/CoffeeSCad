define (require)->
  Backbone = require 'backbone'
  buildProperties = require 'core/utils/buildProperties' #helper for dotted attribute access instead of "get/Set"


  class VisualEditorSettings extends Backbone.Model
    attributeNames: ['name','renderer','antialiasing','shadows','selfShadows',
    'showAxes','showConnectors','showGrid','gridSize','gridStep','gridColor','gridOpacity','gridText',
    'showStats','position','projection','objectViewMode','helpersColor','textColor','bgColor','bgColor2','axesSize']
    
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "VisualEditor"
      title: "Visual Editor"
      
      renderer     : 'webgl'
      antialiasing : true
      
      shadows      : true
      selfShadows  : false
      
      showAxes     : true
      
      showConnectors: false
      
      showGrid     : true
      gridSize     : 200
      gridStep     : 10
      gridColor    : "0xFFFFFF"
      gridOpacity  : 0.1
      gridText     : true
      gridNumberingPosition: 'center'
      
      showStats    : false
      
      position     : "diagonal"
      projection   : "perspective" #orthogonal
      
      objectViewMode : 'shaded'    
      
      
      helpersColor : "0xFFFFFF"
      textColor    : "#FFFFFF"     
      
      bgColor      : "#363335"
      bgColor2     : "#363335"
      axesSize     : 80
      
    constructor:(options)->
      super options
        
  return VisualEditorSettings