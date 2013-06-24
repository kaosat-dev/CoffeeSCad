define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  CoffeeScript = require 'CoffeeScript'
  require 'coffeelint'
  
  vent = require 'core/messaging/appVent'
  codeEditor_template = require "text!./fileCodeViewAce.tmpl"

  class FileCodeView extends Backbone.Marionette.ItemView
    template: codeEditor_template
    className: "tab-pane"
    ui:
      codeBlock : "#codeArea"
      infoFooter: "#infoFooter"
      
    constructor:(options)->
      super options
      @vent = vent
      @settings = options.settings
      @editor = null
      
      @_compileErrorsMarkers = [] #gets reset on each compile
      @_lintErrorsMarkers = []
     
      @_setupEventHandlers()
    
    _setupEventHandlers: =>
      console.log "my model", @model
      @model.on("change:content", @modelChanged)
      @model.on("saved", @modelSaved)
      @settings.on("change", @settingsChanged)
      
      @vent.on("file:closed", @onFileClosed)
      @vent.on("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.on("file:undoRequest", @undo)
      @vent.on("file:redoRequest", @redo)
      
      @vent.on("project:compiled",@_onProjectCompiled)
      @vent.on("project:compile:error",@_onProjectCompileError)
      #hack to fix annoying resize bug
      @vent.on("codeEditor:refresh",@onRefreshRequested)
    
    _tearDownEventHandlers:=>
      #cleanup all events
      @model.off("change", @modelChanged)
      @model.off("saved", @modelSaved)
      @settings.off("change", @settingsChanged)
      
      @vent.off("file:closed", @onFileClosed)
      @vent.off("file:selected", @onFileSelected)
      
      #TODO: these are commands, not events
      @vent.off("file:undoRequest", @undo)
      @vent.off("file:redoRequest", @redo)
      
      @vent.off("project:compiled",@_onProjectCompiled)
      @vent.off("project:compile:error",@_onProjectCompileError)
      #hack to fix annoying resize bug
      @vent.off("codeEditor:refresh",@onRefreshRequested)
    
    
    onRefreshRequested:(newHeight)=>
      #elHeight
      #console.log "on refresh", newHeight
      @$el.height(newHeight)
      @editor.resize()    
    
    onFileSelected:(model)=>
      @vent.off("project:compiled",@_onProjectCompiled)
      @vent.off("project:compile:error",@_onProjectCompileError)
      @vent.off("codeMirror:refresh",@onRefreshRequested)
      
      if model == @model
        @$el.addClass('active')
        @$el.removeClass('fade')
        #temporarhack, needed because of rendering issues forcing to re-render, but thus loosing undo history
        #history = @editor.getHistory()
        #@render()
        #@editor.setHistory history
        
        #@editor.refresh()
        #@updateUndoRedo()
        #@_updateHints()
        @editor.resize()
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
      @_tearDownEventHandlers()
    
    switchModel:(newModel)->
      console.log "switchin'"
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @editor.setValue(@model.get("content"))
      @vent.trigger("clearUndoRedo", @)
      #@undoManager.reset()
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "saved", @modelSaved)
      
    modelChanged: (model, value)=>
      console.log "hey , my model has changed"
      @applyStyles()
      #we have to de/re activate event bindings to avoid infinite event triggering
      @editor.off("change", @_onEditorContentChange)
      @editor.setValue(@model.content)
      @editor.clearSelection()
      @editor.on("change", @_onEditorContentChange)
      
    modelSaved: (model)=>  
      
    applyStyles:=>  
      @$el.find('[rel=tooltip]').tooltip({'placement': 'right'})
      
    settingsChanged:(settings, value)=> 
      for key, val of @settings.changedAttributes()
        switch key
          when "fontSize"
            #.style.fontSize='12px';
            $(".codeEditorBlock").css("font-size","#{val}em")
          when "theme" 
            themePath = "./theme/#{val}"
            @editor.setTheme(themePath)
          when "autoClose"
            @editor.setBehavioursEnabled(val)
          when "hightlightLine"
            @editor.setHighlightActiveLine(val)
          when "showInvisibles"
            @editor.setShowInvisibles(val)
          when "showIndentGuides"
            @editor.setDisplayIndentGuides(val)
          when "showGutter"
            @editor.renderer.setShowGutter(val)
          when "doLint"
            @editor.getSession().setUseWorker(val)
      
            
          #when "startLine"
          #  @editor.setOption("firstLineNumber",val)
          #  @render()
          #when "smartIndent"
          #  @editor.setOption("smartIndent",val)
          #when "linting"
          #  @_updateHints()
          
         
    
    _onProjectCompiled:=>
      @_clearErrorMarkers()
      
    _onProjectCompileError:(compileResult)=>
      @_clearErrorMarkers()
      for i, error of compileResult.errors
        errorMsg = error.message
        errorLine = if error.location? then error.location.first_line-1 else 0
        errorLevel = "error"
        if not isNaN(errorLine)
          marker = {row: errorLine, column: 0, html:"#{errorMsg}", type:"error"}
          #marker = @_processError(errorMsg, errorLevel, errorLine)
          @_compileErrorsMarkers.push(marker)
          
      @editor.getSession().setAnnotations(@_compileErrorsMarkers)
      @applyStyles()
      
    _clearAllMarkers:=>
      @_compileErrorsMarkers = []
      @_lintErrorsMarkers = []
      @editor.getSession().clearAnnotations()
      
    _clearErrorMarkers:=>
      ###
      for marker in @_compileErrorsMarkers
        @editor.setGutterMarker(marker.line,"lintAndErrorsGutter",  null)###
      @_compileErrorsMarkers = []
      
    _clearLintMarkers:=>
      
      #for marker in @_lintErrorsMarkers
      #  @editor.setGutterMarker(marker.line,"lintAndErrorsGutter",  null)
      @_lintErrorsMarkers = []
    
    _processError:(errorMsg, errorLevel, errorLine)=>
      #displays errors/warnings generated by the code inside the adapted gutter, returns a marker
      markerDiv= document.createElement("span")
      markerDiv$ = $(markerDiv)
      escape=(s)-> (''+s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
      .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')#.replace('"',"'")
      
      if errorLevel == "warn"
        markerDiv$.addClass("CodeWarningMarker") 
        markerMarkup= "<a href='#' rel='tooltip' title=\"#{escape errorMsg}\"> <i class='icon-remove-sign'></i></a>"
      else if errorLevel == "error"
        markerDiv$.addClass("CodeErrorMarker")
        markerMarkup= "<a href='#' rel='tooltip' title=\"#{escape errorMsg}\"> <i class='icon-remove-sign'></i></a>"
      
      markerDiv$.html(markerMarkup)
      marker = @editor.setGutterMarker(errorLine,"lintAndErrorsGutter",  markerDiv)
      marker.line = errorLine
      
      @editor.getSession().setAnnotations([{row: errorLine, column: 0, html:"#{errorMsg}", type:"error"}])
      
      return marker
    
    _updateHints:=>
      @_clearLintMarkers()
      try
        errors = coffeelint.lint(@editor.getValue(), @settings.get("linting"))
        if errors.length == 0
          @vent.trigger("file:noError")
        else
          @vent.trigger("file:errors",errors)
        for i, error of errors
          errorMsg = error.message
          errorLine = error.lineNumber-1
          errorLevel = error.level
          if not isNaN(errorLine)
            marker = @_processError(errorMsg, errorLevel, errorLine)
            @_lintErrorsMarkers.push(marker)
          
      catch error
        #here handle any error not already managed by coffeelint
        errorLine = error.message.split("line ")
        errorLine = parseInt(errorLine[errorLine.length - 1],10)-1
        errorMsg = error.message
        
        if not isNaN(errorLine)
          marker = @_processError(errorMsg, "error", errorLine)
          @_lintErrorsMarkers.push(marker)  
        ###
        try
        catch error
          console.log "ERROR #{error} in adding error marker"
        ###
      @applyStyles()
      
      #@editor.getSession().setAnnotations([{row: 1, column: 0, html:"foo<br/>bar", type:"error"}])
      #editor.getSession().addGutterDecoration(0,"error_line");

    #this could also be solved by letting the event listeners access the list of available undos & redos ?
    updateUndoRedo: () =>
      if @undoManager.hasRedo()
        @vent.trigger("file:redoAvailable", @)
      else
        @vent.trigger("file:redoUnAvailable", @)
      if @undoManager.hasUndo()
        @vent.trigger("file:undoAvailable", @)
      else
        @vent.trigger("file:undoUnAvailable", @)
        
    undo:=>
      if @undoManager.hasUndo()
        @editor.undo()
        
    redo:=>
      if @undoManager.hasRedo()
        @editor.redo()
    
    _onEditorContentChange:(cm, change)=>
      @model.off("change:content", @modelChanged)
      @model.content = @editor.getValue()
      @model.on("change:content", @modelChanged)
      @updateUndoRedo()
    
    _setupEditorEventHandlers:=>
      
      @editor.on("change", @_onEditorContentChange)
      
      @editor.getSession().selection.on 'changeCursor', (ev, selection) =>
        cursor = selection.anchor
        infoText = "Line: #{cursor.row} Column: #{cursor.column}"
        @ui.infoFooter.text(infoText)
      
    onRender:=>
      $(".codeEditorBlock").css("font-size","#{@settings.get('fontSize')}em")
    
    onDomRefresh:=>
      ace = require 'ace/ace'
      @editor = ace.edit(@ui.codeBlock.get(0))
      themePath = "./theme/#{@settings.theme}"
      @editor.setTheme(themePath)
      @editor.getSession().setMode("./mode/coffee")
      @editor.getSession().setTabSize(2)
      @editor.setBehavioursEnabled(@settings.autoClose)
      @editor.setHighlightActiveLine(@settings.hightlightLine)
      @editor.setShowInvisibles(@settings.showInvisibles)
      @editor.setDisplayIndentGuides(@settings.showIndentGuides)
      @editor.renderer.setShowGutter(@settings.showGutter)
      @editor.getSession().setUseWorker(@settings.doLint)
      
      UndoManager = require("ace/undomanager").UndoManager
      @editor.getSession().setUndoManager(new UndoManager())
      @undoManager = @editor.getSession().getUndoManager()
      
      @editor.resize()    
      
      
      #undo_manager = ace.getSession().getUndoManager();
      #undo_manager.reset();
      #ace.getSession().setUndoManager(undo_manager);
      ### 
      require ['ace/ace'], (ace)=>
        @editor = ace.edit(@ui.codeBlock.get(0))
        @editor.setTheme("./theme/monokai")
        @editor.getSession().setMode("./mode/coffee")
      ###
      @_setupEditorEventHandlers()
      
      
  return FileCodeView