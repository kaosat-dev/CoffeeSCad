define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  #TODO: turn this into a collection, where each item is a category, to make view rendering more automatic
  class Settings extends Backbone.Model
      localStorage: new Backbone.LocalStorage("Settings")
      defaults:
        projects:
          maxRecentDisplay:  5
        github:
          configured: false
        codeEditor:
          startLine:  1
          theme: "default"
        viewer:
          antialiasing : true
          showgrid : true
        keyBindings:
          "CTRL+Z" : "undo"
          "CTRL+Y" : "redo"
        
        
        

  return Settings