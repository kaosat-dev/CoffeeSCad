define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  class Library extends Backbone.Collection
    """
    a library contains multiple projects
    """  
    model: Project
    localStorage: new Backbone.LocalStorage("Library")
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      @bind("reset", @onReset)
    
    comparator: (project)->
      date = new Date(project.get('lastModificationDate'))
      return date.getTime()
    
    save:()=>
      @each (model)-> 
        model.save()
    
    fetch:(options)=>
      if options?
        if options.id?
          id = options.id
          console.log "id specified"
          proj=null
          if @get(id)
            proj = @get(id)
            proj.new = false
            proj.pfiles.fetch()
          #else
          #  proj = new Project({name:id})
          #  proj.collection = @
          #  proj.fetch()
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
      
      
    onReset:()->
      #if @models.length == 0
      #  @save()
      if debug
        console.log "Library reset" 
        console.log @
        console.log "_____________"
        
  return Library