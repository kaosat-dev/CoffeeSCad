define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'backbone-forms'
  
  class GlViewSettingsForm extends Backbone.Form
    
    constructor:(options)->
      if not options.schema
        options.schema=  
          renderer     :
            type: 'Select'
            options : ["webgl", "canvas"]
          antialiasing : 'Checkbox'
          shadows      : 'Checkbox'
          shadowResolution: 
            title: 'Shadow resolution (restart required)'
            type: 'Select'
            options : ["256x256", "512x512","1024x1024","2048x2048","4096x4096"]
            
          selfShadows  : 
            type:       'Checkbox'
            title:      'Object self shadowing'
          
          showAxes     : 'Checkbox' 
          showConnectors: 'Checkbox'
          showGrid     : 'Checkbox' 
          gridSize     : 'Number'  
          gridStep     : 'Number'
          gridColor    : 'Text'
          gridOpacity  : {type:'Number', editorAttrs: { step: 0.1, min: 0, max: 1 } }
          gridText     : 'Checkbox'
          gridNumberingPosition :
            title : 'Grid numbering position'
            type:'Select'
            options:['center','border']
          
          showStats    : 'Checkbox'
          position     :
            type: 'Select'
            options: ['diagonal', 'top', 'bottom', 'front', 'back', 'left', 'right', 'center'] 
          
          projection   :
            type: 'Select'
            options: ['perspective', 'orthographic']
          
          center: 'Checkbox'
          
          objectViewMode :
            title : 'object rendering'
            type:'Select'
            options:['shaded','wireframe','structural']
          
          helpersColor :  'Text'
          bgColor : 
            title: "background color"
            type: 'Text'
          bgColor2 : 
            title: "background color2 (gradient)" 
            type: 'Text'
            #options: ['solid', 'gradient']
          textColor:
            type: 'Text'
          axesSize: 'Number'
            
        options.fieldsets=[
          "legend":"Render settings"
          "fields": ["renderer","antialiasing","shadows","shadowResolution","selfShadows","objectViewMode"]
        , 
          "legend":"View settings"
          "fields": ["position","projection","center"]
        ,
          "legend":"Axes and Grid settings"
          "fields": ["showAxes","helpersColor","showConnectors", "showGrid","gridSize","gridStep","gridColor","gridOpacity","gridText","gridNumberingPosition"]
        , 
          "legend":"Extra settings"
          "fields": ["bgColor","bgColor2", "textColor", "axesSize", "showStats"]
          
        ]
      super options
      
  
  class VisualEditorSettingsView extends Backbone.Marionette.ItemView
    
    constructor:(options)->
      super options
      @wrappedForm = new GlViewSettingsForm
        model: @model
      
    render:()=>
      if @beforeRender then @beforeRender()
      @trigger("before:render", @)
      @trigger("item:before:render", @)
      
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))

      @bindUIElements()
      if @onRender then @onRender()
      @trigger("render", @)
      @trigger("item:rendered", @)
      return @
      
  return VisualEditorSettingsView