define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  
  projectBrowserTemplate = require "text!./projectBrowser.tmpl"

  class ProjectBrowserView extends Backbone.Marionette.CompositeView
    #itemView: SingleFileView
    #tagName: "li"
    template:projectBrowserTemplate
    
    constructor:(options) ->
      super options

  return ProjectBrowserView