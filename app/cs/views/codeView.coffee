define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  #require 'jsHint'
  codeEdit_template = require "text!templates/codeedit.tmpl"
  
      
  class CodeEditorView extends marionette.ItemView
    template: codeEdit_template
    ui:
      codeBlock : "#codeArea2"
      
    constructor:(options)->
      super options
      @settings= options.settings
      @editor = null
      @app = require 'app'
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@settings, "change", @settingsChanged)
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @editor.setValue(@model.get("content"))
      @app.vent.trigger("clearUndoRedo", @)
      @editor.clearHistory()
      @bindTo(@model, "change", @modelChanged)
      
    modelChanged: (model, value)=>
      @app.vent.trigger("modelChanged", @)
    
    settingsChanged:(settings, value)=> 
      console.log("Settings changed")
      for key, val of @settings.changedAttributes()
        switch key
          when "startLine"
            @editor.setOption("firstLineNumber",val)
            @render()
    
    updateHints:=>
      console.log "tutu"
      #widgets = []
      ###modified version of  codemirror.net/3/demo/widget.html###
      #coffeescriptHint
      editor.operation( ()->
        for i in [0...widgets.length]
          editor.removeLineWidget(widgets[i])
        widgets.length = 0
        
        #TODO: fetch errors from csg compiler?
        JSHINT(editor.getValue())
        for i in [0...JSHINT.errors.length]
          err = JSHINT.errors[i]
          if (!err) then continue
          msg = document.createElement("div");
          icon = msg.appendChild(document.createElement("span"))
          icon.innerHTML = "!!";
          icon.className = "lint-error-icon";
          msg.appendChild(document.createTextNode(err.reason))
          msg.className = "lint-error"
          widgets.push(editor.addLineWidget(err.line - 1, msg, {coverGutter: false, noHScroll: true}));
      )
      info = editor.getScrollInfo()
      after = editor.charCoords({line: editor.getCursor().line + 1, ch: 0}, "local").top
      if (info.top + info.clientHeight < after)
        editor.scrollTo(null, after - info.clientHeight + 3)
    
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
      @editor = CodeMirror.fromTextArea @ui.codeBlock.get(0),
        mode:"coffeescript"
        lineNumbers:true
        gutter:true
        matchBrackets:true
        firstLineNumber:@settings.get("startLine")
        lineWrapping : true
        onChange:(arg, arg2)  =>   
          @model.set "content", @editor.getValue()
          @updateUndoRedo()
      
      setTimeout @editor.refresh, 0 
      
      #TODO : find  a way to put this in the init/constructor
      @app.vent.bind("undoRequest", @undo)
      @app.vent.bind("redoRequest", @redo)
      
  return CodeEditorView