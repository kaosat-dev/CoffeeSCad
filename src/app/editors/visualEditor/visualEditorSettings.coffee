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
      
      showConnectors: false
      objectViewMode : 'shaded'    
      
      showAxes     : true
      axesSize     : 100
      
      showGrid     : true
      gridSize     : 200
      gridStep     : 10
      gridColor    : "0x00baff"
      gridOpacity  : 0.1
      gridText     : true
      gridNumberingPosition: 'center'
      
      position     : "diagonal"
      projection   : "perspective" #orthogonal
      
      helpersColor : "0x00baff"
      textColor    : "#000000"     
      bgColor      : "#FFFFFF"
      bgColor2     : "#FFFFFF"
      
      showStats    : false
      
      
      grid: {
        enabled:true
        size: 200
        steps: 10
        color : "0x00baff"
        opacity: 0.1
        numbering: true
        numberingPosition : 'center'
      }
      
      axes:{
        enabled:true
        size: 100
      }
      
      objects:{
        shadows      : true
        shadowResolution: "256x256"
        selfShadows  :  true
        showConnectors: false
        style:        'shaded'   
      }
      
      camera:{
        position     : "diagonal"
        projection   : "perspective" #orthogonal
      } 
      
      
    constructor:(options)->
      super options
        
  return VisualEditorSettings