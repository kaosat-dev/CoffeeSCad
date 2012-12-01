define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'
  mainMenu_template = require "text!templates/mainMenu.tmpl"
  sF_template = require "text!templates/menuFiles.tmpl"
  
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
      dirtyStar: "#dirtyStar"

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
      #fileName = $(ev.currentTarget).html()
      console.log ("show editor1")
      @app.vent.trigger("editorShowRequest")
      
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
      #(@model, "cleaned", @modelSaved)
      @render()
      
    modelChanged: (model, value)=>
      @ui.dirtyStar.text "*"
     
    modelSaved: (model)=>
      @ui.dirtyStar.text ""
      
  return MainMenuView