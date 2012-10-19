define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  

  class SettingsTest extends Backbone.Model
    id:1
    defaults:
      maxRecentDisplay:  5
      tutu: 'crinoline'
    localStorage: new Backbone.LocalStorage("TestSettings")
      
    constructor:(options)->
      super options
      #@title = "General"
      #@set "title", @title
      

  return SettingsTest