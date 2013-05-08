provideNs=(nameSpace) =>
        nsElems = nameSpace.split('.')
        root = {}
        for nsElem in nsElems
          root[nsElem]= @[nsElem] or {}
          root= @[nsElem] 

      #--------------------    
      rootNs = {}
      console.log "resolved ", filename, "raw source:", source ,"ok"
      
      patate =  "patate = 122\nroot = exports ? this\n"
      scopeStuff="""
      scope=(fn)->
        fn()
      
      """
      source =patate+source
      #console.log "modified src ",source
      rawScript = CoffeeScript.compile(source)
      #console.log "rawScript ", rawScript
      ### 
      rawScript = """
      patapon = 57
      scope = function(fn)
      {
        fn();
      };
      scope(function() {#{rawScript}});"""
      console.log "rawScript2 ", rawScript###
      
      fileNs = filename.split(".")[0]
      rootNs[fileNs] = f = new Function(rawScript)
      compiledFile = f()
      
      #console.log "testVariable", testVariable
      
      @compiledFiles[filename]=compiledFile
      #console.log "compiledFile",compiledFile
      console.log "window", window
      
      
      tokens = CoffeeScript.tokens(source)
      console.log "tokens" 
      console.log tokens
      nodes = CoffeeScript.nodes(tokens)
      console.log "nodes"
      console.log nodes
      ast=nodes
      
      ### 
      ast.traverseChildren true, (node) ->
        #if node.value?
          #if node.constructor.name is "t" # and node.value is not "n "
            #console.log "blah"
        console.log node.constructor.name
        console.log node.value
        if node.operator?
          console.log "operator expr",node.first.base.value, node.operator, node.second.base.value
        
        
        if node.constructor.name is "Call"
          {variable, args} = node
          if variable.base.value is 'require' and variable.properties.length is 0
            console.log args[0]
      ###
      #astWalk(nodes)
      #astNodeManip(source)
      
      
      #--------------------    
      if parent?
        parent.children.push 
       {name:mainFileName,children:[],parent:null}