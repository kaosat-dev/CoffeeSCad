define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  
  class GeneralSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "General"
      title: "General"
      maxRecentFilesDisplay:  5
      theme: "slate"
      
    constructor:(options)->
      super options

  return Settings