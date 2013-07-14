define (require)->
  vent = require 'core/messaging/appVent'
  Command = require './command'
  
  
  class LoadProjectCommand extends Command
  
    execute:(params)->
      params = params or null
      console.log "command : load project"
      vent.trigger("project:load",params)
    
  return LoadProjectCommand