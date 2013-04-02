define (require)->
  #jasmine     = require 'jasmine'
  jasmine = require 'jasmine-html'
  $ = require 'jquery'
  
  #Ensure you point to where your spec folder is, base directory is app/,
  specs=[]
  #core
  specs.push("./spec/project.spec")
  specs.push("./spec/preprocessor.spec")
  specs.push("./spec/csg.spec")
  specs.push("./spec/settings.spec")
  
  specs.push("./spec/regexExperiments.spec")
  
  #editors
  
  #exporters
  specs.push("./spec/exporters/bomExporter/bomExporter.spec")
  specs.push("./spec/exporters/stlExporter/stlExporter.spec")
  specs.push("./spec/exporters/amfExporter/amfExporter.spec")
  
  
  jasmineEnv = jasmine.getEnv()
  jasmineEnv.updateInterval = 1000
  
  trivialReporter = new jasmine.TrivialReporter()
  jasmineEnv.addReporter(trivialReporter)
  
  jasmineEnv.specFilter = (spec) ->
    return trivialReporter.specFilter(spec)
    
  $ ->
    require specs, ->
      jasmineEnv.execute()
    
  #require specs, ()->
    #ConsoleJasmineReporter2 = require('./lib/consoleJasmineReporter2').ConsoleJasmineReporter
    #jasmine.getEnv().addReporter(new ConsoleJasmineReporter2())
    #Set up the jasmine reporters once each spec has been loaded
  ### 
  requirejs specs, ()-> 
    jasmine = require('./test/Vendor/jasmine').jasmine
    #ConsoleJasmineReporter2 = require('./lib/consoleJasmineReporter2').ConsoleJasmineReporter
    #jasmine.getEnv().addReporter(new ConsoleJasmineReporter2())
    #Set up the jasmine reporters once each spec has been loaded
    jasmine.getEnv().addReporter(new jasmine.TrivialReporter())
    jasmine.getEnv().execute()
  ###
    