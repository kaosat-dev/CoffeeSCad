define (require)->
  Backbone = require 'backbone'
  backbone_nested = require 'backbone_nested'
  buildProperties = require 'core/utils/buildProperties' #helper for dotted attribute access instead of "get/Set"
        
  class CodeEditorSettings extends Backbone.NestedModel
    ###
    All settings for the code editor are stored within this class
    ###
    attributeNames: ['theme','startLine','undoDepth','fontSize','autoClose','highlightLine','showInvisibles','showIndentGuides','showGutter','doLint']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "CodeEditor"
      title: "Code editor"
      
      #general
      theme        : "solarized_dark"
      startLine    :  1
      undoDepth    :  40
      fontSize     :  1
      autoClose     : true
      highlightLine: true
      showInvisibles:true
      showIndentGuides:false
      showGutter:true
      
      #linting
      doLint: true
      
    
      
    constructor:(options)->
      super options
    
 
  
  return CodeEditorSettings