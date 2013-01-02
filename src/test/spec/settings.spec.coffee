define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Settings= require "/CoffeeSCad/app/modules/core/settings/settings"

  describe "settings", ->
    settings = null
    beforeEach ->
      settings = new Settings() 
      
    it 'can return a specific setting by name' , ->
      generalSettings= settings.byName("General")
      
      expect(generalSettings.name).toBe "General"
  