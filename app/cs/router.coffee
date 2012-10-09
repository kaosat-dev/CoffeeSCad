define (require) ->
  app = require 'app'
  
  class Router extends Backbone.Router
    routes:
      "": "index"
    index: ->
    
         
  return Router 
