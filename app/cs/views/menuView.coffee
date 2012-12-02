define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  require 'bootbox'
  mainMenu_template = require "text!templates/mainMenu.tmpl"
  sF_template = require "text!templates/menuFiles.tmpl"
  
  #FIXME: temporary, needs cleanup
  examples = require "modules/examples"
  {Library,Project,ProjectFile} = require "modules/project"
  
  class RecentFilesView extends Backbone.Marionette.ItemView
    template: sF_template
    tagName:  "li"
    
    onRender:()=>
      @$el.attr("id",@model.get("name"))
  
  class MainMenuView extends marionette.CompositeView
    template: mainMenu_template
    tagName:  "ul"
    itemView: RecentFilesView
    itemViewContainer: "#recentFilesList"
    ui:
      dirtyStar:    "#dirtyStar"
      examplesList: "#examplesList"

    triggers: 
      "mouseup .newFile":     "file:new:mouseup"
      "mouseup .saveFile":    "file:save:mouseup"
      "mouseup .saveFileAs":  "file:saveas:mouseup"
      "mouseup .loadFile":    "file:load:mouseup"
      "mouseup .newProject":  "project:new:mouseup"
      "mouseup .settings":    "settings:mouseup"
      "mouseup .undo":        "file:undo:mouseup"
      "mouseup .redo":        "file:redo:mouseup"
      "mouseup .parseCSG"  :  "csg:parserender:mouseup"
      "mouseup .downloadStl" :"download:stl:mouseup"
      
    
     events: 
      "mouseup .loadFileDirect":    "requestFileLoad"
      "mouseup .showEditor":        "showEditor"
      "mouseup #aboutBtn":          "showAbout"
      "mouseup .exampleProject":     "loadExample"
      
     templateHelpers:
       dirtyStar: ()=>
         if @model?
          if @model.dirty then return "*" else return ""
         else
          return ""
    
    requestFileLoad:(ev)=>
      fileName = $(ev.currentTarget).html()
      @app.vent.trigger("fileLoadRequest", fileName)
    
    showEditor:(ev)=>
      @app.vent.trigger("editorShowRequest")
      
    showAbout:(ev)=>
      bootbox.dialog """<b>Coffeescad v0.1</b> (experimental)<br/><br/>
      Licenced under the MIT Licence<br/>
      @2012 by Mark 'kaosat-dev' Moissette
      
      """, [
          label: "Ok"
          class: "btn-inverse"
        ],
        "backdrop" : false
        "keyboard":   true
        "animate":false
      
    constructor:(options)->
      super options
      @app = require 'app'
      
      @bindTo(@model, "change", @modelChanged)
      @bindTo(@model, "allSaved", @modelSaved)
      
      @on "file:new:mouseup" ,=>
        @app.vent.trigger("fileNewRequest", @)
      @on "file:undo:mouseup" ,=>
        if not  $('#undoBtn').hasClass "disabled"
          @app.vent.trigger("undoRequest", @)
      @on "file:redo:mouseup" ,=>
        if not  $('#redoBtn').hasClass "disabled"
          @app.vent.trigger("redoRequest", @)
      @on "csg:parserender:mouseup" ,=>
        if not  $('#updateBtn').hasClass "disabled"
          @app.vent.trigger("parseCsgRequest", @)
      @on "download:stl:mouseup" ,=>
        if not $('#exportStl').hasClass "disabled"
          @app.vent.trigger("downloadStlRequest", @) 
        
      @app.vent.bind "undoAvailable", ->
        $('#undoBtn').removeClass("disabled")
      @app.vent.bind "redoAvailable", ->
        $('#redoBtn').removeClass("disabled")
      @app.vent.bind "undoUnAvailable", ->
        $('#undoBtn').addClass("disabled")
      @app.vent.bind "redoUnAvailable", ->
        $('#redoBtn').addClass("disabled")
      @app.vent.bind "clearUndoRedo", ->
        $('#undoBtn').addClass("disabled")
        $('#redoBtn').addClass("disabled")
      @app.vent.bind "modelChanged", ->
        $('#updateBtn').removeClass("disabled")
        $('#exportStl').addClass("disabled")
      @app.vent.bind "parseCsgDone", ->
        $('#updateBtn').addClass("disabled")
        $('#exportStl').removeClass("disabled")
      
      @app.vent.bind "stlGenDone", (blob)=>
        tmpLnk = $("#exportStlLink")
        fileName = @app.project.get("name")
        tmpLnk.prop("download", "#{fileName}.stl")
        tmpLnk.prop("href", blob)
        
    switchModel:(newModel)->
      #replace current model with a new one
      #@unbindFrom(@model) or @unbindAll() ?
      @model = newModel
      @bindTo(@model, "dirtied", @modelChanged)
      @bindTo(@model, "allSaved", @modelSaved)
      @render()
      
    modelChanged: (model, value)=>
      @ui.dirtyStar.text "*"
     
    modelSaved: (model)=>
      @ui.dirtyStar.text ""
    
    loadExample:(ev)=>
      #TOTAL HACK !! yuck
      index = ev.currentTarget.id
      project = new Project({name:examples[index].name})  
      mainPart = new ProjectFile
          name: "mainPart"
          ext: "coscad"
          content: examples[index].content    
      project.add mainPart
      
      ########VIEW UPDATES
      if @app.project.dirty
        bootbox.dialog "Project is unsaved, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @app.project = project
            @app.mainPart= mainPart
            @app.codeEditorView.switchModel @app.mainPart
            @app.glThreeView.switchModel @app.mainPart
            @app.mainMenuView.switchModel @app.project
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      else
        @app.project = project
        @app.mainPart= mainPart
        @app.codeEditorView.switchModel @app.mainPart
        @app.glThreeView.switchModel @app.mainPart
        @app.mainMenuView.switchModel @app.project
    
    onRender:()->
      @ui.examplesList.html("")
      for index,example of examples
        @ui.examplesList.append("<li id='#{index}' class='exampleProject'><a href=#> #{example.name}</a> </li>")
      
  return MainMenuView