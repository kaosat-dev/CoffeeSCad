define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Dropbox = require "dropbox"
  
  class DropBoxStorage
    constructor:->
      @client = new Dropbox.Client
        key: "your app key here"
        sandbox: true
      
    authentificate:()=>
      @client.authDriver new Dropbox.Drivers.Redirect(rememberUser:true, useQuery:true)
      @client.authenticate (error, client)=>
        if error
          return @showError(error)
        @validated()
        
    signOut:()->
      @client.signOut (error)=>
        if not error?
          console.log "signout ok"

    validated:()->
      console.log "all is fine"
      
    showError:(error)->
      console.log "error in dropbox"
      switch error.status
        when 401 then
          # If you're using dropbox.js, the only cause behind this error is that
          # the user token expired.
          # Get the user through the authentication flow again.
        when 404 then
          # The file or folder you tried to access is not in the user's Dropbox.
          # Handling this error is specific to your application.
        when 507 then
          # The user is over their Dropbox quota.
          # Tell them their Dropbox is full. Refreshing the page won't help.
        when 503 then
          # Too many API requests. Tell the user to try again later.
          # Long-term, optimize your code to use fewer API calls.
        when 400  then
          # Bad input parameter
        when 403 then 
          # Bad OAuth request.
        when 405 then
          # Request method not expected
        else
          # Caused by a bug in dropbox.js, in your application, or in Dropbox.
          # Tell the user an error occurred, ask them to refresh the page.
      
    sync:(method, model, options)=>
      switch method
        when 'read' 
          console.log "reading"
          if model.id?
            console.log "bla",model.id
            return @find(model, options)
          else
            return @findAll(model, options)
          
        when 'create'
          console.log "creating"
          unless model.id
            model.set model.id, model.idAttribute
            #model.id = guid()
          
          console.log("id"+model.get("id"))
          id = model.id
          if model.get "ext"
            id = "#{id}.#{model.get('ext')}"
          @writeFile(id, JSON.stringify(model))
          return model.toJSON()
          
        when 'update'
          console.log "updating"
          id = model.id
          if model.get "ext"
            id = "#{id}.#{model.get('ext')}"
          if model.collection.path?
            id ="#{model.collection.path}/#{id}"
          console.log "id: #{id}"
          @writeFile(id, JSON.stringify(model))
          return model.toJSON()
          
        when 'delete'
          console.log "deleting"
          console.log model
          id = model.id
          if model.get "ext"
            id = "#{id}.#{model.get('ext')}"
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
        for fileName in entries
          filePath = "#{rootPath}/#{fileName}"
          console.log "file path: #{filePath}"
          promises.push @_readFile(filePath)
        $.when.apply($, promises).done ()=>
          results = arguments
          results = $.map(results, JSON.parse)
          console.log("ALL DONE", results)
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
      $.when(promise).then(fetchData)    
      
      
    remove:(name)->
      @client.remove name, (error, userInfo)->
        if error
          return showError(error)
        console.log "removed #{name}"
        
    writeFile:(name, content)->
      @client.writeFile name, content, (error, stat) =>
        if error
          return @showError(error)
        console.log ("File saved as revision " + stat.versionTag)
        
    createFolder:(name)->
      @client.mkdir name, (error,stat) =>
        if error
          return @showError(error)  
        console.log "folder create ok"
        
    _readDir:(path)->
      d = $.Deferred()
      @client.readdir path, (error, entries)=>
        if error
          return @showError(error)
        d.resolve entries
      return d.promise()
        
    _readFile:(path)->
      d = $.Deferred()
      @client.readFile path, (error, data)=>
        if error
          return @showError(error)
        d.resolve data
      return d.promise()
    
    _findByName:(path,name)->
      console.log path,name
      d = $.Deferred()
      @client.findByName path,name, (error, data)=>
        if error
          return @showError(error)
        console.log "found data #{data}"
        d.resolve(data)
      return d.promise()
        
        
      
  store = new DropBoxStorage
  return store 