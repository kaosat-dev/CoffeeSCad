define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  marionette = require 'marionette'
  
  
  class LibraryModule extends Backbone.Marionette.Controller

    constructor: (options)->


    _CreateNewProject:()=>
      @project = new Project({name:'TestProject'}) 
      ########VIEW UPDATES
      @mainMenuView.switchModel @project
      @codeEditorView.switchModel @mainPart
      @glThreeView.switchModel @mainPart
    
    _loadProject:(name)=>    
      #console.log("Loading part: #{name}")
      if name != @project.get("name")
        project = @lib.fetch({id:name})
        @project = project
        @mainPart = project.pfiles.at(0)
        @project.add @mainPart
        @lib.add @project
        ########VIEW UPDATES
        @codeEditorView.switchModel @mainPart 
        @glThreeView.switchModel @mainPart
        @mainMenuView.switchModel @project
      else
        console.log "Project already loaded"
      return
    
    _SaveProject:(name)=>
      @project.save()
      #hack to ensure the various sub files(only the one for now) are saved aswell: this should be done within the project class'
      #save method
      @mainPart.save()
      ########VIEW UPDATES
      @mainMenuView.model = @project
       
    newProject:()=>
      if @project.dirty
        bootbox.dialog "Project is unsaved, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @_CreateNewProject()
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
      else
        @_CreateNewProject()
        
    saveProject:(params)=>
      if @project.get("name") == params
        @SaveProject()
      else
        foundProjects = @lib.get(params)
        if foundProjects?
          bootbox.dialog "Project already exists, overwrite?", [
            label: "Ok"
            class: "btn-inverse"
            callback: =>
              @project.set("name",params)
              @lib.add @project
              @_SaveProject()
          ,
            label: "Cancel"
            class: "btn-inverse"
            callback: ->
          ]
          
        else
          @project.set("name",params)
          @lib.add @project
          @_SaveProject()
      return      
      
    loadProject:(name)=>
      #first check if a the current project is dirty/modified (don't want to loose work !)
      if @project.dirty
        bootbox.dialog "Project is unsaved, proceed anyway?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @_loadProject(name)
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
       else
        @_loadProject(name)
        
    deleteProject:(name)=>
      @project.destroy()
      @lib.remove(@project)
      for i,model of @project.pfiles.models
        model.destroy()
      #FIXME: yuck, ugly hack to remove the complete collection too
      localStorage.removeItem(@project.pfiles.localStorage.name)
      #ReCreate Fresh project and part
      @project = new Project({name:'TestProject'}) 
      @mainPart = new ProjectFile()
      @project.add @mainPart 
      ########VIEW UPDATES
      @mainMenuView.switchModel @project
      @codeEditorView.switchModel @mainPart 
      @glThreeView.switchModel @mainPart
      return