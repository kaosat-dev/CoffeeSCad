define (require) ->
  app = require 'app'
  
  project = {}
  #project is a top level element
  #a project contains files
  #a project can reference another project (includes?)
  
  class ProjectFile extends Backbone.Model
    defaults:
      name:     "main"
      ext:      "coscad"
      content:  ""
      blo: []
      
    constructor:(options)->
      console.log "in constructor"
      super options
      @blo = @get("blo")
      @name = @get("name")
    
    initialize:(options)->
      this.bind "change:name", ()=>
        name = @get("name")
        console.log("Changed my name to " + name)

      
    bla:(truc)->
      console.log(@get("blo"))
      @get("blo").push(truc)
    bli:(truc)->
      console.log(@blo)
      @blo.push(truc)
  
  class Project extends Backbone.Collection
    model: ProjectFile
    
    constructor: (options) ->
      @all_files_saved=false
      super options
    
    export:(format)->
      
   
    project.ProjectFile = ProjectFile
    project.Project = Project
    
    
      
  return project
    

    
  
    
