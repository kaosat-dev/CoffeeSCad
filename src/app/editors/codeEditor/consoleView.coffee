define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'core/messaging/appVent'
  
  consoleTemplate =  require "text!./console.tmpl"
  
  
  class ConsoleView extends Backbone.Marionette.ItemView
    template: consoleTemplate
    className: "console"
    
    constructor:(options)->
      super options
      @vent = vent
      @_setupEventHandlers()
    
    _setupEventHandlers: =>
      @model.on("compiled",@onErrors)
      @model.on("compile:error", @onErrors)
      @vent.on("file:errors",   @onLintErrors)
      #@vent.on("file:noError", @clearConsole)
      @vent.on("file:selected", @onFileSelected)
      @model.on("log:messages",@onLogEntries)
    
    _tearDownEventHandlers:=>
      @model.off("compiled",@onErrors)
      @model.off("compile:error", @onErrors)
      @vent.off("file:errors",   @onLintErrors)
      #@vent.off("file:noError", @clearConsole)
      @vent.off("file:selected", @onFileSelected)
      @model.off("log:messages",@onLogEntries)
      
    serializeData: ()->
      null
      
    clearConsole:()=>
      @$el.addClass("well")
      @$el.removeClass("alert alert-error")
      @$el.html("")
      
    onRender:=>
      @clearConsole()

    onErrors:(compileResultData)=>
      #TODO: cleanup
      try
        @$el.removeClass("well")
        @$el.html("")
        for error in compileResultData.errors
          errLine = if error.lineNumber? then error.lineNumber else if error.location? then error.location.first_line
          errMsg = error.message
          errStack= error.stack
          @$el.append("<div class='alert alert-error'><b>File: line #{errLine}:</b>  #{errMsg}<br/>===============================================<br/><br/></div>")
        for entry in compileResultData.logEntries
          level = entry.lvl
          msg = entry.msg
          #line = entry.line
          cssClass = ""
          switch level.toLowerCase()
            when "warn"
              cssClass= "alert alert-warning"
            when "info"
              cssClass= "alert alert-info"
            when "error"
              cssClass= "alert alert-error"
            when "debug"
              cssClass = "alert alert-success"
          msgDiv = "<div class='#{cssClass} console-entry'><b>#{level}:</b>#{msg}</div>"
          @$el.append(msgDiv)
        
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
     
    onLintErrors:(errors)=>
      try
        #@$el.removeClass("well")
        #@$el.html("")
        for error in errors
          errLine = error.message.split("line ")
          errLine = errLine[errLine.length - 1]
          errLine = error.lineNumber
          errMsg = error.message
          errStack= error.stack
          @$el.append("<div class='alert alert-error'><b>File: line #{errLine}:</b>  #{errMsg}<br/>#{errStack}<br/>===============================================<br/><br/></div>")
        
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
       
     #onFileSelected:(model)=>
     #  @clearConsole()
     onClose:=>
       @_tearDownEventHandlers()
        
  return ConsoleView