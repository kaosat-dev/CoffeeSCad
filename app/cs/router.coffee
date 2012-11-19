define (require) ->
  app = require 'app'
  
  class Controller
    constructor:()->
      #tMod = require "modules/testMod"
      
  class Router extends Backbone.Router
    routes:
      "": "index"
    controller: Controller
    index: ->
    
         
  return Router 
