define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'forms'
  forms_bstrap= require 'forms_bootstrap'
  
  class GlViewSettingsForm extends Backbone.Form
    
    constructor:(options)->
      if not options.schema
        options.schema=
          csgRenderMode: 
            title: "Render trigger mode"
            type: 'Select'
            options : ["onDemand", "onCodeChange", "onCodeChangeDelayed", "onSave"]
          csgRenderDelay:
            type: 'Number'
          
          renderer     :
            type: 'Select'
            options : ["webgl", "canvas"]
          antialiasing : 'Checkbox'
          shadows      : 'Checkbox'
          selfShadows  : 
            type:       'Checkbox'
            title:      'Object self shadowing'
          
          showAxes     : 'Checkbox' 
          showConnectors: 'Checkbox'
          showGrid     : 'Checkbox' 
          gridSize     : 'Number'  
          gridStep     : 'Number'
          gridColor    : 'Text'
          gridOpacity  : 'Number'
          
          showStats    : 'Checkbox'
          position     :
            type: 'Select'
            options: ['diagonal', 'top', 'bottom', 'front', 'back', 'left', 'right', 'center'] 
          
          projection   :
            type: 'Select'
            options: ['perspective', 'orthographic']
          
          center: 'Checkbox'
          
          wireframe    : 'Checkbox'
          
          helpersColor :  'Text'
          bgColor : 
            title: "background color"
            type: 'Text'
          bgColor2 : 
            title: "background color2 (gradient)" 
            type: 'Text'
            #options: ['solid', 'gradient']
            
        options.fieldsets=[
          "legend": "CsgRender settings"
          "fields": ["csgRenderMode","csgRenderDelay"]
        ,
          "legend":"Render settings"
          "fields": ["renderer","antialiasing","shadows","selfShadows"]
        , 
          "legend":"View settings"
          "fields": ["position","projection","center","wireframe"]
        ,
          "legend":"Axes and Grid settings"
          "fields": ["showAxes","helpersColor","showConnectors", "showGrid","gridSize","gridStep","gridColor","gridOpacity"]
        , 
          "legend":"Extra settings"
          "fields": ["bgColor","bgColor2", "showStats"]
          
        ]
      super options
      
  
  class VisEditorSettingsView extends Backbone.Marionette.ItemView
    
    events:
      'change #c6_csgRenderMode': "tutu"
    
    constructor:(options)->
      super options
      @wrappedForm = new GlViewSettingsForm
        model: @model
      
    ui:
      csgRenderMode:    "#c6_csgRenderMode"    
      
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
      
    tutu:(bla)=>
      console.log bla
      console.log "gne INDEED"
      
  return VisEditorSettingsView