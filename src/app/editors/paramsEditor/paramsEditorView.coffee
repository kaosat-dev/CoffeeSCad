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
      "change .color-text": "onColorTextChanged"
      "input .color-text": "onColorTextChanged"
      "paste .color-text": "onColorTextChanged"
      
      
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
      @$el.find('[rel=tooltip]').tooltip({'placement': 'bottom'})

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
    
    
    _applyParamChange:(paramName, paramValue)=>
      console.log "paramName",paramName, "paramValue",paramValue
      if not @project.meta.modParams?
        @project.meta.modParams={}
        for param of @project.meta.params
          @project.meta.modParams[param] = @project.meta.params[param]
      
      @project.meta.modParams[paramName] = paramValue
      
      if @autoUpdateBasedOnParams
        vent.trigger("project:compile")
      
    
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
      @_applyParamChange( paramName, paramValue )
    
    onColorTextChanged:(e)=>
      console.log "color change"
      colorText =  e.srcElement.value
      paramName = e.srcElement.parentElement.id
      if colorText.indexOf("rgb") != -1 
        color = colorText.replace("rgba","").replace("rgb","").replace("(","").replace(")","").replace(/\s/g,"")
        color = color.split(',')
        for comp,index in color
          color[index] = parseInt(comp)
        paramValue = color
        
      paramValue = [paramValue[0]/255,paramValue[1]/255, paramValue[2]/255, paramValue[3]]
      
      bleh = $("#"+paramName).find(".color-visual")
      bleh.css('background-color', colorText);
      @_applyParamChange( paramName, paramValue )
      
    onColorChanged:(e)=>
      console.log "color change", e.color.toRGB()
      console.log e
      paramName  = e.currentTarget.id
      paramValue = e.color.toRGB()
      paramValue = [paramValue.r/255,paramValue.g/255, paramValue.b/255, paramValue.a]
      console.log "Color name:", paramName," value",paramValue
      
      @_applyParamChange( paramName, paramValue )
      
    onSliderChanged:(e)=>
      console.log "slider change", e.value
      console.log e
      paramValue = e.value
      paramName  = e.currentTarget.id
      
      @_applyParamChange( paramName, paramValue )
      
    onParamsApply:()=>
      vent.trigger("project:compile")
    
    addFieldToFieldSet:(parentEl, param)=>
      getParamValue= ( param )=>
        if @project.meta.modParams?
          if param.name of @project.meta.modParams
            paramValue = @project.meta.modParams[param.name]
          else
            paramValue = param.default
        else
          paramValue = param.default
        return paramValue
      
      
      console.log "param",param
      paramValue = getParamValue( param )
      console.log "paramValue",paramValue
      
      container = $('<div>',{class: "control-group field-#{param.name}"})
      label = """<label class="control-label" for="#{param.name}">#{param.name}</label>"""
      toolTip = """<div class="help-inline"> <span><a href="#" data-toggle="tooltip" rel="tooltip" title="#{param.caption}"><i class="icon-question-sign icon-medium"/></a></span><div>"""
      
      switch param.type
        when "float", "int"
          control = """<div class="controls"> <input type='number' value='#{paramValue}' id='#{param.name}' class='myParams'/> #{toolTip} </div>"""
        
        when "checkbox"   
          control = """<div class="controls"> <input class='myParams' type='checkbox' id='#{param.name}' #{if param.default==true then 'checked' else ''}/> #{toolTip} </div>"""
        
        when "select"
          values = param.values.split(',')
          vals = ""
          for val in values
            vals += "<option value=#{val}>#{val}</option>"
          control = """<div class="controls"> <select id='#{param.name}' class='myParams'> #{vals} </select>#{toolTip}</div>"""
            
        when "color"
          if "#" in paramValue
            paramValue = @_hexToRgba(paramValue)
          rgbaValue = "rgba(#{paramValue.r}, #{paramValue.g}, #{paramValue.b}, #{paramValue.a})"
          control = """
          <div class="controls">
          <div class="input-append color colorpicker" data-color="#{rgbaValue}" data-color-format="rgba" id='#{param.name}'>
            <input type="text" class="span2 color-text" value="#{rgbaValue}" >
            <span class="add-on"><i class="color-visual" style="background-color: #{rgbaValue};"></i></span>
          </div>
          #{toolTip}</div>"""
         
        when "slider"
          control = """
          <div class="controls">
            <div>
            #{param.min}&nbsp<input id='#{param.name}' type="text" class="span2 slider" value="" 
              data-slider-min="#{param.min}" data-slider-max="#{param.max}" data-slider-step="#{param.step}" data-slider-value="#{paramValue}" 
              data-slider-orientation="horizontal" data-slider-selection="after"data-slider-tooltip="show" data-slider-handle="square">&nbsp#{param.max}
            #{toolTip}
            </div>
          </div>"""
          
      container.append(label)
      container.append(control)
      parentEl.append(container)  
      
    
    
    onParamsGenerated:=>
      if (not @preventUiRegen) or (@preventUiRegen and not @_drawnOnce)
        rootEl = $('<div>',{id: "paramsContainer", class:"form-horizontal"})
        
        if @project.meta.rawParams?
          unTreatedParams = {}
          for param in @project.meta.rawParams.fields
            unTreatedParams[param.name] = param
          
          #first handle all fieldsets and associeted fields/params
          for fieldSetData in @project.meta.rawParams.fieldsets
            console.log "fieldset", fieldSetData
            fieldSet= $('<div>')
            fieldSet.append("""<legend>#{fieldSetData.legend or "Default fieldset Name"}</legend>""")
            
            
            for field in fieldSetData.fields
              param = unTreatedParams[field]
              ### 
              for paramData in @project.meta.rawParams.fields
                if paramData.name == field
                  param = paramData
                  break
              ###
              if param?
                @addFieldToFieldSet(fieldSet, param)
                delete unTreatedParams[field]
              
            rootEl.append( fieldSet )
          
          #handle fields with no fieldset
          fieldSet= $('<div>')
          fieldSet.append("""<legend>Other</legend>""") 
          
          for paramName of unTreatedParams
            param = unTreatedParams[paramName]
            @addFieldToFieldSet( fieldSet, param )
            delete unTreatedParams[field]
          
          rootEl.append( fieldSet )
            
          ### 
          for param in @project.meta.rawParams.fields
            console.log "param",param
            paramValue = getParamValue( param )
            console.log "paramValue",paramValue
            
            container = $('<div>',{class: "control-group field-#{param.name}"})
            label = """<label class="control-label" for="#{param.name}">#{param.name}</label>"""
            toolTip = """<div class="help-inline"> <span><a href="#" data-toggle="tooltip" rel="tooltip" title="#{param.caption}"><i class="icon-question-sign icon-medium"/></a></span><div>"""
            
            switch param.type
              when "float", "int"
                control = """<div class="controls"> <input type='number' value='#{paramValue}' id='#{param.name}' class='myParams'/> #{toolTip} </div>"""
              
              when "checkbox"   
                control = """<div class="controls"> <input class='myParams' type='checkbox' id='#{param.name}' #{if param.default==true then 'checked' else ''}/> #{toolTip} </div>"""
              
              when "select"
                values = param.values.split(',')
                vals = ""
                for val in values
                  vals += "<option value=#{val}>#{val}</option>"
                control = """<div class="controls"> <select id='#{param.name}' class='myParams'> #{vals} </select>#{toolTip}</div>"""
                  
              when "color"
                if "#" in paramValue
                  paramValue = @_hexToRgba(paramValue)
                rgbaValue = "rgba(#{paramValue.r}, #{paramValue.g}, #{paramValue.b}, #{paramValue.a})"
                control = """
                <div class="controls">
                <div class="input-append color colorpicker" data-color="#{rgbaValue}" data-color-format="rgba" id='#{param.name}'>
                  <input type="text" class="span2" value="#{rgbaValue}" readonly="">
                  <span class="add-on"><i style="background-color: #{rgbaValue};"></i></span>
                </div>
                #{toolTip}</div>"""
               
              when "slider"
                control = """
                <div class="controls">
                  <div>
                  #{param.min}&nbsp<input id='#{param.name}' type="text" class="span2 slider" value="" 
                    data-slider-min="#{param.min}" data-slider-max="#{param.max}" data-slider-step="#{param.step}" data-slider-value="#{paramValue}" 
                    data-slider-orientation="horizontal" data-slider-selection="after"data-slider-tooltip="show" data-slider-handle="square">&nbsp#{param.max}
                  
                  #{toolTip}
                  </div>
                </div>"""
                
            container.append(label)
            container.append(control)
            rootEl.append(container)
            ###         
          
          parametrizerSettingsFieldSet = $('<div>')
          parametrizerSettingsFieldSet.append("""<legend>Parametrizer settings</legend>""")
          parametrizerSettings = $('<div>',{class: "control-group field-parametrizerSettings"})
          parametrizerSettings.append("""<div class='control-group field-autoUpdate'><label class="control-label" for="autoUpdate">Auto update</label> <div class="controls"> <input class='autoUpdate' id='autoUpdate' type='checkbox' #{if @autoUpdateBasedOnParams then 'checked' else ''} /></div></div>""")    
          parametrizerSettings.append("""<div class='control-group field-preventUiRegen'><label class="control-label" for="preventUiRegen">Keep ui</label> <div class="controls">   <input class='preventUiRegen' id='preventUiRegen' type='checkbox' #{if @preventUiRegen then 'checked' else ''} /></div></div>""")   
          parametrizerSettings.append("<div class='control-group field-applyParams'><button class='applyParams'>Apply Params</button></div>")  
          parametrizerSettingsFieldSet.append(parametrizerSettings)
          
          rootEl.append( parametrizerSettingsFieldSet ) 
          
           
            
          @_drawnOnce = true
          @newRootEl = rootEl
          @render()
    
      
  return ParamsEditorView