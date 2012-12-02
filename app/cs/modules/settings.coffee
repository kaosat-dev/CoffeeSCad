define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  class GeneralSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "General"
      title: "General"
      maxRecentFilesDisplay:  5
      
    constructor:(options)->
      super options
  
  class GlViewSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "GlView"
      title: "3d view"
      
      csgRenderMode: "onCodeChange" #can be either "onCodeChange", "onCodeChangeDelayed", "onDemand", "onSave"
      csgRenderDelay: 1.0
           
      renderer     : 'webgl'
      antialiasing : true
      
      shadows      : true
      selfShadows  : true
      
      showAxes     : true
      
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
  
  class EditorSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "Editor"
      title: "Code editor"
      startLine    :  1
      theme        : "default"
      
    constructor:(options)->
      super options
       
  class KeyBindings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "Keys"
      title: "Key Bindings"
      "undo":   "CTRL+Z"
      "redo":   "CTRL+Y"
      
    constructor:(options)->
      super options
  
  class GitHubSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "Gists"
      title: "Gist integration"
      configured  : false
    constructor:(options)->
      super options
  
  
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
    
    parse: (response)=>
      #TODO yuck, do we really need custom classes for each piece of settings?
      for i, v of response
        switch v.name
          when "General"
            response[i]= new  GeneralSettings(v)
          when "GlView"
            response[i]= new  GlViewSettings(v)
          when "Editor"
            response[i]= new  EditorSettings(v)
          when "Keys"
            response[i]= new  KeyBindings(v)
          when "Gists"
            response[i]= new  GitHubSettings(v)
      return response
      
    clear:()=>
      @each (model)-> 
        model.destroy()
      
    onReset:()->
      if @models.length == 0
        #console.log "fetched empty collection"
        @init()
      ###
      console.log "collection reset" 
      console.log @
      console.log "_____________"
      ###
    byName:(name)->
      #TODO: cleanup
      return this.filter (setting)->
        return setting.get('name')==name
      
      
   
  return Settings