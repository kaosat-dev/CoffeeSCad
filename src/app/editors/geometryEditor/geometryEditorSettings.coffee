define (require)->
  Backbone = require 'backbone'
  backbone_nested = require 'backbone_nested'
  
        
  class GeometryEditorSettings extends Backbone.NestedModel
    ###
    All settings for the code editor are stored within this class
    ###
    idAttribute: 'name'
    defaults:
      name: "GeometryEditor"
      title: "Geometry editor"
      
    constructor:(options)->
      super options
    
 
  
  return GeometryEditorSettings