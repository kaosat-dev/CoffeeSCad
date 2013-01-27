define (require)->
  Backbone = require 'backbone'
  vent = require 'modules/core/vent'
  
  Project = require 'modules/core/projects/project'
  
  
  class BrowserLibrary extends Backbone.Collection
    """
    a library contains multiple projects, stored in localstorage (browser)
    """  
    model: Project
    localStorage: new Backbone.LocalStorage("Projects")
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      #@bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
  
  class BrowserConnector extends Backbone.Model
    defaults:
      name: "browserConnector"
      storeType: "browser"
    
    constructor:(options)->
      super options
      @isLogginRequired = false
      @loggedIn = true
      @vent = vent
      @vent.on("browserConnector:login", @login)
      @vent.on("browserConnector:logout", @logout)
      
    login:=>
      @loggedIn = true
        
    logout:=>
      @loggedIn = false
    
     getProjectsName:(callback)=>
       tutu=()=>
         callback(["project1","project2"])
       
       setTimeout tutu, 10
       

       
  return BrowserConnector