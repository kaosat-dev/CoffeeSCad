define (require) ->
  ### 
  params = {
      name: 'width', 
      type: 'float', 
      default: 10,
      caption: "Width of the cube:", 
    }
  ###  
  class ParameterParser
    constructor:()->
      @paramControls = []  
      @tablerows = []
    
    exportParams:()=>
    
    getParamDefinitions: (script)->
      scriptisvalid = true
      try
        # first try to execute the script itself
        # this will catch any syntax errors
        f = new Function(script)
        f()
      catch e 
        scriptisvalid = false;
      params = []
      if(scriptisvalid)
        script1 = "if(typeof(getParameterDefinitions) == 'function') {return getParameterDefinitions();} else {return [];} "
        script1 += script
        f = new Function(script1)
        params = f()
        if( (typeof(params) != "object") || (typeof(params.length) != "number") )
          throw new Error("The getParameterDefinitions() function should return an array with the parameter definitions")
      return params    
    
    createControls:(params)=>
      paramDefinitions = params
      for paramdef, index in paramDefinitions
        errorprefix = "Error in parameter definition # #{index} :"
        if not "name" of paramdef then throw new Error(" #{errorprefix} Should include a 'name' parameter")
        
        type = "text"
        type = if 'type' in paramdef then paramdef.type
        
        if( (type != "text") and (type != "int") and (type != "float") and (type != "choice"))
          throw new Error("#{errorprefix} Unknown parameter type #{type}")
          
        control = null
        if( (type == "text") or (type == "int") or (type == "float") )
          control = document.createElement("input")
          control.type = "text"
          if('default' of paramdef)
            control.value = paramdef.default
          else
            if( (type or "int") || (type or "float") )
              control.value = "0"
            else
              control.value = ""
        else if(type == "choice")
          if !('values' of paramdef) then throw new Error(errorprefix + "Should include a 'values' parameter") 
          control = document.createElement("select")
          values = paramdef.values
          captions=null
          if 'captions' in paramdef
            captions = paramdef.captions;
            if captions.length != values.length then throw new Error(errorprefix + "'captions' and 'values' should have the same number of items")
          else
            captions = values
          selectedindex = 0
          for valueindex in [0..values.length]
            option = document.createElement("option")
            option.value = values[valueindex]
            option.text = captions[valueindex]
            control.add(option)
            if 'default' in paramdef
              if paramdef.default == values[valueindex]
                selectedindex = valueindex
                
          if values.length > 0
            control.selectedIndex = selectedindex
  
        paramControls.push(control)
        tr = document.createElement("tr")
        td = document.createElement("td")
        label = paramdef.name + ":"
        if 'caption' in paramdef
          label = paramdef.caption
  
        td.innerHTML = label
        tr.appendChild(td)
        td = document.createElement("td")
        td.appendChild(control)
        tr.appendChild(td)
        tablerows.push(tr)
        
      tablerows.map((tr) ->
        @parameterstable.appendChild(tr)
      )
      @paramControls = paramControls
    
