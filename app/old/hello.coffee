define (require)->
  Backbone = require 'backbone'

  class HelloView extends Backbone.View
    template: require '../templates/hello.js'

    render: =>
      @$el.hide()
      @$el.html @template()
      @$el.fadeIn 1000
      @