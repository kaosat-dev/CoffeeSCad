define (require)->
  AmfExporter = require "exporters/amfExporter/amfExporter"
  Project = require "core/projects/project"
  ProjectManager = require "core/projects/projectManager" 

  describe "AmfExporter ", ->
    projectManager = null 
    project = null
    amfExporter = null
    
    beforeEach ->
      projectManager = new ProjectManager()
      project = new Project
        name:"AProject"
      amfExporter = new AmfExporter()
      projectManager.project = project
    
    it 'can export a project to amf (blobUrl)',->
      project.addFile
        name:"AProject.coffee"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        testPart2 = new TestPart()
        
        assembly.add(testPart)
        assembly.add(testPart2)
        """
      #project.compile()
      projectManager.compileProject()
      blobUrl = amfExporter.export(project.rootAssembly)
      expect(blobUrl).not.toBe(null)
    
    it 'triggers an amfExport:error event when export fails',-> 
      project.addFile
        name:"AProject.coffee"
      errorCallback = jasmine.createSpy('-error event callback-')
      amfExporter.vent.on("amfExport:error", errorCallback)
      
      amfExporter.export(project.rootAssembly)
      errorArgs = errorCallback.mostRecentCall.args
      expect(errorArgs).toBeDefined()
      expect(errorArgs[0].message).toBe("Failed to merge csgObject children with error: TypeError: Object #<Object> has no method 'clone'")
      
    it 'returns null when export fails',->   
      project.addFile
          name:"AProject.coffee"
      blobUrl = amfExporter.export(project.rootAssembly)
      expect(blobUrl).toBe(null)
    
    

