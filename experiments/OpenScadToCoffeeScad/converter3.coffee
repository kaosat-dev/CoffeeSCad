text = "
servo_mount_hole_dia=3;
xtra=0.1;
servo_mount_hole_radius=servo_mount_hole_dia/2;
module ada_servo_driver(pos=[0,0,0],rot=[0,0,0])
{
  width=25.4;
  length=62.5;
  height=3;
  translate(pos) rotate(rot)
  {
    difference()
    {
      translate([0,0,height/2]) cube([width,length,height],center=true);
      cylinder(r=servo_mount_hole_dia/2, h=height+xtra);
    }
  }
}

module cubeWith_hole(COLOR=[0.1,0,1])
{
  color(COLOR)
  difference()
  {
    cube([10,10,10]);
    cylinder(r=1, h=10+xtra);
  }
}

module withSubmodule()
{
  
  module _subModule()
  {
    cylinder(r=1, h=10+xtra);
  }
  difference()
  {
    cube([10,10,10]);
    _subModule();
  }
}
  "
  
  
###########################################
debug=false

paramsmatcher= (text)->
  params = {}
  pattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+|\[(.*?)\])?(?=,|;|$)/g)
  match = pattern.exec(text)
  while match 
    ParamName = match[1]
    ParamValue = match[2]
    #console.log("ParamName: " + ParamName + " value: "+ParamValue)
    params[ParamName] = ParamValue
    match = pattern.exec(text)
  if debug
    for key, val of params
      console.log("pouet"+key + " "+ val)
  return params
  
globalparamsmatcher= (text, parent=null)->
  #cheat , to only catch everything up until first module : could it be fixed by something like (?!module)
  pattern= new RegExp(/(.*?)(?=module)/)
  text = pattern.exec(text)[1]

  pattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+|\[(.*?)\])?(?=,|;|$)/g)
  match = pattern.exec(text)
  while match 
    ParamName = match[1]
    ParamValue = match[2]
    #console.log(" ParamName: " + ParamName + " value: "+ParamValue)
    if parent?
      expr = new Expression(ParamName, ParamValue, parent)
      parent.children.push(expr)
    match = pattern.exec(text)
  

modulematcher= (text, parent=null)->
  pattern = new RegExp(/module\s??([\w]+)\s??\((.*?)\)(\{.*?\})/g)
  match = pattern.exec(text)
  while match  
    moduleName = match[1]
    moduleParams = match[2]
    moduleContent = match[3]
    if debug
      console.log("Match: "  + match )
      console.log("ModuleName: " + moduleName + ", ModuleParams: "+moduleParams)
    console.log("ModuleContent"+moduleContent)
    params = paramsmatcher(moduleParams)
    
    if parent?
      module = new Module(moduleName, params, parent)
      parent.children.push(module)
      
    match = pattern.exec(text)

opsmatcher = (text, parent=null)->
  pattern = new RegExp(/module\s??([\w]+)\s??\((.*?)\)\{(.*?)\}/g)
  match = pattern.exec(text)
  while match  
    console.log("Match: "  + match )
    if parent?
      op = new Operation(type, params, parent)
      parent.children.push(module)
    match = pattern.exec(text)
  

rootMatcher= (text) ->
  root = new Token()
  globalparamsmatcher(text, root)
  modulematcher(text, root)
  root.print()
  #console.log("Result:\n"+root.write())


class Token
  constructor: (@parent=null, @children = []) ->
    #console.log("Parent:"+ "CHILDREN: "+@children+ " PARENT: "+ @parent)
  
  print: ->
    #console.log("params:#{@params}")
    for child in @children
      child.print()
      
  write: ->
    result= ""
    result+=child.write()+"\n" for child in @children
    return result

class Expression extends Token
  """ For expressions like name=value: handles float, int, array, string types of values"""
  constructor: (@name, @value, parent, children = []) ->
    super(parent, null)
    
  print: ->
    console.log("Expr : __Name__: #{@name}, __Value__: #{@value}\n")
  
  write: ->
    result= "#{@name}=#{@value}"
    return result
    
class Operation extends Token
  

class Module extends Token
  constructor: (@name, @params=[], parent, children = []) ->
    super(parent, children)
    #console.log("PARAMS: "+ @params + ", CHILDREN: "+@children+ ", PARENT: "+ @parent+ ", NAME: "+ @name)
  
  print: ->
    output = "Module name: #{@name}, params: \n"
    for key, val of @params
      output+="   __Name__: "+key + ", __Value__: "+ val + "\n"
    output += "   -->\n"
    console.log(output)
    for child in @children
      child.print()
      
   write: ->
    params_data = ""
    tmp = []
    for key, val of @params
        tmp.push("@#{key}=#{val}")
    params_data = tmp.join(",")
    result= "class #{@name}\n
    constructor: (#{params_data})->
      "
    result+=child.write() for child in @children
    return result
    
###########################################
#rootMatcher(text)

ops = ['=','!=', '+=' ,'/=', '*=','+', '-', '%', '/' ,'*']
limiters = [';',',']
text = "servo_mount_hole_dia=3;
xtra=0.1;
xtra2+=0.1;
servo_mount_hole_radius=servo_mount_hole_dia/2;tutu=21.7;"

op = null
name = null
value = null

exprs = []

spliterIndex=-1
startIndex=0

for letter, index in text
  if letter in ops and op ==null
    console.log(letter)
    if name == null
      name = text[startIndex..index-1]
    #console.log ("oh yeah at index #{index}")

    if op != null
      op += letter
    else
      op = letter
    spliterIndex= index+1
  else if letter in limiters
    value = text[spliterIndex..index-1]
    startIndex = index+1
    console.log("__Name__: #{name}, __op__: #{op}, __Value__: #{value}")
    exprs.push("#{name}#{op}#{value}")
    value = name = op = null
      


console.log(exprs);