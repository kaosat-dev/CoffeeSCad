define (require)->
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'

  vent = require 'modules/core/vent'
  buildProperties = require 'modules/core/utils/buildProperties'
  
  Project = require 'modules/core/projects/project'
  storeURI = "projects"
  
  class BrowserLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored in localstorage (browser)
    """  
    model: Project
    localStorage: new Backbone.LocalStorage(storeURI)
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
      @store = new Backbone.LocalStorage(storeURI)
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
      console.log @lib
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
        projectURI = "#{storeURI}-#{projectName}"
        rootStoreURI = "#{projectURI}-files"
        project.rootFolder.sync = project.sync
        project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
        
        onProjectFilesLoaded=()=>
          for file in project.rootFolder.models
            files.push(file.name)
          callback(files)
        
        project.rootFolder.fetch().done(onProjectFilesLoaded)
        
    saveProject_:(project, newName)=>
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      projectURI = "#{storeURI}-#{newName}"
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      @vent.trigger("project:saved")  
    
    saveProject:(project,newName)=>
      #experiment of saving projects withouth using backbone localstorage
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      project.dataStore = @
      project.rootPath="projects-"+project.name #rootStoreURI
      
      projectName = project.name 
      projectURI = "#{storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
       
      filesList = []
      for index, file of project.rootFolder.models
        name = file.name
        content =file.content
        filePath = "#{rootStoreURI}-#{name}"
        ext = name.split('.').pop()
        localStorage.setItem(filePath,JSON.stringify(file.toJSON()))
        filesList.push(file.name)
        file.trigger("save")
      
      #fetch old list of files, for diff, delete old file if not present anymore
      oldFiles = localStorage.getItem(rootStoreURI)
      oldFiles = oldFiles.split(',')
      
      added = _.difference(filesList,oldFiles)
      removed = _.difference(oldFiles,filesList)
      @_removeFile(projectName, fileName) for fileName in removed
        
      localStorage.setItem(rootStoreURI,filesList.join(","))
      localStorage.setItem(projectURI,JSON.stringify(project.toJSON()))
      
      @_addToProjectsList(project.name)
      project.dataStore = @
      
      @vent.trigger("project:saved")  
    
    loadProject:(projectName)=>
      project =  @lib.get(projectName)
      project.collection = @lib
      projectURI = "#{storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.sync = project.sync
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      
      onProjectLoaded=()=>
        #remove old thumbnail
        thumbNailFile = project.rootFolder.get(".thumbnail.png")
        project.rootFolder.remove(thumbNailFile)
        @vent.trigger("project:loaded",project)
      
      project.dataStore = @
      project.rootFolder.fetch().done(onProjectLoaded)
   
    deleteProject:(projectName)=>
      d = $.Deferred()
      console.log "browser storage deletion of #{projectName}"
      project = @lib.get(projectName)
      project.collection = @lib
      
      projectURI = "#{storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.sync = project.sync
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      
      #DESTROYING via backbone does not work!!
      localStorage.removeItem(rootStoreURI)
      
      file = null
      while (file = project.rootFolder.pop()) 
        fileUri = "#{rootStoreURI}-#{file.name}"
        console.log "deleting #{fileUri}"
        #DESTROYING via backbone does not work!! 
        localStorage.removeItem(fileUri)
      
      @_removeFromProjectsList()
      
      @lib.remove(project)
      
      localStorage.removeItem(projectURI)
      return d.resolve()
      
    renameProject:(oldName, newName)=>
      #EVEN MORREEE HACKS ! thanks backbone
      project = @lib.get(oldName)
      @lib.remove(project)
      project.name = newName
      
      projectURI = "#{storeURI}-#{newName}"
      project.localstorage = new Backbone.LocalStorage(projectURI)
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      
      @lib.add(project)
      
    _removeFromProjectsList:(projectName)=>
      projects = localStorage.getItem(storeURI)
      projects = projects.split(',')
      index = projects.indexOf(projectName)
      projects.splice(index, 1)
      projects = projects.join(',')
      localStorage.setItem(storeURI,projects)
      
    _addToProjectsList:(projectName)=>
      projects = localStorage.getItem(storeURI)
      projects = projects.split(',')
      if not projectName in projects
        projects.push(projectName)
        projects = projects.join(',')
        localStorage.setItem(storeURI,projects)
        
    _removeFile:(projectName, fileName)=>
      projectURI = "#{storeURI}-#{projectName}"
      filesURI = "#{projectURI}-files"
      fileNames = localStorage.getItem(filesURI)
      fileNames = fileNames.split(',')
      index = fileNames.indexOf(fileName)
      fileNames.splice(index, 1)
      fileNames = fileNames.join(',')
      localStorage.setItem(filesURI,fileNames)
      
      fileURI = "#{filesURI}-#{fileName}"
      localStorage.removeItem(fileURI)
      
    destroyFile:(projectName, fileName)=>
      return @_removeFile(projectName, fileName)  
      
       
  return BrowserStore