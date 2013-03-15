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
    
    _testSourceFetchHandler:([store,project,path,deferred])=>
      #console.log "handler recieved #{store}/#{project}/#{path}"
      result = ""
      if not project? and path?
        console.log "will fetch #{path} from local (current project) namespace"
        shortName = path
        #console.log "proj"
        #console.log @project
        file = @project.rootFolder.get(shortName)
        result = file.content
        result = "\n#{result}\n"
        deferred.resolve(result)
      else if project? and path?
        throw new Error("non prefixed includes can only get files from current project")
        #console.log "will fetch #{path} from project #{project}'s namespace"
      
    process:(project, coffeeToJs, lint)=>
      coffeeToJs = coffeeToJs or false
      lint= lint or true
      @resolvedIncludes = []
      @unresolvedIncludes = []
      
      #if lint
      #  @lintProject(project)
      @project = project
      mainFileName = @project.name+".coffee"
      mainFile = @project.rootFolder.get(mainFileName)
      if not mainFile?
        throw new Error("Missing main file (needs to have the same name as the project containing it)")
      mainFileCode = mainFile.content
      
      reqRes.addHandler("getlocalFileOrProjectCode",@_testSourceFetchHandler)
      
      result  = @processIncludes(mainFileName, mainFileCode)
      
      if coffeeToJs
        result = CoffeeScript.compile(result, {bare: true})
      return result
    
    lintProject:(project)=>
      @lintErrors = []
      hasError = false
      for file in project.rootFolder.models
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
      #FIXME: as now all stores return deferreds/callbacks , the code here to fetch data should be CHANGED accordingly
      
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
        includeeFileName = projectSubPath
        #includeeFileName = projectSubPath.split(".")[0]
        result = ""
        if includeeFileName in @unresolvedIncludes
          throw new Error("Circular dependency detected from #{filename} to #{includeeFileName}")
        if not (includeeFileName in @resolvedIncludes)
          try
            fetchResult = @fetch_data(store,projectName,projectSubPath)
            $.when(fetchResult).then (fileContent)=>
              result = @processIncludes(includeeFileName, fileContent)
          catch error
            throw error
          @resolvedIncludes.push(includeeFileName)
        console.log "result"
        console.log result
        return result
        
      @unresolvedIncludes.splice(@unresolvedIncludes.indexOf(filename), 1)  
      return source
    
    fetch_data:(store,project,path)=>
      #console.log "fetching data from Store: #{store}, project: #{project}, path: #{path}"
      try
        fileOrProjectRequest = "#{store}/#{project}/#{path}"
        if store is null then prefix = "local" else prefix = store
        deferred = $.Deferred()
        reqRes.request("get#{prefix}FileOrProjectCode",[store, project, path, deferred])
        result = deferred.promise()
        return result
      catch error
        console.log "error: #{error}"
        throw new Error("#{path} : No such file or directory")

  return PreProcessor