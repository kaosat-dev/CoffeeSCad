define (require)->
  marionette = require 'marionette'
  vent = require 'core/messaging/appVent'
  Command = require './command'
  
  
  class NewProjectCommand extends Command
  
    execute:(params)->
      params = params or null
      console.log "command : create project"
      vent.trigger("project:new",params)
    
  return NewProjectCommand