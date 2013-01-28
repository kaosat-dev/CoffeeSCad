define (require)->
  backbone_dropbox = require './backbone.dropbox'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
  class DropBoxLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored on dropbox
    """  
    model: Project
    #sync: backbone_dropbox.sync
    path: ""
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
      
    onReset:()->
      console.log "DropBoxLibrary reset" 
      console.log @
      console.log "_____________"
  
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
      @lib = new DropBoxLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
    login:=>
      try
        @store.authentificate()
        @loggedIn = true
        @vent.trigger("dropBoxConnector:loggedIn")
        
        console.log "dropbox logged in"
       
        #@lib.fetch()
        
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
        
    saveProject:(project)=>
      @lib.add(project)
      
      project.sync=@store.sync
      project.pathRoot=project.get("name") 
      
      #fakeCollection = new Backbone.Collection()
      #fakeCollection.sync = @store.sync
      #fakeCollection.path = project.get("name") 
      #fakeCollection.add(project)
      
      project.pfiles.sync = @store.sync
      project.pfiles.path = project.get("name") 
      for index, file of project.pfiles.models
        file.sync = @store.sync 
        file.pathRoot= project.get("name")
        file.save()
      
      #project.save()
      @vent.trigger("project:saved")
    
    loadProject:(projectName)=>
      console.log "dropbox loading project #{projectName}"
      project =@lib.get(projectName)
      console.log "loaded:"
      console.log project
    
    getProjectsName:(callback)=>
      #hack
      @store.client.readdir "/", (error, entries) ->
        if error
          console.log ("error")
        else
          console.log entries
          callback(entries)
       
  return DropBoxConnector