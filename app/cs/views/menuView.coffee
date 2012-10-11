define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  mainMenu_template = require "text!templates/mainMenu.tmpl"
  
  class MainMenuView extends marionette.CompositeView
    template: mainMenu_template

    triggers: 
      "click .newFile":   "file:new:clicked"
      "click .saveFile":  "file:save:clicked"
      "click .loadFile":  "file:load:clicked"
 
    get_recentProjects = () ->
      for index, project of store.get_files("local")
        value = project
        item = "<li><a tabindex='-1' href='#' >#{value}</a></li>"
        $('#recentFilesList').append(item)
        $('#fileLoadModalFileList').append(item)     
      
    onBeforeRender:() =>
      

      
    onRender: =>
      
  return MainMenuView