define (require)->
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'

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
      
  
  class BrowserStore extends Backbone.Model
    attributeNames: ['name', 'loggedIn']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "browserStore"
      storeType: "browser"
      tooltip:"Store to localstorage (browser)"
      loggedIn: true
    
    constructor:(options)->
      super options
      @store = new Backbone.LocalStorage("Projects")
      @isLogginRequired = false
      @vent = vent
      @vent.on("browserStore:login", @login)
      @vent.on("browserStore:logout", @logout)
      
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
    
    getProject:(projectName)=>
      return @lib.get(projectName)
    
    getProjectFiles:(projectName,callback)=>
      #Get all the file names withing a project : should actually get the file tree? (subdirs support etc)
      #hack
      files = []
      project = @lib.get(projectName)
      #TODO: oh the horror: we have to fetch all model data just to look at the files list
      if project?
        rootStoreURI = "projects-"+project.name+"-files"
        project.rootFolder.sync = project.sync
        project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
        
        onProjectFilesLoaded=()=>
          for file in project.rootFolder.models
            files.push(file.name)
          callback(files)
        
        project.rootFolder.fetch().done(onProjectFilesLoaded)
        
          
    
    saveProject:(project, newName)=>
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      
      rootStoreURI = "projects-"+project.name+"-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      @vent.trigger("project:saved")  
    
    saveProject_alt:(project,newName)=>
      #experiment of saving projects withouth using backbone localstorage
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      project.dataStore = @
      project.rootPath="projects-"+project.name #rootStoreURI
      
      for index, file of project.rootFolder.models
        projectName = project.name
        name = file.name
        content =file.content
        filePath = "#{projectName}/#{name}"
        ext = name.split('.').pop()
        localStorage["bar"] = foo
        localStorage.setItem("bar", foo)
      
      rootStoreURI = "projects-"+project.name+"-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      @vent.trigger("project:saved")  
      
      localStorage.setItem("bar", foo);
    
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
       
       
  return BrowserStore