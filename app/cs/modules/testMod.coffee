###
#first approach
define ["jquery", "underscore", "marionette", "MyApp"], ($, _, Marionette, MyApp) ->
  
  MyModule = MyApp.module("MyModule")
  MyModule.addInitializer ->
    console.log "oi"
  
  MyApp = require('MyApp')
  
  
  
  MyApp.addInitializer (options)->
    console.log "yaargh"
###

###
#second approach
define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  app = require('app')
  
  app.addInitializer (options)->
    console.log "yaargh"
  
  app.vent.on "fileSaveRequest", ->
    console.log "pouer"
###

#third approach
define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  app = require('app')
  
  app.addInitializer (options)->
    console.log "yaargh"
  MyModule = app.module("MyModule")

  MyModule.addInitializer ()->
    console.log("in MyModule init")
