define (require)->
  Backbone = require 'backbone'
  
  buildProperties = require 'core/utils/buildProperties'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  class StoreBase extends Backbone.Model
    idAttribute: 'name'
    attributeNames: ['name','shortName', 'type','description', '',  'isLogInRequired', 'loggedIn']
    
    
    defaults:
      name: "baseStore"
      shortName: "base"
      type: "base"
      description: "Store base class"
      rootUri: ""
      loggedIn: true
      isLogginRequired:false
      isDataDumpAllowed: true
      showPaths: false
    
    buildProperties @
    
    constructor:(options)->
      
      defaults = {name:"store", shortName:"", type:"", description: "", rootUri:"", loggedIn:true, isLoginRequired:false,
      isDataDumpAllowed: false,showPaths:false}
      options = merge defaults, options
      super( options )
      {@name, @shortName, @type, @description, @rootUri, @loggedIn, @isLogginRequired} = options
      
      #TODO: refactor this
      #@vent = options.vent
      #@vent.on("#{@storeType}:login", @login)
      #@vent.on("#{@storeType}:logout", @logout)
      
      @cachedProjectsList = []
      @cachedProjects = []
      
      @fs = require('./fsBase')
      
    login:=>
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
    setup:()->
      #do authentification or any other preliminary operation
    
    tearDown:()->
      #tidily shut down this store: is this necessary ? as stores have the same lifecycle as
      #the app itself ?
    
    listProjects:( uri )=>
     
    listProjectFiles:( uri )=>
        
    saveProject:( project, newName )=> 
    
    loadProject:( projectUri, silent=false )=>
    
    deleteProject:( projectName )=>
      
    renameProject:( oldName, newName )=>
      
    saveFile:( file, uri )=>
    
    loadFile:( uri )=>
      
    getThumbNail:( projectName )=>
          
    
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
        
       
  return StoreBase