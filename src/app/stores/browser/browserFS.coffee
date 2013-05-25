define (require)->
  FSBase = require '../fsBase'
  
  class BrowserFS extends FSBase
    constructor:(sep)->
      super(sep or "/")
    
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
      if options.toJson?
        if options.toJson
          localStorage.setItem(path, JSON.stringify(content.toJSON()))
      else
        localStorage.setItem(path, content)
        
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
    
    mv: ( srcPath, tgtPath )->
      if localStorage.getItem(srcPath) == null
        throw new Error("Source path does not exist")
      if localStorage.getItem(tgtPath) != null
        throw new Error("Destination path already exists")
        
      @mkdir( tgtPath ) 
      
      subElements = @readdir( srcPath )
      tgtElements = []
      for element in subElements
        tgtElement = element
        if element == @basename( srcPath ) + ".coffee"
          tgtElement =  @basename( tgtPath ) + ".coffee"
        
        src = localStorage.getItem( @join( [srcPath, element] ) )
        if src?
          src = src.replace( element, tgtElement ) #FIXME: iffy in case "element" is also present as string inside src (file content)
        localStorage.setItem( @join( [tgtPath, tgtElement] ), src )  
        tgtElements.push( tgtElement )
        
      localStorage.setItem( tgtPath, tgtElements.join( "," ) )
      @rmdir( srcPath )
      
      
          
    
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

    isDir:(path) ->
      #HOWTO ???
      data = localStorage.getItem( path )
      data = JSON.parse(data)
      if data.isDir?
        if data.isDir
          return true
      return false
          
    isProj:(path) ->
      #check if the specified path is a coffeescad project (ie, a directory, with a .coffee file with the same name
      #as the folder)
      if @isDir( path )
        filesList = fs.readdirSync( path )
        projectMainFileName = pathMod.basename + ".coffee"
        if projectMainFileName in filesList
          return true
          
      return false
    
    join:( paths )->
      #something like path.join()
      return paths.join( @sep )
      
    dirname:( path )->
      components = path.split( @sep )
      if components.length > 0
        components.pop()
        result = components.pop()
        
    basename:( path )->
      components = path.split( @sep )
      if components.length > 0
        return components.pop()
      return path
      
    absPath:( path , rootUri)->
      if path.split( @sep ).length <= 1
        path = @join( [rootUri, path] )
      return path
    
    exists: ( path ) ->
      if localStorage.getItem( path )? then return true else return false
        
  return BrowserFS