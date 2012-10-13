define (require) ->
  marionette = require 'marionette'
  template = require "text!templates/mainContent.tmpl"
  

  class MainContentLayout extends marionette.Layout
    template: template
    regions: 
      edit: "#edit"
      gl: "#gl"
      
  return MainContentLayout
 