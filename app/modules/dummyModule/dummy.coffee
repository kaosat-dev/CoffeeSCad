define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  
  class Dummy extends Backbone.Model
    defaults:
      name:     "mainPart"
      ext:      "coscad"
      content:  ""
    constructor:(options)->
      super options
  

  return Dummy