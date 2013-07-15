define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  buildProperties = require 'core/utils/buildProperties'
  
  
  class Settings extends Backbone.Collection
    localStorage: new Backbone.LocalStorage("Settings")
    
    constructor:(options)->
      super options
      @settingNames = new Object()
      @bind("reset", @onReset)
      
      @registerSettingClass("General", GeneralSettings)
      @registerSettingClass("KeyBindings", KeyBindings) 
      
    save:()=>
      @each (model)-> 
        model.save()
    
    registerSettingClass:(settingName, settingClass)->
      #register a new setting class by name (a setting object containing params for a specific sub app)
      @settingNames[settingName] = settingClass
      #TODO: some cleaner alternative to this ?
      @add new settingClass()
      @            
    
    parse: (response)=>
      for i, v of response
        try
          response[i] = new  @settingNames[v.name](v)
        catch error
          console.log "failed to parse setting: #{error}"
      return response
      
    clear:()=>
      @each (model)-> 
        model.destroy()
      
    onReset:()=>
      if @models.length == 0
        for index, settingClass of @settingNames
          subSetting = new settingClass()
          @add subSetting
      ###
      console.log "collection reset" 
      console.log @
      console.log "_____________"
      ###
      
    getByName:(name)=>
      """Return a specific sub setting by name"""
      result = @filter (setting)->
        return setting.get('name')==name
      return result[0]
      
  class GeneralSettings extends Backbone.Model
    attributeNames: ['name', 'csgCompileMode','csgCompileDelay','csgBackgroundProcessing',
    'displayEventNotifications','autoReloadLastProject','autoSave','autoSaveFrequency']
    buildProperties @
    
    idAttribute: 'name'
    defaults:
      name: "General"
      title: "General"
      
      csgCompileMode: "onCodeChange" 
      csgCompileDelay: 1.0
      csgBackgroundProcessing: false
      
      autoReloadLastProject : false
      autoSave: false
      autoSaveFrequency: 30
      
      language: "english"
      theme: "default"
      displayEventNotifications: true
      
      
    constructor:(options)->
      super options
  
  class KeyBindings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "KeyBindings"
      title: "Key Bindings"
      bindings: {
        "project:new":'alt+n'
        "project:load":'mod+l'
        "project:save":'mod+s'
        "project:compile":'f4'
        "project:compile":'alt+c'
      }
      
    constructor:(options)->
      super options
  

  return Settings