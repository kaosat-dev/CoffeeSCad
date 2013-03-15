require.config
  baseUrl: "/app",
  deps: ["../test/runner"]
  
  paths:
    #required for specs
    spec: '../test/spec'
    
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
    lightgl:          "../assets/js/libs/lightgl"
    three:            "../assets/js/libs/three.min"
    detector:         "../assets/js/libs/detector"
    stats:            "../assets/js/libs/Stats"
    utils:            "../assets/js/libs/utils"
    
    jasmine:          "../test/vendor/jasmine"
    'jasmine-html':     "../test/vendor/jasmine-html"
    
    XMLWriter:        "../assets/js/libs/XMLWriter-1.0.0"

    #plugins
    jquery_hotkeys:   "../assets/js/plugins/jquery.hotkeys"
    jquery_ui:        "../assets/js/plugins/jquery-ui-1.10.0.custom"
    jquery_layout:    "../assets/js/plugins/jquery.layout-latest"
    jquery_jstree:    "../assets/js/plugins/jquery.jstree"
    jquery_sscroll:   "../assets/js/plugins/jquery.slimscroll"
    
    bootbox:          "../assets/js/plugins/bootbox.min"
    contextMenu:      "../assets/js/plugins/bootstrap-contextmenu"
    notify:           "../assets/js/plugins/bootstrap-notify"
    
    marionette:       "../assets/js/plugins/backbone.marionette.min"
    eventbinder:      "../assets/js/plugins/backbone.eventbinder.min"
    wreqr:            "../assets/js/plugins/backbone.wreqr.min"
    babysitter:       "../assets/js/plugins/backbone.babysitter.min"
    pickysitter:      "../assets/js/plugins/backbone.pickysitter"
    
    localstorage:     "../assets/js/plugins/backbone.localstorage"
    modelbinder :     "../assets/js/plugins/backbone.ModelBinder.min"
    collectionbinder :"../assets/js/plugins/backbone.CollectionBinder.min"
    
    "backbone-forms" :           "../assets/js/plugins/backbone.forms"
    forms_bootstrap : "../assets/js/plugins/backbone.forms.bootstrap"
    forms_list      : "../assets/js/plugins/backbone.forms.list.min"  
    backbone_nested:  "../assets/js/plugins/backbone.nested.min"
    
    coffeelint:       "../assets/js/plugins/coffeelint"
    
  shim:
    jasmine:
      exports: 'jasmine'
    'jasmine-html':
      deps: ['jasmine']
      exports: 'jasmine'
    underscore:
      deps: []
      exports: '_'
    bootstrap:
      deps:    ["jquery"]
      exports:  "bootstrap"
    bootbox:
      dep: ["bootstrap"]
    'backbone':
      deps:    ["underscore"]
      exports:  "Backbone"
    marionette:
      deps:    ["jquery", "backbone","eventbinder","wreqr"]
      exports:  "marionette"
    localstorage:
      deps:    ["backbone","underscore"]
      exports:  "localstorage"
    backbone_nested:
      deps:["backbone"]
      
    CoffeeScript:
      exports:  "CoffeeScript"
    coffeelint:
      deps:    ["CoffeeScript"]
      exports:  "coffeelint"
    
    XMLWriter:
       exports: "XMLWriter"
