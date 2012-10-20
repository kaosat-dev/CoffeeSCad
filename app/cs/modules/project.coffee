define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  #project is a top level element
  #a project contains files
  #a project can reference another project (includes?)
  #a library contains multiple projects
  
  
  class ProjectFile extends Backbone.Model
    defaults:
      name:     "main"
      ext:      "coscad"
      content:  ""
      
    constructor:(options)->
      super options
      @rendered=false
      
    #validate: (attributes)->
    #  console.log "validating"
  
  class ProjectFiles extends Backbone.Collection
    model: ProjectFile
  
  class Project extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "TestProject"
      pfiles:   null
    
    constructor:(options)->
      super options
      @bind("reset", @onReset)
      
      if @get("pfiles")?
        @pfiles = @get("pfiles")
      else
        @pfiles = new ProjectFiles()
        @set("pfiles", @pfiles)
        
        
    onReset:()->
      console.log "Project model reset" 
      console.log @
      console.log "_____________"
    
    remove:(model)=>
      @pfiles.remove(model)
      
    add:(model)=>
      @pfiles.add(model)  
      
    export:(format)->

      
  class Library extends Backbone.Collection   
    model: Project
    localStorage: new Backbone.LocalStorage("Library")
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      @bind("reset", @onReset)
      
      @namesFetch = false
    
    save:()=>
      @each (model)-> 
        model.save()
    
    fetch:(options)=>
      if options?
        #console.log ("options"+ options)
        if options.id?
          id = options.id
          #console.log "id specified"
          if @get(id)
            proj = @get(id)
          else
            proj = new Project({name:id})
            proj.collection = @
            proj.fetch()
          return proj
        else
          #console.log "NO id specified"
          res= Library.__super__.fetch.apply(this, options)
          return res
      else
          #console.log "NO id specified2"
          res = super(options)
          return res
        
    parse: (response)=>
      #console.log("in lib parse")
      for i, v of response
        response[i].pfiles = new ProjectFiles(response[i].pfiles)
      return response
      
    getLatest:()->
      @namesFetch = true
      
    onReset:()->
      console.log "Library collection reset" 
      console.log @
      console.log "_____________"
    
  return {ProjectFile,Project,Library}
