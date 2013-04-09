define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  
  class VisualEditorRouter extends Backbone.Marionette.AppRouter
    #appRoutes: 
       
    constructor:(options)->
      super options
      @setController(options.controller)
      
    setController:(controller)=>
      @controller = controller
      for route, methodName of @appRoutes
        vent.bind(route, @controller[methodName])
            
  return VisualEditorRouter
