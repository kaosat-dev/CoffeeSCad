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
      date = new Date(project.get('lastModificationDate'))
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
      
    saveProject:(project)=>
      console.log "saving project"
      @lib.add(project)
      rootStoreURI = "projects-"+project.get("name")+"-files"
      project.pfiles.sync = project.sync
      project.pfiles.localStorage = new Backbone.LocalStorage(rootStoreURI) 
      #project.pfiles.sync = Backbone.LocalStorage.sync
           
      for index, file of project.pfiles.models
        file.save() 
        file.trigger("save")
        
      @vent.trigger("project:saved")  
      project.save()
    
    getProjectsName:(callback)=>
      @lib.fetch()
      console.log "browser models"
      console.log @lib.models
      projectNames = []
      
      for model in @lib.models
        projectNames.push(model.id)
        
      callback(projectNames)
    
    loadProject:(projectName)=>
      project =  @lib.get(projectName)
      rootStoreURI = "projects-"+project.get("name")+"-files"
      project.pfiles.sync = project.sync
      project.pfiles.localStorage = new Backbone.LocalStorage(rootStoreURI) 
      
      onProjectLoaded=()=>
        #remove old thumbnail
        thumbNailFile = project.pfiles.get(".thumbnail")
        project.pfiles.remove(thumbNailFile)
        @vent.trigger("project:loaded",project)
      
      project.pfiles.fetch().done(onProjectLoaded)
       
       
  return BrowserConnector