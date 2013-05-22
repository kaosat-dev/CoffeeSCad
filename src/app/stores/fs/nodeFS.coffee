define (require)->
  FSBase = require './fsBase'
  fs = require('fs')
  
  class NodeFS extends FSBase
    constructor:->
      
    mkdir:( path )->
      deferred = $.deferred()
      callback = deferred.resolve
      fs.mkdir( path, callback )
      
      return deferred
    
    readdir: ( path )->
      deferred = $.deferred()
      callback = deferred.resolve
      fs.readir( path, callback )
      
      return deferred
    
    rmdir: ( path )->
      deferred = $.deferred()
      callback = deferred.resolve
      fs.rmdir( path, callback )
      
      return deferred
    
    writefile:(path, content, options)->
      deferred = $.deferred()
      callback = deferred.resolve
      fs.writeFile( path, options, callback )
      
      return deferred
      
      
      
      
