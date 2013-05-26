define (require)->
  utils = require 'core/utils/utils'
  merge = utils.merge
  BrowserFS = require './browserFS'
  StoreBase = require '../storeBase2'
  Project = require 'core/projects/project'
  
  class BrowserStore extends StoreBase
    
    constructor:(options)->
      options = options or {}
      defaults = {
       name:"browser", shortName:"browser", type:"browserStore", description: "Store to localstorage (browser)",
       rootUri:"projects", isDataDumpAllowed: true,showPaths:false}
      options = merge defaults, options
      super options
        
      @cacheSize = 5
      @fs = new BrowserFS()     
      
    setup:()->
      super
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
      uri = @fs.absPath( uri, @rootUri )
      try
        files = @fs.readdir( uri )
        return files
      catch error
        throw new Error( "could not fetch files from #{uri} because of error #{error}" )
    
    saveProject:( project, newName )=> 
      project.dataStore = @
      if newName?
        project.name = newName
      projectUri = @fs.join([@rootUri, project.name])
      @fs.mkdir(projectUri)
      
      for index, file of project.getFiles()
        fileName = file.name
        filePath = @fs.join([projectUri, fileName])
        ext = fileName.split('.').pop()
        @fs.writefile(filePath, file, {toJson:true})
        #file.trigger("save")
      @_dispatchEvent( "project:saved",project )
    
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
        
        #
        @_dispatchEvent( "project:loaded",project )
        return project
        
      catch error
        throw new Error( "could not load project: error #{error}")

    deleteProject:( projectName )=>
      projectPath = @fs.join([@rootUri, projectName])
      @fs.rmdir( projectPath )
      
    renameProject:( projectName, newName) =>
      #should this me "move project?"
      projectSrcPath = @fs.join([@rootUri, projectName])
      projectDstPath = @fs.join([@rootUri, newName])
      
      #TODO: add destination validity check
      #TODO: how to deal with currently open project ??
      #project.name = newName
      @fs.mv( projectSrcPath, projectDstPath )
     
    repair:()->
      #hack/fix in case project list got deleted
      projectsList = localStorage.getItem(@storeURI)
      if projectsList is null or projectsList == "" or projectsList == "null"
        projectsList = @_getAllProjectsHelper()
        localStorage.setItem(@storeURI, projectsList)
    
    exportProjects:->
      #dump all projects to a zip file
      #for zip export
      #require 'jszip'
      #require 'jszip-deflate'
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
    
    #helpers
    projectExists: ( uri )=>
      #checks if specified project /project uri exists
      uri = @fs.absPath( uri, @rootUri )
      return @fs.exists( uri )
      
    getThumbNail:( projectName )=>
      filePath = @fs.join([@rootUri, projectName, ".thumbnail.png"])
      file = @fs.readfile( filePath , {parseJson:true})
      return file.content
    
    spaceUsage: ->
      return @fs.spaceUsage()
    
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
      
    destroyFile:(projectName, fileName)=>
      return @_removeFile(projectName, fileName)  
      
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
      
       
  return BrowserStore