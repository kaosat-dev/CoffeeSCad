define (require)->
  Project = require "core/projects/project"
  DropoxStore = require 'stores/dropbox/dropBoxStore2'
  
  
  describe "dropboxStore", ->
    project = null
    dropboxStore = null
    
    beforeEach ->
      project = new Project
        name:"TestProject"
      project.addFile
        name: "TestProject.coffee"
        content: "bla bla"
      
      dropboxStore = new BrowserStore
        rootUri:"projectsTest"
        
      dropboxStore.setup()
    
    it 'can save projects',->
      dropboxStore.saveProject( project )
      obsLocalStorageData = localStorage.getItem("projectsTest/TestProject/TestProject.coffee")
      expLocalStorageData = """{"name":"TestProject.coffee","content":"bla bla","isActive":false,"isSaveAdvised":false,"isCompileAdvised":false}"""
      expect(obsLocalStorageData).toEqual(expLocalStorageData)
      
      localStorage.removeItem("projectsTest/TestProject/TestProject.coffee")
      
    it 'can load projects',->
      fileData = """{"name":"TestProject.coffee","content":"bla bla","isActive":false,"isSaveAdvised":false,"isCompileAdvised":false}"""
      localStorage.setItem("projectsTest/TestProject/TestProject.coffee", fileData)
      localStorage.setItem("projectsTest/TestProject", ["TestProject.coffee","SomeOtherFile.coffee"])
      
      project = dropboxStore.loadProject( "TestProject" )
      
      localStorage.removeItem("projectsTest/TestProject")
      localStorage.removeItem("projectsTest/TestProject/TestProject.coffee")
    
    it 'can list projects',->
      dropboxStore.saveProject( project )
      obsProjectsList = dropboxStore.listProjects()
      expProjectsList = ["TestProject"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can list a project s files',->
      dropboxStore.saveProject( project )
      obsProjectsList = dropboxStore.listProjectFiles()
      expProjectsList = ["TestProject"]
      
      expect(obsProjectsList).toEqual(expProjectsList)
    
    it 'can rename projects',->
      dropboxStore.renameProject( project, "FooProject" )

    #it 'can delete projects by reference',->
    #  dropboxStore.deleteProject ( project )
    
    it 'can delete projects by name',->
      dropboxStore.saveProject( project )
      dropboxStore.deleteProject ( "TestProject" )
      
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
      dropboxStore.saveProject( project )
      
      obsthumbnail = dropboxStore.getThumbNail( "TestProject" )
      expThumbnail = "beautifull image"
      expect(obsthumbnail).toEqual(expThumbnail)
      
