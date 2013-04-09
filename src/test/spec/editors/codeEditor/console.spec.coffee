define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  
  vent = require 'core/messaging/appVent'
  ConsoleView = require 'editors/codeEditor/consoleView'
  
  describe "console", ->
    consoleView = null
    
    beforeEach ->
      consoleView = new ConsoleView()
  
    it 'changes style depending on error' , -> 
      vent.trigger("error",null)
      consoleClass = consoleView.$el.attr('class')
      expect(consoleClass).toBe "alert alert-error"
      
    it 'clears when there are no errors', ->
      vent.trigger("noError")
      consoleClass = consoleView.$el.attr('class')
      expect(consoleClass).toBe "well"

  