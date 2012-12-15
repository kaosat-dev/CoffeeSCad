define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  projectController = require 'modules/projects/projectController'
  
  class ProjectRouter extends Backbone.Marionette.AppRouter
    controller: projectController
    routes: 
        "project:new"   : 'newProject'
        "project:save"  : 'saveProject'
        "project:load"  : 'loadProject'
        "project:delete": 'deleteProject'
        '*defaults'     : 'home'
  
    return ProjectRouter
