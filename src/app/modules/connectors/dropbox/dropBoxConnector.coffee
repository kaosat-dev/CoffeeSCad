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
  
  class DropBoxConnector extends Backbone.Model
    attributeNames: ['loggedIn']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "dropBoxConnector"
      storeType: "dropBox"
      tooltip:"Connector to the Dropbox Cloud based storage: requires login"
      loggedIn:false
    
    constructor:(options)->
      super options
      @store = new backbone_dropbox()
      console.log "backbone dropbox store"
      console.log @store
      @isLogginRequired = true
      @vent = vent
      @vent.on("dropBoxConnector:login", @login)
      @vent.on("dropBoxConnector:logout", @logout)
      
      #experimental
      @lib = new DropBoxLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
    login:=>
      console.log "login requested"
      try
        onLoginSucceeded=()=>
          console.log "dropbox logged in"
          localStorage.setItem("dropboxCon-auth",true)
          @loggedIn = true
          @vent.trigger("dropBoxConnector:loggedIn")
        onLoginFailed=(error)=>
          console.log "dropbox loggin failed"
          throw error
          
        loginPromise = @store.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
        #@lib.fetch()
      catch error
        @vent.trigger("dropBoxConnector:loginFailed")
        
    logout:=>
      try
        onLogoutSucceeded=()=>
          console.log "dropbox logged out"
          localStorage.removeItem("dropboxCon-auth")
          @loggedIn = false
          @vent.trigger("dropBoxConnector:loggedOut")
        onLoginFailed=(error)=>
          console.log "dropbox logout failed"
          throw error
          
        logoutPromise = @store.signOut()
        $.when(logoutPromise).done(onLogoutSucceeded)
                            .fail(onLogoutFailed)
      
      catch error
        @vent.trigger("dropBoxConnector:logoutFailed")
    
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
      console.log "dropboxConnector got redirect param #{urlAuthOk}"
      
      authOk = localStorage.getItem("dropboxCon-auth")
      console.log "dropboxConnector got localstorage Param #{authOk}"

      if urlAuthOk?
        @login()
        window.history.replaceState('', '', '/')
      else
        #just for tests
        ### 
        if authOk?
          setTimeout ( =>
            @login()
          ), 5000
        ###
        if authOk?
          @login()
      
    createProject:(fileName)=>
      #project = @lib.create(options)
      project = new Project
        name: fileName
      project.pfiles.sync = @store.sync
      project.pfiles.path = project.get("name") 
      
      project.createFile
        name: fileName
      project.createFile
        name: "config"
       
      #FIXME: have one event for both create & load, as in effect , they do the same thing ? (reset views, replace current)
      #@vent.trigger("project:created",project)  
      @vent.trigger("project:loaded",project) 
      
    saveProject:(project)=>
      console.log "saving project"
      @lib.add(project)
      project.sync=@store.sync
      project.pathRoot=project.get("name") 
      
      project.pfiles.sync = @store.sync
      project.pfiles.path = project.get("name") 
      for index, file of project.pfiles.models
        #file.pathRoot= project.get("name")
        #file.save()
        
        #actual saving of file, not json hack
        projectName = project.get("name")
        name = file.get("name")
        ext = file.get("ext")
        content =file.get("content")
        filePath = "#{projectName}/#{name}.#{ext}"
        
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
      
      #project.save()
      @vent.trigger("project:saved")
    
    loadProject:(projectName)=>
      console.log "dropbox loading project #{projectName}"
      #TODO: check if project exists
      project = new Project()
      project.set({"name":projectName},{silent:true})
      
      onProjectLoaded=()=>
        thumbNailFile = project.pfiles.get(".thumbnail")
        project.pfiles.remove(thumbNailFile)
        @vent.trigger("project:loaded",project)
        
      project.pfiles.rawData = true
      project.pfiles.sync = @store.sync
      project.pfiles.path = projectName
      project.pfiles.fetch().done(onProjectLoaded)
      @lib.add(project)
      return project
    
    getProjectsName:(callback)=>
      #hack
      if @store.client?
        @store.client.readdir "/", (error, entries) ->
          if error
            console.log ("error")
          else
            console.log entries
            callback(entries)
          
    getProjectFiles:(projectName,callback)=>
      #hack
      if @store.client?
        @store.client.readdir "/#{projectName}/", (error, entries) ->
          if error
            console.log ("error")
          else
            console.log entries
            callback(entries)
      
    
  return DropBoxConnector