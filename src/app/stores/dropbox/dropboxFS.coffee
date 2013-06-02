define (require)->
  FSBase = require '../fsBase'
  $ = require 'jquery'
  _ = require 'underscore'
  Dropbox = require "dropbox"
  
  class DropboxFS extends FSBase
    constructor:(sep)->
      super(sep or "/")
      
      @debug = true
      @client=null
      @destroy_cache = []
   
    authentificate:()=>
      @client = new Dropbox.Client
        key: "h8OY5h+ah3A=|AS0FmmbZJrmc8/QbpU6lMzrCd5lSGZPCKVtjMlA7ZA=="
        sandbox: true
      @client.authDriver new Dropbox.Drivers.Redirect(rememberUser:true, useQuery:true)
      
      d = $.Deferred()
      @client.authenticate (error, client)=>
        if error?
          @formatError(error,d)
        d.resolve(error)
      return d.promise()
      
    signOut:()->
      d = $.Deferred()
      @client.signOut (error)=>
        if error?
          @formatError(error,d)
        else
          d.resolve(error)
      return d.promise()
    

    formatError:(error, deferred)->
      switch error.status
        when 401
          # If you're using dropbox.js, the only cause behind this error is that
          # the user token expired.
          # Get the user through the authentication flow again.
          error = new Error("Dropbox token expired") 
        when 404 
          # The file or folder you tried to access is not in the user's Dropbox.
          # Handling this error is specific to your application.
          error = new Error("Failed to find the specified file or folder") 
        when 507 
          # The user is over their Dropbox quota.
          # Tell them their Dropbox is full. Refreshing the page won't help.
          error = new Error("Dropbox quota exceeded") 
        when 503 
          # Too many API requests. Tell the user to try again later.
          # Long-term, optimize your code to use fewer API calls.
          error = new Error("Dropbox: too many requests") 
        when 400  
          error = new Error("Dropbox: bad input parameter") 
          # Bad input parameter
        when 403  
          # Bad OAuth request.
          error = new Error("Dropbox: bad oauth request") 
        when 405 
          # Request method not expected
          error = new Error("Dropbox: unexpected request method") 
        else
          error = new Error("Dropbox: uknown error") 
          # Caused by a bug in dropbox.js, in your application, or in Dropbox.
          # Tell the user an error occurred, ask them to refresh the page.
      deferred.reject(error)

    
    mkdir:( path )->
      d = $.Deferred()
      @client.mkdir path, (error,stat) =>
        if error
          @formatError(error,d) 
        else
          d.resolve(stat)
      return d
    
    readdir: ( path )->
      d = $.Deferred()
      @client.readdir path, (error, entries, folderStat, entriesStats)=>
        if error
          @formatError(error,d)
        d.resolve(entries, folderStat, entriesStats)
      return d.promise() 

    rmdir: (name)=>
      d = $.Deferred()
      @client.remove name, (error, userInfo)=>
        if error
          @formatError(error,d)
        console.log "removed #{name}"
        d.resolve()
      return d.promise()
        
    writefile: (name, content)->
      d = $.Deferred()
      @client.writeFile name, content, (error, stat) =>
        if error
          @formatError(error,d)
        if @debug
          console.log "writen file #{name} with content #{content}"
          console.log ("File saved as revision " + stat.versionTag)
        d.resolve()
      return d.promise()
   
    readfile:( path, options )->
      options = options or {}
      d = $.Deferred()
      @client.readFile path,options, (error, data)=>
        if error
          @formatError(error,d)
        d.resolve data
      return d.promise()
   
    rmfile:( path )->
      d = $.Deferred()
      @client.remove name, (error, userInfo)=>
        if error
          @formatError(error,d)
        console.log "removed #{name}"
        d.resolve()
      return d.promise()
    
    mv: (fromPath, toPath)=>
      d = $.Deferred()
      @client.move fromPath, toPath, (error)=>
        if error
          @formatError(error,d)
        d.resolve()
      return d.promise()
    
    _findByName:(path,name)->
      console.log path,name
      d = $.Deferred()
      @client.findByName path,name, (error, data)=>
        if error
          @formatError(error,d)
        console.log "found data #{data}"
        d.resolve(data)
      return d.promise()
    
    
    basename:( path )->
      components = path.split( @sep )
      if components.length > 0
        return components.pop()
      return path
    
    absPath:( path , rootUri)->
      if path.split( @sep ).length <= 1
        path = @join( [rootUri, path] )
      return path
    
    exists: ( path )->
      d = $.Deferred()
      @client.findByName path, "*", {}, (error, data)=>
        if error
          d.reject(false)
        else
          d.resolve(true)
      return d.promise()
   
    getType : ( path ) ->
      result = {name: @basename( path ),
      path : path
      }
      if @isDir( path )
        result.type = 'folder'
      else
        result.type = 'file'

  return DropboxFS