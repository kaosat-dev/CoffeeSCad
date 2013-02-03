define (require)->
  Backbone = require 'backbone'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
  class BrowserLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored in localstorage (browser)
    """  
    model: Project
    localStorage: new Backbone.LocalStorage("Projects")
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
  
  class BrowserConnector extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "browserConnector"
      storeType: "browser"
      tooltip:"Connector to localstorage (browser)"
    
    
    constructor:(options)->
      super options
      @store = new Backbone.LocalStorage("Projects")
      @isLogginRequired = false
      @loggedIn = true
      @vent = vent
      @vent.on("browserConnector:login", @login)
      @vent.on("browserConnector:logout", @logout)
      
      #experimental
      @lib = new BrowserLibrary()
      
    login:=>
      console.log "browser logged in"
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
    authCheck:()->
      
    
    saveProject:(project)=>
      @lib.add(project)
      rootStoreURI = "projects-"+project.get("name")
      project.pfiles.sync = @store.sync
      project.pfiles.localStorage = new Backbone.LocalStorage(rootStoreURI) 
       
      
      for index, file of project.pfiles.models
        file.sync = Backbone.LocalStorage.sync 
        file.localStorage = new Backbone.LocalStorage(rootStoreURI+"-"+file.get("name")) 
        file.save() 
        
      project.save()
    
    getProjectsName:(callback)=>
      @lib.fetch()
      console.log "browser models"
      console.log @lib.models
      tutu=()=>
        callback(["project1","project2"])
     
      setTimeout tutu, 10
       

       
  return BrowserConnector