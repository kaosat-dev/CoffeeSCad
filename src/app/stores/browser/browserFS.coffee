define (require)->
  FSBase = require '../fsBase'
  
  class BrowserFS extends FSBase
    constructor:->
     
    readdir:( path )=>
      #projectURI = "#{@storeURI}-#{projectName}"
      elements = localStorage.getItem(filesURI)
      elements = fileNames.split(',')
      return elements 
    
    rmdir: ( path )=>
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

    readfile:( path )->
      ext = path.split("/")
      ext = ext[ext.length-1]
      if not path of localStorage
        throw new Error("no such file")
        
      fileData = localStorage.getItem( path )
      rawData = JSON.parse(fileData)
      return rawData
        
    
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