define (require)->
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'

  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  
  buildProperties = require 'core/utils/buildProperties'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  Project = require 'core/projects/project'
  
  #for zip dump
  require 'jszip'
  require 'jszip-deflate'
  
  #TODO: replace all getProjects name, files etc, with "readDirs etc", ie something closer to a file system manipulation
  
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
    attributeNames: ['name', 'loggedIn', 'isDataDumpAllowed']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "browserStore"
      storeType: "browser"
      tooltip:"Store to localstorage (browser)"
      loggedIn: true
      isDataDumpAllowed: true
    
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
      console.log "fetched lib", @lib
      
      #handler for project/file data fetch requests
      reqRes.addHandler("getbrowserFileOrProjectCode",@_sourceFetchHandler)
      
      #check for any local storage issues, repair if necessary
      @repair() 
      
    login:=>
      console.log "browser logged in"
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
    authCheck:()->
    
    repair:()->
      #hack/fix in case project list got deleted
      projectsList = localStorage.getItem(@storeURI)
      if projectsList is null or projectsList == "" or projectsList == "null"
        projectsList = @_getAllProjectsHelper()
        localStorage.setItem(@storeURI, projectsList)
    
    dumpAllProjects:->
      #dump all projects to a zip file
      #TODO: add caching
      
      zip = new JSZip()
      
      #TODO: refactor
      projectsList = localStorage.getItem("#{@storeURI}")
      if projectsList
        projectsList = projectsList.split(',')
      else
        projectsList = []
          
      for projectName in projectsList
        try
          files = @_getProjectFiles( projectName )
          folder = zip.folder(projectName)
          for fileName in files
            fileContent = @_readFile(projectName, fileName)
            folder.file(fileName, fileContent)
        catch error

      #zip.file("fileName", "fileContent")
      dataType = "base64"#"blob"
      content = zip.generate({compression:'DEFLATE'})
      zipB64Url = "data:application/zip;#{dataType},"+content
      
      return zipB64Url
        
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
    
    getProjectFiles:(projectName)=>
      #Get all the file names withing a project : should actually get the file tree? (subdirs support etc)
      d = $.Deferred()
      fileNames = []
      #project = @lib.get(projectName)
      if projectName in @projectsList
        fileNames = @_getProjectFiles(projectName)
        #projectURI = "#{@storeURI}-#{projectName}"
        #filesURI = "#{projectURI}-files"
        #project.rootFolder.sync = project.sync
        #project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(filesURI))
        #fileNames = localStorage.getItem(filesURI)
        #files = fileNames.split(',')
      d.resolve(fileNames)
      return d
      
    getThumbNail:(projectName)=>
      deferred = $.Deferred()
      file = @_readFile(projectName,".thumbnail.png")
      #deferred.resolve(file.content)
      deferred.resolve(file)
      return deferred
        
    saveProject:(project,newName)=>
      #experiment of saving projects withouth using backbone localstorage
      project.collection = null
      @lib.add(project)
      
      nameChange = false
      if project.name != newName
        nameChange = true
        
      if newName?
        project.name = newName
        
      firstSave = false
      if not project.dataStore?
        firstSave = true
      else if project.dataStore != @ or nameChange
        firstSave = true
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
        #if ext != "png"
        localStorage.setItem(filePath,JSON.stringify(file.toJSON()))
        #else
        #  localStorage.setItem(filePath, file.content)
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
      
      @vent.trigger("project:saved",project)
      if firstSave
        project._clearFlags()
      project.trigger("save", project)
      
    
    autoSaveProject:(srcProject)=>
      #used for autoSaving projects
      srcProjectName = srcProject.name
      
      fakeClone =(project,newName)=>
        clonedProject = new Project({name:newName})
        for pfile in project.rootFolder.models
          clonedProject.addFile
            name:pfile.name
            content:pfile.content
        return clonedProject
        
      projectName = "autosave"#srcProjectName+"_auto" 
      project = fakeClone(srcProject,projectName)
      @lib.add(project)
      @_addToProjectsList(projectName)
      
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
      
      localStorage.setItem(rootStoreURI,filesList.join(","))
      
      attributes = _.clone(project.attributes)
      for attrName, attrValue of attributes
        if attrName not in project.persistedAttributeNames
          delete attributes[attrName]
      strinfigiedProject = JSON.stringify(attributes)
      
      localStorage.setItem(projectURI,strinfigiedProject)
      
      
      @vent.trigger("project:autoSaved")  
    
    loadProject:(projectName, silent=false)=>
      d = $.Deferred()
      project =  new Project
        name : projectName #@lib.get(projectName)
      project.collection = @lib
      projectURI = "#{@storeURI}-#{projectName}"
      rootStoreURI = "#{projectURI}-files"
      project.rootFolder.sync = project.sync
      project.rootFolder.changeStorage("localStorage",new Backbone.LocalStorage(rootStoreURI))
      
      onProjectLoaded=()=>
        project._clearFlags()
        project.trigger("loaded")
        #project.rootFolder.trigger("reset")
        if not silent
          @vent.trigger("project:loaded",project)
        
        d.resolve(project)
      
      project.dataStore = @
      
      fileNames = @_getProjectFiles(projectName)
      for fileName in fileNames
        content = @_readFile(projectName,fileName)
        ### 
        #remove old thumbnail
        thumbNailFile = project.rootFolder.get(".thumbnail.png")
        if thumbNailFile?
          project.rootFolder.remove(thumbNailFile)
        ###
        project.addFile
          content : content
          name : fileName
      onProjectLoaded()
      #project.rootFolder.fetch().done(onProjectLoaded)
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
        if index != -1
          projects.splice(index, 1)
          if projects.length>0 then projects=projects.join(',') else projects = ""
          localStorage.setItem(@storeURI,projects)
          index = @projectsList.indexOf(projectName)
          @projectsList.splice(index, 1)
          
          console.log "projectName"
          projectURI = "#{@storeURI}-#{projectName}"
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
      
    _getProjectFiles:(projectName)=>
      projectURI = "#{@storeURI}-#{projectName}"
      filesURI = "#{projectURI}-files"
      fileNames = localStorage.getItem(filesURI)
      fileNames = fileNames.split(',')
      return fileNames
      
    _readFile:(projectName, fileName)=>
      projectURI = "#{@storeURI}-#{projectName}"
      filesURI = "#{projectURI}-files"
      fileNames = localStorage.getItem(filesURI)
      fileNames = fileNames.split(',')
      if fileName in fileNames
        fileUri = "#{filesURI}-#{fileName}"
        fileData = localStorage.getItem(fileUri)
        rawData = JSON.parse(fileData)
        #console.log "raw file Data", rawData
        return rawData["content"]
      else
        throw new Error("no such file")
      
      
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
      
    _getAllProjectsHelper:()->
      #just a a temporary helper, as the projects List seems to have been cleared by accident?
      projects = []
      for item, key of localStorage
        projData = item.split("-")
        #console.log "projData",projData
        if projData[0] is "projects"
          projectName = projData[1]
          if projectName?
            if projectName not in projects
              projects.push(projectName)
      
      projects = projects.join(",")
      #console.log "projects",projects
      return projects
      #projectURI = "#{@storeURI}-#{projectName}"
      #filesURI = "#{projectURI}-files"
      #fileNames = localStorage.getItem(filesURI)
      
       
  return BrowserStore