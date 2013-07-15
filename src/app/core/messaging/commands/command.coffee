define (require)->
  marionette = require 'marionette'
  vent = require 'core/messaging/appVent'
  
  class Command
    constructor:->
    
    execute:(params)->
      params = params or null
      vent.trigger("dummyCommand",params)
  
  return Command
  