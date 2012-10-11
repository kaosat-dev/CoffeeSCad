#require (["app", "router"]), (app, Router)->
define (require)->
  app      = require 'app'
  Router   = require 'router'
  #Editor = require 'editor'
  #coscad = require 'opencoffeescad'
  #projectMod = require 'modules/Project'
  
  app.router = new Router()
  
  #app.store = new coscad.Store()
  #app.cadViewer = new coscad.Viewer(document.getElementById("viewer"), 750,750)
  #app.cadProcessor = new coscad.Processor(true, null, document.getElementById("statusBar"), app.cadViewer)
  #app.cadEditor = new Editor()

  #app.updateSolid()
  
  ###
  file = new projectMod.ProjectFile()
  file.bla("yeah")
  console.log(file)
  file.bli("yop")
  console.log(file)
  file.set "name", "uuuurgh"
  ###
  #file.name "uuuurgh"

  Backbone.history.start
    pushState: true
    root: app.root

  app.start()
  #app.vent.trigger "tutu"

  $(document).on "click", "a[href]:not([data-bypass])", (evt)->
    href = 
      prop: $(this).prop("href")
      attr: $(this).attr("href")
    root = location.protocol + "//" + location.host + app.root

    if href.prop.slice(0, root.length) == root
      evt.preventDefault()
      Backbone.history.navigate(href.attr, true)
      return
  
