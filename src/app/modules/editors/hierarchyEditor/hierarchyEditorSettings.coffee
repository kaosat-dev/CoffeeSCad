define (require)->
  Backbone = require 'backbone'


  class HierarchyEditorSettings extends Backbone.Model
      idAttribute: 'name'
      defaults:
        name: "HierarchyEditor"
        title: "Hierarchy Editor"
        
      constructor:(options)->
        super options
        
  return HierarchyEditorSettings