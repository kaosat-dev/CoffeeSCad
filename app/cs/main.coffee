define (require)->
  app      = require 'app'
  Router   = require 'router'
  
  app.router = new Router()

  Backbone.history.start
    pushState: true
    root: app.root

  app.start()

###
  $(document).on "click", "a[href]:not([data-bypass])", (evt)->
    href = 
      prop: $(this).prop("href")
      attr: $(this).attr("href")
    root = location.protocol + "//" + location.host + app.root

    if href.prop.slice(0, root.length) == root
      evt.preventDefault()
      Backbone.history.navigate(href.attr, true)
      return
###

###
require ["jquery", "underscore", "backbone", "marionette", 'router', "MyApp"], ($, _, Backbone, Marionette, Router, MyApp) ->
  MyApp.router = new Router()
  Backbone.history.start
    pushState: true
    root: MyApp.root

  MyApp.start()
###