define (require)->
  utils = require 'core/utils/utils'
  merge = utils.merge
  DropboxFS = require './dropboxFS'
  StoreBase = require '../storeBase2'
  Project = require 'core/projects/project'
 
  class DropBoxStore extends StoreBase
    
    constructor:(options)->
      options = options or {}
      defaults = {
       name:"Dropbox", shortName:"Dropbox", type:"DropboxStore", description: "Store to the Dropbox Cloud based storage: requires login",
       rootUri:"/", isDataDumpAllowed: false, isLoginRequired:true, showPaths:false}
      options = merge defaults, options
      super options
      
      @fs = new DropboxFS()     
      #@debug = true
      #@vent.on("DropboxStore:login", @login)
      #handler for project/file data fetch requests
      #reqRes.addHandler("getdropboxFileOrProjectCode",@_sourceFetchHandler)
      
    login:=>
      try
        onLoginSucceeded=()=>
          localStorage.setItem("dropboxCon-auth",true)
          @loggedIn = true
          @_dispatchEvent("DropboxStore:loggedIn")
          
        onLoginFailed=(error)=>
          throw error
          
        loginPromise = @fs.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
      catch error
        @_dispatchEvent("DropboxStore:loginFailed")
        
    logout:=>
      try
        onLogoutSucceeded=()=>
          localStorage.removeItem("dropboxCon-auth")
          @loggedIn = false
          @_dispatchEvent("DropboxStore:loggedOut")
        onLoginFailed=(error)=>
          throw error
          
        logoutPromise = @fs.signOut()
        $.when(logoutPromise).done(onLogoutSucceeded)
                            .fail(onLogoutFailed)
      
      catch error
        @_dispatchEvent("DropboxStore:logoutFailed")
    
    setup:()->
      super
      
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
      authOk = localStorage.getItem("dropboxCon-auth")
      if urlAuthOk?
        @login()
        appBaseUrl = window.location.protocol + '//' + window.location.host + window.location.pathname
        window.history.replaceState('', '', appBaseUrl)     
      else
        if authOk?
          @login()
    
    listProjects:( uri )=>
      uri = uri or @rootUri
      return @fs.readdir( uri )
    
    listProjectFiles:( uri )=>
      uri = @fs.absPath( uri, @rootUri )
      return @fs.readdir( uri )
    
    saveProject:( project, newName )=> 
      console.log "saving project to dropbox"
      project.dataStore = @
      if newName?
        project.name = newName
      projectUri = @fs.join([@rootUri, project.name])
      @fs.mkdir(projectUri)
      
      for index, file of project.getFiles()
        fileName = file.name
        filePath = @fs.join([projectUri, fileName])
        ext = fileName.split('.').pop()
        content = file.content
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
        
        @fs.writefile(filePath, content, {toJson:false})
        #file.trigger("save")
      @_dispatchEvent( "project:saved",project )
    
    loadProject:( projectUri , silent=false)=>
      projectName = projectUri.split(@fs.sep).pop()
      projectUri = @fs.join([@rootUri, projectUri])
      
      d = $.Deferred()
      project = new Project
          name : projectName
      project.dataStore = @
      
      onProjectLoaded=()=>
        project._clearFlags()
        if not silent
          @_dispatchEvent("project:loaded",project)
        d.resolve(project)
      
      loadFiles=( filesList ) =>
        promises = []
        for fileName in filesList
          filePath = @fs.join( [projectUri, fileName] )
          promises.push( @fs.readfile( filePath ) )
        $.when.apply($, promises).done ()=>
          data = arguments
          for fileName, index in filesList #todo remove this second iteration
            project.addFile 
              name: fileName
              content: data[index]
          onProjectLoaded()
      
      @fs.readdir( projectUri ).done(loadFiles)
      return d
    
    deleteProject:( projectName )=>
      projectPath = @fs.join([@rootUri, projectName])
      #index = @projectsList.indexOf(projectName)
      #@projectsList.splice(index, 1)
      return @fs.rmdir( projectPath )
    
    renameProject:(oldName, newName)=>
      #move /rename project and its main file
      #index = @projectsList.indexOf(oldName)
      #@projectsList.splice(index, 1)
      #@projectsList.push(newName)      
      return @fs.mv(oldName, newName).done(@fs.mv("/#{newName}/#{oldName}.coffee","/#{newName}/#{newName}.coffee"))
    
    getProject:(projectName)=>
      #console.log "locating #{projectName} in @projectsList"
      #console.log @projectsList
      if projectName in @projectsList
        return @loadProject(projectName,true)
      else
        return null
    
    #helpers
    projectExists: ( uri )=>
      #checks if specified project /project uri exists
      uri = @fs.absPath( uri, @rootUri )
      return @fs.exists( uri )
    
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
    
    destroyFile:(projectName, fileName)=>
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