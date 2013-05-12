define (require)->
  Backbone = require 'backbone'


  class ExampleEditorSettings extends Backbone.Model
      idAttribute: 'name'
      defaults:
        name: "ExampleEditor"
        title: "Example Editor"
        
      constructor:(options)->
        super options
        
  return ExampleEditorSettings