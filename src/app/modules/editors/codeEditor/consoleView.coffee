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
      @vent.on("file:errors",   @onErrors)
      @vent.on("file:noError", @clearConsole)
      @vent.on("file:selected", @onFileSelected)
      
    serializeData: ()->
      null
      
    clearConsole:()=>
      @$el.addClass("well")
      @$el.removeClass("alert alert-error")
      @$el.html("")
      
    onRender:=>
      @clearConsole()

    onErrors:(errors)=>
      try
        @$el.removeClass("well")
        @$el.html("")
        @$el.addClass("alert alert-error")
        for error in errors
          errLine = error.message.split("line ")
          errLine = errLine[errLine.length - 1]
          errMsg = error.message
          @$el.append("<div><h6>#{errLine}:</h5>  #{errMsg}<br/>===============================================<br/><br/></div>")
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
        
     onFileSelected:(model)=>
       @clearConsole()
        
  return ConsoleView