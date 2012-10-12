define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
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
        keyBindings:
          "CTRL+Z" : "undo"
          "CTRL+Y" : "redo"
        

  return Settings