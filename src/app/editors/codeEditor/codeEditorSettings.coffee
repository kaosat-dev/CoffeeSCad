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
      fontSize     :  1
      smartIndent    :  true
      
      #linting
      linting:
        indentation:
          value: 2
          level: "error"
        max_line_length:
          value: 80
          level: "warn"
        no_tabs:
          level: "warn"
        no_trailing_whitespace:
          level: "warn"
        no_trailing_semicolons:
          level: "warn"         
          
      
    constructor:(options)->
      super options
    
 
  
  return CodeEditorSettings