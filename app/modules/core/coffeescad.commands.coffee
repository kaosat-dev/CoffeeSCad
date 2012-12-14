define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'

  """Exploring backbone marionettes' commands"
  class Coffeescad.Commands extends Backbone.Wreqr.Commands
  
  
  commands = new Coffeescad.Commands()
  commands.addHandler("foo", ()->
    console.log("the foo command was executed")
    
  return commands
