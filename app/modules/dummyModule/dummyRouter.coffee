define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  #dummyController = require './dummyController'
  vent = require '../coffeescad.vent'
  
  class DummyRouter extends Backbone.Marionette.AppRouter
    #controller: dummyController
    appRoutes: 
        "dummy:list"  : 'listDummies'
        "dummy:new"   : 'newDummy'
        "dummy:delete": 'deleteDummy'
        
    constructor:(options)->
      super options
      @setController(options.controller)
      
    setController:(controller)=>
      @controller = controller
      for route, methodName of @appRoutes
        #console.log "Route: #{route} #{methodName}"
        vent.bind(route, @controller[methodName])
            
  return DummyRouter
