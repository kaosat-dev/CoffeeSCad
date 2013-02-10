define (require) ->
  reqRes = require 'modules/core/reqRes'
  utils = require "modules/core/utils/utils"
  CoffeeScript = require 'CoffeeScript'
  
  
  ##Inner workflow
  #- linting ?
  #- Compile
  #   - Preprocess (resolve includes, parameters (defines))
  #   - Compile Coffeescript to js
  #- rebuildSolid (convert data to geometry) : can be in sync mode (ui thread, simple) or async (web workers)
   
  class CsgProcessor
    #minimal version of csg processor, for future cleanup of the rest
    construtor:()->
      @async = false
      @debug = false
      
    processScript2:(script, async=false, mergeAll=false, callback)-> 
      #experimental process script V2
      
      @callback = callback
      
      @async = async
      base = require './csgBase' 
      CSGBase = base.CSGBase
      
      #main project alias ?
      class Assembly extends CSGBase
        constructor:()->
          super
          @params = []
      
      @assemblyRoot = new Assembly()
      
      @script = script
      csgTmp = @rebuildSolid()
      if mergeAll
        for part in @assemblyRoot.children
          @assemblyRoot.union(part)

      return @assemblyRoot
      

    doStuff:()=>
      @script = """
      {CAGBase,CSGBase,Circle,Cube,Cylinder,Line2D,Line3D,Matrix4x4,
      OrthoNormalBasis,Part,Path2D,Plane,Polygon,PolygonShared,Rectangle,
      RoundedCube,RoundedCylinder,RoundedRectangle,Side,Sphere,Vector2D,Vector3D,
      Vertex,Vertex2D,classRegistry,otherRegistry,property,quickHull2d,quickHull2dVar2,register,solve2Linear}=csg
      #{@script}
      """
      @script = CoffeeScript.compile(@script, {bare: true})
      #console.log "JSIFIED script"
      #console.log @script
      
    rebuildSolid:() =>
      @debug = true
      @processing = true
      paramValues = null
      console.log "Using background rebuild:#{@async}"
      
      @doStuff()
      
      try
        if @async
          @parseScriptASync(@script, paramValues,@callback)
        else
          @parseScriptSync(@script, paramValues, @debugging)
          @callback(@assemblyRoot)
        @processing = false
      catch error
        @processing = false
        throw error
    
    parseScriptSync: (script, mainParameters, debugging) -> 
      #Parse the given coffeescad script in the UI thread (blocking but simple)
      #jsonifiedParams = JSON.stringify(mainParameters)
      csgFull = require "./csg"
      
      workerscript = ""
      workerscript += script
      if @debuging
        workerscript += "//Debugging;\n"
        workerscript += "debugger;\n"
    
      options={}
      
      f = new Function("assembly","csg",workerscript)
      result = f(@assemblyRoot,csgFull)
      return result
    
    parseScriptASync:(script, params, callback)->
      #Parse the given coffeescad script in a seperate thread (web worker)
      rootUrl = (document.location.href).replace('#','')
      workerScript = """
      var rootUrl = "#{rootUrl}";
      importScripts(rootUrl + '/assets/js/libs/require.min.js');
      require(
        {baseUrl: rootUrl +"/app"},["require","modules/core/projects/csg/csg"],
        function(require,csg){
          
            
            var Cube = csg.Cube;
            var Sphere = csg.Sphere;
            var Cylinder = csg.Cylinder;
            var CSGBase = csg.CSGBase;
            
            assembly = new CSGBase();
            #{script}
            //postMessage("before compacting data");
            var result_compact = assembly.toCompactBinary()
            //postMessage("After compacting data");
            postMessage({cmd: 'rendered', result: result_compact});
            
           
            
            
            /*
            onmessage = function(e) { 
            postMessage("Got",e.data);
            var data = e.data;
            if(data == 'render')
            {
              postMessage({cmd: 'rendered', result: result_compact});
            }
            if(data == 'stop')
            {
              postMessage('msg from worker: I WILL STOP'); 
            }
            
            }*/
      });
      """
      
      workerScript2 = """
      var rootUrl = "#{rootUrl}";
      var truc = self;
      importScripts(rootUrl + '/assets/js/libs/require.min.js');
      require([], function() {
          postMessage("in require");
          
          
          self.addEventListener('message', function(e) {
            self.postMessage(e.data);
          }, false);
      
          truc.onmessage = function(event) {
              postMessage("received something");
          }
      });
      
      """
      
      
      blobURL = utils.textToBlobUrl(workerScript)
      worker = new Worker(blobURL)
      worker.onmessage = (e) ->
        if e.data
          #console.log "got data"
          #console.log e.data
          if e.data.cmd is 'rendered'
            
            #console.log "render result"
            #console.log e.data.result
            converters = require './converters' 
            testConversion = converters.fromCompactBinary(e.data.result)
            #console.log "converted"
            #console.log testConversion
            @assemblyRoot=testConversion
            callback(testConversion)
      worker.postMessage("render")
    
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
###

      
  return CsgProcessor