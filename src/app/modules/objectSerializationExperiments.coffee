      class Toto
        constructor:->
            @bla=24
            @bli=27
        myMethod:(tut)=>
          @bla+=tut

      tutu = new Toto()
      console.log "original"
      console.log tutu
      
      ###
      objSource = tutu.toSource()
      console.log "source: #{objSource}"
      f = new Function(objSource)
      obj = f()
      
      obj = eval(objSource)
      console.log "obj: "
      console.log obj
      ###
      
      jsonVer = JSON.stringify(tutu)
      jsonObj = JSON.parse(jsonVer)
      console.log "json result"
      console.log jsonObj