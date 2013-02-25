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
  
  vent = require 'modules/core/vent'
  codeEditor_template = require "text!./fileCode.tmpl"
  
  
  class FileCodeView extends Backbone.Marionette.ItemView
    template: codeEditor_template
    className: "tab-pane"
    ui:
      codeBlock : "#codeArea"
      
    constructor:(options)->
      super options
      @vent = vent
      @settings = options.settings
      @editor = null
      @_markers = []
     
      @model.on("change", @modelChanged)
      @model.on("saved", @modelSaved)
      @settings.on("change", @settingsChanged)
      
      #@vent.bind("csgParseError", @showError)
      @vent.on("file:closed", @onFileClosed)
      @vent.on("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.on("file:undoRequest", @undo)
      @vent.on("file:redoRequest", @redo)
    
    onFileSelected:(model)=>
      if model == @model
        @$el.addClass('active')
        @$el.removeClass('fade')
        #temporarhack, needed because of rendering issues forcing to re-render, but thus loosing undo history
        history = @editor.getHistory()
        @render()
        @editor.setHistory history
        #@editor.refresh()
        @updateUndoRedo()
        @updateHints()
        @editor.focus()
      else
        @$el.removeClass('active')
        @$el.addClass('fade')
    
    onFileClosed:(fileName)=>
      if fileName == @model.get("name")
        @close()
    
    onShow:()=>
      @$el.addClass('active')
      @$el.removeClass('fade')
        
    onClose:()=>
      console.log "closing code view"
      #cleanup all vent event
      @vent.off("file:closed", @onFileClosed)
      @vent.off("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.off("file:undoRequest", @undo)
      @vent.off("file:redoRequest", @redo)
    
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @editor.setValue(@model.get("content"))
      @vent.trigger("clearUndoRedo", @)
      @editor.clearHistory()
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "saved", @modelSaved)
      
    modelChanged: (model, value)=>
      @applyStyles()
      
    applyStyles:=>  
      @$el.find('[rel=tooltip]').tooltip({'placement': 'right'})
    
            
    modelSaved: (model)=>
      
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "startLine"
            @editor.setOption("firstLineNumber",val)
            @render()
          when "linting"
            @updateHints()
    
    _clearMarkers:=>
      for i, marker of @_markers
        @editor.clearMarker(marker)
    
    updateHints: ()=>
      #console.log "updating hints: errors "+@_markers.length
      @_clearMarkers()
      @_markers = []
      @editor.operation( ()=>
        #TODO: fetch errors from csg compiler?
        try
          errors = coffeelint.lint(@editor.getValue(), @settings.get("linting"))
          @vent.trigger("file:errors",errors)
          #console.log "errors:"
          #console.log errors
          if errors.length == 0
            @vent.trigger("file:noError")
          for i, error of errors
            errMsg = error.message
            if error.level == "warn"
              markerDiv= "<span class='CodeWarningMarker'> <a href='#' rel='tooltip' title=\" #{errMsg}\" > <i class='icon-remove-sign'></i></a></span> %N%"
            else if error.level == "error"
              markerDiv= "<span class='CodeErrorMarker'> <a href='#' rel='tooltip' title=\" #{errMsg}\" > <i class='icon-remove-sign'></i></a></span> %N%"
              
            marker = @editor.setMarker(error.lineNumber - 1, markerDiv)
            @_markers.push(marker)
        catch error
            #here handle any error not already managed by coffeelint
            errLine = error.message.split("line ")
            errLine = errLine[errLine.length - 1]
            errMsg = error.message
            markerDiv= "<span class='CodeErrorMarker'> <a href='#' rel='tooltip' title=\" #{errMsg}\" > <i class='icon-remove-sign'></i></a></span> %N%"
            try
              marker = @editor.setMarker(errLine - 1, markerDiv)
              @_markers.push(marker)
            catch error
              console.log "ERROR #{error} in adding error marker"
      )
      @applyStyles()
     # info = @editor.getScrollInfo()
     # after = @editor.charCoords({line: @editor.getCursor().line + 1, ch: 0}, "local").top
     # if (info.top + info.clientHeight < after)
     #   @editor.scrollTo(null, after - info.clientHeight + 3)
    
    #this could also be solved by letting the event listeners access the list of available undos & redos ?
    updateUndoRedo: () =>
      redos = @editor.historySize().redo
      undos = @editor.historySize().undo
      if redos >0
        @vent.trigger("file:redoAvailable", @)
      else
        @vent.trigger("file:redoUnAvailable", @)
      if undos >0
        @vent.trigger("file:undoAvailable", @)
      else
        @vent.trigger("file:undoUnAvailable", @)
        
    undo:=>
      undoes = @editor.historySize().undo
      if undoes > 0
        @editor.undo()
        
    redo:=>
      redoes = @editor.historySize().redo
      if redoes >0
        @editor.redo()
    
    onDomRefresh:=>
      @editor.refresh()
      
    setHeight:(height)=>
      @editor.getWrapperElement().style.height = height+ 'px';
      @editor.refresh()
      
    onRender: =>
      foldFunc = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)
      
      @editor = CodeMirror.fromTextArea @ui.codeBlock.get(0),
        theme: "lesser-dark"
        mode:"coffeescript"
        tabSize: 2
        indentUnit:2
        indentWithTabs:false
        lineNumbers:true
        gutter: true
        matchBrackets:true
        undoDepth: @settings.get("undoDepth")
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
            Tab:(cm)->
              cm.replaceSelection("  ", "end")
      
            
      @hlLine=  @editor.setLineClass(0, "activeline")
      
      setTimeout @editor.refresh, 0 #necessary hack
      @$el.attr('id', @model.get("name"))
      
  return FileCodeView