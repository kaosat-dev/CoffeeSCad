define (require) ->
  Viewer = require 'viewer'
  Processor = require 'processor'
  Store = require 'DataStore'
  
  OpenCoffeeScad = { }
  OpenCoffeeScad.Viewer=Viewer
  OpenCoffeeScad.Processor=Processor
  OpenCoffeeScad.Store=Store
  
  window.OpenCoffeeScad= OpenCoffeeScad
  #TODO: add correct way to output progress and error info (to status bar for ex)
  
  OpenCoffeeScad.log = (txt) ->
      timeInMs = Date.now()
      prevtime = OpenCoffeeScad.log.prevLogTime
      prevtime = if !prevtime then timeInMs 
  
      deltatime = timeInMs - prevtime
      OpenCoffeeScad.log.prevLogTime = timeInMs
      ###timefmt = (deltatime*0.001).toFixed(3)
      txt = "["+timefmt+"] "+txt
      if (typeof(console) == "object") && (typeof(console.log) == "function") 
        console.log(txt)
      else if (typeof(self) == "object") && (typeof(self.postMessage) == "function") 
        self.postMessage({cmd: 'log', txt: txt})
      else throw new Error("Cannot log")###
  
  OpenCoffeeScad.isChrome= ->
    return navigator.userAgent.search("Chrome") >= 0
  
  return OpenCoffeeScad
      
   

     