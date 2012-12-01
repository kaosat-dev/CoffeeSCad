define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  require 'match_high'
  require 'search'
  require 'dialog'
  
  CoffeeScript = require 'CoffeeScript'
  require 'coffeelint'
  codeEdit_template = require "text!templates/codeedit.tmpl"
  
  class CodeEditorView extends marionette.ItemView
    template: codeEdit_template
    ui:
      codeBlock : "#codeArea"
      errorBlock: "#errorConsole"
      
    constructor:(options)->
      super options
      @settings= options.settings
      @editor = null
      @markers = []
      @lintConf = {
        "max_line_length": {"value": 80, "level": "warning"},
        "no_tabs":{"level": "warning"}
        "indentation" : {
          "value" : 2,
          "level" : "ignore"
        }
        }
      
      @app = require 'app'
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "saved", @modelSaved)
      @bindTo(@settings, "change", @settingsChanged)
      @app.vent.bind("csgParseError", @showError)
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @editor.setValue(@model.get("content"))
      @app.vent.trigger("clearUndoRedo", @)
      @editor.clearHistory()
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "saved", @modelSaved)
      
    modelChanged: (model, value)=>
      $(@ui.errorBlock).addClass("well")
      $(@ui.errorBlock).removeClass("alert alert-error")
      $(@ui.errorBlock).html("")
      @app.vent.trigger("modelChanged", @)
      
      $("[rel=tooltip]").tooltip
            placement:'bottom' 
            
    modelSaved: (model)=>
      
    
    settingsChanged:(settings, value)=> 
      console.log("Settings changed")
      for key, val of @settings.changedAttributes()
        switch key
          when "startLine"
            @editor.setOption("firstLineNumber",val)
            @render()
    
    showError:(error)=>
      #console.log("In show error")
      #TODO: should be its own view, not a hack
      try
        $(@ui.errorBlock).removeClass("well")
        $(@ui.errorBlock).addClass("alert alert-error")
        $(@ui.errorBlock).html("<div> <h4>#{error.name}:</h4>  #{error.message}</div>")
        errLine = error.message.split("line ")
        errLine = errLine[errLine.length - 1]
        errMsg = error.message
      catch err
        console.log("Inner err: "+ err)
        $(@ui.errorBlock).text(error)
      
    updateHints: ()=>
      #console.log "updating hints: errors "+@markers.length
      for i, marker of @markers
        @editor.clearMarker(marker)
      @markers = []
      @editor.operation( ()=>
        #TODO: fetch errors from csg compiler?
        try
          errors = coffeelint.lint(@editor.getValue(), @lintConf)
          for i, error of errors
            errMsg = error.message
            markerDiv= "<span class='CodeErrorMarker'> <a href='#' rel='tooltip' title=\" #{errMsg}\" > <i class='icon-remove-sign'></i></a></span> %N%"
            marker = @editor.setMarker(error.lineNumber - 1, markerDiv)
            @markers.push(marker)
        catch error
            #here handle any error not already managed by coffeelint
            errLine = error.message.split("line ")
            errLine = errLine[errLine.length - 1]
            errMsg = error.message
            markerDiv= "<span class='CodeErrorMarker'> <a href='#' rel='tooltip' title=\" #{errMsg}\" > <i class='icon-remove-sign'></i></a></span> %N%"
            try
              marker = @editor.setMarker(errLine - 1, markerDiv)
              @markers.push(marker)
            catch error
              console.log "ERROR #{error} in adding error marker"
      )
      
     # info = @editor.getScrollInfo()
     # after = @editor.charCoords({line: @editor.getCursor().line + 1, ch: 0}, "local").top
     # if (info.top + info.clientHeight < after)
     #   @editor.scrollTo(null, after - info.clientHeight + 3)
    
    #this could also be solved by letting the event listeners access the list of available undos & redos ?
    updateUndoRedo: () =>
      redos = @editor.historySize().redo
      undos = @editor.historySize().undo
      if redos >0
        @app.vent.trigger("redoAvailable", @)
      else
        @app.vent.trigger("redoUnAvailable", @)
      if undos >0
        @app.vent.trigger("undoAvailable", @)
      else
        @app.vent.trigger("undoUnAvailable", @)
        
    undo:=>
      undoes = @editor.historySize().undo
      if undoes > 0
        @editor.undo()
        
    redo:=>
      redoes = @editor.historySize().redo
      if redoes >0
        @editor.redo()
    
    onRender: =>
      foldFunc = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)
      
      @editor = CodeMirror.fromTextArea @ui.codeBlock.get(0),
        mode:"coffeescript"
        tabSize: 2
        indentUnit:2
        indentWithTabs:false
        lineNumbers:true
        gutter: true
        matchBrackets:true
        firstLineNumber:@settings.get("startLine")
        onChange:(arg, arg2)  =>
          @updateHints()
          @model.set "content", @editor.getValue()
          @updateUndoRedo()
          return
        onGutterClick:
          foldFunc 
        onCursorActivity:() =>
          @editor.matchHighlight("CodeMirror-matchhighlight")
          @editor.setLineClass(@hlLine, null, null)
          @hlLine = @editor.setLineClass(@editor.getCursor().line, null, "activeline")
        extraKeys: 
            "Ctrl-Q": (cm) ->
              foldFunc(cm, cm.getCursor().line)
            #"Ctrl-P" : newProject
            #"Ctrl-S" : saveProject
            Tab:(cm)->
              cm.replaceSelection("  ", "end")
            
      @hlLine=  @editor.setLineClass(0, "activeline")
      
      setTimeout @editor.refresh, 0 #necessary hack
      #TODO : find  a way to put this in the init/constructor
      @app.vent.bind("undoRequest", @undo)
      @app.vent.bind("redoRequest", @redo)
      
  return CodeEditorView