define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Project = require "modules/core/projects/project"
  PreProcessor = require "modules/core/projects/preprocessor"
  
  describe "PreProcessor", ->
    project = null
    preprocessor= null
    
    beforeEach ->
      project = new Project
        name:"TestProject"
      
      preprocessor = new PreProcessor()
    
    it 'can emulate coffeescript function syntax (with or without parens) (as it is a "pseudo method")',->
      project.createFile
        name:"TestProject"
        content:"""include ("config.coffee")"""
      project.createFile
        name:"config"
        content:"""testVariable = 42"""  
      
      expPreProcessedSource = """
      
      testVariable = 42
      
      """
      obsPreprocessedSource = preprocessor.process(project) 
      expect(obsPreprocessedSource).toBe(expPreProcessedSource)
      
      
      project.createFile
        name:"TestProject"
        content:"""include "config.coffee" """
      project.createFile
        name:"config"
        content:"""testVariable = 42"""  
      
      obsPreprocessedSource = preprocessor.process(project) 
      expect(obsPreprocessedSource).toBe(expPreProcessedSource)
      
    
    it 'can process file includes from the current project',->
      project.createFile
        name:"TestProject"
        content:"""include ("config.coffee")
        mainVariable = testVariable+2
        """
      project.createFile
        name:"config"
        content:"""testVariable = 42"""
      
      expPreProcessedSource = """
      
      testVariable = 42

      mainVariable = testVariable+2
      """
      
      obsPreprocessedSource = preprocessor.process(project)
      expect(obsPreprocessedSource).toBe(expPreProcessedSource)
    
    it 'can check for circular dependency issues and raise an exception',->
      project.createFile
        name:"TestProject"
        content:"""include ("config.coffee")"""
      project.createFile
        name:"config"
        content:"""include ("someOtherFile.coffee")"""
      project.createFile
        name:"someOtherFile"
        content:"""include ("TestProject.coffee")"""
        
     
      expect(()-> (preprocessor.process(project))).toThrow("Circular dependency detected from someOtherFile to TestProject")
    
    #TODO : how to do these ? in specs ??
    ###
    it 'can process local stl file includes',->
      project.createFile
        name:"TestProject"
        content:"""include ("toto.stl")"""
     
    it 'can process dropbox (remote) file includes',->
      project.createFile
        name:"TestProject"
        content:"""include "browser:MCAD/gears/myGear.coffee" """
    ###
    ###    
    source = """include \"dropbox:mySupaProject/toto/blabla.coffee\"
      include ("browser:otherProject")
      """
    ###