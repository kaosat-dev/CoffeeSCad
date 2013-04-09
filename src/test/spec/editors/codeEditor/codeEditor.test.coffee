define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  CodeEditor = require 'editors/codeEditor/codeEditor'
  CodeEditorSettings = require 'editors/codeEditor/codeEditorSettings'
  
  describe "codeEditor", ->
    project = null
    editorSettings = null
    
    beforeEach ->
      project = new Project
        name:"test_project"
      project.create_part
        name:"testPart"
      project.create_part
        name:"otherPart"
        
      settings=new CodeEditorSettings()
      settings.set("startLine",7)
    
    it 'accepts previously defined settings' , -> 
      codeEditor = new CodeEditor
        project: project
        settings:settings 
      expect(codeEditor.settings.get("startLine")).toBe 7

    it 'creates as many tabs as files are passed to it' , ->
      
      
   
     
    
      