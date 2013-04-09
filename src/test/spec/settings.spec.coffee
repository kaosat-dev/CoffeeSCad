define (require)->
  Settings= require "core/settings/settings"

  describe "Settings", ->
    settings = null
    beforeEach ->
      settings = new Settings() 
      
    it 'can return a specific sub setting by name' , ->
      console.log settings
      generalSettings = settings.getByName("General")
      expect(generalSettings.get("name")).toBe "General"
    
    it 'can register a setting class for modular use', ->
      class TestSettings extends Backbone.Model
        idAttribute: 'name'
        defaults:
          name: "TestSubApp"
          title: "Test Sub App"
          dummySetting: 42
      
      settings.registerSettingClass("TestSubApp", TestSettings)
      expect(settings.settingNames["TestSubApp"]).toBe(TestSettings)
      expect(settings.getByName("TestSubApp").get("dummySetting")).toBe(42)
