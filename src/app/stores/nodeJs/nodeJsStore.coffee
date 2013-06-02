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
    
    listDir:( uri )=>
      uri = if uri? then uri else @rootUri
      d = $.Deferred()
      
      callbackbOfSorts=(err, files )=>
        #console.log "got folders"+ files + " errors "  + err
        results = []
        if not err?
          for file in files
            filePath = @fs.join([uri, file])
            result = @fs.getType( filePath )
            console.log "Result", result
            results.push( result )
        
        d.resolve(results)
        
      $.when(@fs.readdir( uri )).done(callbackbOfSorts)
      return d

    saveProject:( project, path )=> 
      super
      
      @fs.mkdir(project.uri)
      
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
      super
      
      projectName = projectUri.split(@fs.sep).pop()
      #projectUri = @fs.join([@rootUri, projectUri])
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

    #helpers
    projectExists: ( uri )=>
      #checks if specified project /project uri exists
      return @fs.exists( uri )

  return NodeJsStore