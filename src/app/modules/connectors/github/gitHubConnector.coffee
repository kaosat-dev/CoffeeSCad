define (require)->
  backbone_github = require './backbone.github'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
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
  
  class GitHubConnector extends Backbone.Model
    defaults:
      name: "gitHubConnector"
      storeType: "gitHub"
    
    constructor:(options)->
      super options
      @store = new backbone_github()
      @isLogginRequired = true
      @loggedIn = true
      @vent = vent
      @vent.on("gitHubConnector:login", @login)
      @vent.on("gitHubConnector:logout", @logout)
      
      #experimental
      @lib = new GitHubLibrary
        sync: @store.sync
      @lib.sync = @store.sync
      
    login:=>
      try
        onLoginSucceeded=()=>
          console.log "github logged in"
          localStorage.setItem("githubCon-auth",true)
          @loggedIn = true
          @vent.trigger("gitHubConnector:loggedIn")
        onLoginFailed=(error)=>
          console.log "github loggin failed"
          throw error
          
        loginPromise = @store.authentificate()
        $.when(loginPromise).done(onLoginSucceeded)
                            .fail(onLoginFailed)
        
        #@lib.fetch()
      catch error
        @vent.trigger("gitHubConnector:loginFailed")
        
    logout:=>
      try
        @store.signOut()
        @loggedIn = false
        localStorage.removeItem("githubCon-auth")
        @vent.trigger("gitHubConnector:loggedOut")
      catch error
        @vent.trigger("gitHubConnector:logoutFailed")
    
    authCheck:()->
      #/?_githubjs
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
      urlAuthOk = getURLParameter("_githubjs_scope")
      console.log "githubConnector got redirect param #{urlAuthOk}"
      
      authOk = localStorage.getItem("githubCon-auth")
      console.log "githubConnector got localstorage Param #{authOk}"

      ###
      if urlAuthOk?
        if (!window.location.origin)
          window.location.origin = window.location.protocol+"//"+window.location.host
        bla=()->
          window.history.replaceState('', '', '/')
        setTimeout bla, 2
      ###
      
      if urlAuthOk?
        @login()
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
       
  return GitHubConnector