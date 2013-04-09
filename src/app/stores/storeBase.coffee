define (require)->
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'

  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  
  buildProperties = require 'core/utils/buildProperties'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  Project = require 'core/projects/project'
  
  class ProjectLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored in the stores specific storage
    """  
    model: Project
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
    
    comparator: (project)->
      date = new Date(project.lastModificationDate)
      return date.getTime()
      
  
  class StoreBase extends Backbone.Model
    idAttribute: 'name'
    
    attributeNames: ['name','isLogInRequired', 'loggedIn']
    
    defaults:
      name: "baseStore"
      storeType: ""
      storeShortName:""
      tooltip:"Store base class"
      loggedIn: true
      isLogginRequired:false
    attributeNames: ['name', 'loggedIn']
    buildProperties @
    
    constructor:(options)->
      defaults = {storeType:"",storeShortName:"",storeURI:""}
      options = merge defaults, options
      {@storeType,@storeShortName,@storeURI} = options
      super options
        
      @vent = vent
      @vent.on("#{@storeType}:login", @login)
      @vent.on("#{@storeType}:logout", @logout)
      
      #for storage wrapping
      @lib = new ProjectLibrary()
      @projectsList = []
      @cachedProjects = []
      
      #handler for project/file data fetch requests
      reqRes.addHandler("get#{@storeShortName}FileOrProjectCode",@_sourceFetchHandler)
      
    login:=>
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
    authCheck:()->
    
    getProjectsName:(callback)=>
      
    getProject:(projectName)=>
     
    getProjectFiles:(projectName,callback)=>
        
    saveProject_:(project, newName)=>
    
    saveProject:(project,newName)=> 
    
    loadProject:(projectName, silent=false)=>
   
    deleteProject:(projectName)=>
      
    renameProject:(oldName, newName)=>
    
    ###--------------Private methods---------------------###
    _removeFromProjectsList:(projectName)=>
      
    _addToProjectsList:(projectName)=>
        
    _removeFile:(projectName, fileName)=>
      
    _sourceFetchHandler:([store,projectName,path])=>
      #This method handles project/file content requests and returns appropriate data
      if store != @storeShortName
        throw new Error("Bad store name specified")
      console.log "handler recieved #{store}/#{projectName}/#{path}"
      result = ""
      if not projectName? and path?
        throw new Error("Cannot resolve this path in #{@storeType}")
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
          console.log project
          project.rootFolder.fetch()
          file = project.rootFolder.get(path)
          result = file.content
          result = "\n#{result}\n"
          return result
        @loadProject(projectName,true).done(getContent)
        
      
      
       
  return BrowserStore