define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Project = require "modules/core/projects/project"
  
  
  checkDeferred=(df,fn) ->
    callback = jasmine.createSpy()
    errback = jasmine.createSpy()
    df.then(callback, errback)
    waitsFor -> callback.callCount > 0
    runs -> 
      fn.apply @,callback.mostRecentCall.args if fn
      expect(errback).not.toHaveBeenCalled()
  
  describe "Project ", ->
    project = null
    compiler = null
    
    beforeEach ->
      project = new Project
        name:"Project"
    
    it 'can make new project files',->
      project.addFile
        name:"Project.coffee"
        content:"testContent"
      
      expect(project.rootFolder.at(0).name).toBe("Project.coffee")
    
    it 'can remove files from itself' , ->
      file = project.addFile
        name:"testFileName"
        content:"testContent" 
      
      project.removeFile(file)
      expect(project.rootFolder.length).toBe 0
      
    it 'compiles the contents of its files into an assembly of parts', ->
      project.addFile
        name:"Project.coffee"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      checkDeferred $.when(project.compile()), (assembly) =>
        expect(project.rootAssembly.children[0].polygons.length).toBe(9)
      
   
    it 'generates bom data when compiling',->
      project.addFile
        name:"Project.coffee"
        content:"""
        class SubPart extends Part
          constructor:(options)->
            super options
          
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
            @add(new SubPart())
            @add(new SubPart()) 
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      project.compile()
      ###
      expBom = new Backbone.Collection()
      expPart = new Backbone.Model
        included: true
        manufactured: true
        name: "TestPart"
        params: ""
        quantity: 2
        variant: "Default"
      expBom.add  expPart###
      
      checkDeferred $.when(project.compile()), (assembly) =>
        expect(JSON.stringify(project.bom)).toEqual('[{"name":"TestPart","variant":"Default","params":"","quantity":1,"manufactured":true,"included":true},{"name":"SubPart","variant":"Default","params":"","quantity":2,"manufactured":true,"included":true}]')
    
      
    it 'is marked as "dirty" when one of its files gets modified', ->
      expect(project.isCompileAdvised).toBe(false)
      project.addFile
        name:"test_project"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      project.isCompileAdvised = false
      mainFile = project.rootFolder.get("test_project")
      mainFile.content= ""
      expect(project.isCompileAdvised).toBe(true)
     
   
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
      
    
    it 'flags itself as isCompileAdvised on change' , ->  
      part.content="DummyContent"
      expect(part.isCompileAdvised).toBe true
      
    it 'flags itself as not isCompileAdvised on save' , ->  
      part.content="DummyContent"
      part.save()
      expect(part.isCompileAdvised).toBe false
    ### 
    
      