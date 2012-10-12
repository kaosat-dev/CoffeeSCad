define (require) ->
  lightgl = require 'lightgl'
  csg = require 'csg'
  marionette = require 'marionette'
  threedView_template = require "text!templates/3dview.tmpl"
  
  
  class ThreeGlView extends marionette.ItemView
    template: threedView_template

  return ThreeGlView
