define (require)->
  AmfExporter = require "core/projects/kernel/geometry/exporters/amfExporter"
  Project = require "core/projects/project"

  describe "AmfExporter ", ->
    project = null
    amfExporter = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
      amfExporter = new THREE.amfExporter()
    
    
    it 'can export a project to amf',->
      project.addFile
        name:"test_project.coffee"
        content:"""
        myCube = new Cube({size:[20,20,20]})
        mySphere = new Sphere({r:15, $fn:20})
        
        myCube.name = "testCube"
        mySphere.position.x = 25

        assembly.add(myCube)
        assembly.add(mySphere)
        """
      project.compile()
      obsAmf = amfExporter.parse(project.rootAssembly)
      expAmf = null 
      console.log obsAmf
      
      expect(obsAmf).toEqual(expAmf)
    
   
