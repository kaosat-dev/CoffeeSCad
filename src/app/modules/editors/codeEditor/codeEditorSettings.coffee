define (require)->
  Backbone = require 'backbone'
  backbone_nested = require 'backbone_nested'
  
        
  class CodeEditorSettings extends Backbone.NestedModel
    ###
    All settings for the code editor are stored within this class
    ###
    idAttribute: 'name'
    defaults:
      name: "CodeEditor"
      title: "Code editor"
      
      #general
      theme        : "default"
      startLine    :  1
      undoDepth    :  40
      
      #linting
      linting:
        indentation:
          value: 2
          level: "ignore"
        max_line_length:
          value: 80
          level: "warning"
        no_tabs:
            level: "warning"
      
    constructor:(options)->
      super options
    
 
  
  return CodeEditorSettings