define (require) ->
  CoffeeScript = require 'CoffeeScript'
  reqRes = require 'modules/core/reqRes'
  utils = require "modules/core/utils/utils"
  
  class PreProcessor
    
    process:(source)->
      #taken from csg.processor for now
      
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
    
    
    processIncludes:(source="")->
      #finds all matches of "include xxx", and fetches the corresponding text 
      #from coffeescript cookbook
      source = 'include("blabla.coffee")'
      #source = '  include "blabla"'
      source = source.replace /\s*?include\s*?(?:\"([^\"]*)\")|(?:\(\"([^\"]*)\"\))/g, (match) ->
        console.log "FOUND A MATCH: #{match}"
        match.toUpperCase()
      
      console.log "result"
      console.log source
      
      source = 'include ("blabla.coffee")'
      pattern = new RegExp(/(?:\s??include\s??)(?:\"([\w\//:'%~+#-.*]+)\")/g)
      match = pattern.exec(source)
      console.log match
      
      pattern = new RegExp(/(?:\s??include\s??)(?:\(\"([\w\//:'%~+#-.*]+)\"\))/g)
      match = pattern.exec(source)
      console.log match
    
    processIncludes_old:(source)->
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

  return PreProcessor