define (require) ->
  CoffeeScript = require 'CoffeeScript'
  require 'coffeelint'
  reqRes = require 'modules/core/reqRes'
  utils = require "modules/core/utils/utils"

  
  class PreProcessor
    #dependency resolving solved with the help of http://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
    constructor:()->
      @project = null
      @lintErrors = []
      @resolvedIncludes = []
      @unresolvedIncludes = []
      reqRes.addHandler "getFileOrProjectCode",@_testSourceFetchHandler
    
    _testSourceFetchHandler:([store,project,path])=>
      #console.log "handler recieved #{store}/#{project}/#{path}"
      result = ""
      if not project? and path?
        #console.log "will fetch #{path} from local (current project) namespace"
        shortName = path.split('.')[0]
        #console.log "proj"
        #console.log @project
        result = @project.pfiles.get(shortName).get("content")
        result = "\n#{result}\n"
      #else if project? and path?
        #console.log "will fetch #{path} from project #{project}'s namespace"
      return result
      
    process:(project, coffeeToJs, lint)->
      coffeeToJs = coffeeToJs or false
      lint= lint or true
      @resolvedIncludes = []
      @unresolvedIncludes = []
      
      #if lint
      #  @lintProject(project)
        
      @project = project
      mainFileName = @project.get("name")
      mainFileCode = @project.pfiles.get(mainFileName).get("content")
      result  = @processIncludes(mainFileName, mainFileCode)
      
      if coffeeToJs
        result = CoffeeScript.compile(result, {bare: true})
      return result
    
    lintProject:(project)=>
      @lintErrors = []
      hasError = false
      for file in project.pfiles.models
        [errorInFile, lintErrors] = @lintFile(project.get("name"),file.get("name")+"."+file.get("ext"), file.get("content"))
        if not hasError
          hasError = errorInFile
          
      console.log "hasError #{hasError}"
      console.log @lintErrors
        
    lintFile:(projectName, fileName, source)=>

      lintingSettings=
        indentation:
          value: 2
          level: "error"
        max_line_length:
          value: 80
          level: "warn"
        no_tabs:
          level: "warn"
        no_trailing_whitespace:
          level: "error"
        no_trailing_semicolons:
          level: "warn"     
      lintErrors = coffeelint.lint(source, lintingSettings)
      hasError = false
      for error in lintErrors
        error.file = projectName+"/"+fileName
        @lintErrors.push(error)
        if error.level == "error"
          hasError = true
        
      return [hasError, lintErrors]
      
    processIncludes:(filename, source)=>
      #finds all matches of "include xxx", and fetches the corresponding text 
      #console.log "processing #{filename}"
      #console.log "@unresolvedIncludes : #{@unresolvedIncludes.join(' ')}"
      @unresolvedIncludes.push(filename)
      
      source = source or ""
      source = source.replace /(?!\s*?#)(?:\s*?include\s*?)(?:\(?\"([\w\//:'%~+#-.*]+)\"\)?)/g, (match,matchInner) =>
        #console.log "Matched : #{matchInner}"
        includeFull = matchInner.toString()
        store = null
        projectName = null
        projectSubPath = null
        fileInclude = false
        
        if includeFull.indexOf(':') != -1
          storeComponents = includeFull.split(':')
          store = storeComponents[0]
          includeFull = storeComponents[1]
          
        if includeFull.indexOf('/') != -1
          fullPath = includeFull.split('/')
          projectName = fullPath[0]
          projectSubPath = fullPath[1..fullPath.length].join('/')
          
        else
          if includeFull.indexOf('.') != -1 or includeFull.indexOf('.') == 0
            projectSubPath = includeFull#we have a dot -> we have a file
          else
            projectName = includeFull
        #console.log("store: #{store}, project: #{projectName}, subpath: #{projectSubPath}")
        includeeFileName = projectSubPath.split(".")[0]
        result = ""
        if includeeFileName in @unresolvedIncludes
          throw new Error("Circular dependency detected from #{filename} to #{includeeFileName}")
        if not (includeeFileName in @resolvedIncludes)
          result = @fetch_data(store,projectName,projectSubPath)
          result = @processIncludes(includeeFileName, result)
          
          @resolvedIncludes.push(includeeFileName)
        return result
        
      @unresolvedIncludes.splice(@unresolvedIncludes.indexOf(filename), 1)  
      return source
    
    fetch_data:(store,project,path)=>
      #console.log "fetching data from Store: #{store}, project: #{project}, path: #{path}"
      try
        fileOrProjectRequest = "#{store}/#{project}/#{path}"
        return reqRes.request("getFileOrProjectCode",[store, project, path])
      catch error
        console.log "error: #{error}"

  return PreProcessor