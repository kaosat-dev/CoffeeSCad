define (require)->
  require 'Mousetrap_global'
  vent = require 'core/messaging/appVent'

  class KeyBindingsManager
    constructor:(options)->
      @appSettings = options.appSettings or null
      @settings = @appSettings.getByName("KeyBindings")
      @vent = vent
      
      console.log "bliblu", @appSettings
      
      #these are commands
      @commands = {
        "project:save": ()=>@vent.trigger("project:save")
        "project:load": ()=>@vent.trigger("project:load")
        "project:new": ()=>@vent.trigger("project:new")
        "project:compile": ()=>@vent.trigger("project:compile")
      }
      #and keybindings
      @keybindings = {
        "project:new":'alt+n'
        "project:load":'mod+l'
        "project:save":'mod+s'
        "project:compile":'f4'
        "project:compile":'alt+c'
      }
      @appSettings.on("reset", @_onAppSettingsChanged)
    
    _onAppSettingsChanged:(model, attributes)=>
      @settings = @appSettings.getByName("KeyBindings")
      @settings.on("change", @_onSettingsChanged)
      
    _onSettingsChanged:(settings, value)=> 
      keybindings = @settings.get("bindings")
      console.log "settings, keybindings", keybindings
      
            
    setup:=>
      for command of @keybindings
        keys = @keybindings[command]
        commandToCall = @commands[command]
        do(keys, commandToCall)=>
          Mousetrap.bindGlobal keys, (e)=>
            if e.preventDefault
              e.preventDefault()
            else
              # internet explorer
              e.returnValue = false
            commandToCall()
      
      
    bindCommand:(command,keys)=>
      #implementation of unbind/rebind
      #command = "project:save"
      if command == null
        return
        
      Mousetrap.unbind(keybindings[command])
      @keybindings[command]= keys
      
      commandToCall = @commands[command]
      Mousetrap.bindGlobal keys, (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        commandToCall()
      
      ###
      Mousetrap.bindGlobal 'alt+n', (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        
        NewProjectCommand = require 'core/messaging/commands/newProjectCommand'
        newProjectCommand = new NewProjectCommand()
        newProjectCommand.execute()
      
      
      Mousetrap.bindGlobal 'mod+s', (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        console.log "saving yeah"
        @vent.trigger("project:save")
        
      Mousetrap.bindGlobal 'ctrl+l', (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        LoadProjectCommand = require 'core/messaging/commands/loadProjectCommand'
        loadProjectCommand = new LoadProjectCommand()
        loadProjectCommand.execute()
        
      Mousetrap.bindGlobal 'alt+c', (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        console.log "compiling yeah"
        @vent.trigger("project:compile")
        
      Mousetrap.bindGlobal 'f4', (e)=>
        if e.preventDefault
          e.preventDefault()
        else
          # internet explorer
          e.returnValue = false
        console.log "compiling yeah"
        @vent.trigger("project:compile")
      ###
  return KeyBindingsManager