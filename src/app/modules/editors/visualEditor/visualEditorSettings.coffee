define (require)->
  Backbone = require 'backbone'


  class VisualEditorSettings extends Backbone.Model
      idAttribute: 'name'
      defaults:
        name: "VisualEditor"
        title: "Visual Editor"
        
        csgRenderMode: "onCodeChange" #can be either "onCodeChange", "onCodeChangeDelayed", "onDemand", "onSave"
        csgRenderDelay: 1.0
             
        renderer     : 'webgl'
        antialiasing : true
        
        shadows      : true
        selfShadows  : false
        
        showAxes     : true
        
        showConnectors: false
        
        showGrid     : true
        gridSize     : 1000
        gridStep     : 100
        gridColor    : "0xFFFFFF"
        gridOpacity  : 0.1
        
        showStats    : false
        
        position     : "diagonal"
        projection   : "perspective" #orthogonal
              
        wireframe    : false
        
        helpersColor : "0xFFFFFF"
        
        
        bgColor      : "#363335"
        bgColor2     : "#363335"
        
      constructor:(options)->
        super options
        
  return VisualEditorSettings