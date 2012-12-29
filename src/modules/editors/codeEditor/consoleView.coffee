define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  vent = require 'modules/core/vent'
  
  consoleTemplate =  require "text!./console.tmpl"
  
  class ConsoleView extends Backbone.Marionette.ItemView
    template: consoleTemplate
    
    constructor:(options)->
      super options
      @vent = vent
      @vent.on("error",   @onError)
      @vent.on("noError", @clearConsole)
      @vent.on("file:selected", @onFileSelected)
      
    serializeData: ()->
      null
      
    clearConsole:()=>
      @$el.addClass("well")
      @$el.removeClass("alert alert-error")
      @$el.html("")
      
    onRender:=>
      @clearConsole()

    onError:(error)=>
      try
        @$el.removeClass("well")
        @$el.addClass("alert alert-error")
        @$el.html("<div><h4>#{error.name}:</h4>  #{error.message}</div>")
        errLine = error.message.split("line ")
        errLine = errLine[errLine.length - 1]
        errMsg = error.message
      catch err
        console.log("Inner err: "+ err)
        @$el.text("Yikes! Error displaying error:#{err}")
        
     onFileSelected:(model)=>
       @clearConsole()
        
  return ConsoleView