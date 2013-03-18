define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  
  consoleTemplate =  require "text!./console.tmpl"
  
  
  class ConsoleView extends Backbone.Marionette.ItemView
    template: consoleTemplate
    className: "console"
    
    constructor:(options)->
      super options
      @vent = vent
      @model.on("compiled",@onErrors)
      @model.on("compile:error", @onErrors)
      @vent.on("file:errors",   @onLintErrors)
      @vent.on("file:noError", @clearConsole)
      @vent.on("file:selected", @onFileSelected)
      @model.on("log:messages",@onLogEntries)
      
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
        @$el.addClass("alert alert-error")
        for error in compileResultData.errors
          errLine = error.lineNumber
          errMsg = error.message
          errStack= error.stack
          @$el.append("<div><b>File: line #{errLine}:</b>  #{errMsg}<br/>#{errStack}<br/>===============================================<br/><br/></div>")
        for entry in compileResultData.logEntries
          level = entry.lvl
          msg = entry.msg
          @$el.append("<div><b>#{level}:</b> #{msg}</div>")
        
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
     
    onLintErrors:(errors)=>
      try
        @$el.removeClass("well")
        @$el.html("")
        @$el.addClass("alert alert-error")
        for error in errors
          errLine = error.message.split("line ")
          errLine = errLine[errLine.length - 1]
          errLine = error.lineNumber
          errMsg = error.message
          errStack= error.stack
          @$el.append("<div><b>File: line #{errLine}:</b>  #{errMsg}<br/>#{errStack}<br/>===============================================<br/><br/></div>")
        
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
       
     onFileSelected:(model)=>
       @clearConsole()
        
  return ConsoleView