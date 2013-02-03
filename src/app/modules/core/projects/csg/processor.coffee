define (require) ->
  CoffeeScript = require 'CoffeeScript'
  reqRes = require 'modules/core/reqRes'
  utils = require "modules/core/utils/utils"
  csgSugar = require "./sugar2"
  
  
  ##Inner workflow
  #- linting ?
  #- Compile
  #   - Preprocess (resolve includes, parameters (defines))
  #   - Compile Coffeescript to js
  #- rebuildSolid (convert data to geometry) : can be in sync mode (ui thread, simple) or async (web workers)
   
  class CsgProcessor
    #minimal version of csg processor, for future cleanup of the rest
    construtor:()->
      @sync = true
      @debug = true
      
    processScript2:(script, sync=true, mergeAll=false)-> 
      #experimental process script V2
      @sync = sync
      base = require './csg' 
      CSGBase = base.CSGBase
      
      #main project alias ?
      class Assembly extends CSGBase
        constructor:()->
          super
          @params = []
      
      @assemblyRoot = new Assembly()
      
      @script = @compileFormatCoffee(script)
      csgTmp = @rebuildSolid()
      if mergeAll
        for part in @assemblyRoot.children
          @assemblyRoot.union(part)

      return @assemblyRoot
      
    processScript:(script, filename) ->
      #experimental process script
      base = require './csg' 
      CSGBase = base.CSGBase
      #main project alias ?
      class Assembly extends CSGBase
        constructor:()->
          super
          @parts = []
          @params = []
          
        add:(objects...)->
          for obj in objects
            @parts.push(obj)
          console.log @parts
      @assemblyRoot = new Assembly()
      
      @script = @compileFormatCoffee(script)
      csgTmp = @rebuildSolid()
      
      console.log "rootProject object"
      console.log @assemblyRoot
      
      for part in @assemblyRoot.parts
        console.log("part")
        console.log part
        @assemblyRoot.union(part)
      
      return @assemblyRoot
      
    processScript_old:(script, filename) ->
      #original process script
      csg=null
      # script: coffeescript code
      # filename: optional, the name of the .coscad file
      filename = if !filename then "coffeescad.coscad"
      filename = filename.replace(/\.coscad$/i, "")
      @paramDefinitions = []
      @paramControls = []
      @script = null
      
      # @createParamControls() : TODO work on this parametrization
      @script = @compileFormatCoffee(script)
      @filename = filename
      csg=@rebuildSolid()
      
      return csg
        
    processIncludes:(source)->
      #TODO: move this to some more general code processing/ codeediting module ?
      #TODO: cleanup regexp (ie in order not to have to use two)
      #(?:\"([\w\//:'%~+#-.*]+)\")
      #(?:\(\"([\w\//:'%~+#-.*]+)\"\))
      pattern = new RegExp(/(?:\s??include\s??)(?:\"([\w\//:'%~+#-.*]+)\")/g)
      #console.log "searching includes"
      match = pattern.exec(source)
      includes = []
      
      while match  
        #console.log("Match: "  + match )
        includes.push(match[1])
        #for submatch in match
        #  console.log("SubMatch:" + submatch)
        match = pattern.exec(source)
      
      pattern = new RegExp(/(?:\s??include\s??)(?:\(\"([\w\//:'%~+#-.*]+)\"\))/g)
      match = pattern.exec(source)
      while match  
        #console.log("Match2: "  + match )
        includes.push(match[1])
        #for submatch in match
        #  console.log("SubMatch:" + submatch)
        match = pattern.exec(source)
        
      return includes
        
    compileFormatCoffee:(source)->
      #Compile coffeescript code to js, add formating , included libs etc
      #console.log("Compiling & formating coffeescad code")
      libsSource = ""
      
      ###
      FIXME: refactor includes system
      lib = app.lib
      window.include= (options)=>
        pp=pp
      
      extSource = reqRes.request("#{otherProjectName}/#{otherProjectFileName}")
      includes = @processIncludes(source)
      #console.log "includes"+ includes
      for index, inc of includes
        project = lib.fetch({id:inc})
        if project?
          mainPart = project.pfiles.at(0)
          if mainPart?
            includeSrc = mainPart.get("content")
            libsSource+= includeSrc+ "\n" 
      libsSource+="\n"   
      ###
         
      fullSource = libsSource + source
      textblock = CoffeeScript.compile(fullSource, {bare: true})

      formated=""
      #formated += "function main(options)"
      #formated += "{ "
      formated += ""
      formated += textblock
      #formated += "}\n"
      if @debug_ing#TODO correct this
        console.log("Formated scad #{formated}")
      return formated
      
    rebuildSolid:() =>
      @debug = true
      @processing = true
      paramValues = null
      console.log "Using sync rebuild:#{@sync}"
      try
        if @sync
          obj = @parseScriptSync(@script, paramValues, @debugging)
          #@worker = @parseJsCadScriptASync(@script, paramValues, (err, obj)-> 
          #@setCurrentObject(obj)
        else
          obj = @parseScriptASync(@script, paramValues, @debugging)
        obj = @convertToSolid(obj)
        @processing = false
        return obj
      catch error
        @processing = false
        throw error
    
    parseScriptSync: (script, mainParameters, debugging) -> 
      #Parse the given coffeescad script in the UI thread (blocking but simple)
      
      #jsonifiedParams = JSON.stringify(mainParameters)
      base = require './csg' 
      CSGBase = base.CSGBase
      CAGBase = base.CAGBase
  
      shapes3d = require './geometry3d'
      shapes2d = require './geometry2d' 
      
      Cube = shapes3d.Cube
      Sphere = shapes3d.Sphere
      Cylinder= shapes3d.Cylinder
      Rectangle = shapes2d.Rectangle
      Circle = shapes2d.Circle
      
      extras = require './extras'
      quickHull2d = extras.quickHull2d
      #dependencyNames = "CSGBase", "CAGBase", "shapes3d", "shapes2d", "Cube", "Sphere","Cylinder","Rectangle","Circle","quickHull2d"
      dependencies = [CSGBase, CAGBase, shapes3d, shapes2d, Cube, Sphere,Cylinder,Rectangle,Circle,quickHull2d]
      
      workerscript = ""
      workerscript += script;
      if @debuging
        workerscript += "//Debugging;\n"
        workerscript += "debugger;\n"
    
      options={}
      f = new Function("assembly",workerscript)
      #OpenCoffeeScad.log.prevLogTime = Date.now()
      result = f(@assemblyRoot)
      return result
    
    parseScriptASync:(script, params, callback)->
      #Parse the given coffeescad script in a seperate thread (web worker)
    
    _processScriptASync:(script, params, callback)->
      workerscript = ""
      workerscript += script
      
      testMethod=()->
        self.postMessage({cmd: 'rendered', result: result_compact})
      
      blobURL = utils.textToBlobUrl(workerscript)
      worker = new Worker(blobURL)
      worker.onmessage = (e) ->
        if e.data
          if e.data.cmd is "rendered"
            resulttype = e.data.result.class
            result = undefined
            if resulttype is "CSG"
              result = fromCompactBinary(e.data.result)
            else if resulttype is "CAG"
              result = fromCompactBinary(e.data.result)
            else
              throw new Error("Cannot parse result")
            callback null, result
          else if e.data.cmd is "error"
            callback e.data.err, null
          else console.log e.data.txt  if e.data.cmd is "log"
    
      worker.onerror = (e) ->
        errtxt = "Error in line " + e.lineno + ": " + e.message
        callback errtxt, null
    
      worker.postMessage cmd: "render"
      # Start the worker.
      worker
    
    parseCoffeeSCadScriptASync_old = (script, mainParameters, callback) ->
      # callback: should be function(error, csg)
      baselibraries = ["./js/csg.js", "./js/openjscad.js"]
      baseurl = document.location + ""
      workerscript = ""
      workerscript += script
      workerscript += "\n\n\n\n//// The following code is added by OpenJsCad:\n"
      workerscript += "var _csg_libraries=" + JSON.stringify(baselibraries) + ";\n"
      workerscript += "var _csg_baseurl=" + JSON.stringify(baseurl) + ";\n"
      workerscript += "var _csg_makeAbsoluteURL=" + OpenJsCad.makeAbsoluteUrl.toString() + ";\n"
      
      workerscript += "_csg_libraries = _csg_libraries.map(function(l){return _csg_makeAbsoluteURL(l,_csg_baseurl);});\n"
      workerscript += "_csg_libraries.map(function(l){importScripts(l)});\n"
      workerscript += "self.addEventListener('message', function(e) {if(e.data && e.data.cmd == 'render'){"
      workerscript += "  OpenJsCad.runMainInWorker(" + JSON.stringify(mainParameters) + ");"
      
      workerscript += "}},false);\n"
      blobURL = OpenJsCad.textToBlobUrl(workerscript)
      throw new Error("Your browser doesn't support Web Workers. Please update to Chrome, Firefox or Opera")  unless window.Worker
      worker = new Worker(blobURL)
      worker.onmessage = (e) ->
        if e.data
          if e.data.cmd is "rendered"
            resulttype = e.data.result.class
            result = undefined
            if resulttype is "CSG"
              result = fromCompactBinary(e.data.result)
            else if resulttype is "CAG"
              result = fromCompactBinary(e.data.result)
            else
              throw new Error("Cannot parse result")
            callback null, result
          else if e.data.cmd is "error"
            callback e.data.err, null
          else console.log e.data.txt  if e.data.cmd is "log"
    
      worker.onerror = (e) ->
        errtxt = "Error in line " + e.lineno + ": " + e.message
        callback errtxt, null
    
      worker.postMessage cmd: "render"
      # Start the worker.
      worker
      
    convertToSolid : (obj) ->
      ###
      if( (typeof(obj) == "object") and ((obj instanceof CAG)) )
        # convert a 2D shape to a thin solid:
        obj=obj.extrude({offset: [0,0,0.1]})
      else if( (typeof(obj) == "object") and ((obj instanceof CSG)) )
        # obj already is a solid
      else
        throw new Error("Cannot convert to solid");
      ###
      return obj

  #######################
  ###
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

      
  return CsgProcessor