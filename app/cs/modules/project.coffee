define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  #project is a top level element
  #a project contains files
  #a project can reference another project (includes?)
  
  
  class ProjectFile extends backbone.Model
    defaults:
      name:     "main"
      ext:      "coscad"
      content:  ""
      
    localStorage: new Backbone.LocalStorage("TestProjectFile")

    constructor:(options)->
      super options
  
  class Project extends Backbone.Collection
    model: ProjectFile
    localStorage: new Backbone.LocalStorage("Project")
  
    constructor:(options)->
      super options
      
    export:(format)->
    
  return [ProjectFile,Project]
  
  #class Projects extends Backbone.Collection
  
###
  initialize:(options)->
    @bind "change:name", ()=>
      name = @get "name"
      console.log "Changed my name to " + name
###
