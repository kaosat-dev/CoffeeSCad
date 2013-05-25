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
        
      browserStore.setup()
    
    afterEach ->
      localStorage.removeItem("projectsTest/TestProject/TestProject.coffee")
      localStorage.removeItem("projectsTest/TestProject/SomeOtherFile.coffee")
      localStorage.removeItem("projectsTest/TestProject/.thumbnail.png")
      localStorage.removeItem("projectsTest/TestProject")
      
      localStorage.removeItem("projectsTest/FooProject/FooProject.coffee")
      localStorage.removeItem("projectsTest/FooProject/SomeOtherFile.coffee")
      localStorage.removeItem("projectsTest/FooProject/.thumbnail.png")
      localStorage.removeItem("projectsTest/FooProject")
      
      localStorage.removeItem("projectsTest")
    
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
      
    
    it 'can list projects',->
      browserStore.saveProject( project )
      obsProjectsList = browserStore.listProjects()
      expProjectsList = ["TestProject"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can list a project s files',->
      browserStore.saveProject( project )
      obsProjectsList = browserStore.listProjectFiles( project.name )
      expProjectsList = ["TestProject.coffee"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can rename/move projects',->
      browserStore.saveProject( project )
      browserStore.renameProject( "TestProject", "FooProject" )
      
      expect(localStorage.getItem("projectsTest/TestProject")).toEqual(null)
      expect(localStorage.getItem("projectsTest/TestProject/TestProject.coffee")).toEqual(null)
      
      expect(localStorage.getItem("projectsTest/FooProject")).toEqual("FooProject.coffee")
      expect(localStorage.getItem("projectsTest/FooProject/FooProject.coffee")).not.toEqual(null)

    #it 'can rename/move files',->
    #  browserStore.saveProject( project )
    #  browserStore.renameFile( "TestProject/TestProject.coffee", "TestProject/FooProject.coffee" )
      
    #it 'can delete projects by reference',->
    #  browserStore.deleteProject ( project )
    
    it 'can delete projects by name',->
      browserStore.saveProject( project )
      browserStore.deleteProject ( "TestProject" )
      
      expStorageData = null
      obsStorageData = localStorage.getItem( "projectsTest" + "TestProject" )
      expect(obsStorageData).toEqual(expStorageData)
      
      expStorageData = null
      obsStorageData = localStorage.getItem( "projectsTest/TestProject/TestProject.coffee")
      expect(obsStorageData).toEqual(expStorageData)
    
    it "provides a shorthand to get a project's thumbnail", ->
      project.addFile
        name: ".thumbnail.png"
        content: "beautifull image"
      browserStore.saveProject( project )
      
      obsthumbnail = browserStore.getThumbNail( "TestProject" )
      expThumbnail = "beautifull image"
      expect(obsthumbnail).toEqual(expThumbnail)
      
