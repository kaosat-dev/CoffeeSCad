define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  
  class CodeEditorSettings extends Backbone.Model
    ###
    All settings for the code editor are stored within this class
    ###
      
    idAttribute: 'name'
    defaults:
      name: "Editor"
      title: "Code editor"
      
      #general
      theme        : "default"
      startLine    :  1
      undoDepth    :  40
      
      linting:
        max_line_length:
          value: 80
          level: "warning"
        no_tabs:
          level: "warning"
        indentation:
          value: 2
          level: "ignore"
        
    constructor:(options)->
      super options
      
  return CodeEditorSettings