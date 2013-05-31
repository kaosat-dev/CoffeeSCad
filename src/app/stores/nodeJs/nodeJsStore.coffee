define (require)->
  StoreBase = require '../storeBase2'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  NodeFS = require './nodeFS'
  
  class NodeJsStore extends StoreBase
    constructor:(options)->
      options = options or {}
      defaults = {enabled: (if process? then true else false) ,name:"node", shortName:"node", type:"nodeStore",
      description: "NodeJS local file system store",
      rootUri:if process? then process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE else null,
      isDataDumpAllowed: false,showPaths:true}
      
      options = merge defaults, options
      super options
      
      @fs = new NodeFS()
    
    listProjects:( uri )=>
      console.log "listing projects (folders) at " + uri
      uri = uri or @rootUri
      console.log "real uri", uri
      d = $.Deferred()
      callbackbOfSorts=(err, folders )->
        console.log "got folders"+ folders
        result = folders? or []
        d.resolve(folders)
        
      #$.when(@fs.readdir( uri )).done(callbackbOfSorts)
      fs = nodeRequire('fs')
      fs.readdir( "/home/mmoissette/", callbackbOfSorts )
      
      return d
      
    listProjectFiles:( uri )=>
      #this should be list files?
      #Get all the file/folder names within a project 
      uri = @fs.absPath( uri, @rootUri )
      try
        files = @fs.readdir( uri )
        return files
      catch error
        throw new Error( "could not fetch files from #{uri} because of error #{error}" )

    saveProject:( project, options )=> 
      console.log "saving project to dropbox"
      options = options or {}
      
      project.dataStore = @
      
      if options.newName?
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
      
    
