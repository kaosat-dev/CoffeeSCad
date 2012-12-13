define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  
  class ProjectCodeEditorView extends marionette.CompositeView
      
  return ProjectCodeEditorView