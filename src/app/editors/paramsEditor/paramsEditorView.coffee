define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'core/messaging/appVent'
  
  template =  require "text!./paramsEditorView.tmpl"
  
  require 'colorpicker'

  class ParamsEditorView extends Backbone.Marionette.Layout
    template: template
    className: "paramsEditor"
    
    events:
      "resize:start": "onResizeStart"
      "resize:stop": "onResizeStop"
      "resize":"onResizeStop"
      
      "change .myParams":"onParamChanged"
      "click .applyParams":"onParamsApply"
      "change .autoUpdate" : "onAutoUpdateChanged"
      "change .preventUiRegen" : "onPreventUiRegenChanged"
      
    constructor:(options)->
      super options
      @settings = options.settings
      @project = options.model
      @project.on("compiled:params", @onParamsGenerated)
      
      @autoUpdateBasedOnParams= false
      @preventUiRegen = true
      @_drawnOnce = false
      
    onDomRefresh:()=>
      #$('.colorpicker').colorpicker()
      $('.colorpicker').colorpicker().on('changeColor', @onColorChanged )

    onResizeStart:=>
      
    onResizeStop:=>

    onRender:=>
      
    render:=>
      @isClosed = false
      @triggerMethod("before:render", @)
      @triggerMethod("item:before:render", @)
      
      if @newRootEl?
        @$el.html("")
        @$el.append(@newRootEl)
   
      
      @bindUIElements()
      @triggerMethod("render", @)
      @triggerMethod("item:rendered", @)
      return @
    
    onAutoUpdateChanged:(e)=>
      autoUpdate = $(".autoUpdate").prop('checked')
      @autoUpdateBasedOnParams = autoUpdate
      console.log @autoUpdateBasedOnParams
    
    onPreventUiRegenChanged:=>
      preventUiRegen = $(".preventUiRegen").prop('checked')
      @preventUiRegen = preventUiRegen
      console.log @preventUiRegen
    
    onParamChanged:(e)=>
      console.log "param changed",e
      
      if $(e.srcElement).is('input:checkbox')
        paramValue = $(e.srcElement).prop('checked')
      else if $(e.srcElement).is('input:text')
        paramValue = e.srcElement.value
      else if $(e.srcElement).is('input')
        paramValue = e.srcElement.valueAsNumber
      else if $(e.srcElement).is('select')
        paramValue = $(e.srcElement).val()
        
      paramName = e.srcElement.id
      
      console.log "paramName",paramName, "paramValue",paramValue
      
      if not @project.meta.modParams?
        @project.meta.modParams={}
        for param of @project.meta.params
          @project.meta.modParams[param] = @project.meta.params[param]
      
      @project.meta.modParams[paramName] = paramValue
      
      if @autoUpdateBasedOnParams
        vent.trigger("project:compile")
    
    onColorChanged:(e)=>
      console.log "color change", e.color.toRGB()
      console.log e
      paramName  = e.currentTarget.id
      paramValue = e.color.toRGB()
      paramValue = [paramValue.r/255,paramValue.g/255, paramValue.b/255, paramValue.a]
      console.log "Color value",paramValue
      
      if not @project.meta.modParams?
        @project.meta.modParams={}
        for param of @project.meta.params
          @project.meta.modParams[param] = @project.meta.params[param]
      
      @project.meta.modParams[paramName] = paramValue
      
      if @autoUpdateBasedOnParams
        vent.trigger("project:compile")
      
    
    onParamsApply:()=>
      vent.trigger("project:compile")
    
    onParamsGenerated:=>
      if (not @preventUiRegen) or (@preventUiRegen and not @_drawnOnce)
        rootEl = $('<div>',{id: "paramsContainer"})
        for param in @project.meta.rawParams
          console.log "param",param
          switch param.type
            when "float", "int"
              if @project.meta.modParams?
                if param.name of @project.meta.modParams
                  paramValue = @project.meta.modParams[param.name]
                else
                  paramValue = param.default
              else
                paramValue = param.default
              rootEl.append("<div>#{param.name}<input type='number' value='#{paramValue}' id='#{param.name}' class='myParams'/>#{param.caption}</div>")
            when "checkbox"   
             rootEl.append("<div>#{param.name}&nbsp<input class='myParams' type='checkbox' id='#{param.name}' #{if param.default==true then 'checked' else ''}/>&nbsp#{param.caption}</div>")
            when "select"
              values = param.values.split(',')
              vals = ""
              for val in values
                vals += "<option value=#{val}>#{val}</option>"
              rootEl.append("<div>#{param.name}<select id='#{param.name}' class='myParams'> #{vals} </select>#{param.caption}</div>")
            when "color"
              paramValue = param.default
              rootEl.append("<div>#{param.name}<input id='#{param.name}' type='text' class='myParams colorpicker' value='#8fff00' />#{param.caption}</div>")
        
        rootEl.append("<div><button class='applyParams'>Apply Params</button></div>")  
        rootEl.append("<div>Auto update<input class='autoUpdate' type='checkbox' #{if @autoUpdateBasedOnParams then 'checked' else ''} /></div>")    
          
        rootEl.append("<div>Do not regenerate ui <input class='preventUiRegen' type='checkbox' #{if @preventUiRegen then 'checked' else ''} /></div>")    
          
        @_drawnOnce = true
        @newRootEl = rootEl
        @render()
    
      
  return ParamsEditorView