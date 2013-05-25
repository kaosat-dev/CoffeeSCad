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
    
    it 'can list a project s files',->
      browserStore.saveProject( project )
      obsProjectsList = browserStore.listProjectFiles()
      expProjectsList = ["TestProject"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can rename projects',->
      browserStore.renameProject( project, "FooProject" )

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
      
