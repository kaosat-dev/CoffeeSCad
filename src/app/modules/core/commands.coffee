define (require)->
  marionette = require 'marionette'


  ###
  @vent.bind("downloadStlRequest", stlexport)#COMMAND
  @vent.bind("fileSaveRequest", saveProject)#COMMAND
  @vent.bind("fileLoadRequest", loadProject)#COMMAND
  @vent.bind("fileDeleteRequest", deleteProject)#COMMAND
  @vent.bind("editorShowRequest", showEditor)#COMMAND
  ###

  """Exploring backbone marionettes' commands"""
  class Commands extends Backbone.Wreqr.Commands
    constructor:(options)->
      super options
  commands = new Commands()
  commands.addHandler "foo", ()->
    console.log("the foo command was executed")
   
  return commands
