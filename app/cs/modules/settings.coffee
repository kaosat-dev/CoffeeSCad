define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  class GeneralSettings extends Backbone.Model
    defaults:
      maxRecentDisplay:  5
      autoUpdateView  :  true
      
    constructor:(options)->
      super options
      @title = "General"
      @set "title", @title
  
  class GlViewSettings extends Backbone.Model
    defaults:
      renderer     : 'webgl'
      antialiasing : true
      showGrid     : true
      showAxes     : true 
      shadows      : true
      
    constructor:(options)->
      super options
      @title = "3d view"
  
  class EditorSettings extends Backbone.Model
    defaults:
      startLine    :  1
      theme        : "default"
      
    constructor:(options)->
      super options
      @title = "Code editor"
       
  class KeyBindings extends Backbone.Model
    defaults:
      "undo":   "CTRL+Z"
      "redo":   "CTRL+Y"
      
    constructor:(options)->
      super options
      @title = "Key Bindings"
  
  class GitHubSettings extends Backbone.Model
    defaults:
      configured  : false
    constructor:(options)->
      super options
      @title = "GitHub Gist integration"
  
  
  class Settings extends Backbone.Collection
    localStorage: new Backbone.LocalStorage("Settings")

    constructor:(options)->
      super options
      @bind("reset", @onReset)
      @init()
      
    init:()=>
      @add new GeneralSettings()
      @add new GlViewSettings()
      @add new EditorSettings()
      @add new KeyBindings()
      @add new GitHubSettings()
      
    save:()=>
      @each (model)-> 
        model.save()
      
    clear:()=>
      @each (model)-> 
        model.destroy()
      
    onReset:()->
      console.log "collection reset" 
      console.log @
      console.log "_____________"
   
  return Settings