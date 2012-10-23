define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  codeEdit_template = require "text!templates/codeedit.tmpl"
  
      
  class CodeEditorView extends marionette.ItemView
    template: codeEdit_template
    ui:
      codeBlock : "#codeArea2"
      
    constructor:(options)->
      super options
      @editor = null
      @app = require 'app'
      @bindTo(@model, "change", @modelChanged)
    
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
        firstLineNumber:1
        onChange:(arg, arg2)  =>   
          @model.set "content", @editor.getValue()
          @updateUndoRedo()
      
      setTimeout @editor.refresh, 0 
      
      #TODO : find  a way to put this in the init/constructor
      @app.vent.bind("undoRequest", @undo)
      @app.vent.bind("redoRequest", @redo)
      
  return CodeEditorView