define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  Wreqr = require 'wreqr'
  
  
  return new Backbone.Wreqr.RequestResponse()

