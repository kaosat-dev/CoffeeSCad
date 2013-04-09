define (require)->
  BomExporter = require "exporters/bomExporter/bomExporter"
  Project = require "core/projects/project"

  describe "BomExporter", ->
    project = null
    bomExporter = null
    
    beforeEach ->
      project = new Project
        name:"testProject"
      bomExporter = new BomExporter()
    
    it 'can export a project to bom (blobUrl)',->
      project.addFile
        name:"testProject.coffee"
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
      project.addFile
        name:"testFileName"
      errorCallback = jasmine.createSpy('-error event callback-')
      bomExporter.vent.on("bomExport:error", errorCallback)
      
      bomExporter.export(project)
      errorArgs = errorCallback.mostRecentCall.args
      expect(errorArgs).toBeDefined()
      expect(errorArgs[0].message).toBe(" ")
      
    it 'fail gracefully when export fails',->   
      project.addFile
          name:"testFileName"
      blobUrl = bomExporter.export(project.rootAssembly)
      expect(blobUrl).toBe("data:text/json;charset=utf-8,undefined")

