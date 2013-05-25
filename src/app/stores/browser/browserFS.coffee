define (require)->
  FSBase = require '../fsBase'
  
  class BrowserFS extends FSBase
    constructor:(sep)->
      @sep = sep or "/"
    
    join:( paths )->
      #something like path.join()
      return paths.join( @sep )
      
    dirname:( path) ->
      components = path.split( @sep )
      if components.length > 0
        components.pop()
        result = components.pop()
      
    
    mkdir:(path)->
      #make directory(ies) : if a full path, generates all the intermediate directories if
      #they don't exist
      if not localStorage.getItem( path )?
        #if it is a subfolder, add it to parent's index
        pathComponents = path.split( @sep )
        if pathComponents.length > 1
           curDir = pathComponents.pop()
           prePath = @join( pathComponents )
           @_updateDirContent( prePath, curDir )
        localStorage.setItem( path , "")
      
    
    readdir:( path )=>
      #projectURI = "#{@storeURI}-#{projectName}"
      elements = localStorage.getItem( path )
      if elements?
        elements = elements.split(',')
      return elements 
    
    rmdir: ( path )=>
      subElements = localStorage.getItem( path )
      #if not subElements? or subElements == ""
      #  throw new Error(" No such path ")
        
      subElements = subElements.split(',')
      for element in subElements
        pathTosub = @join( [path, element])
        localStorage.removeItem( pathTosub )
      localStorage.removeItem( path )
      ### 
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
      ###
    _updateDirContent: ( path , newEntry ) ->  
      items = localStorage.getItem( path )
      if items?
        if items == ""
          items = []
        else
          items = items.split(',')
        index = items.indexOf( newEntry )
        if index == -1
          items.push( newEntry )
          items=items.join( ',' )
          #items.splice(index, 1)
          #if items.length>0 then items=items.join( ',' ) else items = ""
          localStorage.setItem( path, items )
      else
        localStorage.setItem( path, newEntry )
        
    writefile:(path, content, options)->
      options = options or {}
      dirName = @dirname( path )
      baseDir = path.split(@sep)
      baseDir.pop()
      baseDir = baseDir.join( @sep )
      
      fileName = path.split( @sep ).pop()
      @_updateDirContent(baseDir, fileName)
      
      localStorage.setItem(path, JSON.stringify(content.toJSON()))

    readfile:( path, options )->
      options = options or {}
      ext = path.split("/")
      ext = ext[ext.length-1]
      if not path of localStorage
        throw new Error("no such file")
        
      fileData = localStorage.getItem( path )
      if options.parseJson?
        fileData = JSON.parse(fileData)
      return fileData
        
    
    rm:( path )=>
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

    isDir: (path) ->
      #HOWTO ???
      data = localStorage.getItem( path )
      data = JSON.parse(data)
      if data.isDir?
        if data.isDir
          return true
      return false
          
    isProj: (path) ->
      #check if the specified path is a coffeescad project (ie, a directory, with a .coffee file with the same name
      #as the folder)
      if @isDir( path )
        filesList = fs.readdirSync( path )
        projectMainFileName = pathMod.basename + ".coffee"
        if projectMainFileName in filesList
          return true
          
      return false

  return BrowserFS