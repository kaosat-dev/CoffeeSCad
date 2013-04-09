define (require)->
  StlExporter = require "exporters/stlExporter/stlExporter"
  Project = require "core/projects/project"

  describe "StlExporter ", ->
    project = null
    stlExporter = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
      stlExporter = new StlExporter()
    
    it 'can export a project to stl (blobUrl)',->
      project.addFile
        name:"test_project.coffee"
        content:"""
        class TestPart extends Part
          constructor:(options) ->
            super options
            @union(new Cylinder(h:300, r:20,$fn:3))
        
        testPart = new TestPart()
        assembly.add(testPart)
        """
      project.compile()
      blobUrl = stlExporter.export(project.rootAssembly)
      expect(blobUrl).not.toBe(null)
    
    it 'triggers an stlExport:error event when export fails',-> 
      project.addFile
        name:"test_project.coffee"
      errorCallback = jasmine.createSpy('-error event callback-')
      stlExporter.vent.on("stlExport:error", errorCallback)
      
      stlExporter.export(project.rootAssembly)
      errorArgs = errorCallback.mostRecentCall.args
      expect(errorArgs).toBeDefined()
      expect(errorArgs[0].message).toBe("Failed to merge csgObject children with error: TypeError: Object #<Object> has no method 'clone'")
      
    it 'returns null when export fails',->   
      project.addFile
          name:"testFileName"
      blobUrl = stlExporter.export(project.rootAssembly)
      expect(blobUrl).toBe(null)

