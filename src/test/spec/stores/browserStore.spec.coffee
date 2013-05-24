define (require)->
  Project = require "core/projects/project"
  BrowserStore = require 'stores/browser/browserStore2'
  
  
  describe "browserStore", ->
    project = null
    browserStore = null
    
    beforeEach ->
      project = new Project
        name:"TestProject"
      project.addFile
        name: "TestProject.coffee"
        content: "bla bla"
      
      browserStore = new BrowserStore
        rootUri:"projectsTest"
    
    it 'can save projects',->
      browserStore.saveProject( project )
      obsLocalStorageData = localStorage.getItem("projectsTest/TestProject/TestProject.coffee")
      expLocalStorageData = """{"name":"TestProject.coffee","content":"bla bla","isActive":false,"isSaveAdvised":false,"isCompileAdvised":false}"""
      expect(obsLocalStorageData).toEqual(expLocalStorageData)
      
      localStorage.removeItem("projectsTest/TestProject/TestProject.coffee")
      
    it 'can load projects',->
      fileData = """{"name":"TestProject.coffee","content":"bla bla","isActive":false,"isSaveAdvised":false,"isCompileAdvised":false}"""
      localStorage.setItem("projectsTest/TestProject/TestProject.coffee", fileData)
      localStorage.setItem("projectsTest/TestProject", ["TestProject.coffee","SomeOtherFile.coffee"])
      
      project = browserStore.loadProject( "TestProject" )
      
      localStorage.removeItem("projectsTest/TestProject")
      localStorage.removeItem("projectsTest/TestProject/TestProject.coffee")
    
    it 'can list projects',->
      browserStore.saveProject( project )
      obsProjectsList = browserStore.listProjects()
      expProjectsList = ["TestProject"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can rename projects',->
      browserStore.renameProject( project, "FooProject" )

    it 'can delete projects by reference',->
      browserStore.deleteProject ( project )
    
    it 'can delete projects by name',->
      browserStore.deleteProject ( "TestProject" )
    