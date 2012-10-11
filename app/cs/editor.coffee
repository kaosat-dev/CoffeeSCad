define (require)->
  $          = require 'jquery'
  _          = require 'underscore'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  opencoscad = require 'opencoffeescad'
  

  #store = opencoscad.Store()
  projectName= "MyProject"
  codeUpdated = true
  
  updateSolid=() ->
      cadProcessor.setCoffeeSCad(codeEditor.getValue());
  
  checkCodeEditorContent = () ->
      if codeEditor.lineCount()>0
        $('#updateBtn').removeClass("disabled");
        
  newProject= () -> 
    codeEditor.setValue("")
    codeEditor.clearHistory()
    updateUndoRedo()
    
  saveProject= () ->
    #projectName =  window.projectName
    console.log("saving project")
    if (projectName != "")
      console.log("YESsaving project "+projectName)
      store.save_file("local", projectName, codeEditor.getValue())
      document.title = "OpenCoffeeSCad "+projectName

  loadProject= (projectNameToLoad) =>
    if (projectNameToLoad != "" && projectNameToLoad != null)
      projectName = projectNameToLoad
      codeEditor.setValue(store.load_file("local", projectName))
      codeEditor.clearHistory()
      updateUndoRedo()
      document.title = "OpenCoffeeSCad "+projectName
      
  get_recentProjects = () ->
    for index, project of store.get_files("local")
      value = project
      item = "<li><a tabindex='-1' href='#' >#{value}</a></li>"
      $('#recentFilesList').append(item)
      $('#fileLoadModalFileList').append(item)
   
  class Editor
    constructor:()->   
      @codeEditor = CodeMirror.fromTextArea codeArea,
          mode:"coffeescript"
          lineNumbers:true
          gutter:true
          matchBrackets:true
          firstLineNumber:1
          onChange:(arg, arg2)  =>   
            
            @updateUndoRedo()
           # @checkCodeEditorContent()
            codeUpdated = true
            document.title = "OpenCoffeeSCad "+" *"+projectName
          onGutterClick: ->#foldFunc,
          extraKeys: 
            "Ctrl-Q": (cm) ->
              foldFunc(cm, cm.getCursor().line)
            "Ctrl-P" : newProject
            "Ctrl-S" : saveProject
    updateUndoRedo: () ->
      redoes = @codeEditor.historySize().redo
      undoes = @codeEditor.historySize().undo
      #console.log("undoes"+undoes+" redoes "+redoes );
      if (redoes >0)
        $('#redoBtn').removeClass("disabled")
      else
        $('#redoBtn').addClass("disabled")
      if (undoes >0)
        $('#undoBtn').removeClass("disabled")
      else
        $('#undoBtn').addClass("disabled")
    getValue:()->
      return @codeEditor.getValue()
       
    #click bindings
    $('#undoBtn').on 'click', (e) ->
      codeEditor.undo()
      updateUndoRedo()

    $('#redoBtn').on 'click', (e) ->
      codeEditor.redo()
      updateUndoRedo()

    $('#newFileBtn').on 'click', (e) ->
      newProject()
  
    $('#saveFileBtn').on 'click', (e) ->
      $('#fileSaveModal').modal({"backdrop":false})
  
    $('#realSaveBtn').on 'click', (e) ->
      projectName = $('#projectFileName').val()
      saveProject()
      $('#fileSaveModal').modal('hide')
  
    $('#loadFileBtn').on 'click', (e) ->
      $('#fileLoadModal').modal({"backdrop":false})
     
    $('#realLoadBtn').on 'click', (e) ->
      saveName = $('#loadProjectFileName').val()
      newProject()
      #loadProject(saveName)
      $('#fileLoadModal').modal('hide')
  
    $('#updateBtn').on 'click', (e) ->
      if codeUpdated
        codeUpdated = false
        $('#updateBtn').addClass("disabled")
        updateSolid()
        return false

    $('#settingsBtn').on 'click', (e) ->
      $('#settingsModal').modal {"backdrop":false}
      
    $( "#recentFilesList" )
      .on "click", "li a", ( e ) ->
        pName = $(this).text()
        loadProject(pName)
        
    $( "#fileLoadModalFileList" )
      .on "click", "li a", ( e ) ->
        pName = $(this).text()
        loadProject(pName)

        
        
  return Editor
