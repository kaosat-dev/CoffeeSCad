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
    backbone:         "../assets/js/libs/backbone"
    bootstrap:        "../assets/js/libs/bootstrap.min"
    CoffeeScript:     "../assets/js/libs/CoffeeScript"
    CodeMirror:       "../assets/js/libs/codemirror"
    csg:              "../assets/js/libs/csg"
    lightgl:          "../assets/js/libs/lightgl"
    three:            "../assets/js/libs/three.min"
    detector:         "../assets/js/libs/detector"
    stats:            "../assets/js/libs/Stats"
    utils:            "../assets/js/libs/utils"
    
    #plugins
    jquery_hotkeys:   "../assets/js/plugins/jquery.hotkeys"
    jquery_ui:        "../assets/js/plugins/jquery-ui-1.9.0.custom.min"
    jquery_layout:    "../assets/js/plugins/jquery.layout-latest"
    
    foldcode:         "../assets/js/plugins/foldcode"
    jsHint:           "../assets/js/plugins/javascript-hint"
    coffee_synhigh:   "../assets/js/libs/codeMirror/mode/coffeescript/coffeescript"
    
    marionette:       "../assets/js/plugins/backbone.marionette.min"
    eventbinder:      "../assets/js/plugins/backbone.eventbinder.min"
    wreqr:            "../assets/js/plugins/backbone.wreqr.min"
    localstorage:     "../assets/js/plugins/backbone.localstorage"
    modelbinder :     "../assets/js/plugins/backbone.ModelBinder.min"
    collectionbinder :"../assets/js/plugins/backbone.CollectionBinder.min"
    forms :           "../assets/js/plugins/backbone.forms"
    forms_bootstrap : "../assets/js/plugins/backbone.forms.bootstrap"
    
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
    forms:  
      deps:    ["backbone","underscore"]
      exports:  "forms"
    CoffeeScript:
      exports:  "CoffeeScript"
    CodeMirror:
      exports:  "CodeMirror"
    foldcode:
      deps:    ["CodeMirror"]
    coffee_synhigh:
      deps:    ["CodeMirror"]
    jsHint:
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
    stats:
      exports : "Stats"
    utils: 
      deps:    ["jquery"]
      exports : "normalizeEvent"
    jquery_ui:
      deps:    ["jquery"]
      exports : "jquery_ui"   
    jquery_layout:
      deps:    ["jquery"]
      exports : "jquery_layout"
    
    
    
      
###
require ["CoffeeScript"], (CoffeeScript)->
    tutu = CoffeeScript.compile("class Pouet", {bare: true})
    console.log("tutu:\n"+tutu)
###

  


