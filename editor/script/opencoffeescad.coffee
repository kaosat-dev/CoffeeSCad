#TODO: seperate viewer from processor
#TODO: add correct way to output progress and error info (to status bar for ex)

log = (txt) ->
    timeInMs = Date.now()
    prevtime = OpenCoffeeScad.log.prevLogTime
    if(!prevtime) prevtime = timeInMs
    deltatime = timeInMs - prevtime
    OpenCoffeeScad.log.prevLogTime = timeInMs
    timefmt = (deltatime*0.001).toFixed(3)
    txt = "["+timefmt+"] "+txt
    if (typeof(console) == "object") && (typeof(console.log) == "function") 
      console.log(txt)
    else if (typeof(self) == "object") && (typeof(self.postMessage) == "function") 
      self.postMessage({cmd: 'log', txt: txt})
    else throw new Error("Cannot log")

isChrome = ()->
  return navigator.userAgent.search("Chrome") >= 0

   
class Viewer
  constructor: ()->
  setupUI:->
  
class Processor
  constructor: (@containerdiv,@statusdiv, width, height, onchange)->
    @viewerwidth = (typeof width === "undefined") ? 800 : width
    @viewerheight = (typeof width === "undefined") ? 600 : height
  
  setupUI:->
    if !isChrome
      msg="Please note: OpenJsCad currently only runs reliably on Google Chrome!"
 

##ORDER OF ALGORITHM
#1-setJsCad
#   1-1-getParamDefinitions
#   1-2-createParamControls (optional?)
    
#   1-3 rebuildSolid
#     useSynch= debug 
 
class CoffeeScad
  
  constructor: (@debug=true, @currentObject)->
    
  setDebug: (@debug) -> 
  
  abort:()->
    
  setError:(errorMsg)->
    
    
  setCurrentObject: (obj) ->
    @currentObject = obj
    if(@viewer)
      csg = @convertToSolid(obj)
      @viewer.setCsg(csg)
    @hasValidCurrentObject = true
    ext = @extensionForCurrentObject()
    #this.generateOutputFileButton.innerHTML = "Generate "+ext.toUpperCase();

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
      if errtxt ?
        errorTxt = error.toString()
        postMessage({cmd: 'error', err: errorTxt})
   
  parseJsCadScriptSync: (script, mainParameters, debugging) -> 
    workerscript = ""
    workerscript += script;
    if debugging
      workerscript += "\n\n\n\n\n\n\n/* -------------------------------------------------------------------------\n"
      workerscript += "OpenJsCad debugging\n\nAssuming you are running Chrome:\nF10 steps over an instruction\nF11 steps into an instruction\n"
      workerscript += "F8  continues running\nPress the (||) button at the bottom to enable pausing whenever an error occurs\n"
      workerscript += "Click on a line number to set or clear a breakpoint\n"
      workerscript += "For more information see: http://code.google.com/chrome/devtools/docs/overview.html\n\n"
      workerscript += "------------------------------------------------------------------------- */\n"
      workerscript += "\n\n// Now press F11 twice to enter your main() function:\n\n"
      workerscript += "debugger;\n"
  
    workerscript += "return main("+JSON.stringify(mainParameters)+");"  
    f = new Function(workerscript)
    #OpenJsCad.log.prevLogTime = Date.now()
    result = f()
    return result


  getBlobBuilder:() ->
    bb;
    if(window.BlobBuilder)
      bb = new window.BlobBuilder()
    else if(window.WebKitBlobBuilder)
      bb = new window.WebKitBlobBuilder()
    else if(window.MozBlobBuilder) 
      bb = new window.MozBlobBuilder()
    else throw new Error("Your browser doesn't support BlobBuilder")
    return bb
    
  setJsCad: (script, filename) ->
    # script: javascript code
    # filename: optional, the name of the .jscad file
    if(!filename) filename = "openjscad.jscad"
    filename = filename.replace(/\.jscad$/i, "")
    #this.abort()
    #this.clearViewer();
    @paramDefinitions = []
    @paramControls = []
    @script = null
    #@.setError("")
    scripthaserrors = false
    try
      @paramDefinitions = @getParamDefinitions(script)
      @createParamControls()
    catch(e)
      @setError(e.toString())
      #@statusspan.innerHTML = "Error."
      scripthaserrors = true

    if(!scripthaserrors)
      @script = script
      @filename = filename
      @rebuildSolid()
    else
      #@enableItems()
      #if(this.onchange) this.onchange();

  getParamDefinitions: (script)->
    scriptisvalid = true
    try
      # first try to execute the script itself
      # this will catch any syntax errors
      f = new Function(script)
      f()
    catch(e)
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
     paramValues = {}
     for i in [0...this.paramDefinitions.length]
        paramdef = this.paramDefinitions[i]
        type = "text"
        if'type' in paramdef
          type = paramdef.type
          
        control = @paramControls[i]
        value = ""
        if( (type == "text") || (type == "float") || (type == "int") )
          value = control.value;
          if( (type == "float") || (type == "int") )
            var isnumber = !isNaN(parseFloat(value)) && isFinite(value)
            if(!isnumber)
              throw new Error("Not a number: "+value)
            if(type == "int")
              value = parseInt(value)
            else
              value = parseFloat(value);

        else if(type == "choice")
          value = control.options[control.selectedIndex].value
     paramValues[paramdef.name] = value
     return paramValues
     
   rebuildSolid:() =>
      #@abort()
      #@setError("")
      #@clearViewer()
      @processing = true
      
      #TODO: clean way to handle these type of messages
      #this.statusspan.text = "Processing, please wait..."
    
      #@enableItems()
  
      paramValues = @getParamValues()
      useSync = @debug
      if !useSync
        try
          @worker = OpenJsCad.parseJsCadScriptASync(@script, paramValues, function(err, obj) {
          that.processing = false
          that.worker = null
          if(err)
          {
            that.setError(err);
            that.statusspan.innerHTML = "Error.";
          }
          else
          {
            that.setCurrentObject(obj);
            that.statusspan.innerHTML = "Ready.";
          }
          that.enableItems();
          if(that.onchange) that.onchange();
          });
        catch(e)
          useSync = true
        #TODO : refactor this
      if useSync
        try
          var obj = OpenJsCad.parseJsCadScriptSync(this.script, paramValues, this.debugging);
          @setCurrentObject(obj);
          @processing = false
          #@statusspan.innerHTML = "Ready."
        catch(e)
          @processing = false
          errtxt = e.stack
          if(!errtxt)
            errtxt = e.toString()
          @setError(errtxt)
          #TODO: clean way to handle these type of messages
          #@statusspan.innerHTML = "Error."
      #@enableItems()
     
namespace "OpenCoffeeScad", (exports) ->
  exports.Viewer = Viewer
  