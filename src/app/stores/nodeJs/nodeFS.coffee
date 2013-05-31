define (require)->
  FSBase = require '../fsBase'
  #we use the nodeRequire alias to avoid clash of requirejs and node's require
  try
    fs = nodeRequire('fs')
    pathMod = nodeRequire('path')
  catch error
  
  $ = require 'jquery'
  
  class NodeFS extends FSBase
    constructor:(sep)->
      super(sep or "/")
      
    mkdir:( path )->
      deferred = $.Deferred()
      callback = deferred.resolve
      fs.mkdir( path, callback )
      return deferred
    
    readdir: ( path )->
      console.log("reading path", path)
      deferred = $.Deferred()
      callback = deferred.resolve
      
      fs.readdir( path, callback )
      
      return deferred
    
    rmdir: ( path )->
      deferred = $.Deferred()
      callback = deferred.resolve
      fs.rmdir( path, callback )
      
      return deferred
    
    writefile:(path, content, options)->
      deferred = $.Deferred()
      callback = deferred.resolve
      fs.writeFile( path, options, callback )
      
      return deferred
    
    isDir: (path) ->
      if fs.existsSync( path )
        fs.lstatSync(path).isDirectory()  
    
    isProj: (path) ->
      #check if the specified path is a coffeescad project (ie, a directory, with a .coffee file with the same name
      #as the folder)
      if @isDir( path )
        filesList = fs.readdirSync( path )
        projectMainFileName = pathMod.basename + ".coffee"
        if projectMainFileName in filesList
          return true
          
      return false
    
    listProjs: ( path ) ->
      #return a list of all projects in a given path: FIXME: should this be here or in the store ??
      
    getType : ( path ) ->
      result = {}
      stat = fs.statSync(path)
      if stat.isDirectory()
        result.type = 'folder'
