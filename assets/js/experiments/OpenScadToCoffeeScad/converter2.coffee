test_string = "r=emire_dia/2, h=25, thingy='bla.toto:df', stuff=12.5, otherstuff=[25.7,2,3], stuff2=tutu%7.5"
#identifiers : r , h, thingy, stuff, otherstuff
#values: emire_dia/2 -> expression, 25->simple, int, 'bla'->string, 12.5: float, [25.7,2,3]->array


text = "h=25, stuff=12.5"
pattern = new RegExp(/([\w]+)=(\d*\.?\d*)?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)

console.log("#########################################")
text = "otherstuff=[25.7,2,3], stuff=12.5, h=25, u=12"
pattern = new RegExp(/([\w]+)=(\[(.*?)\])?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)

console.log("#########################################")
text = "thingy='bla.toto:df' , gruck=33"
pattern = new RegExp(/([\w]+)=('.*')+?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)

console.log("#########################################")
text = "stuff2=tutu%7.5*3/2+height-toto, r=emire_dia/2"
pattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+)?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)


console.log("#########################################FULL##")
text = "r=emire_dia/2, h=25, thingy='bla.toto:df', stuff=12.5, otherstuff=[25.7,2,3], stuff2=tutu%7.5*3/2+height-toto"
pattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+|\[(.*?)\])?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)
  
console.log("#########################################FULL2##")
text = "cylinder(r=emire_dia/2, h=emire_height)"
pattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+|\[(.*?)\])?/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  for submatch in match
    console.log("SubMatch:" + submatch)
  match = pattern.exec(text)


console.log("#########################################FULL2##")
text = "module kpla(val=17.2,emire_dia=10, emire_height=7,name='bli', pos=[0,0,0], color=BLACK){cylinder(r=emire_dia/2, h=emire_height);cube([10,10,10],center=true);}
"
pattern = new RegExp(/module\s??([\w]+)\s??\((.*?)\)/g)
match = pattern.exec(text)
while match  
  console.log("Match: "  + match )
  moduleName = match[1]
  moduleParams = match[2]
  
  console.log("moduleName: " + moduleName + " moduleParams: "+moduleParams)
  
  subpattern = new RegExp(/([\w]+)=([\w\//:'%~+#-.*]+|\[(.*?)\])?(?=,|$)/g)
  submatch = subpattern.exec(moduleParams)
  while submatch 
    ParamName = submatch[1]
    ParamValue = submatch[2]
    console.log("ParamName: " + ParamName + " value: "+ParamValue)
    submatch = subpattern.exec(moduleParams)
 
  
  match = pattern.exec(text)
  

class Token
  constructor: () ->
    @params = []
    @children = []
    @parent = null
  