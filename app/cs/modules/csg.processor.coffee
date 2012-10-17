define (require) ->
  CoffeeScript = require 'CoffeeScript'  
  ##ORDER OF ALGORITHM
  #1-setJsCad
  #   1-1-getParamDefinitions
  #   1-2-createParamControls (optional?)
      
  #   1-3 rebuildSolid
  #     useSynch= debug 
   
   
  class CsgProcessorMin
    #minimal version of csg processor, for future cleanup of the rest
    construtor:()->
      @debug=true
      
    setCoffeeSCad: (script, filename) ->
      # script: coffeescript code
      # filename: optional, the name of the .cocad file
      filename = if !filename then "openjscad.jscad"
      filename = filename.replace(/\.jscad$/i, "")
      #@clearViewer()
      @paramDefinitions = []
      @paramControls = []
      @script = null
      scripthaserrors = false
      try
       # @createParamControls() : TODO work on this parametrization
      catch e 
        scripthaserrors = true
  
      if(!scripthaserrors)
        #console.log("script: #{script}")
        @script = @compileFormatCoffee(script)
        @filename = filename
        @rebuildSolid()
        console.log("No errors in script")
      else
        console.log("Errors in script")
        
    compileFormatCoffee:(source)->
      console.log("Compiling & formating coffeescad code")
      extraLibTest = "var Cube = CSG.cube;\n"
      extraLibTest += "var Sphere = CSG.sphere;\n"
      extraLibTest += "var Cylinder = CSG.cylinder;\n"
      extraLibTest += "var fromPoints = CAG.fromPoints;\n"
      
      #console.log("source: #{source}")
      #TODO: replace this with compile --bare 
      source+=".mirroredY().rotateX(-90)"     
      textblock = CoffeeScript.compile(source)
      console.log("-->base compile done")
      
      lines = textblock.split('\n')
      if @debug_ing#TODO correct this
        console.log("Raw Lines" + (lines.length-1))
      endsplitter = lines.length-2
      lines.splice(endsplitter,2)
      lines.splice(0,1)
      formated = "function main()"
      formated += "{"
      formated += extraLibTest; #TODO: work on this, this is just a "namespace removing" / dependency injection test to get rid of CSG. and CAG. 
      #in the actual coffeescad projects/scripts
      formated += lines.join('\n')
      formated += "}\n"
      if @debug_ing#TODO correct this
        console.log("Formated scad #{formated}")
      return formated
      
    rebuildSolid:() =>
      @debug = true
      if @debug ==true
        console.log("Starting solid rebuild")
        #@clearViewer()
        @processing = true
        
        #TODO: clean way to handle these type of messages
        #@statusspan.text = "Processing, please wait..."
    
        paramValues = null
        try
          obj = @parseJsCadScriptSync(@script, paramValues, @debugging)
          @setCurrentObject(obj)
          @processing = false
        catch e 
          @processing = false
          
    setCurrentObject: (obj) =>
      #the threeCSG.fromCSG method needs to take the csg from here 
      @currentObject = obj
      @csg = @convertToSolid(obj)
      #@viewer.setCsg(csg)
      return 
    
    
    parseJsCadScriptSync: (script, mainParameters, debugging) -> 
      #console.log("Synch Parsing")
      workerscript = ""
      workerscript += script;
      if @debuging
        workerscript += "\n\n\n\n\n\n\n/* -------------------------------------------------------------------------\n"
        workerscript += "OpenJsCad debugging\n\nAssuming you are running Chrome:\nF10 steps over an instruction\nF11 steps into an instruction\n"
        workerscript += "F8  continues running\nPress the (||) button at the bottom to enable pausing whenever an error occurs\n"
        workerscript += "Click on a line number to set or clear a breakpoint\n"
        workerscript += "For more information see: http://code.google.com/chrome/devtools/docs/overview.html\n\n"
        workerscript += "------------------------------------------------------------------------- */\n"
        workerscript += "\n\n// Now press F11 twice to enter your main() function:\n\n"
        workerscript += "debugger;\n"
    
      workerscript += "return main("+JSON.stringify(mainParameters)+");"  
      #console.log("workerscript #{workerscript}")
      f = new Function(workerscript)
      #OpenCoffeeScad.log.prevLogTime = Date.now()
      result = f()
      return result
      
    convertToSolid : (obj) ->
      if( (typeof(obj) == "object") && ((obj instanceof CAG)) )
        # convert a 2D shape to a thin solid:
        obj=obj.extrude({offset: [0,0,0.1]})
      else if( (typeof(obj) == "object") && ((obj instanceof CSG)) )
        # obj already is a solid
      else
        throw new Error("Cannot convert to solid");
      return obj


