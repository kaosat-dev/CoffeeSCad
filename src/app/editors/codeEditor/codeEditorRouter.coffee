define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'#request response system , see backbone marionnette docs
  
  
  class CodeEditorRouter extends Backbone.Marionette.AppRouter
    #appRoutes: 
    #    "dummy:list"  : 'listDummies'
       
    constructor:(options)->
      super options
      @setController(options.controller)
      
    setController:(controller)=>
      @controller = controller
      for route, methodName of @appRoutes
        vent.bind(route, @controller[methodName])
            
  return CodeEditorRouter
