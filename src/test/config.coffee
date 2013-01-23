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

    #plugins
    marionette:       "../assets/js/plugins/backbone.marionette.min"
    eventbinder:      "../assets/js/plugins/backbone.eventbinder.min"
    wreqr:            "../assets/js/plugins/backbone.wreqr.min"
    localstorage:     "../assets/js/plugins/backbone.localstorage"
    modelbinder :     "../assets/js/plugins/backbone.ModelBinder.min"
    collectionbinder :"../assets/js/plugins/backbone.CollectionBinder.min"
    forms :           "../assets/js/plugins/backbone.forms"
    forms_bootstrap : "../assets/js/plugins/backbone.forms.bootstrap"
    forms_list      : "../assets/js/plugins/backbone.forms.list.min"  
    backbone_nested:  "../assets/js/plugins/backbone.nested.min"
    
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
    forms:  
      deps:    ["backbone","underscore"]
      exports:  "forms"
    forms_bootstrap:
      deps: ["forms"]
    forms_list:
      deps: ["forms"]
    backbone_nested:
      deps:["backbone"]
