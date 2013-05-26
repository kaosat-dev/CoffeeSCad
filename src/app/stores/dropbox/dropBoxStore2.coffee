define (require)->
  #base64 = require 'base64'
  buildProperties = require 'core/utils/buildProperties'
  backbone_dropbox = require './backbone.dropbox'
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  
  Project = require 'core/projects/project'
  
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
    attributeNames: ['name','loggedIn','isDataDumpAllowed']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "DropboxStore"
      storeType: "Dropbox"
      tooltip:"Store to the Dropbox Cloud based storage: requires login"
      loggedIn:false
      isDataDumpAllowed:false
    
    constructor:(options)->
      super options
      @debug = true
      
      @store = new backbone_dropbox()
      @isLogginRequired = true
      @vent = vent
      
      @vent.on("DropboxStore:login", @login)
      @vent.on("DropboxStore:logout", @logout)
      
      #experimental
      @lib = new DropBoxLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
      #should this be here ?
      @projectsList = []
      @cachedProjects = {}
      #handler for project/file data fetch requests
      reqRes.addHandler("getdropboxFileOrProjectCode",@_sourceFetchHandler)
      
    login:=>
      try
        onLoginSucceeded=()=>
          localStorage.setItem("dropboxCon-auth",true)
          @loggedIn = true
          @vent.trigger("DropboxStore:loggedIn")
          console.lo
          
        onLoginFailed=(error)=>
          throw error
          
        loginPromise = @store.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
      catch error
        @vent.trigger("DropboxStore:loginFailed")
        
    logout:=>
      try
        onLogoutSucceeded=()=>
          localStorage.removeItem("dropboxCon-auth")
          @loggedIn = false
          @vent.trigger("DropboxStore:loggedOut")
        onLoginFailed=(error)=>
          throw error
          
        logoutPromise = @store.signOut()
        $.when(logoutPromise).done(onLogoutSucceeded)
                            .fail(onLogoutFailed)
      
      catch error
        @vent.trigger("DropboxStore:logoutFailed")
    
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
      #console.log "dropboxStore got redirect param #{urlAuthOk}"
      
      authOk = localStorage.getItem("dropboxCon-auth")
      #console.log "dropboxStore got localstorage Param #{authOk}"


      if urlAuthOk?
        @login()
        appBaseUrl = window.location.protocol + '//' + window.location.host + window.location.pathname
        window.history.replaceState('', '', appBaseUrl)     
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
            @projectsList = entries
            if callback?
              callback(entries)
    
    getProject:(projectName)=>
      #console.log "locating #{projectName} in @projectsList"
      #console.log @projectsList
      if projectName in @projectsList
        return @loadProject(projectName,true)
      else
        return null
    
    getProjectFiles:(projectName)=>
      #returns all files in a project
      d = $.Deferred()
      if @store.client?
        @store.client.readdir "/#{projectName}/", (error, entries) =>
          if error
            d.reject(error)
          else
            d.resolve(entries)
       else
        d.reject(error)
      return d
        
    getProjectFiles2:(projectName)=> 
      return @store.client.readdir "/#{projectName}/"
      
    getProjectFile:(projectName, fileName)=>
      
            
    getThumbNail:(projectName)=>
      myDeferred = $.Deferred()
      deferred = @store._readFile( "/#{projectName}/.thumbnail.png",{arrayBuffer:true})
      
      parseBase64Png=( rawData)->
        #convert binary png to base64
        bytes = new Uint8Array(rawData)
        data = ''
        for i in [0...bytes.length]
          data += String.fromCharCode(bytes[i])
        data =   btoa(data)
        #crashes
        #data = btoa(String.fromCharCode.apply(null, ))
        base64src='data:image/png;base64,'+data
        myDeferred.resolve(base64src)

      deferred.done(parseBase64Png)
      return myDeferred
    
    checkProjectExists:(projectName)=>
      return @store._readDir "/#{projectName}/"
    
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
            console.log "base64 v1"
            data =  atob(dataURIComponents[1])
            array = []
            for i in [0...data.length]
              array.push(data.charCodeAt(i))
            content = new Blob([new Uint8Array(array)], {type: 'image/png'})
          else
            console.log "other v2"
            byteString = unescape(dataURIComponents[1])
            length = byteString.length
            ab = new ArrayBuffer(length)
            ua = new Uint8Array(ab)
            for i in [0...length]
              ua[i] = byteString.charCodeAt(i)
        file.trigger("save")
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
    
    loadProject:(projectName,silent=false)=>
      d = $.Deferred()
      if projectName in @projectsList
        console.log "dropbox loading project #{projectName}"
        @lib.add(project)
        
        project = new Project()
        project.name = projectName
        
        onProjectLoaded=()=>
          thumbNailFile = project.rootFolder.get(".thumbnail.png")
          project.rootFolder.remove(thumbNailFile)
          project._clearFlags()
          if not silent
            @vent.trigger("project:loaded",project)
          d.resolve(project)
        
        project.dataStore = @  
        project.rootFolder.rawData = true
        project.rootFolder.sync = @store.sync
        project.rootFolder.path = projectName
        
        project.rootFolder.fetch().done(onProjectLoaded)
      else
        @checkProjectExists(projectName)
        .fail(()=>d.fail(new Error("Project #{projectName} not found")))
        .done ()=>
          @projectsList.push(projectName)
          @loadProject(projectName)
        
      return d
        
    deleteProject:(projectName)=>
      index = @projectsList.indexOf(projectName)
      @projectsList.splice(index, 1)
      return @store.remove("/#{projectName}")
    
    destroyFile:(projectName, fileName)=>
      return @store.remove("#{projectName}/#{fileName}")
    
    renameProject:(oldName, newName)=>
      #move /rename project and its main file
      index = @projectsList.indexOf(oldName)
      @projectsList.splice(index, 1)
      @projectsList.push(newName)      
      return @store.move(oldName,newName).done(@store.move("/#{newName}/#{oldName}.coffee","/#{newName}/#{newName}.coffee"))
      
    _removeFile:(projectName, fileName)=>
      return @store.remove("#{projectName}/#{fileName}")
    
    _sourceFetchHandler:([store, projectName, path, deferred])=>
      #This method handles project/file content requests and returns appropriate data
      if store != "dropbox"
        return null
      console.log "handler recieved #{store}/#{projectName}/#{path}"
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
          #cache for faster access: TODO: clear cache
          @cachedProjects[projectName]=project
          file = project.rootFolder.get(path)
          
          #now we replace all "local" (internal to the project includes) with full path includes
          result = file.content
          result = result.replace /(?!\s*?#)(?:\s*?include\s*?)(?:\(?\"([\w\//:'%~+#-.*]+)\"\)?)/g, (match,matchInner) =>
            includeFull = matchInner.toString()
            return """\ninclude("dropbox:#{projectName}/#{includeFull}")\n"""
            
          result = "\n#{result}\n"
          deferred.resolve(result)
        
        if not (projectName of @cachedProjects)
          @loadProject(projectName,true).done(getContent)
        else 
          getContent(@cachedProjects[projectName])
          
           
        
      return result
      
  return DropBoxStore