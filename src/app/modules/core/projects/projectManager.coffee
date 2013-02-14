define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  
  PreProcessor = require "./preprocessor"
  CsgProcessor = require "./csg/processor"