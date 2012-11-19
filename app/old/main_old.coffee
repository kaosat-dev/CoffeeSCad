#TODO organize into modules
require.config({
  baseUrl: 'js',
  paths: {
    "jquery": "vendor/jquery-1.8.1.min",
    "jquery.hotkeys": "vendor/jquery.hotkeys",
    "bootstrap": "vendor/bootstrap.min",
    
    #"underscore": "vendor/underscore-min",
    
    "CodeMirror": "vendor/codemirror",
    "foldcode": "vendor/foldcode",
    "synHigh": "vendor/codeMirror/mode/coffeescript/coffeescript",
    
    "lightgl":"lightgl",
    "csg":"csg",  
    "CoffeeScript": "vendor/CoffeeScript",
    
    "opencoffeescad": "opencoffeescad",
    "viewer": "viewer",
    "DataStore": "DataStore"
  },
  shim: {
    "CodeMirror": {
      exports: "CodeMirror"
    },
    "bootstrap":{
      deps: ['jquery'],
      exports: "bootstrap"
    },
    "jquery.hotkeys": ['jquery'],
    "foldcode": ["CodeMirror"],
    "synHigh": ["CodeMirror"],
    
    "CoffeeScript":{
       exports: "CoffeeScript"
    },
    
    "opencoffeescad":{
      deps: ['CoffeeScript'],
      exports: "opencoffeescad"
    },
    "viewer": ["opencoffeescad","csg","lightgl"],
    "DataStore": ["opencoffeescad","csg","lightgl"],
    #main application
    app:{
      deps: ["CodeMirror"],
      exports: "App"
    }
    
  }
 })
 

#code editor
#define [], () ->

#require(["jquery", "CodeMirror","bootstrap", "jquery.hotkeys","lightgl","csg", "Coffeescript", "opencoffeescad","DataStore","viewer"], 
#($, CodeMirror, fold, synHigh, bootstrap, jshk,lightgl,csg, CoffeeScript, opencoffeescad, ds,vw)->

require(["CodeMirror","bootstrap", "jquery.hotkeys","opencoffeescad","DataStore","viewer","CoffeeScript"], 
()->
  
    store = new OpenCoffeeScad.DataStoreManager()
   
    cadProcessor = null
    codeEditor = null
    glViewer = null
    
    projectName= "MyProject"
    codeUpdated = true
    
    tutu = CoffeeScript.compile("class Pouet")
    #console.log("pouet"+App)
    #webgl viewer & opencoffeescad processor
    init_ocoffee = () ->
      # Show all exceptions to the user:
      #OpenJsCad.AlertUserOfUncaughtExceptions();
      ###
      gProcessor = null
      gProcessor = new OpenJsCad.Processor(document.getElementById("viewer"),750,750);
      gProcessor.setDebugging(true);
      gProcessor.setJsCad(codeEditor.getValue());###

      glViewer = new OpenCoffeeScad.Viewer(document.getElementById("viewer"),750,750)
      console.log("mlk3")
      cadProcessor = new OpenCoffeeScad.Processor(true, null, document.getElementById("statusBar"), glViewer)
      updateSolid()

    updateSolid=() ->
      cadProcessor.setCoffeeSCad(codeEditor.getValue());


    #project save load etc
    
    checkCodeEditorContent = () ->
      if codeEditor.lineCount()>0
        $('#updateBtn').removeClass("disabled");
        
    updateUndoRedo= () ->
      redoes = codeEditor.historySize().redo
      undoes = codeEditor.historySize().undo
      #console.log("undoes"+undoes+" redoes "+redoes );
      if (redoes >0)
        $('#redoBtn').removeClass("disabled")
      else
        $('#redoBtn').addClass("disabled")
      if (undoes >0)
        $('#undoBtn').removeClass("disabled")
      else
        $('#undoBtn').addClass("disabled")

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
 
    #foldFunc = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)
    codeEditor = CodeMirror.fromTextArea(codeArea,
    {
        mode:"coffeescript",
        lineNumbers:true,
        gutter:true,
        matchBrackets:true,
        firstLineNumber:1,
        onChange:(arg, arg2)  ->   
          updateUndoRedo()
          checkCodeEditorContent()
          codeUpdated = true
          document.title = "OpenCoffeeSCad "+" *"+projectName
        #onGutterClick: foldFunc,
        extraKeys: { 
          "Ctrl-Q": (cm) ->
            foldFunc(cm, cm.getCursor().line)
          #"Ctrl-P" : newProject,
          #"Ctrl-S" : saveProject
        }
    })
    #codeEditor.setOption("mode")
    
    #jquery/ bootstrap UI stuff
    $("[rel=tooltip]").tooltip({placement:'bottom'})
    
    #keybindings
    $(document).bind 'keyup', 'shift+a', ()->
      console.log("Updating solid")
      #updateSolid()

    $(document).bind 'keydown', 'F5', ()->
      console.log("Updating solid")
      updateSolid()
      #return false
  
    $("#codeArea").bind 'keydown', 'F2', ()->
      console.log("Saving file")
      saveProject()
      #preventDefault()
      return false
      
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

    #post initialization
    checkCodeEditorContent()
    document.title = "OpenCoffeeSCad "+projectName
    get_recentProjects()
    init_ocoffee()
    #store.load_fromGist()
)


### 
require(["jquery", "underscore"], ($, underscore)->
    $("#codeArea").val("lm")
    showName = (n) ->
      temp = _.template("Hello <%= name %>")
      $("body").html(temp({name: n})) 
    showName("sdf")  
 )
###

  


