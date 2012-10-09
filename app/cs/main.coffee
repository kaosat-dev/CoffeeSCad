#require (["app", "router"]), (app, Router)->
define (require)->
  app      = require 'app'
  Router   = require 'router'
  Editor = require 'editor'
  coscad = require 'opencoffeescad'
  
  app.router = new Router()
  
  #app.store = new coscad.Store()
  app.cadViewer = new coscad.Viewer(document.getElementById("viewer"), 750,750)
  app.cadProcessor = new coscad.Processor(true, null, document.getElementById("statusBar"), app.cadViewer)
  app.cadEditor = new Editor()

  app.updateSolid()

  Backbone.history.start
    pushState: true
    root: app.root

  $(document).on "click", "a[href]:not([data-bypass])", (evt)->
    href = 
      prop: $(this).prop("href")
      attr: $(this).attr("href")
    root = location.protocol + "//" + location.host + app.root

    if href.prop.slice(0, root.length) == root
      evt.preventDefault()
      Backbone.history.navigate(href.attr, true)
      return
  
