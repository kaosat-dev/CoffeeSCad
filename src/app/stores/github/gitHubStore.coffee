define (require)->
  github = require 'github'
  vent = require 'core/messaging/appVent'
  
  Project = require 'core/projects/project'
  
  class GitHubRedirectDriver
    constructor:->
      @state=1 #initial   
      @client_id = "c346489dcec8041bd88f"
      @redirect_uri=window.location
      @scopes = "gist"
      @authUrl = "https://github.com/login/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{window.location}&scope=#{@scopes}"
    
    getURLParameter:(paramName)->
        searchString = window.location.search.substring(1)
        i = undefined
        val = undefined
        params = searchString.split("&")
        i = 0
        while i < params.length
          val = params[i].split("=")
          return unescape(val[1])  if val[0] is paramName
          i++
        null
    
    postStuff:(url, params)->
      params = encodeURIComponent(params)
      console.log "params"+params
      request = new XMLHttpRequest()
      request.open('get', url, true)
      if ("withCredentials" in request)
        console.log "cors supported"
      request.onreadystatechange = => #Call a function when the state changes.
        console.log "toto"+request.readyState
        alert request.responseText  if request.readyState is 4 and request.status is 200
      request.setRequestHeader("Content-type", "application/x-www-form-urlencoded")
      request.setRequestheader("Origin","http://kaosat-dev.github.com/CoffeeSCad/")
      request.send(params)
      
      console.log "request"
      console.log request
      
    postJsonP:(url,params)->
      foo=(response)->
        meta = response.meta
        data = response.data
        console.log(meta)
        console.log(data)

    run:->
      code = @getURLParameter("code")
      if code?
        @state=2
        console.log("github:phase2")
      if @state == 1
        console.log "gihub auth url #{@authUrl}"
        console.log "redirecting"
        window.location.href = @authUrl
      if @state == 2
        @tokenUrl = "https://github.com/login/oauth/access_token"
        params = "client_id=#{@client_id}&client_secret=mlkmlk&code=#{code}"
        console.log "sending code request to url #{@tokenUrl} with params #{params}"
        
        @postStuff(@tokenUrl,params)
        #@tokenUrl = "https://github.com/login/oauth/access_token?client_id=#{@client_id}&client_secret=&code=#{code}"
        #@postStuff(@tokenUrl,"")
        foo=(response)->
          console.log "jsonp response"
          console.log response
          
        ###
        $.ajax
          type: "GET"
          url: @tokenUrl
          data: null
          jsonpCallback: 'foo'
          success: (r)->console.log "github auth phase 2 ok : #{r}"
          error:(e)->console.log "aie aie error #{e.message}"
          dataType: 'jsonp'
        ###
          
  class GitHubStore
    constructor:->
      @driver= new GitHubRedirectDriver()
      ###
      @github = new Github
        token: "OAUTH_TOKEN"
        auth: "oauth"
      ###  
    authentificate:()=>
      ###@client = new Dropbox.Client 
        key: "h8OY5h+ah3A=|AS0FmmbZJrmc8/QbpU6lMzrCd5lSGZPCKVtjMlA7ZA=="
        sandbox: true
      ###
      #@client.authDriver new Dropbox.Drivers.Redirect(rememberUser:true, useQuery:true)
      @driver.run()
      console.log "here"
      d = $.Deferred()
      ### 
      @client.authenticate (error, client)=>
        console.log "in auth"
        console.log error
        console.log client
        if error?
          d.reject(@formatError(error))
        d.resolve(error)
      ###
      return d.promise()
      
    sync:()->
  
  class GitHubLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored on github
    """  
    model: Project
    #sync: backbone_github.sync
    path: ""
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
      
    onReset:()->
      console.log "GitHubLibrary reset" 
      console.log @
      console.log "_____________"
  
  class GitHubStore extends Backbone.Model
    defaults:
      name: "gitHubStore"
      storeType: "gitHub"
    
    constructor:(options)->
      super options
      @store = new GitHubStore()
      @isLogginRequired = true
      @loggedIn = true
      @vent = vent
      @vent.on("gitHubStore:login", @login)
      @vent.on("gitHubStore:logout", @logout)
      
      #experimental
      @lib = new GitHubLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
    login:=>
      console.log "login requested"
      try
        onLoginSucceeded=()=>
          console.log "github logged in"
          localStorage.setItem("githubCon-auth",true)
          @loggedIn = true
          @vent.trigger("gitHubStore:loggedIn")
        onLoginFailed=(error)=>
          console.log "github loggin failed"
          throw error
          
        loginPromise = @store.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
        #@lib.fetch()
      catch error
        @vent.trigger("gitHubStore:loginFailed")
        
    logout:=>
      try
        onLogoutSucceeded=()=>
          console.log "github logged out"
          localStorage.removeItem("githubCon-auth")
          @loggedIn = false
          @vent.trigger("gitHubStore:loggedOut")
        onLoginFailed=(error)=>
          console.log "github logout failed"
          throw error
          
        logoutPromise = @store.signOut()
        $.when(logoutPromise).done(onLogoutSucceeded)
                            .fail(onLogoutFailed)
      
      catch error
        @vent.trigger("gitHubStore:logoutFailed")
    
    authCheck:()->
      getURLParameter=(paramName)->
        searchString = window.location.search.substring(1)
        i = undefined
        val = undefined
        params = searchString.split("&")
        i = 0
        while i < params.length
          val = params[i].split("=")
          return unescape(val[1])  if val[0] is paramName
          i++
        null
      urlAuthOk = getURLParameter("code")
      console.log "githubStore got redirect param #{urlAuthOk}"
      
      authOk = localStorage.getItem("githubCon-auth")
      console.log "githubStore got localstorage Param #{authOk}"

      if urlAuthOk?
        @login()
        window.history.replaceState('', '', '/')
      else
        if authOk?
          @login()
      
    createProject:(options)=>
      project = @lib.create(options)
      project.createFile
        name: project.get("name")
      project.createFile
        name: "config"
        
    saveProject:(project)=>
      @lib.add(project)
      
      project.sync=@store.sync
      project.pathRoot=project.get("name") 
      
      #fakeCollection = new Backbone.Collection()
      #fakeCollection.sync = @store.sync
      #fakeCollection.path = project.get("name") 
      #fakeCollection.add(project)
      
      project.pfiles.sync = @store.sync
      project.pfiles.path = project.get("name") 
      for index, file of project.pfiles.models
        file.sync = @store.sync 
        file.pathRoot= project.get("name")
        file.save()
      
      #project.save()
      @vent.trigger("project:saved")
    
    loadProject:(projectName)=>
      console.log "github loading project #{projectName}"
      project =@lib.get(projectName)
      console.log "loaded:"
      console.log project
    
    getProjectsName:(callback)=>
      #hack
      @store.client.readdir "/", (error, entries) ->
        if error
          console.log ("error")
        else
          console.log entries
          callback(entries)
       
  return GitHubStore