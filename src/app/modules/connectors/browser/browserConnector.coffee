define (require)->
  Backbone = require 'backbone'
  vent = require 'modules/core/vent'
  buildProperties = require 'modules/core/utils/buildProperties'
  
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
    
    comparator: (project)->
      date = new Date(project.lastModificationDate)
      return date.getTime()
      
  
  class BrowserConnector extends Backbone.Model
    attributeNames: ['loggedIn']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "browserConnector"
      storeType: "browser"
      tooltip:"Connector to localstorage (browser)"
      loggedIn: true
    
    constructor:(options)->
      super options
      @store = new Backbone.LocalStorage("Projects")
      @isLogginRequired = false
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
    
    getProjectsName:(callback)=>
      @lib.fetch()
      projectNames = []
      for model in @lib.models
        projectNames.push(model.id)
        
      callback(projectNames)
    
    saveProject:(project, newName)=>
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      
      rootStoreURI = "projects-"+project.name+"-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      @vent.trigger("project:saved")  
    
    loadProject:(projectName)=>
      project =  @lib.get(projectName)
      project.collection = @lib
      rootStoreURI = "projects-"+project.name+"-files"
      project.rootFolder.sync = project.sync
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      
      onProjectLoaded=()=>
        #remove old thumbnail
        thumbNailFile = project.rootFolder.get(".thumbnail")
        project.rootFolder.remove(thumbNailFile)
        @vent.trigger("project:loaded",project)
      
      project.rootFolder.fetch().done(onProjectLoaded)
       
       
  return BrowserConnector