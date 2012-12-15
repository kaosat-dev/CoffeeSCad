define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  appController = require 'modules/projects/projectController'
  
  class AppRouter extends Backbone.Marionette.AppRouter
    controller: projectController
    routes: 
        '*defaults'     : 'home'
  
    return AppRouter