define (require)->
  Project = require "core/projects/project"
  BrowserStore = require 'core/stores/browser/browserStore'
  
  
  describe "browserStore", ->
    project = null
    browserStore = null
    
    beforeEach ->
      project = new Project
        name:"TestProject"
      project.addFile
        name: "TestProject.coffee"
        content: "bla bla"
      
      browserStore = new BrowserStore()
    
    it 'can save projects',->
      browserStore.saveProject( project )
      
    it 'can load projects',->
      browserStore.loadProject( "TestProject" )
    
    it 'can rename projects',->
      browserStore.renameProject( project, "FooProject" )

    it 'can delete projects by reference',->
      browserStore.deleteProject ( project )
    
    it 'can delete projects by name',->
      browserStore.deleteProject ( "TestProject" )
    