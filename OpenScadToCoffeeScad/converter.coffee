output_string = ""


test_string = "width=25.487; height=17.17; bli=[0,25,0];"
test_string = "abcdef;abcf;module bubu(){a=14;} c+=13.2; d-=12;
module ada_servo_driver(pos=[0,0,0],rot=[0,0,0]){
  width=25.4;
  length=62.5;
  height=3;
  translate(pos) rotate(rot)
  {
    translate([0,0,height/2]) cube([width,length,height],center=true);
  }}
module toto(){}"



##############################################

class StuffMatcher
  constructor: () ->
    @stuffs = []
  

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
    ([\w.]+)
    (?= ;)
  ///g
  
  params_pattern:
    ///
     [^,]+
    ///g
  
  constructor: () ->
    @modules = []
  
  parse: (src)->
    matches = src.match(@main_pattern)
    #console.log("All found modules: "+matches)
    
    for match in matches
      #console.log("Match: "+match)
      submatches = match.match(@components_pattern)
      ### for submatch in submatches
        console.log("submatch: "+submatch)###
      
      className = submatches[1].replace " ", ""
      console.log("Module/class name: " + className)
      params = submatches[2]
      if (params?) 
        console.log("   Module/class params: " + params)
        
      content = submatches[3] 
      if content?
        #console.log("   Content: " + content)
        exprmatches = content.match(@expr_pattern)
        console.log("   Content matches: "+exprmatches)
     
        #expr_pattern   
      
      
      #@modules.push({"className":className,"params":params})
       
        
        
    #console.log(@modules)

##############################################     
test_string=test_string.replace "\n", " "
console.log("Raw string " + test_string)

modMatcher = new ModuleMatcher()
modMatcher.parse(test_string)
        

    
  
