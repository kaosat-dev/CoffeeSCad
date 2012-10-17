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
    three:            "../assets/js/libs/three.min"
    detector:         "../assets/js/libs/detector"
    utils:            "../assets/js/libs/utils"
    
    #plugins
    jquery_hotkeys:   "../assets/js/plugins/jquery.hotkeys"
    jquery_codemirror:"../assets/js/plugins/jquery.codemirror"
    foldcode:         "../assets/js/plugins/foldcode"
    coffee_synhigh:   "../assets/js/libs/codeMirror/mode/coffeescript/coffeescript"
    
    marionette:       "../assets/js/plugins/backbone.marionette.min"
    eventbinder:      "../assets/js/plugins/backbone.eventbinder.min"
    wreqr:            "../assets/js/plugins/backbone.wreqr.min"
    localstorage:     "../assets/js/plugins/backbone.localstorage.min"
    
    three_csg:        "../assets/js/plugins/ThreeCSG"
    

  shim:
    underscore:
      deps: []
      exports: '_'
    bootstrap:
      deps:    ["jquery"]
      exports:  "bootstrap"
    'backbone':
      deps:    ["underscore"]
      exports:  "Backbone"
    marionette:
      deps:    ["jquery", "backbone","eventbinder","wreqr"]
      exports:  "marionette"
    localstorage:
      deps:    ["backbone","underscore"]
      exports:  "localstorage"
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
    three: 
      exports : "THREE"
    three_csg: 
      deps:    ["three"]
      exports : "THREE.CSG"
    detector: 
      exports : "Detector"
    utils: 
      deps:    ["jquery"]
      exports : "normalizeEvent"
      
###
require ["CoffeeScript"], (CoffeeScript)->
    tutu = CoffeeScript.compile("class Pouet", {bare: true})
    console.log("tutu:\n"+tutu)
###

  


