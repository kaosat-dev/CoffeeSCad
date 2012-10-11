define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  CodeMirror = require 'CodeMirror'
  require 'foldcode'
  require 'coffee_synhigh'
  test_template = require "text!templates/codeview.tmpl"
  codeEdit_template = require "text!templates/codeedit.tmpl"
  
  class CodeView extends marionette.ItemView
    template: test_template
    
    initialize:()->
      ###
      @bind @model, ()=>
        name = @get "name"
      ###
    onBeforeRender:() =>
      console.log "pouet"
    onRender: =>
      console.log "tjtj"
  
      
  class CodeEditorView extends marionette.ItemView
    template: codeEdit_template
    ui:
      codeBlock : "#codeArea2"
      editor:     "#editor"
      
    templateHelpers:
      showMessage: ->
        return "Test"  

    constructor:(options)->
      super options
      
    modelChanged: (model, value)->
      console.log "model changed"
      
    updateUndoRedo: () ->
      redoes = @editor.historySize().redo
      undoes = @editor.historySize().undo
      if redoes >0
        console.log "redoes"
      if undoes >0
        console.log "undoes"
      #TODO: remove this yucky piece of code
      if (redoes >0)
        $('#redoBtn').removeClass("disabled")
      else
        $('#redoBtn').addClass("disabled")
      if (undoes >0)
        $('#undoBtn').removeClass("disabled")
      else
        $('#undoBtn').addClass("disabled")
     
    onRender: =>
      #if not @editor?
      #console.log "Editor not instanciated"
      @editor = CodeMirror.fromTextArea @ui.codeBlock.get(0),
        mode:"coffeescript"
        lineNumbers:true
        gutter:true
        matchBrackets:true
        firstLineNumber:1
        onChange:(arg, arg2)  =>   
          @triggerMethod("foo:bar")
          @model.set "content", @editor.getValue()
          #console.log("code changed"+arg,arg2)
          console.log(@model)
          @updateUndoRedo()
      #else
      #  console.log "Editor already instanciated"

      setTimeout @editor.refresh, 0 
      @ui.editor.removeClass("hide") 
      
  return CodeEditorView