define (require)->
  backbone_dropbox = require './backbone.dropbox'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
  class DropBoxLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored on dropbox
    """  
    model: Project
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
  
  
  class DropBoxConnector extends Backbone.Model
    defaults:
      name: "dropBoxConnector"
      storeType: "dropBox"
    
    constructor:(options)->
      super options
      @store = new backbone_dropbox()
      @isLogginRequired = true
      @loggedIn = true
      @vent = vent
      @vent.on("dropBoxConnector:login", @login)
      @vent.on("dropBoxConnector:logout", @logout)
      
      #experimental
      @lib = new DropBoxLibrary()
      
    login:=>
      try
        @store.authentificate()
        @loggedIn = true
        @vent.trigger("dropBoxConnector:loggedIn")
      catch error
        @vent.trigger("dropBoxConnector:loginFailed")
        
    logout:=>
      try
        @store.signOut()
        @loggedIn = false
        @vent.trigger("dropBoxConnector:loggedOut")
      catch error
        @vent.trigger("dropBoxConnector:logoutFailed")
    
      
     createProject:(options)=>
       project = @lib.create(options)
       project.createFile
        name: project.get("name")
       project.createFile
        name: "config"
    
     getProjectsName:(callback)=>
       #hack
       #fakeModel = new Backbone.Model()
       #fakeModel.set("path":"project1")
       #@store.findAll(fakeModel)
       
       #$.wait(@store._readDir("/"))
       @store.client.readdir "/", (error, entries) ->
         if error
          console.log ("error")
         else
          console.log entries
          callback(entries)
       
  return DropBoxConnector