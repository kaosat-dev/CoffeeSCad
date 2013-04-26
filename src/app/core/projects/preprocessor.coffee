define (require) ->
  CoffeeScript = require 'CoffeeScript'
  require 'coffeelint'
  reqRes = require 'core/messaging/appReqRes'
  utils = require "core/utils/utils"
  
  class PreProcessor
    #dependency resolving solved with the help of http://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
    constructor:()->
      @debug = null
      @project = null
      @includePattern = /(?!\s*?#)(?:\s*?include\s*?)(?:\(?\"([\w\//:'%~+#-.*]+)\"\)?)/g
      @paramsPattern = /^\s*?params\s*?=\s*?(\[(.|[\r\n])*?\])/g
      
      @resolvedIncludes = []
      @unresolvedIncludes = []
      
      @lintErrors = []
    
    _localSourceFetchHandler:([store,project,path,deferred])=>
      #console.log "handler recieved #{store}/#{project}/#{path}"
      result = ""
      if not project? and path?
        if @debug
          console.log "will fetch #{path} from local (current project) namespace"
        shortName = path
        file = @project.rootFolder.get(shortName)
        result = file.content
        result = "\n#{result}\n"
        deferred.resolve(result)
      else if project? and path?
        throw new Error("non prefixed includes can only get files from current project")
      
    process:(project, coffeeToJs, lint)=>
      coffeeToJs = coffeeToJs or false
      lint= lint or true
      @resolvedIncludes = []
      @resolvedIncludesFull = []
      @unresolvedIncludes = []
      
      @deferred = $.Deferred()
      try
        #if lint
        #  @lintProject(project)
        
        @project = project
        mainFileName = @project.name+".coffee"
        mainFile = @project.rootFolder.get(mainFileName)
        if not mainFile?
          throw new Error("Missing main file (needs to have the same name as the project containing it)")
          
        mainFileCode = mainFile.content
        
        reqRes.addHandler("getlocalFileOrProjectCode",@_localSourceFetchHandler)
        
        
        @patternReplacers= []
        @processedResult = mainFileCode
        
        @processIncludes(mainFileName, mainFileCode)
      catch error
        @deferred.reject(error)
      
      $.when.apply($, @patternReplacers).done ()=>
        if coffeeToJs
          @processedResult = CoffeeScript.compile(@processedResult, {bare: true})
          
        #experiment
        ###
        tokens = CoffeeScript.tokens(@processedResult)
        console.log "tokens" 
        console.log tokens
        nodes = CoffeeScript.nodes(tokens)
        console.log "nodes"
        console.log nodes
        
        addReplacementVisitor = onCall: (n, replaceCallback) ->
          if n.variable.base.value is "ADD"
            addOp = new nodes.Op("+", n.args[0], n.args[1])
            replaceCallback addOp
        console.log JSON.stringify nodes.expressions, null, "  "
        ###
        ### 
        for include in @resolvedIncludesFull
          @processedResult.replace(include, "")
        @processedResult.replace("""include""","toto")###
        @processedResult = @_findParams(@processedResult) # just a test
        #console.log "@processedResult",@processedResult
        @deferred.resolve(@processedResult)
      
      return @deferred.promise()
    
    
    _findParams:(source)=>
      source = source or ""
      matches = []
      match = @paramsPattern.exec(source)
      while match  
        matches.push(match)
        match = @paramsPattern.exec(source)
      
      @project.meta = {}
      #console.log "matches", matches
      if matches.length>0
        mainMatch = matches[0][0].replace("=",":")
        params = eval(mainMatch)
        results = {}
        for param in params
          results[param.name]=param.default
        source = source.replace(matches[0][0], "")
        @project.meta.params = results
        
      return source      
    
    _findMatches:(source)=>
      source = source or ""
      
      matches = []
      match = @includePattern.exec(source)
      while match  
        matches.push(match)
        match = @includePattern.exec(source)
      return matches
    
    processIncludes:(filename, source)=>
      @unresolvedIncludes.push(filename)
     
      matches =  @_findMatches(source)     
      for match in matches
        includeEntry = match[1] 
        store = null
        projectName = null
        projectSubPath = null
        fullIncludePath = includeEntry
        
        if includeEntry.indexOf(':') != -1
          storeComponents = includeEntry.split(':')
          store = storeComponents[0]
          includeEntry = storeComponents[1]
        if includeEntry.indexOf('/') != -1
          fullPath = includeEntry.split('/')
          projectName = fullPath[0]
          projectSubPath = fullPath[1..fullPath.length].join('/')
        else
          if includeEntry.indexOf('.') != -1 or includeEntry.indexOf('.') == 0
            projectSubPath = includeEntry#we have a dot -> we have a file
          else
            projectName = includeEntry
            
        #console.log("store: #{store}, project: #{projectName}, subpath: #{projectSubPath}")
        includeeFileName = fullIncludePath
        result = ""
        if includeeFileName in @unresolvedIncludes
          throw new Error("Circular dependency detected from #{filename} to #{includeeFileName}")
          
        if not (includeeFileName in @resolvedIncludes)
          try
            deferred = $.Deferred()
            @patternReplacers.push(deferred)
            fetchResult = @_fetch_data(store,projectName,projectSubPath, deferred)
            $.when(fetchResult).then (fileContent)=>
              @processedResult=@processedResult.replace(match[0], fileContent)
              @processIncludes(includeeFileName, fileContent)
              
          catch error
            throw error
          @resolvedIncludes.push(includeeFileName)
          @resolvedIncludesFull.push match[0]
        else
          @processedResult=@processedResult.replace(match[0], "")
      
      @unresolvedIncludes.splice(@unresolvedIncludes.indexOf(filename), 1)  

    _fetch_data:(store,project,path,deferred)=>
      #console.log "fetching data from Store: #{store}, project: #{project}, path: #{path}"
      try
        fileOrProjectRequest = "#{store}/#{project}/#{path}"
        if store is null then prefix = "local" else prefix = store
        reqRes.request("get#{prefix}FileOrProjectCode",[store, project, path, deferred])
        result = deferred.promise()
        return result
      catch error
        console.log "error: #{error}"
        throw new Error("#{path} : No such file or directory")
     
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
      
     
  return PreProcessor