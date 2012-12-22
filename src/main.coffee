define (require)->
  app      = require 'app'
  Router   = require 'router'
  app.router = new Router()

  Backbone.history.start
    pushState: true
    root: app.root
  Backbone.history.loadUrl( Backbone.history.fragment )
  app.start()

  ###
  $(document).on "click", "a[href]:not([data-bypass])", (evt)->
    href = 
      prop: $(this).prop("href")
      attr: $(this).attr("href")
    root = location.protocol + "//" + location.host + app.root
    console.log "#{root}"
    console.log href.prop
    console.log href.attr

    if href.prop.slice(0, root.length) == root
      console.log "gere"
      evt.preventDefault()
      console.log "Navigating to #{href.attr}"
    
      Backbone.history.navigate(href.attr, true)
      return
  ###
