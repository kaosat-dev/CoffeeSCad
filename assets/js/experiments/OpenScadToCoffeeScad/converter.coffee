output_string = ""



#test_string = "width=25.487; height=17.17; bli=[0,25,0];"
###test_string = "abcdef;abcf;module bubu(){a=14;} c+=13.2; d-=12;
module ada_servo_driver(pos=[0,0,0],rot=[0,0,0]){
  width=25.4;
  length=62.5;
  height=3;
  translate(pos) rotate(rot)
  {
    translate([0,0,height/2]) cube([width,length,height],center=true);
  }}
module toto(pos){}
module other(name='bli'){}
module kpla(val=17.2, emire_dia=10, emire_height=7){cylinder(r=emire_dia/2, h=emire_height);}
"###

test_string = "
module kpla(val=17.2, emire_dia=10, emire_height=7,name='bli',pos=[0,0,0],color=BLACK){cylinder(r=emire_dia/2, h=emire_height);cube([10,10,10],center=true);}
"


debug=true
##############################################

class Token
  constructor: () ->
    @children = []
    @parent = null
  

class ModuleMatcher
  main_pattern : ///
  (?:module (.*?) \( (.*?)?? \)
  \{ #main block
    
    .*?
    
  \})
  ///g


  components_pattern : ///
  (?:module (.*?) \( (.*?)?? \)
  \{ #main block
    
    (.*?)??
    
  \})
  ///
  
  expr_pattern: ///
    ([\w]+) 
      [\= \+ \- \*  \/ \%]+ 
    ([\w.-]+)
    (?= ;)
  ///g
  

  params_pattern:
    ///
     ([\w]+
     =?
     (([\w.-]+)?
      |  # or
     (\[ (.*?)?? \])?
     )?)
    ///g
    
    
  ops_pattern:
    ///
    (translate | rotate | scale | mirror | color)
    \{ ?
    ([\w.-]+)?
    \}?
    ///g
    
  shapes_pattern:
    ///
    (cube | cylinder | sphere)
    (?: \( )
      (?: .*?)
    (?: \) ) 
    ;
    ///g
    
  shapes_pattern2:
    ///
    (cube | cylinder | sphere)
     (?: \( )
      (.*?)
     (?: \))
     ;
    ///
    
  cylinder_pattern:
    ///
    r = (.*)+ 
    h = (.* [^,])+
    ///
  
  constructor: () ->
    @modules = []
  
  parse: (src)->
    matches = src.match(@main_pattern)
    #console.log("All found modules: "+matches)
    
    for match in matches
      submatches = match.match(@components_pattern)
      className = submatches[1].replace " ", ""
      if debug
        console.log("Module/class name: " + className)
        console.log("Match: "+match)
        for submatch in submatches
          console.log("   sub match: "+submatch)
      
      ###Module params###
      paramsStr = ""  
      params = submatches[2]
      if params?
        params=  params.match(@params_pattern)
        params = ('@'+param for param in params)
        paramsStr = params.join(',')
        
        if debug
          console.log(" Module/class params: " + params)
          console.log(" Module params Matches "+params)
          for submatch in params
            console.log("     Submatch: "+submatch)
          
          
      ###Module content###
      contentStr = ""
      content = submatches[3] 
      if content?
        console.log("   Raw content "+content)
        try
          exprmatches = content.match(@expr_pattern)
          if exprmatches
            console.log("   Content matches: "+exprmatches)
            content = (''+ctnt for ctnt in exprmatches)
            content = content.join("\n\t")
            content = content.replace(/,/g, "\n").replace(/\=/g, ":")
            if debug 
              console.log("   Content: " + content)
        catch error
          console.log("Error in content parsing: "+error)
      else:
        content = ""
          
      renderstr = ""  
      ###ops and shapes###
      opsshapes = submatches[3]
      if content?
        try
          opsmatches = opsshapes.match(@ops_pattern)
          console.log("Ops matches "+opsmatches)
          
          shapesmatches = opsshapes.match(@shapes_pattern)
          
          #console.log("Shape matches "+shapesmatches)
          
          for shapeData in shapesmatches    
            console.log("Info: " + shapeData)
            [empty, shape_type, shape_params] = shapeData.match(@shapes_pattern2)
            console.log("Shape type "+ shape_type)
            console.log("  Shape params "+shape_params)
            
            if shape_type == "cylinder"
              cyl_params = shape_params.match(@cylinder_pattern)
              console.log ("sqd: "+ cyl_params[1])
              #   console.log ("  cylinder params " + cyl_params.join(" \n "))
              #renderstr += "CSG.cylinder({start: [0, 0, 0], end: [0, 0, @height],radius: @mount_holes_dia/2);"
         
        catch error
          console.log("Error in ops and shapes parsing: "+error)
      
      ###Generate output: coffeescript class ###
      classStr = """
        class #{className}
        \t#{content}

        \tconstructor: (#{paramsStr}) ->
                  
        \trender: =>
        \t\t result = new CSG()
        \t\t #{renderstr}
        """
      @modules.push(classStr)
      
       
  write: ->
    console.log(@modules.join("\n"))

##############################################     
test_string=test_string.replace "\n", " "
console.log("Raw string " + test_string)

modMatcher = new ModuleMatcher()
modMatcher.parse(test_string)
        
modMatcher.write()
    
  
