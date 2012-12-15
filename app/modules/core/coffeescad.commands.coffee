define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'

  """Exploring backbone marionettes' commands"""
  class Commands extends Backbone.Wreqr.Commands
    constructor:(options)->
      super options
  commands = new Commands()
  commands.addHandler "foo", ()->
    console.log("the foo command was executed")
   
  return commands
