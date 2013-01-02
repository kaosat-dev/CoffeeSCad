define (require)->
  #jasmine     = require 'jasmine'
  jasmine = require 'jasmine-html'
  $ = require 'jquery'
  
  #Ensure you point to where your spec folder is, base directory is app/,
  specs=[]
  #specs.push("./test/spec/project.spec")
  specs.push("spec/settings.spec")
  
  jasmineEnv = jasmine.getEnv()
  jasmineEnv.updateInterval = 1000
  
  jasmineEnv.addReporter(new jasmine.TrivialReporter())

  $ ->
    require specs, ->
      jasmineEnv.execute()
    
  #require specs, ()->
    
    #ConsoleJasmineReporter2 = require('./lib/consoleJasmineReporter2').ConsoleJasmineReporter
    #jasmine.getEnv().addReporter(new ConsoleJasmineReporter2())
    #Set up the jasmine reporters once each spec has been loaded
    
  #jasmineEnv.execute()
    
    
  
  ### 
  requirejs specs, ()-> 
    jasmine = require('./test/Vendor/jasmine').jasmine
    #ConsoleJasmineReporter2 = require('./lib/consoleJasmineReporter2').ConsoleJasmineReporter
    #jasmine.getEnv().addReporter(new ConsoleJasmineReporter2())
    #Set up the jasmine reporters once each spec has been loaded
    jasmine.getEnv().addReporter(new jasmine.TrivialReporter())
    jasmine.getEnv().execute()
  ###
    