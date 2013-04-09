define (require) ->
  app = require 'app'
  
  class Controller
    constructor:()->
      #tMod = require "testMod"
      
  class Router extends Backbone.Router
    routes:
      "": "index"
    controller: Controller
    index: ->
    
         
  return Router 
