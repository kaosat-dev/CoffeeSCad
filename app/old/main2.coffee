require.config
  #baseUrl: 'assets/js'
  paths:
    jquery:       "assets/libs/jquery-1.8.1.min"
    underscore:   "assets/libs/underscore-min"
    backbone:     "assets/libs/backbone-min"
    bootstrap:    "assets/libs/bootstrap.min"
    CoffeeScript: "assets/libs/CoffeeScript"
    CodeMirror:   "assets/libs/codemirror"
    foldcode:     "assets/plugins/foldcode"
    
  shim:
    underscore:
      deps: []
      exports: '_'
    backbone:
      deps:    ["underscore"]
      exports:  "Backbone"
    CoffeeScript:
      exports:  "CoffeeScript"
  


#code editor
#define [], () ->
# return CoffeeScript


require ["CoffeeScript"], (CoffeeScript)->
    tutu = CoffeeScript.compile("class Pouet", {bare: true})
    console.log("tutu:\n"+tutu)

define (require)->
  $        = require 'jquery'
  Backbone = require 'backbone'
  Router   = require 'router'

  #router = new Router pushState: false

  Backbone.history.start()
  Backbone.history.on 'route', ->


### 
require(["jquery", "underscore"], ($, underscore)->
    $("#codeArea").val("lm")
    showName = (n) ->
      temp = _.template("Hello <%= name %>")
      $("body").html(temp({name: n})) 
    showName("sdf")  
 )
###

  


