define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  backbone = require 'backbone'
  #project is a top level element
  #a project contains files
  #a project can reference another project (includes?)
  
  class ProjectFile extends backbone.Model
    defaults:
      name:     "main"
      ext:      "coscad"
      content:  ""

    constructor:(options)->
      super options
  
  class Project extends Backbone.Collection
    model: ProjectFile
  
    initialize: (options) =>
  
    export:(format)->
    
  return [ProjectFile,Project]
  
  
###
  initialize:(options)->
    @bind "change:name", ()=>
      name = @get "name"
      console.log "Changed my name to " + name
###
