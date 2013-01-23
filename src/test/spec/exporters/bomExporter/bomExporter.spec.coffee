define (require)->
  BomExporter = require "modules/exporters/bomExporter/bomExporter"
  Project = require "modules/core/projects/project"

  describe "BomExporter", ->
    project = null
    bomExporter = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
      bomExporter = new BomExporter()
    
    it 'can export a project to bom (blobUrl)',->
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
      blobUrl = bomExporter.export(project.rootAssembly)
      expect(blobUrl).not.toBe(null)
    
    it 'triggers an bomExport:error event when export fails',-> 
      project.createFile
        name:"testFileName"
      errorCallback = jasmine.createSpy('-error event callback-')
      bomExporter.vent.on("bomExport:error", errorCallback)
      
      bomExporter.export(project)
      errorArgs = errorCallback.mostRecentCall.args
      expect(errorArgs).toBeDefined()
      expect(errorArgs[0].message).toBe(" ")
      
    it 'returns null when export fails',->   
      project.createFile
          name:"testFileName"
      blobUrl = bomExporter.export(project.rootAssembly)
      expect(blobUrl).toBe(null)

