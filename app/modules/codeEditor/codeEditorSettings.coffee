define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  
  class CodeEditorSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "Editor"
      title: "Code editor"
      startLine    :  1
      theme        : "default"
      
    constructor:(options)->
      super options
      
  return CodeEditorSettings