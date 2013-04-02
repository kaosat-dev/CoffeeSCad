define (require)->
  #.*?
  #[\w\//:'%~+#-.*\{\}]+
  describe "regexp tests", ->
    it "does match", ->
      paramsPattern = /\s*?params\s*?=\s*?(\[(.|[\r\n])*?\])/g
      source = """params = [{
        name: 'width', 
        type: 'float', 
        default: 10,
        caption: "Width of the cube:"
      }
      ]    
    toto = 25"""
    
    
      source = """
      params = [
  {
      name: 'width', 
      type: 'float', 
      default: 10,
      caption: "Width of the cube:", 
    }
    ]
      """
      #source = """params =[{
      #  name:'width', type: 'float', default: 10,caption: "Width of the cube:"},] pouet"""
      matches = []
      match = paramsPattern.exec(source)
      while match  
        matches.push(match)
        match = paramsPattern.exec(source)
      
      console.log "params ", matches
      mainMatch = matches[0][0].replace("=",":") #"{"+matches[0][0]+"}"
      #mainMatch = "params:{#{mainMatch}}"
      params = eval(mainMatch)
      console.log "mainMatch ", params
      
      results = {}
      for param in params
        results[param.name]=param.default
      console.log results
      console.log source
      source = source.replace(matches[0][1], JSON.stringify(results))
      console.log source