#######################
  class CsgProcessor 
    constructor: (debug, @currentObject, @statusdiv, @viewer)->
      console.log "in processor init"
      @debug = if debug? then debug else true 
      console.log "debug #{@debug},@statusdiv : #{@statusdiv}, @viewer: #{@viewer}"
      
    abort:()->
      
    setError:(errorMsg)->
      console.log("ERROR: #{errorMsg}")
      
    setCurrentObject: (obj) =>
      #console.log("Setting current object")
      @currentObject = obj
      if(@viewer)
        #console.log("I HAVE A VIEWER")
        csg = @convertToSolid(obj)
        @viewer.setCsg(csg)
      @hasValidCurrentObject = true
      ext = @extensionForCurrentObject()
      return
      #@generateOutputFileButton.innerHTML = "Generate "+ext.toUpperCase();
      
    convertToSolid : (obj) ->
      if( (typeof(obj) == "object") && ((obj instanceof CAG)) )
        # convert a 2D shape to a thin solid:
        obj=obj.extrude({offset: [0,0,0.1]})
      else if( (typeof(obj) == "object") && ((obj instanceof CSG)) )
        # obj already is a solid
      else
        throw new Error("Cannot convert to solid");
      return obj
      
    extensionForCurrentObject: ()->
      extension
      if(this.currentObject instanceof CSG)
        extension = "stl"
      else if(this.currentObject instanceof CAG)
        extension = "dxf"
      else
        throw new Error("Not supported")
      return extension
  
    clearViewer:()->
      @clearOutputFile()
      @setCurrentObject(new CSG())
      @hasValidCurrentObject = false
      @enableItems()
      
    clearOutputFile:()->
      if @hasOutputFile
        @hasOutputFile = false
        if(@outputFileDirEntry)
          @outputFileDirEntry.removeRecursively(()->)
          @outputFileDirEntry=null
        if @outputFileBlobUrl
          OpenJsCad.revokeBlobUrl(@outputFileBlobUrl)
          @outputFileBlobUrl = null
        @enableItems()
        if @onchange
          this.onchange()
      
    enableItems: () ->
      
    ###
    runMainInWorker: (mainParams) -> 
      try
        #TODO: adapt this to coffeescad
        if (typeof(main) != 'function') 
          throw new Error('Your jscad file should contain a function main() which returns a CSG solid or a CAG area.')
          #OpenJsCad.log.prevLogTime = Date.now()
          result = main(mainParameters);
          if( (typeof(result) != "object") || ((!(result instanceof CSG)) && (!(result instanceof CAG))))
            throw new Error("Your main() function should return a CSG solid or a CAG area.")
          result_compact = result.toCompactBinary()
          result = null # not needed anymore
          #self.postMessage({cmd: 'rendered', result: result_compact});
          
      catch error
        errorTxt = error.stack
        if errtxt?
          errorTxt = error.toString()
          postMessage({cmd: 'error', err: errorTxt})
    ###
     
    parseJsCadScriptSync: (script, mainParameters, debugging) -> 
      #console.log("Synch Parsing")
      workerscript = ""
      workerscript += script;
      if @debuging
        workerscript += "\n\n\n\n\n\n\n/* -------------------------------------------------------------------------\n"
        workerscript += "OpenJsCad debugging\n\nAssuming you are running Chrome:\nF10 steps over an instruction\nF11 steps into an instruction\n"
        workerscript += "F8  continues running\nPress the (||) button at the bottom to enable pausing whenever an error occurs\n"
        workerscript += "Click on a line number to set or clear a breakpoint\n"
        workerscript += "For more information see: http://code.google.com/chrome/devtools/docs/overview.html\n\n"
        workerscript += "------------------------------------------------------------------------- */\n"
        workerscript += "\n\n// Now press F11 twice to enter your main() function:\n\n"
        workerscript += "debugger;\n"
    
      workerscript += "return main("+JSON.stringify(mainParameters)+");"  
      #console.log("workerscript #{workerscript}")
      f = new Function(workerscript)
      #OpenCoffeeScad.log.prevLogTime = Date.now()
      result = f()
      return result
      
    parseCoffeesCadScriptSync: (script, mainParameters, debugging) -> 
      #console.log("Synch Parsing")
      workerscript = ""
      workerscript += script;
      if @debuging
        workerscript += "\n\n\n\n\n\n\n/* -------------------------------------------------------------------------\n"
        workerscript += "OpenJsCad debugging\n\nAssuming you are running Chrome:\nF10 steps over an instruction\nF11 steps into an instruction\n"
        workerscript += "F8  continues running\nPress the (||) button at the bottom to enable pausing whenever an error occurs\n"
        workerscript += "Click on a line number to set or clear a breakpoint\n"
        workerscript += "For more information see: http://code.google.com/chrome/devtools/docs/overview.html\n\n"
        workerscript += "------------------------------------------------------------------------- */\n"
        workerscript += "\n\n// Now press F11 twice to enter your main() function:\n\n"
        workerscript += "debugger;\n"
     
      workerscript += "return main("+JSON.stringify(mainParameters)+");"  
      #console.log("workerscript #{workerscript}")
      f = new Function(workerscript)
      #OpenCoffeeScad.log.prevLogTime = Date.now()
      result = f()
      return result
      
    setCoffeeSCad: (script, filename) ->
      # script: javascript code
      # filename: optional, the name of the .jscad file
      filename = if !filename then "openjscad.jscad"
      filename = filename.replace(/\.jscad$/i, "")
      #@abort()
      @clearViewer()
      @paramDefinitions = []
      @paramControls = []
      @script = null
      #@.setError("")
      scripthaserrors = false
      try
        #@paramDefinitions = @getParamDefinitions(script)
       # console.log("@paramDefinitions: #{@paramDefinitions}")
       # @createParamControls() : TODO work on this parametrization
      catch e 
        @setError(e.toString())
        #@statusspan.innerHTML = "Error."
        scripthaserrors = true
  
      if(!scripthaserrors)
        @script = @compileFormatCoffee(script)
        @filename = filename
        @rebuildSolid()
        #console.log("No errors in script")
      else
        #console.log("Errors in script")
        #@enableItems()
        #if(@onchange) @onchange();
        
    createParamControls: ->
      #@parameterstable.innerHTML = ""
      @paramControls = []
      paramControls = []
      tablerows = []
      for i in [0..@paramDefinitions.length]
        errorprefix = "Error in parameter definition #"+(i+1)+": "
        paramdef = @.paramDefinitions[i]
        if !('name' in paramdef) then throw new Error(errorprefix + "Should include a 'name' parameter")
        type = "text"
        type = if 'type' in paramdef then paramdef.type
  
        if( (type != "text") && (type != "int") && (type != "float") && (type != "choice") )
          throw new Error(errorprefix + "Unknown parameter type '"+type+"'")
        control = null
        if( (type == "text") || (type == "int") || (type == "float") )
          control = document.createElement("input")
          control.type = "text"
          if('default' in paramdef)
            control.value = paramdef.default
          else
            if( (type == "int") || (type == "float") )
              control.value = "0"
            else
              control.value = ""
        else if(type == "choice")
          if !('values' in paramdef) then throw new Error(errorprefix + "Should include a 'values' parameter") 
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
      
     getParamValues: ()->
       if @debug
         console.log("Getting param values")
         console.log("#{@paramDefinitions.length}")
       paramValues = {}
       for i in [0...@paramDefinitions.length]
          paramdef = @paramDefinitions[i]
          type = "text"
          if 'type' in paramdef
            type = paramdef.type
          control = @paramControls[i]
          value = ""
          if( (type == "text") || (type == "float") || (type == "int") )
            value = control.value;
            if( (type == "float") || (type == "int") )
              isnumber = !isNaN(parseFloat(value)) && isFinite(value)
              if(!isnumber)
                throw new Error("Not a number: "+value)
              if(type == "int")
                value = parseInt(value)
              else
                value = parseFloat(value);
  
          else if type == "choice"
            value = control.options[control.selectedIndex].value
          paramValues[paramdef.name] = value
       if @debug
         console.log("Finished getting param values")
       return paramValues
       
     rebuildSolid:() =>
       
       if @debug
        #console.log("Starting solid rebuild")
        #@abort()
        #@setError("")
        #@clearViewer()
        @processing = true
        
        #TODO: clean way to handle these type of messages
        #@statusspan.text = "Processing, please wait..."
      
        #@enableItems()
    
        paramValues = null#@getParamValues()
        useSync = @debug
        if !useSync
          try
            @worker = @parseJsCadScriptASync(@script, paramValues, (err, obj)-> 
              @processing = false
              @worker = null
              if err
                @setError(err)
                #@statusspan.innerHTML = "Error."
              else
                @setCurrentObject(obj)
                #@statusspan.innerHTML = "Ready."
              )
            @enableItems()
            #if(that.onchange) that.onchange()
  
          catch e
            useSync = true
          #TODO : refactor this
        if useSync
          try
            obj = @parseJsCadScriptSync(@script, paramValues, @debugging)
            @setCurrentObject(obj)
            @processing = false
            #@statusspan.innerHTML = "Ready."
          catch e 
            @processing = false
            errtxt = e.stack
            if(!errtxt)
              errtxt = e.toString()
            @setError(errtxt)
            #TODO: clean way to handle these type of messages
            #@statusspan.innerHTML = "Error."
        #@enableItems()
    preprocessCode:(code)->
      #just some experimental js code for fetching all CSG and CAG methods, to add them as no-namespace methods
      #into the project code : ie , "CSG.cube()" should become simply "cube()"
      ###   
      function getMethods(obj)
      {
          var res = [];
          for(var m in obj) {
              if(typeof obj(m) == "function") {
                  res.push(m)
              }
          }
          return res;
      }
      
      for (prop in CSG)
      {
          //console.log("CSG has property " + prop);
      }
    
        console.log(getMethods(CSG));
        
        var objs = Object.getOwnPropertyNames(CSG);
      for(var i in objs ){
        console.log(objs[i]);
      }###
    compileFormatCoffee:(source)->
      ###var extraLibTest2= "fromPoints = "+CAG.fromPoints+ "\n";
      extraLibTest2 += "cube = "+CSG.cube + "\n";###
      extraLibTest = "var cube = CSG.cube;\n"; 
      extraLibTest += "var fromPoints = CAG.fromPoints;\n"; 
      #console.log("fromPoints"+extraLibTest);
      
      ###var textblock= codeEditor.getValue();
      var lines = textblock.split('\n');
      lines.splice(0,1);
      textblock= lines.join('\n');
      console.log(textblock);###
      
      
      
      textblock = CoffeeScript.compile(source)
      lines = textblock.split('\n')
      if @debug_ing#TODO correct this
        console.log("Raw Lines" + (lines.length-1))
      endsplitter = lines.length-2
      lines.splice(endsplitter,2)
      lines.splice(0,1)
      formated = "function main()"
      formated += "{"
      formated += extraLibTest; #TODO: work on this, this is just a "namespace removing" / dependency injection test to get rid of CSG. and CAG. 
      #in the actual coffeescad projects/scripts
      formated += lines.join('\n')
      formated += "}\n"
      if @debug_ing#TODO correct this
        console.log("Formated scad #{formated}")
      return formated
      
  return CsgProcessorMin#CsgProcessor