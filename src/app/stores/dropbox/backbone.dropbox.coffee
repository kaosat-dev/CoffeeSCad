define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Dropbox = require "dropbox"
  
  class DropBoxStorage
    constructor:(debug=false)->
      @debug = debug
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
    
    sync:(method, model, options)=>
      switch method
        when 'read' 
          if model.id?
            console.log "bla",model.id
            return @find(model, options)
          else
            return @findAll(model, options)
          
        when 'create'
          unless model.id
            model.set model.id, model.idAttribute
          
          console.log("id"+model.get("id"))
          id = model.id
          id = "#{id}"
          @writeFile(id, JSON.stringify(model))
          return model.toJSON()
          
        when 'update'
          id = model.id
          id = "#{id}"
          if model.collection?
            if model.collection.path?
              id ="#{model.collection.path}/#{id}"
          console.log "id: #{id}"
          @writeFile(id, JSON.stringify(model))
          
          #hack
          for model in @destroy_cache
            console.log "REALLY deleting model"
            console.log model
            id = model.id
            if model.collection?
              if model.collection.path?
                id ="#{model.collection.path}/#{id}"
            else if model.memoPath
              id ="#{model.memoPath}/#{id}"
            @remove(id)
          @destroy_cache = []
          
          
          return model.toJSON()
          
        when 'delete'
          #delete caching experiment
          #model.memoPath = model.collection.path 
          #@destroy_cache.push(model)
          id = model.id
          if model.collection?
            if model.collection.path?
              id ="#{model.collection.path}/#{id}"
          @remove(id)
          
    
    find: (model, options) ->
       path = model.rootPath or model.path or "/"
       promise  =  @_findByName(path, model.id)
       
       parse=(res)=>
         console.log "res"
         console.log res[0]
         filePath = res[0].path
         @_readFile(filePath).then (res)->
           console.log "gne"
           console.log res
           #return JSON.parse(res)
           model.set(JSON.parse(res))
           console.log model
       
       $.when(promise).then(parse)
       
      #return JSON.parse(this.localStorage().getItem(this.name+"-"+model.id))
    
    findAll:(model, options)->
      console.log "searching at #{model.path}"
      rootPath = model.path
      success = options.success
      error = options.error
      
      promises = []
      promise  = @_readDir(model.path)
      model.trigger('fetch', model, null, options)
      
      fetchData=(entries)=>
        #d = $.Deferred()
        for fileName in entries
          filePath = "#{rootPath}/#{fileName}"
          if @debug
            console.log "file path: #{filePath}"
          promises.push @_readFile(filePath)
        $.when.apply($, promises).done ()=>
          preResults = arguments
          if model.rawData?
            #console.log entries
            results = []
            for i in [0...entries.length]
              entry = entries[i]
              if @debug
                console.log "retrieved entry #{entry}"
              entryData = entry.split('.')
              #ext= entryData[entryData.length - 1]
              #filename = entryData[0...entryData.length-1].join('.')
              filename = entry
              results.push 
                name:filename
                #ext:ext
                content:preResults[i]
          else
            results = $.map(results, JSON.parse)
          #console.log("ALL DONE", results)
          if options.update?
            if options.update == true
              model.update(results)
              model.trigger("update",results)
            else
              model.reset(results, collection:model)
          else
            model.reset(results, collection:model)
          if success?
            success(results)
          return results
        #return d
          
      p = $.when(promise).then(fetchData)    
      
      return p
      
    remove:(name)=>
      d = $.Deferred()
      @client.remove name, (error, userInfo)=>
        if error
          @formatError(error,d)
        console.log "removed #{name}"
        d.resolve()
      return d.promise()
        
    writeFile:(name, content)->
      d = $.Deferred()
      @client.writeFile name, content, (error, stat) =>
        if error
          @formatError(error,d)
        if @debug
          console.log "writen file #{name} with content #{content}"
          console.log ("File saved as revision " + stat.versionTag)
        d.resolve()
      return d.promise()
        
    createFolder:(name)->
      @client.mkdir name, (error,stat) =>
        if error
          @formatError(error,d)  
        console.log "folder create ok"
    
    move:(fromPath, toPath)=>
      d = $.Deferred()
      @client.move fromPath, toPath, (error)=>
        if error
          @formatError(error,d)
        d.resolve()
      return d.promise()
        
    _readDir:(path)->
      d = $.Deferred()
      @client.readdir path, (error, entries)=>
        if error
          @formatError(error,d)
        d.resolve entries
      return d.promise()
        
    _readFile:(path, options)->
      options = options or {}
      d = $.Deferred()
      @client.readFile path,options, (error, data)=>
        if error
          @formatError(error,d)
        d.resolve data
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
        
  return DropBoxStorage 