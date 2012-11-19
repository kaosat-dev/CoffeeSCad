define (require) ->
  marionette = require 'marionette'
  template = require "text!templates/mainContent.tmpl"
  #jquery_layout=  require 'jquery_layout'
  
  class MainContentLayout extends marionette.Layout
    template: template
    regions: 
      edit: "#edit"
      gl: "#gl"
    
    onRender:()=>
      paddingWrapper = @$el.find("#paddingWrapper")
      container = @$el.find("#container")
      #container.layout()
      #paddingWrapper.layout()
      #$('body').layout({ applyDemoStyles: true });
      #$@el.layout({ applyDemoStyles: true });
      #@$el.split({orientation:'vertical', limit:500})
      #class="ui-layout-center"
      
  return MainContentLayout
 