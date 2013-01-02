require.config
  deps: ["runner"]
  paths:
    #JavaScript folders.
    libs:             "../assets/js/libs"
    plugins:          "../assets/js/plugins"
    vendor:           "../assets/vendor"
    
    #Libraries.
    jquery:           "../assets/js/libs/jquery-1.8.1.min"
    underscore:       "../assets/js/libs/underscore-min"
    backbone:         "../assets/js/libs/backbone"
    
    jasmine:          "../test/vendor/jasmine"
    'jasmine-html':     "../test/vendor/jasmine-html"
    
  shim:
    jasmine:
      exports: 'jasmine'
    'jasmine-html':
      deps: ['jasmine']
      exports: 'jasmine'


