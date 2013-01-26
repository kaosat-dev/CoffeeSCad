define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Project = require "modules/core/projects/project"
  
  describe "Project ", ->
    project = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
    
    it 'can make new project files',->
      project.createFile
        name:"testFileName"
        content:"testContent"
      
      expect(project.pfiles.at(0).get("name")).toBe("testFileName")
    
    it 'can remove files from itself' , ->
      file = project.createFile
        name:"testFileName"
        content:"testContent" 
      
      project.remove(file)
      expect(project.files.length).toBe 0
      
    it 'compiles the contents of its files into an assembly of parts', ->
      project.createFile
        name:"testFileName"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      project.compile()
      expect(project.rootAssembly.children[0].polygons.length).toBe(9)
   
    it 'generates bom data when compiling',->
      project.createFile
        name:"testFileName"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      project.compile()
      expBom = new Backbone.Collection()
      expPart = new Backbone.Model
        included: true
        manufactured: true
        name: "TestPart"
        params: ""
        quantity: 2
        variant: "Default"
      expBom.add  expPart
      expect(JSON.stringify(project.bom)).toEqual('[{"name":"TestPart","variant":"Default","params":"","quantity":2,"manufactured":true,"included":true}]')
      
    it 'is marked as "dirty" when one of its files gets modified', ->
      expect(project.dirty).toBe(false)
      project.createFile
        name:"testFileName"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      expect(project.dirty).toBe(true)
      project.dirty = false
      project.pfiles.at(0).set("content","")
      expect(project.dirty).toBe(true)
     
   
   #########################
   ### 
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
    ### 
    
      