define (require)->
  Library = require "core/projects/library"
  Project = require "core/projects/project"
  
  describe "library", ->
    library = null
    
    beforeEach ->
      library = new Library()
  
    it 'can list projects from different types of storage', ->
      allProjects = library.getProjectByStore("all")
      
      expect(allProjects).toEqual([])
      
    it 'can save a project to browser (localstorage)' , ->
      project = new Project
        name : "testProject"
      project.createFile
        name : "testFile"
        content : "someContent"
    
