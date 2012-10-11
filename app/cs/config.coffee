require.config
  deps: ["main"]
  paths:
    #JavaScript folders.
    libs:             "../assets/js/libs"
    plugins:          "../assets/js/plugins"
    vendor:           "../assets/vendor"
    #Libraries.
    jquery:           "../assets/js/libs/jquery-1.8.1.min"
    underscore:       "../assets/js/libs/underscore-min"
    backbone:         "../assets/js/libs/backbone-min"
    bootstrap:        "../assets/js/libs/bootstrap.min"
    CoffeeScript:     "../assets/js/libs/CoffeeScript"
    CodeMirror:       "../assets/js/libs/codemirror"
    csg:              "../assets/js/libs/csg"
    lightgl:          "../assets/js/libs/lightgl"
    marionette:       "../assets/js/libs/backbone.marionette.min"
    eventbinder:      "../assets/js/libs/backbone.eventbinder.min"
    wreqr:            "../assets/js/libs/backbone.wreqr.min"
    #plugins
    jquery_hotkeys:   "../assets/js/plugins/jquery.hotkeys"
    jquery_codemirror:"../assets/js/plugins/jquery.codemirror"
    foldcode:         "../assets/js/plugins/foldcode"
    coffee_synhigh:   "../assets/js/libs/codeMirror/mode/coffeescript/coffeescript"
    


  shim:
    underscore:
      deps: []
      exports: '_'
    backbone:
      deps:    ["underscore"]
      exports:  "Backbone"
    bootstrap:
      deps:    ["jquery"]
      exports:  "bootstrap"
    marionette:
      deps:    ["jquery", "backbone","eventbinder","wreqr"]
      exports:  "marionette"
    CoffeeScript:
      exports:  "CoffeeScript"
    CodeMirror:
      exports:  "CodeMirror"
    foldcode:
      deps:    ["CodeMirror"]
    coffee_synhigh:
      deps:    ["CodeMirror"]
    jquery_codemirror:
      deps:    ["CodeMirror","jquery"]
###
require ["CoffeeScript"], (CoffeeScript)->
    tutu = CoffeeScript.compile("class Pouet", {bare: true})
    console.log("tutu:\n"+tutu)
###

  


