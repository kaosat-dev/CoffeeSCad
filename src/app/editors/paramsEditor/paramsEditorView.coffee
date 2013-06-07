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
  require 'slider'

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
      
      @autoUpdateBasedOnParams= true
      @preventUiRegen = true
      @_drawnOnce = false
      
    onDomRefresh:()=>
      $('.colorpicker').colorpicker().on('changeColor', @onColorChanged )
      $('.slider').slider().on('slide', @onSliderChanged )
      @$el.find('[rel=tooltip]').tooltip({'placement': 'right'})

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
    
    _componentToHex:(c)->
      hex = c.toString(16);
      return hex.length == 1 ? "0" + hex : hex

    _rgbaToHex:(r, g, b, a)->
      return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b) + componentToHex(a) 
    
    _hexToRgba:(hex)->
      # Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
      shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
      hex = hex.replace(shorthandRegex, (m, r, g, b, a)-> 
          return (r + r + g + g + b + b + a + a );
      )
      result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})?$/i.exec(hex);
      return {
          r: parseInt(result[1], 16),
          g: parseInt(result[2], 16),
          b: parseInt(result[3], 16),
          a: if result[4]? then parseInt(result[4], 16) else 1
        }

    
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
      console.log "Color name:", paramName," value",paramValue
      
      if not @project.meta.modParams?
        @project.meta.modParams={}
        for param of @project.meta.params
          @project.meta.modParams[param] = @project.meta.params[param]
      
      @project.meta.modParams[paramName] = paramValue
      
      if @autoUpdateBasedOnParams
        vent.trigger("project:compile")
      
    onSliderChanged:(e)=>
      console.log "slider change", e.value
      console.log e
      paramValue = e.value
      paramName  = e.currentTarget.id
      
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
        
        getParamValue= ( param )=>
          if @project.meta.modParams?
            if param.name of @project.meta.modParams
              paramValue = @project.meta.modParams[param.name]
            else
              paramValue = param.default
          else
            paramValue = param.default
          return paramValue
        
        for param in @project.meta.rawParams
          console.log "param",param
          paramValue = getParamValue( param )
          console.log "paramValue",paramValue
          
          toolTip = """<span><a href="#" data-toggle="tooltip" rel="tooltip" title="#{param.caption}"><i class="icon-question-sign icon-medium"/></a></span>"""
          
          switch param.type
            when "float", "int"
              rootEl.append("<div>#{param.name}<input type='number' value='#{paramValue}' id='#{param.name}' class='myParams'/>#{toolTip}</div>")
            when "checkbox"   
             rootEl.append("<div>#{param.name}&nbsp<input class='myParams' type='checkbox' id='#{param.name}' #{if param.default==true then 'checked' else ''}/>&nbsp#{toolTip}</div>")
            when "select"
              values = param.values.split(',')
              vals = ""
              for val in values
                vals += "<option value=#{val}>#{val}</option>"
              rootEl.append("<div>#{param.name}<select id='#{param.name}' class='myParams'> #{vals} </select>#{toolTip}</div>")
            when "color"
              if "#" in paramValue
                paramValue = @_hexToRgba(paramValue)
              rgbaValue = "rgba(#{paramValue.r}, #{paramValue.g}, #{paramValue.b}, #{paramValue.a})"
              
              rootEl.append(""" 
              <div>#{param.name}
              <div class="input-append color colorpicker" data-color="#{rgbaValue}" data-color-format="rgba" id='#{param.name}'>
                <input type="text" class="span2" value="#{rgbaValue}" readonly="">
                <span class="add-on"><i style="background-color: #{rgbaValue};"></i></span>
              </div>
              #{toolTip}</div>
              """)
            when "slider"
              rootEl.append(""" 
              <div>#{param.name}
              #{param.min}&nbsp<input id='#{param.name}' type="text" class="span2 slider" value="" 
                data-slider-min="#{param.min}" data-slider-max="#{param.max}" data-slider-step="#{param.step}" data-slider-value="#{paramValue}" 
                data-slider-orientation="horizontal" data-slider-selection="after"data-slider-tooltip="show" data-slider-handle="square">&nbsp#{param.max}
              
              #{toolTip}</div>
                """)
                    
        
        rootEl.append("<div><button class='applyParams'>Apply Params</button></div>")  
        rootEl.append("<div>Auto update<input class='autoUpdate' type='checkbox' #{if @autoUpdateBasedOnParams then 'checked' else ''} /></div>")    
          
        rootEl.append("<div>Do not regenerate ui <input class='preventUiRegen' type='checkbox' #{if @preventUiRegen then 'checked' else ''} /></div>")    
          
        @_drawnOnce = true
        @newRootEl = rootEl
        @render()
    
      
  return ParamsEditorView