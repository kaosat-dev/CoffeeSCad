define (require)->
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'

  vent = require 'modules/core/messaging/appVent'
  reqRes = require 'modules/core/messaging/appReqRes'
  
  buildProperties = require 'modules/core/utils/buildProperties'
  utils = require 'modules/core/utils/utils'
  merge = utils.merge
  
  Project = require 'modules/core/projects/project'
  
  class BrowserLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored in localstorage (browser)
    """  
    model: Project
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
      defaults = {storeURI:"projects"}
      options = merge defaults, options
      {@storeURI} = options
      super options
        
      @store = new Backbone.LocalStorage(@storeURI)
      @isLogginRequired = false
      @vent = vent
      @vent.on("browserStore:login", @login)
      @vent.on("browserStore:logout", @logout)
      
      #experimental
      @lib = new BrowserLibrary()
      @lib.localStorage = new Backbone.LocalStorage(@storeURI)
      @projectsList = []
      
      #TODO: should this be here ? ie this preloads all projects, perhaps we could lazy load?
      @lib.fetch()
      
      #handler for project/file data fetch requests
      reqRes.addHandler("getbrowserFileOrProjectCode",@_sourceFetchHandler)
      
    login:=>
      console.log "browser logged in"
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
    authCheck:()->
    
    getProjectsName:(callback)=>
      try
        projectsList = localStorage.getItem("#{@storeURI}")
        if projectsList
          projectsList = projectsList.split(',')
        else
          projectsList = []
        @projectsList = projectsList
        #kept for now
        ### 
        projectNames = []
        for model in @lib.models
          projectNames.push(model.id)
          @projectsList.push(model.id) 
        ### 
        callback(@projectsList)
      catch error
        console.log "could not fetch projectsName from #{@name} because of error #{error}"
    
    getProject:(projectName)=>
      return @lib.get(projectName)
    
    getProjectFiles:(projectName,callback)=>
      #Get all the file names withing a project : should actually get the file tree? (subdirs support etc)
      #hack
      files = []
      project = @lib.get(projectName)
      #TODO: oh the horror: we have to fetch all model data just to look at the files list
      if project?
        projectURI = "#{@storeURI}-#{projectName}"
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
      projectURI = "#{@storeURI}-#{newName}"
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
      
      projectName = project.name 
      @_addToProjectsList(project.name)
      
      projectURI = "#{@storeURI}-#{projectName}"
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
      if oldFiles?
        oldFiles = oldFiles.split(',')
        added = _.difference(filesList,oldFiles)
        removed = _.difference(oldFiles,filesList)
        @_removeFile(projectName, fileName) for fileName in removed
      
      localStorage.setItem(rootStoreURI,filesList.join(","))
      
      attributes = _.clone(project.attributes)
      for attrName, attrValue of attributes
        if attrName not in project.persistedAttributeNames
          delete attributes[attrName]
      strinfigiedProject = JSON.stringify(attributes)
      
      localStorage.setItem(projectURI,strinfigiedProject)
      
      
      @vent.trigger("project:saved")  
    
    loadProject:(projectName, silent=false)=>
      d = $.Deferred()
      project =  @lib.get(projectName)
      project.collection = @lib
      projectURI = "#{@storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.sync = project.sync
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      
      onProjectLoaded=()=>
        #remove old thumbnail
        thumbNailFile = project.rootFolder.get(".thumbnail.png")
        project.rootFolder.remove(thumbNailFile)
        project._clearFlags()
        if not silent
          @vent.trigger("project:loaded",project)
        d.resolve(project)
      
      project.dataStore = @
      project.rootFolder.fetch().done(onProjectLoaded)
      return d
   
    deleteProject:(projectName)=>
      d = $.Deferred()
      console.log "browser storage deletion of #{projectName}"
      project = @lib.get(projectName)
      
      projectURI = "#{@storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
      
      file = null
      filesURI = "#{projectURI}-files"
      console.log "filesURI #{filesURI}"
      fileNames = localStorage.getItem(filesURI)
      console.log "fileNames #{fileNames}"
      if fileNames
        fileNames = fileNames.split(',')
        for fileName in fileNames 
          fileUri = "#{rootStoreURI}-#{fileName}"
          console.log "deleting #{fileUri}"
          localStorage.removeItem(fileUri)
      
      @_removeFromProjectsList(projectName)
      @lib.remove(project)
      
      return d.resolve()
      
    renameProject:(oldName, newName)=>
      #EVEN MORREEE HACKS ! thanks backbone
      project = @lib.get(oldName)
      @lib.remove(project)
      project.name = newName
      
      projectURI = "#{@storeURI}-#{newName}"
      project.localstorage = new Backbone.LocalStorage(projectURI)
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      project.save()
      
      @lib.add(project)
    
    destroyFile:(projectName, fileName)=>
      return @_removeFile(projectName, fileName)  
      
    _removeFromProjectsList:(projectName)=>
      projects = localStorage.getItem(@storeURI)
      if projects?
        projects = projects.split(',')
        index = projects.indexOf(projectName)
        projects.splice(index, 1)
        if projects.length>0 then projects=projects.join(',') else projects = ""
        localStorage.setItem(storeURI,projects)
        index = @projectsList.indexOf(projectName)
        @projectsList.splice(index, 1)
        
        console.log "projectName"
        projectURI = "#{storeURI}-#{projectName}"
        rootStoreURI = "#{projectURI}-files"
        
        localStorage.removeItem(rootStoreURI)
        localStorage.removeItem(projectURI)
      
    _addToProjectsList:(projectName)=>
      projects = localStorage.getItem(@storeURI)
      if projects?
        if projects == ""
          projects = "#{projectName}"
        else
          projects = projects.split(',')
          if not (projectName in projects)
            projects.push(projectName)
            projects = projects.join(',')
      else
        projects = "#{projectName}"
      
      @projectsList.push(projectName)
      localStorage.setItem(@storeURI,projects)
        
    _removeFile:(projectName, fileName)=>
      projectURI = "#{@storeURI}-#{projectName}"
      filesURI = "#{projectURI}-files"
      fileNames = localStorage.getItem(filesURI)
      fileNames = fileNames.split(',')
      index = fileNames.indexOf(fileName)
      fileNames.splice(index, 1)
      fileNames = fileNames.join(',')
      localStorage.setItem(filesURI,fileNames)
      
      fileURI = "#{filesURI}-#{fileName}"
      localStorage.removeItem(fileURI)
      
    _sourceFetchHandler:([store, projectName, path, deferred])=>
      #This method handles project/file content requests and returns appropriate data
      if store != "browser"
        return null
      #console.log "handler recieved #{store}/#{projectName}/#{path}"
      result = ""
      if not projectName? and path?
        shortName = path
        #console.log "proj"
        #console.log @project
        file = @project.rootFolder.get(shortName)
        result = file.content
        result = "\n#{result}\n"
      else if projectName? and not path?
        console.log "will fetch project #{projectName}'s namespace"
        project = @getProject(projectName)
        console.log project
        namespaced = {}
        for index, file of project.rootFolder.models
          namespaced[file.name]=file.content
          
        namespaced = "#{projectName}={"
        for index, file of project.rootFolder.models
          namespaced += "#{file.name}:'#{file.content}'"
        namespaced+= "}"
        #namespaced = "#{projectName}="+JSON.stringify(namespaced)
        #namespaced = """#{projectName}=#{namespaced}"""
        result = namespaced
        
      else if projectName? and path?
        console.log "will fetch #{path} from #{projectName}"
        getContent=(project) =>
          project.rootFolder.fetch()
          file = project.rootFolder.get(path)
          
          #now we replace all "local" (internal to the project includes) with full path includes
          result = file.content
          result = result.replace /(?!\s*?#)(?:\s*?include\s*?)(?:\(?\"([\w\//:'%~+#-.*]+)\"\)?)/g, (match,matchInner) =>
            includeFull = matchInner.toString()
            return """\ninclude("browser:#{projectName}/#{includeFull}")\n"""
          result = "\n#{result}\n"
          #console.log "browserStore returning #{result}"
          
          deferred.resolve(result)
        @loadProject(projectName,true).done(getContent)
      
      
       
  return BrowserStore