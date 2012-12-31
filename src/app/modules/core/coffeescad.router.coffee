define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  class AppRouter extends Backbone.Marionette.AppRouter
    controller: projectController
    routes: 
        '*defaults'     : 'home'
  
  return AppRouter