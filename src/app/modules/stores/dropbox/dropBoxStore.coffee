define (require)->
  #base64 = require 'base64'
  buildProperties = require 'modules/core/utils/buildProperties'
  backbone_dropbox = require './backbone.dropbox'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
  class DropBoxLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored on dropbox
    """  
    #model: Project
    #sync: backbone_dropbox.sync
    path: ""
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
      
    onReset:()->
      console.log "DropBoxLibrary reset" 
      console.log @
      console.log "_____________"
  
  class DropBoxStore extends Backbone.Model
    attributeNames: ['name','loggedIn']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "dropBoxStore"
      storeType: "dropBox"
      tooltip:"Store to the Dropbox Cloud based storage: requires login"
      loggedIn:false
    
    constructor:(options)->
      super options
      @store = new backbone_dropbox()
      console.log "backbone dropbox store"
      console.log @store
      @isLogginRequired = true
      @vent = vent
      @vent.on("dropBoxStore:login", @login)
      @vent.on("dropBoxStore:logout", @logout)
      
      #experimental
      @lib = new DropBoxLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
      #should this be here ?
      @projectsList = []
      
    login:=>
      console.log "login requested"
      try
        onLoginSucceeded=()=>
          console.log "dropbox logged in"
          localStorage.setItem("dropboxCon-auth",true)
          @loggedIn = true
          @vent.trigger("dropBoxStore:loggedIn")
        onLoginFailed=(error)=>
          console.log "dropbox loggin failed"
          throw error
          
        loginPromise = @store.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
        #@lib.fetch()
      catch error
        @vent.trigger("dropBoxStore:loginFailed")
        
    logout:=>
      try
        onLogoutSucceeded=()=>
          console.log "dropbox logged out"
          localStorage.removeItem("dropboxCon-auth")
          @loggedIn = false
          @vent.trigger("dropBoxStore:loggedOut")
        onLoginFailed=(error)=>
          console.log "dropbox logout failed"
          throw error
          
        logoutPromise = @store.signOut()
        $.when(logoutPromise).done(onLogoutSucceeded)
                            .fail(onLogoutFailed)
      
      catch error
        @vent.trigger("dropBoxStore:logoutFailed")
    
    authCheck:()->
      getURLParameter=(paramName)->
        searchString = window.location.search.substring(1)
        i = undefined
        val = undefined
        params = searchString.split("&")
        i = 0
        while i < params.length
          val = params[i].split("=")
          return unescape(val[1])  if val[0] is paramName
          i++
        null
      urlAuthOk = getURLParameter("_dropboxjs_scope")
      console.log "dropboxStore got redirect param #{urlAuthOk}"
      
      authOk = localStorage.getItem("dropboxCon-auth")
      console.log "dropboxStore got localstorage Param #{authOk}"

      if urlAuthOk?
        @login()
        window.history.replaceState('', '', '/')
      else
        if authOk?
          @login()
    
    getProjectsName:(callback)=>
      #hack
      if @store.client?
        @store.client.readdir "/", (error, entries) =>
          if error
            console.log ("error")
          else
            console.log "@projectsList"
            @projectsList = entries
            console.log entries
            callback(entries)
    
    getProject:(projectName)=>
      #console.log "locating #{projectName} in @projectsList"
      #console.log @projectsList
      if projectName in @projectsList
        return true
      else
        return null
    
    getProjectFiles:(projectName,callback)=>
      #console.log "fetching project files for #{projectName}"
      if @store.client?
        @store.client.readdir "/#{projectName}/", (error, entries) =>
          if error
            console.log ("error")
            console.log error
          else
            callback(entries)
   
    getProjectFiles2:(projectName)=> 
      return @store.client.readdir "/#{projectName}/"
            
    getThumbNail:(projectName)=>
      
    
    createProject:(fileName)=>
      #project = @lib.create(options)
      project = new Project
        name: fileName
      project.rootFolder.sync = @store.sync
      project.rootFolder.path = project.get("name") 
      
      project.createFile
        name: fileName
      project.createFile
        name: "config"
       
      #FIXME: have one event for both create & load, as in effect , they do the same thing ? (reset views, replace current)
      #@vent.trigger("project:created",project)  
      @vent.trigger("project:loaded",project) 
      
      
    saveProject:(project, newName)=>
      console.log "saving projectto dropbox"
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      project.dataStore = @
      project.rootPath="/"+project.name+"/"
      
      project.sync = @store.sync
      project.rootFolder.sync = project.sync
      project.rootFolder.path = project.name
      
      filesList = []
      for index, file of project.rootFolder.models
        #actual saving of file, not json INSIDE the file
        projectName = project.name
        name = file.name
        content =file.content
        filePath = "#{projectName}/#{name}"
        filesList.push(file.name)
        ext = name.split('.').pop()
        if ext == "png"
          #save thumbnail
          dataURIComponents = content.split(',')
          mimeString = dataURIComponents[0].split(':')[1].split(';')[0]
          if(dataURIComponents[0].indexOf('base64') != -1)
            data =  atob(dataURIComponents[1])
            array = []
            for i in [0...data.length]
              array.push(data.charCodeAt(i))
            content = new Blob([new Uint8Array(array)], {type: 'image/jpeg'})
          else
            byteString = unescape(dataURIComponents[1])
            length = byteString.length
            ab = new ArrayBuffer(length)
            ua = new Uint8Array(ab)
            for i in [0...length]
              ua[i] = byteString.charCodeAt(i)
          file.trigger("save")
          file.sync = @store.sync
        console.log "saving file to #{filePath}"
        @store.writeFile(filePath, content)
        
      #fetch old list of files, for diff, delete old file if not present anymore
      ###
      oldFiles = @projectsList
      added = _.difference(filesList,oldFiles)
      removed = _.difference(oldFiles,filesList)
      console.log "added",added
      console.log "removed", removed
      @_removeFile(projectName, fileName) for fileName in removed
      ###
        
      @vent.trigger("project:saved")
      
    saveProject_:(project,newName)=>
      console.log "saving projectto dropbox"
      project.collection = null
      @lib.add(project)
      if newName?
        project.name = newName
      project.sync = @store.sync
      project.rootFolder.sync = project.sync
      project.rootFolder.path = project.name
      #project.rootFolder.changeStorage("dropboxDataStore",{path:project.name})
      project.save()
      ### 
      for index, file of project.rootFolder.models
        #file.pathRoot= project.get("name")
        #file.save()
        
        #actual saving of file, not json hack
        projectName = project.name
        name = file.name
        content =file.content
        filePath = "#{projectName}/#{name}"
        ext = name.split('.').pop()
        if ext == "png"
          #save thumbnail
          dataURIComponents = content.split(',')
          console.log "dataURIComponents"
          console.log dataURIComponents
          mimeString = dataURIComponents[0].split(':')[1].split(';')[0]
          if(dataURIComponents[0].indexOf('base64') != -1)
            data =  atob(dataURIComponents[1])
            array = []
            for i in [0...data.length]
              array.push(data.charCodeAt(i))
            content = new Blob([new Uint8Array(array)], {type: 'image/jpeg'})
          else
            byteString = unescape(dataURIComponents[1])
            length = byteString.length
            ab = new ArrayBuffer(length)
            ua = new Uint8Array(ab)
            for i in [0...length]
              ua[i] = byteString.charCodeAt(i)
          file.trigger("save")
        console.log "saving file to #{filePath}"
        @store.writeFile(filePath, content)
        ###
      @vent.trigger("project:saved")
    
    loadProject:(projectName)=>
      if projectName in @projectsList
        console.log "dropbox loading project #{projectName}"
        project = new Project()
        project.name = projectName
        
        onProjectLoaded=()=>
          thumbNailFile = project.rootFolder.get(".thumbnail.png")
          project.rootFolder.remove(thumbNailFile)
          @vent.trigger("project:loaded",project)
          
        project.rootFolder.rawData = true
        project.rootFolder.sync = @store.sync
        project.rootFolder.path = projectName
        project.rootFolder.fetch().done(onProjectLoaded)
        @lib.add(project)
        project.dataStore = @
        return project
        
    deleteProject:(projectName)=>
      index = @projectsList.indexOf(projectName)
      @projectsList.splice(index, 1)
      return @store.remove("/#{projectName}")
      
    renameProject:(oldName, newName)=>
      #move /rename project and its main file
      index = @projectsList.indexOf(oldName)
      @projectsList.splice(index, 1)
      @projectsList.push(newName)      
      return @store.move(oldName,newName).done(@store.move("/#{newName}/#{oldName}.coffee","/#{newName}/#{newName}.coffee"))
      
    _removeFile:(projectName, fileName)=>
      return @store.remove("#{projectName}/#{fileName}")
    
    destroyFile:(projectName, fileName)=>
      return @store.remove("#{projectName}/#{fileName}")
      
      
  return DropBoxStore