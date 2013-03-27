define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  require 'bootstrap'
  require 'bootbox'
  require 'notify'
  
  vent = require 'modules/core/messaging/appVent'
  
  mainMenuMasterTemplate = require "text!./mainMenu.tmpl"
  
  mainMenuTemplate = _.template($(mainMenuMasterTemplate).filter('#mainMenuTmpl').html())
  recentFileTemplate = _.template($(mainMenuMasterTemplate).filter('#recentFileTmpl').html())
  
  
  class MainMenuView extends Backbone.Marionette.Layout
    template: mainMenuTemplate
    regions:
      recentProjects:   "#recentProjects"
      examplesStub:         "#examples"
      exportersStub:        "#exporters"
    
    ui: 
      exportersStub: "#exporters"
      storesStub: "#stores"
      
    events:
      "click .newProject":    ()->vent.trigger("project:new")
      "click .newFile":       ()->vent.trigger("project:file:new")
      "click .saveProjectAs": ()->vent.trigger("project:saveAs")
      "click .saveProject":   ()->vent.trigger("project:save")
      "click .loadProject":   ()->vent.trigger("project:load")
      "click .deleteProject": ()->vent.trigger("project:delete")
      "click .undo":          "onUndoClicked"
      "click .redo":          "onRedoClicked"
      
      "click .settings":      ()->vent.trigger("settings:show")
      "click .showEditor":    ()->vent.trigger("codeEditor:show")
      
      "click .compileProject"  : ()->vent.trigger("project:compile")
      
      "click .geometryCreator" : ()->vent.trigger("geometryEditor:show")
      
      "click .about" : "showAbout"
  
    constructor:(options)->
      super options
      @vent = vent
      @stores= options.stores ? {}
      @exporters= options.exporters ? {}
      
      #TODO: move this to data binding
      @vent.on("file:undoAvailable", @_onUndoAvailable)
      @vent.on("file:redoAvailable", @_onRedoAvailable)
      @vent.on("file:undoUnAvailable", @_onNoUndoAvailable)
      @vent.on("file:redoUnAvailable", @_onNoRedoAvailable)
      @vent.on("clearUndoRedo", @_clearUndoRedo)
        
      @vent.on("notify",@onNotificationRequested)
      @vent.on("project:loaded",()=>@_onNotificationRequested("Project:loaded"))
      @vent.on("project:saved",()=>@_onNotificationRequested("Project:saved"))
      @vent.on("project:compiled",()=>@_onNotificationRequested("Project:compiled"))
      @vent.on("project:loaded", @onProjectLoaded)
    
    _onNotificationRequested:(message)=>
      $('.notifications').notify(message: { text:message },fadeOut:{enabled:true, delay: 1000 }).show()
      
    _clearUndoRedo:=>
      $('#undoBtn').addClass("disabled")
      $('#redoBtn').addClass("disabled")
    _onUndoAvailable:=>
      $('#undoBtn').removeClass("disabled")
    _onRedoAvailable:=>
      $('#redoBtn').removeClass("disabled")
    _onNoUndoAvailable:=>
      $('#undoBtn').addClass("disabled")
    _onNoRedoAvailable:=>
      $('#redoBtn').addClass("disabled")
    
    _addExporterEntries:=>
      #add exporter entries to menu, and their event handlers
      for index, exporterName of @exporters
         className = "start#{index[0].toUpperCase() + index[1..-1]}Exporter"
         event = "#{index}Exporter:start"
         @events["click .#{className}"] = do(event)-> ->@vent.trigger(event)
         #see http://www.mennovanslooten.nl/blog/post/62 and http://rzrsharp.net/2011/06/27/what-does-coffeescripts-do-do.html
         #for more explanation (or lookup "anonymous functions inside loops")
         @ui.exportersStub.append("<li ><a href='#' class='#{className}'>#{index}</li>") 
           
    _addStoreEntries:=>
      #add store entries to menu, and their event handlers
      for index, store of @stores
         if store.isLogginRequired
           loginClassName = "login#{index[0].toUpperCase() + index[1..-1]}"
           loginEvent = "#{index}Store:login"
           @events["click .#{loginClassName}"] = do(loginEvent)-> ->@vent.trigger(loginEvent)
           
           logoutClassName = "logout#{index[0].toUpperCase() + index[1..-1]}"
           logoutEvent = "#{index}Store:logout"
           @events["click .#{logoutClassName}"] = do(logoutEvent)-> ->@vent.trigger(logoutEvent)
           
           do(index)=>
             onLoggedIn=()=>
               selector = "##{loginClassName}"
               $('.notifications').notify
                message: { text: "#{index}: logged IN" }
                fadeOut:{enabled:true, delay: 1000 }
               .show()
               
               $(selector).replaceWith("<li id='#{logoutClassName}' ><a href='#' class='#{logoutClassName}'><i class='icon-signout' style='color:green'/>  #{index} - Signed In</a></li>")
             
             onLoggedOut=()=>
               selector = "##{logoutClassName}"
               $('.notifications').notify
                message: { text: "#{index}: logged OUT" }
                fadeOut:{enabled:true, delay: 1000 }
               .show()
               $(selector).replaceWith("<li id='#{loginClassName}' ><a href='#' class='#{loginClassName}'><i class='icon-signin' style='color:red'/>  #{index} - Signed out</a></li>")
             
             @vent.on("#{index}Store:loggedIn",()->onLoggedIn())
             @vent.on("#{index}Store:loggedOut",()->onLoggedOut())
           
           @ui.storesStub.append("<li id='#{loginClassName}'><a href='#' class='#{loginClassName}'><i class='icon-signin' style='color:red'/>  #{index} - Signed Out</a></li>") 
    
    onDomRefresh:=>
      @$el.find('[rel=tooltip]').tooltip({'placement': 'bottom'})
      @_addExporterEntries()
      @_addStoreEntries()
      @delegateEvents()
    
    onRedoClicked:=>
      if not ($('#redoBtn').hasClass("disabled"))
        @vent.trigger("file:redoRequest")
    
    onUndoClicked:->
      console.log $('#undoBtn')
      if not ($('#undoBtn').hasClass("disabled"))
        console.log "triggering undo Request"
        @vent.trigger("file:undoRequest")
    
    _fetchFiles:=>
      #just experimenting
      serverUrl = window.location.href
      examplesUrl = "#{serverUrl}/examples"
      console.log "ServerURL : #{serverUrl}"
      $.get "#{examplesUrl}", (data) =>
        console.log "totot"
        console.log data
        
    showAbout:(ev)=>
      bootbox.dialog """<b>Coffeescad v0.3</b> (pre-alpha)<br/><br/>
      Licenced under the MIT Licence<br/>
      @2012-2013 by Mark 'kaosat-dev' Moissette
      """, [
          label: "Ok"
          class: "btn-inverse"
        ],
        "backdrop" : false
        "keyboard":   true
        "animate":false

  class RecentFileView extends Backbone.Marionette.ItemView
    template: recentFileTemplate
    tagName:  "li"
    
    onRender:()=>
      @$el.attr("id",@model.name)
  
  class RecentFilesView extends Backbone.Marionette.CollectionView
    
  class ExamplesView extends Backbone.Marionette.ItemView
    
    constructor:->
      #examples = require "modules/examples"
      #{Library,Project,ProjectFile} = require "modules/project"
      @examplesList = {
        "basics": {
            "Basic": {
                "files": [
                    "basic.coffee"
                ]
            },
            "MultiFile": {
                "files": [
                    "MultiFile.coffee",
                    "config.coffee"
                ]
            },
            "Includes": {
                "files": [
                    "Includes.coffee",
                    "config.coffee"
                ]
            }
        },
        "geometry": {
            "2dGeometry": {
                "files": [
                    "2dGeometry.coffee"
                ]
            },
            "3dGeometry": {
                "files": [
                    "3dGeometry.coffee"
                ]
            }
        },
        "transforms": {
            "BasicTransforms": {
                "files": [
                    "BasicTransforms.coffee"
                ]
            },
            "BooleanOperations": {
                "files": [
                    "BooleanOperations.coffee"
                ]
            },
            "Extras": {
                "files": [
                    "Extras.coffee"
                ]
            }
        },
        "objectOriented":{
            "Basics": {
                "files": [
                    "Basics.coffee"
                ]
            }
        }
      }
    
    loadExample:(ev)=>
      #TOTAL HACK !! yuck
      index = ev.currentTarget.id
      project = new Project({name:examples[index].name})  
      for fileName in @examplesList[index]
        project.addFile
          name: "mainPart"
          ext: "coscad"
          content: examples[index].content    
    
    onRender:()->
      @ui.examplesList.html("")
      for index,example of examples
        @ui.examplesList.append("<li id='#{index}' class='exampleProject'><a href=#> #{example.name}</a> </li>")

  return MainMenuView