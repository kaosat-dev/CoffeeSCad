define (require)->
  utils = require 'core/utils/utils'
  merge = utils.merge
  BrowserFS = require './browserFS'
  StoreBase = require '../storeBase2'
  Project = require 'core/projects/project'
  
  #TODO: replace all getProjects name, files etc, with "readDirs etc", ie something closer to a file system manipulation
  
  class BrowserStore extends StoreBase
    
    constructor:(options)->
      options = options or {}
      defaults = {
       browserStore:"store", shortName:"browser", type:"browser", description: "Store to localstorage (browser)",
       rootUri:"projects", isDataDumpAllowed: true,showPaths:false}
      options = merge defaults, options
      super options
        
      @cacheSize = 5
      @cachedProjects = []#TODO: remove 
      @fs = new BrowserFS()     
      
    setup:()->
      #super.setup()
      @fs.mkdir( @rootUri )
      #check for any local storage issues, repair if necessary
      #@repair() 
      
    listProjects:( uri )=>
      uri = uri or @rootUri
      try
        projects = []
        projects = @fs.readdir( uri )
        return projects
      catch error
        throw new Error( console.log "could not fetch projects at #{uri} because of error #{error}" )
    
    listProjectFiles:( uri )=>
      #Get all the file names within a project : should actually get the file tree? (subdirs support etc)
      try
        files = []
        files = @fs.readdir( uri )
        return files
      catch error
        throw new Error( "could not fetch files from #{uri} because of error #{error}" )
    
    saveProject:( project, newName )=> 
      project.dataStore = @
      if newName?
        project.name = newName
        #TODO: delete original project
      projectUri = @fs.join([@rootUri, project.name])
      
      @fs.mkdir(projectUri)
      
      for index, file of project.getFiles()
        filePath = @fs.join([projectUri, file.name])
        @fs.writefile(filePath, file)
        #ext = name.split('.').pop()
        #file.trigger("save")

    
    loadProject:( projectUri , silent=false)=>
      projectName = projectUri.split(@fs.sep).pop()
      projectUri = @fs.join([@rootUri, projectUri])
      if projectUri in @cachedProjects
        #TODO: how to invalidate cache???
        return @cachedProjects[ projectUri ]
      try
        project = new Project
          name : projectName
        project.dataStore = @
        #first list the files in the project
        fileNames = @fs.readdir( projectUri )
        for fileName in fileNames
          fileUri = @fs.join([projectUri, fileName])
          fileData = @fs.readfile( fileUri, {parseJson:true})
          if fileData?
            fileContent = fileData.content
          else
            fileContent = ""
          project.addFile
            name: fileName
            content: fileContent
        
        #TODO: is this even needed ? the event dispatching should not come from the stores themselves
        #as they are meant to be independant of the app's core
        onProjectLoaded=()=>
          project._clearFlags()
          project.trigger("loaded")
          #project.rootFolder.trigger("reset")
          if not silent
            @vent.trigger("project:loaded",project)
          d.resolve(project)
        
        @cachedProjects[ projectUri ] = project
        return project
        
      catch error
        throw new Error( "could not load project: error #{error}")

    deleteProject:(projectName)=>
      projectPath = @fs.join([@rootUri, projectName])
      @fs.rmdir( projectPath )
     
    repair:()->
      #hack/fix in case project list got deleted
      projectsList = localStorage.getItem(@storeURI)
      if projectsList is null or projectsList == "" or projectsList == "null"
        projectsList = @_getAllProjectsHelper()
        localStorage.setItem(@storeURI, projectsList)
    
    dumpAllProjects:->
      #dump all projects to a zip file
      #for zip dump
      #require 'jszip'
      #require 'jszip-deflate'
      
      #TODO: add caching
      #exportTimeStamp = new Date().getTime()
      #if @exportTimeStamp
      #  bla = 2
      
      
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
      
    getThumbNail:( projectName )=>
      filePath = @fs.join([@rootUri, projectName, ".thumbnail.png"])
      file = @fs.readfile( filePath )
      
    
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