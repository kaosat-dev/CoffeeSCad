describe "toto", ->
  it 'can do jokes', ->
    expect(true).toBe(true)

define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  {Library,Project,ProjectFile} = require "modules/project"
  
  describe "library", ->
    lib = null
    
    beforeEach ->
      lib = new Library()
  
    #it 'can save itself' , ->
    #  #lib.save()
    #  expect(lib.files).toBe(["bla","bli"])
  
  
  describe "project", ->
    project = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
    
    it 'can add files to itself' , ->
      part = new ProjectFile
        name: "a part"
        ext: "coscad"
        content: ""    
      project.add(part)
      expect(project.files.length).toBe 1
      expect(project.pfiles.length).toBe 1
      expect(project.files[0]).toBe("a part")
     
    it 'can remove files from itself' , ->
      part = new ProjectFile
        name: "a part"
        ext: "coscad"
        content: ""    
      
      project.add(part)
      project.remove(part)
      expect(project.files.length).toBe 0
   
   #########################
   
   describe "projectFile", ->
    project = null
    part = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
      part = new ProjectFile
        name: "test_part"
        ext: "coscad"
        content: "" 
      project.add part  
    
    afterEach ->
      part.destroy()
      localStorage.removeItem("Library-test_project")
      localStorage.removeItem("Library-test_project-parts")
      
    
    it 'flags itself as dirty on change' , ->  
      part.set("content","DummyContent")
      expect(part.dirty).toBe true
      
    it 'flags itself as not dirty on save' , ->  
      part.set("content","DummyContent")
      part.save()
      expect(part.dirty).toBe false
     
    
      