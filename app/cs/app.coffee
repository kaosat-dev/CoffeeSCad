define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  require 'bootstrap'


  app = new marionette.Application
    root: "/opencoffeescad"
    cadProcessor: null
    cadEditor: null
    cadViewer: null
    projectName: "MyProject"
    codeUpdated: true
    updateSolid: () ->
      app.cadProcessor.setCoffeeSCad(app.cadEditor.getValue())
    
  # Mix Backbone.Events, modules, and layout management into the app object.
  ###return _.extend app,
    module: (additionalProps)->
      return _.extend
        Views: {}
        additionalProps
  ###