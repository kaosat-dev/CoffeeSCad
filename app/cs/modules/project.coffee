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
    #localStorage: new Backbone.LocalStorage("Projects")
    defaults:
      name:     "TestProject"
      content : "bla"
      
   # toJSON: ->
   #   json = {Project : @attributes}
   #   return _.extend(json, {pfiles: @pfiles.toJSON()})
    
    constructor:(options)->
      super options
      @pfiles = new ProjectFiles()
    
    remove:(model)=>
      @pfiles.remove(model)
      
    add:(model)=>
      @pfiles.add(model)  
      
    export:(format)->
      
  class Library extends Backbone.Collection   
    model: Project
    localStorage: new Backbone.LocalStorage("Library")
    
    
  return [ProjectFile,Project,Library]
  
  
  
###
  initialize:(options)->
    @bind "change:name", ()=>
      name = @get "name"
      console.log "Changed my name to " + name
###

#{"Project":{"name":"MyProject","id":"faf67514-f4bd-7b98-0703-db51d8d277a9"},"ProjectFiles":[{"name":"main","ext":"coscad","content":"\nclass CubeClass\n width:20\n length:20\n height:20\n constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->\n return @render()\n \n render: =>\n result = new CSG()\n cube1 =CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]})\n result = cube1\n return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2]) \n\ncubeStuff = new CubeClass()\nreturn cubeStuff"}]}
