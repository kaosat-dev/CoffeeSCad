define (require)->
  Backbone = require 'backbone'
  buildProperties = require 'core/utils/buildProperties' #helper for dotted attribute access instead of "get/Set"


  class VisualEditorSettings extends Backbone.Model
    attributeNames: ['name','renderer','antialiasing','shadows','shadowResolution','selfShadows',
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
      shadowResolution: "256x256"
      selfShadows  : false
      
      showAxes     : true
      
      showConnectors: false
      
      showGrid     : true
      gridSize     : 200
      gridStep     : 10
      gridColor    : "0x00baff"
      gridOpacity  : 0.1
      gridText     : true
      gridNumberingPosition: 'center'
      
      showStats    : false
      
      position     : "diagonal"
      projection   : "perspective" #orthogonal
      
      objectViewMode : 'shaded'    
      
      
      helpersColor : "0x00baff"
      textColor    : "#000000"     
      
      bgColor      : "#FFFFFF"
      bgColor2     : "#FFFFFF"
      axesSize     : 100
      
    constructor:(options)->
      super options
        
  return VisualEditorSettings